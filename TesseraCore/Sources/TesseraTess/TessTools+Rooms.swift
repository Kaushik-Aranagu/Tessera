import Foundation
import TesseraCore

/// The strict `patchRoom` tool (Chart room R1 spec section 2): one sentence's change to a room, as ops on named parts.
/// Every field is required so the schema stays strict and small (an empty string or -1 means "not given", which keeps
/// the union count down); `props` carries a JSON object as text, since a strict schema cannot hold free keys. The
/// validator runs inside the action, and a refusal comes back to the model as the error line, once: the second
/// refusal is shown to him.
@MainActor
extension TessTools {
    static var patchRoom: Tool {
        let step = TessSchema.object([
            ("op", .choice(["add", "set", "remove", "move", "look", "grant"], "What to do to the room")),
            ("id", .string("The part's id, for add, set, remove and move; empty otherwise")),
            ("kind", .string("The kind of part for add, as said; empty otherwise")),
            ("place", .string("The place for add and move; empty otherwise")),
            ("props", .string("The part's props as one JSON object, e.g. {\"text\":\"Plants\"}; empty for none")),
            ("bind", .string("The class whose objects the part shows, e.g. Plant; empty for none")),
            ("trait", .string("For look: the trait, or color; empty otherwise")),
            ("value", .string("For look: its value; empty otherwise")),
            ("reach", .string("For grant: what the room may do, e.g. write Plant.lastWatered; empty otherwise")),
            ("index", .integer("For move: where in the place, from 0; -1 otherwise")),
        ])
        return Tool(
            name: "patchRoom",
            description: "Change the Chart room he talks to: add, set, remove or move its parts, change its look, "
                + "or ask for what it may do. Plan in plain words first, then call this once.",
            input: .object([("room", .string("The room's name, e.g. Chart room")),
                            ("say", .string("What to say when it is set, no full stop, e.g. Plants, set")),
                            ("ops", .array(step))])
        ) { args, call in
            let room = try args.string("room")
            let say = try args.string("say")
            let steps = try (args["ops"] as? [[String: Any]] ?? []).map(Self.roomStep)
            guard !steps.isEmpty else { throw TessToolError("ops is empty") }
            let patch = RoomPatch(room: room, say: say, ops: steps)
            switch try RoomPatcher.apply(patch, sentence: say, engine: call.engine, pending: call.pending) {
            case let .applied(record, _):
                return [record]
            case let .refused(refusal, queued):
                if let queued {
                    return [queued]
                }
                // The line goes back to the model for one retry; Tess shows the second.
                throw TessToolError(refusal.line)
            }
        }
    }

    static func roomStep(_ raw: [String: Any]) throws -> RoomPatch.Step {
        func text(_ key: String) -> String? {
            let value = (raw[key] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
            return value.isEmpty ? nil : value
        }
        guard let op = text("op") else { throw TessToolError("op is missing") }
        var props: [String: RawJSON]?
        if let json = text("props") {
            guard let decoded = try? JSONDecoder().decode([String: RawJSON].self, from: Data(json.utf8)) else {
                throw TessToolError("props isn't a JSON object")
            }
            props = decoded
        }
        let index = (raw["index"] as? Int) ?? (raw["index"] as? Double).map { Int($0) }
        return RoomPatch.Step(op: op, id: text("id"), kind: text("kind"), place: text("place"), props: props,
                              bind: text("bind"), trait: text("trait"), value: text("value"), reach: text("reach"),
                              index: (index ?? -1) >= 0 ? index : nil)
    }
}
