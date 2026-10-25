import SwiftUI

/// Deck's keystone (sheet 258 v2, locked direction): a blackboard set into the page. The slate is a precomputed
/// texture (three octaves of noise, fine grain, a soft light from the top-left, faint ghosts of wiped chalk) whose
/// edge is a 44 pt feather of chalk dust built from noise, never a gradient, frame or shadow. Everything on it is
/// chalk, drawn in two passes (a soft wide stroke under a crisp one, with a hair of jitter) and grain knocked out.
///
/// Touch: tap the top line to open today's workout; tap a best's number to open that lift; drag writes in chalk
/// (kept on screen only); a fast swipe left is the towel and wipes the writing. Reduce Motion: one still board,
/// no drifting dust; taps still work.
struct TrainingBlackboard: View {
    let board: TrainingBoard
    var openToday: () -> Void
    var openLift: (UUID) -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var strokes: [[CGPoint]] = []
    @State private var current: [CGPoint] = []
    @State private var wiping = false
    @State private var travelled: CGFloat = 0
    @State private var cue = HapticCue()

    static let feather: CGFloat = 44
    static let featherY: CGFloat = 24
    /// The chalk's own inset from the slot edge: the writing sits on the solid slate, inside the dust.
    static let margin: CGFloat = 26

    private var dark: Bool {
        scheme == .dark
    }

    private var chalk: Color {
        Color(hex: 0xF1EEE6)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                BlackboardSlate(dark: dark)
                    // Softens the noise cells into dust, so the edge never reads as pixels or tiles.
                    .blur(radius: 1.6)
                    .drawingGroup()
                if !reduceMotion, !ProcessInfo.processInfo.isLowPowerModeEnabled {
                    BlackboardDust(chalk: chalk)
                        .allowsHitTesting(false)
                }
                Canvas { context, canvasSize in
                    drawWriting(in: &context, size: canvasSize)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                Canvas { context, _ in
                    drawStrokes(in: &context)
                }
                .opacity(wiping ? 0 : 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                targets(size: size)
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .gesture(writing)
            .tesseraFeedback(cue)
        }
    }

    // MARK: Layout (design points inside the 354 x 182 slot)

    private var headlineOrigin: CGPoint {
        CGPoint(x: Self.margin, y: 18)
    }

    private var detailOrigin: CGPoint {
        CGPoint(x: Self.margin, y: 62)
    }

    private var weekOrigin: CGPoint {
        CGPoint(x: Self.margin, y: 90)
    }

    private var bestsY: CGFloat {
        122
    }

    private func bestFrames(width: CGFloat) -> [CGRect] {
        let count = max(board.bests.count, 1)
        let column = (width - Self.margin * 2) / CGFloat(count)
        return board.bests.indices.map { index in
            CGRect(x: Self.margin + CGFloat(index) * column, y: bestsY, width: column, height: 36)
        }
    }

    // MARK: Chalk writing

    private func drawWriting(in context: inout GraphicsContext, size: CGSize) {
        var rng = ChalkRandom(seed: 258)
        context.drawLayer { layer in
            chalkText(board.headline, size: 30, weight: .semibold, at: headlineOrigin, in: &layer, rng: &rng)
            chalkText(board.detail, size: 15, weight: .regular, at: detailOrigin, in: &layer, rng: &rng, alpha: 0.78)
            drawWeek(in: &layer, rng: &rng)
            for (best, frame) in zip(board.bests, bestFrames(width: size.width)) {
                chalkText(best.lift, size: 13, weight: .regular, at: CGPoint(x: frame.minX, y: frame.minY),
                          in: &layer, rng: &rng, alpha: 0.7)
                // The lift's name small, its best under it in larger chalk: one column each, never overlapping.
                chalkText(best.number, size: 17, weight: .semibold,
                          at: CGPoint(x: frame.minX, y: frame.minY + 15),
                          in: &layer, rng: &rng)
            }
            // Grain knocked out of the chalk, so it sits in the slate rather than on it.
            layer.blendMode = .destinationOut
            var grain = ChalkRandom(seed: 7)
            for _ in 0 ..< 900 {
                let point = CGPoint(x: grain.next() * size.width, y: grain.next() * size.height)
                let side = 0.6 + grain.next() * 0.9
                layer.fill(Path(CGRect(origin: point, size: CGSize(width: side, height: side))),
                           with: .color(.black.opacity(0.35 + grain.next() * 0.4)))
            }
        }
    }

    private func drawWeek(in context: inout GraphicsContext, rng: inout ChalkRandom) {
        let step: CGFloat = 40
        for day in board.week {
            let x = weekOrigin.x + CGFloat(day.id) * step
            chalkText(day.letter, size: 15, weight: day.isToday ? .bold : .regular,
                      at: CGPoint(x: x, y: weekOrigin.y), in: &context, rng: &rng, alpha: day.isToday ? 0.95 : 0.7)
            if day.done {
                // A tick beside the letter, drawn as two chalk strokes.
                var tick = Path()
                tick.move(to: CGPoint(x: x + 17, y: weekOrigin.y + 9))
                tick.addLine(to: CGPoint(x: x + 21, y: weekOrigin.y + 15))
                tick.addLine(to: CGPoint(x: x + 30, y: weekOrigin.y + 1))
                chalkStroke(tick, width: 2.2, in: &context, rng: &rng)
            }
            if day.isToday {
                var line = Path()
                line.move(to: CGPoint(x: x - 2, y: weekOrigin.y + 22))
                line.addLine(to: CGPoint(x: x + 14, y: weekOrigin.y + 21))
                chalkStroke(line, width: 1.8, in: &context, rng: &rng)
            }
        }
    }

    private func chalkFont(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .custom("Figtree", fixedSize: size).weight(weight)
    }

    /// Two passes: a soft, wide, faint stroke (four offset copies) under one crisp copy, each with a hair of jitter.
    private func chalkText(_ text: String, size: CGFloat, weight: Font.Weight, at origin: CGPoint,
                           in context: inout GraphicsContext, rng: inout ChalkRandom, alpha: Double = 0.92)
    {
        let resolved = context.resolve(Text(text).font(chalkFont(size, weight)).foregroundStyle(chalk))
        let spread = max(0.8, size * 0.035)
        for offset in [CGSize(width: -spread, height: 0), CGSize(width: spread, height: 0),
                       CGSize(width: 0, height: -spread), CGSize(width: 0, height: spread)]
        {
            var copy = context
            copy.opacity = alpha * 0.18
            copy.draw(resolved, at: CGPoint(x: origin.x + offset.width, y: origin.y + offset.height),
                      anchor: .topLeading)
        }
        var crisp = context
        crisp.opacity = alpha
        crisp.draw(
            resolved,
            at: CGPoint(x: origin.x + (rng.next() - 0.5) * 0.8, y: origin.y + (rng.next() - 0.5) * 0.8),
            anchor: .topLeading
        )
    }

    private func chalkStroke(_ path: Path, width: CGFloat, in context: inout GraphicsContext,
                             rng: inout ChalkRandom, alpha: Double = 0.9)
    {
        var soft = context
        soft.opacity = alpha * 0.25
        soft.stroke(path, with: .color(chalk), style: StrokeStyle(lineWidth: width * 2.4, lineCap: .round))
        var crisp = context
        crisp.opacity = alpha
        crisp.translateBy(x: (rng.next() - 0.5) * 0.6, y: (rng.next() - 0.5) * 0.6)
        crisp.stroke(path, with: .color(chalk), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func drawStrokes(in context: inout GraphicsContext) {
        var rng = ChalkRandom(seed: 31)
        for points in strokes + [current] where points.count > 1 {
            var path = Path()
            path.addLines(points)
            chalkStroke(path, width: 2.4, in: &context, rng: &rng, alpha: 0.85)
        }
    }

    // MARK: Taps

    @ViewBuilder
    private func targets(size: CGSize) -> some View {
        Button(action: openToday) {
            Color.clear.frame(width: size.width - Self.margin * 2, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: headlineOrigin.x, y: headlineOrigin.y - 4)
        .accessibilityLabel(board.headline)
        .accessibilityHint("Opens today's workout")
        ForEach(Array(zip(board.bests, bestFrames(width: size.width))), id: \.0.id) { best, frame in
            Button { openLift(best.id) } label: {
                Color.clear.frame(width: frame.width, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: frame.minX, y: frame.minY - 4)
            .accessibilityLabel("\(best.lift) best \(best.number)")
            .accessibilityHint("Opens the lift")
        }
        // The week reads as one line to VoiceOver.
        Color.clear
            .frame(width: 7 * 40, height: 26)
            .offset(x: weekOrigin.x, y: weekOrigin.y)
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(weekSpoken)
    }

    private var weekSpoken: String {
        let done = board.week.filter(\.done).count
        return done == 0 ? "This week, nothing trained yet" : "This week, \(done) \(done == 1 ? "day" : "days") trained"
    }

    // MARK: Writing and the towel

    private var writing: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if wiping {
                    wiping = false
                }
                if let last = current.last {
                    travelled += hypot(value.location.x - last.x, value.location.y - last.y)
                    if travelled > 24 {
                        travelled = 0
                        cue.play(.selection)
                    }
                }
                current.append(value.location)
            }
            .onEnded { value in
                let fastLeft = value.translation.width < -80
                    && abs(value.translation.height) < 40
                    && value.predictedEndTranslation.width < value.translation.width - 120
                if fastLeft {
                    current = []
                    towel()
                } else {
                    if current.count > 1 {
                        strokes.append(current)
                    }
                    current = []
                    if strokes.count > 24 {
                        strokes.removeFirst(strokes.count - 24)
                    }
                }
            }
    }

    /// The towel: the writing goes with one soft sweep.
    private func towel() {
        guard !strokes.isEmpty else { return }
        cue.play(.notNow)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { wiping = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            strokes = []
            wiping = false
        }
    }
}

// MARK: - The slate

/// The precomputed slate: uneven darkness from three octaves of value noise, fine grain, a soft light from the
/// top-left, seven faint ghosts of wiped chalk, and an edge that dissolves into the page as chalk dust.
private struct BlackboardSlate: View {
    let dark: Bool

    var body: some View {
        Canvas { context, size in
            let base = dark ? (r: 0.17, g: 0.19, b: 0.19) : (r: 0.17, g: 0.21, b: 0.20)
            let cell: CGFloat = 2
            let columns = Int(ceil(size.width / cell))
            let rows = Int(ceil(size.height / cell))
            let feather = TrainingBlackboard.feather
            for row in 0 ..< rows {
                for column in 0 ..< columns {
                    let x = CGFloat(column) * cell
                    let y = CGFloat(row) * cell
                    let shade = BoardNoise.fractal(x / 60, y / 60, seed: 3)
                    // The dust edge: distance to the nearest edge, roughened by its own noise, eased over the feather.
                    // The sides dissolve over the full 44 pt; top and bottom over 24 pt, so the writing keeps solid
                    // slate.
                    let edge = min(
                        min(x, size.width - x),
                        min(y, size.height - y) * feather / TrainingBlackboard.featherY
                    )
                    let ragged = edge + (BoardNoise.fractal(x / 14, y / 14, seed: 11) - 0.5) * feather * 0.9
                    let reach = max(0, min(1, ragged / feather))
                    let alpha = reach * reach * (3 - 2 * reach)
                    guard alpha > 0.01 else { continue }
                    let light = 0.05 * (1 - (x / size.width + y / size.height) / 2)
                    let tone = (shade - 0.5) * 0.06 + light
                    let color = Color(red: base.r + tone, green: base.g + tone, blue: base.b + tone)
                    context.fill(Path(CGRect(x: x, y: y, width: cell + 0.5, height: cell + 0.5)),
                                 with: .color(color.opacity(alpha)))
                }
            }
            // Ghosts of wiped chalk: wide soft smears.
            var rng = ChalkRandom(seed: 91)
            for _ in 0 ..< 7 {
                let width = 70 + rng.next() * 120
                let height = 14 + rng.next() * 26
                let rect = CGRect(x: rng.next() * (size.width - width), y: 30 + rng.next() * (size.height - 60),
                                  width: width, height: height)
                let shading = GraphicsContext.Shading.radialGradient(
                    Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0)]),
                    center: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0, endRadius: width / 2
                )
                context.fill(Path(ellipseIn: rect), with: shading)
            }
            // Loose dust grains along the edge, some settled on the page.
            for _ in 0 ..< 160 {
                let alongTop = rng.next() < 0.5
                let x = rng.next() * size.width
                let depth = rng.next() * feather * 0.8
                let y = alongTop ? depth : size.height - depth
                let side = 0.6 + rng.next() * 1.1
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: side, height: side)),
                             with: .color(Color(hex: 0xF1EEE6).opacity(0.12 + rng.next() * 0.2)))
            }
            // Fine grain over the solid slate.
            for _ in 0 ..< 700 {
                let point = CGPoint(x: rng.next() * size.width, y: feather * 0.5 + rng.next() * (size.height - feather))
                context.fill(Path(CGRect(origin: point, size: CGSize(width: 0.8, height: 0.8))),
                             with: .color(Color.white.opacity(0.04)))
            }
        }
        .accessibilityHidden(true)
    }
}

/// A few grains of dust drifting slowly down the board's lower edge (off under Reduce Motion and Low Power).
private struct BlackboardDust: View {
    let chalk: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                var rng = ChalkRandom(seed: 5)
                for _ in 0 ..< 18 {
                    let x = rng.next() * size.width
                    let speed = 2 + rng.next() * 4
                    let phase = rng.next() * 40
                    let fall = (time * speed + phase).truncatingRemainder(dividingBy: 40)
                    let y = size.height - TrainingBlackboard.feather + fall
                    let sway = sin(time * 0.6 + phase) * 3
                    context.fill(Path(ellipseIn: CGRect(x: x + sway, y: y, width: 1.2, height: 1.2)),
                                 with: .color(chalk.opacity(0.25 * (1 - fall / 40))))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Noise

/// A small deterministic random source, so the board looks the same on every draw.
struct ChalkRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 0x9E37_79B9_7F4A_7C15 | 1
    }

    mutating func next() -> CGFloat {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return CGFloat(state % 10000) / 10000
    }
}

/// Value noise, summed over three octaves (0 to 1).
enum BoardNoise {
    static func fractal(_ x: CGFloat, _ y: CGFloat, seed: Int) -> CGFloat {
        var total: CGFloat = 0
        var amplitude: CGFloat = 0.5
        var frequency: CGFloat = 1
        for octave in 0 ..< 3 {
            total += value(x * frequency, y * frequency, seed: seed + octave * 17) * amplitude
            amplitude *= 0.5
            frequency *= 2
        }
        return total / 0.875
    }

    private static func value(_ x: CGFloat, _ y: CGFloat, seed: Int) -> CGFloat {
        let cellX = Int(floor(x))
        let cellY = Int(floor(y))
        let fracX = x - CGFloat(cellX)
        let fracY = y - CGFloat(cellY)
        let easeX = fracX * fracX * (3 - 2 * fracX)
        let easeY = fracY * fracY * (3 - 2 * fracY)
        let topLeft = hash(cellX, cellY, seed)
        let topRight = hash(cellX + 1, cellY, seed)
        let bottomLeft = hash(cellX, cellY + 1, seed)
        let bottomRight = hash(cellX + 1, cellY + 1, seed)
        return topLeft + (topRight - topLeft) * easeX + (bottomLeft - topLeft) * easeY
            + (topLeft - topRight - bottomLeft + bottomRight) * easeX * easeY
    }

    private static func hash(_ x: Int, _ y: Int, _ seed: Int) -> CGFloat {
        var mixed = UInt64(bitPattern: Int64(x &* 374_761_393 &+ y &* 668_265_263 &+ seed &* 2_147_483_647))
        mixed = (mixed ^ (mixed >> 13)) &* 1_274_126_177
        mixed ^= mixed >> 16
        return CGFloat(mixed % 1000) / 1000
    }
}
