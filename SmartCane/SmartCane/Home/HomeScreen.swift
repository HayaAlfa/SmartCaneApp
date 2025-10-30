//
//  HomeScreen.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI

// MARK: - Home Screen
// This is the main home screen that provides quick access to all app features
// It displays a grid of buttons for easy navigation to different sections
struct HomeScreen: View {
    @Binding var selectedTab: Int
    @StateObject private var recognizer = SpeechRecognizer()
    @EnvironmentObject private var dataService: SmartCaneDataService

    
    @AppStorage("OpenObstacleLogFromSiri", store: AppGroup.userDefaults) private var openObstacleLogFromSiri = false
    @AppStorage("OpenMyRoutesFromSiri", store: AppGroup.userDefaults) private var openMyRoutesFromSiri = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var navigateToObstacleLogs = false
    
    // Removed navigateToObstacleLogs - no longer needed
    
    @State private var navigateToNavigation = false
    @State private var navigateToMyRoutes = false
    
    
    @Environment(\.scenePhase) private var scenePhase
    
    
    // MARK: - Main Body
    // This defines the main user interface of the home screen
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // MARK: - Screen Title
                // Dynamic type makes the title scalable for accessibility
                let displayName: String = {
                    print("🔍 Debug - authViewModel.username: '\(authViewModel.username)'")
                    print("🔍 Debug - authViewModel.email: '\(authViewModel.email)'")
                    print("🔍 Debug - UserDefaults username: '\(UserDefaults.standard.string(forKey: "username") ?? "nil")'")
                    
                    // Check if username is actually an email (contains @)
                    if !authViewModel.username.isEmpty && !authViewModel.username.contains("@") {
                        print("✅ Using authViewModel.username: \(authViewModel.username)")
                        return authViewModel.username
                    } else if let storedUsername = UserDefaults.standard.string(forKey: "username"), !storedUsername.isEmpty {
                        if storedUsername.contains("@") {
                            // Extract username from stored email
                            let extracted = String(storedUsername.prefix(while: { $0 != "@" }))
                            print("✅ Using extracted from stored email: \(extracted)")
                            return extracted
                        } else {
                            print("✅ Using stored username: \(storedUsername)")
                            return storedUsername
                        }
                    } else if !authViewModel.email.isEmpty {
                        // Extract username from email (part before @)
                        let extracted = String(authViewModel.email.prefix(while: { $0 != "@" }))
                        print("✅ Using extracted from email: \(extracted)")
                        return extracted
                    } else if !authViewModel.username.isEmpty && authViewModel.username.contains("@") {
                        // Extract username from authViewModel.username if it's an email
                        let extracted = String(authViewModel.username.prefix(while: { $0 != "@" }))
                        print("✅ Using extracted from authViewModel.username: \(extracted)")
                        return extracted
                    } else {
                        print("❌ Using Guest fallback")
                        return "Guest"
                    }
                }()
                
                Text("Hello, \(displayName)!")
                    .font(.title) // Dynamic type - scales with user's accessibility settings
                    .padding(.top, 20)
                
                // MARK: - Visual Separator
                // Divider provides visual separation between title and content
                Divider()
                
                // MARK: - Navigation Buttons Grid
                // LazyVGrid creates a responsive grid layout that adapts to screen size
                // Two columns with flexible sizing and 20-point spacing
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    // MARK: - My Locations Button
                    // NavigationLink wraps the button to enable navigation to SavedLocationsView
                    NavigationLink(destination: SavedLocationsView(selectedTab: $selectedTab)){
                        HomeButtonView(
                            title: "My Locations",
                            systemImage: "mappin.and.ellipse"  // Changed from "list.bullet" to location pin icon
                        )
                    }
                    .buttonStyle(PlainButtonStyle())  // Removes default NavigationLink styling
                    .simultaneousGesture(TapGesture().onEnded {
                        // Provide voice feedback when button is tapped
                        SpeechManager.shared.speak(_text: "My locations selected")
                        
                    })
                    
                    // MARK: - My Routes Button
                    // Button to manage saved familiar routes
                    NavigationLink(destination: MyRoutesView()) {
                        HomeButtonView(
                            title: "My Routes",
                            systemImage: "map.circle.fill"  // Route/map icon for saved routes
                        )
                    }
                    .buttonStyle(PlainButtonStyle())  // Removes default NavigationLink styling
                    .simultaneousGesture(TapGesture().onEnded {
                        // Provide voice feedback when button is tapped
                        SpeechManager.shared.speak(_text: "My routes selected")
                    })
                    
                    // MARK: - Profile Button
                    // NavigationLink wraps the button to enable navigation to ProfileView
                    NavigationLink(destination: ProfileView()) {
                        HomeButtonView(
                            title: "Profile",
                            systemImage: "person.fill"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())  // Removes default NavigationLink styling
                    .simultaneousGesture(TapGesture().onEnded {
                        // Provide voice feedback when button is tapped
                        SpeechManager.shared.speak(_text: "Profile selected")
                    })
                    
                    NavigationLink(destination: ObstacleLogsView()) {
                        HomeButtonView(
                            title: "Obstacle Logs",
                            systemImage: "list.bullet.rectangle"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(TapGesture().onEnded {
                        SpeechManager.shared.speak(_text: "Obstacle logs selected")
                    })
                    
                }
                .navigationDestination(for: String.self) { destination in
                    if destination == "ObstacleLogs" {
                        ObstacleLogsView()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openObstacleLogs)) { _ in
                    // Siri intent triggers this notification
                    navigateToObstacleLogs = true
//                    SpeechManager.shared.speak(_text: "Opening obstacle logs")
                }
                .padding(.top, 30)
                
                // --- Centered Live Mode Button ---
//                VStack {
//                    NavigationLink(destination: LiveScreen()) {
//                        Label("Live Mode", systemImage: "antenna.radiowaves.left.and.right")
//                            .font(.title.bold())
//                            .foregroundColor(Theme.brand)
//                            .padding(.vertical, 20)
//                            .padding(.horizontal, 30)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .background(
//                        RoundedRectangle(cornerRadius: 15)
//                            .stroke(Theme.brand, lineWidth: 2)
//                    )
//                }
//                .frame(maxWidth: .infinity)
//                .padding(.top, 18)
                
   
                .padding(.top, 30)
                
                 // MARK: - Spacer
                 // Pushes all content to the top of the screen
                 Spacer()
                 
                 // NavigationLinks for Siri intents
                 NavigationLink(destination: ObstacleLogsView(), isActive: $navigateToObstacleLogs) { EmptyView() }
                 NavigationLink(destination: LiveScreen(), isActive: $navigateToNavigation) { EmptyView() }
                 NavigationLink(destination: MyRoutesView(), isActive: $navigateToMyRoutes) { EmptyView() }
                
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)  // Makes title smaller and inline
            
            //            // 🧠 On transcript change — detect commands
            //            .onChange(of: recognizer.transcript) { newValue in
            //                let transcript = newValue.lowercased()
            //                if transcript.contains("open obstacle logs") {
            //                    navigateToObstacleLogs = true
            //                    SpeechManager.shared.speak(_text: "Opening obstacle logs")
            //                } else if transcript.contains("start navigation") {
            //                    navigateToNavigation = true
            //                    SpeechManager.shared.speak(_text: "Starting navigation")
            //                }
            //              }
            //
            
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    if openObstacleLogFromSiri {
                        navigateToObstacleLogs = true
                        openObstacleLogFromSiri = false
//                        SpeechManager.shared.speak(_text: "Obstacle log opened.")
                    } else if openMyRoutesFromSiri {
                        navigateToMyRoutes = true
                        openMyRoutesFromSiri = false
//                        SpeechManager.shared.speak(_text: "Opening my routes.")
                    } else {
//                        SpeechManager.shared.speak(_text: "SmartCane is open. Say a command to begin.")
                    }
                }
            }
                    
        // 🧠 On transcript change — detect commands
                    .onChange(of: recognizer.transcript) { newValue in
                        let transcript = newValue.lowercased()
                        if transcript.contains("open obstacle logs") {
                            // Obstacle logs can be accessed via the button on home screen
                            SpeechManager.shared.speak(_text: "Obstacle logs available on home screen")
                        } else if transcript.contains("start navigation") {
                            navigateToNavigation = true
                            SpeechManager.shared.speak(_text: "Starting navigation")
                        }
                    }
                    
                }
            }
        }
        
        
        // MARK: - Preview
        // Shows the view in Xcode's canvas for design purposes
        
        // MARK: - Reusable Home Button Component (with action)
        // This is a custom button component used for buttons that need custom actions
        // It provides consistent styling and behavior for all navigation buttons
        struct HomeButton: View {
            // MARK: - Properties
            let title: String        // Text displayed on the button
            let systemImage: String  // SF Symbol icon name
            let action: () -> Void   // Function to call when button is tapped
            
            // MARK: - Button Body
            // This defines the visual appearance and behavior of the button
            var body: some View {
                Button(action: action) {  // Call the action function when tapped
                    VStack {
                        // MARK: - Icon Display
                        // SF Symbol icon that represents the button's function
                        Image(systemName: systemImage)
                            .resizable()                    // Allows icon to be resized
                            .scaledToFit()                  // Maintains aspect ratio
                            .frame(width: 40, height: 40)   // Fixed size for consistency
                            .foregroundColor(.primary)      // Uses system primary color (adapts to light/dark mode)
                        
                        // MARK: - Title Text
                        // Button title text with accessibility-friendly font
                        Text(title)
                            .font(.body)                    // Scalable for dynamic type (accessibility)
                            .multilineTextAlignment(.center) // Centers text for better appearance
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)  // Makes button fill available width
                    .background(
                        RoundedRectangle(cornerRadius: 15)      // Rounded corners for modern look
                            .stroke(Color.primary, lineWidth: 1) // Border using system primary color
                    )
                }
                .buttonStyle(PlainButtonStyle())  // Removes default button styling for custom appearance
            }
        }
        struct HomeNavButton<Destination: View>: View {
            let title: String
            let systemImage: String
            let destination: Destination
            
            var body: some View {
                NavigationLink(destination: destination) {
                    VStack {
                        Image(systemName: systemImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.primary)
                        Text(title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(RoundedRectangle(cornerRadius: 15).stroke(Color.primary, lineWidth: 1))
                }
            }
        }
        // MARK: - Home Button View Component (without action)
        // This is a view-only version of the home button used inside NavigationLinks
        // It provides the same visual styling but without button functionality
        struct HomeButtonView: View {
            // MARK: - Properties
            let title: String        // Text displayed on the button
            let systemImage: String  // SF Symbol icon name
            
            // MARK: - View Body
            // This defines the visual appearance of the button view
            var body: some View {
                VStack {
                    // MARK: - Icon Display
                    // SF Symbol icon that represents the button's function
                    Image(systemName: systemImage)
                        .resizable()                    // Allows icon to be resized
                        .scaledToFit()                  // Maintains aspect ratio
                        .frame(width: 60, height: 60)   // Bigger size for easier tapping
                        .foregroundColor(.primary)      // Uses system primary color (adapts to light/dark mode)
                    
                    // MARK: - Title Text
                    // Button title text with accessibility-friendly font
                    Text(title)
                        .font(.body.bold())             // Bold and scalable for dynamic type (accessibility)
                        .multilineTextAlignment(.center) // Centers text for better appearance
                }
                .frame(maxWidth: .infinity, minHeight: 140)  // Makes button fill available width with bigger height
                .background(
                    RoundedRectangle(cornerRadius: 15)      // Rounded corners for modern look
                        .stroke(Color.primary, lineWidth: 1) // Border using system primary color
                )
            }
        }
        
    

