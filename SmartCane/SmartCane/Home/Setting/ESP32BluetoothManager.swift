//
//  ESP32BluetoothManager.swift
//  SmartCane
//
//  Created for ESP32 SmartCane integration
//

import Foundation
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
    
    // ESP32 Service and Characteristic UUIDs
    static let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") // Nordic UART Service
    static let rxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // RX (Write)
    static let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // TX (Notify)
    
    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for ESP32 SmartCane devices
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        
        print("🔍 Starting scan for ESP32 SmartCane devices...")
        centralManager.scanForPeripherals(withServices: [Self.serviceUUID], options: nil)
    }
    
    /// Stop scanning for devices
    func stopScanning() {
        centralManager.stopScan()
        print("🛑 Stopped scanning")
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Check if this is a SmartCane device
        guard peripheral.name?.contains("SmartCane") == true else { return }
        
        let device = ESP32SmartCane(
            name: peripheral.name ?? "Unknown SmartCane",
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
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        // Discover services
        peripheral.discoverServices([Self.serviceUUID])
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
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect to ESP32 SmartCane: \(error?.localizedDescription ?? "Unknown error")")
        connectionState = .disconnected
    }
}

// MARK: - CBPeripheralDelegate
extension ESP32BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == Self.serviceUUID {
                print("🔍 Discovered ESP32 service")
                peripheral.discoverCharacteristics([Self.rxCharacteristicUUID, Self.txCharacteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        var rxCharacteristic: CBCharacteristic?
        var txCharacteristic: CBCharacteristic?
        
        for characteristic in characteristics {
            if characteristic.uuid == Self.rxCharacteristicUUID {
                rxCharacteristic = characteristic
                print("📤 Found RX characteristic (Write)")
            } else if characteristic.uuid == Self.txCharacteristicUUID {
                txCharacteristic = characteristic
                print("📥 Found TX characteristic (Notify)")
                
                // Subscribe to notifications
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        // Create connected device
        if let rxChar = rxCharacteristic, let txChar = txCharacteristic {
            connectedDevice = ESP32SmartCane(
                name: peripheral.name ?? "SmartCane",
                peripheral: peripheral,
                rssi: 0,
                rxCharacteristic: rxChar,
                txCharacteristic: txChar
            )
            
            isConnected = true
            connectionState = .connected
            print("✅ ESP32 SmartCane fully connected and ready")
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
        print("📥 Raw message from ESP32: \(message)")
        
        // Use SensorSignalProcessor to parse the message
        let sensorProcessor = SensorSignal()
        let parsedResult = sensorProcessor.receiveSignal(message)
        
        print("📝 Parsed result: \(parsedResult)")
        
        // Post notification with parsed result
        NotificationCenter.default.post(
            name: .obstacleDetected,
            object: nil,
            userInfo: [
                "rawMessage": message,
                "parsedResult": parsedResult
            ]
        )
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

