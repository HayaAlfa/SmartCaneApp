//
//  OpenSmartCaneIntents.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 10/17/25.
//

import Foundation
import AppIntents
@available(iOS 16.0, *)


struct OpenSmartCaneIntent: AppIntent {
    static var title: LocalizedStringResource = "Open SmartCane"
    static var description = IntentDescription("Opens the SmartCane app using Siri or Shortcuts.")
    static var openAppWhenRun: Bool = true

//    static var parameterSummary: some ParameterSummary {
//            Summary("Open SmartCane")
//        }

    

    func perform() async throws -> some IntentResult & ProvidesDialog {
         AppGroup.userDefaults.set(false, forKey: "OpenObstacleLogFromSiri")
         return .result(dialog: "Opening SmartCane.")
     }

}
