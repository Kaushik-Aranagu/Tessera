import SwiftUI

// Tess on her own layer (Design 209): one clear overlay above all of Home, hit-testing off everywhere except on her.
// She is TessSoul exactly as built (six dabs, a radial wash, blur, multiply on light and screen on dark, a 9 s lift, a
// 6.4 s
// breath, eyes with a 160 ms blink) in a 96 pt canvas whose body is about 64 pt wide, with one plain ink line beside
// her.
// Tapping her: she pools together over 1.8 s, the line moves to her next thought, the mosaic plays the Tess moment and
// one soft haptic plays. She never fades. Reduce Motion: still dabs and a plain swap of the line.

enum TessLayerShape {
    /// The canvas and the room B leaves for her at the bottom of Home.
    static let canvas: CGFloat = 96
    static let roomHeight: CGFloat = 80
    static let leading: CGFloat = 22
    /// Her pool takes 1.8 s.
    static let poolSeconds: TimeInterval = 1.8

    /// Where her canvas's top-left sits: the top of the room, 22 pt from the leading edge.
    static func origin(screenHeight: CGFloat, bottomInset: CGFloat) -> CGPoint {
        CGPoint(x: leading, y: screenHeight - bottomInset - roomHeight)
    }

    /// The thought after `index`, wrapping.
    static func next(after index: Int, count: Int) -> Int {
        count > 0 ? (index + 1) % count : 0
    }
}

struct TessLayer: View {
    /// What she is thinking, in order. The first shows at rest; each tap moves to the next.
    var thoughts: [String]
    /// A tap: the host plays the Tess moment in the mosaic.
    var onTap: () -> Void = {}
    /// Her resting mode.
    var rest: TessSoul.Mode = .idle
    var eyes = true

    @State private var index = 0
    @State private var pooling = false
    @State private var shownIndex = 0
    @State private var reveal: CGFloat = 1
    @State private var feel = HapticCue()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    private var line: String {
        thoughts.indices.contains(shownIndex) ? thoughts[shownIndex] : ""
    }

    var body: some View {
        GeometryReader { proxy in
            let origin = TessLayerShape.origin(screenHeight: proxy.size.height + proxy.safeAreaInsets.top
                + proxy.safeAreaInsets.bottom, bottomInset: proxy.safeAreaInsets.bottom)
            // Everything on this layer lets touches through except Tess and her line.
            HStack(alignment: .center, spacing: Theme.Spacing.s) {
                TessSoul(mode: pooling ? .done : rest, eyes: eyes)
                    .frame(width: TessLayerShape.canvas, height: TessLayerShape.canvas)
                    .contentShape(Circle().inset(by: 16))
                    .onTapGesture { tap() }
                    .accessibilityElement()
                    .accessibilityLabel("Tess")
                    .accessibilityHint("Plays her next thought")
                    .accessibilityAddTraits(.isButton)
                Text(line)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 220, alignment: .leading)
                    .mask(alignment: .leading) {
                        // A new line comes in from the left by a clip, never a fade.
                        Rectangle().frame(maxWidth: .infinity).scaleEffect(x: reveal, anchor: .leading)
                    }
                    .accessibilityLabel(line)
            }
            .offset(x: origin.x, y: origin.y - proxy.safeAreaInsets.top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .tesseraFeedback(feel)
    }

    private func tap() {
        guard !pooling else { return }
        feel.play(.soulStroke)
        onTap()
        pooling = true
        index = TessLayerShape.next(after: index, count: thoughts.count)
        if reduceMotion {
            shownIndex = index
        } else {
            reveal = 0.001
            shownIndex = index
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { reveal = 1 }
        }
        Task {
            try? await Task.sleep(for: .seconds(TessLayerShape.poolSeconds))
            pooling = false
        }
    }
}
