//
//  AppKeys.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/3/25.
//

// MARK: - App Configuration Keys
// This enum stores all the UserDefaults keys used throughout the app
// Using constants prevents typos and makes it easy to change key names in one place
enum AppKeys {
    // MARK: - User Preferences
    // Key for storing whether voice feedback is enabled or disabled
    // This setting controls whether the app speaks aloud when users interact with it
    static let voiceEnabled = "voiceFeedbackEnabled"
}
