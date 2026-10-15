import AppIntents
import TesseraIntents

/// Pulls Core's intents and Shortcuts into the app's App Intents metadata.
struct TesseraAppIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [TesseraIntentsPackage.self]
    }
}

/// Shortcuts have to be declared in the app target: a Swift package's `AppShortcutsProvider` isn't extracted into
/// the app's metadata. Mirrors Core's `TesseraShortcuts` (which can be removed from the package).
struct TesseraAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: TellTessIntent(), phrases: ["Tell \(.applicationName)", "Log in \(.applicationName)"],
                    shortTitle: "Tell Tess", systemImageName: "text.bubble")
        AppShortcut(intent: LogSetIntent(), phrases: ["Log a set in \(.applicationName)"],
                    shortTitle: "Log a Set", systemImageName: "dumbbell")
        AppShortcut(intent: UndoLastSetIntent(), phrases: ["Undo last set in \(.applicationName)"],
                    shortTitle: "Undo Last Set", systemImageName: "arrow.uturn.backward")
        AppShortcut(intent: StartRoutineIntent(), phrases: ["Start \(\.$routine) in \(.applicationName)"],
                    shortTitle: "Start Workout", systemImageName: "figure.strengthtraining.traditional")
        AppShortcut(intent: FinishWorkoutIntent(), phrases: ["Finish my workout in \(.applicationName)"],
                    shortTitle: "Finish Workout", systemImageName: "flag.checkered")
        AppShortcut(intent: CreateTaskIntent(), phrases: ["Add a task in \(.applicationName)"],
                    shortTitle: "Add Task", systemImageName: "checkmark.circle")
    }
}
