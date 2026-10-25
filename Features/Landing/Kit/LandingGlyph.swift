import SwiftUI

/// The widget glyph library (sheet 283 v3): 20 small line drawings plus the cover (the item's own words), 80 x 80, in
/// the item's color, picked by rules on the item's header, big and middle lines (first match wins; Tess picks later).
enum GlyphKind: String, CaseIterable {
    /// Log
    case spark, bulb, book, checklist
    /// Lookout
    case rain, moon, sun
    /// Deck
    case steps, ticks, barbell
    /// Galley
    case plates, bowl, ticket, basket
    /// Watch
    case wateringCan, grove, birdAndFlower
    /// Purse
    case calendar, coins, indexLine

    /// The first rule that matches the item's words, or nil (the cover: the item's own words).
    static func pick(header: String, big: String, middle: String) -> GlyphKind? {
        let words = [header, big, middle].joined(separator: " ").lowercased()
        func has(_ needles: String...) -> Bool {
            needles.contains { words.contains($0) }
        }
        let rules: [(GlyphKind, Bool)] = [
            (.bulb, has("repair", "fix", "lamp")),
            (.book, has("club", "book", "read")),
            (.checklist, has("packing", "list", "plan")),
            (.spark, has("tess")),
            (.rain, has("rain", "storm", "shower")),
            (.moon, has("low", "night", "tonight")),
            (.sun, has("driest", "clear", "sunny")),
            (.steps, has("walk", "run", "steps")),
            (.ticks, has("this week", "of 6", "week")),
            (.barbell, has("push", "pull", "legs", "lift")),
            (.plates, has("dishes", "wash")),
            (.bowl, has("rice", "leftover", "soup")),
            (.ticket, has("tacos", "cook", "dinner", "tonight")),
            (.basket, has("things", "get", "on the way")),
            (.wateringCan, has("journal", "thirsty", "water")),
            (.grove, has("tended", "of 7", "grove")),
            (.birdAndFlower, has("next", "stretch", "bird")),
            (.calendar, has("drop", "rent", "due")),
            (.coins, has("today", "spent", "spend")),
            (.indexLine, has("still yours", "pace", "month")),
        ]
        return rules.first { $0.1 }?.0
    }
}

/// One drawing, in an 80 x 80 box, strokes 2.2 pt round, `t` is seconds for its one small move.
struct GlyphDrawing: View {
    let kind: GlyphKind
    let color: Color
    var t: Double = 0

    var body: some View {
        Canvas { context, _ in
            let stroke = StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
            func line(_ points: [CGPoint]) {
                var path = Path()
                path.addLines(points)
                context.stroke(path, with: .color(color), style: stroke)
            }
            func oval(_ rect: CGRect) {
                context.stroke(Path(ellipseIn: rect), with: .color(color), style: stroke)
            }
            func rect(_ rect: CGRect, _ radius: CGFloat = 4) {
                context.stroke(Path(roundedRect: rect, cornerRadius: radius), with: .color(color), style: stroke)
            }
            let wave = CGFloat(sin(t * 2 * .pi))
            switch kind {
            case .spark:
                for index in 0 ..< 8 {
                    let angle = Double(index) * .pi / 4 + t * 0.6
                    let inner: CGFloat = index % 2 == 0 ? 10 : 14
                    line([CGPoint(x: 40 + inner * cos(angle), y: 40 + inner * sin(angle)),
                          CGPoint(x: 40 + 28 * cos(angle), y: 40 + 28 * sin(angle))])
                }
            case .bulb:
                oval(CGRect(x: 22, y: 8, width: 36, height: 36))
                line([CGPoint(x: 31, y: 56), CGPoint(x: 49, y: 56)])
                line([CGPoint(x: 33, y: 64), CGPoint(x: 47, y: 64)])
                line([CGPoint(x: 32, y: 44), CGPoint(x: 34, y: 56)])
                line([CGPoint(x: 48, y: 44), CGPoint(x: 46, y: 56)])
            case .book:
                line([CGPoint(x: 40, y: 18), CGPoint(x: 40, y: 64)])
                line([CGPoint(x: 40, y: 18), CGPoint(x: 14, y: 22), CGPoint(x: 14, y: 66), CGPoint(x: 40, y: 64)])
                line([CGPoint(x: 40, y: 18), CGPoint(x: 66, y: 22), CGPoint(x: 66, y: 66), CGPoint(x: 40, y: 64)])
            case .checklist:
                for row in 0 ..< 3 {
                    let y = CGFloat(18 + row * 20)
                    rect(CGRect(x: 10, y: y - 6, width: 12, height: 12), 3)
                    line([CGPoint(x: 30, y: y), CGPoint(x: 68, y: y)])
                }
                line([CGPoint(x: 12, y: 18), CGPoint(x: 16, y: 22), CGPoint(x: 22, y: 12)])
            case .rain:
                var cloud = Path()
                cloud.addEllipse(in: CGRect(x: 14 + wave * 3, y: 18, width: 30, height: 22))
                cloud.addEllipse(in: CGRect(x: 30 + wave * 3, y: 10, width: 34, height: 28))
                context.stroke(cloud, with: .color(color), style: stroke)
                for index in 0 ..< 4 {
                    let x = CGFloat(22 + index * 12)
                    let drop = CGFloat((t * 1.4 + Double(index) * 0.25).truncatingRemainder(dividingBy: 1)) * 8
                    line([CGPoint(x: x, y: 50 + drop), CGPoint(x: x - 3, y: 58 + drop)])
                }
            case .moon:
                var moon = Path()
                moon.addArc(
                    center: CGPoint(x: 40, y: 40),
                    radius: 24,
                    startAngle: .degrees(60),
                    endAngle: .degrees(300),
                    clockwise: false
                )
                moon.addArc(
                    center: CGPoint(x: 50, y: 34),
                    radius: 20,
                    startAngle: .degrees(300),
                    endAngle: .degrees(60),
                    clockwise: true
                )
                context.stroke(moon, with: .color(color), style: stroke)
            case .sun:
                oval(CGRect(x: 26, y: 26, width: 28, height: 28))
                for index in 0 ..< 8 {
                    let angle = Double(index) * .pi / 4 + t * 0.4
                    line([CGPoint(x: 40 + 20 * cos(angle), y: 40 + 20 * sin(angle)),
                          CGPoint(x: 40 + 30 * cos(angle), y: 40 + 30 * sin(angle))])
                }
            case .steps:
                for (index, point) in [(18.0, 56.0), (34.0, 40.0), (50.0, 56.0), (64.0, 28.0)].enumerated() {
                    let lift = index == Int(t * 2) % 4 ? CGFloat(-3) : 0
                    oval(CGRect(x: point.0 - 7, y: point.1 - 5 + lift, width: 14, height: 10))
                }
            case .ticks:
                for index in 0 ..< 6 {
                    let x = CGFloat(10 + (index % 3) * 22)
                    let y = CGFloat(index < 3 ? 22 : 52)
                    let done = index < 3
                    if done {
                        line([CGPoint(x: x, y: y), CGPoint(x: x + 6, y: y + 8), CGPoint(x: x + 16, y: y - 8)])
                    } else {
                        line([CGPoint(x: x, y: y + 4), CGPoint(x: x + 14, y: y + 4)])
                    }
                }
            case .barbell:
                line([CGPoint(x: 6, y: 40), CGPoint(x: 74, y: 40)])
                for x in [14.0, 22.0, 58.0, 66.0] {
                    line([CGPoint(x: x, y: 28 + wave * 0.5), CGPoint(x: x, y: 52 - wave * 0.5)])
                }
            case .plates:
                for index in 0 ..< 3 {
                    oval(CGRect(x: 14, y: 12 + CGFloat(index) * 16, width: 52, height: 22))
                }
            case .bowl:
                var bowl = Path()
                bowl.addArc(
                    center: CGPoint(x: 40, y: 38),
                    radius: 26,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180),
                    clockwise: false
                )
                bowl.closeSubpath()
                context.stroke(bowl, with: .color(color), style: stroke)
                for index in 0 ..< 3 {
                    let x = CGFloat(28 + index * 12)
                    line([
                        CGPoint(x: x, y: 28 - CGFloat(index % 2) * 4),
                        CGPoint(x: x + 3 * wave, y: 14 - CGFloat(index % 2) * 4),
                    ])
                }
            case .ticket:
                line([
                    CGPoint(x: 18, y: 10),
                    CGPoint(x: 62, y: 10),
                    CGPoint(x: 62, y: 62),
                    CGPoint(x: 55, y: 68),
                    CGPoint(x: 48, y: 62),
                    CGPoint(x: 41, y: 68),
                    CGPoint(x: 34, y: 62),
                    CGPoint(x: 27, y: 68),
                    CGPoint(x: 18, y: 62),
                    CGPoint(x: 18, y: 10),
                ])
                line([CGPoint(x: 26, y: 24), CGPoint(x: 54, y: 24)])
                line([CGPoint(x: 26, y: 36), CGPoint(x: 50, y: 36)])
            case .basket:
                var basket = Path()
                basket.move(to: CGPoint(x: 12, y: 34)); basket.addLine(to: CGPoint(x: 68, y: 34))
                basket.addLine(to: CGPoint(x: 60, y: 66)); basket.addLine(to: CGPoint(x: 20, y: 66)); basket
                    .closeSubpath()
                context.stroke(basket, with: .color(color), style: stroke)
                var handle = Path()
                handle.addArc(
                    center: CGPoint(x: 40, y: 34),
                    radius: 20,
                    startAngle: .degrees(180),
                    endAngle: .degrees(360),
                    clockwise: false
                )
                context.stroke(handle, with: .color(color), style: stroke)
            case .wateringCan:
                rect(CGRect(x: 16, y: 30, width: 34, height: 30), 6)
                line([CGPoint(x: 50, y: 42), CGPoint(x: 70, y: 28)])
                line([CGPoint(x: 16, y: 38), CGPoint(x: 6, y: 30), CGPoint(x: 6, y: 20)])
                for index in 0 ..< 3 {
                    line([
                        CGPoint(x: 70 + CGFloat(index) * 3, y: 34 + CGFloat(index) * 8),
                        CGPoint(x: 72 + CGFloat(index) * 3, y: 40 + CGFloat(index) * 8),
                    ])
                }
            case .grove:
                for (x, h) in [(18.0, 34.0), (40.0, 48.0), (62.0, 30.0)] {
                    line([CGPoint(x: x, y: 68), CGPoint(x: x, y: 68 - h * 0.5)])
                    oval(CGRect(x: x - 11, y: 68 - h * 0.5 - h * 0.7, width: 22, height: h * 0.8))
                }
            case .birdAndFlower:
                line([CGPoint(x: 8, y: 30), CGPoint(x: 72, y: 24)])
                var bird = Path()
                bird.addArc(
                    center: CGPoint(x: 38, y: 20 + wave),
                    radius: 8,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false
                )
                context.stroke(bird, with: .color(color), style: stroke)
                line([CGPoint(x: 52, y: 70), CGPoint(x: 52, y: 52)])
                for index in 0 ..< 5 {
                    let angle = Double(index) * 2 * .pi / 5
                    oval(CGRect(x: 52 + 6 * cos(angle) - 4, y: 46 + 6 * sin(angle) - 4, width: 8, height: 8))
                }
            case .calendar:
                rect(CGRect(x: 12, y: 16, width: 56, height: 52), 6)
                line([CGPoint(x: 12, y: 30), CGPoint(x: 68, y: 30)])
                line([CGPoint(x: 28, y: 10), CGPoint(x: 28, y: 22)])
                line([CGPoint(x: 52, y: 10), CGPoint(x: 52, y: 22)])
                oval(CGRect(x: 34, y: 44, width: 12, height: 12))
            case .coins:
                for index in 0 ..< 3 {
                    oval(CGRect(x: 18, y: 14 + CGFloat(index) * 14, width: 44, height: 16))
                }
            case .indexLine:
                var path = Path()
                path.move(to: CGPoint(x: 6, y: 56))
                for (x, y) in [(20.0, 48.0), (32.0, 52.0), (46.0, 34.0), (60.0, 26.0)] {
                    path.addLine(to: CGPoint(
                        x: x,
                        y: y
                    ))
                }
                context.stroke(path, with: .color(color), style: stroke)
                context.fill(Path(ellipseIn: CGRect(x: 56, y: 22, width: 8, height: 8)), with: .color(color))
            }
        }
        .frame(width: 80, height: 80)
    }
}

/// The item's own words when no drawing fits (up to three, Figtree 900 caps, set like the wall).
struct GlyphCover: View {
    let words: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(words.prefix(3).enumerated()), id: \.offset) { _, word in
                Text(word.uppercased())
                    .font(.custom("Figtree", fixedSize: 18).weight(.black))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(width: 80, alignment: .leading)
            }
        }
        .frame(width: 80, height: 80, alignment: .leading)
    }
}

/// The widget's glyph: picked by the library rules, drawn in the item's color. It never cuts: on a change the old
/// drawing collapses into a point (260 ms, rotating 70 degrees), a 6 pt dot pulses, and the new one forms from it
/// (440 ms from 330 ms, overshoot 1.08). Each drawing moves once on arrival and every 7 s. Reduce Motion: no motion.
struct LandingGlyph: View {
    let item: WidgetItem
    let color: Color
    /// When the drawing forms after it collapses (330 ms in the widget; the shell starts it sooner after a split).
    var formDelay = 0.33

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var formed = false
    @State private var shownID = ""
    @State private var moveStart = Date.now

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion)) { timeline in
            let seconds = timeline.date.timeIntervalSince(moveStart)
            // One move on arrival, then one every 7 s: a 2 s move inside each 7 s cycle.
            let cycle = reduceMotion ? 0 : seconds.truncatingRemainder(dividingBy: 7)
            let t = cycle < 2 ? cycle / 2 : 0
            ZStack {
                if let kind = GlyphKind.pick(header: item.header, big: item.big, middle: item.middle) {
                    GlyphDrawing(kind: kind, color: color, t: t)
                } else {
                    GlyphCover(words: [item.big, item.middle, item.header].filter { !$0.isEmpty }, color: color)
                }
                Circle().fill(color).frame(width: 6, height: 6).scaleEffect(formed ? 0 : 1.4).opacity(formed ? 0 : 1)
            }
            .scaleEffect(formed ? 1 : 0.001)
            .rotationEffect(.degrees(formed ? 0 : 70))
        }
        .frame(width: 80, height: 80)
        .onAppear { form() }
        .onChange(of: item.id) { _, _ in form() }
        .accessibilityHidden(true)
    }

    private func form() {
        guard !reduceMotion else {
            formed = true
            return
        }
        moveStart = .now
        withAnimation(.easeIn(duration: 0.26)) { formed = false }
        withAnimation(.spring(duration: 0.44, bounce: 0.3).delay(formDelay)) { formed = true }
    }
}
