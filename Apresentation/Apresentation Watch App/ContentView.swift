//
//  ContentView.swift
//  Apresentation Watch App
//
//  Created by Ana Clara Ferreira Caldeira on 14/08/26.
//

import SwiftUI

struct ContentView: View {
    
    @State private var path: [AppRoute] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            StartView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                        case .ready: ReadyView(path:$path)
                        case .session: SessionTabView(path:$path)
                        case .config: ConfigView(path:$path)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
