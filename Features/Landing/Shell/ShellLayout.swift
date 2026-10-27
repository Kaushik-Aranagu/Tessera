import CoreGraphics
import SwiftUI

/// Where each place sits in each layout (sheet 283 v4 frames, `LandingPlace`), the merge table of v5, and the pure
/// rules the shell plays a change by. No views here, so the tests read it directly.
enum ShellLayout {
    /// The level 1 places and the level 0 places they are made from (sheet 283 v5).
    static let merges: [Place: [Place]] = [
        .doorTitle: [.switcher, .needs],
        .page: [.widget, .glyph, .dial, .doorSummary],
    ]

    /// The breaths the Page also takes in: below the widget (612) and above the foot (760).
    static let pageBreaths: [LandingPlace] = [.breathBelowWidget, .breathAboveFoot]

    /// Places that exist in a layout. The rest are kept, empty and touch-free, at their merge partner's rect.
    static func places(in layout: LayoutKind) -> Set<Place> {
        switch layout {
        case .landing:
            [.title, .navWord, .switcher, .needs, .keystone, .caption, .widget, .glyph, .dial, .doorSummary,
             .actionWord, .tess]
        case .door:
            [.title, .navWord, .doorTitle, .keystone, .caption, .page, .actionWord, .tess]
        case .bridge:
            // Bridge (sheet 283 v4): the Settings word holds the Title's place, the Departure board the Switcher's;
            // the apps dial takes the whole doors band; the foot holds the undo line. The Nav word, Caption and
            // Glyph are kept and empty there.
            [.title, .navWord, .switcher, .keystone, .caption, .widget, .glyph, .dial, .actionWord, .tess]
        }
    }

    /// Where a place that is not in a layout waits there: the place it merged into, or (on Bridge) the place that
    /// folds it in. A change spreads it out of that place's rect, or flows it into it.
    static func partner(_ place: Place, in layout: LayoutKind) -> Place? {
        switch layout {
        case .landing:
            nil
        case .door:
            target(of: place)
        case .bridge:
            switch place {
            case .needs, .doorTitle: .switcher
            case .doorSummary: .dial
            case .page: .widget
            default: nil
            }
        }
    }

    /// A place's frame in a layout where it exists.
    static func layoutFrame(_ place: Place, in layout: LayoutKind) -> CGRect {
        guard layout == .bridge else { return ownFrame(place) }
        switch place {
        case .title: return LandingPlace.Masthead.settingsWord
        case .switcher: return LandingPlace.Masthead.departureBoard
        case .dial: return LandingPlace.doors.frame
        default: return ownFrame(place)
        }
    }

    /// Gap kept between the last row's room and the action word (Design sheets 288 and 291: no text crosses another
    /// element's frame, in any look or Dynamic Type size).
    static let pageFootGap: CGFloat = 10

    /// The action word's slot height at a Dynamic Type size: the verb line (24 pt, 32 line) over the object line
    /// (13 pt, 18 line), both scaled, never less than the design frame. The word grows upward from its bottom edge.
    static func actionSlotHeight(typeSize: DynamicTypeSize) -> CGFloat {
        let size = min(typeSize, .accessibility2)
        return max(Foot.designHeight, (32 * titleScale(size)).rounded(.up) + (18 * captionScale(size)).rounded(.up))
    }

    private typealias Foot = LandingPlace.Foot

    /// Title 2 and Caption 1 scale factors by size, close to UIFontMetrics' curve.
    private static func titleScale(_ size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall: 0.86
        case .small: 0.93
        case .medium: 0.96
        case .large: 1
        case .xLarge: 1.07
        case .xxLarge: 1.14
        case .xxxLarge: 1.21
        case .accessibility1: 1.32
        default: 1.5
        }
    }

    private static func captionScale(_ size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall: 0.92
        case .small: 0.96
        case .medium: 0.98
        case .large: 1
        case .xLarge: 1.08
        case .xxLarge: 1.17
        case .xxxLarge: 1.25
        case .accessibility1: 1.4
        default: 1.6
        }
    }

    /// A place's rect on screen (x not centred): its layout frame, y scaled to the screen's height. The action word
    /// grows up from its bottom edge with Dynamic Type, and the Page's viewport stops above whatever the word needs,
    /// so rows always end above it.
    static func screenRect(_ place: Place, in layout: LayoutKind, scale: CGFloat,
                           typeSize: DynamicTypeSize) -> CGRect
    {
        var rect = frame(place, in: layout)
        rect.origin.y *= scale
        switch place {
        case .actionWord:
            let slot = actionSlotHeight(typeSize: typeSize)
            rect.origin.y += rect.height - slot
            rect.size.height = slot
        case .page:
            let word = screenRect(.actionWord, in: layout, scale: scale, typeSize: typeSize)
            rect.size.height = max(0, min(rect.height, word.minY - pageFootGap - rect.minY))
        default:
            break
        }
        return rect
    }

    static func exists(_ place: Place, in layout: LayoutKind) -> Bool {
        places(in: layout).contains(place)
    }

    /// The merge target a level 0 place flows into, if any.
    static func target(of source: Place) -> Place? {
        merges.first { $0.value.contains(source) }?.key
    }

    /// The place's own frame on the 402 x 874 design screen (landing frames from `LandingPlace`).
    static func ownFrame(_ place: Place) -> CGRect {
        switch place {
        case .title: LandingPlace.Masthead.title
        case .navWord: LandingPlace.Masthead.navWord
        case .switcher: LandingPlace.Masthead.switcher
        case .needs: LandingPlace.Masthead.needs
        case .keystone: LandingPlace.keystone.frame
        case .caption: LandingPlace.caption.frame
        case .widget: LandingPlace.widget.frame
        case .glyph: LandingPlace.Widget.glyph
        case .dial: LandingPlace.Doors.dial
        case .doorSummary: LandingPlace.Doors.summary
        case .actionWord: LandingPlace.Foot.actionWord
        case .tess: LandingPlace.Foot.tess
        case .doorTitle, .page: mergedFrame(place)
        }
    }

    /// A merge target's rect: the Door title's v7 frame, or the Page: the union of its sources and the two breaths.
    static func mergedFrame(_ target: Place) -> CGRect {
        // Sheet 283 v7 sets the Door title at 24, 106, 354 by 70 (inside the union of the Switcher and Needs).
        if target == .doorTitle {
            return CGRect(x: 24, y: 106, width: 354, height: 70)
        }
        var rect = (merges[target] ?? []).map(ownFrame).reduce(CGRect.null) { $0.union($1) }
        if target == .page {
            for breath in pageBreaths {
                rect = rect.union(breath.frame)
            }
        }
        return rect
    }

    /// Where a place sits in a layout: its own frame when it exists there; a source merged away sits in its
    /// target's rect (so a split spreads out from it).
    static func frame(_ place: Place, in layout: LayoutKind) -> CGRect {
        if exists(place, in: layout) {
            return layoutFrame(place, in: layout)
        }
        if let partner = partner(place, in: layout), exists(partner, in: layout) {
            return layoutFrame(partner, in: layout)
        }
        if let target = target(of: place) {
            return mergedFrame(target)
        }
        return ownFrame(place)
    }

    /// How a place travels when the layout changes.
    enum Travel: Equatable {
        /// In both layouts: glides from the old frame to the new one (no move when they are equal).
        case glide
        /// A source flowing into its target's rect and fading as the target appears.
        case merge(into: Place)
        /// A source spreading from the merged place's rect to its own frame.
        case split(from: Place)
        /// The merge target forming where its sources met (fades in) or giving way to them (fades out).
        case form
        case dissolve
        /// In neither layout.
        case absent
    }

    static func travel(_ place: Place, from old: LayoutKind, to new: LayoutKind) -> Travel {
        let before = exists(place, in: old)
        let after = exists(place, in: new)
        switch (before, after) {
        case (true, true): return .glide
        case (false, false): return .absent
        case (true, false):
            if let partner = partner(place, in: new), exists(partner, in: new) {
                return .merge(into: partner)
            }
            return merges[place] != nil ? .form : .dissolve
        case (false, true):
            if let partner = partner(place, in: old), exists(partner, in: old) {
                return .split(from: partner)
            }
            return merges[place] != nil ? .form : .dissolve
        }
    }
}

/// What a place does with its content on a change (the per-place diff rules of the contract).
enum PlaceMove: Equatable {
    /// Same id on both sides: nothing plays. (The keystone stays when a door opens.)
    case untouched
    /// Same kind, new id: the place's own move.
    case move
    /// Different kind: the old content collapses to a point and the new one forms from it.
    case collapseAndForm
    /// Nothing to content: only the arriving half plays.
    case enter
    /// Content to nothing: only the leaving half plays.
    case leave
    /// Nothing on either side.
    case none

    static func diff(_ old: SlotContent?, _ new: SlotContent?) -> PlaceMove {
        switch (old, new) {
        case (nil, nil): .none
        case (nil, .some): .enter
        case (.some, nil): .leave
        case let (.some(before), .some(after)):
            if before.id == after.id {
                .untouched
            } else if before.kind == after.kind {
                .move
            } else {
                .collapseAndForm
            }
        }
    }

    /// The moves of every place between two screens.
    static func plan(from old: Screen?, to new: Screen) -> [Place: PlaceMove] {
        var moves: [Place: PlaceMove] = [:]
        for place in Place.allCases {
            moves[place] = diff(old?[place], new[place])
        }
        return moves
    }
}

/// The one clock of a change (sheet 283 v4/v5). Seconds from the change's start; the whole change ends within 1 s.
enum ShellTiming {
    static let whole = 0.98
    static let reducedFade = 0.15
    /// Merge: content leaves first, the places flow, the target's content arrives after.
    static let contentOut = 0.15
    static let travelStart = 0.15
    static let travel = 0.42
    static let mergeArrive = 0.47
    /// Split: the sources' content arrives once the places have spread.
    static let splitArrive = 0.52
    /// Arrivals after a split, in place order, this far apart.
    static let arriveStagger = 0.03
    static let arriveSeconds = 0.3
    /// Door page rows settle in from the top down.
    static let rowStagger = 0.03
    static let rowSeconds = 0.3
    static let rowsShown = 6
    /// The dial reel, the longest move.
    static let reel = 0.98
    /// The door summary comes in as the reel slows (v4 says 640 ms; 560 keeps the change inside 1 s).
    static let summaryDelay = 0.56
    /// The opening: places in order, 80 ms apart, 0.5 s each.
    static let openingStagger = 0.08
    static let openingSeconds = 0.5

    /// When a place's entry has finished, so it takes touches again.
    static func entryEnd(_ place: Place, move: PlaceMove, merging: Bool, splitting: Bool) -> Double {
        switch move {
        case .untouched, .none: return 0
        case .leave: return merging || splitting ? contentOut : 0.26
        default: break
        }
        if merging, ShellLayout.merges[place] != nil {
            return min(whole, mergeArrive + Double(rowsShown) * rowStagger + rowSeconds)
        }
        if splitting, ShellLayout.target(of: place) != nil {
            return min(whole, splitArrive + Double(arrivalOrder(place)) * arriveStagger + arriveSeconds)
        }
        switch place {
        case .dial: return reel
        case .doorSummary: return summaryDelay + 0.42
        case .actionWord: return 0.42 + 0.46
        case .caption: return 0.52 + 0.32
        case .widget: return 0.2 + 0.42
        case .glyph: return 0.33 + 0.44
        default: return 0.18 + 0.34 + 0.06
        }
    }

    /// The order places arrive in after a split or at the opening.
    static func arrivalOrder(_ place: Place) -> Int {
        switch place {
        case .title, .navWord, .switcher, .needs, .doorTitle: 0
        case .keystone: 1
        case .caption: 2
        case .widget, .glyph, .page: 3
        case .dial: 4
        case .doorSummary: 5
        case .actionWord, .tess: 6
        }
    }
}
