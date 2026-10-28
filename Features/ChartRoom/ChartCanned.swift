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
    ]
}
