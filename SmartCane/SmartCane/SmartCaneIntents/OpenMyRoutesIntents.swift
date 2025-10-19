//
//  OpenMyRoutesIntents.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 10/19/25.
//

import Foundation
import AppIntents

@available(iOS 16.0, *)
struct OpenMyRoutesIntents: AppIntent {
    static var title: LocalizedStringResource = "Open my routes in SmartCane"
    static var description = IntentDescription("Open the my routes screen in SmartCane using Siri.")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppGroup.userDefaults.set(true, forKey: "OpenMyRoutesFromSiri")
        return .result(dialog: "Opening my routes.")
    }
}
