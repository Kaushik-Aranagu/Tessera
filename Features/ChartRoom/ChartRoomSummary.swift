import SwiftUI

/// What Bridge's apps dial reads from the Chart room (sheet 365): nothing about the room is hard-coded there. Before he
/// names it the row says "Chart room" in slate with "Say what it's for"; once named it carries the room's own name and
/// colour, with its live top fact on the right ("Orchid, 6 days"). Pure over a document.
enum ChartRoomSummary {
    static let unnamed = "Chart room"
    static let unnamedLine = "Say what it's for"

    /// The Theme colour of a colour role (never a hex in a room's document).
    static func color(_ role: String) -> Color {
        switch role {
        case "olive": Theme.Colors.Accent.lists
        case "wine": Theme.Colors.Accent.wine
        case "ink": Theme.Colors.ink
        case "inkSoft": Theme.Colors.inkSecondary
        case "notes", "violet": Theme.Colors.Accent.notes
        case "sage": Theme.Colors.Accent.money
        case "ochre": Theme.Colors.Accent.kitchen
        case "cobalt": Theme.Colors.Accent.training
        case "dusk": Theme.Colors.Accent.routines
        case "rain": Theme.Colors.Accent.rain
        default: Theme.Colors.Accent.chart
        }
    }

    /// The room's own name: its title part's words, once it has one.
    static func name(_ doc: ChartDoc) -> String {
        for part in doc.parts where part.kind == .title {
            if let text = part.props.text("text"), !text.isEmpty {
                return PartText.shown(text)
            }
        }
        return unnamed
    }

    /// The live top fact, from the `top` part's bound query: "Orchid, 6 days". Nil when the room has none.
    @MainActor
    static func fact(_ doc: ChartDoc, data: RoomData = DemoRoomData()) -> String? {
        guard let modifier = doc.parts.first(where: { $0.kind == .top }),
              let target = modifier.props.text("on").flatMap({ doc.part($0) }), let bind = target.bind,
              let top = PartResolver.topItem(in: doc, bind: bind, data: { data.items($0) })
        else { return nil }
        let days = Int(PartResolver.value(top, modifier.props.text("field") ?? ""))
        return "\(top.name), \(days) \(days == 1 ? "day" : "days")"
    }

    /// The dial's row: name, colour and right-hand line, read from the stored room.
    @MainActor
    static func row(defaults: UserDefaults = .standard) -> (name: String, color: Color, line: String) {
        guard let json = defaults.string(forKey: ChartRoomModel.defaultsKey), let doc = try? ChartDoc.decode(json),
              name(doc) != unnamed
        else { return (unnamed, color("slate"), unnamedLine) }
        return (name(doc), color(doc.color), fact(doc) ?? "")
    }
}

extension ChartRoomSummary {
    /// A taken-down room has no row in the dial (the dial's rows are the rooms that are up).
    static func isUp(defaults: UserDefaults = .standard) -> Bool {
        !defaults.bool(forKey: ChartRoomModel.archivedKey)
    }
}
