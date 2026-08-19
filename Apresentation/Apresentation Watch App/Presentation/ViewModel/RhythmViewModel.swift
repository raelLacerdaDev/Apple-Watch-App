//
//  RhythmViewModel.swift
//  Apresentation
//
//  Created by Ana Clara Ferreira Caldeira on 19/08/26.
//

import SwiftUI
import Observation

@Observable
final class RhythmViewModel {

	private(set) var currentWPM: Int = 0
    private(set) var currentState: SpeechState = .onPace
    
    // Encapsula o motor de cálculo
    private var calculator: PaceCalculator
    
    init(calculator: PaceCalculator = PaceCalculator()) {
        self.calculator = calculator
    }
    
    // equipe de captura de áudio chama para cada segundo
    func didReceive(wordCount: Int) {
        // Processa o dado no motor matemático
        let result = calculator.process(wordCount: wordCount)
        
        // Atualiza a View reativamente
        self.currentWPM = result.wpm
        self.currentState = result.speechState
    }
    
    // Se a equipe de áudio fornecer um fluxo contínuo (AsyncStream), o ViewModel gerencia a Task
    func startListening(audioStream: AsyncStream<Int>) async {
        for await wordCount in audioStream {
            didReceive(wordCount: wordCount)
        }
    }
}
