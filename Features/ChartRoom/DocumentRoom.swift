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
    /// The small line the Say word carries (it names the place he pointed at).
    var sayObject = DocumentRoom.sayObject
    /// While the history is open the foot reads Close (and Go back while a version is previewed).
    var footSteps: [ShellStep]?

    func screen(for _: ShellRoute, state: RoomState) -> Screen {
        func slot(_ place: Place, _ kind: SlotKind, _ payload: SlotPayload?, id: String? = nil) -> SlotContent? {
            guard let payload else { return nil }
            let ids = (nodes[place] ?? []).map(\.id).joined(separator: ",")
            return SlotContent(id: ContentID(id ?? "chart.\(place.rawValue).\(ids)"), kind: kind, payload: payload,
                               ghost: ghost.contains(place))
        }
        let words = switcherWords
        let windows = needsWindows
        let window = windows.isEmpty ? 0 : ((state.switcherIndex % windows.count) + windows.count) % windows.count
        let needs = windows.isEmpty ? needsLines : windows[window]
        let cards = widgetCards
        let card = cards.isEmpty ? nil : cards[((state.widgetIndex % cards.count) + cards.count) % cards.count]
        let focus = doors.isEmpty ? nil : doors[((state.dialFocus % doors.count) + doors.count) % doors.count]
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
            .switcher: words.isEmpty ? slot(.switcher, .parts, tree(.switcher))
                : slot(.switcher, .switcher, .switcher(across: words, vertical: []), id: "chart.switcher.words"),
            .needs: needs.isEmpty ? nil : slot(.needs, .text, .lines(needs), id: "chart.needs.\(window)"),
            .keystone: slot(.keystone, .parts, tree(.keystone)),
            .caption: caption.isEmpty ? nil : slot(.caption, .text, .lines(caption)),
            .widget: cards.isEmpty ? slot(.widget, .parts, tree(.widget))
                : slot(.widget, .widget, .widget(cards), id: "chart.widget.cards"),
            .glyph: card.map { slot(.glyph, .glyph, .glyph($0, color: accent), id: "chart.glyph.\($0.id)") }
                ?? slot(.glyph, .parts, tree(.glyph)),
            .dial: doors.isEmpty ? nil : slot(.dial, .dial, .dial(doors), id: "chart.dial"),
            .doorSummary: focus.flatMap { door in
                door.label == nil && door.lines.isEmpty ? nil
                    : slot(.doorSummary, .summary, .summary(door), id: "chart.summary.\(door.id)")
            },
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

    /// The Switcher's across words (a `line` part with `words`), pipe-joined in its node.
    private var switcherWords: [String] {
        (nodes[.switcher] ?? []).flatMap { node -> [String] in
            guard case let .line(_, text) = node, text.contains("|") else { return [] }
            return text.split(separator: "|").map(String.init)
        }
    }

    /// The Needs for each Switcher word (a `lines` part with `windows`): each window two pipe-joined lines.
    private var needsWindows: [[String]] {
        (nodes[.needs] ?? []).flatMap { node -> [[String]] in
            guard case let .lines(_, texts) = node, texts.contains(where: { $0.contains("|") }) else { return [] }
            return texts.map { $0.split(separator: "|").map(String.init) }
        }
    }

    /// The widget's items (a `list` part with `cards`): header, big, middle, small and a colour role, pipe-joined.
    private var widgetCards: [WidgetItem] {
        (nodes[.widget] ?? []).flatMap { node -> [WidgetItem] in
            guard case let .lines(id, texts) = node, texts.contains(where: { $0.contains("|") }) else { return [] }
            return texts.enumerated().map { index, text in
                let f = text.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
                func at(_ i: Int) -> String {
                    f.indices.contains(i) ? f[i] : ""
                }
                return WidgetItem(id: "\(id).\(index)", header: at(0), big: at(1), middle: at(2), small: at(3),
                                  bigColor: at(4) == "wine" ? Theme.Colors.Accent.wine : nil, strikeable: false)
            }
        }
    }

    /// The doors (a `doors` part): name, then the summary's label and lines, pipe-joined. A door named `wine`-last
    /// carries the wine.
    private var doors: [DialDoor] {
        (nodes[.dial] ?? []).flatMap { node -> [DialDoor] in
            guard case let .doors(_, names) = node else { return [] }
            return names.enumerated().map { index, record in
                var f = record.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
                let wine = f.last == "wine"
                if wine {
                    f.removeLast()
                }
                return DialDoor(id: "chart.door.\(index)", name: f.first ?? "",
                                color: wine ? Theme.Colors.Accent.wine : accent,
                                label: f.count > 1 ? f[1] : nil, lines: Array(f.dropFirst(2)))
            }
        }
    }

    /// The foot: the room's own action word when it has one (and the grant for what it does), then Say. A
    /// swipe across the word turns to the next.
    private var foot: SlotContent {
        if let footSteps, let first = footSteps.first {
            return SlotContent(id: ContentID("chart.action.history.\(first.id)"), kind: .action,
                               payload: .action(footSteps, accent: accent))
        }
        var steps: [ShellStep] = []
        for node in nodes[.actionWord] ?? [] {
            if case let .actionWord(id, verb, object, _) = node {
                steps.append(ShellStep(id: "does:\(id)", verb: verb, object: object, hold: false))
            }
        }
        steps.append(ShellStep(id: "say", verb: "Say", object: sayObject))
        let first = steps.first?.id ?? "say"
        return SlotContent(id: ContentID("chart.action.\(first)"), kind: .action,
                           payload: .action(steps, accent: accent), ghost: ghost.contains(.actionWord))
    }
}
