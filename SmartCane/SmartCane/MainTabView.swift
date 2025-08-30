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
                .tabItem { Label("Home", systemImage: "house.fill")}
            
            MapScreen ()
                .tabItem { Label("Map", systemImage: "map.fill")}
            
            SettingsScreen()
                .tabItem { Label("Setting", systemImage: "gearshape.fill")}
            
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
