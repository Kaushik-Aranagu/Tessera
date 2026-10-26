// swiftlint:disable identifier_name cyclomatic_complexity
import CoreGraphics
import Foundation

// Layout mode's data (Design 283 v4 map, v7 and v8): every place of the 402 x 874 phone, its frame on each level, and
// the plan of how panes flow into each other when the room or the level changes. Pure values: no views, so the frames
// are pinned by unit tests (4 pt seams, 24 pt margins). A debug surface only.

/// The two levels a room has: its landing and a door page (Bridge has one).
enum LayoutLevel: Equatable {
    case landing, door
}

/// One place on the screen. `key` is stable across rooms ("Breath@612" tells the three breaths apart).
struct LayoutPlace: Identifiable, Equatable {
    enum Kind: Equatable {
        /// The frosted plate the masthead's panes sit on.
        case plate
        /// A pane of glass.
        case pane
        /// A measured gap, never a pane.
        case breath
    }

    let name: String
    let frame: CGRect
    let kind: Kind

    var id: String {
        key
    }

    var key: String {
        kind == .breath ? "Breath@\(Int(frame.minY))" : name
    }

    /// Short stable word for accessibility identifiers: "door-summary".
    var slug: String {
        key.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "@", with: "-")
    }

    var isGap: Bool {
        kind == .breath
    }

    var isPlate: Bool {
        kind == .plate
    }

    /// The pane's rect: 2 pt in from the place's frame on every side, so every seam reads as a 4 pt gap, except where
    /// the contract's frames sit 4 pt apart already (Switcher's right and Needs' left take 0 pt) or 2 pt apart (the Door
    /// summary's right and the Dial's left take 1 pt; the dial is on the right since Oct 26). Design 283: frames stay as
    /// the contract has them, the insets differ.
    var paneFrame: CGRect {
        let inset = LayoutPlaces.inset
        var left = inset, right = inset
        switch name {
        case "Switcher": right = 0
        case "Needs": left = 0
        case "Dial": left = 1
        case "Door summary": right = 1
        default: break
        }
        return CGRect(x: frame.minX + left, y: frame.minY + inset,
                      width: frame.width - left - right, height: frame.height - 2 * inset)
    }

    /// Radius: min(22, max(10, 0.3 of the shorter side)) of the place's own frame.
    var radius: CGFloat {
        min(22, max(10, min(frame.width, frame.height) * 0.3))
    }

    /// True for the places on the lower half (the card docks over the keystone for these).
    var isLow: Bool {
        frame.midY > 440
    }
}

enum LayoutPlaces {
    static let phone = CGSize(width: 402, height: 874)
    static let inset: CGFloat = 2
    static let margin: CGFloat = 24

    /// The Bridge-only places that fold into the room's Title, Switcher, Needs and Nav word.
    static let bridgeOnly = ["Settings word", "Departure board"]

    private static func pane(_ name: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> LayoutPlace {
        LayoutPlace(name: name, frame: CGRect(x: x, y: y, width: w, height: h), kind: .pane)
    }

    private static func breath(_ y: CGFloat, _ h: CGFloat) -> LayoutPlace {
        LayoutPlace(name: "Breath", frame: CGRect(x: 24, y: y, width: 354, height: h), kind: .breath)
    }

    private static let plate = LayoutPlace(name: "Masthead", frame: CGRect(x: 0, y: 44, width: 402, height: 138),
                                           kind: .plate)

    /// Landing, in a room: the v4 map.
    private static let roomLanding: [LayoutPlace] = [
        plate,
        pane("Title", 24, 50, 260, 48), pane("Nav word", 300, 50, 94, 46),
        pane("Switcher", 24, 106, 200, 76), pane("Needs", 228, 118, 150, 58),
        breath(182, 14),
        pane("Keystone", 24, 196, 354, 182), pane("Caption", 24, 378, 354, 34),
        pane("Widget", 24, 412, 354, 200), pane("Glyph", 298, 444, 80, 80),
        breath(612, 28),
        pane("Dial", 218, 640, 160, 120), pane("Door summary", 24, 640, 192, 120),
        breath(760, 16),
        pane("Action word", 24, 786, 220, 62), pane("Tess", 306, 776, 96, 96),
    ]

    /// Bridge: the Settings word and the Departure board stand where the room's Title, Switcher, Needs and Nav word
    /// are.
    private static let bridgeLanding: [LayoutPlace] = roomLanding.filter {
        !["Title", "Nav word", "Switcher", "Needs"].contains($0.name)
    }.flatMap { place -> [LayoutPlace] in
        place.name == "Masthead"
            ? [place, pane("Settings word", 24, 74, 110, 44), pane("Departure board", 140, 74, 238, 104)]
            : [place]
    }

    /// A door page (level 1): Switcher + Needs are the Door title; Widget, Glyph, the breaths at 612 and 760, Dial and
    /// Door summary are the Page.
    private static let door: [LayoutPlace] = [
        plate,
        pane("Title", 24, 50, 260, 48), pane("Nav word", 300, 50, 94, 46),
        pane("Door title", 24, 106, 354, 70),
        breath(182, 14),
        pane("Keystone", 24, 196, 354, 182), pane("Caption", 24, 378, 354, 34),
        pane("Page", 24, 412, 354, 364),
        pane("Action word", 24, 786, 220, 62), pane("Tess", 306, 776, 96, 96),
    ]

    static func places(_ room: LayoutRoom, _ level: LayoutLevel) -> [LayoutPlace] {
        if room == .bridge {
            return bridgeLanding
        }
        return level == .door ? door : roomLanding
    }

    /// Which places a merged or folded place is made from (and the reverse, for a split).
    static let made: [String: [String]] = [
        "Door title": ["Switcher", "Needs"],
        "Page": ["Widget", "Glyph", "Breath@612", "Dial", "Door summary", "Breath@760"],
        "Title": ["Settings word"],
        "Switcher": ["Departure board"],
        "Needs": ["Departure board"],
        "Nav word": ["Departure board"],
    ]

    static func place(named name: String, in room: LayoutRoom, _ level: LayoutLevel) -> LayoutPlace? {
        places(room, level).first { $0.name == name }
    }
}

// MARK: - The liquid plan

/// A pane that flows from one rect to another during a change: merging, splitting, or folding to a dot.
struct LiquidTrack: Equatable {
    let from: CGRect
    let to: CGRect
    /// Stagger by distance, in ms (0 to 160).
    let delay: Double
    /// Fades out as it flows (a place with no partner in the new layout).
    let gone: Bool
}

/// What a change does: which panes stay still, which set again after the liquid, which tracks flow.
struct LayoutChange: Equatable {
    var tracks: [LiquidTrack] = []
    /// Keys whose place has the very same frame on both sides: they only take the new tint.
    var steady: Set<String> = []
    /// New or reshaped keys, in order: hidden under the liquid, then set into glass (300 ms blur-in).
    var settle: [String] = []
    /// Old places that leave (fade 160 ms).
    var leaving: [String] = []

    /// Total clock for the liquid pass: 720 ms damped spring plus the longest stagger.
    static let springMs: Double = 720
    var total: Double {
        (tracks.map(\.delay).max() ?? 0) + Self.springMs
    }

    var isLiquid: Bool {
        !tracks.isEmpty
    }

    /// Ported from the board's `change()`: a pane that changes shape becomes a blob that flows to its new frame.
    static func plan(from old: [LayoutPlace], to new: [LayoutPlace]) -> LayoutChange {
        var change = LayoutChange()
        let oldByKey = Dictionary(old.map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first })
        let newKeys = Set(new.map(\.key))

        func delay(_ a: CGRect, _ b: CGRect) -> Double {
            min(160, abs(a.minY - b.minY) * 0.25 + Double((Int(a.minX) + Int(a.minY)) % 7) * 6)
        }
        func track(_ a: CGRect, _ b: CGRect, gone: Bool = false) {
            change.tracks.append(LiquidTrack(from: a, to: b,
                                             delay: delay(a, b), gone: gone))
        }

        for place in new {
            if let before = oldByKey[place.key], before.frame == place.frame {
                change.steady.insert(place.key)
                continue
            }
            change.settle.append(place.key)
            if place.isPlate || place.isGap {
                continue
            }
            if let before = oldByKey[place.key] {
                track(before.paneFrame, place.paneFrame)
                continue
            }
            let sources = (LayoutPlaces.made[place.key] ?? []).compactMap { oldByKey[$0] }
            if !sources.isEmpty {
                for source in sources {
                    track(source.paneFrame, place.paneFrame)
                }
                continue
            }
            let bigger = old.filter {
                (LayoutPlaces.made[$0.key] ?? []).contains(place.key) && !newKeys.contains($0.key)
            }
            if !bigger.isEmpty {
                for source in bigger {
                    track(source.paneFrame, place.paneFrame)
                }
                continue
            }
            let dot = CGRect(x: place.frame.midX - 6, y: place.frame.midY - 6, width: 12, height: 12)
            track(dot, place.paneFrame)
        }

        for place in old {
            if change.steady.contains(place.key) {
                continue
            }
            let related = new.contains {
                (LayoutPlaces.made[$0.key] ?? []).contains(place.key)
                    || (LayoutPlaces.made[place.key] ?? []).contains($0.key) || $0.key == place.key
            }
            if !place.isGap, !place.isPlate, !related {
                let dot = CGRect(x: place.frame.midX - 4, y: place.frame.midY - 4, width: 8, height: 8)
                track(place.paneFrame, dot, gone: true)
            }
            change.leaving.append(place.key)
        }
        return change
    }

    /// The damped spring the liquid uses, 0 at the start and 1 at rest, overshooting on the way.
    static func spring(_ t: Double) -> Double {
        if t <= 0 {
            return 0
        }
        if t >= 1 {
            return 1
        }
        return 1 - exp(-6.5 * t) * cos(7.2 * t)
    }

    /// A track's rect at clock `ms`.
    func rect(_ track: LiquidTrack, at ms: Double) -> CGRect {
        let s = Self.spring((ms - track.delay) / Self.springMs)
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
            a + (b - a) * s
        }
        return CGRect(x: mix(track.from.minX, track.to.minX), y: mix(track.from.minY, track.to.minY),
                      width: max(2, mix(track.from.width, track.to.width)),
                      height: max(2, mix(track.from.height, track.to.height)))
    }
}
