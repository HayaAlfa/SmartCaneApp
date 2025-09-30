//
//  HomeScreen.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI

struct HomeScreen: View {
    var body: some View {
        NavigationView {
            VStack {
                // Title
                Text("Smart Cane")
                    .font(.title) // dynamic type make it scalable
                    .padding(.top, 40)
                
                Divider()


                // Extra spacing before buttons
                Spacer().frame(height: 60) // adjust this number for more/less gap

                // Grid of buttons
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
                    
                    HomeButton(title: "My Locations", systemImage: "location.circle") {
                        SpeechManager.shared.speak(_text: "My Locations button tapped")
                    }
                    
                    HomeButton(title: "Navigation", systemImage: "map.fill") {
                        SpeechManager.shared.speak(_text: "Navigation button tapped")
                    }
                    
                    HomeNavButton(title: "Obstacle Logs", systemImage: "list.bullet", destination: ObstacleLogsView())
                }
                .padding(.horizontal, 20) // ✅ now correctly inside VStack

                Spacer() // pushes content down so it's not stuck at top

            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
    // Reusable home button
struct HomeButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action){
            VStack {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.body) //scalable for dynamic type
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(RoundedRectangle(cornerRadius: 15).stroke(Color.primary, lineWidth: 1))
        }
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
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(RoundedRectangle(cornerRadius: 15).stroke(Color.primary, lineWidth: 1))
            
        }
        .simultaneousGesture(TapGesture().onEnded {
            SpeechManager.shared.speak(_text: "\(title) button tapped")
        })
    }
}
