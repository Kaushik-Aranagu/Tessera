import SwiftUI

/// The masthead switcher (sheet 283): one word, Figtree 300 at 38 pt, text only, x 24-224, top 106, 76 tall. Swipe
/// across and the old letters stream out leaning with the swipe while the new ones stream in from that side; swipe up
/// or down and each letter rolls over like a drum. Past 40 pt commits; tap goes to the next across. While dragging
/// the word follows the finger, spacing opens to +.055 em and the weight rises to 600. Reduce Motion: a plain swap.
struct LandingSwitcher: View {
    let across: [String]
    var vertical: [String] = []
    @Binding var acrossIndex: Int
    @Binding var verticalIndex: Int
    /// Needs change with the word.
    var changed: () -> Void = {}

    static var size: CGSize {
        CGSize(width: 200, height: 76)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag = CGSize.zero
    @State private var direction = 1
    @State private var rolling = false
    @State private var cue = HapticCue()

    private var word: String {
        if !vertical.isEmpty, vertical.indices.contains(verticalIndex), rolling {
            return vertical[verticalIndex]
        }
        return across.indices.contains(acrossIndex) ? across[acrossIndex] : ""
    }

    var body: some View {
        let dragging = drag != .zero
        HStack(spacing: 0) {
            ForEach(Array(word.enumerated()), id: \.offset) { position, letter in
                Text(String(letter))
                    .font(.custom("Figtree", size: 38, relativeTo: .largeTitle).weight(dragging ? .semibold : .light))
                    .tracking(dragging ? 38 * 0.055 : 0)
                    .foregroundStyle(Theme.Colors.ink)
                    .transition(letterTransition(position))
            }
        }
        .id(word)
        // Sheet 297: the word under his finger fades through the frame's edge (22 pt, no lean: the drag skews it).
        .edgeFade(axis: .horizontal, shift: drag.width * 0.5, placeLength: Self.size.width, reduceMotion: reduceMotion)
        .offset(x: drag.width * 0.5, y: drag.height * 0.3)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .leading)
        .contentShape(Rectangle())
        .gesture(swipe)
        .onTapGesture { step(across: 1) }
        .tesseraFeedback(cue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(word)
        .accessibilityAdjustableAction { direction in step(across: direction == .increment ? 1 : -1) }
    }

    private func letterTransition(_ position: Int) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let delay = Double(position) * 0.022
        if rolling {
            return .asymmetric(
                insertion: .modifier(active: LetterRoll(angle: 85), identity: LetterRoll(angle: 0))
                    .animation(.easeOut(duration: 0.62).delay(Double(position) * 0.024)),
                removal: .opacity.animation(.easeIn(duration: 0.2))
            )
        }
        return .asymmetric(
            insertion: .modifier(active: LetterStream(dx: 40 * CGFloat(direction), skew: 0, heavy: true),
                                 identity: LetterStream(dx: 0, skew: 0, heavy: false))
                .animation(.spring(duration: 0.72, bounce: 0.2).delay(delay)),
            removal: .modifier(
                active: LetterStream(dx: -40 * CGFloat(direction), skew: 24 * Double(direction), heavy: false),
                identity: LetterStream(dx: 0, skew: 0, heavy: false)
            )
            .animation(.easeIn(duration: 0.3).delay(Double(position) * 0.014))
        )
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { drag = $0.translation }
            .onEnded { value in
                let across = abs(value.translation.width) >= abs(value.translation.height)
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { drag = .zero }
                if across, abs(value.translation.width) > 40 {
                    step(across: value.translation.width < 0 ? 1 : -1)
                } else if !across, abs(value.translation.height) > 40, !vertical.isEmpty {
                    stepVertical(value.translation.height < 0 ? 1 : -1)
                }
            }
    }

    private func step(across delta: Int) {
        guard across.count > 1 else { return }
        direction = delta
        rolling = false
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            acrossIndex = (acrossIndex + delta + across.count) % across.count
        }
        cue.play(.selection)
        changed()
    }

    private func stepVertical(_ delta: Int) {
        guard vertical.count > 1 else { return }
        rolling = true
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            verticalIndex = (verticalIndex + delta + vertical.count) % vertical.count
        }
        cue.play(.selection)
        changed()
    }
}

private struct LetterStream: ViewModifier {
    let dx: CGFloat
    let skew: Double
    let heavy: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: dx)
            .transformEffect(CGAffineTransform(a: 1, b: 0, c: CGFloat(tan(skew * .pi / 180)) * -1, d: 1, tx: 0, ty: 0))
            .blur(radius: abs(dx) > 0 ? 2.5 : 0)
            .opacity(abs(dx) > 0 ? 0 : 1)
            .fontWeight(heavy ? .heavy : nil)
    }
}

private struct LetterRoll: ViewModifier {
    let angle: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0))
            .opacity(angle == 0 ? 1 : 0)
    }
}
