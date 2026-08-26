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
	// 10s conforme requisito (RN05/RN09/RF10/RF14) — também é o número de segundos consecutivos
	// acima do limite necessário pra disparar o estado "accelerated" (ver updateSpeechPace).
	let secondsWindowAnalysis = 10

	// Fator de calibração aplicado por cima do WPM calculado a partir dos picos de áudio. Mesmo
	// depois de afinar a sensibilidade do detector (peakToNoiseRatio/minimumAmplitudeThreshold em
	// AudioPeakAnalyzer), o valor exibido continuava abaixo do ritmo real percebido pelo usuário —
	// em vez de seguir caçando sensibilidade de captação (risco de pegar ruído como pico), corrige
	// direto na métrica final.
	// 1.5 calculado a partir de dado real de console: sessão de fala rápida mediu média ~118 ppm e
	// máximo 150 ppm com gain 1.25 — 1.25 * (180/150) = 1.5 pra levar o pico até a faixa esperada.
	let calibrationGain = 1.5

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
		let secondsToMinutes = 60.0 / Double(slidingWindow.count)
		currentWpm = Int(Double(totalWords) * secondsToMinutes * calibrationGain)
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
