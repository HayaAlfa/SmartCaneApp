import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/hayaalfakieh/Downloads/SmartCaneApp/SmartCane/SmartCane/NotificationSettingsView.swift", line: 1)
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
                    Toggle(__designTimeString("#28966_0", fallback: "Enable Notifications"), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                // When user enables notifications, request permission
                                requestNotificationPermission()
                            }
                        }
                } footer: {
                    Text(__designTimeString("#28966_1", fallback: "Control all notification types for the SmartCane app"))
                }
                
                // MARK: - Alert Types Section
                // Only show when notifications are enabled
                if notificationsEnabled {
                    Section(__designTimeString("#28966_2", fallback: "Alert Types")) {
                        // MARK: - Obstacle Detection Alerts
                        // Critical safety alerts for detected obstacles
                        Toggle(__designTimeString("#28966_3", fallback: "Obstacle Detection Alerts"), isOn: $obstacleAlerts)
                        
                        // MARK: - Location Service Updates
                        // Alerts about GPS and location service status
                        Toggle(__designTimeString("#28966_4", fallback: "Location Service Updates"), isOn: $locationUpdates)
                        
                        // MARK: - Device Connection Status
                        // Alerts about SmartCane device connectivity
                        Toggle(__designTimeString("#28966_5", fallback: "Device Connection Status"), isOn: $deviceConnection)
                    }
                    
                    // MARK: - Reminders & Reports Section
                    // Optional notification types for user engagement
                    Section(__designTimeString("#28966_6", fallback: "Reminders & Reports")) {
                        // MARK: - Daily Usage Reminders
                        // Gentle reminders to use the app daily
                        Toggle(__designTimeString("#28966_7", fallback: "Daily Usage Reminders"), isOn: $dailyReminders)
                        
                        // MARK: - Weekly Activity Reports
                        // Summary of weekly app usage and detections
                        Toggle(__designTimeString("#28966_8", fallback: "Weekly Activity Reports"), isOn: $weeklyReports)
                    }
                    
                    // MARK: - Notification Timing Section
                    // Advanced notification scheduling options
                    Section(__designTimeString("#28966_9", fallback: "Notification Timing")) {
                        // MARK: - Quiet Hours Navigation
                        // Link to quiet hours settings
                        NavigationLink(__designTimeString("#28966_10", fallback: "Quiet Hours")) {
                            QuietHoursView()
                        }
                        
                        // MARK: - Sound & Vibration Navigation
                        // Link to sound and vibration settings
                        NavigationLink(__designTimeString("#28966_11", fallback: "Sound & Vibration")) {
                            SoundSettingsView()
                        }
                    }
                }
                
                // MARK: - System Settings Section
                // Link to iOS system notification settings
                Section {
                    Button(__designTimeString("#28966_12", fallback: "Open System Settings")) {
                        openSystemSettings()  // Open iOS Settings app
                    }
                    .foregroundColor(.blue)
                } footer: {
                    Text(__designTimeString("#28966_13", fallback: "Some notification settings can only be changed in System Settings"))
                }
            }
            .navigationTitle(__designTimeString("#28966_14", fallback: "Notifications"))  // Navigation bar title
            .navigationBarTitleDisplayMode(.inline)  // Inline title style
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // MARK: - Done Button
                    // Button to close the settings view
                    Button(__designTimeString("#28966_15", fallback: "Done")) {
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
                    self.notificationsEnabled = __designTimeBoolean("#28966_16", fallback: true)
                } else {
                    self.notificationsEnabled = __designTimeBoolean("#28966_17", fallback: false)
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
                Toggle(__designTimeString("#28966_18", fallback: "Enable Quiet Hours"), isOn: $quietHoursEnabled)
            } footer: {
                Text(__designTimeString("#28966_19", fallback: "During quiet hours, only critical alerts will be shown"))
            }
            
            // MARK: - Time Range Section
            // Only show when quiet hours are enabled
            if quietHoursEnabled {
                Section(__designTimeString("#28966_20", fallback: "Time Range")) {
                    // MARK: - Start Time Picker
                    DatePicker(__designTimeString("#28966_21", fallback: "Start Time"), selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    // MARK: - End Time Picker
                    DatePicker(__designTimeString("#28966_22", fallback: "End Time"), selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                // MARK: - Critical Alerts Notice
                Section(__designTimeString("#28966_23", fallback: "Critical Alerts")) {
                    Text(__designTimeString("#28966_24", fallback: "Obstacle detection alerts will still be shown during quiet hours for safety"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(__designTimeString("#28966_25", fallback: "Quiet Hours"))  // Navigation bar title
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
            Section(__designTimeString("#28966_26", fallback: "Sound & Vibration")) {
                // MARK: - Sound Toggle
                Toggle(__designTimeString("#28966_27", fallback: "Sound"), isOn: $soundEnabled)
                
                // MARK: - Vibration Toggle
                Toggle(__designTimeString("#28966_28", fallback: "Vibration"), isOn: $vibrationEnabled)
            }
            
            // MARK: - Alert Sound Section
            // Only show when sound is enabled
            if soundEnabled {
                Section(__designTimeString("#28966_29", fallback: "Alert Sound")) {
                    // MARK: - Sound Picker
                    Picker(__designTimeString("#28966_30", fallback: "Sound"), selection: $selectedSound) {
                        ForEach(availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())  // Dropdown picker style
                }
            }
            
            // MARK: - Sound Preview Section
            Section(__designTimeString("#28966_31", fallback: "Preview")) {
                // MARK: - Test Sound Button
                Button(__designTimeString("#28966_32", fallback: "Test Sound")) {
                    // In a real app, this would play the selected sound
                    // For now, it's just a placeholder
                }
                .disabled(!soundEnabled)  // Disable if sound is off
            }
        }
        .navigationTitle(__designTimeString("#28966_33", fallback: "Sound & Vibration"))  // Navigation bar title
        .navigationBarTitleDisplayMode(.inline)  // Inline title style
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    NotificationSettingsView(notificationsEnabled: .constant(__designTimeBoolean("#28966_34", fallback: true)))
}
