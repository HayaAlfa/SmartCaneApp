//
//  SettingsScreen.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 8/30/25.
//

import SwiftUI

struct SettingsScreen: View {
    @AppStorage(AppKeys.voiceEnabled) private var voiceFeedbackEnabled: Bool = true
    var body: some View {
        NavigationView {
            Form {
                Toggle("Enable Voice Feedback", isOn: $voiceFeedbackEnabled)
                    .accessibilityLabel("Voice Feedback Toggle")
                    .accessibilityHint("Turns speech feedback on or off")
                
            }
           
                .navigationTitle("Settings")
            
//            Button("Speak") {
//                SpeechManager.shared.speak(_text: "Settings Screen")
//            }
        }
    }
}
#Preview {
    SettingsScreen()
}
