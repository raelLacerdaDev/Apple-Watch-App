//
//  GestureModeView.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 26/08/26.
//
import SwiftUI
import WatchKit

struct GestureModeView: View {
    @Binding var path: [AppRoute]
    @State private var session = WKExtendedRuntimeSession()
    
    var body: some View {
        ZStack(alignment: .center) {
            HStack (spacing: 8){
                Image(systemName: "hand.raised")
                    .font(.title2)
                Text("Faça isso ...")
                    .font(.title2)
            }
            Button(action: {
                HapticsManager.shared.play(.notification)
            }) {
                Color.clear
            }
            .buttonStyle(PlainButtonStyle())
            .handGestureShortcut(.primaryAction)
        }
        .onAppear() { session.start() }
        .onDisappear() { session.invalidate() }
    }
}
