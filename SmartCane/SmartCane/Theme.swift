//
//  Theme.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI

// MARK: - App Theme Configuration
// This enum defines the color scheme and visual theme for the entire SmartCane app
// Using a centralized theme makes it easy to maintain consistent colors throughout the app
enum Theme {
    // MARK: - Brand Colors
    // These colors are defined in the Assets.xcassets file and represent the app's brand identity
    // Sunlight-readable palette (high contrast)
    // Use very dark accents and pure white backgrounds for maximum outdoor readability
    static let brand = Color.black               // Primary brand color (high contrast in sunlight)
    static let brandMuted = Color(red: 0.2, green: 0.2, blue: 0.2) // Dark gray for secondary elements
    
    // MARK: - System Colors
//    // These colors adapt automatically to light/dark mode and accessibility settings
    static let bg = Color.white                 // Pure white background for maximum contrast
//    static let text = Color.white               // Pure black text for maximum contrast
}
