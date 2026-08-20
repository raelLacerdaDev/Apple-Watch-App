//
//  TimerManager.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 19/08/26.
//

import SwiftUI
internal import Combine

@MainActor
class TimerManager: ObservableObject {
    @Published var progress: CGFloat = 0.0
    @Published var ringOpacity: Double = 1.0
    
    private var timerTask: Task<Void, Never>? = nil
    
    func start() {
        
        guard timerTask == nil else { return }
        
        
        progress = 0.0
        ringOpacity = 1.0
        
        timerTask = Task {
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            while !Task.isCancelled {
                
                
                withAnimation(.linear(duration: 60)) {
                    progress = 1.0
                }
                
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                if Task.isCancelled { break }
                
                withAnimation(.easeOut(duration: 0.4)) {
                    ringOpacity = 0.0
                }
                
                try? await Task.sleep(nanoseconds: 400_000_000)
                if Task.isCancelled { break }
                
                withAnimation(nil) {
                    progress = 0.0
                }
                
                
                withAnimation(.easeIn(duration: 0.4)) {
                    ringOpacity = 1.0
                }
                
                try? await Task.sleep(nanoseconds: 400_000_000)
                if Task.isCancelled { break }
                
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
    
    func stop() {
        timerTask?.cancel()
        timerTask = nil
    }
}
