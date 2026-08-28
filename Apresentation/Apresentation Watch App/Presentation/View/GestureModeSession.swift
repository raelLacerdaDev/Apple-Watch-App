//
//  GestureModeSession.swift
//  Apresentation
//
//  Created by israel lacerda gomes santos on 26/08/26.
//


import SwiftUI

struct GestureModeSession: View {
    @Binding var path: [AppRoute]
    @State private var selectedTab = 1
    var body: some View {
        TabView(selection: $selectedTab) {
            GestureModeView(path: $path)
            .tag(1)
            EndSessionPageView(path: $path)
            .tag(2)
        }
        .tabViewStyle(.page)
        .navigationBarBackButtonHidden(true)
    }
}
