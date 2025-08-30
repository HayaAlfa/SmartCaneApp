//
//  ContentView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/29/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
    
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
