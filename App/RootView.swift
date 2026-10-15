import SwiftUI

/// Motion grammar: deeper pages zoom out of the tapped row (drag-to-dismiss zooms back = up); jumps and
/// breadcrumbs cross-fade; workout mode is a process, so it rises from the bottom; Tess morphs out of the glass bar.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Namespace private var zoom

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.path) {
            TodayView()
                .environment(\.animateEntrance, model.consumeFirstVisit(nil))
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
            BottomChrome().environment(\.zoomNamespace, zoom)
        }
        .fullScreenCover(isPresented: $model.isWorkoutPresented) {
            WorkoutModeView()
                .environment(\.animateEntrance, true)
        }
        .background { ThemedBackground() }
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
