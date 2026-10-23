import SwiftUI
import TesseraCore
import UIKit

// Home is the mosaic (Design 202): MosaicHomeLayer is Home's background. The whole screen, under the safe areas too,
// is the screen's own pixels; the mood's field comes up out of them with no frame. The sentence, the caption and the
// Next rows sit on top of it. Builder B places the layer and feeds it the core's top and the text's frames.

extension MosaicMood {
    /// How the mood comes in on the screen mosaic (sheet 202): day, golden, rest and night flip like the departure
    /// board; morning and rain fall; running and done wave; back gathers.
    var changeover: MosaicChangeoverKind {
        switch self {
        case .day, .golden, .rest, .night: .flip
        case .morning, .rain: .standard(.fall)
        case .running, .done: .standard(.wave)
        case .back: .standard(.gather)
        }
    }
}

/// Holds the engine, the cached layer of the screen's own pixels and everything a host (Next, an app's finish, a
/// touch) needs.
@MainActor
final class MosaicScreenController {
    private(set) var engine: MosaicScreenEngine?
    /// The layer's origin in the window, so a struck row's frame or a touch can be turned into screen points.
    var globalOrigin: CGPoint = .zero

    private struct Key: Equatable {
        var scene: MosaicScene
        var dark: Bool
        var size: CGSize
        var coreTop: CGFloat
        var nowColumn: Int?
        var text: String?
        var ground: [Double]
        var mood: MosaicMood?
        var accents: Int
        var sets: Int
        var moment: UUID?
        var page: MosaicPage
        var nextClock: String?
        var weekDone: Int
        var reaction: Int
    }

    private var key: Key?
    private var lastPage = MosaicPage.mood
    private var pendingReaction: MosaicOpenReaction?
    private var reactionToken = 0

    /// A reaction on open (sheet 209 B): played at the next sync, never stacked.
    func react(_ reaction: MosaicOpenReaction) {
        pendingReaction = reaction
        reactionToken += 1
    }

    private var restored = false
    private var lastDay: Date?
    private var lastMood: MosaicMood?
    private var lastMoment: MosaicMomentEvent?
    private var momentStart: TimeInterval = 0
    private var lastShield: [CGRect] = []

    // MARK: Hosting

    /// A tile flies from the struck row's frame (window space) to a free tile in the now column and is laid there.
    /// Returns whether a tile was laid or is flying (false when none could be: no layer, or one already in flight).
    @discardableResult
    func lay(from rect: CGRect, tone: MosaicTone, now: Date = AppClock.now) -> Bool {
        guard let engine else { return false }
        let column = engine.nowColumn(now) ?? engine.targetCore.left
        let point = CGPoint(x: rect.midX - globalOrigin.x, y: rect.midY - globalOrigin.y)
        return engine.lay(from: point, side: min(max(rect.height, 8), 18), column: column, tone: tone)
    }

    func touch(atGlobal point: CGPoint) -> Bool {
        engine?.touch(at: CGPoint(x: point.x - globalOrigin.x, y: point.y - globalOrigin.y)) ?? false
    }

    func endTouch() {
        engine?.endTouch()
    }

    // MARK: Sync

    struct Inputs {
        var scene: MosaicScene
        var facts: MosaicFacts
        var dark: Bool
        var ground: MosaicTriple
        var size: CGSize
        var coreTop: CGFloat
        var reduceMotion: Bool
        var mood: MosaicMood?
        var moodContext: MosaicMoodContext
        var moment: MosaicMomentEvent?
        var shield: [CGRect]
        var page: MosaicPage = .mood
        var pageDirection = 1
        var pageFacts: MosaicPageFacts?
    }

    /// Makes the engine for this size and re-reads the scene's colours when anything they depend on changed.
    @discardableResult
    func sync(_ inputs: Inputs) -> MosaicScreenEngine {
        let engine = engine ?? MosaicScreenEngine(size: inputs.size, coreTop: inputs.coreTop)
        self.engine = engine
        engine.reduceMotion = inputs.reduceMotion
        engine.configure(size: inputs.size, coreTop: inputs.coreTop, dark: inputs.dark, ground: inputs.ground)
        let facts = inputs.facts
        if let lastDay, lastDay != facts.day {
            engine.reset()
            restored = false
        }
        lastDay = facts.day
        let moodField = inputs.scene == .day ? inputs.mood : nil
        let moment = inputs.moment
        let size = moment?.moment.window ?? moodField?.window ?? MosaicWindows.scene
        engine.setWindow(columns: size.columns, rows: size.rows)
        if key == nil {
            engine.snapWindow()
        }
        if inputs.shield != lastShield {
            lastShield = inputs.shield
            engine.shield = engine.grid.shield(for: inputs.shield)
        }
        restoreFinished(engine, facts: facts, once: &restored)
        let input = MosaicController.input(facts, dark: inputs.dark)
        let next = Key(scene: inputs.scene, dark: inputs.dark, size: inputs.size, coreTop: inputs.coreTop,
                       nowColumn: engine.nowColumn(facts.now), text: MosaicScenes.text(for: inputs.scene, input: input),
                       ground: [inputs.ground.red, inputs.ground.green, inputs.ground.blue], mood: inputs.mood,
                       accents: inputs.moodContext.doneAccents.count,
                       sets: inputs.moodContext.doneSets * 100 + inputs.moodContext.remainingSets, moment: moment?.id,
                       page: inputs.page, nextClock: inputs.pageFacts?.nextClock,
                       weekDone: inputs.pageFacts?.weekDone ?? 0,
                       reaction: reactionToken)
        guard next != key else { return engine }
        if let moment, moment.id != lastMoment?.id {
            momentStart = engine.clock
        }
        retarget(engine, inputs: inputs, input: input, moodField: moodField)
        if let moment, moment.id != lastMoment?.id {
            flyFinished(engine, moment: moment, facts: facts)
        }
        lastMoment = moment
        lastMood = moodField
        key = next
        return engine
    }

    private func restoreFinished(_ engine: MosaicScreenEngine, facts: MosaicFacts, once restored: inout Bool) {
        guard !restored else { return }
        restored = true
        let window = MosaicGeometry(config: engine.windowConfig, width: 0)
        for item in facts.finishedToday {
            let hour = item.time.timeIntervalSince(facts.day) / 3600
            let column = engine.targetCore.left + window.column(ofHour: hour)
            guard let row = engine.freeRow(inColumn: column) else { continue }
            engine.restore(column: column, row: row, tone: item.app.map { .accent($0) } ?? .glaze)
        }
    }

    // swiftlint:disable:next function_body_length
    private func retarget(
        _ engine: MosaicScreenEngine,
        inputs: Inputs,
        input: MosaicSceneInput,
        moodField: MosaicMood?
    ) {
        let window = engine.windowConfig
        let local = MosaicGeometry(config: window, width: 0)
        var context = inputs.moodContext
        context.nowColumn = MosaicReadout.nowColumn(inputs.facts.now, config: window)
        context.dark = inputs.dark
        let ground = inputs.ground
        let moment = inputs.moment
        // The moment's plan: its field, its light and its sway, in the window's own coordinates.
        let plan = moment.map { event -> MosaicMomentPlan in
            let under = MosaicMoodField.base(moodField ?? .day, geometry: local, input: input, ground: ground,
                                             context: context)
            return MosaicMomentField.plan(event.moment, under: under, window: (window.columns, window.rows),
                                          ground: ground, context: context, start: momentStart,
                                          reduceMotion: inputs.reduceMotion)
        }
        let digits = MosaicScenes.digitTiles(for: inputs.scene, input: input, geometry: local)
        let colourAt: (Int, Int) -> MosaicTriple = { column, row in
            let place = engine.local(column: column, row: row)
            let jitterIndex = abs(column &* 7919 &+ row)
            if let plan, let base = plan.base, moment?.moment.ownField == true {
                let clampedColumn = min(max(place.column, 0), window.columns - 1)
                let clampedRow = min(max(place.row, 0), window.rows - 1)
                return base[clampedColumn * window.rows + clampedRow]
            }
            var colour: MosaicTriple = if let mood = moodField ?? (moment != nil ? .day : nil) {
                MosaicMoodField.colour(mood, column: place.column, row: place.row, geometry: local,
                                       input: input, ground: ground, context: context,
                                       jitterIndex: jitterIndex)
            } else {
                MosaicScenes.colour(inputs.scene, column: place.column, row: place.row, geometry: local,
                                    input: input, ground: ground, digits: digits, jitterIndex: jitterIndex)
            }
            if let step = moment?.moment.stepBack, step > 0 {
                colour = MosaicColour.mix(colour, ground, step)
            }
            // A glance washes the mood behind it 18% toward the app's accent; the rim samples that, never the sign.
            if case let .glance(app)? = moment?.moment {
                colour = MosaicColour.mix(
                    colour,
                    MosaicMomentField.glanceAccent(app, context),
                    MosaicMomentField.glanceWash
                )
            }
            return colour
        }
        let left = engine.targetCore.left, top = engine.targetCore.top
        func mapped(_ column: Int, _ row: Int) -> (Int, Int) {
            (min(max(column - left, 0), window.columns - 1), min(max(row - top, 0), window.rows - 1))
        }
        let moodLight = moodField.flatMap {
            MosaicMoodField.overlay($0, geometry: local, context: context, reduceMotion: inputs.reduceMotion)
        }
        // A page other than the mood draws its own sign in the window (never under a moment, which plays over any
        // page).
        let pageLight: MosaicMoodField.Overlay? = moment == nil && inputs.scene == .day && inputs.page != .mood
            ? MosaicPageField.light(inputs.page, cols: window.columns, rows: window.rows, start: engine.clock,
                                    ground: ground, context: context, facts: inputs.pageFacts,
                                    still: inputs.reduceMotion)
            : nil
        let light = sparkled(plan?.overlay ?? pageLight ?? moodLight, engine: engine, moment: moment, input: input,
                             local: local, context: context, reduceMotion: inputs.reduceMotion)
        // During an announcement the rim samples the background, never the words.
        var signOnly = pageLight != nil
        switch moment?.moment {
        case .announce?, .glance?: signOnly = true
        default: break
        }
        engine.rimSamplesLight = !signOnly
        engine.overlay = light.map { inner in
            { column, row, time, colour in
                let place = mapped(column, row)
                return inner(place.0, place.1, time, colour)
            }
        }
        engine.scaleHook = plan?.scale.map { hook in
            { column, row, time in
                let place = mapped(column, row)
                return hook(place.0, place.1, time)
            }
        }
        engine.offsetHook = plan?.offset.map { hook in
            { column, row, time in
                let place = mapped(column, row)
                return hook(place.0, place.1, time)
            }
        }
        let origin = (column: engine.grid.centreColumn, row: engine.grid.coreTop + window.rows / 2)
        let nightAt: (Int, Int) -> MosaicTriple = { column, row in
            let place = engine.local(column: column, row: row)
            return MosaicMoodField.colour(.night, column: place.column, row: place.row, geometry: local, input: input,
                                          ground: ground, context: context, jitterIndex: abs(column &* 7919 &+ row))
        }
        let dustyAt: (Int, Int) -> MosaicTriple = { column, row in
            let place = engine.local(column: column, row: row)
            return MosaicMoodField.colour(.back, column: place.column, row: place.row, geometry: local, input: input,
                                          ground: ground, context: context, jitterIndex: abs(column &* 7919 &+ row))
        }
        let reaction = inputs.reduceMotion || moment != nil ? nil : pendingReaction
        pendingReaction = nil
        if key == nil {
            if reaction == .gather {
                // A cold launch: night first, then gather into now after 500 ms, 1.8 s.
                engine.settle(colourAt: nightAt)
                engine.morph(.standard(.gather), origin: origin, total: reaction?.duration, after: reaction?.delay ?? 0,
                             colourAt: colourAt)
            } else {
                engine.settle(colourAt: colourAt)
            }
            lastPage = inputs.page
            return
        }
        switch reaction {
        case .ripple?:
            engine.rippleFromCentre(seconds: MosaicOpenReaction.ripple.duration)
            return
        case .flip?:
            engine.morph(.flipRows, origin: origin, total: MosaicOpenReaction.flip.duration, colourAt: colourAt)
            return
        case .nightToDay?:
            engine.morph(.standard(.fall), origin: origin, total: MosaicOpenReaction.nightToDay.duration,
                         from: nightAt, colourAt: colourAt)
            return
        case .back?:
            engine.morph(.standard(.gather), origin: origin, total: MosaicOpenReaction.back.duration,
                         from: dustyAt, colourAt: colourAt)
            return
        default: break
        }
        var kind = changeover(plan: plan, moment: moment, moodField: moodField)
        var total: TimeInterval?
        if inputs.page != lastPage {
            // A page wipes in the swipe's direction in 0.5 s.
            kind = .wipeColumns(reverse: inputs.pageDirection < 0)
            total = MosaicPage.wipeSeconds
        }
        lastPage = inputs.page
        engine.morph(kind, origin: origin, total: total, colourAt: colourAt)
    }

    /// Which changeover to use: a moment's own way in, the hand-back of the moment that just ended, the mood's own
    /// (flip for day, golden, rest and night), or a wave for a scene.
    private func changeover(plan: MosaicMomentPlan?, moment: MosaicMomentEvent?, moodField: MosaicMood?)
        -> MosaicChangeoverKind
    {
        if let plan, moment?.id != lastMoment?.id {
            return .standard(plan.transition)
        }
        if moment == nil, let previous = lastMoment {
            switch previous.moment.returnChangeover {
            case .melt: return .melt
            case let .transition(value): return .standard(value)
            }
        }
        if let moodField, moodField != lastMood {
            return moodField.changeover
        }
        return .standard(.wave)
    }

    private func sparkled(
        _ light: MosaicMoodField.Overlay?,
        engine: MosaicScreenEngine,
        moment: MosaicMomentEvent?,
        input: MosaicSceneInput,
        local: MosaicGeometry,
        context: MosaicMoodContext,
        reduceMotion: Bool
    ) -> MosaicMoodField.Overlay? {
        guard let moment, !reduceMotion, case let .finished(tone) = moment.moment else { return light }
        let column = (engine.nowColumn(input.now) ?? engine.targetCore.left) - engine.targetCore.left
        let landing = (column: column, row: Int(Double(local.config.rows) * 0.62))
        let accent: MosaicTriple = switch tone {
        case .glaze: MosaicColour.scaled(input.sky(local.hour(ofColumn: landing.column)), 1.25)
        case let .accent(app): context.accents[app] ?? context.ink
        }
        let sparkle = MosaicMomentField.sparkleLight(landing: landing, colour: accent, start: momentStart)
        return { column, row, time, colour in
            sparkle(column, row, time, light?(column, row, time, colour) ?? colour)
        }
    }

    /// One tile flies from the top-right, under the sentence, to the now column at 62% height.
    private func flyFinished(_ engine: MosaicScreenEngine, moment: MosaicMomentEvent, facts: MosaicFacts) {
        guard case let .finished(tone) = moment.moment else { return }
        let column = engine.nowColumn(facts.now) ?? engine.targetCore.left
        let row = engine.grid.coreTop + Int(Double(engine.windowTarget.rows) * 0.62)
        engine.lay(from: CGPoint(x: engine.grid.centreColumn.cgFloat * MosaicScreenGrid.step * 1.6, y: -8), side: 10,
                   column: column, tone: tone, row: row)
    }
}

private extension Int {
    var cgFloat: CGFloat {
        CGFloat(self)
    }
}

// MARK: - The layer

struct MosaicHomeLayer: View {
    let facts: MosaicFacts
    @Binding var scene: MosaicScene
    let controller: MosaicScreenController
    /// Points from the top of the screen to the core's top (the old block's top).
    var coreTop: CGFloat
    /// The sentence's, the caption's and the Next rows' frames in window space: the field is capped there.
    var shield: [CGRect] = []
    var mood: MosaicMood?
    var moodContext = MosaicMoodContext()
    var moment: MosaicMomentEvent?
    /// The view writes its one caption line here for the host to draw.
    var caption: Binding<String>?
    /// The mosaic's page (sheet 209 C), from B's pager, the swipe's direction and what the pages read.
    var page: MosaicPage = .mood
    var pageDirection = 1
    var pageFacts: MosaicPageFacts?

    /// Whether this process has opened Home yet (a cold launch plays its own reaction once).
    @MainActor private static var launched = false

    @State private var tracker = MosaicOpenTracker()
    @Environment(\.scenePhase) private var scenePhase
    @State private var cue = HapticCue()
    @State private var didOpen = false
    @State private var opening = false
    @State private var firedNext = false
    @State private var firedSky = false
    @State private var visible = true
    @State private var active: MosaicMomentEvent?
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var captionText: String {
        page == .mood || scene != .day ? facts.caption(for: scene) : page.caption(facts: facts, page: pageFacts)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: lowPower ? 1.0 / 30 : nil, paused: !visible)) { timeline in
            Canvas(rendersAsynchronously: false) { context, size in
                draw(&context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { controller.globalOrigin = $0 }
        .onAppear {
            visible = true
            // The first open of this process is a cold launch: gather from night. Never over a moment, never under
            // Reduce Motion.
            if !Self.launched {
                Self.launched = true
                if !reduceMotion, active == nil {
                    controller.react(.gather)
                }
                tracker.recordOpen()
            }
        }
        .onDisappear { visible = false }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                tracker.recordBackground()
            } else if phase == .active {
                // A reopen reacts once, by how long he was away; a moment already playing wins; no haptic.
                guard !reduceMotion, active == nil, scene == .day else {
                    tracker.recordOpen()
                    return
                }
                let cue = facts.openCue(lastBackground: tracker.lastBackground, lastOpen: tracker.lastOpen,
                                        coldLaunch: false)
                controller.react(cue.reaction)
                tracker.recordOpen()
            }
        }
        .onChange(of: captionText, initial: true) { _, text in
            caption?.wrappedValue = text
        }
        .onChange(of: moment, initial: true) { _, event in
            if let event {
                active = event
            }
        }
        .onChange(of: mood) { _, _ in active = nil }
        .task(id: active?.id) {
            guard let event = active else { return }
            try? await Task.sleep(for: .seconds(event.moment.duration))
            guard !Task.isCancelled, active?.id == event.id else { return }
            active = nil
        }
        .task {
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
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .tesseraFeedback(cue)
    }

    // MARK: Drawing

    private func rgb(_ color: Color, _ environment: EnvironmentValues) -> MosaicTriple {
        let resolved = color.resolve(in: environment)
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
    }

    private func draw(_ context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let environment = context.environment
        let dark = colorScheme == .dark
        let ground = rgb(Theme.Colors.paper, environment)
        var momentContext = moodContext
        momentContext.ink = rgb(Theme.Colors.ink, environment)
        momentContext.tess = rgb(Theme.Colors.tess, environment)
        for app in AppID.allCases {
            momentContext.accents[app] = rgb((HomeApp(rawValue: app.name) ?? .tasks).accent, environment)
        }
        let engine = controller.sync(.init(scene: scene, facts: facts, dark: dark, ground: ground, size: size,
                                           coreTop: coreTop, reduceMotion: reduceMotion, mood: mood,
                                           moodContext: momentContext, moment: active,
                                           shield: shield.map { $0.offsetBy(dx: -controller.globalOrigin.x,
                                                                            dy: -controller.globalOrigin.y) },
                                           page: page, pageDirection: pageDirection, pageFacts: pageFacts))
        engine.step(to: time)
        if engine.consumeLandings() > 0 {
            DispatchQueue.main.async { cue.play(.fleckReachesNow) }
        }
        let grid = engine.grid
        let nowColumn = engine.nowColumn(facts.now)
        let region = engine.region
        context.withCGContext { cg in
            drawField(cg, engine: engine, nowColumn: nowColumn, region: region, dark: dark, environment: environment)
        }
    }

    private func drawField(
        _ cg: CGContext,
        engine: MosaicScreenEngine,
        nowColumn: Int?,
        region: MosaicTileRect,
        dark: Bool,
        environment: EnvironmentValues
    ) {
        let grid = engine.grid
        let columns = max(region.left, 0) ... min(region.right, grid.columns - 1)
        let rows = max(region.top, 0) ... min(region.bottom, grid.rows - 1)
        var ghosts: [(CGRect, MosaicTriple)] = []
        for column in columns {
            for row in rows {
                guard let tile = engine.tile(column: column, row: row, nowColumn: nowColumn),
                      !engine.isLaid(grid.index(column: column, row: row)) else { continue }
                fill(cg, grid: grid, column: column, row: row, tile: tile)
                if let ghost = tile.ghost {
                    let rect = grid.rect(column: column, row: row)
                    let side = rect.width * ghost.scale
                    ghosts.append((
                        CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2 + ghost.offset.y, width: side,
                               height: side),
                        ghost.colour
                    ))
                }
            }
        }
        for ghost in ghosts {
            cg.setFillColor(red: ghost.1.red, green: ghost.1.green, blue: ghost.1.blue, alpha: 1)
            cg.fill(ghost.0)
        }
        for item in engine.laid {
            let tone = laidColour(item.tone, column: item.column, engine: engine, dark: dark, environment: environment)
            let rect = grid.rect(column: item.column, row: item.row)
            cg.setFillColor(red: tone.red, green: tone.green, blue: tone.blue, alpha: engine.laidOpacity(item))
            cg.fill(rect.insetBy(dx: -0.4, dy: -0.4))
        }
        if let flight = engine.flight, let state = engine.flightState() {
            let tone = laidColour(
                flight.tone,
                column: flight.column,
                engine: engine,
                dark: dark,
                environment: environment
            )
            cg.saveGState()
            cg.translateBy(x: state.center.x, y: state.center.y)
            cg.rotate(by: state.angle)
            cg.setFillColor(red: tone.red, green: tone.green, blue: tone.blue, alpha: 1)
            cg.fill(CGRect(x: -state.side / 2, y: -state.side / 2, width: state.side, height: state.side))
            cg.restoreGState()
        }
    }

    private func fill(_ cg: CGContext, grid: MosaicScreenGrid, column: Int, row: Int, tile: MosaicScreenTile) {
        let rect = grid.rect(column: column, row: row)
        let width = rect.width * tile.scale
        let height = width * tile.scaleY
        cg.setFillColor(red: tile.colour.red, green: tile.colour.green, blue: tile.colour.blue, alpha: 1)
        cg.fill(CGRect(
            x: rect.midX - width / 2 + tile.offset.x,
            y: rect.midY - height / 2 + tile.offset.y,
            width: width,
            height: height
        ))
    }

    private func laidColour(
        _ tone: MosaicTone,
        column: Int,
        engine: MosaicScreenEngine,
        dark: Bool,
        environment: EnvironmentValues
    ) -> MosaicTriple {
        switch tone {
        case .glaze:
            let hour = MosaicGeometry(config: engine.windowConfig, width: 0)
                .hour(ofColumn: column - engine.targetCore.left)
            return MosaicColour.scaled(MosaicColour.triple(facts.sky(atHour: hour), dark: dark), 0.52)
        case let .accent(app):
            return rgb((HomeApp(rawValue: app.name) ?? .tasks).accent, environment)
        }
    }
}

// MARK: - Touch

extension View {
    /// Feeds every touch on this view (above the page, so the whole of Home) to the mosaic as lean and ripple, without
    /// taking it from the buttons and the scroll view.
    func mosaicTouchFeed(_ controller: MosaicScreenController, enabled: Bool = true) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if enabled {
                        _ = controller.touch(atGlobal: value.location)
                    }
                }
                .onEnded { _ in controller.endTouch() }
        )
    }
}
