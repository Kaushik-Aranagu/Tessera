import SwiftUI

private typealias Paint = WorkoutPaint

/// Rest in the plates' place (docs/design/set-block.md): a 3 pt horizon in the rest colour, draining right to left,
/// the same line as the Live Activity. Drag right for +15 (the line grows under the finger); fling left to go.
struct RestHorizon: View {
    /// 1 → 0 while resting.
    let fraction: Double
    var showsHint = false
    var onExtend: () -> Void
    var onSkip: () -> Void

    @Environment(\.motionReduced) private var reduceMotion
    @State private var pull: CGFloat = 0
    @State private var drawn = false
    @State private var extends = 0
    @State private var skips = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let filled = min(max(width * fraction + max(pull, 0), 0), width)
                ZStack(alignment: .leading) {
                    Brushstroke(progress: 1)
                        .stroke(Paint.cream.opacity(0.14), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .frame(height: 10)
                    Brushstroke(progress: drawn ? 1 : 0)
                        .stroke(Paint.now, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: filled, height: 10)
                        .tesseraAnimation(.linear(duration: 1), value: fraction)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 8, coordinateSpace: .global)
                        .onChanged { value in
                            // Starts within 20 pt of the screen's left edge belong to the back swipe.
                            guard value.startLocation.x > 20 else { return }
                            pull = value.translation.width
                        }
                        .onEnded { value in
                            guard value.startLocation.x > 20 else { return }
                            let fling = value.predictedEndTranslation.width
                            if fling < -120 {
                                skips += 1
                                onSkip()
                            } else if value.translation.width > 24 {
                                extends += 1
                                onExtend()
                            }
                            withTesseraAnimation(.spring(response: 0.3, dampingFraction: 0.8),
                                                 reduceMotion: reduceMotion) { pull = 0 }
                        }
                )
            }
            .frame(height: 44)
            if showsHint {
                Text("Drag right +15 · Fling left to go")
                    .textRole(.label)
                    .foregroundStyle(Paint.secondary)
            }
        }
        .onAppear {
            withTesseraAnimation(.easeOut(duration: 0.5), reduceMotion: reduceMotion) { drawn = true }
        }
        .tesseraFeedback(.selection, trigger: extends)
        .tesseraFeedback(.selection, trigger: skips)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rest")
        .accessibilityActions {
            Button("Add 15 seconds", action: onExtend)
            Button("Skip rest", action: onSkip)
        }
    }
}
