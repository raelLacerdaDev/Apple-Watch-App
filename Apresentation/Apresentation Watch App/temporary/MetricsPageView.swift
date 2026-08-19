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
    
    //healthkit - infos
    @State private var bpm: Double = 82.0
    @State private var ppm: Double = 80.0
    
    // para teste alterar depois
    let audioTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            
            ZStack {
                TimerRingView(themeColor: $currentTheme)
                    .frame(width: 120, height: 120)
                AudioSpectrumView(audioLevel: $currentAudioLevel, themeColor: $currentTheme)
            }
            HStack {
                HStack {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundColor(.red)
                    VStack {
                        Text("\(bpm, specifier: "%.0f")").font(.body.bold())
                        Text("bpm").font(.caption2)
                    }
                }
                Spacer()
                HStack {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.purple)
                    VStack {
                        Text("\(ppm, specifier: "%.0f")").font(.body.bold())
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
    }
}
