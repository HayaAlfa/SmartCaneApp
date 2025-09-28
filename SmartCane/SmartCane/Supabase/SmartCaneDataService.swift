//
//  SmartCaneDataService.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/17/25.
//

import Foundation
import Supabase
import PostgREST

class SmartCaneDataService: ObservableObject {
    @Published var obstacleLogs: [ObstacleLog] = []
    
    // Track which obstacle logs have already been announced via text-to-speech
    private var announcedObstacleKeys: Set<String> = []
    private var hasLoadedInitialLogs = false
    private var currentDeviceFilter: String?
    
    struct ObstacleLogInsert: Encodable {
        let device_id: String
        let obstacle_type: String
        let distance_cm: Int?
        let confidence_score: Double?
        let sensor_type: String?
        let latitude: Double?
        let longitude: Double?
        let severity_level: Int?
        let user_id: UUID?
    }
    
    // MARK: - Insert log into Supabase
    @MainActor
    func saveObstacleLog(_ obstacle: ObstacleLog) async {
        do {
            let insert = ObstacleLogInsert(
                device_id: obstacle.deviceId ?? "cane-001",
                obstacle_type: obstacle.obstacleType,
                distance_cm: obstacle.distanceCm,
                confidence_score: obstacle.confidenceScore,
                sensor_type: obstacle.sensorType,
                latitude: obstacle.latitude,
                longitude: obstacle.longitude,
                severity_level: obstacle.severityLevel,
                user_id: obstacle.userId
            )
            
            try await supabase
                .from("obstacle_logs")
                .insert(insert)
                .execute()
            
            print("✅ Obstacle log inserted!")
            await fetchObstacleLogs(deviceId: currentDeviceFilter)
        } catch {
            print("❌ Insert failed: \(error)")
        }
    }
    
    // MARK: - Fetch logs from Supabase
    @MainActor
    func fetchObstacleLogs(deviceId: String? = nil) async {
        do {
            if deviceId != currentDeviceFilter {
                currentDeviceFilter = deviceId
                resetAnnouncementTracking()
            }

            var query = supabase
                .from("obstacle_logs")
                .select()
            
            if let id = deviceId, !id.isEmpty {
                query = query.eq("device_id", value: id)
            }
            
            let logs: [ObstacleLog] = try await query
                .execute()
                .value
            
            let logKeys = logs.map(announcementKey(for:))
            let newLogs: [ObstacleLog]
            if hasLoadedInitialLogs {
                newLogs = zip(logs, logKeys)
                    .filter { !announcedObstacleKeys.contains($0.1) }
                    .map { $0.0 }
            } else {
                newLogs = []
                hasLoadedInitialLogs = true
            }
            logKeys.forEach { announcedObstacleKeys.insert($0) }

            newLogs.forEach { announceObstacleLog($0) }
            self.obstacleLogs = logs
            print("✅ Loaded obstacle logs: \(logs.count)")
        } catch {
            print("❌ Error fetching logs: \(error)")
        }
    }

    // MARK: - Announcement Helpers
    private func resetAnnouncementTracking() {
        announcedObstacleKeys.removeAll()
        hasLoadedInitialLogs = false
    }

    private func announcementKey(for log: ObstacleLog) -> String {
        if let id = log.id {
            return "id:\(id.uuidString)"
        }
        var components: [String] = ["type:\(log.obstacleType.lowercased())"]
        if let deviceId = log.deviceId, !deviceId.isEmpty {
            components.append("device:\(deviceId.lowercased())")
        }
        if let created = log.createdAt {
            components.append("created:\(created.timeIntervalSince1970)")
        } else if let timestamp = log.timestamp {
            components.append("timestamp:\(timestamp.timeIntervalSince1970)")
        } else if let distance = log.distanceCm {
            components.append("distance:\(distance)")
        }
        if let severity = log.severityLevel {
            components.append("severity:\(severity)")
        }
        return components.joined(separator: "|")
    }

    private func announceObstacleLog(_ log: ObstacleLog) {
        var phrases: [String] = ["New obstacle detected: \(log.obstacleType.capitalized)"]
        if let distance = log.distanceCm {
            phrases.append("\(distance) centimeters away")
        }
        if let severity = log.severityLevel {
            let severityDescription: String
            switch severity {
            case Int.min...0:
                severityDescription = "unknown severity"
            case 1:
                severityDescription = "low severity"
            case 2:
                severityDescription = "medium severity"
            case 3:
                severityDescription = "high severity"
            default:
                severityDescription = "severity level \(severity)"
            }
            phrases.append(severityDescription)
        }
        if let deviceId = log.deviceId, !deviceId.isEmpty {
            phrases.append("reported by device \(deviceId)")
        }
        let message = phrases.joined(separator: ", ")
        SpeechManager.shared.speak(_text: message)
    }
}
