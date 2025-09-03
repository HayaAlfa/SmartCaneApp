//
//  MainTabView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI


struct MainTabView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem { Label("Home", systemImage: "house.fill")}
                .tag(0)
            
            MapScreen ()
                .tabItem { Label("Map", systemImage: "map.fill")}
                .tag(1)
            
            SettingsScreen()
                .tabItem { Label("Setting", systemImage: "gearshape.fill")}
                .tag(2)
            
        }
        .onChange(of: selectedTab) {
            speakTabChange(selectedTab)
            
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

private func speakTabChange(_ tab: Int) {
    switch tab {
    case 0:
        SpeechManager.shared.speak(_text: "Home tab selected")
    case 1:
        SpeechManager.shared.speak(_text: "Map tab selected")
    case 2:
        SpeechManager.shared.speak(_text: "Settings tab selected")
    default:
        #warning("Unhandled tab selection")
        
    }
}
