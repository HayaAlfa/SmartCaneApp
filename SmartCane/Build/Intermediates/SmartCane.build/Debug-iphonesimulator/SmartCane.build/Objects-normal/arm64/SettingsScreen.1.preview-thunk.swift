import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/hayaalfakieh/Downloads/SmartCaneApp/SmartCane/SmartCane/SettingsScreen.swift", line: 1)
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
                Toggle(__designTimeString("#1041_0", fallback: "Enable Voice Feedback"), isOn: $voiceFeedbackEnabled)
                    .accessibilityLabel(__designTimeString("#1041_1", fallback: "Voice Feedback Toggle"))
                    .accessibilityHint(__designTimeString("#1041_2", fallback: "Turns speech feedback on or off"))
                
            }
           
                .navigationTitle(__designTimeString("#1041_3", fallback: "Settings"))
            
//            Button("Speak") {
//                SpeechManager.shared.speak(_text: "Settings Screen")
//            }
        }
    }
}
#Preview {
    SettingsScreen()
}
