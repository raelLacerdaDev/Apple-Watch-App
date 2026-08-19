//
//  SessionTabView.swift
//  NavigationWatchOs
//
//  Created by israel lacerda gomes santos on 18/08/26.
//

import SwiftUI

struct SessionTabView: View {
    @Binding var path: [AppRoute]
    
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            MetricsPageView()
                .tag(1)
            EndSessionPageView(path: $path)
                .tag(2)
        }
        .tabViewStyle(.page)
        .navigationBarBackButtonHidden(true)
    }
}
