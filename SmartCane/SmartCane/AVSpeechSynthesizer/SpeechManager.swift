//
//  SpeechManager.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/3/25.
//

import AVFoundation

class SpeechManager {
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()
    private init() {}
    
    func speak(_text: String, language: String = "en-US", rate: Float = 0.5) {
        let voiceEnabled = UserDefaults.standard.bool(forKey: "voiceFeedbackEnabled")
        guard voiceEnabled else { return }
        
        
        let utterance = AVSpeechUtterance(string: _text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        synthesizer.speak(utterance)
    }
    
    
    
}
