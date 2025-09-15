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

            
            SettingsScreen()
                .tabItem { Label("Setting", systemImage: "gearshape.fill")}

                .tag(1)
            // MARK: - Map Tab
            // This is the first tab that shows the map with location services and search
            MapView()
                .tabItem {
                    // This sets the icon and text for the tab bar item
                    Image(systemName: "map")        // Uses SF Symbols for the map icon
                    Text("Map")                     // Text label shown below the icon
                }
                .tag(2)
            
            // MARK: - Saved Locations Tab
            // This is the second tab that shows a list of user's saved locations
            SavedLocationsView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")  // Pin icon for saved locations
                    Text("Saved")                             // Tab label
                }
                .tag(3)
            
            // MARK: - Object Detection Tab
            // This is the third tab for AI-powered obstacle detection using photos
            ObjectDetectionView()
                .tabItem {
                    Image(systemName: "camera.viewfinder")    // Camera icon for detection
                    Text("Detection")                         // Tab label
                }
                .tag(4)
            
            // MARK: - Profile Tab
            // This is the fourth tab for user settings, profile, and app information
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")        // Person icon for profile
                    Text("Profile")                           // Tab label
                }
                .tag(5)
        

        }
        .onChange(of: selectedTab) { newValue in
            speakTabChange(newValue)
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
        SpeechManager.shared.speak(_text: "Settings tab selected")

    case 2:
        SpeechManager.shared.speak(_text: "Mapview tab selected")
    case 3:
        SpeechManager.shared.speak(_text: "Saved location tab selected")
    case 4:
        SpeechManager.shared.speak(_text: "Obstacle detection tab selected")
    case 5:
        SpeechManager.shared.speak(_text: "Profile tab selected")

    default:
        #warning("Unhandled tab selection")
        
    }
}
