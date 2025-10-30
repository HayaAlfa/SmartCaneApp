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
    // MARK: - Singleton
    static let shared = Pipeline()
    
    // Published properties for UI feedback
    @Published var isSaving = false
    @Published var appError: AppError?

    private let speech = SpeechManager.shared
    private let dataService: SmartCaneDataService

    private init(dataService: SmartCaneDataService = SmartCaneDataService()) {
        self.dataService = dataService
    }

    // MARK: - Handle Incoming Obstacle
    func handleIncomingObstacle(distance: Int,
                                direction: String,
                                obstacleType: String,
                                confidence: Double) async {
        guard let user = supabase.auth.currentUser else {
            appError = .database("You must be signed in to record obstacle logs.")
            return
        }

        isSaving = true
        defer { isSaving = false }

        // 1️⃣ Build log model
        let log = ObstacleLog(
            id: nil,
            deviceId: "SmartCane_001",
            userId: user.id,
            obstacleType: obstacleType,  // Now saves AI-classified type instead of direction
            distanceCm: distance,
            confidenceScore: confidence,
            sensorType: "ultrasonic",
            latitude: nil,
            longitude: nil,
            timestamp: Date(),
            userVerified: nil,
            severityLevel: 1,
            createdAt: nil
        )

        // 2️⃣ Save to Supabase with retry
        do {
            try await saveLogWithRetry(log)
            // Saved obstacle log
            NotificationCenter.default.post(name: .obstacleDetected, object: nil)
            // 3️⃣ Voice feedback: replace only the type, keep original phrasing
            let spokenType = obstacleType.isEmpty ? "Obstacle" : obstacleType
            speech.speak(_text: "\(spokenType) \(direction) at \(distance) centimeters away.")
            appError = nil
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
                SpeechManager.shared.speak(_text: "Obstacle detected ahead.")

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
