//
//  TimerRingView.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 19/08/26.
//
import SwiftUI

struct TimerRingView: View {
    @Binding var themeColor: Color
    
    var progress: CGFloat
    var ringOpacity: Double
    
    var body: some View {
        ZStack {
            // Trilha
            Circle()
                .stroke(lineWidth: 6)
                .foregroundColor(themeColor.opacity(0.15))
                .animation(.easeInOut(duration: 0.3), value: themeColor)
            
            // Progresso preenchendo
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(themeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .opacity(ringOpacity)
                .animation(.easeInOut(duration: 0.3), value: themeColor)
        }
        
    }
}
