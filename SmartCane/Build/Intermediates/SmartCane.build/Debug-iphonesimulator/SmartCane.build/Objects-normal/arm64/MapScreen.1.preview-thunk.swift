import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/hayaalfakieh/Downloads/SmartCaneApp/SmartCane/SmartCane/MapScreen.swift", line: 1)
//
//  MapScreen.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI

struct MapScreen: View {
    var body: some View {
        NavigationStack {
            Text(__designTimeString("#646_0", fallback: "Map Screen Placeholder"))
                .navigationTitle(__designTimeString("#646_1", fallback: "Map"))
            
            Button(__designTimeString("#646_2", fallback: "Speak")) {
                SpeechManager.shared.speak(_text: __designTimeString("#646_3", fallback: "Maps Screen"))
            }
        }
    }
}
#Preview {
    MapScreen()
}

