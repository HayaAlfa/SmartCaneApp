//
//  MainTabView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI

// MARK: - Color Extension
extension Color {
    var uiColor: UIColor {
        return UIColor(self)
    }
}

// MARK: - Main Tab View
// This is the root navigation view that contains all the main app screens
// It provides bottom tab navigation between different features of the SmartCane app
struct MainTabView: View {
    // MARK: - State Properties
    // Tracks which tab is currently selected (0 = Home, 1 = Map, 2 = Detection)
    @Binding var isAuthenticated: Bool   // ✅ added to handle logout
    private let onSignOut: () async -> Void

    init(isAuthenticated: Binding<Bool>, onSignOut: @escaping () async -> Void = {}) {
        self._isAuthenticated = isAuthenticated
        self.onSignOut = onSignOut
    }

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



            ObjectDetectionView()
                .tabItem {
                    Image(systemName: "camera.viewfinder")    // Camera icon for detection
                    Text("Detection")                         // Tab label
                }
                .tag(2)  // Unique identifier for this tab

            SettingsScreen(onSignOut: onSignOut)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)

        
        }
        .onAppear {
            // Customize the tab bar appearance to make it larger
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            // Increase tab bar height and content size
            appearance.shadowColor = UIColor.systemGray4
            appearance.backgroundColor = .white
            
            // Larger title font
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.black
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            
            // Larger icon size through padding
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.darkGray
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
            
            // Apply the appearance
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        // MARK: - Tab Change Handler
        // This triggers whenever user switches to a different tab
        .onChange(of: selectedTab) { newTab in
            if newTab == 0 {
                NotificationCenter.default.post(name: .homeTabSelected, object: nil)
            }
        }
        // MARK: - Visual Styling
        .tint(Theme.brand)      // Use app's brand color for selected tab
        .background(Theme.bg)   // Use app's background color
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview { MainTabView(isAuthenticated: .constant(true)) }
#Preview("Dark Mode") {
    MainTabView(isAuthenticated: .constant(true))
        .preferredColorScheme(.dark)
}


// MARK: - Tab Change Voice Feedback
// This function provides voice feedback when user switches tabs
// It helps visually impaired users know which tab they've selected
//private func speakTabChange(_ tab: Int) {
//    switch tab {
//    case 0:
//        SpeechManager.shared.speak(_text: "Home tab selected")
//        
//    case 1:
//
//        SpeechManager.shared.speak(_text: "Mapview selected")
//        
//    case 2:
//        SpeechManager.shared.speak(_text: "Objects detection selected")
//
//    case 3:
//        SpeechManager.shared.speak(_text: "Settings selected")
//
//    default:
//        SpeechManager.shared.speak(_text: "Tab selected")
//    }
//}
