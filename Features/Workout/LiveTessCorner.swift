import SwiftUI

private typealias Paint = WorkoutPaint

/// Tess in live mode (docs/design/no-buttons.md, "Tess: a soul at rest"): only the soul in the bottom-right thumb
/// corner. When she has something to say, her line slides in beside it and fades after 4 s; UNDO sits under it as a
/// label word for as long as there is something to undo. Tap the soul to type to her; double tap goes to Today.
struct LiveTessCorner: View {
    let line: String
    let mode: TessSoul.Mode
    let canUndo: Bool
    /// "Tess has eyes"; in the workout they never glance (the live page is glance-free, tess-motion.md §14).
    var eyes = false
    /// The colour she wears for his day (idea 4): her paint, so the corner wears it too.
    var wear: (Date) -> CGFloat = { _ in 0 }
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
            // Tess's slot keeps its height (two lines and the UNDO row) whether or not she speaks, so nothing on
            // the page moves when her line comes or goes (day-seams S1, one-ask.md).
            ZStack(alignment: .bottomTrailing) {
                slotTemplate
                spoken
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

    /// Her line, trailing beside the soul, with UNDO under it.
    private var spoken: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if let shownLine, !shownLine.isEmpty {
                // Beside the soul, trailing, at most 270 pt and 2 lines, UNDO under it (day-seams S1).
                Text(shownLine)
                    .font(Theme.voice)
                    .foregroundStyle(Paint.tess)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .frame(maxWidth: 270, alignment: .trailing)
                    .minimumScaleFactor(0.85)
                    // A new line cross-fades in place; only an empty corner slides a line in.
                    .contentTransition(.opacity)
                    .transition(.asymmetric(insertion: .offset(x: reduceMotion ? 0 : 12).combined(with: .opacity),
                                            removal: .opacity))
            }
            // UNDO leaves with its line, never alone (Design #297 follow-up).
            if canUndo, shownLine?.isEmpty == false {
                Button(action: onUndo) { Text("Undo").textRole(.keyWord) }
                    .buttonStyle(.labelWord(Theme.Colors.liveInk, silent: true))
                    .accessibilityLabel("Undo the last change")
                    // Clear of the soul's done splash, which spreads about 60 pt on dark looks (Design A2).
                    .padding(.trailing, 12)
                    .transition(.opacity)
            }
        }
    }

    /// Invisible: reserves two Body lines and the UNDO row at the current Dynamic Type size.
    private var slotTemplate: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(verbatim: "Tess\nTess").font(Theme.voice).lineLimit(2)
            Button {} label: { Text("Undo").textRole(.keyWord) }.buttonStyle(.labelWord(
                Theme.Colors.liveInk,
                silent: true
            ))
        }
        .hidden()
        .accessibilityHidden(true)
    }

    /// The three dabs, about 46×40 with a 64×64 hit area, breathing 1 ↔ 1.08 over 3.2 s.
    private var soul: some View {
        TessSoul(mode: mode, eyes: eyes, wear: wear)
            .scaleEffect(0.72)
            .liveBreath(on: breathe)
            .scaleEffect(swell ? 1.35 : 1)
            .frame(width: 46, height: 40)
            .frame(width: 64, height: 64)
            .contentShape(Rectangle())
            // One tap types to her, two go to Today; the swell answers either tap.
            .gesture(TapGesture(count: 2).onEnded { touched(then: onHome) }
                .exclusively(before: TapGesture().onEnded { touched(then: onOpen) }))
            // On the finish screen she only speaks: no touch, no haptic.
            .allowsHitTesting(onOpen != nil || onHome != nil)
            .tesseraFeedback(.selection, trigger: opens)
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
