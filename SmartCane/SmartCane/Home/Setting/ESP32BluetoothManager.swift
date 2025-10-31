//
//  ESP32BluetoothManager.swift
//  SmartCane
//
//  Created for ESP32 SmartCane integration
//

import Foundation
import AVFAudio
import CoreBluetooth
import Combine
import SwiftUI

// MARK: - ESP32 SmartCane Bluetooth Manager
// This class will handle real Bluetooth communication with ESP32-based SmartCane devices
class ESP32BluetoothManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectedDevice: ESP32SmartCane?
    @Published var discoveredDevices: [ESP32SmartCane] = []
    @Published var connectionState: BluetoothConnectionState = .disconnected
    
    // MARK: - Core Bluetooth Properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    
    // ESP32 Service and Characteristic UUIDs (from Michelle's ESP32 code)
    static let serviceUUID = CBUUID(string: "34123456-1234-1234-1234-1234567890AB") // SmartCane Service
    static let characteristicUUID = CBUUID(string: "34123456-1234-1234-1234-1234567890AC") // SmartCane Characteristic
    
    // Legacy Nordic UART Service UUIDs (for nRF Connect testing)
    static let nordicServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let rxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // RX (Write)
    static let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // TX (Notify)
    
    // MARK: - Processing Lock
    private var isProcessingObstacle = false
    private var isInCooldown = false
    private let processingQueue = DispatchQueue(label: "obstacle.processing", qos: .userInitiated)
    private var isScreenOn = true

    private func startCooldown() {
        self.processingQueue.async {
            self.isProcessingObstacle = false
            self.isInCooldown = true
            print("🔓 Processing lock released - starting 10-second cooldown")
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                self.processingQueue.async {
                    self.isInCooldown = false
                    print("✅ Cooldown period ended - ready for next obstacle")
                }
            }
        }
    }

    private func speakObstacle(distance: Int) {
        DispatchQueue.main.async {
            // Ensure speaker route when speaking warnings
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            } catch { }
            print("🔊 (BG/NoCam) Speaking obstacle ahead: \(distance)cm")
            SpeechManager.shared.speak(_text: "Obstacle ahead \(distance) centimeters")
        }
    }
    
    // MARK: - Cooldown Check Helper
    private func canProcessObstacle() -> Bool {
        return !isProcessingObstacle && !isInCooldown
    }
    
    // MARK: - Camera + AI Classification for Bluetooth
    private func processBluetoothObstacleWithCamera(distance: Int, direction: String, confidence: Double) async {
        // Set processing flag (cooldown check already done at handler level)
        processingQueue.async {
            self.isProcessingObstacle = true
        }
        
        print("📸 Starting camera + AI classification for Bluetooth obstacle...")
        
        // Import the camera and AI components
        let autoCamera = AutoCameraCapture.shared
        
        // Start camera session
        print("📸 Starting camera session...")
        autoCamera.startSession()
        
        // Wait for camera to initialize, then capture
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        print("📸 Calling autoCamera.capturePhoto()...")
        autoCamera.capturePhoto()
        
        // Wait for photo capture and then process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Handle the obstacle result - only once
        if let image = autoCamera.capturedImage {
            print("📸 Photo captured, processing with AI...")
            
            // Use AI to classify the obstacle
            await withCheckedContinuation { continuation in
                ObstacleClassifierManager.shared.classify(image: image) { result, aiConfidence in
                    Task { @MainActor in
                        let objectType = result.isEmpty ? "unknown obstacle" : result
                        print("✅ AI Classification result: \(objectType) (\(aiConfidence))")
                        
                        // Stop camera session before speaking/logging to avoid audio route conflicts
                        print("📸 Stopping camera session...")
                        autoCamera.stopSession()
                        
                        // Save to Supabase with AI-classified type (this will speak via Pipeline)
                        await Pipeline.shared.handleIncomingObstacle(
                            distance: distance,
                            direction: direction,
                            obstacleType: objectType,  // AI-classified type
                            confidence: aiConfidence
                        )
                        
                        // Release processing lock and start cooldown
                        self.processingQueue.async {
                            self.isProcessingObstacle = false
                            self.isInCooldown = true
                            print("🔓 Processing lock released - starting 10-second cooldown")
                            
                            // Start 10-second cooldown timer
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                self.processingQueue.async {
                                    self.isInCooldown = false
                                    print("✅ Cooldown period ended - ready for next obstacle")
                                }
                            }
                        }
                        
                        continuation.resume()
                    }
                }
            }
        } else {
            print("❌ No image captured after 2 seconds")
            // Fallback: save with generic type
            await Pipeline.shared.handleIncomingObstacle(
                distance: distance,
                direction: direction,
                obstacleType: "obstacle",  // Generic fallback
                confidence: confidence
            )
            autoCamera.stopSession()
            
            // Release processing lock and start cooldown
            processingQueue.async {
                self.isProcessingObstacle = false
                self.isInCooldown = true
                print("🔓 Processing lock released (fallback) - starting 10-second cooldown")
                
                // Start 10-second cooldown timer
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                    self.processingQueue.async {
                        self.isInCooldown = false
                        print("✅ Cooldown period ended - ready for next obstacle")
                    }
                }
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        // Use state restoration so Bluetooth can continue delivering events in background
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: "com.smartcane.central"]
        )
        // Screen state detection
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func appDidEnterBackground() { isScreenOn = false }
    @objc private func appWillEnterForeground() { isScreenOn = true }
    
    // MARK: - Public Methods
    
    /// Start scanning for ESP32 SmartCane devices
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        
            // Starting scan for ESP32 SmartCane devices
        // Temporarily scan for ALL devices to debug
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    /// Stop scanning for devices
    func stopScanning() {
        centralManager.stopScan()
        // Stopped scanning
    }
    
    /// Connect to a specific ESP32 SmartCane device
    func connectToDevice(_ device: ESP32SmartCane) {
        guard let peripheral = device.peripheral else { return }
        
        print("🔗 Connecting to ESP32 SmartCane: \(device.name)")
        connectionState = .connecting
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Disconnect from current device
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        
        print("🔌 Disconnecting from ESP32 SmartCane")
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    /// Send command to ESP32 (e.g., start obstacle detection)
    func sendCommand(_ command: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = connectedDevice?.rxCharacteristic else { return }
        
        let data = command.data(using: .utf8)!
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("📤 Sent command to ESP32: \(command)")
    }
    
    /// Request obstacle detection data from ESP32
    func requestObstacleData() {
        sendCommand("GET_OBSTACLES")
    }
    
    /// Start continuous obstacle monitoring
    func startObstacleMonitoring() {
        sendCommand("START_MONITORING")
    }
    
    /// Stop obstacle monitoring
    func stopObstacleMonitoring() {
        sendCommand("STOP_MONITORING")
    }
}

// MARK: - CBCentralManagerDelegate
extension ESP32BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth is powered on")
            startScanning()
        case .poweredOff:
            print("❌ Bluetooth is powered off")
            connectionState = .disconnected
        case .unauthorized:
            print("❌ Bluetooth access unauthorized")
        case .unsupported:
            print("❌ Bluetooth not supported")
        default:
            print("⚠️ Bluetooth state: \(central.state)")
        }
    }

    // Background restoration handler (enables delivery in background)
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // Restoring Bluetooth state in background/launch
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral], let first = peripherals.first {
            connectedPeripheral = first
            connectedPeripheral?.delegate = self
            // Restored peripheral: \(first.identifier)
        }
        // Resume scanning to continue receiving obstacle signals
        startScanning()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Check if device advertises SmartCane Service or Nordic UART Service
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        let hasSmartCaneService = serviceUUIDs?.contains(Self.serviceUUID) ?? false
        let hasNordicUART = serviceUUIDs?.contains(Self.nordicServiceUUID) ?? false
        
        // Check if this is a SmartCane device (by name OR by service UUID)
        let hasSmartCaneName = peripheral.name?.contains("SmartCane") == true
        
        // Only log devices that have services or are SmartCane devices
        let services = serviceUUIDs?.map { $0.uuidString }.joined(separator: ", ") ?? "none"
        
        // Skip logging devices with no services and no SmartCane connection
        if !hasSmartCaneName && !hasSmartCaneService && !hasNordicUART && services == "none" {
            return
        }
        
        // Determine device type based on services
        let deviceName = peripheral.name ?? "Unknown"
        let deviceType: String
        if hasNordicUART {
            deviceType = "nRF Connect"
        } else if hasSmartCaneService || hasSmartCaneName {
            deviceType = "SmartCane"
        } else {
            deviceType = deviceName
        }
        
        // Clean, short device discovery log
        print("📡 \(deviceType) - Services: \(services)")
        
        if !hasSmartCaneName && !hasSmartCaneService && !hasNordicUART {
            return
        }
        
        if hasSmartCaneService {
            print("   ✅ SmartCane Service found! (ESP32)")
        }
        if hasNordicUART {
            print("   ✅ Nordic UART Service found! (nRF Connect)")
        }
        if hasSmartCaneName {
            print("   ✅ SmartCane device found by name!")
        }
        
        let device = ESP32SmartCane(
            name: peripheral.name ?? "SmartCane Mock",
            peripheral: peripheral,
            rssi: RSSI.intValue
        )
        
        // Add to discovered devices if not already present
        if !discoveredDevices.contains(where: { $0.peripheral?.identifier == peripheral.identifier }) {
            discoveredDevices.append(device)
            print("🔍 Discovered ESP32 SmartCane: \(device.name) (RSSI: \(RSSI))")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to ESP32 SmartCane: \(peripheral.name ?? "Unknown")")
        
        // Stop scanning once connected to save battery
        stopScanning()
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        // Wait a bit for ESP32 to finish setting up services
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🔍 Starting service discovery...")
            // Discover ALL services (nil = discover all)
            peripheral.discoverServices(nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Disconnected from ESP32 SmartCane")
        
        connectedPeripheral = nil
        connectedDevice = nil
        isConnected = false
        connectionState = .disconnected
        
        if let error = error {
            print("❌ Disconnection error: \(error)")
        }
        
        // Optionally restart scanning after disconnection
        // Uncomment the line below if you want auto-reconnect capability
        // startScanning()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect to ESP32 SmartCane: \(error?.localizedDescription ?? "Unknown error")")
        connectionState = .disconnected
    }
}

// MARK: - CBPeripheralDelegate
extension ESP32BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Service discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("❌ No services found - ESP32 might not have created services yet")
            print("💡 Retrying service discovery in 2 seconds...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                peripheral.discoverServices(nil)
            }
            return
        }
        
        if services.isEmpty {
            print("❌ Services array is empty - ESP32 GATT server not ready")
            print("💡 Retrying service discovery in 2 seconds...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                peripheral.discoverServices(nil)
            }
            return
        }
        
        // Services found - logging removed for cleaner output
        
        for service in services {
            if service.uuid == Self.serviceUUID {
                print("✅ Discovered ESP32 SmartCane service")
                peripheral.discoverCharacteristics([Self.characteristicUUID], for: service)
            } else if service.uuid == Self.nordicServiceUUID {
                print("✅ Discovered Nordic UART service (nRF Connect)")
                peripheral.discoverCharacteristics([Self.rxCharacteristicUUID, Self.txCharacteristicUUID], for: service)
            } else {
                // Discover ALL characteristics for unknown services
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Characteristic discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("❌ No characteristics found for service: \(service.uuid)")
            return
        }
        
        // Characteristics found - logging removed for cleaner output
        
        var rxCharacteristic: CBCharacteristic?
        var txCharacteristic: CBCharacteristic?
        var smartCaneChar: CBCharacteristic?
        
        for characteristic in characteristics {
            // ESP32 SmartCane characteristic (READ | NOTIFY)
            if characteristic.uuid == Self.characteristicUUID {
                smartCaneChar = characteristic
                print("📥 Found SmartCane characteristic (ESP32)")
                // Subscribe to notifications
                peripheral.setNotifyValue(true, for: characteristic)
            }
            // Nordic UART Service characteristics (for nRF Connect)
            else if characteristic.uuid == Self.rxCharacteristicUUID {
                rxCharacteristic = characteristic
                print("📤 Found RX characteristic (Write)")
            } else if characteristic.uuid == Self.txCharacteristicUUID {
                txCharacteristic = characteristic
                print("📥 Found TX characteristic (Notify)")
                // Subscribe to notifications
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        // Create connected device (ESP32 or nRF Connect)
        if let smartChar = smartCaneChar {
            // ESP32 SmartCane device
            connectedDevice = ESP32SmartCane(
                name: peripheral.name ?? "SmartCane",
                peripheral: peripheral,
                rssi: 0,
                rxCharacteristic: nil,
                txCharacteristic: smartChar
            )
            isConnected = true
            connectionState = .connected
            print("✅ ESP32 SmartCane fully connected and ready")
        } else if let rxChar = rxCharacteristic, let txChar = txCharacteristic {
            // nRF Connect device
            connectedDevice = ESP32SmartCane(
                name: peripheral.name ?? "SmartCane",
                peripheral: peripheral,
                rssi: 0,
                rxCharacteristic: rxChar,
                txCharacteristic: txChar
            )
            isConnected = true
            connectionState = .connected
            print("✅ nRF Connect device fully connected and ready")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        if let message = String(data: data, encoding: .utf8) {
            print("📥 Received from ESP32: \(message)")
            handleIncomingData(message)
        }
    }
    
    // Handle incoming data from ESP32
    private func handleIncomingData(_ message: String) {
        print("📥 Raw message received: \(message)")
        
        // Try to parse as JSON first (ESP32 format)
        if let jsonData = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            // Check if it's the real ESP32 format (has cm1 and cm2)
            if json["cm1"] != nil && json["cm2"] != nil {
                handleRealESP32Format(json)
            } else {
                handleJSONFormat(json)
            }
            return
        }
        
        // Try simple format (nRF Connect: "F:20", "L:20", etc.)
        if message.contains(":") && message.count < 10 {
            handleSimpleFormat(message)
            return
        }
        
        // Try OBSTACLE format: "OBSTACLE:distance:direction:confidence"
        if message.hasPrefix("OBSTACLE:") {
            handleObstacleFormat(message)
            return
        }
        
        // Unknown message: \(message)
    }
    
    // Handle JSON format from ESP32: {"cm":-1.0,"ir":0,"zone":0,"buzz":0,"mot":0}
    private func handleJSONFormat(_ json: [String: Any]) {
        guard let cm = json["cm"] as? Double else {
            print("❌ Invalid JSON format - missing 'cm' field")
            return
        }
        
        let ir = json["ir"] as? Int ?? 0
        let zone = json["zone"] as? Int ?? 0
        let buzz = json["buzz"] as? Int ?? 0
        let mot = json["mot"] as? Int ?? 0
        
        // Skip if no obstacle detected (cm < 0 means timeout, zone 0 means no obstacle)
        if cm < 0 || (zone == 0 && ir == 0) {
            print("📊 ESP32 Status: cm=\(cm), ir=\(ir), zone=\(zone), buzz=\(buzz), mot=\(mot)% - No obstacle")
            return
        }
        
        let distance = Int(cm)
        
        // Determine direction based on zone
        let direction: String
        switch zone {
        case 1: direction = "left"
        case 2: direction = "front"
        case 3: direction = "right"
        default: direction = "front"
        }
        
        // Calculate confidence based on IR sensor and motor intensity
        let confidence = ir == 1 ? 0.95 : Double(mot) / 100.0
        
        print("🚧 ESP32 Obstacle: \(distance)cm, zone=\(zone) (\(direction)), ir=\(ir), mot=\(mot)%")
        
        
        if distance <= 100 {
                    if canProcessObstacle() {
                        if isScreenOn {
                            print("📸 Obstacle within 100cm - activating camera + AI classification")
                            Task { await processBluetoothObstacleWithCamera(distance: distance, direction: direction, confidence: confidence) }
                        } else {
                            print("🔊 Screen off/background — speaking obstacle without camera, starting cooldown")
                            processingQueue.async { self.isProcessingObstacle = true }
                            speakObstacle(distance: distance)
                            startCooldown()
                        }
                    } else {
                        if isProcessingObstacle { print("⚠️ Already processing obstacle - skipping new signal") }
                        else if isInCooldown { print("⏳ Still in 10-second cooldown period - skipping new signal") }
                    }
                } else {
                    print("📏 Obstacle at \(distance)cm - too far, skipping camera activation")
                }
            }
    
    
    // Handle real ESP32 format: {"cm1": 100, "cm2": 103, "cm_min":186, "ir":1, "zone":0,"mot":0}
    private func handleRealESP32Format(_ json: [String: Any]) {
        guard let cm1 = json["cm1"] as? Double,
              let cm2 = json["cm2"] as? Double else {
            print("❌ Invalid real ESP32 format - missing 'cm1' or 'cm2' field")
            return
        }
        
        let ir = json["ir"] as? Int ?? 0
        let zone = json["zone"] as? Int ?? 0
        let mot = json["mot"] as? Int ?? 0
        let cm_min = json["cm_min"] as? Double ?? 0
        
        // Calculate average distance from cm1 and cm2
        let averageDistance = (cm1 + cm2) / 2.0
        let distance = Int(averageDistance)
        
        // Skip if no obstacle detected (average distance too far or no IR detection)
        if averageDistance > 200 || (zone == 0 && ir == 0) {
            print("📊 Real ESP32 Status: cm1=\(cm1), cm2=\(cm2), avg=\(averageDistance), ir=\(ir), zone=\(zone), mot=\(mot)% - No obstacle")
            return
        }
        
        // Determine direction based on zone
        let direction: String
        switch zone {
        case 1: direction = "left"
        case 2: direction = "front"
        case 3: direction = "right"
        default: direction = "front"
        }
        
        // Calculate confidence based on IR sensor and motor intensity
        let confidence = ir == 1 ? 0.95 : Double(mot) / 100.0
        
        print("🚧 Real ESP32 Obstacle: cm1=\(cm1), cm2=\(cm2), avg=\(averageDistance)cm, zone=\(zone) (\(direction)), ir=\(ir), mot=\(mot)%")
        
        if distance <= 100 {
            if canProcessObstacle() {
                if isScreenOn {
                    print("📸 Obstacle within 100cm - activating camera + AI classification")
                    Task { await processBluetoothObstacleWithCamera(distance: distance, direction: direction, confidence: confidence) }
                } else {
                    print("🔊 Screen off/background — speaking obstacle without camera, starting cooldown")
                    processingQueue.async { self.isProcessingObstacle = true }
                    speakObstacle(distance: distance)
                    startCooldown()
                }
            } else {
                if isProcessingObstacle { print("⚠️ Already processing obstacle - skipping new signal") }
                else if isInCooldown { print("⏳ Still in 10-second cooldown period - skipping new signal") }
            }
        } else {
            print("📏 Obstacle at \(distance)cm - too far, skipping camera activation")
 
        }
    }
    
    // Handle simple format from nRF Connect: "F:20", "L:20", "R:20", "B:20"
    private func handleSimpleFormat(_ message: String) {
        let components = message.split(separator: ":")
        guard components.count == 2,
              let directionChar = components[0].first,
              let distance = Int(components[1]) else {
            print("❌ Invalid simple format")
            return
        }
        
        let direction: String
        switch directionChar {
        case "F", "f": direction = "front"
        case "L", "l": direction = "left"
        case "R", "r": direction = "right"
        case "B", "b": direction = "back"
        default: direction = "front"
        }
        
        let confidence = 0.85
        
        print("🚧 nRF Connect Obstacle: \(distance)cm, \(direction)")
        
        
        if distance <= 100 {
            if canProcessObstacle() {
                if isScreenOn {
                    print("📸 Obstacle within 100cm - activating camera + AI classification")
                    Task { await processBluetoothObstacleWithCamera(distance: distance, direction: direction, confidence: confidence) }
                } else {
                    print("🔊 Screen off/background — speaking obstacle without camera, starting cooldown")
                    processingQueue.async { self.isProcessingObstacle = true }
                    speakObstacle(distance: distance)
                    startCooldown()
                }
            } else {
                if isProcessingObstacle { print("⚠️ Already processing obstacle - skipping new signal") }
                else if isInCooldown { print("⏳ Still in 10-second cooldown period - skipping new signal") }
            }
        } else {
            print("📏 Obstacle at \(distance)cm - too far, skipping camera activation")
 
        }
        
        // Note: Pipeline handles notifications, no need to post here
    }
    
    // Handle OBSTACLE format: "OBSTACLE:distance:direction:confidence"
    private func handleObstacleFormat(_ message: String) {
        let components = message.dropFirst(9).split(separator: ":")
        guard components.count >= 3 else {
            print("❌ Invalid OBSTACLE format")
            return
        }
        
        let distance = Int(components[0]) ?? 0
        let direction = String(components[1])
        let confidence = Double(components[2]) ?? 0.0
        
        print("🚧 Obstacle detected: \(distance)cm, \(direction), \(confidence)%")
        
        if distance <= 100 {
            if canProcessObstacle() {
                if isScreenOn {
                    print("📸 Obstacle within 100cm - activating camera + AI classification")
                    Task { await processBluetoothObstacleWithCamera(distance: distance, direction: direction, confidence: confidence) }
                } else {
                    print("🔊 Screen off/background — speaking obstacle without camera, starting cooldown")
                    processingQueue.async { self.isProcessingObstacle = true }
                    speakObstacle(distance: distance)
                    startCooldown()
                }
            } else {
                if isProcessingObstacle { print("⚠️ Already processing obstacle - skipping new signal") }
                else if isInCooldown { print("⏳ Still in 10-second cooldown period - skipping new signal") }
            }
        } else {
            print("📏 Obstacle at \(distance)cm - too far, skipping camera activation")
 
        }
        
        // Note: Pipeline handles notifications, no need to post here
    }

}

// MARK: - ESP32 SmartCane Device Model
struct ESP32SmartCane: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let peripheral: CBPeripheral?
    let rssi: Int
    let rxCharacteristic: CBCharacteristic?
    let txCharacteristic: CBCharacteristic?
    
    init(name: String, peripheral: CBPeripheral?, rssi: Int, rxCharacteristic: CBCharacteristic? = nil, txCharacteristic: CBCharacteristic? = nil) {
        self.name = name
        self.peripheral = peripheral
        self.rssi = rssi
        self.rxCharacteristic = rxCharacteristic
        self.txCharacteristic = txCharacteristic
    }
    
    static func == (lhs: ESP32SmartCane, rhs: ESP32SmartCane) -> Bool {
        return lhs.peripheral?.identifier == rhs.peripheral?.identifier
    }
}

// MARK: - Bluetooth Connection State
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

// MARK: - Notification Names
extension Notification.Name {
    static let obstacleDetected = Notification.Name("obstacleDetected")
}

