import AppIntents
import SwiftUI
import TesseraCore
import TesseraLegacyStore

@main
struct TesseraApp: App {
    private let container: TesseraContainer
    /// Saves finished workouts to Apple Health.
    private let health: HealthExporter
    @State private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var didWarmUp = false

    init() {
        FontRegistry.registerAll()
        Theme.configure()
        AppClock.configure()
        let container = TesseraSchema.makeContainer()
        self.container = container
        // Data from builds before GRDB (SwiftData) moves across once, then the old store goes to Backups.
        // Only into a store on disk: if opening fell back to memory, leave the old files for next launch.
        if TesseraSchema.lastOpenOutcome != .inMemoryFallback {
            try? LegacyStore.migrate(into: container.mainContext)
        }
        let model = AppModel(context: container.mainContext)
        // Fake history only when asked for (simulator, recordings): never on Kaushik's phone.
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-demo") || arguments.contains("-resetDemo") {
            DemoData.prepare(model)
        }
        _model = State(initialValue: model)
        LiveWorkout.model = model
        // App Intents (Shortcuts, Siri, the Action button) run against the same engine as the UI.
        if let runtime = model.runtime {
            AppDependencyManager.shared.add(dependency: runtime)
        }
        health = HealthExporter(engine: model.engine)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-soulGallery") {
                        SoulGallery()
                    } else if ProcessInfo.processInfo.arguments.contains("-notes") {
                        NotesView()
                    } else if ProcessInfo.processInfo.arguments.contains("-review") {
                        ReviewView()
                    } else if ProcessInfo.processInfo.arguments.contains("-groceries") {
                        GroceriesView()
                    } else {
                        RootView()
                    }
                #else
                    RootView()
                #endif
            }
            .environment(model)
            // The rest Live Activity follows the live session: each logged set, +15s, Skip and the end.
            .onChange(of: model.session?.loggedCount, initial: true) {
                RestActivityController.shared.update(for: model.session)
            }
            .onChange(of: model.session?.restEndsAt) { RestActivityController.shared.update(for: model.session) }
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active {
                    model.tidyProcesses()
                }
                if phase == .active, !didWarmUp {
                    didWarmUp = true
                    Task { await model.ledger.warmUp() }
                }
            }
            .onOpenURL { url in
                if url.host() == "workout", model.session != nil {
                    model.isWorkoutPresented = true
                }
            }
        }
    }
}
