import Foundation
import TesseraCore

extension ChartRoomModel {
    /// The board's four sentences as Core patches (sheet 357; spec section 2: in Demo, and with "Tess asks Claude"
    /// Off, the four sentences map to canned patches so the room still demonstrates). Free sentences wait for Core's
    /// `patchRoom` job. Core's own `RoomPatch`, so the same patch goes through the engine when a store is attached.
    static let canned: [(heard: String, patch: RoomPatch)] = [
        ("Make this my plant room", RoomPatch(room: "Chart room", say: "Plants, set", ops: [
            .init(op: "add", id: "title", kind: "title", place: "title", props: ["text": .string("Plants")]),
            .init(op: "add", id: "line", kind: "line", place: "switcher",
                  props: ["text": .string("{count} plants, the {top} is thirsty")], bind: "Plant"),
            .init(op: "look", trait: "density", value: "airy"),
        ])),
        ("Put them on the keystone by when I last watered", RoomPatch(room: "Chart room", say: "Keystone, set", ops: [
            .init(op: "add", id: "row", kind: "row", place: "keystone",
                  props: ["big": .string("daysSince(lastWatered)"), "small": .string("title"),
                          "sort": .string("-daysSince(lastWatered)"), "max": .number(4)], bind: "Plant"),
            .init(op: "add", id: "cap", kind: "line", place: "caption",
                  props: ["text": .string("Days since water")], bind: "Plant"),
        ])),
        ("Glow the thirstiest one", RoomPatch(room: "Chart room", say: "Glow, set", ops: [
            .init(op: "add", id: "top", kind: "top", place: "keystone",
                  props: ["on": .string("row"), "field": .string("lastWatered")]),
            .init(op: "set", id: "cap", props: ["text": .string("Days since water, the {top} first")]),
        ])),
        ("Let me mark one watered", RoomPatch(room: "Chart room", say: "Watered, set", ops: [
            .init(op: "grant", reach: "write Plant.lastWatered"),
            .init(op: "add", id: "water", kind: "actionWord", place: "actionWord",
                  props: ["verb": .string("Watered"), "object": .string("the {top}"),
                          "does": .string("write Plant.lastWatered")], bind: "Plant"),
        ])),
        ("Under the title, show what's thirsty, what's due this week, and light", RoomPatch(
            room: "Chart room", say: "Line, set", ops: [
                .init(
                    op: "set",
                    id: "line",
                    props: ["words": .array(["Thirsty", "This week", "Light"].map { .string($0) })]
                ),
                .init(op: "add", id: "need", kind: "lines", place: "needs", props: ["windows": .array([
                    .string("Orchid, 6 days|Monstera, 4 days"), .string("Repot the basil|Feed the fern Friday"),
                    .string("Orchid by the window|Fern in the shade"),
                ])]),
            ]
        )),
        ("Put the thirstiest plant in the widget with how to water it", RoomPatch(
            room: "Chart room", say: "Widget, set", ops: [
                .init(op: "add", id: "next", kind: "list", place: "widget", props: ["cards": .array([
                    .string("Thirstiest|Orchid|Last watered Wednesday|Ice cubes, not a pour|wine"),
                ])]),
            ]
        )),
        ("Then the monstera, then the basil, which needs repotting", RoomPatch(
            room: "Chart room", say: "Widget, three", ops: [
                .init(op: "set", id: "next", props: ["cards": .array([
                    .string("Thirstiest|Orchid|Last watered Wednesday|Ice cubes, not a pour|wine"),
                    .string("Next|Monstera|Last watered Friday|When the top inch is dry"),
                    .string("Repot|Basil|Roots out of the bottom|The 6 inch pot is on the shelf"),
                ])]),
            ]
        )),
        ("Use the watering can for the first two", RoomPatch(
            room: "Chart room", say: "Glyphs, set", ops: [.init(op: "look", trait: "glyph", value: "can")]
        )),
        ("A door for each plant, with when I last watered it", RoomPatch(
            room: "Chart room", say: "Doors, set", ops: [
                .init(op: "add", id: "doors", kind: "doors", place: "dial", props: ["doors": .array([
                    .string("Orchid|Last watered Wednesday|wine"), .string("Monstera|Last watered Friday"),
                    .string("Fern|Last watered Sunday"), .string("Basil|Last watered yesterday"),
                ])]),
            ]
        )),
        ("Say how often and where each one sits", RoomPatch(
            room: "Chart room", say: "Doors, filled in", ops: [
                .init(op: "set", id: "doors", props: ["doors": .array([
                    .string(
                        "Orchid|Last watered Wednesday|Water every 7 days|By the east window|Ice cubes, not a pour|wine"
                    ),
                    .string("Monstera|Last watered Friday|Water every 5 days|By the couch|When the top inch is dry"),
                    .string("Fern|Last watered Sunday|Water every 3 days|In the bathroom|Keep it out of the sun"),
                    .string(
                        "Basil|Last watered yesterday|Water every 2 days|On the kitchen sill|Pinch the flowers off"
                    ),
                ])]),
            ]
        )),
        ("Keep a Say word to change things", RoomPatch(
            room: "Chart room", say: "Say, kept", ops: [.init(op: "look", trait: "say", value: "kept")]
        )),
        ("Make it teal", RoomPatch(
            room: "Chart room", say: "Colour, set", ops: [.init(op: "look", trait: "color", value: "olive")]
        )),
    ]
}
