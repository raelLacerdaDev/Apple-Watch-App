//
//  SessionTabView.swift
//  NavigationWatchOs
//
//  Created by israel lacerda gomes santos on 18/08/26.
//

import SwiftUI

struct SessionTabView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject var workoutManager: WorkoutManager

    @State private var selectedTab = 1
    @StateObject private var timerManager = TimerManager()
    // Liga permissão de microfone + AudioPeakAnalyzer + MotionEnergyAnalyzer, entrega palavras/segundo.
    @StateObject private var captureManager = SpeechCaptureManager()
    // @Observable é tipo de valor de referência gerenciado pela View — @State é o jeito certo de guardar,
    // não @StateObject (isso é específico de ObservableObject/Combine).
    @State private var rhythmViewModel = RhythmViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            MetricsPageView(
                rhythmViewModel: rhythmViewModel,
                progress: timerManager.progress,
                ringOpacity: timerManager.ringOpacity
            )
            .tag(1)
            EndSessionPageView(path: $path)
                .tag(2)
        }
        .tabViewStyle(.page)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            timerManager.start()
            workoutManager.startWorkout()
        }
        .onDisappear {
            timerManager.stop()
            captureManager.stop()
            workoutManager.stopWorkout()
        }
        .task {
            // O RhythmViewModel consome o stream até a View sumir (SwiftUI cancela essa Task sozinho),
            // o que já dispara o onTermination do AsyncStream e encerra a captura de ponta a ponta.
            await rhythmViewModel.startListening(audioStream: captureManager.start())
        }
        // Vibra uma vez toda vez que o estado entra em "accelerated" — não faz nada ao entrar em
        // "onPace" (silêncio é o comportamento esperado, não precisa de alerta pra isso).
        .onChange(of: rhythmViewModel.currentState) { _, newState in
            guard newState == .accelerated else { return }
            HapticsManager.shared.play(.notification)
        }
    }
}
