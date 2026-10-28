import Foundation
@testable import TesseraCore

/// R1's 20-sentence eval (spec section 7): Design's twelve board sentences (sheet 359) plus eight more covering colors,
/// order, density, doors and an action word. Each has the room it starts from, the shape a right answer has, and a
/// golden patch (what a correct model says) that the offline test checks against the validator and the shape.
@MainActor
enum RoomEvalCorpus {
    struct Shape: Equatable {
        var op: String
        var kind: String?
        var place: String?
        var trait: String?
    }

    struct Case {
        var sentence: String
        /// Parts the starting room lacks (so the sentence has something to add).
        var without: [String] = []
        var blank = false
        var expect: [Shape]
        var golden: [RoomPatch.Step]
    }

    static func add(_ id: String, _ kind: String, _ place: String, _ props: [String: RawJSON] = [:],
                    bind: String? = nil) -> RoomPatch.Step
    {
        RoomPatch.Step(op: "add", id: id, kind: kind, place: place, props: props, bind: bind)
    }

    static func look(_ trait: String, _ value: String) -> RoomPatch.Step {
        RoomPatch.Step(op: "look", trait: trait, value: value)
    }

    static func start(_ item: Case) -> RoomDocument {
        if item.blank {
            return RoomDocument(name: "Chart room")
        }
        var document = RoomFixture.chart
        document.parts.removeAll { item.without.contains($0.id) }
        if item.without.contains("water") {
            document.reach = []
        }
        return document
    }

    static let cases: [Case] = [
        Case(sentence: "Make this my plant room", blank: true,
             expect: [Shape(op: "add", kind: "title", place: "title")],
             golden: [add("title", "title", "title", ["text": .string("Plants")])]),
        Case(sentence: "Put them on the keystone by when I last watered", without: ["row", "both", "top"],
             expect: [Shape(op: "add", kind: "row", place: "keystone")],
             golden: [add("row", "row", "keystone", ["big": .string("waterEvery"), "small": .string("title"),
                                                     "sort": .string("-daysSince(lastWatered)"), "max": .number(4)],
                          bind: "Plant")]),
        Case(sentence: "Glow the thirstiest one", without: ["top"], expect: [Shape(op: "add", kind: "top")],
             golden: [add("top", "top", "widget", ["on": .string("row"), "field": .string("lastWatered")])]),
        Case(sentence: "Let me mark one watered", without: ["water"],
             expect: [Shape(op: "grant"), Shape(op: "add", kind: "actionWord", place: "actionWord")],
             golden: [RoomPatch.Step(op: "grant", reach: "write Plant.lastWatered"),
                      add("water", "actionWord", "actionWord", ["verb": .string("Watered"),
                                                                "does": .string("write Plant.lastWatered")],
                          bind: "Plant")]),
        Case(sentence: "Under the title, show what's thirsty, what's due this week, and light", without: ["need"],
             expect: [Shape(op: "add", kind: "lines", place: "needs")],
             golden: [add("need", "lines", "needs",
                          ["lines": .array([.string("Thirsty first"), .string("Due this week")])])]),
        Case(sentence: "Put the thirstiest plant in the widget with how to water it", without: ["next", "both"],
             expect: [Shape(op: "add", kind: "list", place: "widget")],
             golden: [add("next", "list", "widget", ["big": .string("waterEvery"), "small": .string("title"),
                                                     "sort": .string("-daysSince(lastWatered)"), "max": .number(1)],
                          bind: "Plant")]),
        Case(sentence: "Then the monstera, then the basil, which needs repotting", expect: [Shape(op: "set")],
             golden: [RoomPatch.Step(op: "set", id: "list", props: ["max": .number(3)])]),
        Case(sentence: "Use the watering can for the first two", expect: [Shape(op: "look", trait: "glyph")],
             golden: [look("glyph", "can")]),
        Case(sentence: "A door for each plant, with when I last watered it", without: ["doors"],
             expect: [Shape(op: "add", kind: "doors", place: "dial")],
             golden: [add("doors", "doors", "dial", ["summary": .string("lastWatered")], bind: "Plant")]),
        Case(sentence: "Say how often and where each one sits", expect: [Shape(op: "set")],
             golden: [RoomPatch.Step(op: "set", id: "doors", props: ["summary": .string("waterEvery")])]),
        Case(sentence: "Keep a Say word to change things", expect: [Shape(op: "look", trait: "say")],
             golden: [look("say", "kept")]),
        Case(sentence: "Make it teal", expect: [Shape(op: "look", trait: "color")], golden: [look("color", "olive")]),
        Case(sentence: "Make this calmer", expect: [Shape(op: "look", trait: "motion")],
             golden: [look("motion", "calm")]),
        Case(sentence: "Give it more room", expect: [Shape(op: "look", trait: "density")],
             golden: [look("density", "airy")]),
        Case(sentence: "Sort the list by how long since I watered", expect: [Shape(op: "set")],
             golden: [RoomPatch.Step(op: "set", id: "list", props: ["sort": .string("-daysSince(lastWatered)")])]),
        Case(sentence: "Move the list to the widget", expect: [Shape(op: "move")],
             golden: [RoomPatch.Step(op: "move", id: "list", place: "widget", index: 0)]),
        Case(sentence: "Take the glyph off", expect: [Shape(op: "remove")],
             golden: [RoomPatch.Step(op: "remove", id: "leaf")]),
        Case(sentence: "Show how many plants I have", without: ["days", "pair"],
             expect: [Shape(op: "add", kind: "number", place: "keystone")],
             golden: [add("days", "number", "keystone", ["label": .string("plants"), "agg": .string("count")],
                          bind: "Plant")]),
        Case(sentence: "A leaf at the top left", without: ["leaf"],
             expect: [Shape(op: "add", kind: "glyph", place: "glyph")],
             golden: [add("leaf", "glyph", "glyph", ["symbol": .string("leaf"), "color": .string("sage")])]),
        Case(sentence: "Stop moving", expect: [Shape(op: "look", trait: "motion")], golden: [look("motion", "still")]),
    ]

    /// Whether a patch has every shape the case expects (an unset field is a don't-care).
    static func matches(_ patch: RoomPatch, _ item: Case) -> Bool {
        item.expect.allSatisfy { shape in
            patch.ops.contains { step in
                guard step.op == shape.op else { return false }
                if let kind = shape.kind, step.kind.flatMap({ RoomKit.kind($0)?.name }) != kind {
                    return false
                }
                if let place = shape.place, step.place != place {
                    return false
                }
                if let trait = shape.trait, step.trait != trait {
                    return false
                }
                return true
            }
        }
    }
}
