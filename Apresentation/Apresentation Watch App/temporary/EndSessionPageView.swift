//
//  EndSessionPageView.swift
//  NavigationWatchOs
//
//  Created by israel lacerda gomes santos on 18/08/26.
//

import SwiftUI

struct EndSessionPageView: View {
    
    @Binding var path: [AppRoute]
    
    var body: some View {
        VStack(spacing: 16) {
            Button {
                path.removeAll()
            } label: {
                HStack (spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headline)
                    Text("Finalizar")
                        .font(.headline)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}
