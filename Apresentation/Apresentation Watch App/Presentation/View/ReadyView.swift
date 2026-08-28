//
//  ReadyView.swift
//  NavigationWatchOs
//
//  Created by israel lacerda gomes santos on 18/08/26.
//

import SwiftUI
internal import Combine


struct ReadyView: View {
    
    @Binding var path: [AppRoute]
    @State private var countDown = 3
    let mode: SessionMode
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack (spacing: 10) {
            Text("Preparar")
                .font(.title)
            Text("\(countDown)")
                .font(.title)
        }
        .onReceive(timer) { _ in
            if countDown > 1 {
                countDown -= 1
            } else {
                timer.upstream.connect().cancel()
                
                if mode == .speech {
                    path = [.session]
                } else {
                    path = [.gestureSession]
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
