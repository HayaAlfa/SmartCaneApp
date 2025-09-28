//
//  SmartCaneModels.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/18/25.
//

import Foundation

// MARK: - Obstacle Log Model
struct ObstacleLog: Codable, Identifiable {
    let id: UUID?
    let deviceId: String?
    let userId: UUID?
    let obstacleType: String
    let distanceCm: Int?
    let confidenceScore: Double?
    let sensorType: String?
    let latitude: Double?
    let longitude: Double?
    let timestamp: Date?
    let userVerified: Bool?
    let severityLevel: Int?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case userId = "user_id"
        case obstacleType = "obstacle_type"
        case distanceCm = "distance_cm"
        case confidenceScore = "confidence_score"
        case sensorType = "sensor_type"
        case latitude
        case longitude
        case timestamp
        case userVerified = "user_verified"
        case severityLevel = "severity_level"
        case createdAt = "created_at"
    }
    
    // Initialize for new obstacle detection
    init(deviceId: String,
         obstacleType: String,
         distanceCm: Int,
         confidenceScore: Double,
         sensorType: String,
         severityLevel: Int,
         latitude: Double? = nil,
         longitude: Double? = nil) {
        self.id = nil
        self.deviceId = deviceId
        self.userId = nil
        self.obstacleType = obstacleType
        self.distanceCm = distanceCm
        self.confidenceScore = confidenceScore
        self.sensorType = sensorType
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = Date()
        self.userVerified = nil
        self.severityLevel = severityLevel
        self.createdAt = nil
    }
}

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
