//
//  SpeechViewModel.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 10/16/25.
//

import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine = AVAudioEngine()
    private var request = SFSpeechAudioBufferRecognitionRequest()
    private var task: SFSpeechRecognitionTask?

    func startRecording() throws {
        transcript = ""
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        request = SFSpeechAudioBufferRecognitionRequest()
        
        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            [weak self] buffer, _ in
            self?.request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() {
        audioEngine.stop()
        request.endAudio()
    }
}

