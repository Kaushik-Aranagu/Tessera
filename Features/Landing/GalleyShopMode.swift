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
        /// Already in the basket from this aisle, for the struck rows.
        var got: [Item] = []

        var id: String {
            name
        }
    }

    var aisles: [Aisle] = []
    /// What is in the basket so far.
    var got = 0
    /// Tonight's dish, short, for the rail's ticket; nil when none is planned.
    var tonight: String?
    /// The things on the list for tonight's dish, with the ones already in the basket struck off (by index).
    var tonightLines: [String] = []
    var tonightGot: Set<Int> = []

    var left: Int {
        aisles.reduce(0) { $0 + $1.items.count }
    }
}

/// Shopping mode's whole screen as data (sheet 328): the aisle and where it is, the thing at 64 pt with its amount, why
/// it is on the list and a tip on how to pick it, the aisle's list with dotted leaders (got ones struck), and what is
/// after this. Pure, so it tests.
struct GalleyShopScreen: Equatable {
    struct Line: Equatable, Identifiable {
        let id: String
        let name: String
        let amount: String?
        let struck: Bool
    }

    var aisle = ""
    var spot: String?
    /// Top right: what is left, and tonight's things.
    var topRight = ""
    var thing = ""
    var amount: String?
    var why: String?
    var tip: String?
    var inAisle: [Line] = []
    /// "Dairy, along the back wall".
    var after: String?
    var verb = "Got"
    var object = ""
    var rail: [GalleyRailItem] = []
    var empty = true

    init(_ facts: GalleyShopFacts, aisle index: Int) {
        let total = facts.left + facts.got
        var top = total == 0 ? "Nothing to get" : "\(facts.left) of \(total) to get"
        if facts.tonight != nil, !facts.tonightLines.isEmpty {
            top += ", tonight \(facts.tonightGot.count) of \(facts.tonightLines.count)"
        }
        topRight = top
        rail = facts.aisles.enumerated().map { offset, aisle in
            GalleyRailItem(id: offset, label: aisle.name, detail: "\(aisle.items.count)", current: offset == index)
        }
        guard facts.aisles.indices.contains(index), let first = facts.aisles[index].items.first else { return }
        empty = false
        let current = facts.aisles[index]
        aisle = current.name
        spot = GalleyCues.aisleSpot(current.name)
        thing = GalleyCookWords.capital(first.name)
        amount = first.amount
        why = first.why
        tip = GalleyCues.pick(first.name)
        object = GalleyCookWords.capital(first.name)
        inAisle = (current.items.map { Line(id: $0.id, name: $0.name, amount: $0.amount, struck: false) }
            + current.got.map { Line(id: $0.id, name: $0.name, amount: $0.amount, struck: true) })
        if facts.aisles.indices.contains(index + 1) {
            let next = facts.aisles[index + 1]
            after = [next.name, GalleyCues.aisleSpot(next.name)?.lowercased()].compactMap(\.self)
                .joined(separator: ", ")
        }
    }
}
