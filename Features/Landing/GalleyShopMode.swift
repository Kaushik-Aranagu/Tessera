import SwiftUI
import TesseraCore

/// Shopping mode (sheet 322): the Galley's landing while the list is being shopped. The rail holds the aisle you are
/// in as a long receipt and tonight's ticket, the sentence place leads with the next thing in the aisle, the dial holds
/// the aisles in store order with the count left in each, the summary is that aisle's list, and the foot does Got, with
/// Not here and Pay (hold) across (Swap, where Tess suggests a close one, is not built yet). Pure: facts in, a `Screen`
/// out.
struct GalleyShopFacts: Equatable {
    struct Item: Equatable, Identifiable {
        let id: String
        /// Already masked: a private item reads "Private item".
        let name: String
        /// "1 gal", "2", nil.
        var amount: String?
        /// Why it is on the list: "You are low", "For the tacos tonight".
        var why: String?

        /// "Milk 1 gal".
        var line: String {
            amount.map { "\(name) \($0)" } ?? name
        }
    }

    struct Aisle: Equatable, Identifiable {
        let name: String
        var items: [Item]

        var id: String {
            name
        }
    }

    var aisles: [Aisle] = []
    /// What is in the basket so far.
    var got = 0
    /// Tonight's dish, short, for the rail's ticket; nil when none is planned.
    var tonight: String?
    var tonightLines: [String] = []

    var left: Int {
        aisles.reduce(0) { $0 + $1.items.count }
    }
}

enum GalleyShopWords {
    /// "7 of 11 to get", "4 aisles to go".
    static func band(_ facts: GalleyShopFacts) -> [String] {
        let total = facts.left + facts.got
        let count = facts.aisles.count
        return [total == 0 ? "Nothing to get" : "\(facts.left) of \(total) to get",
                count == 1 ? "1 aisle to go" : "\(count) aisles to go"]
    }

    /// "Dairy, 2 of 4": the aisle and its place in the walk.
    static func header(_ facts: GalleyShopFacts, aisle index: Int) -> String {
        guard facts.aisles.indices.contains(index) else { return "All got" }
        return "\(facts.aisles[index].name), \(index + 1) of \(facts.aisles.count)"
    }

    /// What comes after the first thing in the aisle.
    static func after(_ aisle: GalleyShopFacts.Aisle) -> String {
        let rest = aisle.items.dropFirst().prefix(2).map(\.name)
        return rest.isEmpty ? "Last in this aisle" : "After it, \(rest.joined(separator: ", ").lowercased())"
    }

    /// Moves an item to the end of its aisle ("Not here").
    static func notHere(_ aisle: GalleyShopFacts.Aisle, item id: String) -> GalleyShopFacts.Aisle {
        guard let index = aisle.items.firstIndex(where: { $0.id == id }) else { return aisle }
        var items = aisle.items
        items.append(items.remove(at: index))
        return GalleyShopFacts.Aisle(name: aisle.name, items: items)
    }
}

struct GalleyShopContent: RoomContent {
    static let room = "galley.shop"
    static let sceneKey = "galley.shop.rail"

    let facts: GalleyShopFacts
    var accent: Color = LandingAccent.kitchen

    func screen(for _: ShellRoute, state: RoomState) -> Screen {
        let focus = facts.aisles.isEmpty ? 0 : min(max(state.dialFocus, 0), facts.aisles.count - 1)
        return Screen(layout: .landing, slots: [
            .title: SlotContent(id: "galley.shop.title", kind: .text, payload: .title("Groceries", accent: accent)),
            .navWord: SlotContent(id: "galley.shop.nav", kind: .text, payload: .navWord("Galley")),
            .needs: SlotContent(id: ContentID("galley.shop.band.\(facts.left).\(facts.aisles.count)"), kind: .text,
                                payload: .lines(GalleyShopWords.band(facts))),
            .keystone: SlotContent(id: ContentID(Self.sceneKey), kind: .scene,
                                   payload: .scene(Self.sceneKey, label: "The shopping rail")),
            .caption: SlotContent(id: "galley.shop.caption", kind: .text,
                                  payload: .lines(["Tap the thing when it is in the basket"])),
            .widget: widget(aisle: focus),
            .dial: facts.aisles.isEmpty ? nil : SlotContent(id: "galley.shop.dial", kind: .dial, payload: .dial(dial)),
            .doorSummary: summary(focus),
            .actionWord: action(aisle: focus),
            .tess: nil,
        ])
    }

    /// The next thing in the aisle, big, with why it is on the list.
    private func widget(aisle index: Int) -> SlotContent? {
        guard facts.aisles.indices.contains(index), let first = facts.aisles[index].items.first else { return nil }
        let aisle = facts.aisles[index]
        let item = WidgetItem(id: "shop.\(first.id)", header: GalleyShopWords.header(facts, aisle: index),
                              big: first.name, middle: first.amount ?? "",
                              small: first.why ?? GalleyShopWords.after(aisle),
                              bigColor: accent, strikeable: false)
        return SlotContent(id: ContentID("galley.shop.widget.\(first.id)"), kind: .widget, payload: .widget([item]))
    }

    private var dial: [DialDoor] {
        facts.aisles.map { DialDoor(id: "aisle.\($0.name)", name: $0.name, count: "\($0.items.count)", color: accent) }
    }

    private func summary(_ index: Int) -> SlotContent? {
        guard facts.aisles.indices.contains(index) else { return nil }
        let aisle = facts.aisles[index]
        let door = DialDoor(
            id: "aisle.\(aisle.name)",
            name: aisle.name,
            color: accent,
            label: "\(aisle.items.count) left",
            lines: aisle.items.prefix(4).map(\.line)
        )
        return SlotContent(id: ContentID("galley.shop.summary.\(aisle.name).\(aisle.items.count)"), kind: .summary,
                           payload: .summary(door))
    }

    /// Got; Not here moves it to the end; Pay (hold) puts everything bought away.
    private func action(aisle index: Int) -> SlotContent {
        let first = facts.aisles.indices.contains(index) ? facts.aisles[index].items.first : nil
        var steps = [ShellStep(id: "got", verb: "Got", object: first?.name ?? "")]
        steps.append(ShellStep(id: "nothere", verb: "Not here", object: ""))
        steps.append(ShellStep(id: "pay", verb: "Pay", object: facts.got == 0 ? "" : "\(facts.got) got", hold: true))
        return SlotContent(id: "galley.shop.action", kind: .action, payload: .action(steps, accent: accent))
    }

    // MARK: The rail

    /// The aisle you are in as a long receipt of what is left in it, then tonight's ticket.
    static func tickets(_ facts: GalleyShopFacts, aisle index: Int) -> [GalleyTicket] {
        var out: [GalleyTicket] = []
        if facts.aisles.indices.contains(index) {
            let aisle = facts.aisles[index]
            out.append(GalleyTicket(id: "shop.aisle", title: aisle.name, sub: "\(aisle.items.count) left",
                                    lines: aisle.items.map(\.line), big: true, ink: .toGet, opens: .groceries))
        }
        if let tonight = facts.tonight {
            out.append(GalleyTicket(id: "shop.tonight", title: "Tonight", sub: tonight,
                                    lines: facts.tonightLines, big: false, ink: .dinner, opens: .recipes))
        }
        return out
    }
}
