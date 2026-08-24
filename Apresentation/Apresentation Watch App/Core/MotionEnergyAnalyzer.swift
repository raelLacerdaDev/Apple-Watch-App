//
//  MotionEnergyAnalyzer.swift
//  Apresentation
//
//  Created by Manoel Pedro Prado Sa Teles on 20/08/26.
//

import Foundation
import CoreMotion
internal import Combine

final class MotionEnergyAnalyzer: ObservableObject {
    // Soma da energia captada na sessão de movimento do braço.
    // Não é uma distância fixa e mmetros é um valor relativo de intesidade de gesticulação
    @Published private(set) var totalMovementEnergy: Double = 0

    // true quando o braço está esticado (longe do rosto), calculado a partir do vetor de gravidade.
    // Calibrado com dado real: gravity.z fica perto de -1 com o braço perto do rosto,
    // e sobe pra perto de -0.15/-0.2 com o braço esticado.
    @Published private(set) var isArmExtended: Bool = false

    // Usa o motion manager para pegar o movimento do braço
    private let motionManager = CMMotionManager()

    // De quanto em quanto tempo o sistema deve entregar uma nova leitura
    private let updateInterval: TimeInterval

    // Suaviza gravity.z (média móvel exponencial) pra não reagir a um solavanco isolado, só a uma posição sustentada.
    private let gravityZSmoothing: Double
    private var smoothedGravityZ: Double = -1

    // Histerese: dois limiares diferentes pra entrar e sair de "esticado", evitando ficar trocando de estado
    // toda hora quando o braço está numa posição intermediária.
    private let armExtendedThreshold: Double
    private let armCloseThreshold: Double

    // Debounce por amostras consecutivas: só troca isArmExtended depois que o candidato bater esse número
    // de vezes seguidas. Mesma técnica usada antes pro role falante/plateia, agora aplicada aqui.
    // Como process() roda a ~50Hz, 15 amostras ≈ 300ms de posição sustentada antes de trocar.
    private let armPositionDebounceSamples: Int
    private var pendingArmExtended: Bool?
    private var pendingArmExtendedStreak: Int = 0

    enum MotionError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Sensor de movimento não disponível"
            }
        }
    }

    // O valor default é de 50Hz (50 leituras por segundo, é o número mais alto de captura de movimento que o sistema consegue responder.
    init(
        updateInterval: TimeInterval = 1.0 / 50.0,
        gravityZSmoothing: Double = 0.1,
        armExtendedThreshold: Double = -0.5,
        armCloseThreshold: Double = -0.75,
        armPositionDebounceSamples: Int = 15
    ) {
        self.updateInterval = updateInterval
        self.gravityZSmoothing = gravityZSmoothing
        self.armExtendedThreshold = armExtendedThreshold
        self.armCloseThreshold = armCloseThreshold
        self.armPositionDebounceSamples = armPositionDebounceSamples
    }
    
    func start() throws {
        guard motionManager.isDeviceMotionAvailable else {
            throw MotionError.unavailable
        }
        guard !motionManager.isDeviceMotionActive else { return }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        
        // O sistema vai monitorar o movimento do braço repetidamente.
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.process(motion)
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func reset() {
        totalMovementEnergy = 0
        smoothedGravityZ = -1
        isArmExtended = false
        pendingArmExtended = nil
        pendingArmExtendedStreak = 0
    }
    
    // É uma struct do CoreMotion que entrega a cada leitura o acelerômetro e giroscópio.
    private func process(_ motion: CMDeviceMotion) {
        
        // O userAcceleration ja tira a gravidade e buffers padrões do sistema
        let acceleration = motion.userAcceleration
        
        // A velocidade que o pulso é girada em cada eixo.
        let rotation = motion.rotationRate
        
        // É norma euclidianda num vetor 3D, como se fosse Pitagoras só que em 3 dimensões, converte os 3 números num unico número que representa o quão intenso foi o movimento naquele instante idependente da direção.
        let accelerationMagnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        
        let rotationMagnitude = sqrt(
            rotation.x * rotation.x +
            rotation.y * rotation.y +
            rotation.z * rotation.z
        )
        
        // A cada leitura é acumulado o valor
        totalMovementEnergy += accelerationMagnitude + rotationMagnitude

        updateArmPosition(gravityZ: motion.gravity.z)
    }

    // gravity.z indica a inclinação do pulso em relação à gravidade: perto de -1 com o braço perto do rosto,
    // perto de -0.15/-0.2 com o braço esticado (calibrado com dado real).
    private func updateArmPosition(gravityZ: Double) {
        smoothedGravityZ += (gravityZ - smoothedGravityZ) * gravityZSmoothing

        // Histerese decide o candidato: só vira "esticado" acima de armExtendedThreshold, só volta a "perto"
        // abaixo de armCloseThreshold. Na zona entre os dois, o candidato repete o estado atual (não decide nada novo).
        let candidateIsExtended: Bool
        if smoothedGravityZ > armExtendedThreshold {
            candidateIsExtended = true
        } else if smoothedGravityZ < armCloseThreshold {
            candidateIsExtended = false
        } else {
            candidateIsExtended = isArmExtended
        }

        // Debounce: só aplica o candidato depois que ele se repetir armPositionDebounceSamples vezes seguidas.
        // Isso segura trocas rápidas de estado (ex.: braço passando por uma posição intermediária de rápido).
        if candidateIsExtended == pendingArmExtended {
            pendingArmExtendedStreak += 1
        } else {
            pendingArmExtended = candidateIsExtended
            pendingArmExtendedStreak = 1
        }

        guard pendingArmExtendedStreak >= armPositionDebounceSamples, isArmExtended != candidateIsExtended else { return }
        isArmExtended = candidateIsExtended
    }
    
}

