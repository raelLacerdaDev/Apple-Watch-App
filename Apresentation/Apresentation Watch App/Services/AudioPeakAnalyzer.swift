//
//  AudioPeakAnalyzer.swift
//  Apresentation
//
//  Created by Manoel Pedro Prado Sa Teles on 19/08/26.
//

import Foundation
import AVFoundation
import Accelerate // O framework de baixo nível da Apple para matemática vetorizada (SIMD): soma, RMS, FFT, filtros, otimizdo para um hardware de chip.
internal import Combine

final class AudioPeakAnalyzer: ObservableObject {
    
    @Published private(set) var peakCount: Int = 0
    @Published private(set) var currentRMS: Float = 0
    @Published private(set) var recentPeakTimestamps: [TimeInterval] = []
    
    private let audioEngine = AVAudioEngine()

    // Parâmetros da adaptação dinâmica de ruído
    private let minThreshold: Float
    private let sensitivityFactor: Float
    private let refractoryInterval: TimeInterval
    
    private var noiseFloor: Float = 0.0005
    private var peakEnvelope: Float = 0.01
    
    private var isAboveThreshold = false
    private var lastPeakTime: TimeInterval = 0
    
    init(
        minThreshold: Float = 0.0006,
        sensitivityFactor: Float = 0.22,
        refractoryInterval: TimeInterval = 0.09
    ) {
        self.minThreshold = minThreshold
        self.sensitivityFactor = sensitivityFactor
        self.refractoryInterval = refractoryInterval
    }
    
    
    func start() throws {
        
        // O audio engine trava com clique duplo
        guard !audioEngine.isRunning else { return }
        
        let session = AVAudioSession.sharedInstance()
        
        // Configura o que o app quer fazer com o áudio no sistema o record só grava e o measurement pede o dado cru para análise
        try session.setCategory(.record, mode: .measurement)
        try session.setActive(true)
        
        // Funciona como um grafo de nós de áudio conectado, pega o formato padrão do áudio
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
//        print("formato do input: \(format)")
        
        // Ponto de escuta no fluxo de áudio sem interferir nele, o audio flui normalmente, mas a cada 1024 amostras o closure é chamado.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format){
            [weak self] buffer, _ in
            self?.process(buffer)
        }
        
        // Antes de começar a captar o aúdio pré-aloca os recursos internos (buffers, threads de áudio) reduz a latência.
        audioEngine.prepare()
        
        try audioEngine.start()
        print("engine rodando: \(audioEngine.isRunning)")
    }
    
    //Primeiro remove o tap e depois desativa a sessão de aúdio e avisa que o a app liberou o uso exclusivo do aúdio.
    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        isAboveThreshold = false
    }
    
    // Zera o estado sem precisar destruir e recriar o objeto inteiro.
    func reset() {
        peakCount = 0
        lastPeakTime = 0
        isAboveThreshold = false
        noiseFloor = 0.0005
        peakEnvelope = 0.01
        currentRMS = 0
        recentPeakTimestamps.removeAll()
    }
    
    private func process(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else {
                print("floatChannelData é nil - formato do buffer: \(buffer.format)")
                return
            } // Guatda as amostras de áudio como ponteiros de memória crua, organizando por canal [0] primeiro canal
        
        // O vDSP_Length é uim tipo do Accelerate que espera um UInt32
        let frameLength = vDSP_Length(buffer.frameLength)
        
        // root mean square, é uma medida estatística usada para indicar o tamanho ou a força de um sinal que muda de valor com o tempo
        var rms: Float = 0
        
        // Calcula o RMS (root mean square) daquele pedaço de áudio matematicamente usando sqrt (média dos quadrados das amostras)
        // É a forma padão de medir energia/volume de um sinal de áudio
        vDSP_rmsqv(channelData, 1, &rms, frameLength)
        print("rms: \(rms)")
        
        // Há quanto tempo o sistema está ligado em segundos
        evaluatePeak(rms: rms, now: ProcessInfo.processInfo.systemUptime)
    }
    
    // Observa a linha do tempo do áudio, a cada buffer (23ms) essa função roda e decide se o momento do áudio está altou ou não
    private func evaluatePeak(rms: Float, now: TimeInterval) {
        // Atualiza a Média Móvel Exponencial (EMA) do ruído de fundo
        if rms < noiseFloor {
            noiseFloor = noiseFloor * 0.9 + rms * 0.1
        } else {
            noiseFloor = noiseFloor * 0.998 + rms * 0.002
        }
        
        // Atualiza o envelope de picos de voz recente
        if rms > peakEnvelope {
            peakEnvelope = rms
        } else {
            peakEnvelope = peakEnvelope * 0.98 + rms * 0.02
        }
        
        let dynamicThreshold = noiseFloor + max((peakEnvelope - noiseFloor) * sensitivityFactor, minThreshold)
        let isLoud = rms > dynamicThreshold

        // Vê se o som acabou de ficar alto
        if isLoud, !isAboveThreshold, now - lastPeakTime >= refractoryInterval {
            lastPeakTime = now
            
            // Toda vez que é identificado um pico é somado 1 no peakcount que vai contanto quantos momentos de pico teve
            // Além disso os timestamps dos picos também são salvos e o RMS é atualizado
            Task { @MainActor [weak self] in
                self?.peakCount += 1
                self?.currentRMS = rms
                self?.recentPeakTimestamps.append(now)
            }
        }
        
        isAboveThreshold = isLoud
    }
    
    
}
