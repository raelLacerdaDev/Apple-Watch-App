//
//  GestureModeView.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 26/08/26.
//
import SwiftUI


struct GestureModeView: View {
    @Binding var path: [AppRoute]
    var body: some View {
        ZStack(alignment: .center) {
            HStack (spacing: 8){
                Image(systemName: "hand.raised")
                    .font(.title2)
                Text("Faça isso ...")
                    .font(.title2)
            }
        }
    }
}



