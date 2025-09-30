//
//  SettingsScreen.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI
import UserNotifications  // For checking and requesting notification permissions
import CoreBluetooth      // For real Bluetooth functionality

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
    @State private var showingBluetoothDevices = false

    
    // Real ESP32 Bluetooth Manager
    @StateObject private var btManager = ESP32BluetoothManager()
    
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
                    
                    // MARK: - Bluetooth Status
                    // Shows general bluetooth status with toggle
                    HStack {
                        Image(systemName: "bluetooth")
                            .foregroundColor(bluetoothEnabled ? .green : .gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Bluetooth")
                                .font(.body)
                            Text(bluetoothEnabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Bluetooth toggle
                        Toggle("", isOn: $bluetoothEnabled)
                        .onChange(of: bluetoothEnabled) { _, newValue in
                            if !newValue {
                                // If Bluetooth is disabled, disconnect SmartCane
                                btManager.disconnect()
                            }
                        }
                        
                        // Button to open bluetooth settings
                        Button("Settings") {
                            openBluetoothSettings()
                        }
                        .font(.caption)
                    }
                    
                    // MARK: - SmartCane Device Connection
                    // Shows specific ESP32 SmartCane connection status
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "cane")
                                .foregroundColor(btManager.connectionState.color)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("SmartCane Device")
                                    .font(.body)
                                Text(btManager.connectionState.displayText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let device = btManager.connectedDevice {
                                    Text(device.name)
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            // Connection button
                            Button(action: {
                                if btManager.connectionState == .connected {
                                    btManager.disconnect()
                                } else {
                                    showingBluetoothDevices = true
                                }
                            }) {
                                Text(btManager.connectionState.buttonText)
                                    .font(.caption)
                                    .foregroundColor(btManager.connectionState.buttonColor)
                            }
                            .disabled(btManager.connectionState == .connecting)
                        }
                        
                        // Connection progress indicator
                        if btManager.connectionState == .connecting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Connecting...")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        // Signal strength indicator
                        if btManager.connectionState == .connected, let device = btManager.connectedDevice {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.green)
                                Text("RSSI: \(device.rssi) dBm")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                
                // ✅ MARK: - Data & Logs Section
                Section("Data & Logs") {
                    NavigationLink(destination: ExportLogs(logs: ObstacleLog.sampleData)) {
                        Label("Export Logs (CSV)", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        print("Logs cleared")
                        // TODO: implement persistence clear
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                }

            }
            .navigationTitle("Settings")  // Sets the navigation bar title
            .onAppear {
                // Check current permission status when view appears
                checkPermissions()
            }
            .sheet(isPresented: $showingBluetoothDevices) {
                BluetoothDeviceListView(
                    devices: btManager.discoveredDevices,
                    bluetoothEnabled: bluetoothEnabled,
                    onDeviceSelected: { device in
                        btManager.connectToDevice(device)
                        showingBluetoothDevices = false
                    }
                )
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


// Bluetooth device list view
struct BluetoothDeviceListView: View {
    let devices: [ESP32SmartCane]
    let bluetoothEnabled: Bool
    let onDeviceSelected: (ESP32SmartCane) -> Void
    
    var body: some View {
        NavigationView {
            List(devices) { device in
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(device.name)
                                .font(.headline)
                            Image(systemName: "cpu")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        if let peripheral = device.peripheral {
                            Text("ID: \(peripheral.identifier.uuidString.prefix(8))...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(signalColor(for: device.rssi))
                            Text("\(device.rssi) dBm")
                                .font(.caption)
                        }
                        
                        Button("Connect") {
                            onDeviceSelected(device)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .disabled(!bluetoothEnabled)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Available Devices")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func signalColor(for rssi: Int) -> Color {
        switch rssi {
        case -50...0:
            return .green
        case -70 ..< -50:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    SettingsScreen()
}
