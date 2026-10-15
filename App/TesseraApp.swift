import SwiftUI
import TesseraCore
import TesseraLegacyStore

@main
struct TesseraApp: App {
    private let container: TesseraContainer
    @State private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FontRegistry.registerAll()
        Theme.configure()
        AppClock.configure()
        let container = TesseraSchema.makeContainer()
        self.container = container
        // Data from builds before GRDB (SwiftData) moves across once, then the old store goes to Backups.
        try? LegacyStore.migrate(into: container.mainContext)
        let model = AppModel(context: container.mainContext)
        DemoData.prepare(model)
        _model = State(initialValue: model)
        LiveWorkout.model = model
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-soulGallery") {
                        SoulGallery()
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
            }
            .onOpenURL { url in
                if url.host() == "workout", model.session != nil {
                    model.isWorkoutPresented = true
                }
            }
        }
    }
}
