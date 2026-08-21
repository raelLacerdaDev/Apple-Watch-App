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
    
    enum SpeechPace {
        case ideal
        case acelerado
    }
    
    // Variáveis para atualizar a UI
    @Published private(set) var state: RRecordingState = .idle
    @Published private(set) var wordsPerMinute: Int = 0
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var speechPace: SpeechPace = .ideal
    @Published private(set) var peakCount: Int = 0
    
    private let permissions: PermissionsManager
    private let analyzer: AudioPeakAnalyzer
    private let syllablesPerWord: Double
    private let windowDuration: TimeInterval
    private let acceleratedThresholdWPM: Int
    
    private var startDate: Date?
    private var tickTask: Task<Void, Never>?
    
    init(
        permissions: PermissionsManager? = nil,
        analyzer: AudioPeakAnalyzer? = nil,
        syllablesPerWord: Double = 2.0,
        windowDuration: TimeInterval = 5.0, // Janela de tempo do cálculo de palavras por minuto
        acceleratedThresholdWPM: Int = 140 // Quantidade de palavras por minuto necessárias para ativar o modo acelerado
    ) {
        self.permissions = permissions ?? PermissionsManager()
        self.analyzer = analyzer ?? AudioPeakAnalyzer()
        self.syllablesPerWord = syllablesPerWord
        self.windowDuration = windowDuration
        self.acceleratedThresholdWPM = acceleratedThresholdWPM
    }
    
    func startPresentation() async {
        if permissions.microphoneStatus == .notDetermined {
            await permissions.requestMicrophone()
        }
        
        guard permissions.isAuthorized else {
            state = .error("Permissão de microfone negada")
            return
        }
        
        analyzer.reset()
        wordsPerMinute = 0
        elapsedSeconds = 0
        speechPace = .ideal
        peakCount = 0
        startDate = Date()
        
        do {
            try analyzer.start()
        } catch {
            state = .error(error.localizedDescription)
            return
        }
        
        state = .recording
        startTicking()
    }
    
    func stopPresentation() {
        analyzer.stop()
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
    
    private func tick() {
        guard let startDate else { return }
        
        let elapsed = Date().timeIntervalSince(startDate)
        elapsedSeconds = elapsed
        peakCount = analyzer.peakCount
        
        // Janela deslizante: filtra picos dos últimos 4 segundos
        let now = ProcessInfo.processInfo.systemUptime
        let recentPeaks = analyzer.recentPeakTimestamps.filter { now - $0 <= windowDuration }
        
        let effectiveWindow = max(min(elapsed, windowDuration), 1.0)

        // Cálculo temporal de WPM
        let words = Double(recentPeaks.count) / syllablesPerWord
        let minutes = effectiveWindow / 60.0
        let currentWPM = Int((words / minutes).rounded())
        
        // Lança o estado acelerado ou ideal
        wordsPerMinute = currentWPM
        speechPace = currentWPM >= acceleratedThresholdWPM ? .acelerado : .ideal
    }
    
}
