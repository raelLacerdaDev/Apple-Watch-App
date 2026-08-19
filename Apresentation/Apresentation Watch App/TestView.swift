//
//  TestView.swift
//  Apresentation
//
//  Created by Manoel Pedro Prado Sa Teles on 19/08/26.
//

import SwiftUI

struct TestView: View {
    @StateObject private var permissions = PermissionsManager()
    @StateObject private var analyzer = AudioPeakAnalyzer()

    @State private var isRecording = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 8) {
            Text("\(analyzer.peakCount)")
                .font(.system(size: 40, weight: .bold))
            Text("picos detectados")
                .font(.caption)

            Button(isRecording ? "Parar" : "Iniciar") {
                toggleRecording()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .task {
            await permissions.requestMicrophone()
        }
    }

    private func toggleRecording() {
        guard permissions.isAuthorized else {
            errorMessage = "Permissão de microfone negada"
            return
        }

        if isRecording {
            analyzer.stop()
        } else {
            analyzer.reset()
            do {
                try analyzer.start()
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
        isRecording.toggle()
    }
}

#Preview {
    TestView()
}
