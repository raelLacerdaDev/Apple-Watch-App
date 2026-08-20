//
//  ContentView.swift
//  Apresentation Watch App
//
//  Created by Ana Clara Ferreira Caldeira on 14/08/26.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var workoutManager: WorkoutManager
//    @EnvironmentObject var hapticsManager: HapticsManager
	
	var body: some View {
		VStack {
			Text("Hello word")
            
//            Button("Testar Haptics") {
//                HapticsManager.shared.play(.directionUp, loop: true, interval: 0.8, count: 5)
//            }
		}
		.padding()
		.task {
			await workoutManager.requestAuthorization()
        }
	}
}

#Preview {
    ContentView()
}
