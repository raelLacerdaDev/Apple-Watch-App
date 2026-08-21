//
//  PresentationViewModel.swift
//  Apresentation
//
//  Created by Manoel Pedro Prado Sa Teles on 19/08/26.
//

import Foundation
internal import Combine

@MainActor
final class PresentationViewModel: ObservableObject {

    enum RRecordingState: Equatable {
        case idle
        case recording
        case error(String)
    }

    @Published private(set) var state: RRecordingState = .idle
    @Published private(set) var wordsPerMinute: Int = 0
    // Energia de movimento acumulada dividida pelos minutos decorridos, mesma ideia do wordsPerMinute, mas pro braço.
    @Published private(set) var movementIntensityPerMinute: Double = 0
    @Published private(set) var elapsedSeconds: TimeInterval = 0

    private let permissions: PermissionsManager
    private let audioAnalyzer: AudioPeakAnalyzer
    // Serviço isolado que só sabe captar movimento do pulso, não sabe nada sobre áudio nem sobre a apresentação em si.
    private let motionAnalyzer: MotionEnergyAnalyzer
    private let syllablesPerWord: Double

    private var startDate: Date?
    private var tickTask: Task<Void, Never>?

    init(
        permissions: PermissionsManager? = nil,
        audioAnalyzer: AudioPeakAnalyzer? = nil,
        motionAnalyzer: MotionEnergyAnalyzer? = nil,
        syllablesPerWord: Double = 2.2
    ) {
        self.permissions = permissions ?? PermissionsManager()
        self.audioAnalyzer = audioAnalyzer ?? AudioPeakAnalyzer()
        self.motionAnalyzer = motionAnalyzer ?? MotionEnergyAnalyzer()
        self.syllablesPerWord = syllablesPerWord
    }

    func startPresentation() async {
        if permissions.microphoneStatus == .notDetermined {
            await permissions.requestMicrophone()
        }

        guard permissions.isAuthorized else {
            state = .error("Permissão de microfone negada")
            return
        }

        audioAnalyzer.reset()
        motionAnalyzer.reset()
        wordsPerMinute = 0
        movementIntensityPerMinute = 0
        elapsedSeconds = 0
        startDate = Date()

        do {
            try audioAnalyzer.start()
        } catch {
            state = .error(error.localizedDescription)
            return
        }

        // Se o sensor de movimento falhar depois que o áudio já começou, desliga o áudio também.
        // Sem esse rollback o microfone ficaria gravando sozinho com a apresentação em estado de erro.
        do {
            try motionAnalyzer.start()
        } catch {
            audioAnalyzer.stop()
            state = .error(error.localizedDescription)
            return
        }

        state = .recording
        startTicking()
    }

    func stopPresentation() {
        audioAnalyzer.stop()
        motionAnalyzer.stop()
        tickTask?.cancel()
        tickTask = nil
        startDate = nil
        state = .idle
    }

    private func startTicking() {
        tickTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                self.tick()
            }
        }
    }

    // Um único tick calcula as duas métricas usando o mesmo elapsed/minutes,
    // assim wordsPerMinute e movementIntensityPerMinute nunca ficam dessincronizados entre si.
    private func tick() {
        guard let startDate else { return }

        let elapsed = Date().timeIntervalSince(startDate)
        elapsedSeconds = elapsed

        guard elapsed >= 2 else { return }

        // Repassa a posição do braço detectada pelo motion pro audio, pra ele trocar de perfil de threshold.
        audioAnalyzer.setArmExtended(motionAnalyzer.isArmExtended)

        let minutes = elapsed / 60

        let words = Double(audioAnalyzer.peakCount) / syllablesPerWord
        wordsPerMinute = Int((words / minutes).rounded())

        // Normaliza o acumulador cru do MotionEnergyAnalyzer pelo tempo decorrido,
        // pra dar pra comparar apresentações de durações diferentes.
        movementIntensityPerMinute = motionAnalyzer.totalMovementEnergy / minutes
    }

}
