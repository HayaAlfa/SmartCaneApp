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
        VStack {
            Image(systemName: __designTimeString("#6881_0", fallback: "globe"))
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(__designTimeString("#6881_1", fallback: "Hello, world!"))
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
