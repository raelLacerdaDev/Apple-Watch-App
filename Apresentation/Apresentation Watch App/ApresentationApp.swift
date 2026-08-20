//
//  ApresentationApp.swift
//  Apresentation Watch App
//
//  Created by Ana Clara Ferreira Caldeira on 14/08/26.
//

import SwiftUI

@main
struct Apresentation_Watch_AppApp: App {
	@StateObject private var workoutManager = WorkoutManager()

	@SceneBuilder var body: some Scene {
		WindowGroup {
			NavigationView {
				RouteView()
			}
			.environmentObject(workoutManager)
		}
	}
}
