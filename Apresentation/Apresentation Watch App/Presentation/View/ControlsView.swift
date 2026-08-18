//
//  ControlsView.swift
//  WorkoutSessionTest Watch App
//
//  Created by Ana Clara Ferreira Caldeira on 17/08/26.
//

import SwiftUI

struct ControlsView: View {
	@EnvironmentObject var workoutManager: WorkoutManager
	
	var body: some View {
		HStack {
			VStack {
				Button {
					workoutManager.stopWorkout()
				} label: {
					Image(systemName: "xmark")
				}
				.tint(.red)
				.font(.title2)
				Text("End")
			}
			VStack {
				Button {
					workoutManager.togglePause()
				} label: {
					Image(systemName: workoutManager.running ? "pause" : "play")
				}
				.tint(.yellow)
				.font(.title2)
				Text(workoutManager.running ? "Pause" : "Resume")
			}
		}
	}
}

#Preview {
    ControlsView()
}
