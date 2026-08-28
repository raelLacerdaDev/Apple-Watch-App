import Foundation
import HealthKit
import os
internal import Combine

// nonisolated pra poder ser chamado de workoutSession(_:didFailWithError:), que é nonisolated
// (protocolo do HealthKit) — sem isso o isolamento padrão em MainActor do projeto barra o acesso.
nonisolated private let workoutLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.anaclaracaldeira.Apresentation", category: "WorkoutManager")

@MainActor
class WorkoutManager: NSObject, ObservableObject {
	
	let healthStore = HKHealthStore()
	var session: HKWorkoutSession?
	var builder: HKLiveWorkoutBuilder?
	
	// O app precisa saber se está rodando para a UI
	@Published var running = false
	
	// Métricas para a tela de resumo final
	@Published var averageHeartRate: Double = 0
	@Published var heartRate: Double = 0
	@Published var workout: HKWorkout?
	@Published var timeAccelerated: TimeInterval = 0
	@Published var warningsCount: Int = 0

	// Permissões iniciais
	func requestAuthorization() async {
		guard HKHealthStore.isHealthDataAvailable() else { return }

		let typesToShare: Set = [
			HKObjectType.workoutType()
		]
		
		let typesToRead: Set = [
			HKQuantityType.quantityType(forIdentifier: .heartRate)!
		]
		
		do {
			try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
		} catch {
			workoutLogger.error("Erro na permissão do HealthKit: \(error.localizedDescription)")
		}
	}
	
	// Início da sessão do workout
	func startWorkout() {
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = .mindAndBody
		configuration.locationType = .indoor
		
		do {
			session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
			builder = session?.associatedWorkoutBuilder()
		} catch {
			workoutLogger.error("Erro ao iniciar sessão: \(error.localizedDescription)")
			return
		}
		
		// Define os delegates para receber os dados ao vivo
		session?.delegate = self
		builder?.delegate = self
		
		builder?.dataSource = HKLiveWorkoutDataSource(
			healthStore: healthStore,
			workoutConfiguration: configuration
		)
		
		let startDate = Date()
		session?.startActivity(with: startDate)
		
		Task {
			do {
				try await builder?.beginCollection(at: startDate)
				self.running = true
			} catch {
				workoutLogger.error("Erro ao iniciar coleta do treino: \(error.localizedDescription)")
			}
		}
	}
	
	// Encerramento manual pelo usuário
	func stopWorkout() {
		session?.end()
	}
	
	func togglePause() {
		if running {
			pause()
		} else {
			resume()
		}
	}

	func pause() {
		session?.pause()
	}

	func resume() {
		session?.resume()
	}
	
	// Atualização dos batimentos
	func updateForStatistics(_ statistics: HKStatistics?) {
		guard let statistics = statistics else { return }

		switch statistics.quantityType {
		case HKQuantityType.quantityType(forIdentifier: .heartRate):
			let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
			self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
			self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
		default:
			return
		}
	}
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
	nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
		Task { @MainActor in
			self.running = (toState == .running)
			
			// Se o treino parou ou encerrou
			if toState == .stopped || toState == .ended {
				self.running = false
				do {
					try await self.builder?.endCollection(at: date)
					let workout = try await self.builder?.finishWorkout()
					self.workout = workout
				} catch {
					workoutLogger.error("Erro ao encerrar treino: \(error.localizedDescription)")
				}
			}
		}
	}

	nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
		workoutLogger.error("Sessão falhou: \(error.localizedDescription)")
	}
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
	nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

	nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
		for type in collectedTypes {
			guard let quantityType = type as? HKQuantityType else { return }
			
			let statistics = workoutBuilder.statistics(for: quantityType)
			
			Task { @MainActor in
				self.updateForStatistics(statistics)
			}
		}
	}
}
