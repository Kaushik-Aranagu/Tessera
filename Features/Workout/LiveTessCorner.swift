import SwiftUI

private typealias Paint = WorkoutPaint

/// Tess in live mode (docs/design/no-buttons.md, "Tess: a soul at rest"): only the soul in the bottom-right thumb
/// corner. When she has something to say, her line slides in beside it and fades after 4 s; UNDO sits under it as a
/// label word for as long as there is something to undo. Tap the soul to type to her; double tap goes to Today.
struct LiveTessCorner: View {
    let line: String
    let mode: TessSoul.Mode
    let canUndo: Bool
    /// An instruction ("Last one. Hold to finish.") stays until it is done; everything else fades after 4 s.
    var holdsLine = false
    var onUndo: () -> Void
    var onOpen: (() -> Void)?
    var onHome: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownLine: String?
    @State private var breathe = false
    @State private var swell = false
    @State private var opens = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .trailing, spacing: 6) {
                if let shownLine, !shownLine.isEmpty {
                    Text(shownLine)
                        .font(Theme.voice)
                        .foregroundStyle(Paint.tess)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        // A new line cross-fades in place; only an empty corner slides a line in.
                        .contentTransition(.opacity)
                        .transition(.asymmetric(insertion: .offset(x: reduceMotion ? 0 : 12).combined(with: .opacity),
                                                removal: .opacity))
                }
                if canUndo {
                    Button("Undo", action: onUndo)
                        .buttonStyle(.labelWord(Theme.Colors.liveInk))
                        .accessibilityLabel("Undo the last change")
                        // Clear of the soul's done splash, which spreads about 60 pt on dark looks (Design A2).
                        .padding(.trailing, 12)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            soul
        }
        .tesseraAnimation(Theme.Motion.house, value: shownLine)
        .tesseraAnimation(value: canUndo)
        .task(id: "\(line)|\(holdsLine)") {
            shownLine = line
            guard !holdsLine else { return }
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled {
                shownLine = nil
            }
        }
        .onAppear { breathe = true }
    }

    /// The three dabs, about 46×40 with a 64×64 hit area, breathing 1 ↔ 1.08 over 3.2 s.
    private var soul: some View {
        TessSoul(mode: mode)
            .scaleEffect(0.72)
            .scaleEffect(breathe ? 1.08 : 1)
            .tesseraAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: breathe)
            .scaleEffect(swell ? 1.35 : 1)
            .frame(width: 46, height: 40)
            .frame(width: 64, height: 64)
            .contentShape(Rectangle())
            // One tap types to her, two go to Today; the swell answers either tap.
            .gesture(TapGesture(count: 2).onEnded { touched(then: onHome) }
                .exclusively(before: TapGesture().onEnded { touched(then: onOpen) }))
            // On the finish screen she only speaks: no touch, no haptic.
            .allowsHitTesting(onOpen != nil || onHome != nil)
            .sensoryFeedback(.selection, trigger: opens)
            .accessibilityElement()
            .accessibilityLabel("Tess")
            .accessibilityValue(shownLine ?? "")
            .accessibilityHint(onOpen == nil ? "" : "Type to Tess.")
            .accessibilityAddTraits(onOpen == nil ? [] : .isButton)
            .accessibilityAction { onOpen?() }
            .accessibilityActions {
                if let onHome {
                    Button("Go to Today", action: onHome)
                }
            }
    }

    private func touched(then action: (() -> Void)?) {
        opens += 1
        withTesseraAnimation(.easeOut(duration: 0.13), reduceMotion: reduceMotion) { swell = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(130))
            withTesseraAnimation(.easeInOut(duration: 0.13), reduceMotion: reduceMotion) { swell = false }
        }
        action?()
    }
}
