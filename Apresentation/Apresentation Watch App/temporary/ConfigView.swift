//
//  ConfigView.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 19/08/26.
//

import SwiftUI

struct ConfigView: View {
    
    @Binding var path: [AppRoute]
    @State private var ppm: CGFloat = 80
    
    var body: some View {
        HStack {
            Button {
                ppm -= 1
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            
            Spacer()
            
            VStack {
                Text("\(ppm, specifier: "%.0f")")
                    .font(.title)
                Text("ppm")
                    .font(.caption)
            }
            
            Spacer()
            
            Button {
                ppm += 1
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
        }
    }
}

