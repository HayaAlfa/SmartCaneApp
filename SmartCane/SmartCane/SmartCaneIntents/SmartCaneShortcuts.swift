import AppIntents

struct SmartCaneShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenObstacleLogIntents(),
            phrases: [
                "Open obstacle log in ${applicationName}",
                "Open obstacle logs in ${applicationName}",
                "Open obstacle logs with ${applicationName}"
            ],
            shortTitle: "Obstacle Logs",
            systemImageName: "list.bullet.rectangle"
            )
        AppShortcut(
            intent: ReadLastObstacleIntent(),
            phrases: [
                "Read last obstacle in ${applicationName}",
                "Read obstacle in ${applicationName}"
            ],
            shortTitle: "Read last obstacle",
            systemImageName: "list.bullet.rectangle"
            
        )
        AppShortcut(
            intent: OpenMyRoutesIntents(),
            phrases: [
                "Open my routes in ${applicationName}",
                "Open my route in ${applicationName}"
            ],
            shortTitle: "Open my routes",
            systemImageName: "maps.bullet.rectangle"
            
        )

        AppShortcut(
            intent: OpenSmartCaneIntent(),
            phrases: [
                "Open ${applicationName}",
                "Launch ${applicationName}"
            ],
            shortTitle: "Open App",
            systemImageName: "figure.walk"
        )
    }
}
