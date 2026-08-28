//
//  SpeechCaptureManager.swift
//  Apresentation
//
//  Created by Manoel Pedro Prado Sa Teles on 21/08/26.
//

import Foundation
internal import Combine

// Liga permissão de microfone + AudioPeakAnalyzer + MotionEnergyAnalyzer, e entrega o resultado
// como um AsyncStream<Int> de palavras-por-segundo, no formato que RhythmViewModel.startListening já espera.
@MainActor
final class SpeechCaptureManager: ObservableObject {

    @Published private(set) var errorMessage: String?

    private let permissions: PermissionsManager
    private let audioAnalyzer: AudioPeakAnalyzer
    private let motionAnalyzer: MotionEnergyAnalyzer
    private let syllablesPerWord: Double

    private var lastPeakCount = 0
    // Sobra fracionária da conversão pico→palavra que não formou uma palavra inteira ainda.
    // Sem isso, um segundo com 1 pico (0.45 palavra a 2.2 sílabas/palavra) arredondava pra 0
    // e a fração era descartada — silêncio "fantasma" mesmo com fala real acontecendo.
    private var wordRemainder: Double = 0
    private var captureTask: Task<Void, Never>?

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

    // Devolve o stream pronto pra RhythmViewModel.startListening(audioStream:) consumir.
    func start() -> AsyncStream<Int> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            self.captureTask = Task { [weak self] in
                await self?.runCaptureLoop(continuation: continuation)
                continuation.finish()
            }

            continuation.onTermination = { [weak self] _ in
                // Resolve o self fraco pra uma constante local ANTES de entrar na Task —
                // capturar "weak self" direto numa closure concorrente vira warning
                // ("captured var"), porque uma referência weak é mutável por baixo dos panos.
                guard let self else { return }
                Task { @MainActor in
                    self.captureTask?.cancel()
                }
            }
        }
    }

    func stop() {
        captureTask?.cancel()
    }

    private func runCaptureLoop(continuation: AsyncStream<Int>.Continuation) async {
        errorMessage = nil

        if permissions.microphoneStatus == .notDetermined {
            await permissions.requestMicrophone()
        }

        guard permissions.isAuthorized else {
            errorMessage = "Permissão de microfone negada"
            return
        }

        audioAnalyzer.reset()
        motionAnalyzer.reset()
        lastPeakCount = 0
        wordRemainder = 0

        do {
            try audioAnalyzer.start()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        // Se o sensor de movimento falhar depois que o áudio já começou, desliga o áudio também.
        do {
            try motionAnalyzer.start()
        } catch {
            audioAnalyzer.stop()
            errorMessage = error.localizedDescription
            return
        }

        defer {
            audioAnalyzer.stop()
            motionAnalyzer.stop()
        }

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { break }

            // Repassa a posição do braço pro audio trocar de perfil de threshold em tempo real.
            audioAnalyzer.setArmExtended(motionAnalyzer.isArmExtended)

            let peakCount = audioAnalyzer.peakCount
            let peakDelta = peakCount - lastPeakCount
            lastPeakCount = peakCount

            // Converte picos (proxy de sílaba) em palavras antes de entregar — evita acoplar o
            // targetWpm do RhythmViewModel à nossa constante interna de sílabas por palavra.
            //
            // O resto da divisão não é descartado: soma no wordRemainder e carrega pro próximo
            // segundo. Sem isso, segundos com poucos picos (ex.: 1 pico = 0.45 palavra) arredondavam
            // sempre pra 0 e a fração sumia — silêncio "fantasma" na UI mesmo com fala real.
            let wordsThisSecond = Double(peakDelta) / syllablesPerWord + wordRemainder
            let wholeWords = Int(wordsThisSecond)
            wordRemainder = wordsThisSecond - Double(wholeWords)

            continuation.yield(wholeWords)
        }
    }
}
