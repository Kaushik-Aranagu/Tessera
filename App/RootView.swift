import SwiftUI
import TesseraCore

/// Motion grammar: deeper pages zoom out of the tapped row (drag-to-dismiss zooms back = up); jumps and
/// breadcrumbs cross-fade; workout mode is a process, so it rises from the bottom; Tess opens out of her soul in the
/// corner (the page recedes behind her), and double-tapping her floods the screen with paint to go Home.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var zoom
    @State private var flooding = false
    /// Low Power, read through `PowerState` only; the system's change notice just says when to ask it again.
    @State private var lowPower = PowerState.isLowPower
    /// `-openCook "Paprika chicken"` (simulator only, read through LaunchFlags): starts that cook and opens its clock
    /// page, for recordings.
    @State private var demoCook: DemoCookCover?
    /// Settings, opened from the entry at the top right of any page below Home.
    @State private var settingsOpen = false
    #if DEBUG
        /// `-openLayoutMode` (simulator only, LaunchFlags) opens Layout mode at launch, for its UI tests and stills.
        @State private var layoutModeOpen = false
    #endif

    /// A full-screen cover or Tess's capture surface hides the stack: nothing under it draws live.
    private var covered: Bool {
        var covers = model.isWorkoutPresented || model.isCommandExpanded || demoCook != nil || settingsOpen
        #if DEBUG
            covers = covers || layoutModeOpen
        #endif
        return covers
    }

    var body: some View {
        @Bindable var model = model
        GeometryReader { proxy in
            ZStack {
                NavigationStack(path: $model.path) {
                    Group {
                        // Home v2 (sheet 137) while its Review switch is On; else Home as it was.
                        if HomeMosaic.isOn {
                            // Sheet 283 v5: Bridge and its rooms in the one standing shell.
                            if ShellHome.isOn {
                                RootShellHost()
                            } else {
                                HomeMosaicPage()
                            }
                        } else if HomeV2.isOn {
                            HomeV2View()
                        } else {
                            HomeSpatialView()
                        }
                    }
                    .environment(\.animateEntrance, model.consumeFirstVisit(nil))
                    // Live only when seen: Home is the visible page only with nothing pushed over it and no cover up.
                    .liveScope(model.path.isEmpty && !covered)
                    .toolbarVisibility(.hidden, for: .navigationBar)
                    .navigationDestination(for: Route.self) { route in
                        ObjectPage(route: route)
                            .environment(\.animateEntrance, model.consumeFirstVisit(route))
                            // Only the top of the stack is seen; the pages under it and any cover hide it.
                            .liveScope(model.path.last == route && !covered)
                            .modifier(ArrivalTransition(
                                id: route,
                                arrival: model.arrivals[route] ?? .crossFade,
                                namespace: zoom
                            ))
                    }
                }
                .tint(Theme.Colors.ink)
                .environment(\.zoomNamespace, zoom)
                // Room for Tess's soul (a 64 pt corner overlay), so the last row of any page can scroll clear of it.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 56).allowsHitTesting(false)
                }
                // Sheet 203: "Settings" and the knob at the top right of every page below Home (Home has its own).
                if SettingsV2.isOn, !model.path.isEmpty {
                    SettingsEntry { settingsOpen = true }
                        .padding(.trailing, Theme.Spacing.gutter - 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
                // On Home, with the mosaic's own Tess layer up, she is that layer (one Tess in the corner, not two).
                if !(model.homeTessLayerActive && model.path.isEmpty) {
                    BottomChrome(onSoulDoubleTap: goHome)
                        .environment(\.zoomNamespace, zoom)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }

                DoorwayOverlay(doorway: model.doorway)
                PaintFlood(isOn: flooding, origin: CGPoint(x: proxy.size.width - 46, y: proxy.size.height - 30))
                    .ignoresSafeArea()
            }
            // Stroke her: a pan across her band, read beside everything else on Home (never instead of it).
            .soulStroke(model.soul, isHome: model.path.isEmpty && !model.isCommandExpanded)
            .overlay(alignment: .top) {
                // A running process lights the top edge; tapping it resumes. A suspended one moves to the ledger.
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    let _ = context.date
                    if let session = model.session, !model.isWorkoutPresented,
                       model.processes.running()?.subject?.id == session.workout.id
                    {
                        RunningSeam(session: session) { model.isWorkoutPresented = true }
                            .ignoresSafeArea(edges: .top)
                            .transition(.opacity)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $model.isWorkoutPresented) {
            if model.workoutRisesFromLane {
                // START on Training: live mode rises out of the first lane (training-mode.md).
                WorkoutCover()
                    .environment(\.animateEntrance, true)
                    .navigationTransition(.zoom(sourceID: WorkoutRise.sourceID, in: zoom))
            } else {
                WorkoutCover()
                    .environment(\.animateEntrance, true)
            }
        }
        .fullScreenCover(item: $demoCook) { CookClockPage(cookID: $0.id) }
        #if DEBUG
            .fullScreenCover(isPresented: $layoutModeOpen) {
                NavigationStack { LayoutModeView() }
            }
            .task {
                guard LaunchFlags.has("-openLayoutMode") else { return }
                try? await Task.sleep(for: .milliseconds(1200))
                layoutModeOpen = true
            }
        #endif
            .fullScreenCover(isPresented: $settingsOpen) {
                NavigationStack { SettingsPage(cameFrom: "Back") }
                    .environment(\.animateEntrance, true)
            }
            .task {
                guard let title = LaunchFlags.value(after: "-openCook"),
                      let recipe = model.objects(of: .recipe).first(where: { $0.title == title }),
                      let cook = try? model.engine.perform(StartCooking(recipe: recipe.id), by: .user).output
                else { return }
                try? await Task.sleep(for: .milliseconds(600))
                demoCook = DemoCookCover(id: cook.id)
            }
            .task {
                // Simulator only (LaunchFlags): opens the first routine's workout, for the large-text swipe test.
                guard LaunchFlags.has("-openWorkout"),
                      let routine = model.objects(of: .routine).first(where: { !$0.isDeleted }) else { return }
                try? await Task.sleep(for: .milliseconds(800))
                model.startRoutine(routine)
            }
            .task {
                // Simulator only (LaunchFlags): `-openExercise "Bench Press"` opens that exercise's page, for stills.
                // `-massUnit lb` shows weights in pounds, the way the Measure choice will.
                if LaunchFlags.value(after: "-massUnit") == "lb" {
                    Format.unit = .pounds
                }
                guard let name = LaunchFlags.value(after: "-openExercise"), let root = model.classDef(.exercise),
                      let target = ClassResolver.descendants(of: root).first(where: { $0.name == name }) else { return }
                try? await Task.sleep(for: .milliseconds(1500))
                model.open(.classDef(target.id))
            }
            .background { ThemedBackground() }
            .modifier(RestReceipt())
            .environment(\.lowPowerMotion, lowPower)
            .onReceive(PowerState.changes) { _ in
                lowPower = PowerState.isLowPower
            }
    }

    /// Paint floods out of Tess (~0.5 s); Home is swapped in underneath, then the paint fades. Tapping her again on
    /// Home takes you back to where you were.
    private func goHome() {
        model.isCommandExpanded = false
        model.soul.handle(.goHome(reduceMotion: reduceMotion))
        flooding = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 480))
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                if model.path.isEmpty, let back = model.homeReturnPath {
                    model.path = back
                    model.homeReturnPath = nil
                } else if !model.path.isEmpty {
                    model.homeReturnPath = model.path
                    model.path.removeAll()
                }
            }
            try? await Task.sleep(for: .milliseconds(60))
            flooding = false
        }
    }
}

#Preview {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model = AppModel(context: container.mainContext)
    DemoData.prepare(model)
    return RootView()
        .environment(model)
}

private struct DemoCookCover: Identifiable {
    let id: UUID
}
