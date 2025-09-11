import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/hayaalfakieh/Downloads/SmartCaneApp/SmartCane/SmartCane/HomeScreen.swift", line: 1)
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
            VStack(spacing: __designTimeInteger("#1433_0", fallback: 20)) {
                Text(__designTimeString("#1433_1", fallback: "Home"))
                    .font(.title) //dynamic type make it scalable
                    .padding(.top)
                
                Divider()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: __designTimeInteger("#1433_2", fallback: 20)) {
                    // Buttons on Home
                    HomeButton(title: __designTimeString("#1433_3", fallback: "My Locations"), systemImage: __designTimeString("#1433_4", fallback: "list.bullet"))
                    HomeButton(title: __designTimeString("#1433_5", fallback: "Navigation"), systemImage: __designTimeString("#1433_6", fallback: "map.fill"))
                }
                .padding()
                
                // Example Speak button for testing
                Button(__designTimeString("#1433_7", fallback: "Speak")) {
                    SpeechManager.shared.speak(_text:__designTimeString("#1433_8", fallback: "Welcome to Smart Cane. Navigation assistance activated."))
                }
                .padding(.top, __designTimeInteger("#1433_9", fallback: 30))
                
                Spacer()
            }
            .padding()
            .navigationTitle(__designTimeString("#1433_10", fallback: "Home"))
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
                .frame(width: __designTimeInteger("#1433_11", fallback: 40), height: __designTimeInteger("#1433_12", fallback: 40))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.body) //scalable for dynamic type
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: __designTimeInteger("#1433_13", fallback: 100))
        .background(RoundedRectangle(cornerRadius: __designTimeInteger("#1433_14", fallback: 15)).stroke(Color.primary, lineWidth: __designTimeInteger("#1433_15", fallback: 1)))
    }
}
