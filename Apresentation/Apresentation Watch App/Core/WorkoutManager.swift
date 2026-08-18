import Foundation
import HealthKit
import Combine

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
	func requestAuthorization() {
		let typesToShare: Set = [
			HKObjectType.workoutType()
		]
		
		let typesToRead: Set = [
			HKQuantityType.quantityType(forIdentifier: .heartRate)!
		]
		
		healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
		}
	}
	
	// inicio da sessao do workout
	func startWorkout() {
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = .other
		configuration.locationType = .unknown
		
		do {
			session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
			builder = session?.associatedWorkoutBuilder()
		} catch {
			print("Erro ao iniciar sessão: \(error.localizedDescription)")
			return
		}
		
		session?.delegate = self
		builder?.delegate = self
		
		builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
													 workoutConfiguration: configuration)
		
		let startDate = Date()
		session?.startActivity(with: startDate)
		builder?.beginCollection(withStart: startDate) { (success, error) in }
	}
	
	// Encerramento manual pelo usuário
	func stopWorkout() {
		session?.stopActivity(with: Date())
	}
	
	func togglePause() {
		if running == true {
			self.pause()
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

		DispatchQueue.main.async {
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
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
		
		DispatchQueue.main.async {
			self.running = toState == .running
		}

		// Se o treino parou
		if toState == .stopped {
			builder?.endCollection(withEnd: date) { (success, error) in
				self.builder?.finishWorkout { (workout, error) in
					self.session?.end()
					DispatchQueue.main.async {
						self.workout = workout
					}
				}
			}
		}
	}

	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
		//
	}
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
	}

	func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
		for type in collectedTypes {
			guard let quantityType = type as? HKQuantityType else { return }
			let statistics = workoutBuilder.statistics(for: quantityType)
			updateForStatistics(statistics)
		}
	}
}
