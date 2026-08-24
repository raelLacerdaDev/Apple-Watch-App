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
            HapticsManager.shared.stopLoop() // O loop de haptics estava rodando fora da tela de apresentação
        }
        .task {
            // O RhythmViewModel consome o stream até a View sumir (SwiftUI cancela essa Task sozinho),
            // o que já dispara o onTermination do AsyncStream e encerra a captura de ponta a ponta.
            await rhythmViewModel.startListening(audioStream: captureManager.start())
        }
        // Enquanto o estado for "accelerated" o haptic vibra em loop (a cada 2s) até voltar pro
        // ritmo normal — antes disparava só uma vez na transição e nunca mais, mesmo que a pessoa
        // continuasse falando rápido por vários segundos.
        .onChange(of: rhythmViewModel.currentState) { _, newState in
            switch newState {
            case .accelerated:
                HapticsManager.shared.play(.notification, loop: true, interval: 2.0)
            case .onPace:
                HapticsManager.shared.stopLoop()
            }
        }
    }
}
