import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/hayaalfakieh/Downloads/SmartCaneApp/SmartCane/SmartCane/MainTabView.swift", line: 1)
//
//  MainTabView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI


struct MainTabView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem { Label(__designTimeString("#4762_0", fallback: "Home"), systemImage: __designTimeString("#4762_1", fallback: "house.fill"))}
                .tag(__designTimeInteger("#4762_2", fallback: 0))
            
            MapScreen ()
                .tabItem { Label(__designTimeString("#4762_3", fallback: "Map"), systemImage: __designTimeString("#4762_4", fallback: "map.fill"))}
                .tag(__designTimeInteger("#4762_5", fallback: 1))
            
            SettingsScreen()
                .tabItem { Label(__designTimeString("#4762_6", fallback: "Setting"), systemImage: __designTimeString("#4762_7", fallback: "gearshape.fill"))}
                .tag(__designTimeInteger("#4762_8", fallback: 2))
            
        }
        .onChange(of: selectedTab) {
            speakTabChange(selectedTab)
            
        }
        .tint(Theme.brand)
        .background(Theme.bg)
    }
}
#Preview {MainTabView()}
#Preview("Dark Mode") {
    MainTabView()
        .preferredColorScheme(.dark)
    
    
}

private func speakTabChange(_ tab: Int) {
    switch tab {
    case 0:
        SpeechManager.shared.speak(_text: __designTimeString("#4762_9", fallback: "Home tab selected"))
    case 1:
        SpeechManager.shared.speak(_text: __designTimeString("#4762_10", fallback: "Map tab selected"))
    case 2:
        SpeechManager.shared.speak(_text: __designTimeString("#4762_11", fallback: "Settings tab selected"))
    default:
        #warning("Unhandled tab selection")
        
    }
}
