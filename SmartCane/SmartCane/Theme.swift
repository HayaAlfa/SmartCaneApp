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
    static let brand = Color("Brand")           // Primary brand color (main app color)
    static let brandMuted = Color("BrandMuted") // Muted version of brand color (for subtle elements)
    
    // MARK: - System Colors
    // These colors adapt automatically to light/dark mode and accessibility settings
    static let bg = Color(.systemBackground)    // Background color (white in light mode, black in dark mode)
    static let text = Color.primary             // Primary text color (black in light mode, white in dark mode)
}
