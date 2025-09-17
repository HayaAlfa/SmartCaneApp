//
//  SpeechService.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/3/25.
//
import AVFoundation

// MARK: - Speech Service
// This is an alternative speech service class (simpler version than SpeechManager)
// It provides basic text-to-speech functionality without user preference checking
class SpeechService {
    // MARK: - Speech Synthesizer
    // AVSpeechSynthesizer converts text into spoken audio
    private let synthesizer = AVSpeechSynthesizer()
    
    // MARK: - Basic Speech Function
    // This function speaks the provided text with default settings
    // Parameters:
    // - _text: The text to be spoken aloud
    func speak(_text: String) {
        // Create a speech utterance (the text to be spoken)
        let utterance = AVSpeechUtterance(string: _text)
        
        // Set the voice to English US
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Set a moderate speech rate (0.5 = normal speed)
        utterance.rate = 0.5
        
        // Start speaking the text
        synthesizer.speak(utterance)
    }
}
