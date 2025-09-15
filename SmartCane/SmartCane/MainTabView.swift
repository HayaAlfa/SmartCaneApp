//
//  MainTabView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI

// MARK: - Main Tab View
// This is the root navigation view that contains all the main app screens
// It provides bottom tab navigation between different features of the SmartCane app
struct MainTabView: View {
    // MARK: - State Properties
    // Tracks which tab is currently selected (0 = Home, 1 = Map, 2 = Detection)
    @State private var selectedTab = 0
    
    // MARK: - Main Body
    // This defines the main user interface with tab navigation
    var body: some View {
        // TabView creates the bottom tab bar navigation
        // selection binding tracks which tab is currently active
        TabView(selection: $selectedTab) {
            // MARK: - Home Tab
            // First tab shows the home screen with quick access buttons
            HomeScreen(selectedTab: $selectedTab)
                .tabItem { 
                    Label("Home", systemImage: "house.fill")  // House icon for home
                }
                .tag(0)  // Unique identifier for this tab
            
            // MARK: - Map Tab
            // Second tab shows the interactive map with location services
            MapView()
                .tabItem {
                    // This sets the icon and text for the tab bar item
                    Image(systemName: "map")        // Uses SF Symbols for the map icon
                    Text("Map")                     // Text label shown below the icon
                }
                .tag(1)  // Unique identifier for this tab
            
            // MARK: - Object Detection Tab
<<<<<<< HEAD
            // Fourth tab for AI-powered obstacle detection using photos
=======
            // Third tab for AI-powered obstacle detection using photos
>>>>>>> bdea4a9f9675dcc7a084f14af7574cedd53216dc
            ObjectDetectionView()
                .tabItem {
                    Image(systemName: "camera.viewfinder")    // Camera icon for detection
                    Text("Detection")                         // Tab label
                }
                .tag(2)  // Unique identifier for this tab
<<<<<<< HEAD
            
=======
>>>>>>> bdea4a9f9675dcc7a084f14af7574cedd53216dc
        }
        // MARK: - Tab Change Handler
        // This triggers whenever user switches to a different tab
        .onChange(of: selectedTab) {
            speakTabChange(selectedTab)  // Provide voice feedback for tab changes
        }
        // MARK: - Visual Styling
        .tint(Theme.brand)      // Use app's brand color for selected tab
        .background(Theme.bg)   // Use app's background color
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {MainTabView()}
#Preview("Dark Mode") {
    MainTabView()
        .preferredColorScheme(.dark)  // Test how it looks in dark mode
}

// MARK: - Tab Change Voice Feedback
// This function provides voice feedback when user switches tabs
// It helps visually impaired users know which tab they've selected
private func speakTabChange(_ tab: Int) {
    switch tab {
    case 0:
        SpeechManager.shared.speak(_text: "Home tab selected")
    case 1:
<<<<<<< HEAD
        SpeechManager.shared.speak(_text: "Map tab selected")
    case 2:
        SpeechManager.shared.speak(_text: "Object detection selected")
=======
        SpeechManager.shared.speak(_text: "Mapview selected")
    case 2:
        SpeechManager.shared.speak(_text: "Objects detection selected")
>>>>>>> bdea4a9f9675dcc7a084f14af7574cedd53216dc
    default:
        SpeechManager.shared.speak(_text: "Tab selected")
    }
}
