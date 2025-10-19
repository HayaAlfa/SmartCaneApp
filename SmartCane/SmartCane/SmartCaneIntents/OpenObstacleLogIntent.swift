//
//  OpenObstacleLogIntent.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 10/17/25.
//

import Foundation
import AppIntents

@available(iOS 16.0, *)
struct OpenObstacleLogIntent: AppIntent {
    static var title: LocalizedStringResource = "Open obstacle Log"
    static var description = IntentDescription("Opens the obstacle log screen in SmartCane.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        UserDefaults.standard.set(true, forKey: "OpenObstacleLogFromSiri")

        // Tell Siri what to say
        return .result(dialog: "Opening obstacle log.")
    }
}
