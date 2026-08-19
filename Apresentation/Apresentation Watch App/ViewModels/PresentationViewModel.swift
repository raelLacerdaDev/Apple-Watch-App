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
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    
    private let permissions: PermissionsManager
    private let analyzer: AudioPeakAnalyzer
    private let syllablesPerWord: Double
    
    private var startDate: Date?
    private var tickTask: Task<Void, Never>?
    
    init(
        permissions: PermissionsManager? = nil,
        analyzer: AudioPeakAnalyzer? = nil,
        syllablesPerWord: Double = 2.2
    ) {
        self.permissions = permissions ?? PermissionsManager()
        self.analyzer = analyzer ?? AudioPeakAnalyzer()
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
        
        analyzer.reset()
        wordsPerMinute = 0
        elapsedSeconds = 0
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
        
        guard elapsed >= 2 else { return }
        
        let words = Double(analyzer.peakCount) / syllablesPerWord
        let minutes = elapsed / 60
        wordsPerMinute = Int((words / minutes).rounded())
    }
    
}
