//
//  ContentView.swift
//  Apresentation Watch App
//
//  Created by Ana Clara Ferreira Caldeira on 14/08/26.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var workoutManager: WorkoutManager
	
	var body: some View {
		VStack {
			Text("Hello word")
		}
		.padding()
		.onAppear {
			workoutManager.requestAuthorization()
		}
	}
}

#Preview {
    ContentView()
}
