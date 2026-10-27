import Foundation

/// How a feature's UI is driven. Every live piece of UI (a keystone, the Lookout sky, a mosaic face) declares one
/// of these once. The data under it always updates; only the drawing is gated.
enum LiveMode: String, CaseIterable, Sendable {
    /// Draws and animates, but only while he can see it (scene active, on the visible page, not covered).
    case uiRead
    /// Never draws live. Data only. The still it shows is made from the current data when it appears.
    case backgroundOnly
}

/// The developer switch over a declared mode. `auto` follows the declaration.
enum LiveSwitch: String, CaseIterable, Sendable {
    /// Follow the feature's declared mode.
    case auto
    /// Old behaviour: live whether or not it is seen. Exists so a before/after can run on one build.
    case alwaysLive
    /// Force data only.
    case dataOnly
    /// Quiet (sheet 286): still draws on change while seen, but has no idle loop. One switch for a keystone's Quiet
    /// setting and for "stop animating the sky".
    case quiet
}

/// What a feature costs while live, so the meter and the spec can rank them.
enum LiveCost: Sendable, Equatable {
    case frames(perSecond: Int)
    case periodic(seconds: Int)
    case still
}

/// One declared live feature. `id` is the stable key for the switch, the meter and the element contract.
struct LiveFeature: Identifiable, Hashable, Sendable {
    enum Owner: String, Sendable { case builderA, builderB, core }

    let id: String
    let title: String
    let owner: Owner
    let mode: LiveMode
    let cost: LiveCost

    static func == (lhs: LiveFeature, rhs: LiveFeature) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// The pure rule. No SwiftUI, so it tests without a view.
enum LiveGate {
    struct Inputs: Equatable, Sendable {
        /// The scene is `.active`.
        var sceneActive: Bool
        /// The region is on screen (appeared and not scrolled or paged away).
        var visible: Bool
        /// Every enclosing `liveScope` is on (the page is current, nothing covers it).
        var scopeOn: Bool
    }

    static func isLive(mode: LiveMode, switchState: LiveSwitch, inputs: Inputs) -> Bool {
        switch switchState {
        case .alwaysLive: true
        case .dataOnly: false
        case .auto:
            seen(mode: mode, inputs: inputs)
        case .quiet:
            seen(mode: mode, inputs: inputs)
        }
    }

    /// Idle loops (a drifting sky, a breathing glyph) run only when live and not Quiet. Change-driven moves ignore
    /// this.
    static func runsIdle(live: Bool, switchState: LiveSwitch) -> Bool {
        live && switchState != .quiet
    }

    private static func seen(mode: LiveMode, inputs: Inputs) -> Bool {
        mode == .uiRead && inputs.sceneActive && inputs.visible && inputs.scopeOn
    }
}

/// What a keystone drew, as id to a short fingerprint (ticket ids and texts, tile faces, chalk lines).
typealias LiveSnapshot = [String: String]

/// What changed while a region was away (sheet 286, section 4).
struct LiveDiff: Equatable, Sendable {
    var added: [String]
    var changed: [String]
    var removed: [String]

    var count: Int {
        added.count + changed.count + removed.count
    }

    var isEmpty: Bool {
        count == 0
    }

    /// What actually plays. Removed things are simply gone.
    var playable: [String] {
        added + changed
    }
}

enum LiveReturn: Equatable, Sendable {
    /// Show the current state, nothing plays.
    case showNow
    /// Show the current state, then after `delay` play `diff` once within `window`.
    case play(diff: LiveDiff, delay: TimeInterval, window: TimeInterval)

    static let settle: TimeInterval = 0.65
    static let window: TimeInterval = 0.6
    static let maxChanges = 6
    static let maxAway: TimeInterval = 3600

    /// Order is stable: ids sorted, so a keystone can stagger in reading order by sorting its own ids.
    static func diff(seen: LiveSnapshot, now: LiveSnapshot) -> LiveDiff {
        LiveDiff(
            added: now.keys.filter { seen[$0] == nil }.sorted(),
            changed: now.keys.filter { seen[$0] != nil && seen[$0] != now[$0] }.sorted(),
            removed: seen.keys.filter { now[$0] == nil }.sorted()
        )
    }

    /// More than six changes, or more than an hour away, is just "show now". No replay of missed motion, ever.
    static func plan(seen: LiveSnapshot, now: LiveSnapshot, away: TimeInterval) -> LiveReturn {
        let diff = diff(seen: seen, now: now)
        if diff.playable.isEmpty || diff.count > maxChanges || away > maxAway {
            return .showNow
        }
        return .play(diff: diff, delay: settle, window: window)
    }
}

/// Every feature that draws live. Add a row here when a feature starts animating; the owner then wraps its view in
/// `.liveRegion(_:)` and drives its clock with `LiveTimeline`.
enum LiveFeatures {
    static let deckChalk = LiveFeature(id: "keystone.deck.chalk", title: "Deck blackboard", owner: .builderA,
                                       mode: .uiRead, cost: .frames(perSecond: 15))
    static let galleyRail = LiveFeature(id: "keystone.galley.rail", title: "Galley ticket rail", owner: .builderB,
                                        mode: .uiRead, cost: .periodic(seconds: 30))
    static let purseChart = LiveFeature(id: "keystone.purse.chart", title: "Purse index chart", owner: .builderB,
                                        mode: .uiRead, cost: .still)
    static let watchWoodland = LiveFeature(id: "keystone.watch.woodland", title: "Watch woodland", owner: .builderB,
                                           mode: .uiRead, cost: .frames(perSecond: 30))
    static let lookoutSky = LiveFeature(id: "keystone.lookout.sky", title: "Lookout sky and glass", owner: .builderA,
                                        mode: .uiRead, cost: .frames(perSecond: 60))
    static let mosaicHome = LiveFeature(id: "home.mosaic", title: "Bridge mosaic", owner: .builderB,
                                        mode: .uiRead, cost: .frames(perSecond: 30))
    static let landingGlyph = LiveFeature(id: "landing.glyph", title: "Landing glyph", owner: .builderA,
                                          mode: .uiRead, cost: .frames(perSecond: 20))
    static let tessSoul = LiveFeature(id: "tess.soul", title: "Tess soul", owner: .builderA,
                                      mode: .uiRead, cost: .frames(perSecond: 30))

    static let lookoutHandover = LiveFeature(id: "keystone.lookout.handover", title: "Lookout drop hand-over",
                                             owner: .builderA, mode: .uiRead, cost: .frames(perSecond: 60))
    static let wallHandover = LiveFeature(id: "keystone.wall.handover", title: "Wall chalk-dust hand-over",
                                          owner: .builderA, mode: .uiRead, cost: .frames(perSecond: 60))
    static let watchHandover = LiveFeature(id: "keystone.watch.handover", title: "Watch bird and petals hand-over",
                                           owner: .builderA, mode: .uiRead, cost: .frames(perSecond: 60))
    static let thinking = LiveFeature(id: "tess.thinking", title: "Tess thinking glyph", owner: .builderA,
                                      mode: .uiRead, cost: .frames(perSecond: 60))
    static let tessGlint = LiveFeature(id: "tess.glint", title: "Tess glint sheen", owner: .builderA, mode: .uiRead,
                                       cost: .frames(perSecond: 30))
    static let tessRoundRobin = LiveFeature(
        id: "tess.roundrobin",
        title: "Tess working bars",
        owner: .builderA,
        mode: .uiRead,
        cost: .frames(perSecond: 30)
    )
    static let processSeam = LiveFeature(
        id: "machined.seam",
        title: "Process seam glint",
        owner: .builderA,
        mode: .uiRead,
        cost: .frames(perSecond: 60)
    )
    static let inkDrops = LiveFeature(
        id: "setmark.inkdrops",
        title: "Set-mark ink drops",
        owner: .builderA,
        mode: .uiRead,
        cost: .frames(perSecond: 60)
    )
    static let groundSky = LiveFeature(id: "theme.groundsky", title: "Ground sky mesh", owner: .builderA, mode: .uiRead,
                                       cost: .frames(perSecond: 15))
    static let driftWash = LiveFeature(
        id: "paint.driftwash",
        title: "Ground drifting wash",
        owner: .builderA,
        mode: .uiRead,
        cost: .still
    )
    static let soulBreath = LiveFeature(id: "tess.breath", title: "Tess soul breath", owner: .builderA, mode: .uiRead,
                                        cost: .frames(perSecond: 60))
    static let doorway = LiveFeature(id: "home.doorway", title: "Pixel doorway", owner: .builderA, mode: .uiRead,
                                     cost: .frames(perSecond: 60))
    static let tessConversation = LiveFeature(
        id: "tess.conversation",
        title: "Tess conversation arrival",
        owner: .builderA,
        mode: .uiRead,
        cost: .frames(perSecond: 60)
    )
    static let exerciseStrip = LiveFeature(
        id: "workout.strip",
        title: "Workout exercise strip glint",
        owner: .builderA,
        mode: .uiRead,
        cost: .frames(perSecond: 60)
    )
    static let workoutSetMarks = LiveFeature(
        id: "workout.setmarks",
        title: "Workout set marks",
        owner: .builderA,
        mode: .uiRead,
        cost: .frames(perSecond: 60)
    )
    static let swapPanel = LiveFeature(
        id: "workout.swap",
        title: "Workout swap breath",
        owner: .builderA,
        mode: .uiRead,
        cost: .frames(perSecond: 20)
    )
    static let weatherWords = LiveFeature(id: "home.weatherwords", title: "Weather word effects", owner: .builderB,
                                          mode: .uiRead, cost: .frames(perSecond: 30))

    static let all: [LiveFeature] = [
        deckChalk, galleyRail, purseChart, watchWoodland, lookoutSky, mosaicHome, landingGlyph, tessSoul,
        lookoutHandover, wallHandover, watchHandover, thinking,
        tessGlint, tessRoundRobin, processSeam, inkDrops, groundSky, driftWash, soulBreath, doorway, tessConversation,
        exerciseStrip, workoutSetMarks, swapPanel, weatherWords,
    ]
}
