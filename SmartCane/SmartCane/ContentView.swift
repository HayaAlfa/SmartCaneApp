//
//  ContentView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/29/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // MARK: - Main Tab Navigation
        // TabView creates the bottom tab bar that allows users to switch between different screens
        TabView {
            // MARK: - Map Tab
            // This is the first tab that shows the map with location marker and search bar
            MapView()
                .tabItem {
                    // This sets the icon and text for the tab bar item
                    Image(systemName: "map")        // Uses SF Symbols for the map icon
                    Text("Map")                     // Text label shown below the icon
                }
            
            // MARK: - Saved Locations Tab
            // This is the second tab that shows a list of saved locations with categories
            SavedLocationsView()
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")  // Pin icon for saved locations
                    Text("Saved")                             // Tab label
                }
            
            // MARK: - Object Detection Tab
            // This is the third tab for AI-powered obstacle detection using photos
            ObjectDetectionView()
                .tabItem {
                    Image(systemName: "camera.viewfinder")    // Camera icon for detection
                    Text("Detection")                         // Tab label
                }
            
            // MARK: - Profile Tab
            // This is the fourth tab for user settings, profile, and app information
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")        // Person icon for profile
                    Text("Profile")                           // Tab label
                }
        }
        .accentColor(.blue)  // Sets the blue color for selected tabs and active elements
    }
}

// MARK: - Preview
// This allows you to see the view in Xcode's canvas/preview
#Preview {
    ContentView()
}
