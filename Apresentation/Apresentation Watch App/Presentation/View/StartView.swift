//
//  StartView.swift
//  NavigationWatchOs
//
//  Created by israel lacerda gomes santos on 18/08/26.
//

import SwiftUI


struct StartView: View {
    
    @Binding var path: [AppRoute]
    
    var body: some View {
        VStack(spacing: 10) {
            Button {
                path.append(.ready)
            }label: {
                HStack {
                    Image(systemName: "play")
                        .font(.body)
                    Text("Começar")
                        .font(.body)
                }
            }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            Button {
                path.append(.config)
            } label: {
                HStack {
                    Image(systemName: "gear")
                        .font(.body)
                    Text("Configurações")
                        .font(.body)
                }
            }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
        }
        .navigationTitle("Início")
    }
}
