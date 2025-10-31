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
    @Published var savedLocations: [SavedLocation] = []
    @Published var userRoutes: [SavedRoute] = []
    
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

    // MARK: - Locations Table Models
    struct SavedLocationInsert: Encodable {
        let user_id: UUID
        let name: String
        let address: String?
        let latitude: Double
        let longitude: Double
        let created_at: Date? = nil
    }

    struct LocationRow: Decodable, Identifiable {
        let id: UUID
        let user_id: UUID
        let name: String
        let address: String?
        let latitude: Double
        let longitude: Double
        let created_at: Date?
    }

    // MARK: - Locations: Save
    @MainActor
    func saveUserLocation(_ location: SavedLocation) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            // When signed out, save to user-specific key to prevent mixing accounts
            let userId = UUID().uuidString // Temporary ID for signed-out user
            let userKey = "SavedLocations_\(userId)"
            var local = savedLocations
            local.insert(location, at: 0)
            savedLocations = local
            if let encoded = try? JSONEncoder().encode(local) {
                UserDefaults.standard.set(encoded, forKey: userKey)
            }
            print("⚠️ Not authenticated. Saved location locally with user-specific key: \(location.name)")
            return
        }

        let insert = SavedLocationInsert(
            user_id: userId,
            name: location.name,
            address: location.address,
            latitude: location.latitude,
            longitude: location.longitude
        )

        try await supabase
            .from("locations")
            .insert(insert)
            .execute()

        print("✅ Location saved:", location.name)
    }

    // MARK: - Locations: Fetch
    @MainActor
    func fetchUserLocations() async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            // When signed out, don't load old data (it might be from a different account)
            self.savedLocations = []
            print("⚠️ Not authenticated. Cleared locations (user-specific data required).")
            return
        }

        let rows: [LocationRow] = try await supabase
            .from("locations")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        let mapped: [SavedLocation] = rows.map { row in
            SavedLocation(
                id: row.id,
                name: row.name,
                address: row.address ?? "",
                latitude: row.latitude,
                longitude: row.longitude,
                notes: "",
                created_at: row.created_at ?? Date()
            )
        }

        self.savedLocations = mapped
        
        // Clear old global UserDefaults key to prevent mixing accounts
        UserDefaults.standard.removeObject(forKey: "SavedLocations")
        
        print("✅ Loaded locations from Supabase:", mapped.count)
    }

    // MARK: - Locations: Delete
    @MainActor
    func deleteUserLocation(_ location: SavedLocation) async throws {
        if let userId = supabase.auth.currentUser?.id {
            try await supabase
                .from("locations")
                .delete()
                .eq("id", value: location.id)
                .eq("user_id", value: userId)
                .execute()
            print("🗑️ Deleted location:", location.name)
            try await fetchUserLocations()
            return
        }

        // Signed out: delete from local (using user-specific key if available)
        savedLocations.removeAll { $0.id == location.id }
        // Note: When signed out, locations are stored in memory only
        // No UserDefaults persistence for signed-out users to prevent account mixing
    }
    // MARK: - Routes Table Models
    struct RouteInsert: Encodable {
        let user_id: UUID
        let name: String
        let description: String?
        let start_name: String
        let start_address: String
        let start_lat: Double
        let start_lon: Double
        let end_name: String
        let end_address: String
        let end_lat: Double
        let end_lon: Double
    }

    struct RouteRow: Decodable, Identifiable {
        let id: UUID
        let user_id: UUID
        let name: String
        let description: String?
        let start_name: String
        let start_address: String
        let start_lat: Double
        let start_lon: Double
        let end_name: String
        let end_address: String
        let end_lat: Double
        let end_lon: Double
        let created_at: Date?
    }

    // MARK: - Routes: Save
    @MainActor
    func saveUserRoute(_ route: SavedRoute) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            // When signed out, save locally (in memory only - no UserDefaults for routes when signed out)
            var local = userRoutes
            local.insert(route, at: 0)
            userRoutes = local
            print("⚠️ Not authenticated. Saved route locally: \(route.name)")
            return
        }

        let insert = RouteInsert(
            user_id: userId,
            name: route.name,
            description: route.description,
            start_name: route.startLocation.name,
            start_address: route.startLocation.address,
            start_lat: route.startLocation.latitude,
            start_lon: route.startLocation.longitude,
            end_name: route.endLocation.name,
            end_address: route.endLocation.address,
            end_lat: route.endLocation.latitude,
            end_lon: route.endLocation.longitude
        )

        print("🧾 Saving route for user:", userId)
        print("🧭 Route name:", route.name)

        try await supabase
            .from("routes")
            .insert(insert)
            .execute()

        // Reload after saving
        try await fetchUserRoutes()
        
        // Also save to UserDefaults as local cache
        if let encoded = try? JSONEncoder().encode(userRoutes) {
            UserDefaults.standard.set(encoded, forKey: "SavedRoutes")
        }
        
        print("✅ Route saved successfully")
    }

    // MARK: - Routes: Fetch
    @MainActor
    func fetchUserRoutes() async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            // When signed out, don't load old data (it might be from a different account)
            self.userRoutes = []
            print("⚠️ Not authenticated. Cleared routes (user-specific data required).")
            return
        }

        let rows: [RouteRow] = try await supabase
            .from("routes")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        let mapped: [SavedRoute] = rows.map { row in
            let start = SavedLocation(
                id: UUID(),
                name: row.start_name,
                address: row.start_address,
                latitude: row.start_lat,
                longitude: row.start_lon,
                notes: "",
                created_at: row.created_at ?? Date()
            )
            let end = SavedLocation(
                id: UUID(),
                name: row.end_name,
                address: row.end_address,
                latitude: row.end_lat,
                longitude: row.end_lon,
                notes: "",
                created_at: row.created_at ?? Date()
            )

            var route = SavedRoute(
                name: row.name,
                startLocation: start,
                endLocation: end,
                description: row.description ?? ""
            )
            route.id = row.id
            return route
        }

        self.userRoutes = mapped
        
        // Clear old global UserDefaults key to prevent mixing accounts
        UserDefaults.standard.removeObject(forKey: "SavedRoutes")
        
        // Update UserDefaults with fresh data from Supabase
        if let encoded = try? JSONEncoder().encode(mapped) {
            UserDefaults.standard.set(encoded, forKey: "SavedRoutes")
        }
        
        print("✅ Loaded routes from Supabase:", mapped.count)
    }

    // MARK: - Routes: Delete
    @MainActor
    func deleteUserRoute(_ route: SavedRoute) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            // Signed out: delete from local (in memory only)
            userRoutes.removeAll { $0.id == route.id }
            print("🗑️ Deleted route from local:", route.name)
            return
        }

        try await supabase
            .from("routes")
            .delete()
            .eq("id", value: route.id)
            .eq("user_id", value: userId)
            .execute()

        // Update local state
        userRoutes.removeAll { $0.id == route.id }
        print("🗑️ Deleted route:", route.name)
        
        // Reload to ensure consistency
        try await fetchUserRoutes()
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
        // Disabled TTS here to avoid duplicate announcements; Pipeline handles speaking
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
        print("🔔 Obstacle log announced (silent): \(message)")
        // SpeechManager.shared.speak(_text: message)
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
