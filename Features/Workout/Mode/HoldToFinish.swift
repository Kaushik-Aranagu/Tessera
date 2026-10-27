import SwiftUI

/// Holding "hold to finish" (sheet 340): the words are rewritten from left to right in accent chalk across the 600 ms
/// hold, as a widening clip. No bar, no ring. Released early or moved more than 10 pt, it clears. This is the pure
/// part.
enum HoldToFinish {
    static let duration = 0.6
    /// A finger that drifts further than this (points) cancels the hold.
    static let slop: CGFloat = 10

    /// How much of the accent words shows after `elapsed` seconds of holding (0 to 1, linear).
    static func fraction(elapsed: TimeInterval) -> Double {
        min(max(elapsed / duration, 0), 1)
    }

    /// The hold is complete once the whole duration has passed.
    static func isComplete(elapsed: TimeInterval) -> Bool {
        elapsed >= duration
    }

    /// The hold cancels when the finger has moved more than 10 pt from where it went down.
    static func shouldCancel(moved distance: CGFloat) -> Bool {
        distance > slop
    }
}

/// The words, with the accent version written over them while the hold runs. The hold works with Reduce Motion on (it
/// still finishes after 600 ms); only the overwrite is not drawn.
struct HoldToFinishWords: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fraction = 0.0
    @State private var isDown = false
    @State private var isCancelled = false
    @State private var timer: Task<Void, Never>?

    private let words = "hold to finish"

    var body: some View {
        ZStack(alignment: .leading) {
            Text(words).foregroundStyle(Chalk.faint)
            Text(words).foregroundStyle(Chalk.blue)
                .mask(alignment: .leading) {
                    GeometryReader { proxy in
                        Rectangle().frame(width: proxy.size.width * fraction)
                    }
                }
        }
        .font(Chalk.font(16))
        .lineLimit(1)
        .fixedSize()
        .frame(minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDown {
                        begin()
                    } else if !isCancelled, HoldToFinish.shouldCancel(moved: hypot(value.translation.width,
                                                                                   value.translation.height))
                    {
                        cancel()
                    }
                }
                .onEnded { _ in
                    if !isCancelled {
                        cancel()
                    }
                    isDown = false
                    isCancelled = false
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hold to finish")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onFinish() }
    }

    private func begin() {
        isDown = true
        isCancelled = false
        if !reduceMotion {
            withAnimation(.linear(duration: HoldToFinish.duration)) { fraction = 1 }
        }
        timer = Task {
            try? await Task.sleep(for: .seconds(HoldToFinish.duration))
            guard !Task.isCancelled, isDown, !isCancelled else { return }
            isCancelled = true
            fraction = 0
            onFinish()
        }
    }

    /// Released early or moved too far: the words clear at once.
    private func cancel() {
        isCancelled = true
        timer?.cancel()
        withAnimation(.easeOut(duration: 0.12)) { fraction = 0 }
    }
}
