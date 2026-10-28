import Foundation
import TesseraCore

// The seam between Core's room types (`RoomDocument`, `RoomPatch`, written by `patchRoom` through the engine) and the
// player's own value types (`ChartDoc`, `ChartPatch`), which add what drawing needs. Everything Core stores reads in
// through here, so Core's fixture and its objects drive the player with no other change.

extension PropValue {
    init?(_ raw: RawJSON) {
        switch raw {
        case let .string(value): self = .text(value)
        case let .number(value): self = .number(value)
        case let .bool(value): self = .flag(value)
        case let .array(values):
            // A list of texts, or a list of {name, bind} objects (a doors part): its names.
            self = .texts(values.compactMap { value in
                switch value {
                case let .string(text): text
                case let .object(object): if case let .string(name)? = object["name"] {
                        name
                    } else {
                        nil
                    }
                default: nil
                }
            })
        default: return nil
        }
    }

    var raw: RawJSON {
        switch self {
        case let .text(value): .string(value)
        case let .number(value): .number(value)
        case let .flag(value): .bool(value)
        case let .texts(values): .array(values.map { .string($0) })
        }
    }
}

extension ChartPart {
    init?(_ part: RoomPart) {
        guard let kind = PartKind(rawValue: part.kind) else { return nil }
        var props: PartProps = [:]
        for (key, value) in part.props {
            props[key] = PropValue(value)
        }
        self.init(id: part.id, kind: kind, place: part.place, props: props, bind: part.bind)
    }
}

extension ChartDoc {
    init(_ room: RoomDocument) {
        self.init(name: room.name, color: room.color, look: room.look, reach: room.reach,
                  parts: room.parts.compactMap(ChartPart.init))
    }
}

extension ChartPatch {
    init(_ patch: RoomPatch, heard: String = "") {
        let ops = patch.ops.compactMap { step -> PatchOp? in
            var props: PartProps = [:]
            for (key, value) in step.props ?? [:] {
                props[key] = PropValue(value)
            }
            switch step.op {
            case "add":
                guard let id = step.id, let kind = step.kind.flatMap(PartKind.init) else { return nil }
                return .add(ChartPart(id: id, kind: kind, place: step.place ?? "", props: props, bind: step.bind))
            case "set": return step.id.map { .set(id: $0, props: props, bind: step.bind) }
            case "remove": return step.id.map { .remove(id: $0) }
            case "move":
                guard let id = step.id, let place = step.place else { return nil }
                return .move(id: id, place: place, index: step.index)
            case "look":
                guard let trait = step.trait, let value = step.value else { return nil }
                return .look(trait: trait, value: value)
            case "grant": return step.reach.map { .grant($0) }
            default: return nil
            }
        }
        self.init(room: patch.room, say: patch.say, ops: ops, heard: heard)
    }
}

extension ChartPart {
    /// The part as Core reads it (props back to raw JSON).
    var core: RoomPart {
        RoomPart(id: id, kind: kind.rawValue, place: place, props: props.mapValues(\.raw), bind: bind)
    }
}
