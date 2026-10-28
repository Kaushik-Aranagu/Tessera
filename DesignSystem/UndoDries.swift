import SwiftUI

/// Sheet 290, "the Undo word dries": it holds full ink for 6 s, then fades to 45% by the end of its 10 s, so the time
/// left is felt without a timer. Starts again when `id` changes (a new line with its own Undo). It plays once, never
/// loops, has no haptic, and Reduce Motion drops it (the word stays full ink).
private struct UndoDries: ViewModifier {
    let id: AnyHashable
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dried = false

    static let holds: Duration = .seconds(6)
    static let fades: Double = 4
    static let floor: Double = 0.45

    func body(content: Content) -> some View {
        content
            .opacity(dried && !reduceMotion ? Self.floor : 1)
            .task(id: id) {
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) { dried = false }
                guard !reduceMotion else { return }
                try? await Task.sleep(for: Self.holds)
                guard !Task.isCancelled else { return }
                withTesseraAnimation(.linear(duration: Self.fades), reduceMotion: reduceMotion) { dried = true }
            }
    }
}

extension View {
    /// The Undo word fades to 45% over its last 4 s of 10 (sheet 290). `id` names the line it belongs to.
    func undoDries(id: some Hashable) -> some View {
        modifier(UndoDries(id: AnyHashable(id)))
    }
}
