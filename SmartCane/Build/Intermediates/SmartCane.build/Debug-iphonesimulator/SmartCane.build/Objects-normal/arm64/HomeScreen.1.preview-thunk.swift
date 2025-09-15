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
            VStack(spacing: __designTimeInteger("#5110_0", fallback: 20)) {
                Text(__designTimeString("#5110_1", fallback: "Home"))
                    .font(.title) //dynamic type make it scalable
                    .padding(.top)
                
                Divider()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: __designTimeInteger("#5110_2", fallback: 20)) {
                    // Buttons on Home
                    HomeButton(title: __designTimeString("#5110_3", fallback: "My Locations"), systemImage: __designTimeString("#5110_4", fallback: "list.bullet"))
                    HomeButton(title: __designTimeString("#5110_5", fallback: "Navigation"), systemImage: __designTimeString("#5110_6", fallback: "map.fill"))
                }
                .padding()
                
                // Example Speak button for testing
                Button(__designTimeString("#5110_7", fallback: "Speak")) {
                    SpeechManager.shared.speak(_text:__designTimeString("#5110_8", fallback: "Welcome to Smart Cane. Navigation assistance activated."))
                }
                .padding(.top, __designTimeInteger("#5110_9", fallback: 30))
                
                Spacer()
            }
            .padding()
            .navigationTitle(__designTimeString("#5110_10", fallback: "Home"))
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
                .frame(width: __designTimeInteger("#5110_11", fallback: 40), height: __designTimeInteger("#5110_12", fallback: 40))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.body) //scalable for dynamic type
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: __designTimeInteger("#5110_13", fallback: 100))
        .background(RoundedRectangle(cornerRadius: __designTimeInteger("#5110_14", fallback: 15)).stroke(Color.primary, lineWidth: __designTimeInteger("#5110_15", fallback: 1)))
    }
}
