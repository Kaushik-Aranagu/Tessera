import SwiftUI

// Tess on her own layer (Design 209, and Kaushik's 11:46 AM change): one clear overlay above all of Home, hit-testing
// off
// everywhere except on her. She sits quietly in the bottom-right corner, reacting, with no standing line: her line
// shows
// only when he taps or holds her, or when she has something to say.
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
    /// How far from the trailing edge her canvas sits, and how long a line stays up before it goes back in.
    static let trailing: CGFloat = 14
    static let bottom: CGFloat = 14
    static let lineSeconds: TimeInterval = 6
    /// Her pool takes 1.8 s.
    static let poolSeconds: TimeInterval = 1.8

    /// Where her canvas's top-left sits: 14 pt from the right and bottom edges of the screen.
    static func origin(screenWidth: CGFloat, screenHeight: CGFloat) -> CGPoint {
        CGPoint(x: screenWidth - trailing - canvas, y: screenHeight - bottom - canvas)
    }

    /// On the phone she is about 30% smaller than on the design board (Kaushik, 1:25 PM): the sheet's numbers times
    /// this.
    static let phoneScale: CGFloat = 0.7

    /// Her layer open (sheet 215 rev 4): 1.35x, down from 1.7x, and 1.2x during a hold.
    static let openScale: CGFloat = 1.35
    static let holdScale: CGFloat = 1.2
    /// Where she goes: the bottom middle, 112 pt up (centre), from her corner's centre (14 pt in, half her canvas).
    static let openRise: CGFloat = 112

    /// The offset from her corner to the bottom middle, in points.
    static func openOffset(width: CGFloat) -> CGSize {
        let cornerX = width - trailing - canvas / 2
        let cornerFromBottom = bottom + canvas / 2
        return CGSize(width: width / 2 - cornerX, height: -(openRise - cornerFromBottom))
    }

    /// The thought after `index`, wrapping.
    static func next(after index: Int, count: Int) -> Int {
        count > 0 ? (index + 1) % count : 0
    }
}

struct TessLayer: View {
    /// What she is thinking, in order. None shows at rest; a tap or a hold brings up the next.
    var thoughts: [String]
    /// Something she has to say (a suggestion, an answer): it comes up by itself and goes back in after a while.
    var message: String?
    /// A tap: the host plays the Tess moment in the mosaic.
    var onTap: () -> Void = {}
    /// Her resting mode.
    var rest: TessSoul.Mode = .idle
    var eyes = true
    /// Her own layer is open (sheet 215): she moves to the bottom middle, 112 pt up, at 1.35x (1.2x while he holds).
    var open = false
    var holding = false
    /// While he holds to talk: his voice's level, when the last word was heard, and a finger near her.
    var voice: Double = 0
    var heardAt: Date?
    var attention: CGPoint?
    /// Her mouth, when she has one (never while she speaks or listens).
    var mouth: (kind: SoulMouth, start: Date)?
    /// Her reaction to touch, a line or a deed.
    var reaction: (kind: SoulLife.Reaction, start: Date)?

    @State private var index = -1
    @State private var pooling = false
    @State private var shown: String?
    @State private var reveal: CGFloat = 0
    @State private var lineTask: Task<Void, Never>?
    @State private var gaze: SoulGaze = .ahead
    @State private var feel = HapticCue()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    private var line: String {
        shown ?? ""
    }

    var body: some View {
        GeometryReader { geometry in
            // Everything on this layer lets touches through except Tess herself (and her line, while it is up).
            HStack(alignment: .center, spacing: Theme.Spacing.s) {
                Text(line)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 220, alignment: .trailing)
                    .mask(alignment: .trailing) {
                        // A line comes in from the right by a clip, never a fade.
                        Rectangle().frame(maxWidth: .infinity).scaleEffect(x: reveal, anchor: .trailing)
                    }
                    .accessibilityHidden(shown == nil)
                    .accessibilityLabel(line)
                TessSoul(mode: pooling ? .done : rest, eyes: eyes, gaze: gaze, attention: attention, reaction: reaction,
                         voice: voice, heardAt: heardAt, mouth: mouth)
                    .frame(width: TessLayerShape.canvas, height: TessLayerShape.canvas)
                    .scaleEffect(TessLayerShape
                        .phoneScale * (open ? (holding ? TessLayerShape.holdScale : TessLayerShape.openScale) : 1))
                    .offset(open ? TessLayerShape.openOffset(width: geometry.size.width) : .zero)
                    .tesseraAnimation(Theme.Motion.house, value: open)
                    .tesseraAnimation(Theme.Motion.house, value: holding)
                    .contentShape(Circle().inset(by: 16))
                    .onTapGesture { tap() }
                    .accessibilityElement()
                    .accessibilityLabel("Tess")
                    .accessibilityHint("Plays her next thought")
                    .accessibilityAddTraits(.isButton)
            }
            .fixedSize()
            .padding(.trailing, TessLayerShape.trailing)
            .padding(.bottom, TessLayerShape.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .ignoresSafeArea()
        .tesseraFeedback(feel)
        .task {
            // Her eyes wander slowly; under Reduce Motion they stay ahead.
            while !Task.isCancelled, !reduceMotion {
                try? await Task.sleep(for: .seconds(7))
                gaze = gaze == .ahead ? .atLine : .ahead
            }
        }
        .onChange(of: message) { _, text in
            if let text, !text.isEmpty {
                say(text)
            }
        }
    }

    private func nextThought() -> String {
        index = TessLayerShape.next(after: index, count: thoughts.count)
        return thoughts.indices.contains(index) ? thoughts[index] : ""
    }

    /// Brings a line up (a clip from the right) and takes it back in after a while.
    private func say(_ text: String) {
        guard !text.isEmpty else { return }
        lineTask?.cancel()
        shown = text
        if reduceMotion {
            reveal = 1
        } else {
            reveal = 0.001
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { reveal = 1 }
        }
        lineTask = Task {
            try? await Task.sleep(for: .seconds(TessLayerShape.lineSeconds))
            guard !Task.isCancelled else { return }
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { reveal = 0 }
            try? await Task.sleep(for: .milliseconds(450))
            if !Task.isCancelled {
                shown = nil
            }
        }
    }

    private func tap() {
        guard !pooling else { return }
        feel.play(.soulStroke)
        onTap()
        pooling = true
        say(nextThought())
        Task {
            try? await Task.sleep(for: .seconds(TessLayerShape.poolSeconds))
            pooling = false
        }
    }
}
