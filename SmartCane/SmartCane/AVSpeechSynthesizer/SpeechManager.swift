//
//  SpeechManager.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/3/25.
//

import AVFoundation

// MARK: - Speech Manager
// This class handles text-to-speech functionality for accessibility features
// It provides voice feedback to help visually impaired users navigate the app
class SpeechManager {
    // MARK: - Singleton Pattern
    // Using singleton ensures only one speech manager exists throughout the app
    // This prevents multiple speech synthesizers from speaking at the same time
    static let shared = SpeechManager()
    
    // MARK: - Speech Synthesizer
    // AVSpeechSynthesizer is Apple's text-to-speech engine
    // It converts text into spoken audio
    private let synthesizer = AVSpeechSynthesizer()
    
    // MARK: - Private Initializer
    // Private init prevents other parts of the app from creating new instances
    // This enforces the singleton pattern
    private init() {}
    
    // MARK: - Speech Function
    // This function converts text to speech and plays it through the device speakers
    // Parameters:
    // - _text: The text to be spoken aloud
    // - language: The language code for speech (defaults to English US)
    // - rate: How fast the speech plays (0.0 = very slow, 1.0 = very fast)
    func speak(_text: String, language: String = "en-US", rate: Float = 0.5) {
        // Check if voice feedback is enabled in user settings
        // If disabled, don't speak anything (respects user preference)
        let voiceEnabled = UserDefaults.standard.bool(forKey: "voiceFeedbackEnabled")
        guard voiceEnabled else { return }
        
        // Create a speech utterance (the text to be spoken)
        let utterance = AVSpeechUtterance(string: _text)
        
        // Set the voice language (affects pronunciation and accent)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        
        // Set the speech rate (how fast it speaks)
        utterance.rate = rate
        
        // Start speaking the text
        synthesizer.speak(utterance)
    }
}
