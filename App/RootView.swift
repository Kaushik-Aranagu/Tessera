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

    var body: some View {
        @Bindable var model = model
        GeometryReader { proxy in
            ZStack {
                NavigationStack(path: $model.path) {
                    HomeSpatialView()
                        .environment(\.animateEntrance, model.consumeFirstVisit(nil))
                        .toolbarVisibility(.hidden, for: .navigationBar)
                        .navigationDestination(for: Route.self) { route in
                            ObjectPage(route: route)
                                .environment(\.animateEntrance, model.consumeFirstVisit(route))
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
                BottomChrome(onSoulDoubleTap: goHome)
                    .environment(\.zoomNamespace, zoom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    // Full width, so the band strip spans the screen (a stroke starts beside her, not on her).
                    .soulStroke(model.soul)

                PaintFlood(isOn: flooding, origin: CGPoint(x: proxy.size.width - 46, y: proxy.size.height - 30))
                    .ignoresSafeArea()
            }
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
                WorkoutModeView()
                    .environment(\.animateEntrance, true)
                    .navigationTransition(.zoom(sourceID: WorkoutRise.sourceID, in: zoom))
            } else {
                WorkoutModeView()
                    .environment(\.animateEntrance, true)
            }
        }
        .background { ThemedBackground() }
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
