import Observation
import SwiftUI
import UIKit

/// Sheet 299, "ink goes last" (and sheet 290's paper-to-black delight): when the look changes the old page stays on top
/// with its old colours pinned (a snapshot of the screen taken just before the change). Its ground fades away first,
/// over
/// 200 ms, showing the new ground under it; 60 ms in the old ink fades out over 220 ms, so the new ink (already there
/// under it) takes over, and the swap is over by 320 ms. The old page takes no touches while it leaves. Nothing arrives
/// again: the snapshot is only a picture, the live page never re-runs. Reduce Motion: an instant swap.
@MainActor @Observable
final class LookInk {
    static let shared = LookInk()

    struct Pass: Identifiable {
        let id = UUID()
        let image: UIImage
        /// Whether the old page was a dark look: its ink is light, so the ink layer screens (else it multiplies).
        let wasDark: Bool
        let start: Date
    }

    /// The pass in flight (nil at rest).
    private(set) var pass: Pass?

    // MARK: Timing (sheet 299)

    nonisolated static let groundFade = 0.2
    nonisolated static let inkDelay = 0.06
    nonisolated static let inkFade = 0.22
    nonisolated static let whole = 0.32

    /// How much of the old ground is left `time` seconds into the pass.
    nonisolated static func groundAlpha(at time: Double) -> Double {
        1 - min(max(time / groundFade, 0), 1)
    }

    /// How much of the old ink is left `time` seconds into the pass.
    nonisolated static func inkAlpha(at time: Double) -> Double {
        1 - min(max((time - inkDelay) / inkFade, 0), 1)
    }

    /// Joins `ThemeStore`: the snapshot is taken as the look is about to change.
    static func install() {
        ThemeStore.willChangeLook = { old in
            guard Thread.isMainThread else { return }
            MainActor.assumeIsolated { LookInk.shared.begin(replacing: old) }
        }
    }

    func begin(replacing old: Look) {
        guard !UIAccessibility.isReduceMotionEnabled, let image = Self.snapshot() else { return }
        let started = Pass(image: image, wasDark: old.isDark, start: .now)
        pass = started
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Self.whole + 0.04))
            if self?.pass?.id == started.id {
                self?.pass = nil
            }
        }
    }

    /// What is on the key window right now (the frame before the change is drawn).
    private static func snapshot() -> UIImage? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let window = scenes.first(where: { $0.activationState == .foregroundActive })?.windows
            .first(where: \.isKeyWindow)
        else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
    }
}

/// The old page leaving: on top of everything, no touches, hidden from VoiceOver. Two copies of the old page: one in
/// plain colour that fades first (its ground goes, over 200 ms), and one that adds only its ink, by multiplying (dark
/// ink
/// on a light ground) or screening (light ink on a dark ground), which holds on 60 ms longer and then fades. A ground
/// that
/// is light multiplies to nothing and a dark one screens to nothing, so the second copy is only the type, as it was.
struct LookInkOverlay: View {
    var body: some View {
        if let pass = LookInk.shared.pass {
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSince(pass.start)
                ZStack {
                    Image(uiImage: pass.image)
                        .resizable()
                        .opacity(LookInk.groundAlpha(at: time))
                    Image(uiImage: pass.image)
                        .resizable()
                        .opacity(LookInk.inkAlpha(at: time))
                        .blendMode(pass.wasDark ? .screen : .multiply)
                }
            }
            .id(pass.id)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
