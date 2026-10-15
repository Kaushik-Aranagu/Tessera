import SwiftUI

private typealias Paint = WorkoutPaint

/// Tess in live mode (docs/design/no-buttons.md, "Tess: a soul at rest"): only the soul in the bottom-right thumb
/// corner. When she has something to say, her line slides in beside it and fades after 4 s; UNDO sits under it as a
/// label word for as long as there is something to undo. Tap the soul to type to her; double tap goes to Today.
struct LiveTessCorner: View {
    let line: String
    let mode: TessSoul.Mode
    let canUndo: Bool
    var onUndo: () -> Void
    var onOpen: (() -> Void)?
    var onHome: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownLine: String?
    @State private var breathe = false
    @State private var swell = false
    @State private var pressed = false
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
                        .transition(.asymmetric(insertion: .offset(x: reduceMotion ? 0 : 12).combined(with: .opacity),
                                                removal: .opacity))
                        .id(shownLine)
                }
                if canUndo {
                    Button("Undo", action: onUndo)
                        .buttonStyle(.labelWord(Paint.live))
                        .accessibilityLabel("Undo the last change")
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            soul
        }
        .tesseraAnimation(Theme.Motion.house, value: shownLine)
        .tesseraAnimation(value: canUndo)
        .task(id: line) {
            shownLine = line
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
            // The swell answers the touch at once, so the double-tap wait never reads as lag.
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    pressed = true
                    opens += 1
                    withTesseraAnimation(.easeOut(duration: 0.13), reduceMotion: reduceMotion) { swell = true }
                }
                .onEnded { _ in
                    pressed = false
                    withTesseraAnimation(.easeInOut(duration: 0.13), reduceMotion: reduceMotion) { swell = false }
                })
            .onTapGesture(count: 2) { onHome?() }
            .onTapGesture { onOpen?() }
            .sensoryFeedback(.selection, trigger: opens)
            .accessibilityElement()
            .accessibilityLabel("Tess")
            .accessibilityValue(shownLine ?? "")
            .accessibilityHint("Type to Tess.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Go to Today") { onHome?() }
    }
}
