//
//  SettingsScreen.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI

struct SettingsScreen: View {
    @AppStorage(AppKeys.voiceEnabled) private var voiceFeedbackEnabled: Bool = true
    @AppStorage(AppKeys.darkModeEnabled) private var darkModeEnabled: Bool = false
    @AppStorage(AppKeys.notificationsEnabled) private var notificationsEnabled: Bool = true
    @Environment(\.colorScheme) private var systemColorScheme

    
    var body: some View {
        NavigationView {
            Form {
                // Accessibility Section
                Section(header: Text("Accessibility")) {
                    Toggle("Enable Voice Feedback", isOn: $voiceFeedbackEnabled)
                        .accessibilityLabel("Voice Feedback Toggle")
                        .accessibilityHint("Turns speech feedback on or off")
                    
                    
                }
                
                // Appearance Section
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .accessibilityLabel("Dark Mode Toggle")
                        .accessibilityHint("Turns dark appearance on or off for the app")
                }
                
                // ✅ Data & Logs Section
                Section(header: Text("Data & Logs")) {
                    // Export CSV
                    NavigationLink(destination: ExportLogs(logs: sampleLogs)) {
                        Label("Export Logs (CSV)", systemImage: "square.and.arrow.up")
                    }
                    
                    // Clear Logs
                    Button(role: .destructive) {
                        // TODO: implement persistence & clear logs here
                        print("Logs cleared")
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                }
                
                // Preferences Section
                Section(header: Text("Preferences")) {
                    NavigationLink(destination: NotificationSettingsView(notificationsEnabled: $notificationsEnabled)) {
                        Text("Notification Settings")
                    }
                    NavigationLink(destination: PrivacySettingsView()) {
                        Text("Privacy Settings")
                    }
                }
                
                // About Section
                Section {
                    NavigationLink(destination: AboutView()) {
                        Text("About")
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            // Initialize dark mode toggle to match system on first run
            if UserDefaults.standard.object(forKey: AppKeys.darkModeEnabled) == nil {
                darkModeEnabled = (systemColorScheme == .dark)
            }
        }
    }
}
