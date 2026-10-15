import SwiftUI
import TesseraCore

/// Motion grammar: deeper pages zoom out of the tapped row (drag-to-dismiss zooms back = up); jumps and
/// breadcrumbs cross-fade; workout mode is a process, so it rises from the bottom; Tess morphs out of the glass bar,
/// and tapping her floods the screen with paint to go Home.
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
                    Group {
                        if model.isHomeShown {
                            HomeView()
                                .environment(\.animateEntrance, true)
                                .transition(.opacity)
                        } else {
                            TodayView()
                                .environment(\.animateEntrance, model.consumeFirstVisit(nil))
                                .transition(.opacity)
                        }
                    }
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
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    BottomChrome(onSoulTap: goHome).environment(\.zoomNamespace, zoom)
                }

                PaintFlood(isOn: flooding, origin: CGPoint(x: 44, y: proxy.size.height - 30))
                    .ignoresSafeArea()
            }
            .overlay(alignment: .top) {
                if let session = model.session, !model.isWorkoutPresented {
                    RunningSeam(session: session) { model.isWorkoutPresented = true }
                        .ignoresSafeArea(edges: .top)
                        .transition(.opacity)
                }
            }
        }
        .fullScreenCover(isPresented: $model.isWorkoutPresented) {
            WorkoutModeView()
                .environment(\.animateEntrance, true)
        }
        .background { ThemedBackground() }
    }

    /// Paint floods out of Tess (~0.5 s); the other surface is swapped in underneath, then the paint fades.
    private func goHome() {
        model.isCommandExpanded = false
        model.tessMode = .done
        flooding = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 480))
            model.path.removeAll()
            model.isHomeShown.toggle()
            try? await Task.sleep(for: .milliseconds(60))
            flooding = false
            try? await Task.sleep(for: .milliseconds(900))
            model.tessMode = .idle
        }
    }
}

#Preview {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model = AppModel(context: container.mainContext)
    DemoData.prepare(model)
    return RootView()
        .environment(model)
        .modelContainer(container)
}
