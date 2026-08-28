//
//  ModeView.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 26/08/26.
//

import SwiftUI

struct ModeView : View {
    
    @Binding var path: [AppRoute]
    
    var body: some View {
        VStack (spacing: 10){
            Button {
                path.append(.ready(mode: .speech))
            }label: {
                HStack {
                    Image(systemName: "microphone")
                        .font(.body)
                    Text("Modo Fala")
                        .font(.body)
                }
            }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            
            Button {
                path.append(.ready(mode: .gesture))
            }label: {
                HStack {
                    Image(systemName: "hand.palm.facing")
                        .font(.body)
                    Text("Modo Gesto")
                        .font(.body)
                }
            }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
    }
}
