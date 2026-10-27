import SwiftUI
import TesseraCore

/// A room the root shell holds alongside Bridge (sheet 283 v5): its content for each route, its own drawings (a
/// scene keystone), its intents and what it presents. One driver per room lives as long as the shell.
@MainActor
protocol ShellRoomDriver: AnyObject {
    /// The room's id, a `ShellRoute.room`.
    var room: String { get }
    var accent: Color { get }
    /// Tess wears this room's colour on its landing.
    var tessRoom: AppID? { get }
    func content(model: AppModel, scheme: ColorScheme) -> any RoomContent
    /// Draws one of the room's own places (a `SlotPayload.scene` key); nil when the key is not this room's.
    func scene(_ key: String) -> AnyView?
    /// The page behind the places while this room shows; nil keeps the theme's page.
    var backdrop: AnyView? { get }
    /// Answers a touch on one of its places; false leaves it to the shell (back pops).
    func handle(_ intent: ShellIntent, navigator: ShellNavigator) -> Bool
    /// The room's sheets and alerts, laid behind the shell.
    func presenter() -> AnyView
    /// How the room's keystone comes in from Bridge's mosaic (sheet 283 v4 flip orders).
    var flip: KeystoneFlip { get }
    /// The room's door-summary move (sheet 283 v6) and glyph library.
    var summaryStyle: DoorSummaryStyle { get }
    var glyphRoom: GlyphKind.Room? { get }
    /// A colour scheme the room's page forces (Lookout's plate); nil keeps the phone's.
    var scheme: ColorScheme? { get }
    /// The room's hand-over drawn over the shell while its landing shows (a ticket falling, chalk dust, drops).
    func overlay(navigator: ShellNavigator) -> AnyView
    /// Called when the room's landing comes in from Bridge.
    func entered(navigator: ShellNavigator)
}

extension ShellRoomDriver {
    func scene(_: String) -> AnyView? {
        nil
    }

    var backdrop: AnyView? {
        nil
    }

    func presenter() -> AnyView {
        AnyView(EmptyView())
    }

    var summaryStyle: DoorSummaryStyle {
        .plain
    }

    var glyphRoom: GlyphKind.Room? {
        nil
    }

    var scheme: ColorScheme? {
        nil
    }

    func overlay(navigator _: ShellNavigator) -> AnyView {
        AnyView(EmptyView())
    }

    func entered(navigator _: ShellNavigator) {}
}

/// The rooms of the root shell, by id, routing each route to its room's content.
struct RootShellContent: RoomContent {
    let rooms: [String: any RoomContent]
    var flips: [String: KeystoneFlip] = [:]

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        guard var screen = rooms[route.room]?.screen(for: route, state: state) else {
            return Screen(layout: .landing, slots: [:])
        }
        if screen.flip == nil {
            screen.flip = flips[route.room]
        }
        return screen
    }
}

/// Which shell room a Home link or door opens. Rooms the shell does not hold yet keep their own pages.
enum ShellRoomIDs {
    static func room(for link: HomeLink) -> String? {
        switch link {
        case .notes: NotesRoomContent.room
        case .training: "deck"
        case .recipes: "galley"
        case .money: "purse"
        case .review: "watch"
        case .settings: "settings"
        case .groceries, .lists, .pantry, .pasteRecipe, .today: nil
        }
    }

    static func room(for door: HomeV2Door) -> String? {
        switch door {
        case .review: "watch"
        case .lookout: "lookout"
        case .settings: "settings"
        case let .app(app):
            switch app {
            case .notes: NotesRoomContent.room
            case .training: "deck"
            case .kitchen: "galley"
            case .money: "purse"
            case .routines: "watch"
            default: nil
            }
        }
    }
}

extension EnvironmentValues {
    /// Opens a Home door (the apps dial's rows) in the standing shell when it holds that room; false keeps the
    /// door's own page.
    @Entry var openShellDoor: @MainActor (HomeV2Door) -> Bool = { _ in false }
}

/// Whether Bridge and its rooms run in the one standing shell. On by default; `-classicBridge` on the simulator
/// draws Bridge as its own page with rooms as full-screen pages, as before.
enum ShellHome {
    static var isOn: Bool {
        !LaunchFlags.has("-classicBridge")
    }
}

/// The root of Home in the standing shell (sheet 283 v5): one persistent `ShellView` holds Bridge and every room the
/// registry has a driver for. Opening a room from Bridge pushes its route, and every place changes in place: the
/// masthead flaps, the mosaic flips into the room's keystone in the room's order, the widget rises, the dial reels,
/// the action word streams. Back (the Nav word, the edge pull, Tess's double tap) runs it the other way, every place
/// restored. Rooms without a driver yet open on their own pages, as before.
struct RootShellHost: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.realModel) private var realModel
    @State private var navigator = ShellNavigator(root: .landing(BridgeRoomContent.room))
    @State private var stage = BridgeStage()
    @State private var drivers: [String: any ShellRoomDriver] = ShellRooms.drivers()
    /// The mosaic's own pixels behind Bridge: kept while it flips away, gone in a room.
    @State private var field = FieldState()
    @State private var minute = 0

    private var onBridge: Bool {
        navigator.route.room == BridgeRoomContent.room
    }

    var body: some View {
        let _ = model.revision
        let route = navigator.route
        let driver = drivers[route.room]
        ShellView(room: content(), navigator: navigator, accent: driver?.accent ?? Theme.Colors.ink, act: handle)
            .environment(\.shellScene) { key in scene(key) }
            .environment(\.shellBackdrop, AnyView(backdrop(driver)))
            .environment(\.openShellDoor) { door in openDoor(door) }
            .environment(\.doorSummaryStyle, driver?.summaryStyle ?? .plain)
            .environment(\.shellGlyphRoom, driver?.glyphRoom)
            .modifier(SchemeOverride(scheme: onBridge ? nil : driver?.scheme))
            .overlay {
                if let driver, !onBridge, navigator.route.level == 0 {
                    driver.overlay(navigator: navigator)
                }
            }
            .modifier(BridgeLife(stage: stage, showing: onBridge, tessElsewhere: true))
            .overlay { tess(driver) }
            .modifier(BridgeDoors(stage: stage))
            .background {
                ForEach(Array(drivers.keys.sorted()), id: \.self) { id in
                    drivers[id]?.presenter()
                }
            }
            .onAppear { wire() }
            .onChange(of: onBridge) { _, now in
                moveField(toBridge: now)
                if !now, let driver {
                    driver.entered(navigator: navigator)
                }
            }
            // Rooms that read the clock (Lookout's sky) refresh each minute.
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60 - Double(Calendar.current.component(.second, from: .now))))
                    minute += 1
                }
            }
        #if DEBUG
            .task {
                NotesDemo.seedIfRequested(model)
                await ShellStills.walkRoot(navigator)
            }
        #endif
    }

    // MARK: Content

    private func content() -> RootShellContent {
        (drivers[SettingsRoomContent.room] as? SettingsRoomDriver)?.realModel = realModel
        let _ = minute
        var rooms: [String: any RoomContent] = [BridgeRoomContent.room: BridgeRoomContent()]
        var flips: [String: KeystoneFlip] = [:]
        for (id, driver) in drivers {
            flips[id] = driver.flip
        }
        // Only the room on screen loads its facts: every room's facts on every frame is far too slow (the Settings
        // privacy scan alone), and the shell only ever asks for the current route.
        let current = navigator.route.room
        if let driver = drivers[current] {
            rooms[current] = driver.content(model: model, scheme: scheme)
        }
        return RootShellContent(rooms: rooms, flips: flips)
    }

    /// The room being entered or left: its flip order for the mosaic's tiles.
    private var flipOrder: KeystoneFlip {
        let room = navigator.stack.first { $0.room != BridgeRoomContent.room }?.room
            ?? navigator.change?.from.room ?? NotesRoomContent.room
        return drivers[room]?.flip ?? .rows
    }

    private func scene(_ key: String) -> AnyView {
        if key.hasPrefix("bridge.") {
            return AnyView(BridgeRoomContent.draw(key, stage: stage))
        }
        let room = String(key.split(separator: ".").first ?? "")
        return drivers[room]?.scene(key) ?? AnyView(EmptyView())
    }

    private func backdrop(_ driver: (any ShellRoomDriver)?) -> some View {
        ZStack {
            if let page = driver?.backdrop {
                page
            } else {
                ThemedBackground()
            }
            if field.mounted {
                BridgeField(stage: stage)
                    .modifier(FieldFlip(
                        time: field.time,
                        entering: field.entering,
                        plain: field.plain,
                        flip: field.flip
                    ))
            }
        }
    }

    /// Tess: on Bridge her own layer (the mosaic's); in a room her soul in the room's colour, whose double tap goes
    /// back to Bridge.
    @ViewBuilder
    private func tess(_ driver: (any ShellRoomDriver)?) -> some View {
        if onBridge, stage.layerOn, HomeMosaic.appsListIsOn {
            BridgeTess(stage: stage)
        } else {
            BottomChrome(onSoulDoubleTap: { toBridge() }, room: onBridge ? nil : driver?.tessRoom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    // MARK: Intents and opening rooms

    private func handle(_ intent: ShellIntent) {
        if let driver = drivers[navigator.route.room], driver.handle(intent, navigator: navigator) {
            return
        }
        if intent == .back {
            navigator.pop()
        }
    }

    /// Starts the field's half of the flip: away in the room's order when a room opens, back in when Bridge returns.
    /// Reduce Motion: a 150 ms cross-fade.
    private func moveField(toBridge: Bool) {
        field.flip = flipOrder
        field.token += 1
        let mine = field.token
        field.mounted = true
        field.entering = toBridge
        field.plain = reduceMotion
        field.time = 0
        let duration = reduceMotion ? ShellTiming.reducedFade : TileFlipTransition.whole
        Task { @MainActor in
            await Task.yield()
            withAnimation(MotionPolicy.resolve(.linear(duration: duration), reduceMotion: false)) { field.time = 1 }
            guard !toBridge else { return }
            try? await Task.sleep(for: .seconds(duration))
            if field.token == mine {
                field.mounted = false
            }
        }
    }

    private func toBridge() {
        while navigator.canPop {
            navigator.pop()
        }
    }

    private func wire() {
        stage.model = model
        stage.openInShell = { link in
            guard let room = ShellRoomIDs.room(for: link), drivers[room] != nil else { return false }
            enter(room)
            return true
        }
        stage.openDoorInShell = { door in openDoor(door) }
    }

    private func openDoor(_ door: HomeV2Door) -> Bool {
        guard let room = ShellRoomIDs.room(for: door), drivers[room] != nil else { return false }
        enter(room)
        return true
    }

    /// Bridge to a room: its landing, from Bridge's level (a room opened from a room's page goes back to Bridge
    /// first, so back always lands on Bridge).
    private func enter(_ room: String) {
        guard navigator.route.room != room else { return }
        if navigator.route.room != BridgeRoomContent.room {
            toBridge()
        }
        navigator.push(.landing(room))
    }
}

/// The mosaic's pixels leaving Bridge (and coming back): outside the keystone they fade; inside it the tiles turn
/// away in the room's order (sheet 283 v4, the flip), or turn back in on the way back.
struct FieldState {
    var mounted = true
    var time = 1.0
    var entering = true
    var plain = false
    var flip = KeystoneFlip.rows
    var token = 0
}

/// The field's mask during the flip.
struct FieldFlip: ViewModifier, Animatable {
    var time: Double
    let entering: Bool
    var plain = false
    let flip: KeystoneFlip

    nonisolated var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func body(content: Content) -> some View {
        if plain {
            content.opacity(entering ? time : 1 - time)
        } else {
            tiles(content)
        }
    }

    private func tiles(_ content: Content) -> some View {
        content.mask {
            GeometryReader { proxy in
                let scale = max(0.86, min(1.1, proxy.size.height / 874))
                let dx = (proxy.size.width - 402) / 2
                let slot = LandingPlace.keystone.frame
                let rect = CGRect(x: slot.minX + dx, y: slot.minY * scale, width: slot.width, height: slot.height)
                Canvas { context, size in
                    // Outside the slot the field fades with the change.
                    let outside = entering ? time : 1 - time
                    var around = Path(CGRect(origin: .zero, size: size))
                    around.addRect(rect)
                    context.fill(around, with: .color(.black.opacity(outside)), style: FillStyle(eoFill: true))
                    let width = rect.width / CGFloat(TileFlipTransition.columns)
                    let height = rect.height / CGFloat(TileFlipTransition.rows)
                    for row in 0 ..< TileFlipTransition.rows {
                        for column in 0 ..< TileFlipTransition.columns {
                            let p = TileFlipTransition.progress(column: column, row: row,
                                                                flip: flip, time: time, entering: entering)
                            // Leaving, the tile turns away; coming back, the page's tile over it turns away.
                            let open = entering ? sin(.pi / 2 * p) : cos(.pi / 2 * p)
                            let tile = height * open
                            context.fill(Path(CGRect(x: rect.minX + CGFloat(column) * width,
                                                     y: rect.minY + CGFloat(row) * height + (height - tile) / 2,
                                                     width: width + 0.5, height: tile)), with: .color(.black))
                        }
                    }
                }
            }
        }
    }
}

/// A room that forces its page's colour scheme (Lookout's plate) wears it inside the shell too.
private struct SchemeOverride: ViewModifier {
    let scheme: ColorScheme?

    func body(content: Content) -> some View {
        if let scheme {
            content.environment(\.colorScheme, scheme)
        } else {
            content
        }
    }
}
