import AppIntents
import SwiftUI
import TesseraCore
import TesseraIntents
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
        let model = AppModel(context: container.mainContext, seedsStarterLists: true)
        // Fake history only when asked for (simulator, recordings): never on Kaushik's phone.
        // -resetDemo starts the first-launch rest day over too (QA low on #641); LaunchFlags is simulator-only.
        if LaunchFlags.has("-resetDemo") {
            UserDefaults.standard.removeObject(forKey: SettingsStore.firstLaunchKey)
        }
        if LaunchFlags.has("-demo") || LaunchFlags.has("-resetDemo") {
            DemoData.prepare(model)
        }
        _model = State(initialValue: model)
        LiveWorkout.model = model
        HomeV2.resetOnce()
        // Approved features ship On (Kaushik, Oct 23); he asks for one to be turned off.
        if FeatureFlagStore.isRealLaunch {
            FeatureFlagStore.migrateOnce()
            if let surfaces = ReviewChoices.all.first(where: { $0.id == SurfacesV2.choiceID }) {
                SurfacesV2.mirrorFlag(SurfacesV2.isOn(value: ReviewChoices.shared.value(of: surfaces)))
            }
        }
        WatchBridge.shared.start(model: model)
        // App Intents (Shortcuts, Siri, the Action button) run against the same engine as the UI.
        if let runtime = model.runtime {
            AppDependencyManager.shared.add(dependency: runtime)
        }
        health = HealthExporter(engine: model.engine)
    }

    var body: some Scene {
        WindowGroup {
            // The Sample data flip crossfades the two trees, 150 ms (Design on #1199), never a jump.
            ZStack {
                Group {
                    #if DEBUG
                        if LaunchFlags.has("-soulGallery") {
                            SoulGallery()
                        } else if LaunchFlags.has("-measureGallery") {
                            MeasureGallery().environment(model)
                        } else if LaunchFlags.has("-notes") {
                            NotesView()
                        } else if LaunchFlags.has("-trainingLanding") {
                            TrainingRoomView()
                        } else if LaunchFlags.has("-routinesLanding") {
                            NavigationStack { RoutinesWoodlandLandingPage() }
                        } else if LaunchFlags.has("-settingsLanding") {
                            NavigationStack { SettingsLandingPage() }
                        } else if LaunchFlags.has("-weatherLanding") {
                            WeatherLandingView()
                        } else if LaunchFlags.has("-money") {
                            NavigationStack { MoneyLandingView() }
                        } else if LaunchFlags.has("-kitchen") {
                            KitchenLandingHost()
                        } else if LaunchFlags.has("-review") {
                            ReviewView()
                        } else if LaunchFlags.has("-groceries") {
                            GroceriesView()
                        } else if LaunchFlags.has("-looks") {
                            LookSentence()
                                .padding(Theme.Spacing.gutter)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background { ThemedBackground() }
                        } else if LaunchFlags.has("-backup") {
                            BackupView()
                        } else if LaunchFlags.has("-recipe") {
                            RecipeView(recipeID: nil)
                        } else if LaunchFlags.has("-pasteRecipe") {
                            PasteRecipeView()
                        } else {
                            RootView()
                        }
                    #else
                        RootView()
                    #endif
                }
                // Sample data swaps every screen onto its own in-memory store; his model keeps running underneath
                // (backups, Health, the Watch, Siri and the Live Activity stay on his data).
                .environment(SampleData.shared.model(over: model))
                .environment(\.realModel, model)
                .id(SampleData.isOn)
                .transition(.opacity)
            }
            .animation(MotionPolicy.reducedMotionFade, value: SampleData.isOn)
            .onChange(of: SampleData.isOn) { _, on in
                if !on {
                    SampleData.shared.release()
                }
            }
            // A pinned look holds the appearance too ("Obsidian always" on a light phone gets a light status bar
            // on black otherwise).
            .preferredColorScheme(ThemeStore.shared.pin.map { $0.isDark ? .dark : .light })
            // The rest Live Activity follows the live session: each logged set, +15s, Skip and the end.
            .onChange(of: model.session?.loggedCount, initial: true) {
                RestActivityController.shared.update(for: model.session)
                WatchBridge.shared.update(for: model.session)
            }
            .onChange(of: model.session?.restEndsAt) {
                RestActivityController.shared.update(for: model.session)
                WatchBridge.shared.update(for: model.session)
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                // Once a day, on the way out: a backup copy (docs/research/free-signing-survival.md).
                if phase == .background {
                    BackupKeeper.runDaily(model.context)
                }
                if phase == .background {
                    model.soul.handle(.backgrounded)
                }
                // Surfaces v2: the widgets' day sentence follows the app in and out (a no-op clear while Off).
                if phase == .active || phase == .background {
                    SurfacesWriter.refresh(model: model)
                }
                if phase == .active {
                    model.soul.handle(.foregrounded(underLive: model.isWorkoutPresented))
                    model.tidyProcesses()
                    Task { await model.drainWaitingPhrases() }
                    // Siri or the Lock Screen may have taken a set back while we were away.
                    model.session?.refreshAfterExternalWrite()
                }
                if phase == .active, !didWarmUp {
                    didWarmUp = true
                    Task { await model.ledger.warmUp() }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .tesseraSetTakenBack)) { _ in
                model.session?.refreshAfterExternalWrite()
                model.touch()
            }
            .onOpenURL { url in
                if url.host() == "workout", model.session != nil {
                    model.isWorkoutPresented = true
                }
            }
        }
    }
}
