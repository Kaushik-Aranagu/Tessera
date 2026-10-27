import SwiftUI

/// How a live mode opens (sheet 330): the room's keystone grows from its slot (354 x 182) to the whole screen in 560 ms
/// on a soft spring, and Back runs it the other way. With Reduce Motion it is a plain cut.
///
/// A `.fullScreenCover` is a separate hierarchy, so `matchedGeometryEffect` cannot join the keystone to the cover's
/// background directly. The same continuity is made by measuring the keystone's global frame and having the cover's
/// background start masked to that frame and open to the full screen. Shared by workout, cook and shop modes:
///
///     .modeKeystoneFrame($frame)                      // on the keystone slot
///     .fullScreenCover(isPresented: $open) { Mode().modeGrow(from: frame) }
enum ModeOpen {
    /// 560 ms on a soft spring (a touch of bounce so it settles, not snaps).
    static let growth = Animation.spring(Spring(duration: 0.56, bounce: 0.08))
    static let duration: TimeInterval = 0.56
}

extension View {
    /// Records this view's frame in global space (the keystone's slot) for `modeGrow(from:)`.
    func modeKeystoneFrame(_ frame: Binding<CGRect>) -> some View {
        onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame.wrappedValue = $0 }
    }

    /// Opens this content from `frame` to the whole screen. Put it on the cover's content.
    func modeGrow(from frame: CGRect) -> some View {
        modifier(ModeGrowModifier(source: frame))
    }
}

private struct ModeGrowModifier: ViewModifier {
    let source: CGRect
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grown = false

    func body(content: Content) -> some View {
        // The content keeps the safe area (the mode's slots sit inside it); only the clip reaches the screen's edges.
        content
            .mask {
                GeometryReader { proxy in
                    let full = proxy.frame(in: .global)
                    let rect = grown || reduceMotion || source.isEmpty ? full : source
                    // The keystone's slot and then the screen: a hard clip, no blur or material at its edge.
                    Rectangle()
                        .frame(width: rect.width, height: rect.height)
                        .offset(x: rect.minX - full.minX, y: rect.minY - full.minY)
                        .frame(width: full.width, height: full.height, alignment: .topLeading)
                }
                .ignoresSafeArea()
            }
            .onAppear {
                guard !reduceMotion else { grown = true; return }
                withTesseraAnimation(ModeOpen.growth, reduceMotion: reduceMotion) { grown = true }
            }
            .transaction {
                if reduceMotion {
                    $0.animation = nil
                }
            }
    }
}

/// The keystone slot's latest global frame, kept where a cover presented from the app root can reach it (the room is
/// a different part of the hierarchy from the cover). Written by the shell's scene keystone, read by `WorkoutCover`.
@MainActor
enum ModeOpenFrames {
    static var keystone: CGRect = .zero
}

extension View {
    /// Records this view as the keystone slot for any live mode that opens from it.
    func recordsModeKeystoneFrame() -> some View {
        onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { ModeOpenFrames.keystone = $0 }
    }
}
