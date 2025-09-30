
//
//  Obstacle.swift
//  SmartCane
//
//  Created by Thu Hieu Truong on 8/30/25.
//

import Foundation

struct Obstacle: Identifiable, Codable {
    let id = UUID()        // auto-generate, don’t decode from JSON
    var type: String
    var latitude: Double
    var longitude: Double
    var detectedAt: Date
    var distance: Float

    // Only decode/encode the real JSON fields
    private enum CodingKeys: String, CodingKey {
        case type, latitude, longitude, detectedAt, distance
    }
}

// Storage
var savedObstacles: [Obstacle] = []

// Example mock JSON
let mockBluetoothJSON = """
[
    {"type": "Pole", "latitude": 37.7749, "longitude": -122.4194, "detectedAt": "2025-08-30T10:00:00Z"},
    {"type": "Trash Can", "latitude": 37.7755, "longitude": -122.4180, "detectedAt": "2025-08-30T10:05:00Z"}
]
"""

func parseObstacles(from json: String) -> [Obstacle] {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard let data = json.data(using: .utf8) else {
        print("⚠️ JSON conversion failed")
        return []
    }
    
    do {
        let obstacles = try decoder.decode([Obstacle].self, from: data)
        savedObstacles.append(contentsOf: obstacles)
        return obstacles
    } catch {
        print("⚠️ Failed to decode JSON:", error)
        return []
    }
}


