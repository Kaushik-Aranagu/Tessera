import SwiftUI

/// The landing's switcher (Kaushik, 12:26 PM PDT Oct 25): one element that swipes up or down to the next or previous
/// thing, so a landing carries another dimension without a list or a tab. It slides 1:1 with the finger, the others
/// follow with a little parallax, a swipe past 40 pt (or a flick) turns on the house spring with one light tick. No
/// dots, no counter. A drag that starts here stays here until lift. Reduce Motion: it turns with a plain swap.
struct LandingOneThing<Item: Identifiable & Equatable, Content: View>: View {
    let items: [Item]
    @Binding var index: Int
    var height: CGFloat = 64
    @ViewBuilder let content: (Item) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: CGFloat = 0
    @State private var cue = HapticCue()

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.element.id) { position, item in
                let relative = CGFloat(position - index) + (drag / height)
                if abs(relative) <= 1.2 {
                    content(item)
                        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
                        .offset(y: relative * height * (reduceMotion ? 1 : (relative > 0 ? 0.9 : 0.72)))
                        .blur(radius: reduceMotion ? 0 : min(abs(relative), 1) * 1.8)
                        .scaleEffect(reduceMotion ? 1 : 1 - min(abs(relative), 1) * 0.06, anchor: .topLeading)
                        .opacity(abs(relative) < 0.01 ? 1 : (reduceMotion ? 0 : 0.5))
                        .allowsHitTesting(position == index)
                        .accessibilityHidden(position != index)
                }
            }
        }
        .frame(height: height, alignment: .top)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard abs(value.translation.height) > abs(value.translation.width) else { return }
                    drag = Self.resisted(value.translation.height, at: index, count: items.count, height: height)
                }
                .onEnded { value in
                    let flick = abs(value.predictedEndTranslation.height) > 500 * 0.3
                    var delta = 0
                    if value.translation.height < -40 || (flick && value.translation.height < -12) { delta = 1 }
                    if value.translation.height > 40 || (flick && value.translation.height > 12) { delta = -1 }
                    let next = index + delta
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                        drag = 0
                        if items.indices.contains(next), delta != 0 { index = next }
                    }
                    if delta != 0, items.indices.contains(next) { cue.play(.pageTurn) }
                }
        )
        .tesseraFeedback(cue)
        .accessibilityAdjustableAction { direction in
            let next = index + (direction == .increment ? 1 : -1)
            if items.indices.contains(next) { index = next }
        }
    }

    /// A pull past either end gives way slowly instead of stopping dead.
    static func resisted(_ pull: CGFloat, at index: Int, count: Int, height: CGFloat) -> CGFloat {
        let atStart = index == 0 && pull > 0
        let atEnd = index >= count - 1 && pull < 0
        return atStart || atEnd ? pull * 0.25 : max(-height, min(height, pull))
    }
}
