//
//  SmartCaneApp.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/29/25.
//

import SwiftUI

@main
struct SmartCaneApp: App {
    @AppStorage(AppKeys.darkModeEnabled) private var darkModeEnabled: Bool = false
    var body: some Scene {
        WindowGroup {
            MainTabView()

                .preferredColorScheme(darkModeEnabled ? .dark : .light)
           

        }
    }
}
