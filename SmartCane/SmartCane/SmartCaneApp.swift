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
    @StateObject private var dataService = SmartCaneDataService()


    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isRestoringSession {
                    // Show loading state while checking session
                    ProgressView()
                        .task {
                            // Restore session on app launch to remember logged-in user
                            await authViewModel.restoreSession()
                        }
                } else if authViewModel.isAuthenticated {
                    MainTabView(isAuthenticated: .constant(false))
                        .environmentObject(authViewModel)
                        .environmentObject(dataService)
                } else {
                    AuthView()
                        .environmentObject(authViewModel)
                        .environmentObject(dataService)
                }
            }
        }
    }
}
