//
//  Pipeline.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 10/4/25.
//

import Foundation
import AVFoundation

@MainActor
final class Pipeline: ObservableObject {
    // Published properties for UI feedback
    @Published var isSaving = false
    @Published var appError: AppError?

    private let speech = SpeechManager.shared
    private let dataService = SmartCaneDataService()

    // MARK: - Handle Incoming Obstacle
    func handleIncomingObstacle(distance: Int,
                                direction: String,
                                confidence: Double) async {
        isSaving = true
        defer { isSaving = false }

        // 1️⃣ Build log model
        let log = ObstacleLog(
            deviceId: "SmartCane_001",
            obstacleType: direction,
            distanceCm: distance,
            confidenceScore: confidence,
            sensorType: "ultrasonic",
            severityLevel: 1,
            latitude: nil,
            longitude: nil
        )

        // 2️⃣ Save to Supabase with retry
        do {
            try await saveLogWithRetry(log)
            print("✅ Saved obstacle log to Supabase")
            // 3️⃣ Voice feedback
            speech.speak(_text: "Obstacle \(direction) at \(distance) centimeters away.")
        } catch {
            print("❌ Save failed: \(error.localizedDescription)")
            appError = .database("Could not save to Supabase. Check your connection.")
        }
    }

    // MARK: - Retry Helper
    private func saveLogWithRetry(_ log: ObstacleLog) async throws {
        for attempt in 1...3 {
            do {
                try await dataService.saveObstacleLog(log)
                return
            } catch {
                if attempt == 3 { throw error }
                try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s delay before retry
            }
        }
    }
}

// MARK: - Unified App Error Type
enum AppError: LocalizedError, Identifiable {
    var id: String { localizedDescription }

    case bluetooth(String)
    case network(String)
    case database(String)

    var errorDescription: String? {
        switch self {
        case .bluetooth(let msg),
             .network(let msg),
             .database(let msg):
            return msg
        }
    }
}
