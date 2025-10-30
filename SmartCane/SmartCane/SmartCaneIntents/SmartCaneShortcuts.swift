import Foundation
import AppIntents

@available(iOS 16.0, *)
struct SmartCaneShortCuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenSmartCaneIntent(),
            phrases: [
                "Open ${applicationName}",
                "Launch ${applicationName}"
            ]
        )
        
        AppShortcut(
            intent: OpenObstacleLogIntents(),
            phrases: [
                "Open obstacle log in ${applicationName}",
                "Show obstacle log in ${applicationName}",
                "Open my obstacle log in ${applicationName}"
            ]
        )
        
        AppShortcut(
            intent: OpenMyRoutesIntents(),
            phrases: [
                "Open my routes in ${applicationName}",
                "Show my routes in ${applicationName}",
                "View my routes in ${applicationName}"
            ]
        )
        
        AppShortcut(
            intent: ReadLastObstacleIntent(),
            phrases: [
                "Read last obstacle in ${applicationName}",
                "Tell me the last obstacle in ${applicationName}",
                "What was the last obstacle in ${applicationName}"
            ]
        )
    }
}
