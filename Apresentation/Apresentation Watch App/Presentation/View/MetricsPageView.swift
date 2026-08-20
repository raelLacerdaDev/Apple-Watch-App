//
//  MetricsPageView.swift
//  NavigationWatchOs
//
//  Created by israel lacerda gomes santos on 18/08/26.
//
import SwiftUI
internal import Combine

struct MetricsPageView: View {
    
    @State private var currentAudioLevel: CGFloat = 0.0
    @State private var isRecording = true
    let normalColor: Color = .blue
    let alertColor: Color = .yellow
    @State private var currentTheme: Color = .blue
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var rhythmViewModel = RhythmViewModel()
    
    
    // animacao de anel tive que elevar estado
    var progress: CGFloat
    var ringOpacity: Double
    
    // para teste alterar depois
    let audioTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // TODO: Remover simulador de palavras posteriormente (acionado a cada 1 segundo)
    let wordSimulatorTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                TimerRingView(themeColor: $currentTheme, progress: progress, ringOpacity: ringOpacity)
                    .frame(width: 120, height: 120)
                AudioSpectrumView(audioLevel: $currentAudioLevel, themeColor: $currentTheme)
            }
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundColor(.red)
                    VStack {
                        Text("\(workoutManager.heartRate, specifier: "%.0f")").font(.body.bold())
                        Text("bpm").font(.caption2)
                    }
                }
                HStack {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.purple)
                    VStack {
                        Text("\(rhythmViewModel.currentWPM)").font(.body.bold())
                        Text("ppm").font(.caption)
                    }
                }
            }.padding(.horizontal, 10)
        }
        // para teste alterar depois
        .onReceive(audioTimer) { _ in
            if isRecording {
                currentAudioLevel = CGFloat.random(in: 0.1...1.0)
            }
        }
        // TODO: Remover bloco do simulador posteriormente
        .onReceive(wordSimulatorTimer) { _ in
            if isRecording {
                // Simula 2 a 3 palavras por segundo para testar o limite acelerado vs no ritmo
                // 3 palavras/seg = 180 wpm (vai acelerar)
                // 2 palavras/seg = 120 wpm (volta pro pace)
                let simulatedWordCount = Int.random(in: 2...3)
                rhythmViewModel.didReceive(wordCount: simulatedWordCount)
            }
        }
        .onChange(of: rhythmViewModel.currentState) { oldValue, newValue in
            withAnimation {
                currentTheme = newValue == .onPace ? normalColor : alertColor
            }
        }
    }
}
