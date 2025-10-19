//
//  ReadObstacleIntent.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 10/19/25.
//

import Foundation
import AppIntents
import AVFoundation

@available(iOS 16.0, *)
struct ReadLastObstacleIntent: AppIntent {
    static var title: LocalizedStringResource = "Read Last Obstacle"
    static var description = IntentDescription("Reads the most recent obstacle recorded in the log.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Example: Fetch last obstacle from local storage (UserDefaults or database)
        // You’ll replace this with your actual obstacle log retrieval later
        let username = UserDefaults.standard.string(forKey: "username") ?? ""
        let key = "lastObstacleDescription_\(username)"
        let lastObstacle = UserDefaults.standard.string(forKey: key) ?? "No recent obstacle recorded for your account."

        // Speak aloud
        let utterance = AVSpeechUtterance(string: "The last obstacle recorded is: \(lastObstacle)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        AVSpeechSynthesizer().speak(utterance)

        // Also display on Siri screen
        return .result(dialog: "The last obstacle recorded is: \(lastObstacle)")
    }
}
