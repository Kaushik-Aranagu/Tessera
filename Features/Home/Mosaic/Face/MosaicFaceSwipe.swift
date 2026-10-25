import SwiftUI
import TesseraCore

/// The mosaic's own swipe, on the slot and nowhere else (never on the Home page, where it bled into the one-thing
/// list). Through GestureKit's pieces: `SwipeTracker` locks the axis once and keeps a swipe out of the back-edge zone,
/// the face follows the finger 1:1, and `GestureTuning.stackCommits` decides at lift (past 35% of the face or a flick).
/// A vertical drag is never taken: the page scrolls.
private struct MosaicFaceSwipe: ViewModifier {
    let model: MosaicFaceModel

    @State private var tracker = SwipeTracker()
    @GestureState private var touching = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart), coordinateSpace: .global)
                    .updating($touching) { _, state, _ in state = true }
                    .onChanged { value in
                        guard let pull = tracker.update(
                            startX: Double(value.startLocation.x), dx: Double(value.translation.width),
                            dy: Double(value.translation.height), sides: .both, limit: 600
                        ) else { return }
                        model.dragged(travel: CGFloat(pull))
                    }
                    .onEnded { value in
                        let pull = tracker.pull
                        let locked = tracker.lock == .horizontal
                        tracker.reset()
                        if locked {
                            model.released(travel: CGFloat(pull), velocity: value.velocity.width)
                        }
                    }
            )
            // A touch the system took (a scroll won) never reaches `onEnded`: the faces still come home.
            .onChange(of: touching) { _, isTouching in
                guard !isTouching, tracker.lock == .horizontal else { return }
                let pull = tracker.pull
                tracker.reset()
                model.released(travel: CGFloat(pull), velocity: 0)
            }
    }
}

extension View {
    /// The face swipe: 1:1 following, commit past 35% or on a flick. Put it on the mosaic's slot only.
    func mosaicFaceSwipe(_ model: MosaicFaceModel) -> some View {
        modifier(MosaicFaceSwipe(model: model))
    }
}
