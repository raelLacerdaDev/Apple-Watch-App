//
//  TestView.swift
//  Apresentation
//
//  Created by Manoel Pedro Prado Sa Teles on 19/08/26.
//

import SwiftUI

struct TestView: View {
    @StateObject private var viewModel = PresentationViewModel()
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack {
                    Text("\(viewModel.peakCount)")
                        .font(.system(size: 40, weight: .bold))
                    Text("picos detectados")
                        .font(.caption)
                }
                
                VStack {
                    Text("\(viewModel.wordsPerMinute)")
                        .font(.system(size: 40, weight: .bold))
                    Text("WPM")
                        .font(.caption)
                }
            }
            
            Button(viewModel.state == .recording ? "Parar" : "Iniciar") {
                Task {
                    if viewModel.state == .recording {
                        viewModel.stopPresentation()
                    } else {
                        await viewModel.startPresentation()
                    }
                }
            }
            
//            Text(viewModel.speechPace.hashValue)
//                .font(.caption)

            if case let .error(message) = viewModel.state {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

#Preview {
    TestView()
}
