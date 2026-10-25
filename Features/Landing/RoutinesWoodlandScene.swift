// swiftlint:disable identifier_name function_body_length function_parameter_count cyclomatic_complexity file_length type_body_length
// A port of the 248 painter: its short drawing names (x, rx, c, t) are kept so it reads against scene.html.
import SwiftUI

/// The habit woodland (sheet 248), a port of `scene.html`'s painter into one SwiftUI `Canvas` on a `TimelineView`:
/// the sky and hills, the lake in the clearing, one plant per routine at its stage and health, flowers for done today,
/// fruit for a kept week, a nest from day 30, a caretaker resting by the lake. 354 x 160 pt, its edges fading into the
/// page. Reduce Motion: one still frame (no sway, no clouds, no butterfly).
struct RoutinesWoodlandScene: View {
    let trees: [WoodlandTree]
    let selected: UUID?
    let tap: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    static let size = WoodlandLayout.sceneSize

    var body: some View {
        let places = WoodlandLayout.places(count: trees.count)
        let families = WoodlandLayout.families(for: places)
        let still = reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
        TimelineView(.animation(minimumInterval: 1 / 30, paused: still)) { timeline in
            let t = still ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas { context, _ in
                var painter = WoodlandPainter(trees: trees, places: places, families: families, t: t,
                                              dark: scheme == .dark, selected: selected, motion: !still)
                painter.paint(&context)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .mask { EdgeFade() }
        .contentShape(Rectangle())
        .gesture(SpatialTapGesture().onEnded { value in
            if let id = Self.hit(value.location, trees: trees, places: places) {
                tap(id)
            }
        })
        .overlay { targets(places) }
        .accessibilityElement(children: .contain)
    }

    /// The plant nearest a tap, within its crown and a 22 pt reach (so every visible plant has a target).
    static func hit(_ point: CGPoint, trees: [WoodlandTree], places: [WoodlandPlace]) -> UUID? {
        var best: (UUID, CGFloat)?
        for (tree, place) in zip(trees, places) {
            let height = tree.height * place.scale
            let center = CGPoint(x: place.x, y: place.base - height / 2)
            let reachX = max(22, 26 * place.scale)
            let reachY = max(22, height / 2 + 6)
            let dx = abs(point.x - center.x), dy = abs(point.y - center.y)
            guard dx <= reachX, dy <= reachY else { continue }
            let distance = hypot(dx, dy)
            if best == nil || distance < best!.1 {
                best = (tree.id, distance)
            }
        }
        return best?.0
    }

    /// VoiceOver: one element per plant, at its crown, with its name and stage.
    private func targets(_ places: [WoodlandPlace]) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(zip(trees, places)), id: \.0.id) { tree, place in
                let height = max(tree.height * place.scale, 30)
                Color.clear
                    .frame(width: 44, height: height)
                    .position(x: place.x, y: place.base - height / 2)
                    .allowsHitTesting(false)
                    .accessibilityElement()
                    .accessibilityLabel(([tree.name, tree.stageWords] + [tree.stateWords].compactMap(\.self))
                        .joined(separator: ", "))
                    .accessibilityHint(selected == tree.id ? "Opens it" : "Names it")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("woodland.plant")
                    .accessibilityAction { tap(tree.id) }
            }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
    }
}

/// The scene's edges fade into the page (248: the slot background is the page colour).
private struct EdgeFade: View {
    var body: some View {
        LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.12),
                               .init(color: .black, location: 0.88), .init(color: .clear, location: 1)],
                       startPoint: .leading, endPoint: .trailing)
            .mask {
                LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.2),
                                       .init(color: .black, location: 0.86), .init(color: .clear, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
    }
}

// MARK: - Painter

/// An RGB triple that can be calmed (22% toward grey) and dried (toward the straw colour of a thirsty plant).
private struct RGB {
    var r: Double, g: Double, b: Double

    init(_ hex: UInt32) {
        r = Double((hex >> 16) & 0xFF)
        g = Double((hex >> 8) & 0xFF)
        b = Double(hex & 0xFF)
    }

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    var calm: RGB {
        let grey = r * 0.27 + g * 0.56 + b * 0.17
        return RGB(r: r * 0.78 + grey * 0.22, g: g * 0.78 + grey * 0.22, b: b * 0.78 + grey * 0.22)
    }

    func dried(_ dry: Double) -> RGB {
        RGB(r: r * (1 - dry) + 161 * dry, g: g * (1 - dry) + 132 * dry, b: b * (1 - dry) + 92 * dry)
    }

    var color: Color {
        Color(red: r / 255, green: g / 255, blue: b / 255)
    }
}

private struct WoodlandPainter {
    let trees: [WoodlandTree]
    let places: [WoodlandPlace]
    let families: [WoodlandFamily]
    let t: Double
    let dark: Bool
    let selected: UUID?
    let motion: Bool

    private static let palettes: [WoodlandFamily: [UInt32]] = [
        .blue: [0x426D92, 0x7CA6BC, 0xC4D8DD], .green: [0x62884D, 0xA3BD70, 0xDCE5B1],
        .violet: [0x816A9C, 0xBAA0D0, 0xE4D6EE], .rose: [0xA47C80, 0xC9A1A0, 0xE8CEBD],
        .pearl: [0x89958F, 0xBDC4B6, 0xE5E6D3], .gold: [0xA08D5B, 0xC6B47C, 0xE7D9A8],
    ]

    private var ink: Color {
        Color(hex: dark ? 0xE8DFCC : 0x605D50)
    }

    mutating func paint(_ c: inout GraphicsContext) {
        landscape(&c)
        let order = Array(zip(trees, places).enumerated()).sorted { $0.element.1.base < $1.element.1.base }
        for (index, pair) in order where pair.1.base <= 126 {
            plant(&c, pair.0, pair.1, index: index, family: families[index])
        }
        pond(&c)
        for (index, pair) in order where pair.1.base > 126 {
            plant(&c, pair.0, pair.1, index: index, family: families[index])
        }
        keeper(&c)
        if motion {
            butterfly(&c)
        }
    }

    // MARK: Shapes

    private func ell(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                     _ shading: GraphicsContext.Shading, _ angle: CGFloat = 0)
    {
        let rx = max(0.1, rx), ry = max(0.1, ry)
        let path = Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
            .applying(CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: x, y: y)))
        c.fill(path, with: shading)
    }

    private func ell(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                     _ color: Color, _ angle: CGFloat = 0)
    {
        ell(&c, x, y, rx, ry, .color(color), angle)
    }

    private func stroke(_ c: inout GraphicsContext, _ color: Color, _ width: CGFloat, _ build: (inout Path) -> Void) {
        var path = Path()
        build(&path)
        c.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private static func seed(_ k: Double) -> CGFloat {
        let a = sin(k * 127.1 + 311.7) * 43758.5453
        return CGFloat(a - floor(a))
    }

    // MARK: Landscape

    private func landscape(_ c: inout GraphicsContext) {
        let rect = CGRect(origin: .zero, size: WoodlandLayout.sceneSize)
        let sky = dark ? [0x101918, 0x283832, 0x3D4735] : [0xDEE9DF, 0xF0E3C4, 0xD9D6AB]
        c.fill(Path(rect), with: .linearGradient(
            Gradient(stops: [.init(color: Color(hex: UInt32(sky[0])), location: 0),
                             .init(color: Color(hex: UInt32(sky[1])), location: 0.62),
                             .init(color: Color(hex: UInt32(sky[2])), location: 1)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: 160)
        ))
        // The sun and its halo.
        let halo = Color(hex: 0xFCE2A6)
        c.fill(Path(CGRect(x: 180, y: 0, width: 174, height: 120)), with: .radialGradient(
            Gradient(colors: [halo.opacity(dark ? 0.2 : 0.5), halo.opacity(0)]),
            center: CGPoint(x: 281, y: 27), startRadius: 2, endRadius: dark ? 40 : 70
        ))
        ell(&c, 281, 27, 10, 10, Color(hex: dark ? 0xE2E3CB : 0xF2D18C))
        // Slow clouds.
        for cloud in 0 ..< 3 {
            let speed = 0.9 + Double(cloud) * 0.12
            let x = CGFloat((t * speed + Double(cloud) * 127 + 32).truncatingRemainder(dividingBy: 430)) - 38
            let y = CGFloat(22 + cloud * 9)
            for puff in 0 ..< 6 {
                let px = x + CGFloat(puff) * 6
                let py = y + sin(CGFloat(puff) * 2 + CGFloat(cloud)) * 1.5
                let r = 6 + Self.seed(Double(puff + cloud * 8)) * 4
                let white = Color(hex: dark ? 0xAEBEC7 : 0xF7F4DF)
                ell(&c, px, py, r, r * 0.38, .radialGradient(
                    Gradient(colors: [white.opacity(dark ? 0.15 : 0.55), white.opacity(0)]),
                    center: CGPoint(x: px, y: py), startRadius: 1, endRadius: r
                ))
            }
        }
        // Three hill layers, the far one with faint trees.
        let hills: [UInt32] = dark ? [0x293B38, 0x3B4539, 0x4B503E] : [0xC5C7B6, 0xC0B99B, 0xB9B18A]
        for layer in 0 ..< 3 {
            let base = CGFloat(97 + layer * 12)
            var path = Path()
            path.move(to: CGPoint(x: 0, y: base + 7))
            for x in stride(from: CGFloat(0), through: 354, by: 6) {
                let wave = sin(x * 0.018 + CGFloat(layer) * 2) * 7 + sin(x * 0.044 + CGFloat(layer)) * 3
                path.addLine(to: CGPoint(x: x, y: base + wave))
            }
            path.addLine(to: CGPoint(x: 354, y: 160))
            path.addLine(to: CGPoint(x: 0, y: 160))
            path.closeSubpath()
            c.fill(path, with: .color(Color(hex: hills[layer])))
            if layer == 0 {
                let faint = Color(hex: dark ? 0x859C9C : 0xA0B6A0).opacity(0.16)
                for j in 0 ..< 16 {
                    let x = CGFloat(j) * 24 + Self.seed(Double(j)) * 10
                    let h = 7 + Self.seed(Double(j + 54)) * 10
                    let y = base - 4 + sin(x * 0.018) * 4
                    ell(&c, x, y - h * 0.3, h * 0.38, h * 0.55, faint)
                    ell(&c, x - h * 0.25, y - h * 0.15, h * 0.3, h * 0.4, faint)
                }
            }
        }
        // The ochre path.
        stroke(&c, Color(hex: dark ? 0x8E8865 : 0xDACC9E), 7) { p in
            p.move(to: CGPoint(x: 15, y: 155))
            p.addCurve(to: CGPoint(x: 181, y: 154), control1: CGPoint(x: 73, y: 137), control2: CGPoint(x: 115, y: 157))
            p.addCurve(
                to: CGPoint(x: 339, y: 130),
                control1: CGPoint(x: 241, y: 151),
                control2: CGPoint(x: 278, y: 145)
            )
        }
        // Grass blades, one path.
        let sway = motion ? sin(t * 0.5) * 0.6 : 0
        stroke(&c, Color(hex: dark ? 0x94AA76 : 0x627E4D).opacity(0.45), 0.55) { p in
            for i in 0 ..< 75 {
                let x = 7 + CGFloat(i) * 4.5, y = 146 + sin(CGFloat(i) * 3.5) * 6
                p.move(to: CGPoint(x: x, y: y))
                p.addQuadCurve(to: CGPoint(x: x + 1.5 + sway, y: y - 5 - CGFloat(i % 5)),
                               control: CGPoint(x: x + sway * 0.5, y: y - 4))
            }
        }
    }

    // MARK: The lake

    private func pond(_ c: inout GraphicsContext) {
        let night = dark
        var bank = Path()
        bank.move(to: CGPoint(x: 145, y: 124))
        bank.addCurve(to: CGPoint(x: 210, y: 124), control1: CGPoint(x: 159, y: 111), control2: CGPoint(x: 198, y: 113))
        bank.addLine(to: CGPoint(x: 207, y: 128))
        bank.addCurve(to: CGPoint(x: 145, y: 128), control1: CGPoint(x: 183, y: 123), control2: CGPoint(x: 163, y: 122))
        bank.closeSubpath()
        c.fill(bank, with: .color(Color(hex: night ? 0x637361 : 0xB8B08A)))

        var water = Path()
        water.move(to: CGPoint(x: 156, y: 121))
        water.addCurve(
            to: CGPoint(x: 204, y: 122),
            control1: CGPoint(x: 166, y: 117),
            control2: CGPoint(x: 193, y: 117)
        )
        water.addCurve(
            to: CGPoint(x: 227, y: 137),
            control1: CGPoint(x: 208, y: 126),
            control2: CGPoint(x: 224, y: 130)
        )
        water.addCurve(
            to: CGPoint(x: 201, y: 150),
            control1: CGPoint(x: 232, y: 144),
            control2: CGPoint(x: 218, y: 149)
        )
        water.addCurve(
            to: CGPoint(x: 139, y: 146),
            control1: CGPoint(x: 181, y: 154),
            control2: CGPoint(x: 154, y: 151)
        )
        water.addCurve(
            to: CGPoint(x: 138, y: 131),
            control1: CGPoint(x: 126, y: 143),
            control2: CGPoint(x: 128, y: 137)
        )
        water.addCurve(
            to: CGPoint(x: 156, y: 121),
            control1: CGPoint(x: 145, y: 128),
            control2: CGPoint(x: 150, y: 125)
        )
        water.closeSubpath()
        c.fill(water, with: .linearGradient(
            Gradient(stops: [.init(color: Color(hex: night ? 0x8EA49F : 0xD3DDD0), location: 0),
                             .init(color: Color(hex: night ? 0x496B70 : 0x9CB9B0), location: 0.35),
                             .init(color: Color(hex: night ? 0x71918B : 0xBFD0BF), location: 1)]),
            startPoint: CGPoint(x: 0, y: 118), endPoint: CGPoint(x: 0, y: 153)
        ))
        var inside = c
        inside.clip(to: water)
        // Uneven wavelets catch the sky; no rings.
        stroke(&inside, Color(hex: night ? 0xD1DED0 : 0xF3F1DA).opacity(night ? 0.4 : 0.7), 0.4) { p in
            for j in 0 ..< 16 {
                let y = 122 + CGFloat(j) * 1.75
                let width = 3 + (y - 120) * 0.28
                let drift = motion ? sin(t * 0.28 + Double(j)) * 0.7 : 0
                let x = 136 + Self.seed(Double(j + 24)) * 79 + drift
                p.move(to: CGPoint(x: x, y: y))
                p.addCurve(to: CGPoint(x: x + width, y: y), control1: CGPoint(x: x + width * 0.35, y: y + 0.2),
                           control2: CGPoint(x: x + width * 0.7, y: y - 0.2))
            }
        }
        // The near shore covers the water's lower edge.
        var shore = Path()
        shore.move(to: CGPoint(x: 130, y: 143))
        shore.addCurve(
            to: CGPoint(x: 184, y: 153),
            control1: CGPoint(x: 147, y: 151),
            control2: CGPoint(x: 169, y: 149)
        )
        shore.addCurve(
            to: CGPoint(x: 230, y: 140),
            control1: CGPoint(x: 201, y: 151),
            control2: CGPoint(x: 217, y: 147)
        )
        shore.addLine(to: CGPoint(x: 230, y: 146))
        shore.addCurve(
            to: CGPoint(x: 129, y: 148),
            control1: CGPoint(x: 202, y: 157),
            control2: CGPoint(x: 155, y: 160)
        )
        shore.closeSubpath()
        c.fill(shore, with: .color(Color(hex: night ? 0x727D5D : 0xBDB88D)))
        stroke(&c, Color(hex: night ? 0x8DA77A : 0x7F946C), 0.5) { p in
            for j in 0 ..< 38 {
                let u = CGFloat(j) / 37, x = 131 + u * 98, y = 147 + sin(u * .pi) * 6
                let h = 2 + Self.seed(Double(j + 11)) * 3.4
                p.move(to: CGPoint(x: x, y: y + 1))
                p.addQuadCurve(to: CGPoint(x: x + 1, y: y - h), control: CGPoint(x: x + 0.5, y: y - h * 0.5))
            }
        }
    }

    // MARK: Plants

    private func colors(_ family: WoodlandFamily, dry: Double) -> [Color] {
        (Self.palettes[family] ?? Self.palettes[.pearl]!).map { RGB($0).calm.dried(dry * 0.9).color }
    }

    private func plant(_ g: inout GraphicsContext, _ tree: WoodlandTree, _ place: WoodlandPlace, index: Int,
                       family: WoodlandFamily)
    {
        var c = g
        c.translateBy(x: place.x, y: place.base)
        c.scaleBy(x: place.scale, y: place.scale)
        c.translateBy(x: -place.x, y: -143)
        let health = tree.health
        let dry: Double = health.isBare ? 1 : health.isWithering ? 0.9 : min(0.25, Double(health.misses) * 0.08)
        let days = tree.days
        let h = tree.height
        let base: CGFloat = 143
        let bend = motion ? CGFloat(sin(t * 0.65 + Double(index) * 1.7)) * (days > 35 ? 1 : 1.8) *
            CGFloat(1 - dry * 0.5) : 0
        let x = place.x + bend
        let y = base - h
        let tones = colors(family, dry: dry)
        let rx = place.x

        // A soft shadow and the undergrowth at its foot.
        ell(
            &c,
            rx - 8,
            base + 1,
            max(7, h * 0.32),
            2 + h * 0.025,
            Color(hex: dark ? 0x14222C : 0x405739).opacity(0.2),
            -0.1
        )
        for k in 0 ..< 5 {
            let a = CGFloat(k) * 2.4
            ell(&c, rx + cos(a) * 7, base - 1 + sin(a) * 1.6, 2.6, 1.6,
                Color(hex: dark ? (k % 2 == 0 ? 0x5C785C : 0x6E8567) : (k % 2 == 0 ? 0x91A46D : 0xB1B780)), a * 0.3)
        }

        if health.isBare {
            bare(&c, tree, x: x, rx: rx, base: base, h: h, withering: false)
        } else if health.isWithering, tree.isBush {
            bare(&c, tree, x: x, rx: rx, base: base, h: h, withering: true)
        } else if days < 3 {
            stroke(&c, Color(hex: 0x8A9970), 0.9) { p in
                p.move(to: CGPoint(x: rx, y: base))
                p.addQuadCurve(to: CGPoint(x: x, y: y + 5), control: CGPoint(x: x - 1, y: base - 8))
            }
            ell(&c, x - 4, y + 5, 5, 2.5, tones[1], 0.4)
            ell(&c, x + 4, y + 3, 5, 2.5, tones[2], -0.5)
        } else if days < 7 {
            stroke(&c, tones[0], 1) { p in
                p.move(to: CGPoint(x: rx, y: base))
                p.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: rx + 2, y: base - 10),
                           control2: CGPoint(x: x - 2, y: y + 8))
            }
            for j in 0 ..< 3 {
                let side: CGFloat = j % 2 == 0 ? -1 : 1
                ell(&c, x + side * 4, y + 10 + CGFloat(j) * 6, 6, 2.5, tones[1 + j % 2], side * -0.6)
            }
            for j in 0 ..< 6 {
                let a = CGFloat(j) * .pi * 2 / 6, r: CGFloat = tree.doneToday ? 6 : 4
                ell(&c, x + cos(a) * r * 0.7, y + sin(a) * r * 0.7, r * 0.65, r * 0.4, tones[j % 3], a)
            }
            ell(&c, x, y, 1.6, 1.6, Color(hex: 0xD1B872))
        } else if tree.isBush {
            for j in 0 ..< 7 {
                let xx = x + CGFloat(j - 3) * 4.8
                let yy = base - h * (0.65 + Self.seed(Double(j + index * 13)) * 0.35)
                stroke(&c, tones[0], 0.9) { p in
                    p.move(to: CGPoint(x: rx, y: base))
                    p.addQuadCurve(to: CGPoint(x: xx + bend * 0.3, y: yy),
                                   control: CGPoint(x: rx + (xx - rx) * 0.8, y: base - h * 0.35))
                }
                for q in 0 ..< 4 {
                    let u = CGFloat(q) / 4, side: CGFloat = q % 2 == 0 ? -1 : 1
                    ell(&c, rx + (xx - rx) * (1 - u * 0.5) + side * 3, yy + CGFloat(q) * 7, 5.5, 2.2,
                        tones[(j + q) % 3], side * 0.6)
                }
            }
        } else {
            canopyTree(&c, tree, x: x, rx: rx, base: base, h: h, tones: tones, index: index)
        }
        if !health.isWithering, !health.isBare {
            signals(&c, tree, x: x, base: base, h: h)
        }
        if tree.id == selected {
            ell(&c, rx, 150, 2, 2, ink)
        }
    }

    private func bare(_ c: inout GraphicsContext, _ tree: WoodlandTree, x: CGFloat, rx: CGFloat, base: CGFloat,
                      h: CGFloat, withering: Bool)
    {
        let color = Color(hex: dark ? 0xCFC0A2 : 0x8D7A64)
        let days = tree.days
        let branches = days < 7 ? 3 : (tree.isBush ? 6 : 9)
        stroke(&c, color, days < 7 ? 1.2 : days < 28 ? 1.5 : 2.2) { p in
            p.move(to: CGPoint(x: rx, y: base))
            p.addCurve(to: CGPoint(x: x, y: base - h * 0.91), control1: CGPoint(x: rx - 2, y: base - h * 0.25),
                       control2: CGPoint(x: x + 2, y: base - h * 0.6))
        }
        stroke(&c, color, 1) { p in
            for j in 0 ..< branches {
                let u = 0.26 + CGFloat(j) / CGFloat(branches + 1) * 0.6
                let side: CGFloat = j % 2 == 0 ? -1 : 1
                let yy = base - h * u
                let xx = x + side * h * (days < 7 ? 0.16 : 0.24) * (1 - u * 0.55)
                let tip = yy - h * 0.13
                p.move(to: CGPoint(x: x, y: yy + 3))
                p.addQuadCurve(to: CGPoint(x: xx, y: tip), control: CGPoint(x: x + side * 3, y: yy - 2))
            }
        }
        if withering {
            for j in 0 ..< 9 {
                let xx = x + (Self.seed(Double(j * 19 + days)) - 0.5) * min(34, h * 0.6)
                ell(&c, xx, base + Self.seed(Double(j + 33)) * 2, 1.5, 0.55,
                    Color(hex: j % 2 == 0 ? 0x8C825C : 0xAB916C).opacity(0.55), CGFloat(j) * 0.7)
            }
        }
    }

    private func canopyTree(_ c: inout GraphicsContext, _ tree: WoodlandTree, x: CGFloat, rx: CGFloat, base: CGFloat,
                            h: CGFloat, tones: [Color], index: Int)
    {
        let kind = tree.species
        let mature = min(1, CGFloat(tree.days - 28) / 35)
        let widthBase: CGFloat = switch kind {
        case .pine: 18
        case .oak: 31
        case .cherry: 30
        case .citrus: 23
        default: 26
        }
        let canopyW = (widthBase + mature * 9) * (0.72 + min(104, tree.cap) * 0.0027)
        let canopyH = h * (kind == .willow ? 0.48 : kind == .cherry ? 0.32 : kind == .citrus ? 0.37 : 0.42)
        let trunkH = h * 0.66
        let y = base - h
        // The trunk.
        let w = 2 + mature * 1.7
        var trunk = Path()
        trunk.move(to: CGPoint(x: rx - w, y: base))
        trunk.addCurve(
            to: CGPoint(x: x - 0.6, y: y + canopyH * 0.5),
            control1: CGPoint(x: rx - w - 1, y: base - h * 0.3),
            control2: CGPoint(x: x - 1, y: base - trunkH * 0.75)
        )
        trunk.addLine(to: CGPoint(x: x + 0.8, y: y + canopyH * 0.5))
        trunk.addCurve(to: CGPoint(x: rx + w, y: base), control1: CGPoint(x: x + 2, y: base - trunkH * 0.75),
                       control2: CGPoint(x: rx + w - 1, y: base - h * 0.3))
        trunk.closeSubpath()
        let birch = kind == .birch
        c.fill(trunk, with: .linearGradient(
            Gradient(colors: [Color(hex: birch ? 0xA8A38E : 0x786B52), Color(hex: birch ? 0xDAD2B8 : 0xBAA482),
                              Color(hex: birch ? 0xA9AA93 : 0x8C795D)]),
            startPoint: CGPoint(x: rx - 4, y: 0), endPoint: CGPoint(x: rx + 4, y: 0)
        ))
        // Branches.
        stroke(&c, Color(hex: dark ? 0xA69B82 : 0x88765D), 0.6 + mature * 0.45) { p in
            for j in 0 ..< 7 {
                let yy = base - h * (0.28 + CGFloat(j) * 0.065)
                let side: CGFloat = j % 2 == 0 ? -1 : 1
                let xx = x + side * canopyW * (0.28 + Self.seed(Double(j + index)) * 0.5)
                let tipY = yy - h * (0.1 + Self.seed(Double(j + 8 + index)) * 0.07)
                p.move(to: CGPoint(x: x, y: yy + 7))
                p.addQuadCurve(to: CGPoint(x: xx, y: tipY), control: CGPoint(x: x + (xx - x) * 0.6, y: yy))
            }
        }
        let thin = tree.health.isWithering
        if kind == .pine {
            for j in 0 ..< 11 {
                if thin, j % 5 != 0 {
                    continue
                }
                let yy = y + 6 + CGFloat(j) * h * 0.055
                let wide = (6 + CGFloat(j) * 1.5) * (1 + mature * 0.3)
                var tier = Path()
                tier.move(to: CGPoint(x: x, y: yy - 10))
                tier.addCurve(to: CGPoint(x: x - wide, y: yy + 7), control1: CGPoint(x: x - 3, y: yy - 3),
                              control2: CGPoint(x: x - wide * 0.7, y: yy + 1))
                tier.addQuadCurve(to: CGPoint(x: x, y: yy + 5), control: CGPoint(x: x - 3, y: yy + 3))
                tier.addQuadCurve(to: CGPoint(x: x + wide, y: yy + 7), control: CGPoint(x: x + wide * 0.5, y: yy + 4))
                tier.addQuadCurve(to: CGPoint(x: x, y: yy - 10), control: CGPoint(x: x + 3, y: yy - 3))
                c.fill(tier, with: .linearGradient(Gradient(colors: [tones[0], tones[2], tones[0]]),
                                                   startPoint: CGPoint(x: x - wide, y: yy),
                                                   endPoint: CGPoint(x: x + wide, y: yy)))
            }
            return
        }
        let cy = y + canopyH * 0.62
        let masses = kind == .willow ? 8 : 13
        if !thin {
            for j in 0 ..< masses {
                let a = CGFloat(j) * 2.399
                let rr = sqrt((CGFloat(j) + 0.5) / CGFloat(masses)) * (kind == .citrus ? 0.8 : 1)
                let xx = x + cos(a) * canopyW * rr * 0.85
                let yy = cy + sin(a) * canopyH * rr * 0.65
                let rad = (kind == .oak ? 10 : kind == .willow ? 5 : 8)
                    + (1 - rr) * (kind == .citrus ? 13 : kind == .willow ? 5 : 10)
                ell(&c, xx, yy, rad * (kind == .willow ? 0.9 : 1), rad * (kind == .willow ? 1.3 : 0.85),
                    .radialGradient(Gradient(colors: [tones[2], tones[0]]), center: CGPoint(x: xx - 4, y: yy - 5),
                                    startRadius: 1, endRadius: rad))
            }
        }
        let leaves = kind == .willow ? 50 : 70
        for j in 0 ..< leaves {
            let s = Double(j + index * 97)
            if Self.seed(s + 401) < (thin ? 0.82 : 0) {
                continue
            }
            let a = Self.seed(s + 44) * .pi * 2
            let rr = sqrt(Self.seed(s + 122)) * (kind == .citrus ? 0.88 : 1)
            let xx = x + cos(a) * canopyW * rr
            let yy = cy + sin(a) * canopyH * rr * 0.82
            let sway = motion ? CGFloat(sin(t * (0.7 + Double(Self.seed(s))) + Double(j))) * 0.5 : 0
            if kind == .willow {
                for k in 0 ..< 3 {
                    ell(&c, xx + sway, yy + CGFloat(k) * 5 + 4, 1.3, 2.8, tones[(j + k) % 3], -0.15)
                }
            } else {
                let lighting = (xx - x) / canopyW * 0.4 - (yy - cy) / canopyH * 0.8 + sqrt(max(0, 1 - rr * rr)) * 0.35
                let tone = lighting > 0.45 ? 2 : lighting < -0.12 ? 0 : 1
                ell(
                    &c,
                    xx + sway,
                    yy,
                    2.1 + Self.seed(s + 8) * 2.8,
                    1.3 + Self.seed(s + 9) * 1.5,
                    tones[tone],
                    a * 0.45
                )
            }
        }
        if thin {
            for j in 0 ..< 9 {
                let xx = x + (Self.seed(Double(j * 19 + index)) - 0.5) * min(34, h * 0.6)
                ell(&c, xx, base + Self.seed(Double(j + 33)) * 2, 1.5, 0.55,
                    Color(hex: j % 2 == 0 ? 0x8C825C : 0xAB916C).opacity(0.55), CGFloat(j) * 0.7)
            }
        }
    }

    /// Flowers for done today, fruit for a kept week, a nest from day 30.
    private func signals(_ c: inout GraphicsContext, _ tree: WoodlandTree, x: CGFloat, base: CGFloat, h: CGFloat) {
        let small = tree.isBush
        let cy = small ? base - h * 0.76 : base - h + h * (tree.species == .cherry ? 0.32 : 0.42) * 0.62
        let wide = small ? 12 : min(28, h * 0.3)
        if tree.doneToday {
            for j in 0 ..< 3 {
                let a = CGFloat(j) * 2.4 + 1
                let xx = x + cos(a) * wide * 0.6, yy = cy + sin(a) * h * 0.12
                for k in 0 ..< 5 {
                    let b = CGFloat(k) * .pi * 2 / 5
                    ell(&c, xx + cos(b) * 1.4, yy + sin(b) * 1.4, 1.4, 0.9,
                        Color(hex: tree.species == .cherry ? 0xF0BED5 : 0xEFDEC6), b)
                }
                ell(&c, xx, yy, 0.6, 0.6, Color(hex: 0xC4A164))
            }
        }
        if tree.hasFruit {
            let fruit: UInt32 = switch tree.species {
            case .citrus: 0xEEA04E
            case .cherry: 0xB65D80
            case .oak: 0xB99760
            case .birch: 0x9B798D
            case .pine: 0xB49A63
            default: 0xC8A367
            }
            for j in 0 ..< min(4, tree.fruitCycle) {
                let a = 2 + CGFloat(j) * 2.2
                let xx = x + cos(a) * wide * 0.7, yy = cy + sin(a) * h * 0.13
                let size: CGFloat = small ? 1.8 : tree.species == .citrus ? 3.15 : 2.4
                stroke(&c, Color(hex: 0x6F7050), 0.5) { p in
                    p.move(to: CGPoint(x: xx, y: yy - 2.8))
                    p.addLine(to: CGPoint(x: xx, y: yy))
                }
                ell(&c, xx, yy, size, size, Color(hex: fruit))
            }
        }
        if tree.hasNest {
            let nx = x + 7, ny = base - h * 0.39
            stroke(&c, Color(hex: 0x998569), 0.7) { p in
                p.move(to: CGPoint(x: nx - 3, y: ny))
                p.addQuadCurve(to: CGPoint(x: nx + 4, y: ny - 1), control: CGPoint(x: nx, y: ny + 3))
                p.move(to: CGPoint(x: nx - 3, y: ny + 1))
                p.addLine(to: CGPoint(x: nx + 3, y: ny + 2))
            }
        }
    }

    // MARK: The caretaker and visitors

    /// The caretaker rests by the lake (the walk out to plant and water is a later step).
    private func keeper(_ c: inout GraphicsContext) {
        let x: CGFloat = 181, y: CGFloat = 151
        ell(&c, x, y + 1, 5, 1.2, Color(hex: 0x40573A).opacity(0.25))
        ell(&c, x, y - 4, 2.6, 3.6, Color(hex: dark ? 0xC9A27A : 0xB0705A))
        ell(&c, x, y - 9.5, 1.9, 1.9, Color(hex: dark ? 0xE7CDB0 : 0xD9B596))
        ell(&c, x, y - 11, 3.4, 0.9, Color(hex: dark ? 0xD8C690 : 0xC9A65A))
    }

    /// A butterfly visits a plant that was done today.
    private func butterfly(_ c: inout GraphicsContext) {
        let done = zip(trees, places).filter { $0.0.doneToday && !$0.0.health.isWithering && !$0.0.health.isBare }
        guard !done.isEmpty else { return }
        let pick = done[Int(t / 8) % done.count]
        let h = pick.0.height * pick.1.scale
        let x = pick.1.x + CGFloat(sin(t * 1.2)) * 15
        let y = pick.1.base - h * 0.72 + CGFloat(cos(t * 1.5)) * 8
        let flap = max(0.5, abs(CGFloat(sin(t * 9))) * 3)
        for side: CGFloat in [-1, 1] {
            ell(&c, x + side * 3, y, flap, 3, Color(hex: dark ? 0xDFBD83 : 0xD0A371), side * 0.4)
        }
    }
}
