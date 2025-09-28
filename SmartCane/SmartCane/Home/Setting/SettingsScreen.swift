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
    @State private var bluetoothConnectionState: BluetoothConnectionState = .disconnected
    @State private var showingBluetoothDevices = false
    @State private var selectedDevice: MockBluetoothDevice?
    @StateObject var dataService = SmartCaneDataService()
    
    // Mock ESP32 SmartCane devices
    @State private var availableDevices: [MockBluetoothDevice] = [
        MockBluetoothDevice(name: "SmartCane-Pro", deviceId: "SC-001", signalStrength: 85, macAddress: "AA:BB:CC:DD:EE:01", firmwareVersion: "1.2.0"),
        MockBluetoothDevice(name: "SmartCane-Basic", deviceId: "SC-002", signalStrength: 72, macAddress: "AA:BB:CC:DD:EE:02", firmwareVersion: "1.1.0"),
        MockBluetoothDevice(name: "SmartCane-Plus", deviceId: "SC-003", signalStrength: 90, macAddress: "AA:BB:CC:DD:EE:03", firmwareVersion: "1.3.0")
    ]
    
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
                                    disconnectDevice()
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
                                .foregroundColor(bluetoothConnectionState.color)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("SmartCane Device")
                                    .font(.body)
                                Text(bluetoothConnectionState.displayText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let device = selectedDevice {
                                    Text(device.name)
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            // Connection button
                            Button(action: {
                                if bluetoothConnectionState == .connected {
                                    disconnectDevice()
                                } else {
                                    showingBluetoothDevices = true
                                }
                            }) {
                                Text(bluetoothConnectionState.buttonText)
                                    .font(.caption)
                                    .foregroundColor(bluetoothConnectionState.buttonColor)
                            }
                            .disabled(bluetoothConnectionState == .connecting)
                        }
                        
                        // Connection progress indicator
                        if bluetoothConnectionState == .connecting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Connecting...")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        // Signal strength indicator
                        if bluetoothConnectionState == .connected, let device = selectedDevice {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.green)
                                Text("Signal: \(device.signalStrength)%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // ✅ MARK: - Data & Logs Section
                Section("Data & Logs") {
                    NavigationLink(destination: ExportLogs(logs: dataService.obstacleLogs)) {
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
                    devices: availableDevices,
                    bluetoothEnabled: bluetoothEnabled,
                    onDeviceSelected: { device in
                        connectToDevice(device)
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
    
    // MARK: - Bluetooth Connection Methods
    
    // Connect to selected ESP32 SmartCane device
    private func connectToDevice(_ device: MockBluetoothDevice) {
        // Check if Bluetooth is enabled first
        guard bluetoothEnabled else {
            print("❌ Cannot connect to SmartCane: Bluetooth is disabled")
            return
        }
        
        selectedDevice = device
        bluetoothConnectionState = .connecting
        
        print("🔗 Connecting to ESP32 SmartCane: \(device.name)")
        print("🔗 MAC Address: \(device.macAddress)")
        print("🔗 Service UUID: \(MockBluetoothDevice.serviceUUID)")
        print("🔗 Characteristic UUID: \(MockBluetoothDevice.characteristicUUID)")
        
        // Simulate ESP32 connection process
        // In real implementation, this would use Core Bluetooth to:
        // 1. Scan for device with matching MAC address
        // 2. Connect to the ESP32 BLE peripheral
        // 3. Discover services and characteristics
        // 4. Subscribe to notifications for obstacle detection data
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            bluetoothConnectionState = .connected
            print("✅ Successfully connected to ESP32 SmartCane")
        }
    }
    
    // Disconnect from current SmartCane device
    private func disconnectDevice() {
        bluetoothConnectionState = .disconnected
        selectedDevice = nil
        print("🔌 Disconnected from SmartCane device")
    }
}

// MARK: - Supporting Data Structures

// Bluetooth connection states
enum BluetoothConnectionState {
    case disconnected
    case connecting
    case connected
    
    var displayText: String {
        switch self {
        case .disconnected:
            return "Not Connected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        }
    }
    
    var buttonText: String {
        switch self {
        case .disconnected:
            return "Connect"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Disconnect"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        }
    }
    
    var buttonColor: Color {
        switch self {
        case .disconnected:
            return .blue
        case .connecting:
            return .gray
        case .connected:
            return .red
        }
    }
}

// ESP32 SmartCane device model
struct MockBluetoothDevice: Identifiable {
    let id = UUID()
    let name: String
    let deviceId: String
    let signalStrength: Int
    let macAddress: String
    let firmwareVersion: String
    let isESP32: Bool
    
    // ESP32-specific service UUIDs (typical for ESP32 BLE)
    static let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") // Nordic UART Service
    static let characteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // RX Characteristic
    
    init(name: String, deviceId: String, signalStrength: Int, macAddress: String = "", firmwareVersion: String = "1.0.0") {
        self.name = name
        self.deviceId = deviceId
        self.signalStrength = signalStrength
        self.macAddress = macAddress.isEmpty ? "ESP32-\(deviceId)" : macAddress
        self.firmwareVersion = firmwareVersion
        self.isESP32 = true
    }
}

// Bluetooth device list view
struct BluetoothDeviceListView: View {
    let devices: [MockBluetoothDevice]
    let bluetoothEnabled: Bool
    let onDeviceSelected: (MockBluetoothDevice) -> Void
    
    var body: some View {
        NavigationView {
            List(devices) { device in
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(device.name)
                                .font(.headline)
                            if device.isESP32 {
                                Image(systemName: "cpu")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                        Text("ID: \(device.deviceId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("MAC: \(device.macAddress)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("FW: \(device.firmwareVersion)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(signalColor(for: device.signalStrength))
                            Text("\(device.signalStrength)%")
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
    
    private func signalColor(for strength: Int) -> Color {
        switch strength {
        case 80...100:
            return .green
        case 60...79:
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
