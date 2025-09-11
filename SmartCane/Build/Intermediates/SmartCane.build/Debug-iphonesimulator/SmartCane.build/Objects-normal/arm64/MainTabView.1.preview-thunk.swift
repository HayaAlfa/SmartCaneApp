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
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem { Label(__designTimeString("#7007_0", fallback: "Home"), systemImage: __designTimeString("#7007_1", fallback: "house.fill"))}
                .tag(__designTimeInteger("#7007_2", fallback: 0))
            
            MapScreen ()
                .tabItem { Label(__designTimeString("#7007_3", fallback: "Map"), systemImage: __designTimeString("#7007_4", fallback: "map.fill"))}
                .tag(__designTimeInteger("#7007_5", fallback: 1))
            
            SettingsScreen()
                .tabItem { Label(__designTimeString("#7007_6", fallback: "Setting"), systemImage: __designTimeString("#7007_7", fallback: "gearshape.fill"))}
                .tag(__designTimeInteger("#7007_8", fallback: 2))
            // MARK: - Map Tab
            // This is the first tab that shows the map with location services and search
            MapView()
                .tabItem {
                    // This sets the icon and text for the tab bar item
                    Image(systemName: __designTimeString("#7007_9", fallback: "map"))        // Uses SF Symbols for the map icon
                    Text(__designTimeString("#7007_10", fallback: "Map"))                     // Text label shown below the icon
                }
                .tag(__designTimeInteger("#7007_11", fallback: 3))
            
            // MARK: - Saved Locations Tab
            // This is the second tab that shows a list of user's saved locations
            SavedLocationsView()
                .tabItem {
                    Image(systemName: __designTimeString("#7007_12", fallback: "mappin.and.ellipse"))  // Pin icon for saved locations
                    Text(__designTimeString("#7007_13", fallback: "Saved"))                             // Tab label
                }
                .tag(__designTimeInteger("#7007_14", fallback: 4))
            
            // MARK: - Object Detection Tab
            // This is the third tab for AI-powered obstacle detection using photos
            ObjectDetectionView()
                .tabItem {
                    Image(systemName: __designTimeString("#7007_15", fallback: "camera.viewfinder"))    // Camera icon for detection
                    Text(__designTimeString("#7007_16", fallback: "Detection"))                         // Tab label
                }
                .tag(__designTimeInteger("#7007_17", fallback: 5))
            
            // MARK: - Profile Tab
            // This is the fourth tab for user settings, profile, and app information
            ProfileView()
                .tabItem {
                    Image(systemName: __designTimeString("#7007_18", fallback: "person.circle"))        // Person icon for profile
                    Text(__designTimeString("#7007_19", fallback: "Profile"))                           // Tab label
                }
                .tag(__designTimeInteger("#7007_20", fallback: 6))
            
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
        SpeechManager.shared.speak(_text: __designTimeString("#7007_21", fallback: "Home tab selected"))
    case 1:
        SpeechManager.shared.speak(_text: __designTimeString("#7007_22", fallback: "Map tab selected"))
    case 2:
        SpeechManager.shared.speak(_text: __designTimeString("#7007_23", fallback: "Settings tab selected"))
    case 3:
        SpeechManager.shared.speak(_text: __designTimeString("#7007_24", fallback: "Mapview tab selected"))
    case 4:
        SpeechManager.shared.speak(_text: __designTimeString("#7007_25", fallback: "Saved location tab selected"))
    case 5:
        SpeechManager.shared.speak(_text: __designTimeString("#7007_26", fallback: "Obstacle detection tab selected"))
    case 6:
        SpeechManager.shared.speak(_text: __designTimeString("#7007_27", fallback: "Profile tab selected"))
    default:
        #warning("Unhandled tab selection")
        
    }
}
