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
    @StateObject private var authViewModel = AuthViewModel()


    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView(isAuthenticated: .constant(false))
                    .environmentObject(authViewModel)
                    .task { await authViewModel.restoreSession() }
                
            } else {
                AuthView()
                    .environmentObject(authViewModel)
                    .task { await authViewModel.restoreSession() }
            }
            
        }
    }
}
