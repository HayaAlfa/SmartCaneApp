//
//  Untitled.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/21/25.
//
import SwiftUI

struct ObstacleLogsView: View {
    @StateObject private var dataService = SmartCaneDataService()
    
    var body: some View {
        VStack {
            Button("➕ Add Test Log") {
                Task {
                    let newLog = ObstacleLog(
                        deviceId: "cane-001",
                        obstacleType: "Wall",
                        distanceCm: 120,
                        confidenceScore: 0.95,
                        sensorType: "ultrasonic",
                        severityLevel: 2,
                        latitude: 25.7617,
                        longitude: -80.1918
                    )
                    await dataService.saveObstacleLog(newLog)
                }
            }
            .padding(.vertical)

            List(dataService.obstacleLogs) { log in
                VStack(alignment: .leading) {
                    Text(log.obstacleType)
                        .font(.headline)
                    // Show createdAt if available, else fallback to timestamp
                    Text(
                        (log.createdAt ?? log.timestamp)?.formatted(date: .abbreviated, time: .shortened) ?? "—"
                    )
                        .font(.subheadline)
                    Text("Device: \(log.deviceId ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Obstacle Logs")
        .task {
            await dataService.fetchObstacleLogs()
        }
    }
}
