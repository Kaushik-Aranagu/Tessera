// swiftlint:disable identifier_name function_body_length function_parameter_count cyclomatic_complexity file_length type_body_length
// A port of the 248 painter: its short drawing names (x, rx, c, t) are kept so it reads against scene.html.
import SwiftUI

/// The habit woodland (sheets 248 and 268 v4), a port of the painter into one SwiftUI `Canvas` on a `TimelineView`:
/// the sky lit by the real hour, the hills and the lake, one tree per routine in three rows at its stage and health,
/// buds for its steps, flowers for done today, fruit for a kept week, a lamp on a planned rest, a caretaker by the
/// lake. It spans the phone's full width (402 x 182, painted in the 354 x 160 scene scaled up) and its edges dissolve
/// into the page; no frame. Hold a tree 1.5 s to water it. Reduce Motion: one still frame, no reactions drawn.
/// One water asked for from outside the woodland, stamped so the same tree can be watered twice.
struct WoodlandWaterRequest: Equatable {
    let id: UUID
    let at: Date
}

struct RoutinesWoodlandScene: View {
    let trees: [WoodlandTree]
    let selected: UUID?
    var hour: Double = 12
    let tap: (UUID) -> Void
    var water: (UUID) -> Void = { _ in }
    /// A water from outside the slot (the foot's Water): the tree springs and blooms as after a hold.
    var waterRequest: WoodlandWaterRequest?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var press: Press?
    @State private var watering: (id: UUID, since: Date)?
    @State private var bloom: (id: UUID, at: Date)?
    @State private var cue = HapticCue()

    private struct Press {
        let start: Date
        let location: CGPoint
        let id: UUID?
        var moved = false
        var ready = false
    }

    static let size = CGSize(width: 402, height: 182)
    /// Scene points (354 x 160) to view points.
    static let paint: CGFloat = 402 / 354
    /// How long a hold waters a tree (268).
    static let holdSeconds: Double = 1.5

    var body: some View {
        let places = WoodlandLayout.places(count: trees.count)
        let families = WoodlandLayout.families(for: places)
        let still = reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
        let light = WoodlandLight.at(hour: hour)
        LiveClock(LiveFeatures.watchWoodland, minimumInterval: 1 / 30, paused: still) { timeline in
            let now = timeline.date
            let t = still ? 0 : now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas { context, _ in
                context.scaleBy(x: Self.paint, y: Self.paint)
                var painter = WoodlandPainter(
                    trees: trees, places: places, families: families, t: t, dark: false, pageDark: scheme == .dark,
                    selected: selected, motion: !still, light: light,
                    watering: still ? nil : watering.map { (
                        $0.id,
                        min(1, now.timeIntervalSince($0.since) / Self.holdSeconds)
                    ) },
                    bloom: still ? nil : bloom.flatMap { now.timeIntervalSince($0.at) < 4.5 ? (
                        $0.id,
                        now.timeIntervalSince($0.at)
                    ) : nil }
                )
                painter.paint(&context)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .mask { EdgeFade(wide: scheme == .dark) }
        .contentShape(Rectangle())
        .gesture(hold(places))
        .tesseraFeedback(cue)
        .overlay { targets(places) }
        .accessibilityElement(children: .contain)
        .onChange(of: waterRequest) { _, request in
            guard let request else { return }
            bloom = (request.id, request.at)
            cue.play(.done)
        }
    }

    /// One gesture for the slot (it owns any drag that starts here): a short tap names or opens; a 1.5 s hold on a
    /// tree waters it (a cloud gathers while held; on release it springs and blooms).
    private func hold(_ places: [WoodlandPlace]) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if press == nil {
                    let id = Self.hit(Self.scene(value.startLocation), trees: trees, places: places)
                    let started = Date()
                    press = Press(start: started, location: value.startLocation, id: id)
                    guard let id else { return }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        guard let current = press, current.start == started, !current.moved else { return }
                        watering = (id, started.addingTimeInterval(0.3))
                        try? await Task.sleep(for: .milliseconds(Int((Self.holdSeconds - 0.3) * 1000)))
                        guard let still = press, still.start == started, !still.moved else { return }
                        press?.ready = true
                        cue.play(.selection)
                    }
                } else if let current = press, !current.moved,
                          hypot(value.location.x - current.location.x, value.location.y - current.location.y) > 10
                {
                    press?.moved = true
                    watering = nil
                }
            }
            .onEnded { _ in
                defer {
                    press = nil
                    watering = nil
                }
                guard let current = press, !current.moved, let id = current.id else { return }
                if current.ready {
                    bloom = (id, Date())
                    cue.play(.done)
                    water(id)
                } else if Date().timeIntervalSince(current.start) < 0.5 {
                    tap(id)
                }
            }
    }

    /// View points to scene points.
    static func scene(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x / paint, y: point.y / paint)
    }

    /// The plant nearest a tap (scene points), within its crown and a 22 pt reach (so every plant has a target).
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

    /// VoiceOver: one element per plant, at its crown, with its name and stage; Water is its own action.
    private func targets(_ places: [WoodlandPlace]) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(zip(trees, places)), id: \.0.id) { tree, place in
                let height = max(tree.height * place.scale, 30) * Self.paint
                Color.clear
                    .frame(width: 44, height: height)
                    .position(x: place.x * Self.paint, y: place.base * Self.paint - height / 2)
                    .allowsHitTesting(false)
                    .accessibilityElement()
                    .accessibilityLabel(([tree.name, tree.stageWords] + [tree.stateWords].compactMap(\.self))
                        .joined(separator: ", "))
                    .accessibilityHint(selected == tree.id ? "Opens it" : "Names it")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("woodland.plant")
                    .accessibilityAction { tap(tree.id) }
                    .accessibilityAction(named: "Water") { water(tree.id) }
            }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
    }
}

/// The scene dissolves into the page (268 v3): an alpha falloff of 11% at the sides, 12% at the top, 18% at the foot.
/// On a black page a bright sky needs a longer fall (268 v2's hardest case), so the dark fade is wider.
private struct EdgeFade: View {
    var wide = false

    var body: some View {
        let side = wide ? 0.2 : 0.11
        LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: side),
                               .init(color: .black, location: 1 - side), .init(color: .clear, location: 1)],
                       startPoint: .leading, endPoint: .trailing)
            .mask {
                LinearGradient(stops: [.init(color: .clear, location: 0),
                                       .init(color: .black, location: wide ? 0.24 : 0.12),
                                       .init(color: .black, location: wide ? 0.74 : 0.82),
                                       .init(color: .clear, location: 1)],
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
    let pageDark: Bool
    let selected: UUID?
    let motion: Bool
    let light: WoodlandLight
    /// The tree being watered and how far the hold has gone (0 to 1).
    let watering: (UUID, Double)?
    /// The tree that was just watered and the seconds since (the spring, petals and a bird, 4.5 s).
    let bloom: (UUID, Double)?

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
        lightPass(&c)
        lamps(&c)
        if motion {
            fireflies(&c)
            reactions(&c)
        }
        // The whole scene leans toward the page so the dissolving edge has less to fade (268 v2).
        let rect = CGRect(origin: .zero, size: WoodlandLayout.sceneSize)
        c.fill(Path(rect), with: .color(pageDark ? Color.black.opacity(0.32) : Color(hex: 0xFBF8F1).opacity(0.12)))
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
        let sky = light.sky
        c.fill(Path(rect), with: .linearGradient(
            Gradient(stops: [.init(color: Color(hex: sky[0]), location: 0),
                             .init(color: Color(hex: sky[1]), location: 0.62),
                             .init(color: Color(hex: sky[2]), location: 1)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: 160)
        ))
        // The sun (warm, low ones redder) or the moon, with a halo; stars at night.
        if let sun = light.sun {
            let halo = Color(hex: light.warmth > 0.3 ? 0xF7C27E : 0xFCE2A6)
            c.fill(Path(rect), with: .radialGradient(
                Gradient(colors: [halo.opacity(0.5), halo.opacity(0)]),
                center: sun, startRadius: 2, endRadius: 70
            ))
            ell(&c, sun.x, sun.y, 10, 10, Color(hex: light.warmth > 0.3 ? 0xF1B76E : 0xF2D18C))
        }
        if let moon = light.moon {
            c.fill(Path(rect), with: .radialGradient(
                Gradient(colors: [Color(hex: 0xDDE4EE).opacity(0.28), .clear]),
                center: moon, startRadius: 1, endRadius: 36
            ))
            ell(&c, moon.x, moon.y, 7, 7, Color(hex: 0xEDEFE6))
            ell(&c, moon.x + 3, moon.y - 1.5, 6, 6, Color(hex: sky[0]))
        }
        if light.isNight {
            for j in 0 ..< 22 {
                let x = Self.seed(Double(j + 300)) * 354, y = Self.seed(Double(j + 500)) * 70
                let twinkle = motion ? 0.4 + 0.6 * abs(sin(t * 0.8 + Double(j))) : 0.8
                ell(&c, x, y, 0.6, 0.6, Color.white.opacity(0.7 * twinkle * light.dim))
            }
        }
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
        let age = bloom.flatMap { $0.0 == tree.id ? $0.1 : nil }
        let spring = age.map { 1 + exp(-$0 * 1.6) * sin($0 * 9) * 0.08 } ?? 1
        c.translateBy(x: place.x, y: place.base)
        c.scaleBy(x: place.scale, y: place.scale * spring)
        c.translateBy(x: -place.x, y: -143)
        let health = tree.health
        var dry: Double = health.isBare ? 1 : health.isWithering ? 0.9 : min(0.25, Double(health.misses) * 0.08)
        // Just watered: it stands up while the moment lasts (the log itself is unchanged).
        if let age {
            dry *= max(0, min(1, (age - 3) / 1.5))
        }
        let days = tree.days
        let h = tree.height
        let base: CGFloat = 143
        let bend = motion ? CGFloat(sin(t * 0.65 + Double(index) * 1.7)) * (days > 35 ? 1 : 1.8) *
            CGFloat(1 - dry * 0.5) : 0
        let x = place.x + bend
        let y = base - h
        // Kinds that wear their own colour (268 v4): jacaranda purple, maple orange-red.
        let tones = switch tree.species {
        case .jacaranda: colors(.violet, dry: dry)
        case .maple: [0xB2553A, 0xD9804F, 0xF0B27A].map { RGB($0).calm.dried(dry * 0.9).color }
        default: colors(family, dry: dry)
        }
        let rx = place.x

        // A soft shadow and the undergrowth at its foot.
        ell(
            &c,
            rx - 8 * light.side,
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
        case .poplar: 13
        case .jacaranda: 38
        default: 26
        }
        let canopyW = (widthBase + mature * 9) * (0.72 + min(104, tree.cap) * 0.0027)
        let canopyH = h *
            (kind == .willow ? 0.48 : kind == .cherry ? 0.32 : kind == .citrus ? 0.37 : kind == .poplar ? 0.72 : kind ==
                .jacaranda ? 0.24 : 0.42)
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
                let lighting = (xx - x) / canopyW * 0.4 * light.side - (yy - cy) / canopyH * 0.8 + sqrt(max(
                    0,
                    1 - rr * rr
                )) * 0.35
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
        // Buds are its steps (268): closed until the day is done, when they open as the flowers above.
        if !tree.doneToday, tree.steps > 0 {
            let count = min(tree.steps, 9)
            for j in 0 ..< count {
                let a = CGFloat(j) / CGFloat(count) * .pi * 2 + 0.4
                let xx = x + cos(a) * wide * 0.72, yy = cy + sin(a) * h * (small ? 0.1 : 0.14)
                ell(&c, xx, yy + 0.8, 1.1, 0.7, Color(hex: 0x6F8A4E))
                ell(&c, xx, yy, 1.25, 1.5, Color(hex: tree.species == .cherry ? 0xE7A6BE : 0xE2A4A0))
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

    // MARK: Light, lamps, fireflies and the watering moment (268)

    /// Where a point drawn in a plant's own space lands in the scene.
    private func world(_ place: WoodlandPlace, _ point: CGPoint) -> CGPoint {
        CGPoint(x: place.x + (point.x - place.x) * place.scale, y: place.base + (point.y - 143) * place.scale)
    }

    /// Night dims the land toward blue; a low sun warms it.
    private func lightPass(_ c: inout GraphicsContext) {
        let rect = CGRect(origin: .zero, size: WoodlandLayout.sceneSize)
        if light.dim > 0.01 {
            var night = c
            night.blendMode = .multiply
            night.fill(Path(rect), with: .color(Color(hex: 0x3A4A6A).opacity(light.dim)))
        }
        if light.warmth > 0.01 {
            var warm = c
            warm.blendMode = .softLight
            warm.fill(Path(rect), with: .color(Color(hex: 0xF3B36B).opacity(light.warmth * 0.45)))
        }
    }

    /// A planned rest hangs a lamp in the tree; it glows once the light is low.
    private func lamps(_ c: inout GraphicsContext) {
        for (tree, place) in zip(trees, places) where tree.restToday && !tree.health.isBare {
            let hang = world(place, CGPoint(x: place.x + 7 * light.side, y: 143 - tree.height * 0.5))
            stroke(&c, Color(hex: 0x6B5B45), 0.5) { p in
                p.move(to: CGPoint(x: hang.x, y: hang.y - 4))
                p.addLine(to: hang)
            }
            if light.dim > 0.15 {
                c.fill(Path(ellipseIn: CGRect(x: hang.x - 12, y: hang.y - 10, width: 24, height: 24)),
                       with: .radialGradient(Gradient(colors: [Color(hex: 0xFFD58A).opacity(0.55 * light.dim + 0.2),
                                                               .clear]),
                                             center: CGPoint(x: hang.x, y: hang.y + 2), startRadius: 0.5,
                                             endRadius: 12))
            }
            ell(&c, hang.x, hang.y + 2, 1.6, 2.2, Color(hex: light.dim > 0.15 ? 0xFFDE9A : 0xD9B26A))
            ell(&c, hang.x, hang.y - 0.2, 1.9, 0.6, Color(hex: 0x6B5B45))
        }
    }

    private func fireflies(_ c: inout GraphicsContext) {
        guard light.isNight else { return }
        for j in 0 ..< 9 {
            let x = 30 + Self.seed(Double(j + 700)) * 294 + CGFloat(sin(t * 0.4 + Double(j))) * 8
            let y = 110 + Self.seed(Double(j + 800)) * 36 + CGFloat(cos(t * 0.5 + Double(j) * 2)) * 4
            let glow = 0.3 + 0.7 * abs(sin(t * 1.3 + Double(j) * 1.7))
            c.fill(Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8)),
                   with: .radialGradient(Gradient(colors: [Color(hex: 0xE9F59A).opacity(0.6 * glow), .clear]),
                                         center: CGPoint(x: x, y: y), startRadius: 0.2, endRadius: 4))
            ell(&c, x, y, 0.7, 0.7, Color(hex: 0xF5FBC4).opacity(glow))
        }
    }

    /// While held: a cloud gathers over the tree and rains on it. After release: petals scatter from the crown, a
    /// ring spreads on the grass and a bird flies in and lands (268 v3), all inside 4.5 s.
    private func reactions(_ c: inout GraphicsContext) {
        if let (id, progress) = watering, let pair = zip(trees, places).first(where: { $0.0.id == id }) {
            let (tree, place) = pair
            let top = place.base - tree.height * place.scale
            let cx = place.x, cy = max(14, top - 12)
            let grow = 0.55 + 0.45 * progress
            for k in 0 ..< 5 {
                let px = cx + CGFloat(k - 2) * 5 * grow
                let r = (5 + Self.seed(Double(k + 90)) * 3) * grow
                ell(&c, px, cy + (k % 2 == 0 ? 0 : -2), r, r * 0.62, Color(hex: 0xC9D3DA).opacity(0.92))
            }
            stroke(&c, Color(hex: 0x8FB4CC).opacity(0.85), 0.7) { p in
                for d in 0 ..< Int(8 + progress * 18) {
                    let dx = cx + (Self.seed(Double(d + 40)) - 0.5) * 22 * grow
                    let fall = CGFloat((t * 60 + Double(d) * 13).truncatingRemainder(dividingBy: 30))
                    let y = cy + 4 + fall
                    guard y < place.base else { continue }
                    p.move(to: CGPoint(x: dx, y: y))
                    p.addLine(to: CGPoint(x: dx - 0.6, y: y + 3))
                }
            }
        }
        guard let (id, age) = bloom, let pair = zip(trees, places).first(where: { $0.0.id == id }) else { return }
        let (tree, place) = pair
        let h = tree.height * place.scale
        let crown = CGPoint(x: place.x, y: place.base - h * 0.7)
        let fade = max(0, 1 - age / 3.2)
        let petals: [UInt32] = [0xF0BED5, 0xF6E3A4, 0xFFFFFF, 0xE6A9C9]
        for j in 0 ..< 34 {
            let a = Self.seed(Double(j + 1000)) * .pi * 2
            let speed = 8 + Self.seed(Double(j + 1100)) * 18
            let x = crown.x + cos(a) * speed * CGFloat(age)
            let y = crown.y + sin(a) * speed * CGFloat(age) * 0.6 + 6 * CGFloat(age * age)
            ell(&c, x, y, 1.3, 0.8, Color(hex: petals[j % 4]).opacity(fade), a + CGFloat(age) * 2)
        }
        let ring = 4 + CGFloat(age) * 14
        c.stroke(Path(ellipseIn: CGRect(x: place.x - ring, y: place.base - ring * 0.22, width: ring * 2,
                                        height: ring * 0.44)),
                 with: .color(Color.white.opacity(0.5 * max(0, 1 - age / 2))), lineWidth: 0.7)
        // The bird: in from the open sky over 1.6 s, then it sits on the crown.
        let land = CGPoint(x: crown.x + 5, y: place.base - h - 1)
        let u = CGFloat(min(1, age / 1.6))
        let ease = 1 - pow(1 - u, 3)
        let from = CGPoint(x: land.x + 70 * light.side, y: 8)
        let bx = from.x + (land.x - from.x) * ease, by = from.y + (land.y - from.y) * ease
        let flap = u < 1 ? CGFloat(sin(age * 22)) * 2.2 : 0.4
        let bird = Color(hex: 0x4E4A57)
        ell(&c, bx, by, 2.4, 1.5, bird)
        ell(&c, bx + 2 * light.side * -1, by - 1.2, 1.1, 1.1, bird)
        stroke(&c, bird, 0.8) { p in
            p.move(to: CGPoint(x: bx - 2.5, y: by - flap))
            p.addQuadCurve(to: CGPoint(x: bx + 2.5, y: by - flap), control: CGPoint(x: bx, y: by - 1))
        }
    }
}
