import SwiftUI
import TesseraCore

// Home's mosaic (Design 199): today as a grid of flat sky-coloured tiles, 6 am on the left to midnight on the right.
// Past hours are set, the hours ahead are pale, the current column breathes and a tile pops now and then. A touch
// ripples the tiles and reads the hour; a finished thing flies in and is laid in this hour's column. Behind Settings ›
// Review › "Home mosaic" (default Off). Builder B places it on Home; Core feeds `MosaicFacts`.

enum HomeMosaicSwitch {
    nonisolated static let choiceID = "homeMosaic"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

/// Holds one mosaic's engine so a host (Next, an app's finish) can lay a tile without owning the drawing.
@MainActor
final class MosaicController {
    let engine = MosaicEngine()
    /// The mosaic's frame in the window, kept by the view, so a struck row's frame can be turned into its space.
    var globalFrame: CGRect = .zero

    private struct Key: Equatable {
        var scene: MosaicScene
        var dark: Bool
        var width: CGFloat
        var nowColumn: Int?
        var text: String?
        var ground: [Double]
    }

    private var key: Key?
    private var restored = false
    private(set) var firstLaidIndex: Int?

    /// A tile flies from the struck row's frame (window space) to a free tile in the now column and is laid there:
    /// glazed for a Next line, an app's accent for a thing finished in its app.
    func lay(from rect: CGRect, tone: MosaicTone, now: Date = AppClock.now) {
        let config = engine.config
        let column = MosaicReadout.nowColumn(now, config: config) ?? 0
        let point = CGPoint(x: rect.midX - globalFrame.minX, y: rect.midY - globalFrame.minY)
        engine.lay(from: point, side: min(max(rect.height, 8), 18), column: column, tone: tone)
        if firstLaidIndex == nil { firstLaidIndex = engine.laid.first?.index }
    }

    /// Re-reads the scene's colours when anything they depend on changed, easing the tiles there from the scene's origin.
    func sync(scene: MosaicScene, facts: MosaicFacts, dark: Bool, ground: MosaicRGB, width: CGFloat, reduceMotion: Bool) {
        engine.reduceMotion = reduceMotion
        engine.resize(width: width)
        let config = engine.config
        if !restored {
            restored = true
            for item in facts.finishedToday {
                engine.restore(column: engine.geometry.column(ofHour: item.hour), tone: item.tone)
            }
            firstLaidIndex = engine.laid.first?.index
        }
        let next = Key(scene: scene, dark: dark, width: width,
                       nowColumn: MosaicReadout.nowColumn(facts.now, config: config),
                       text: MosaicScenes.text(for: scene, facts: facts), ground: [ground.red, ground.green, ground.blue])
        guard next != key else { return }
        let targets = MosaicScenes.targets(scene, geometry: engine.geometry, facts: facts, dark: dark, ground: ground)
        if key == nil {
            engine.settle(to: targets)
        } else {
            let origin = MosaicScenes.origin(scene, geometry: engine.geometry, facts: facts, firstLaid: firstLaidIndex)
            engine.morph(to: targets, origin: origin)
        }
        key = next
    }
}

struct MosaicView: View {
    let facts: MosaicFacts
    @Binding var scene: MosaicScene
    var controller: MosaicController?

    @State private var owned = MosaicController()
    @State private var reading: String?
    @State private var cue = HapticCue()
    @State private var didOpen = false
    @State private var opening = false
    @State private var firedNext = false
    @State private var firedSky = false
    @State private var a11yColumn = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var typeSize

    private var live: MosaicController { controller ?? owned }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            tiles
            Text(reading ?? facts.caption(for: scene))
                .textRole(.data)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .tesseraAnimation(Theme.Motion.snappy, value: reading ?? facts.caption(for: scene))
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
            if let minutes = facts.minutesToSunset, (0 ... 20).contains(minutes), !firedSky {
                firedSky = true
                scene = .sky
            } else if let next = facts.nextTimed, (0 ... 30).contains(next.minutes), !firedNext {
                firedNext = true
                scene = .next
            }
        }
        .tesseraFeedback(cue)
    }

    private var tiles: some View {
        TimelineView(.animation(minimumInterval: lowPower ? 1.0 / 30 : (reduceMotion ? 1.0 / 20 : nil))) { timeline in
            Canvas(rendersAsynchronously: false) { context, size in
                draw(&context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .aspectRatio(CGFloat(MosaicConfig.home.columns) / CGFloat(MosaicConfig.home.rows), contentMode: .fit)
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
            let config = live.engine.config
            a11yColumn = min(max(a11yColumn + (direction == .increment ? 2 : -2), 0), config.columns - 1)
            reading = MosaicReadout.text(column: a11yColumn, config: config, event: event(forColumn: a11yColumn))
        }
    }

    private var lowPower: Bool { ProcessInfo.processInfo.isLowPowerModeEnabled }

    private func event(forColumn column: Int) -> String? {
        let config = live.engine.config
        let hour = config.firstHour + Int((Double(column / 2 * 2) * Double(config.hours) / Double(config.columns)).rounded())
        return facts.events[hour]
    }

    private func touch(at point: CGPoint) {
        let engine = live.engine
        let result = engine.touch(at: point)
        let config = engine.config
        if result.down { cue.play(.soulStroke) }
        if result.spanChanged { cue.play(.selection) }
        if let column = engine.touchedColumn {
            reading = MosaicReadout.text(column: column, config: config, event: event(forColumn: column))
            a11yColumn = column
        }
    }

    // MARK: - Drawing

    private func rgb(_ color: Color, _ environment: EnvironmentValues) -> MosaicRGB {
        let resolved = color.resolve(in: environment)
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
    }

    private func swiftColor(_ value: MosaicRGB, opacity: Double = 1) -> Color {
        Color(.sRGB, red: value.red, green: value.green, blue: value.blue, opacity: opacity)
    }

    private func draw(_ context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let controller = live
        let engine = controller.engine
        let environment = context.environment
        let dark = colorScheme == .dark
        let ground = rgb(Theme.Colors.paper, environment)
        controller.sync(scene: scene, facts: facts, dark: dark, ground: ground, width: size.width,
                        reduceMotion: reduceMotion)
        engine.step(to: time)
        if engine.consumeLandings() > 0 { DispatchQueue.main.async { cue.play(.fleckReachesNow) } }

        let geometry = engine.geometry
        let config = engine.config
        let nowColumn = MosaicReadout.nowColumn(facts.now, config: config)
        var big: [(column: Int, row: Int)] = []
        for column in 0 ..< config.columns {
            for row in 0 ..< config.rows {
                let index = geometry.index(column: column, row: row)
                if engine.isLaid(index) { continue }
                if engine.popProgress(index) != nil { big.append((column, row)) }
                let value = engine.colour(column: column, row: row, nowColumn: nowColumn)
                fill(&context, engine: engine, column: column, row: row, colour: swiftColor(value))
            }
        }
        for tile in big {
            let value = engine.colour(column: tile.column, row: tile.row, nowColumn: nowColumn)
            fill(&context, engine: engine, column: tile.column, row: tile.row, colour: swiftColor(value))
        }
        for item in engine.laid {
            let value = laidColour(item.tone, column: item.column, geometry: geometry, dark: dark, environment: environment)
            let column = item.index / config.rows
            fill(&context, engine: engine, column: column, row: item.index % config.rows,
                 colour: swiftColor(value, opacity: engine.laidOpacity(item)))
        }
        if let flight = engine.flight, let state = engine.flightState() {
            let value = laidColour(flight.tone, column: flight.to / config.rows, geometry: geometry, dark: dark,
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
        let frame = CGRect(x: rect.midX - side / 2 + offset.x, y: rect.midY - side / 2 + offset.y, width: side, height: side)
        context.fill(Path(roundedRect: frame, cornerRadius: config.corner * scale), with: .color(colour))
    }

    /// A glazed tile is its hour's sky x 0.52; an accent tile is the app's accent.
    private func laidColour(
        _ tone: MosaicTone,
        column: Int,
        geometry: MosaicGeometry,
        dark: Bool,
        environment: EnvironmentValues
    ) -> MosaicRGB {
        switch tone {
        case .glaze:
            MosaicColour.scaled(facts.sky.rgb(atHour: geometry.hour(ofColumn: column), dark: dark), geometry.config.glaze)
        case let .accent(app):
            rgb(app.accent, environment)
        }
    }
}
