//
//  AppGroupUserDefaults.swift
//  SmartCane
//
//  Created by Codex on 3/17/24.
//

import Foundation

enum AppGroup {
    static let identifier = "group.com.haya.SmartCane"

    static var userDefaults: UserDefaults {
        if let shared = UserDefaults(suiteName: identifier) {
            return shared
        }

        assertionFailure("App Group \(identifier) is not configured. Falling back to standard UserDefaults.")
        return .standard
    }
}

