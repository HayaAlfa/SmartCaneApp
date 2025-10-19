//
//  ObstacleLogsView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/21/25.
//

import SwiftUI

struct ObstacleLogsView: View {
    @StateObject private var dataService: SmartCaneDataService
    @State private var isLoading = true
    @State private var appError: AppError?
    @State private var showConfirm = false        // for clear button alert

    init() {
        let sharedService = SmartCaneDataService()
        _dataService = StateObject(wrappedValue: sharedService)
    }
    
    var body: some View {
        ZStack {
            VStack {
                Button("➕ Add Test Log") {
                    Task { await addTestLog() }
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
                    try? await dataService.fetchObstacleLogs()
                    if let latest = dataService.obstacleLogs.first {
                             let type = latest.obstacleType
                             let time = latest.createdAt?.formatted(date: .omitted, time: .shortened) ?? "just now"
                             let spokenText = "Obstacle detected: \(type), at \(time)."
                             SpeechManager.shared.speak(_text: spokenText)
                             print("🔊 Speaking: \(spokenText)")
                         }
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
    @MainActor
    private func loadLogs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await dataService.fetchObstacleLogs()
        } catch SmartCaneDataServiceError.notAuthenticated {
            appError = .database("Please sign in to view your obstacle logs.")
            dataService.obstacleLogs = []
        } catch {
            appError = .database("Could not fetch obstacle logs. \(error.localizedDescription)")
        }
    }

    @MainActor
    private func addTestLog() async {
        await Pipeline.shared.handleIncomingObstacle(
            distance: 120,
            direction: "front",
            obstacleType: "test obstacle",  // Test obstacle type
            confidence: 0.95
        )
        appError = Pipeline.shared.appError
        
        if let lastObstacle = dataService.obstacleLogs.first {
            let obstacleDescription = "\(lastObstacle.obstacleType) detected at \(lastObstacle.createdAt?.formatted(date: .omitted, time: .shortened) ?? "unknown time")"
            if let username = UserDefaults.standard.string(forKey: "username") {
                UserDefaults.standard.set(obstacleDescription, forKey: "lastObstacleDescription_\(username)")
            }
            print("🗂️ Saved for Siri: \(obstacleDescription)")
        }

    }
}
