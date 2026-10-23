import SwiftUI
import TesseraCore

// Home's mosaic (Design 199): today as a grid of flat sky-coloured tiles, 6 am on the left to midnight on the right.
// Past hours are set, the hours ahead are pale, the current column breathes and a tile pops now and then. A touch
// ripples the tiles and reads the hour; a finished thing flies in and is laid in this hour's column. Builder B places
// it
// on Home behind their `homeMosaic` switch (default Off); Core feeds `MosaicFacts`.

/// Holds one mosaic's engine so a host (Next, an app's finish) can lay a tile without owning the drawing.
@MainActor
final class MosaicController {
    let engine: MosaicEngine

    init(config: MosaicConfig = .home) {
        engine = MosaicEngine(config: config)
    }

    /// The mosaic's frame in the window, kept by the view, so a struck row's frame can be turned into its space.
    var globalFrame: CGRect = .zero

    private struct Key: Equatable {
        var scene: MosaicScene
        var dark: Bool
        var width: CGFloat
        var nowColumn: Int?
        var text: String?
        var ground: [Double]
        var mood: MosaicMood?
        var accents: Int
        var sets: Int
    }

    private var lastMood: MosaicMood?

    private var key: Key?
    private var restored = false
    private(set) var firstLaidIndex: Int?

    /// A tile flies from the struck row's frame (window space) to a free tile in the now column and is laid there:
    /// glazed for a Next line, an app's accent for a thing finished in its app.
    func lay(from rect: CGRect, tone: MosaicTone, now: Date = AppClock.now) {
        let column = engine.nowColumn(now) ?? engine.targetLeft
        let point = CGPoint(x: rect.midX - globalFrame.minX, y: rect.midY - globalFrame.minY)
        engine.lay(from: point, side: min(max(rect.height, 8), 18), column: column, tone: tone)
        if firstLaidIndex == nil {
            firstLaidIndex = engine.laid.first?.index
        }
    }

    private var lastDay: Date?

    /// The scenes' input from Core's facts: the moment, the sky at an hour matched to the look, minutes to the next
    /// thing.
    static func input(_ facts: MosaicFacts, dark: Bool) -> MosaicSceneInput {
        MosaicSceneInput(now: facts.now, nextMinutes: facts.freeMinutes) { hour in
            MosaicColour.triple(facts.sky(atHour: hour), dark: dark)
        }
    }

    /// Re-reads the scene's colours when anything they depend on changed, easing the tiles there from the scene's
    /// origin.
    func sync(
        scene: MosaicScene,
        facts: MosaicFacts,
        dark: Bool,
        ground: MosaicTriple,
        width: CGFloat,
        reduceMotion: Bool,
        mood: MosaicMood? = nil,
        moodContext: MosaicMoodContext = MosaicMoodContext()
    ) {
        engine.reduceMotion = reduceMotion
        engine.resize(width: width)
        let config = engine.config
        // A new day clears yesterday's tiles; the first sync lays what finished earlier today with no flight.
        if let lastDay, lastDay != facts.day {
            engine.reset()
            restored = false
            firstLaidIndex = nil
        }
        lastDay = facts.day
        if !restored {
            restored = true
            for item in facts.finishedToday {
                let hour = item.time.timeIntervalSince(facts.day) / 3600
                let tone: MosaicTone = item.app.map { .accent($0) } ?? .glaze
                let local = MosaicGeometry(config: engine.windowConfig, width: width).column(ofHour: hour)
                engine.restore(column: engine.targetLeft + local, tone: tone)
            }
            firstLaidIndex = engine.laid.first?.index
        }
        let input = Self.input(facts, dark: dark)
        let moodField = scene == .day ? mood : nil
        // The mood's own window of the grid, anchored top-right; fields are drawn in the window's own coordinates.
        let size = moodField?.window ?? MosaicWindows.scene
        if config.windowed {
            engine.setWindow(columns: size.columns, rows: size.rows)
        }
        if key == nil {
            engine.snapWindow()
        }
        let window = engine.windowConfig
        let local = MosaicGeometry(config: window, width: width)
        let next = Key(scene: scene, dark: dark, width: width, nowColumn: engine.nowColumn(facts.now),
                       text: MosaicScenes.text(for: scene, input: input), ground: [
                           ground.red,
                           ground.green,
                           ground.blue,
                       ], mood: mood, accents: moodContext.doneAccents.count,
                       sets: moodContext.doneSets * 100 + moodContext.remainingSets)
        guard next != key else { return }
        var context = moodContext
        context.nowColumn = MosaicReadout.nowColumn(facts.now, config: window)
        context.dark = dark
        let fieldColours = moodField.map {
            MosaicMoodField.base($0, geometry: local, input: input, ground: ground, context: context)
        } ?? MosaicScenes.targets(scene, geometry: local, input: input, ground: ground)
        let targets = MosaicWindows.expand(fieldColours, window: (window.columns, window.rows), config: config)
        engine.ground = ground
        let left = engine.targetLeft
        engine.overlay = moodField.flatMap {
            MosaicMoodField.overlay($0, geometry: local, context: context, reduceMotion: reduceMotion)
        }.map { inner in
            { column, row, time, colour in
                inner(min(max(column - left, 0), window.columns - 1), min(row, window.rows - 1), time, colour)
            }
        }
        if key == nil {
            engine.settle(to: targets)
        } else {
            var origin = MosaicScenes.origin(scene, geometry: local, input: input, firstLaid: nil)
            origin = (left + origin.column, origin.row)
            if scene == .done, let first = firstLaidIndex {
                origin = (first / config.rows, first % config.rows)
            }
            let transition = (moodField != nil && moodField != lastMood) ? moodField?.transition ?? .wave : .wave
            engine.morph(to: targets, origin: origin, transition: transition)
        }
        lastMood = moodField
        key = next
    }
}

struct MosaicView: View {
    let facts: MosaicFacts
    @Binding var scene: MosaicScene
    var controller: MosaicController?
    /// The departure mosaic's mood (sheet 200), from Core's `MosaicMoodPicker`; nil is the plain 199 day.
    var mood: MosaicMood?
    var moodContext = MosaicMoodContext()
    /// When the host draws the caption itself (the Home page's slot does), the view writes its one line here and
    /// draws no caption of its own, so the tiles take the whole frame.
    var caption: Binding<String>?

    @State private var owned: MosaicController
    @State private var reading: String?
    @State private var cue = HapticCue()
    @State private var didOpen = false
    @State private var opening = false
    @State private var firedNext = false
    @State private var firedSky = false
    @State private var a11yColumn = 0
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var typeSize

    init(
        facts: MosaicFacts,
        scene: Binding<MosaicScene>,
        controller: MosaicController? = nil,
        mood: MosaicMood? = nil,
        moodContext: MosaicMoodContext = MosaicMoodContext(),
        caption: Binding<String>? = nil
    ) {
        self.caption = caption
        self.facts = facts
        _scene = scene
        self.controller = controller
        self.mood = mood
        self.moodContext = moodContext
        _owned = State(initialValue: MosaicController(config: mood == nil ? .home : .moods))
    }

    private var live: MosaicController {
        controller ?? owned
    }

    private var captionText: String {
        reading ?? facts.caption(for: scene)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            tiles
            if caption == nil {
                Text(captionText)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onChange(of: captionText, initial: true) { _, text in
            caption?.wrappedValue = text
        }
        .task {
            // Opening Home: the time for 2.6 s, then the day.
            guard !didOpen else { return }
            didOpen = true
            opening = true
            scene = .time
        }
        .task(id: scene) {
            guard scene != .day else { return }
            try? await Task.sleep(for: .seconds(scene == .time && opening ? 2.6 : 6))
            guard !Task.isCancelled else { return }
            opening = false
            scene = .day
        }
        .task(id: Int(facts.now.timeIntervalSince1970 / 60)) {
            // Sunset within 20 minutes plays the sky once; a timed thing within 30 plays the next once.
            guard !opening else { return }
            let sunsetMinutes = Int(facts.sunset.timeIntervalSince(facts.now) / 60)
            if (0 ... 20).contains(sunsetMinutes), !firedSky {
                firedSky = true
                scene = .sky
            } else if let free = facts.freeMinutes, facts.nextTimed != nil, (0 ... 30).contains(free), !firedNext {
                firedNext = true
                scene = .next
            }
        }
        .tesseraFeedback(cue)
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private var tiles: some View {
        TimelineView(.animation(minimumInterval: lowPower ? 1.0 / 30 : (reduceMotion ? 1.0 / 20 : nil))) { timeline in
            Canvas(rendersAsynchronously: false) { context, size in
                draw(&context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .aspectRatio(CGFloat(live.engine.config.columns) / CGFloat(live.engine.config.rows), contentMode: .fit)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { live.globalFrame = $0 }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in touch(at: value.location) }
                .onEnded { _ in
                    live.engine.endTouch()
                    reading = nil
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today, as a mosaic of its hours")
        .accessibilityValue(reading ?? facts.caption(for: scene))
        .accessibilityAdjustableAction { direction in
            let window = live.engine.windowConfig
            a11yColumn = min(max(a11yColumn + (direction == .increment ? 2 : -2), 0), window.columns - 1)
            reading = MosaicReadout.text(column: a11yColumn, config: window, event: event(forColumn: a11yColumn))
        }
    }

    private func event(forColumn _: Int) -> String? {
        nil
    }

    private func touch(at point: CGPoint) {
        let engine = live.engine
        let result = engine.touch(at: point)
        let window = engine.windowConfig
        if result.down {
            cue.play(.soulStroke)
        }
        if result.spanChanged {
            cue.play(.selection)
        }
        if let column = engine.touchedColumn {
            let local = engine.localColumn(column)
            reading = MosaicReadout.text(column: local, config: window, event: event(forColumn: local))
            a11yColumn = local
        }
    }

    // MARK: - Drawing

    private func rgb(_ color: Color, _ environment: EnvironmentValues) -> MosaicTriple {
        let resolved = color.resolve(in: environment)
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
    }

    private func swiftColor(_ value: MosaicTriple, opacity: Double = 1) -> Color {
        Color(.sRGB, red: value.red, green: value.green, blue: value.blue, opacity: opacity)
    }

    private func draw(_ context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let controller = live
        let engine = controller.engine
        let environment = context.environment
        let dark = colorScheme == .dark
        let ground = rgb(Theme.Colors.paper, environment)
        controller.sync(scene: scene, facts: facts, dark: dark, ground: ground, width: size.width,
                        reduceMotion: reduceMotion, mood: mood, moodContext: moodContext)
        engine.step(to: time)
        if engine.consumeLandings() > 0 {
            DispatchQueue.main.async { cue.play(.fleckReachesNow) }
        }

        let geometry = engine.geometry
        let config = engine.config
        let nowColumn = engine.nowColumn(facts.now)
        var big: [(column: Int, row: Int)] = []
        for column in 0 ..< config.columns {
            for row in 0 ..< config.rows {
                let index = geometry.index(column: column, row: row)
                if engine.isLaid(index) || engine.isDropped(column: column, row: row) {
                    continue
                }
                if engine.popProgress(index) != nil {
                    big.append((column, row))
                }
                let value = engine.colour(column: column, row: row, nowColumn: nowColumn)
                fill(&context, engine: engine, column: column, row: row, colour: swiftColor(value))
            }
        }
        for tile in big {
            let value = engine.colour(column: tile.column, row: tile.row, nowColumn: nowColumn)
            fill(&context, engine: engine, column: tile.column, row: tile.row, colour: swiftColor(value))
        }
        for item in engine.laid {
            let value = laidColour(
                item.tone,
                column: item.column,
                engine: engine,
                dark: dark,
                environment: environment
            )
            let column = item.index / config.rows
            fill(&context, engine: engine, column: column, row: item.index % config.rows,
                 colour: swiftColor(value, opacity: engine.laidOpacity(item)))
        }
        if let flight = engine.flight, let state = engine.flightState() {
            let value = laidColour(flight.tone, column: flight.to / config.rows, engine: engine, dark: dark,
                                   environment: environment)
            var rotated = context
            rotated.translateBy(x: state.center.x, y: state.center.y)
            rotated.rotate(by: .radians(state.angle))
            let rect = CGRect(x: -state.side / 2, y: -state.side / 2, width: state.side, height: state.side)
            rotated.fill(Path(roundedRect: rect, cornerRadius: config.corner), with: .color(swiftColor(value)))
        }
    }

    private func fill(_ context: inout GraphicsContext, engine: MosaicEngine, column: Int, row: Int, colour: Color) {
        let config = engine.config
        let rect = engine.geometry.rect(column: column, row: row)
        let scale = engine.scale(column: column, row: row)
        let offset = engine.offset(column: column, row: row)
        let side = rect.width * scale
        let frame = CGRect(
            x: rect.midX - side / 2 + offset.x,
            y: rect.midY - side / 2 + offset.y,
            width: side,
            height: side
        )
        context.fill(Path(roundedRect: frame, cornerRadius: config.corner * scale), with: .color(colour))
    }

    /// A glazed tile is its hour's sky x 0.52; an accent tile is the app's accent.
    private func laidColour(
        _ tone: MosaicTone,
        column: Int,
        engine: MosaicEngine,
        dark: Bool,
        environment: EnvironmentValues
    ) -> MosaicTriple {
        switch tone {
        case .glaze:
            let hour = MosaicGeometry(config: engine.windowConfig, width: engine.geometry.width)
                .hour(ofColumn: engine.localColumn(column))
            return MosaicColour.scaled(MosaicColour.triple(facts.sky(atHour: hour), dark: dark), engine.config.glaze)
        case let .accent(app):
            return rgb((HomeApp(rawValue: app.name) ?? .tasks).accent, environment)
        }
    }
}
