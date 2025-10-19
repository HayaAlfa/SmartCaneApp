import AppIntents

@available(iOS 16.0, *)
struct OpenObstacleLogIntents: AppIntent {
    static var title: LocalizedStringResource = "Open obstacle log in SmartCane"
    static var description = IntentDescription("Open the obstacle log screen in SmartCane using Siri.")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppGroup.userDefaults.set(true, forKey: "OpenObstacleLogFromSiri")
        return .result(dialog: "Opening obstacle log.")
    }
}
