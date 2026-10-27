import SwiftUI

/// The Chart room as content for the standing shell (R1 spec section 6): a `RoomContent` that answers
/// `screen(for:state:)` from a document's parts, so the shell, its moves and back work unchanged. Parts that fit an
/// existing `SlotPayload` use it (title, caption, needs, doors, the action word); free compositions use the one new
/// `SlotKind.parts`. Pure: no views, no store reads; the caller resolves binds and passes the nodes.
struct DocumentRoom: RoomContent {
    static let room = "chart"

    /// The places the blank frame outlines (sheet 357), in reading order, with the name each carries.
    static let outlined: [(place: Place, name: String)] = [
        (.title, "Title"), (.switcher, "Line"), (.keystone, "Keystone"), (.caption, "Caption"), (.widget, "Widget"),
        (.dial, "Doors"),
    ]

    /// What the foot says before the room has a word of its own (on the phone; the board shows the next sentence).
    static let sayObject = "what to build"

    let nodes: [Place: [PartNode]]
    /// The places a pending patch fills: drawn at 38% until it sets.
    var ghost: Set<Place> = []
    var accent: Color = Theme.Colors.Accent.chart

    func screen(for _: ShellRoute, state _: RoomState) -> Screen {
        func slot(_ place: Place, _ kind: SlotKind, _ payload: SlotPayload?, id: String? = nil) -> SlotContent? {
            guard let payload else { return nil }
            let ids = (nodes[place] ?? []).map(\.id).joined(separator: ",")
            return SlotContent(id: ContentID(id ?? "chart.\(place.rawValue).\(ids)"), kind: kind, payload: payload,
                               ghost: ghost.contains(place))
        }
        let needs = needsLines
        func tree(_ place: Place) -> SlotPayload? {
            guard let list = nodes[place], !list.isEmpty else { return nil }
            // The Line runs the whole 354 pt unless the Needs beside it has words.
            return .parts(PartTree(nodes: list, accent: accent, width: place == .switcher && needs.isEmpty ? 354 : nil))
        }
        let title = nodes[.title]?.compactMap { node -> String? in
            if case let .title(_, text) = node {
                text
            } else {
                nil
            }
        }.first
        let caption = captionLines
        return Screen(layout: .landing, slots: [
            .title: title.flatMap { text in
                slot(.title, .text, .title(text, accent: accent))
            },
            .navWord: SlotContent(id: "chart.nav.bridge", kind: .text, payload: .navWord("Bridge")),
            .switcher: slot(.switcher, .parts, tree(.switcher)),
            .needs: needs.isEmpty ? nil : slot(.needs, .text, .lines(needs)),
            .keystone: slot(.keystone, .parts, tree(.keystone)),
            .caption: caption.isEmpty ? nil : slot(.caption, .text, .lines(caption)),
            .widget: slot(.widget, .parts, tree(.widget)),
            .glyph: slot(.glyph, .parts, tree(.glyph)),
            .dial: doors.isEmpty ? nil : slot(.dial, .dial, .dial(doors)),
            .doorSummary: nil,
            .actionWord: foot,
            .tess: nil,
        ])
    }

    // MARK: Words

    private var captionLines: [String] {
        (nodes[.caption] ?? []).flatMap { node -> [String] in
            switch node {
            case let .line(_, text): [text]
            case let .lines(_, texts): texts
            default: []
            }
        }
    }

    private var needsLines: [String] {
        (nodes[.needs] ?? []).flatMap { node -> [String] in
            if case let .lines(_, texts) = node {
                texts
            } else {
                []
            }
        }
    }

    private var doors: [DialDoor] {
        (nodes[.dial] ?? []).flatMap { node -> [DialDoor] in
            guard case let .doors(_, names) = node else { return [] }
            return names.enumerated().map { index, name in
                DialDoor(id: "chart.door.\(index)", name: name, color: index == 0 ? accent : Theme.Colors.ink)
            }
        }
    }

    /// The foot: the room's own action word when it has one (and the grant for what it does), then Say. A
    /// swipe across the word turns to the next.
    private var foot: SlotContent {
        var steps: [ShellStep] = []
        for node in nodes[.actionWord] ?? [] {
            if case let .actionWord(id, verb, object, _) = node {
                steps.append(ShellStep(id: "does:\(id)", verb: verb, object: object, hold: false))
            }
        }
        steps.append(ShellStep(id: "say", verb: "Say", object: Self.sayObject))
        let first = steps.first?.id ?? "say"
        return SlotContent(id: ContentID("chart.action.\(first)"), kind: .action,
                           payload: .action(steps, accent: accent), ghost: ghost.contains(.actionWord))
    }
}
