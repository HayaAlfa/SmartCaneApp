//
//  SettingsScreen.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI
import UserNotifications  // For checking and requesting notification permissions

// MARK: - Settings Screen
// This screen provides app configuration options and user preferences
// It allows users to customize their experience with the SmartCane app
struct SettingsScreen: View {
    // MARK: - App Storage Properties
    // @AppStorage automatically saves/loads values from UserDefaults
    // This ensures user preferences persist between app launches
    @AppStorage(AppKeys.voiceEnabled) private var voiceFeedbackEnabled: Bool = true
    
    // MARK: - State Properties
    // These properties track the current status of various device services
    @State private var notificationsEnabled = false      // Whether notifications are allowed
    @State private var locationServicesEnabled = false   // Whether location services are active
    @State private var bluetoothEnabled = false          // Whether bluetooth is connected
    
    // MARK: - Main Body
    // This defines the main user interface of the settings screen
    var body: some View {
        NavigationView {
            // MARK: - Settings Form
            // Form provides a native iOS settings interface with proper styling
            Form {
                // MARK: - App Preferences Section
                // Settings that control app behavior and user experience
                Section("App Preferences") {
                    // MARK: - Voice Feedback Toggle
                    // Toggle switch to enable/disable voice feedback throughout the app
                    Toggle("Enable Voice Feedback", isOn: $voiceFeedbackEnabled)
                        .accessibilityLabel("Voice Feedback Toggle")        // Accessibility label for screen readers
                        .accessibilityHint("Turns speech feedback on or off") // Helpful hint for accessibility
                }
                
                // MARK: - Device Services Section
                // Settings that show and control device-level services
                Section("Device Services") {
                    // MARK: - Notifications Toggle
                    // Shows current notification permission status
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(notificationsEnabled ? .green : .gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Notifications")
                                .font(.body)
                            Text(notificationsEnabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Button to open notification settings
                        Button("Settings") {
                            openNotificationSettings()
                        }
                        .font(.caption)
                    }
                    
                    // MARK: - Location Services Toggle
                    // Shows current location services status
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(locationServicesEnabled ? .green : .gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Location Services")
                                .font(.body)
                            Text(locationServicesEnabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Button to open location settings
                        Button("Settings") {
                            openLocationSettings()
                        }
                        .font(.caption)
                    }
                    
                    // MARK: - Bluetooth Toggle
                    // Shows current bluetooth connection status
                    HStack {
                        Image(systemName: "bluetooth")
                            .foregroundColor(bluetoothEnabled ? .green : .gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Bluetooth")
                                .font(.body)
                            Text(bluetoothEnabled ? "Connected" : "Disconnected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Button to open bluetooth settings
                        Button("Settings") {
                            openBluetoothSettings()
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")  // Sets the navigation bar title
            .onAppear {
                // Check current permission status when view appears
                checkPermissions()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Check current permission status for various services
    private func checkPermissions() {
        // Check notification permission status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {  // Update UI on main thread
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
        
        // Check location permission status (simplified for demo)
        locationServicesEnabled = true // In a real app, check actual permission status
        
        // Check bluetooth status (simplified for demo)
        bluetoothEnabled = false // In a real app, check actual bluetooth status
    }
    
    // Open iOS Settings app to notification permissions
    private func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // Open iOS Settings app to location permissions
    private func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // Open iOS Settings app to bluetooth settings
    private func openBluetoothSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    SettingsScreen()
}
