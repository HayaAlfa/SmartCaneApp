import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/hayaalfakieh/Downloads/SmartCaneApp/SmartCane/SmartCane/MainTabView.swift", line: 1)
//
//  MainTabView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label(__designTimeString("#7374_0", fallback: "Home"), systemImage: __designTimeString("#7374_1", fallback: "house.fill"))}
            
            MapScreen ()
                .tabItem { Label(__designTimeString("#7374_2", fallback: "Map"), systemImage: __designTimeString("#7374_3", fallback: "map.fill"))}
            
            SettingsScreen()
                .tabItem { Label(__designTimeString("#7374_4", fallback: "Setting"), systemImage: __designTimeString("#7374_5", fallback: "gearshape.fill"))}
            
        }
        .tint(Theme.brand)
        .background(Theme.bg)
    }
}
#Preview {MainTabView()}
#Preview("Dark Mode") {
    MainTabView()
        .preferredColorScheme(.dark)
}
