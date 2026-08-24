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
    
    // 
    @Published private(set) var peakCount: Int = 0
    
    private let audioEngine = AVAudioEngine()

    // Piso mínimo do threshold, evita que ele caia perto de zero num ambiente completamente silencioso
    // (nesse caso o próprio ruído do sensor/mic já dispararia picos falsos).
    private let minimumAmplitudeThreshold: Float

    // Quantas vezes acima do piso de ruído o som precisa estar pra virar pico. Ex: 2.5 = precisa estar 150% mais alto que o ambiente.
    private let peakToNoiseRatio: Float

    // Ratio mais permissivo, usado só quando o MotionEnergyAnalyzer avisa que o braço está esticado.
    // Calibrado com dado real: mesmo esticado o sinal de fala raramente passa de ~1.8x o ruído de fundo
    // (contra os >2x fáceis de ver perto do rosto), então um ratio mais alto que isso nunca dispararia nada.
    private let extendedArmPeakToNoiseRatio: Float

    // Quão rápido o piso de ruído CAI quando o ambiente fica mais quieto que o piso atual.
    // Rápido de propósito: uma pausa real na fala precisa recalibrar o piso pra baixo sem demora.
    private let noiseFloorFallSmoothing: Float

    // Quão rápido o piso de ruído SOBE quando algo fica mais alto que o piso atual, mas ainda abaixo do threshold.
    // Bem mais devagar que a queda: numa fala rápida e contínua quase não existe silêncio de verdade entre
    // sílabas (o que sobra é resquício da própria fala, não ruído de ambiente). Se o piso subisse na mesma
    // velocidade que desce, uma fala contínua ia empurrar o próprio piso pra cima ao longo da sessão,
    // subindo o threshold e dificultando cada vez mais detectar a sílaba seguinte — um ciclo que se
    // autoalimenta e piora justamente quando a pessoa fala mais rápido e sem pausa.
    private let noiseFloorRiseSmoothing: Float

    private let refractoryInterval: TimeInterval

    // Estimativa do "ruído de fundo" do ambiente, atualizada continuamente enquanto o som está quieto.
    private var noiseFloor: Float

    // Atualizado externamente (pelo PresentationViewModel/TestView) a partir do MotionEnergyAnalyzer.isArmExtended.
    private var isArmExtended = false

    private var isAboveThreshold = false
    private var lastPeakTime: TimeInterval = 0

    // RMS do buffer anterior e se o envelope estava subindo — usados pra achar o máximo local
    // de cada sílaba (ver comentário em evaluatePeak).
    private var previousRms: Float = 0
    private var isRising = false

    //
    init(
        minimumAmplitudeThreshold: Float = 0.0015,
        peakToNoiseRatio: Float = 1.5,
        extendedArmPeakToNoiseRatio: Float = 1.2,
        noiseFloorFallSmoothing: Float = 0.02,
        noiseFloorRiseSmoothing: Float = 0.002,
        refractoryInterval: TimeInterval = 0.12
    ) {
        self.minimumAmplitudeThreshold = minimumAmplitudeThreshold
        self.peakToNoiseRatio = peakToNoiseRatio
        self.extendedArmPeakToNoiseRatio = extendedArmPeakToNoiseRatio
        self.noiseFloorFallSmoothing = noiseFloorFallSmoothing
        self.noiseFloorRiseSmoothing = noiseFloorRiseSmoothing
        self.refractoryInterval = refractoryInterval
        self.noiseFloor = minimumAmplitudeThreshold
    }

    // Chamado a cada leitura de posição do MotionEnergyAnalyzer, pra trocar de perfil de threshold em tempo real.
    func setArmExtended(_ extended: Bool) {
        isArmExtended = extended
    }

    
    func start() throws {
        
        // O audio engine trava com clique duplo
        guard !audioEngine.isRunning else { return }
        
        let session = AVAudioSession.sharedInstance()

        // Voltamos pra .measurement: testamos .voiceChat + setVoiceProcessingEnabled(true) e a unidade
        // de voice processing do sistema falhou constantemente (render err: -1 em praticamente todo buffer),
        // entregando amostras não confiáveis. .measurement não tem AGC, mas pelo menos é estável.
        try session.setCategory(.record, mode: .measurement)
        try session.setActive(true)

        // Funciona como um grafo de nós de áudio conectado, pega o formato padrão do áudio
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        print("formato do input: \(format)")
        
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
        noiseFloor = minimumAmplitudeThreshold
        isArmExtended = false
        previousRms = 0
        isRising = false
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
        
        // Há quanto tempo o sistema está ligado em segundos
        evaluatePeak(rms: rms, now: ProcessInfo.processInfo.systemUptime)
        
    }
    
    // Observa a linha do tempo do áudio, a cada buffer (23ms) essa função roda e decide se o momento do áudio está altou ou não
    private func evaluatePeak(rms: Float, now: TimeInterval) {
        // O threshold é relativo ao ruído do ambiente (noiseFloor), não mais um número fixo.
        // Com o braço esticado usa o ratio mais permissivo — o sinal chega mais fraco e o ratio padrão nunca dispararia.
        // O max() com minimumAmplitudeThreshold impede que o threshold desabe demais numa sala completamente silenciosa.
        let ratio = isArmExtended ? extendedArmPeakToNoiseRatio : peakToNoiseRatio
        let threshold = max(noiseFloor * ratio, minimumAmplitudeThreshold)
        let isLoud = rms > threshold

        // Log temporário pra calibrar os thresholds com dado real (perto vs. longe da boca, sala quieta vs. barulhenta).
        // Remover depois que os valores default estiverem calibrados.
        print("rms: \(rms) | noiseFloor: \(noiseFloor) | threshold: \(threshold) | isArmExtended: \(isArmExtended) | isLoud: \(isLoud)")

        let currentlyRising = rms > previousRms

        // Conta o pico no MÁXIMO LOCAL (quando o envelope para de subir e começa a cair), não na
        // borda de subida do threshold. Antes, contar na borda de subida fazia fala rápida/contínua
        // subestimar o WPM: em fala corrida o RMS quase nunca cai de volta abaixo do threshold entre
        // sílabas, então várias sílabas ficavam grudadas num único platô "alto" e viravam 1 pico só —
        // quanto mais rápido a pessoa falava, MENOS picos por segundo eram detectados. Olhando pro
        // máximo local em vez da borda, cada sílaba conta separadamente mesmo dentro de um platô
        // contínuo, porque o envelope ainda sobe e desce sílaba a sílaba.
        if isLoud, isAboveThreshold, isRising, !currentlyRising, now - lastPeakTime >= refractoryInterval {
            lastPeakTime = now

            Task { @MainActor [weak self] in
                self?.peakCount += 1
            }
        }
        isRising = isLoud && currentlyRising

        // Só atualiza o piso de ruído enquanto o som está quieto — se atualizasse durante a fala,
        // o próprio piso subiria junto com a voz e o detector ia parar de reconhecer picos numa fala contínua.
        // Sobe devagar (noiseFloorRiseSmoothing), desce rápido (noiseFloorFallSmoothing) — ver comentário
        // nas propriedades pra entender por que essa assimetria importa.
        if !isLoud {
            let smoothing = rms > noiseFloor ? noiseFloorRiseSmoothing : noiseFloorFallSmoothing
            noiseFloor += (rms - noiseFloor) * smoothing
        }

        isAboveThreshold = isLoud
        previousRms = rms
    }
    
    
}
