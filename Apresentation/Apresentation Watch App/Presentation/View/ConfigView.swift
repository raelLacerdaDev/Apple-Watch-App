//
//  ConfigView.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 19/08/26.
//

import SwiftUI

struct ConfigView: View {
    
    @Binding var path: [AppRoute]
    @AppStorage("targetWPM") private var ppm: Int = 130
    
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
                Text("\(ppm)")
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

