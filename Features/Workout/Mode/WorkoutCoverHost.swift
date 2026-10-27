import SwiftUI

#if DEBUG
    /// The simulator's `-trainingLanding` root has no workout cover of its own (RootView hosts it in the app); this
    /// gives
    /// it the same one, so a hold on Start can be driven there.
    private struct WorkoutCoverHost: ViewModifier {
        @Environment(AppModel.self) private var model

        func body(content: Content) -> some View {
            @Bindable var model = model
            content.fullScreenCover(isPresented: $model.isWorkoutPresented) { WorkoutCover() }
        }
    }

    extension View {
        func hostsWorkoutCover() -> some View {
            modifier(WorkoutCoverHost())
        }
    }
#endif
