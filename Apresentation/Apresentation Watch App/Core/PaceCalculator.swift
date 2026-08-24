//
//  PaceCalculatore.swift
//  Apresentation
//
//  Created by Ana Clara Ferreira Caldeira on 19/08/26.
//
import Foundation

protocol SpeechPaceCalculable {
	var currentState: SpeechState { get }
	var currentWPM: Int { get }
	
	mutating func process(wordsInLastSecond wordCount: Int)
}

struct PaceCalculator {
	let targetWpm: Int
	var upperLimit: Int { targetWpm + 5 }
	
	init(targetWpm: Int? = nil) {
		if let target = targetWpm {
			self.targetWpm = target
		} else {
			let savedTarget = UserDefaults.standard.integer(forKey: "targetWPM")
			self.targetWpm = savedTarget > 0 ? savedTarget : 130
		}
	}
	
	private var upperLimitSeconds = 0
	private var silenceSeconds = 0
	
	private var slidingWindow: [Int] = []
	
	let silenceLimit = 10
	let secondsWindowAnalysis = 10
	
	private(set) var currentWpm = 0
	private(set) var currentState: SpeechState = .onPace
	
	mutating func process(wordCount: Int) -> (wpm: Int, speechState: SpeechState) {
		// Verifica: esta em silencio por 10 segundos. Existem pausas longas?
		silenceSeconds = (wordCount == 0) ? silenceSeconds + 1 : 0
		guard silenceSeconds < silenceLimit else { return (currentWpm, currentState) }
		
		// Renova a janela a ser analisada pela nova janela de 10 segundos
		slidingWindow.append(wordCount)
		if slidingWindow.count > secondsWindowAnalysis {
			slidingWindow.removeFirst()
		}
		
		// Calcula o novo ritmo e atualiza o estado de acordo com o novo calculo
		calcuteWpm()
		updateSpeechPace()
		
		return (currentWpm, currentState)
	}
	
	private mutating func calcuteWpm() {
		// Verifica se a nova janela nao esta vazia
		guard !slidingWindow.isEmpty else { return }
		
		// Calcula se a media
		let totalWords = slidingWindow.reduce(0, +)
		let multiplier = 60.0 / Double(slidingWindow.count)
		currentWpm = Int(Double(totalWords) * multiplier)
	}
	
	private mutating func updateSpeechPace() {
		// Observa caso o batimento esteja alterado para confirmar por mais tempo e devolve pro usuario o novo estado
		// Se esta no ritmo pula pro proximo segundo
		
		switch currentState {
		case .onPace:
			upperLimitSeconds = (currentWpm > upperLimit) ? upperLimitSeconds + 1 : 0
			
			if upperLimitSeconds >= secondsWindowAnalysis {
				currentState = .accelerated
				upperLimitSeconds = 0
			}
			
		case .accelerated:
			if currentWpm <= upperLimit - 5 {
				currentState = .onPace
			}
		}
	}
}
