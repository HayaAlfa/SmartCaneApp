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
        NavigationStack {
            Text(__designTimeString("#7480_0", fallback: "Home Screen Placeholder"))
                .navigationTitle(__designTimeString("#7480_1", fallback: "Home"))
        }
    }
}
#Preview {
    HomeScreen()
}

