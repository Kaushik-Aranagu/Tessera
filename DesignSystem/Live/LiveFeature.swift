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
            switch mode {
            case .backgroundOnly: false
            case .uiRead: inputs.sceneActive && inputs.visible && inputs.scopeOn
            }
        }
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

    static let all: [LiveFeature] = [
        deckChalk, galleyRail, purseChart, watchWoodland, lookoutSky, mosaicHome, landingGlyph, tessSoul,
    ]
}
