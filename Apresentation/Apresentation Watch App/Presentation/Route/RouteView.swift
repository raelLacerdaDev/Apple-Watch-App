//
//  ContentView.swift
//  Apresentation Watch App
//
//  Created by Ana Clara Ferreira Caldeira on 14/08/26.
//

import SwiftUI

struct RouteView: View {
    
    @State private var path: [AppRoute] = []
	@EnvironmentObject var workoutManager: WorkoutManager
	
	
    var body: some View {
        NavigationStack(path: $path) {
            StartView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                        case .ready(let selectedMode): ReadyView(path:$path, mode: selectedMode)
                        case .session: SessionTabView(path:$path)
                        case .config: ConfigView(path:$path)
                        case .mode: ModeView(path:$path)
                        case .gestureSession: GestureModeSession(path: $path)
                    }
                }
        }
		.task {
			await workoutManager.requestAuthorization()
		}
		// Atalho da complication do mostrador ("oratio://start") — pula direto pro countdown de
		// preparação, como se o usuário tivesse tocado em "Começar" na tela inicial.
		.onOpenURL { url in
			guard url.scheme == "oratio", url.host == "start" else { return }
			path = [.ready]
		}
    }
}

#Preview {
    RouteView()
}
