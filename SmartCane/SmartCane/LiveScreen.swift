//
//  LiveScreen.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 10/4/25.
//

import SwiftUI

struct LiveScreen: View {
    @StateObject private var pipeline = Pipeline()

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Smart Cane Live Mode")
                    .font(.title2).bold()

                Button("Simulate Obstacle") {
                    Task {
                        await pipeline.handleIncomingObstacle(
                            distance: 125,
                            direction: "front",
                            confidence: 0.95
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            // 🔄 show progress while saving
            if pipeline.isSaving {
                ProgressView("Saving to Supabase…")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
        // ⚠️ show error alerts if something fails
        .alert(item: $pipeline.appError) { err in
            Alert(
                title: Text("Error"),
                message: Text(err.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
