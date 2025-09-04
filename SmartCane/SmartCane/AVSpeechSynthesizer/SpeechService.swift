//
//  SpeechService.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/3/25.
//
import AVFoundation

class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_text: String) {
        let utterance = AVSpeechUtterance(string: _text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}
