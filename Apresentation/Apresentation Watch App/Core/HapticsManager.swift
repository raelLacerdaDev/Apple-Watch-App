//
//  HapticsManager.swift
//  Apresentation Watch App
//
//  Created by Rodrigo Barbosa Pereira on 19/08/26.
//

import Foundation
import WatchKit
internal import Combine

@MainActor
final class HapticsManager: ObservableObject {
    
    static let shared = HapticsManager()
    
    @Published private(set) var isLooping: Bool = false
    
    // Task assíncrona responsável pelo loop ativo
    private var loopTask: Task<Void, Never>?
    
    init() {}
    
    deinit {
        loopTask?.cancel()
    }
    
    // MARK: - Função Principal
    
    /// Toca um haptic no Apple Watch.
    /// - Parameters:
    ///   - type: Tipo do haptic (`WKHapticType`). Default: `.notification`.
    ///   - loop: Se `true`, repete a execução do haptic em loop. Default: `false`.
    ///   - interval: O tempo de espera em segundos entre cada toque no modo loop. Default: `1.0`.
    ///   - count: Quantidade limite de repetições. Se `nil` e `loop == true`, repetirá infinitamente até chamar `stopLoop()`.
    func play(
        _ type: WKHapticType = .notification,
        loop: Bool = false,
        interval: TimeInterval = 1.0,
        count: Int? = nil
    ) {
        // Cancela qualquer loop anterior ativo
        stopLoop()
        
        if loop {
            startLoop(type: type, interval: interval, count: count)
        } else {
            WKInterfaceDevice.current().play(type)
        }
    }
        
    func stopLoop() {
        loopTask?.cancel()
        loopTask = nil
        isLooping = false
    }
        
    private func startLoop(type: WKHapticType, interval: TimeInterval, count: Int?) {
        isLooping = true
        
        loopTask = Task { [weak self] in
            var currentCount = 0
            
            while !Task.isCancelled {
                WKInterfaceDevice.current().play(type)
                currentCount += 1
                
                if let count = count, currentCount >= count {
                    break
                }
                
                let nanoseconds = UInt64(max(0.05, interval) * 1_000_000_000)
                do {
                    try await Task.sleep(nanoseconds: nanoseconds)
                } catch {
                    break
                }
            }
            
            self?.finishLoop()
        }
    }
    
    private func finishLoop() {
        isLooping = false
        loopTask = nil
    }
    
    // MARK: - Padrões de Haptics (Patterns)
    
    /// Reproduz uma sequência  customizada de haptics.
    /// - Parameters:
    ///   - pattern: Array de tuplas `(type: WKHapticType, delayAfter: TimeInterval)`.
    ///   - loop: Se `true`, repetirá o padrão completo continuamente. Default: `false`.
    func playPattern(_ pattern: [(type: WKHapticType, delayAfter: TimeInterval)], loop: Bool = false) {
        stopLoop()
        
        guard !pattern.isEmpty else { return }
        
        if loop {
            isLooping = true
            loopTask = Task { [weak self] in
                while !Task.isCancelled {
                    for item in pattern {
                        if Task.isCancelled { break }
                        WKInterfaceDevice.current().play(item.type)
                        
                        let nanoseconds = UInt64(max(0.05, item.delayAfter) * 1_000_000_000)
                        do {
                            try await Task.sleep(nanoseconds: nanoseconds)
                        } catch {
                            break
                        }
                    }
                }
                self?.finishLoop()
            }
        } else {
            Task {
                for item in pattern {
                    WKInterfaceDevice.current().play(item.type)
                    let nanoseconds = UInt64(max(0.05, item.delayAfter) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: nanoseconds)
                }
            }
        }
    }    
}
