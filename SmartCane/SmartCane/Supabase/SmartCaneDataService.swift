//
//  SmartCaneDataService.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/17/25.
//

import Foundation
import Supabase
import PostgREST

enum SmartCaneDataServiceError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You need to be signed in to manage obstacle logs."
        }
    }
}

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
    func saveObstacleLog(_ obstacle: ObstacleLog) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            print("❌ No logged-in user")
            throw SmartCaneDataServiceError.notAuthenticated
        }
        
        let insert = ObstacleLogInsert(
            device_id: obstacle.deviceId ?? "cane-001",
            obstacle_type: obstacle.obstacleType,
            distance_cm: obstacle.distanceCm,
            confidence_score: obstacle.confidenceScore,
            sensor_type: obstacle.sensorType,
            latitude: obstacle.latitude,
            longitude: obstacle.longitude,
            severity_level: obstacle.severityLevel,
            user_id: userId // ✅ Tie log to the logged-in user
        )
        
        try await supabase
            .from("obstacle_logs")
            .insert(insert)
            .execute()
        
        print("✅ Obstacle log inserted!")
        // Note: Pipeline will handle notification and refresh

    }

    @MainActor
    func fetchObstacleLogs(deviceId: String? = nil) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw SmartCaneDataServiceError.notAuthenticated
        }

        if deviceId != currentDeviceFilter {
            currentDeviceFilter = deviceId
            resetAnnouncementTracking()
        }

        var query = supabase
            .from("obstacle_logs")
            .select()
            .eq("user_id", value: userId) // ✅ Only this user's logs

        if let id = deviceId, !id.isEmpty {
            query = query.eq("device_id", value: id)
        }
        
        let logs: [ObstacleLog] = try await query
            .order("created_at", ascending: false) // ✅ newest first
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
    
    @MainActor
    func refreshLastObstacleForSiri() async {
        guard let userId = supabase.auth.currentUser?.id else { return }
        
        do {
            // Get only the latest obstacle for this user
            let latest: [ObstacleLog] = try await supabase
                .from("obstacle_logs")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            if let newest = latest.first {
                        let obstacleType = newest.obstacleType.capitalized
                        let formattedTime = newest.createdAt?.formatted(date: .omitted, time: .shortened)
                            ?? newest.timestamp?.formatted(date: .omitted, time: .shortened)
                            ?? "an unknown time"
                        
                        // ✅ Full spoken phrase for Siri
                        let sentence = "\(obstacleType) detected at \(formattedTime)."
                        
                        // Save per-user Siri key
                        let username = UserDefaults.standard.string(forKey: "username") ?? "unknown"
                        UserDefaults.standard.set(sentence, forKey: "lastObstacleDescription_\(username)")
                        
                        print("✅ Siri cache refreshed for \(username): \(sentence)")
                    } else {
                        let username = UserDefaults.standard.string(forKey: "username") ?? "unknown"
                        UserDefaults.standard.removeObject(forKey: "lastObstacleDescription_\(username)")
                        print("⚠️ No obstacles found for \(username)")
                    }
                } catch {
                    print("❌ Failed to refresh Siri cache:", error.localizedDescription)
                }
    }


}
