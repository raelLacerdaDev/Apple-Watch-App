//
//  PermissionsManager.swift
//  Apresentation
//
//  Created by Manoel Pedro Prado Sa Teles on 19/08/26.
//

import Foundation
import AVFoundation
internal import Combine // Recurso novo do Swift para que o ObservableObject e @Published, fazem parte do framework Combine


//Pedir permissão do microfone roda na thread principal
@MainActor
final class PermissionsManager: ObservableObject {
    
    enum Status {
        case notDetermined
        case granted
        case denied
    }
    
    // Para atualizar a UI com segurança.
    @Published private(set) var microphoneStatus: Status = .notDetermined
    
    var isAuthorized: Bool {
        microphoneStatus == .granted
    }
    
    //Peder permissão de acesso ao microfone, o alerta de permitir ou não acesso ao microfone é tratado aqui,
    //O @discardableResult permite ignorar o valor, para que o XCode não reclame que o retorno/valor dessa função e ignorar o resultado, uma vez que só quero pedir permissão.
    
    // Ele pede permissão do microfone e converte o Bool do sistema para o Status e atualiza a propiedade microphoneStatus e deolvedo para quem chamou de forma síncrona.
    @discardableResult
    func requestMicrophone() async -> Status {
        
        let granted = await AVAudioApplication.requestRecordPermission()
        
        let status: Status = granted ? .granted : .denied
        microphoneStatus = status
        return status
        
    }
    
}
