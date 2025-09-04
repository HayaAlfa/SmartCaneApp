import SwiftUI
import UserNotifications  // For checking and requesting notification permissions

struct NotificationSettingsView: View {
    // MARK: - Properties
    // @Binding creates a two-way connection with the parent view's notification state
    @Binding var notificationsEnabled: Bool
    
    // MARK: - Environment
    // @Environment provides access to the current view's environment
    @Environment(\.dismiss) private var dismiss  // Used to close the sheet
    
    // MARK: - State Properties
    // @State properties control the UI state for various notification settings
    @State private var obstacleAlerts = true        // Whether to show obstacle detection alerts
    @State private var locationUpdates = true       // Whether to show location service updates
    @State private var deviceConnection = true      // Whether to show device connection status
    @State private var dailyReminders = false       // Whether to show daily usage reminders
    @State private var weeklyReports = false        // Whether to show weekly activity reports
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Main Notification Toggle Section
                // Controls the overall notification permission
                Section {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                // When user enables notifications, request permission
                                requestNotificationPermission()
                            }
                        }
                } footer: {
                    Text("Control all notification types for the SmartCane app")
                }
                
                // MARK: - Alert Types Section
                // Only show when notifications are enabled
                if notificationsEnabled {
                    Section("Alert Types") {
                        // MARK: - Obstacle Detection Alerts
                        // Critical safety alerts for detected obstacles
                        Toggle("Obstacle Detection Alerts", isOn: $obstacleAlerts)
                        
                        // MARK: - Location Service Updates
                        // Alerts about GPS and location service status
                        Toggle("Location Service Updates", isOn: $locationUpdates)
                        
                        // MARK: - Device Connection Status
                        // Alerts about SmartCane device connectivity
                        Toggle("Device Connection Status", isOn: $deviceConnection)
                    }
                    
                    // MARK: - Reminders & Reports Section
                    // Optional notification types for user engagement
                    Section("Reminders & Reports") {
                        // MARK: - Daily Usage Reminders
                        // Gentle reminders to use the app daily
                        Toggle("Daily Usage Reminders", isOn: $dailyReminders)
                        
                        // MARK: - Weekly Activity Reports
                        // Summary of weekly app usage and detections
                        Toggle("Weekly Activity Reports", isOn: $weeklyReports)
                    }
                    
                    // MARK: - Notification Timing Section
                    // Advanced notification scheduling options
                    Section("Notification Timing") {
                        // MARK: - Quiet Hours Navigation
                        // Link to quiet hours settings
                        NavigationLink("Quiet Hours") {
                            QuietHoursView()
                        }
                        
                        // MARK: - Sound & Vibration Navigation
                        // Link to sound and vibration settings
                        NavigationLink("Sound & Vibration") {
                            SoundSettingsView()
                        }
                    }
                }
                
                // MARK: - System Settings Section
                // Link to iOS system notification settings
                Section {
                    Button("Open System Settings") {
                        openSystemSettings()  // Open iOS Settings app
                    }
                    .foregroundColor(.blue)
                } footer: {
                    Text("Some notification settings can only be changed in System Settings")
                }
            }
            .navigationTitle("Notifications")  // Navigation bar title
            .navigationBarTitleDisplayMode(.inline)  // Inline title style
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // MARK: - Done Button
                    // Button to close the settings view
                    Button("Done") {
                        dismiss()  // Close the sheet
                    }
                }
            }
            .onAppear {
                // MARK: - View Setup
                // Check current notification status when view appears
                checkNotificationStatus()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // MARK: - Check Notification Status
    // Checks the current notification permission status from iOS
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {  // Update UI on main thread
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Request Notification Permission
    // Asks iOS for permission to send notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {  // Update UI on main thread
                if granted {
                    self.notificationsEnabled = true
                } else {
                    self.notificationsEnabled = false
                    if let error = error {
                        print("Notification permission error: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Open System Settings
    // Opens the iOS Settings app for manual notification configuration
    private func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Quiet Hours View
// Sub-view for configuring notification quiet hours
struct QuietHoursView: View {
    // MARK: - State Properties
    @State private var quietHoursEnabled = false  // Whether quiet hours are active
    @State private var startTime = Date()         // Start time for quiet hours
    @State private var endTime = Date()           // End time for quiet hours
    
    var body: some View {
        Form {
            Section {
                // MARK: - Quiet Hours Toggle
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
            } footer: {
                Text("During quiet hours, only critical alerts will be shown")
            }
            
            // MARK: - Time Range Section
            // Only show when quiet hours are enabled
            if quietHoursEnabled {
                Section("Time Range") {
                    // MARK: - Start Time Picker
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    // MARK: - End Time Picker
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                // MARK: - Critical Alerts Notice
                Section("Critical Alerts") {
                    Text("Obstacle detection alerts will still be shown during quiet hours for safety")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Quiet Hours")  // Navigation bar title
        .navigationBarTitleDisplayMode(.inline)  // Inline title style
    }
}

// MARK: - Sound Settings View
// Sub-view for configuring notification sounds and vibration
struct SoundSettingsView: View {
    // MARK: - State Properties
    @State private var soundEnabled = true           // Whether notification sounds are on
    @State private var vibrationEnabled = true       // Whether notification vibration is on
    @State private var selectedSound = "Default"     // Selected notification sound
    
    // MARK: - Available Sounds
    // List of notification sound options
    let availableSounds = ["Default", "Gentle", "Alert", "Custom"]
    
    var body: some View {
        Form {
            // MARK: - Sound & Vibration Section
            Section("Sound & Vibration") {
                // MARK: - Sound Toggle
                Toggle("Sound", isOn: $soundEnabled)
                
                // MARK: - Vibration Toggle
                Toggle("Vibration", isOn: $vibrationEnabled)
            }
            
            // MARK: - Alert Sound Section
            // Only show when sound is enabled
            if soundEnabled {
                Section("Alert Sound") {
                    // MARK: - Sound Picker
                    Picker("Sound", selection: $selectedSound) {
                        ForEach(availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())  // Dropdown picker style
                }
            }
            
            // MARK: - Sound Preview Section
            Section("Preview") {
                // MARK: - Test Sound Button
                Button("Test Sound") {
                    // In a real app, this would play the selected sound
                    // For now, it's just a placeholder
                }
                .disabled(!soundEnabled)  // Disable if sound is off
            }
        }
        .navigationTitle("Sound & Vibration")  // Navigation bar title
        .navigationBarTitleDisplayMode(.inline)  // Inline title style
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    NotificationSettingsView(notificationsEnabled: .constant(true))
}
