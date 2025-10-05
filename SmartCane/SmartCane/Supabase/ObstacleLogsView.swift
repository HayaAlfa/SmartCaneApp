//
//  ObstacleLogsView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/21/25.
//

import SwiftUI

struct ObstacleLogsView: View {
    @StateObject private var dataService = SmartCaneDataService()
    @State private var isLoading = true
    @State private var appError: AppError?
    @State private var showConfirm = false        // for clear button alert
    
    var body: some View {
        ZStack {
            VStack {
                Button("➕ Add Test Log") {
                    Task {
                        await Pipeline().handleIncomingObstacle(
                            distance: 120,
                            direction: "front",
                            confidence: 0.95
                        )
                    }
                }
                .padding(.vertical)

                List(dataService.obstacleLogs) { log in
                    VStack(alignment: .leading) {
                        Text(log.obstacleType)
                            .font(.headline)
                        Text(
                            (log.createdAt ?? log.timestamp)?
                                .formatted(date: .abbreviated, time: .shortened) ?? "—"
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
                await loadLogs()
            }
            .onReceive(NotificationCenter.default.publisher(for: .obstacleDetected)) { _ in
                Task { @MainActor in
                    await dataService.fetchObstacleLogs()
                }
            }
            
            // 🔄 loading overlay
            if isLoading {
                ProgressView("Loading obstacle logs…")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
            
            // ⚠️ simple error banner
            if let err = appError {
                VStack {
                    Spacer()
                    Text(err.localizedDescription)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
    
    // MARK: - Helpers
    private func loadLogs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            await dataService.fetchObstacleLogs()
        } catch {
            appError = .database("Could not fetch obstacle logs. Check your connection.")
        }
    }
}
