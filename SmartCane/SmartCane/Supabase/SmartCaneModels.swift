//
//  SmartCaneModels.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/18/25.
//

import Foundation

// MARK: - Device Status Model
struct DeviceStatus: Codable, Identifiable {
    let id: UUID?
    let deviceId: String
    let batteryLevel: Int
    let wifiSignalStrength: Int?
    let lastHeartbeat: Date?
    let firmwareVersion: String?
    let isActive: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case batteryLevel = "battery_level"
        case wifiSignalStrength = "wifi_signal_strength"
        case lastHeartbeat = "last_heartbeat"
        case firmwareVersion = "firmware_version"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
    
    // Initialize for device status update
    init(deviceId: String,
         batteryLevel: Int,
         firmwareVersion: String? = nil) {
        self.id = nil
        self.deviceId = deviceId
        self.batteryLevel = batteryLevel
        self.wifiSignalStrength = nil
        self.lastHeartbeat = Date()
        self.firmwareVersion = firmwareVersion
        self.isActive = true
        self.createdAt = nil
    }
}
