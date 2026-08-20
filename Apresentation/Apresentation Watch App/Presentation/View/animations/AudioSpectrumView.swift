//
//  AudioSpectrumView.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 19/08/26.
//

import SwiftUI
internal import Combine

struct AudioSpectrumView: View {
    // 0.0 .. 1.0
    @Binding var audioLevel: CGFloat
    
    @Binding var themeColor: Color
    
    @State private var idlePhase: CGFloat = 0.0
    private let barMultipliers: [CGFloat] = [0.3, 0.6, 1.0, 0.6, 0.3]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barMultipliers.count, id: \.self) { index in
                let baseMultiplier = barMultipliers[index]
                
                let idleMovement = (sin(idlePhase + CGFloat(index)) + 1) / 2 * 0.15
                let activeLevel = audioLevel * baseMultiplier
                let finalLevel = max(idleMovement, activeLevel)
                
                Capsule()
                    .fill(themeColor)
                    .frame(width: 8, height: 10 + (finalLevel * 40))
                    .animation(.spring(response: 0.15, dampingFraction: 0.6), value: audioLevel)
                    .animation(.easeInOut(duration: 0.3), value: themeColor)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                idlePhase = .pi * 2
            }
        }
    }
}
