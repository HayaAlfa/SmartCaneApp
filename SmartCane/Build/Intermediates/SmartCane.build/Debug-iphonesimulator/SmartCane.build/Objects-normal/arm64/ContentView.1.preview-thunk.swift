import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/hayaalfakieh/Downloads/SmartCaneApp/SmartCane/SmartCane/ContentView.swift", line: 1)
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
            // This is the first tab that shows the map with location services and search
            MapView()
                .tabItem {
                    // This sets the icon and text for the tab bar item
                    Image(systemName: __designTimeString("#27882_0", fallback: "map"))        // Uses SF Symbols for the map icon
                    Text(__designTimeString("#27882_1", fallback: "Map"))                     // Text label shown below the icon
                }
            
            // MARK: - Saved Locations Tab
            // This is the second tab that shows a list of user's saved locations
            SavedLocationsView()
                .tabItem {
                    Image(systemName: __designTimeString("#27882_2", fallback: "mappin.and.ellipse"))  // Pin icon for saved locations
                    Text(__designTimeString("#27882_3", fallback: "Saved"))                             // Tab label
                }
            
            // MARK: - Object Detection Tab
            // This is the third tab for AI-powered obstacle detection using photos
            ObjectDetectionView()
                .tabItem {
                    Image(systemName: __designTimeString("#27882_4", fallback: "camera.viewfinder"))    // Camera icon for detection
                    Text(__designTimeString("#27882_5", fallback: "Detection"))                         // Tab label
                }
            
            // MARK: - Profile Tab
            // This is the fourth tab for user settings, profile, and app information
            ProfileView()
                .tabItem {
                    Image(systemName: __designTimeString("#27882_6", fallback: "person.circle"))        // Person icon for profile
                    Text(__designTimeString("#27882_7", fallback: "Profile"))                           // Tab label
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

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
