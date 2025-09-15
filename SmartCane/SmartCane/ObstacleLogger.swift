//
//  ObstacleLogger.swift
//  SmartCane
//
//  Created by Assistant on 12/19/24.
//

import Foundation

// MARK: - Simple Obstacle Logger
// Basic logging for obstacle detection events
class ObstacleLogger {
    
    // MARK: - Singleton
    static let shared = ObstacleLogger()
    
    // MARK: - Simple Event Model
    struct ObstacleEvent: Codable {
        let id: String
        let timestamp: Date
        let obstacleType: String
        let confidence: Double
        let action: String  // "detected", "saved", "dismissed"
    }
    
    // MARK: - Properties
    private var events: [ObstacleEvent] = []
    
    // MARK: - Private Init
    private init() {
        loadEvents()
    }
    
    // MARK: - Logging Methods
    
    // Log when AI detects an obstacle
    func logDetection(obstacleType: String, confidence: Double) {
        let event = ObstacleEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            obstacleType: obstacleType,
            confidence: confidence,
            action: "detected"
        )
        
        events.append(event)
        saveEvents()
        print("🔍 Logged detection: \(obstacleType) (\(confidence))")
    }
    
    // Log when user saves a detection
    func logSave(obstacleType: String, confidence: Double) {
        let event = ObstacleEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            obstacleType: obstacleType,
            confidence: confidence,
            action: "saved"
        )
        
        events.append(event)
        saveEvents()
        print("💾 Logged save: \(obstacleType)")
    }
    
    // Log when user dismisses a detection
    func logDismiss(obstacleType: String, confidence: Double) {
        let event = ObstacleEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            obstacleType: obstacleType,
            confidence: confidence,
            action: "dismissed"
        )
        
        events.append(event)
        saveEvents()
        print("❌ Logged dismiss: \(obstacleType)")
    }
    
    // MARK: - Helper Methods
    
    // Get all events
    func getAllEvents() -> [ObstacleEvent] {
        return events
    }
    
    // Get recent events (last 10)
    func getRecentEvents() -> [ObstacleEvent] {
        return Array(events.suffix(10))
    }
    
    // Get detection count
    func getDetectionCount() -> Int {
        return events.filter { $0.action == "detected" }.count
    }
    
    // Clear all events
    func clearAll() {
        events.removeAll()
        UserDefaults.standard.removeObject(forKey: "ObstacleEvents")
        print("🗑️ Cleared all events")
    }
    
    // MARK: - Storage
    
    // Save events to UserDefaults
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "ObstacleEvents")
        }
    }
    
    // Load events from UserDefaults
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: "ObstacleEvents"),
           let decoded = try? JSONDecoder().decode([ObstacleEvent].self, from: data) {
            events = decoded
            print("📊 Loaded \(decoded.count) events")
        }
    }
}
