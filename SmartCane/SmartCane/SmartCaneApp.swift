//
//  SmartCaneApp.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/29/25.
//

import SwiftUI

// MARK: - Main App Entry Point
// This is the main entry point of the SmartCane iOS application
// The @main attribute tells SwiftUI this is where the app starts
@main
struct SmartCaneApp: App {
    // MARK: - App Body
    // This defines the main scene of the application
    // A Scene represents a part of the app's user interface
    var body: some Scene {
        // WindowGroup creates the main window for the app
        // This is where the primary user interface is displayed
        WindowGroup {
            // MainTabView is the root view that contains all the app's tabs
            // This provides the bottom tab navigation between different screens
            MainTabView()
        }
    }
}
