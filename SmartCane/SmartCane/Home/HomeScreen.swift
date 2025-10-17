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
    @State private var navigateToObstacleLogs = false
    @State private var navigateToNavigation = false
    
    
    // MARK: - Main Body
    // This defines the main user interface of the home screen
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // MARK: - Screen Title
                // Dynamic type makes the title scalable for accessibility
                let username = UserDefaults.standard.string(forKey: "username") ?? "Guest"
                Text("Hello, \(username)!")
                    .font(.title) // Dynamic type - scales with user's accessibility settings
                    .padding(.top)
                
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
                .padding(.top, 30)

                // --- Centered Live Mode Button ---
                VStack {
                    NavigationLink(destination: LiveScreen()) {
                        Label("Live Mode", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.title2.bold())
                            .foregroundColor(Theme.brand)
                            .padding(.vertical, 10)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 18)

                // --- Centered Voice Command Section ---
                VStack {
                    Text("🎤 Say a command")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                // The rest of the VStack for transcript and mic button...
                VStack {
                    Text(recognizer.transcript)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Theme.brand)
                                .frame(width: 72, height: 72)
                                .shadow(radius: 5)
                            Button(action: {
                                try? recognizer.startRecording()
                            }) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(.white)
                                    .accessibility(label: Text("Start voice command recording"))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Spacer()
                    }
                    Button("Stop") {
                        recognizer.stopRecording()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom, 30)
                    
                    
                    // MARK: - Spacer
                    // Pushes all content to the top of the screen
                    Spacer()
                NavigationLink(destination: ObstacleLogsView(),
                                               isActive: $navigateToObstacleLogs) { EmptyView() }

                NavigationLink(destination: LiveScreen(),
                                               isActive: $navigateToNavigation) { EmptyView() }
                }
                .padding()
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)  // Makes title smaller and inline
            // 🧠 On transcript change — detect commands
            .onChange(of: recognizer.transcript) { newValue in
                let transcript = newValue.lowercased()
                if transcript.contains("open obstacle logs") {
                    navigateToObstacleLogs = true
                    SpeechManager.shared.speak(_text: "Opening obstacle logs")
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
    }
    

