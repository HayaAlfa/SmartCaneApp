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
    
    struct ObstacleLogInsert: Encodable { let device_id: String; let obstacle_type: String; let user_id: UUID? }
    
    @MainActor
    func saveObstacleLog(_ obstacle: ObstacleLog) async {
        do {
            let insert = ObstacleLogInsert(
                device_id: obstacle.deviceId ?? "cane-001",
                obstacle_type: obstacle.obstacleType,
                user_id: obstacle.userId
            )
            
            try await supabase
                .from("obstacle_logs")
                .insert(insert)
                .execute()
            
            print("✅ Obstacle log inserted!")
            await fetchObstacleLogs()
        } catch {
            print("❌ Insert failed: \(error)")
        }
    }
    
    // MARK: - Fetch logs
    @MainActor
    func fetchObstacleLogs(deviceId: String? = nil) async {
        do {
            var query = supabase
                .from("obstacle_logs")
                .select()
            
            if let id = deviceId, !id.isEmpty {
                query = query.eq("device_id", value: id)
            }
            
            let logs: [ObstacleLog] = try await query
                .execute()
                .value
            
            self.obstacleLogs = logs
            print("✅ Loaded obstacle logs: \(logs.count)")
        } catch {
            print("❌ Error fetching logs: \(error)")
        }
    }
}
