//
//  TimerRingView.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 19/08/26.
//
import SwiftUI

struct TimerRingView: View {
    
    @Binding var themeColor: Color
    
    @State private var progress: CGFloat = 0.0
    @State private var ringOpacity: Double = 1.0
    
    @State private var timerTask: Task<Void, Never>? = nil
    
    var body: some View {
        ZStack {
            // Trilha
            Circle()
                .stroke(lineWidth: 6)
                // Usamos a cor sólida com uma leve opacidade para o fundo
                .foregroundColor(themeColor.opacity(0.15))
                .animation(.easeInOut(duration: 0.3), value: themeColor)
            
            // progresso preenchendo
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(themeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .opacity(ringOpacity)
                .animation(.easeInOut(duration: 0.3), value: themeColor)
        }
        .onAppear {
            startTimerLoop()
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }
    
    private func startTimerLoop() {
        timerTask?.cancel()
        
        timerTask = Task {
            while !Task.isCancelled {
                progress = 0.0
                ringOpacity = 1.0
                
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
                
                progress = 0.0
                withAnimation(.easeIn(duration: 0.4)) {
                    ringOpacity = 1.0
                }
                
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
    }
}
