//
//  ObstacleLog.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/17/25.
//

import Foundation

// MARK: - Obstacle Log Model
/// Represents a single obstacle detection event fetched from or sent to Supabase.
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

    /// Designated initializer used when transforming Supabase payloads into app models.
    init(id: UUID? = nil,
         deviceId: String? = nil,
         userId: UUID? = nil,
         obstacleType: String,
         distanceCm: Int? = nil,
         confidenceScore: Double? = nil,
         sensorType: String? = nil,
         latitude: Double? = nil,
         longitude: Double? = nil,
         timestamp: Date? = nil,
         userVerified: Bool? = nil,
         severityLevel: Int? = nil,
         createdAt: Date? = nil) {
        self.id = id
        self.deviceId = deviceId
        self.userId = userId
        self.obstacleType = obstacleType
        self.distanceCm = distanceCm
        self.confidenceScore = confidenceScore
        self.sensorType = sensorType
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.userVerified = userVerified
        self.severityLevel = severityLevel
        self.createdAt = createdAt
    }

    /// Convenience initializer for creating new obstacle logs on-device before uploading.
    init(deviceId: String,
         obstacleType: String,
         distanceCm: Int,
         confidenceScore: Double,
         sensorType: String,
         severityLevel: Int,
         latitude: Double? = nil,
         longitude: Double? = nil) {
        self.init(
            id: nil,
            deviceId: deviceId,
            userId: nil,
            obstacleType: obstacleType,
            distanceCm: distanceCm,
            confidenceScore: confidenceScore,
            sensorType: sensorType,
            latitude: latitude,
            longitude: longitude,
            timestamp: Date(),
            userVerified: nil,
            severityLevel: severityLevel,
            createdAt: nil
        )
    }
}

// MARK: - Presentation Helpers
extension ObstacleLog {
    /// Returns the most relevant date for display purposes.
    var displayDate: Date? {
        createdAt ?? timestamp
    }

    /// Formats the display date using a concise date/time style.
    var formattedTimestamp: String {
        guard let date = displayDate else { return "—" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    /// Human friendly identifier for the originating device.
    var deviceDisplayName: String {
        deviceId ?? "Unknown Device"
    }

    /// Sample data used for SwiftUI previews and tests.
    static var sampleData: [ObstacleLog] {
        [
            ObstacleLog(
                id: UUID(),
                deviceId: "cane-001",
                obstacleType: "Wall",
                distanceCm: 120,
                confidenceScore: 0.95,
                sensorType: "ultrasonic",
                latitude: 25.7617,
                longitude: -80.1918,
                timestamp: Date().addingTimeInterval(-1_800),
                userVerified: true,
                severityLevel: 2,
                createdAt: Date().addingTimeInterval(-1_800)
            ),
            ObstacleLog(
                id: UUID(),
                deviceId: "cane-002",
                obstacleType: "Stairs",
                distanceCm: 80,
                confidenceScore: 0.87,
                sensorType: "infrared",
                latitude: 25.7743,
                longitude: -80.1937,
                timestamp: Date().addingTimeInterval(-3_600),
                userVerified: nil,
                severityLevel: 3,
                createdAt: Date().addingTimeInterval(-3_600)
            ),
            ObstacleLog(
                id: UUID(),
                deviceId: "cane-003",
                obstacleType: "Person",
                distanceCm: 150,
                confidenceScore: 0.78,
                sensorType: "camera",
                latitude: 25.783,
                longitude: -80.2101,
                timestamp: Date().addingTimeInterval(-5_400),
                userVerified: false,
                severityLevel: 1,
                createdAt: Date().addingTimeInterval(-5_400)
            )
        ]
    }
}
