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
            VStack(spacing: 20) {
                Text("Home")
                    .font(.title) //dynamic type make it scalable
                    .padding(.top)
                
                Divider()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    // Buttons on Home
                    HomeButton(title: "My Locations", systemImage: "list.bullet")
                    HomeButton(title: "Navigation", systemImage: "map.fill")
                }
                .padding()
                
                // Example Speak button for testing
                Button("Speak") {
                    SpeechManager.shared.speak(_text:"Welcome to Smart Cane. Navigation assistance activated.")
                }
                .padding(.top, 30)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeScreen()
}

// Reusable home button
struct HomeButton: View {
    let title: String
    let systemImage: String
    
    var body: some View {
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
