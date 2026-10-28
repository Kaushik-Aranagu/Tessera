import Foundation
import TesseraCore

/// The room's one action word writes one field of one object: a date to now. A real op, so the history, Undo and the
/// op log hold it like any other change (the room's reach decides whether it may be offered at all).
struct RoomWriteField: EngineAction {
    static let descriptor = ActionDescriptor(
        name: "roomWriteField", summary: "A room's action word writes one field",
        parameters: [.init("object", .object, "the object"), .init("key", .string, "the field")],
        isOfferedToModel: false
    )

    var object: UUID
    var key: String

    @MainActor func apply(_ transaction: inout Transaction) throws {
        guard let record = transaction.store.object(id: object) else { return }
        try transaction.set(key, to: .date(transaction.now), on: record)
    }

    @MainActor func summary(in store: ObjectStore) -> String {
        "Wrote \(store.object(id: object)?.title ?? "an object")"
    }

    @MainActor func receipt(in store: ObjectStore) -> String? {
        store.object(id: object).map { "\($0.title), watered" }
    }
}

/// What the room's binds read from the real store, through Core's `RoomBind` (private objects already read "Private").
/// A date field also reads as `daysSince(key)`, so a sort or a `top` ranks by how long ago.
@MainActor
final class EngineRoomData: RoomData {
    let engine: ActionEngine

    init(engine: ActionEngine) {
        self.engine = engine
    }

    private var bind: RoomBind {
        RoomBind(store: engine.store, classes: engine.classes)
    }

    func items(_ query: String) -> [BoundItem] {
        let part = RoomPart(id: "bind", kind: "row", place: "", props: ["max": .number(24)], bind: query)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: AppClock.now)
        return bind.rows(for: part).map { row in
            var fields: [String: Double] = [:]
            for (key, value) in row.values {
                switch value {
                case let .number(number): fields[key] = number
                case let .date(date):
                    let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: today).day ?? 0
                    fields["daysSince(\(key))"] = Double(max(0, days))
                default: break
                }
            }
            return BoundItem(name: row.title, fields: fields, isPrivate: row.title == "Private")
        }
    }

    func write(_ does: String, to item: String) -> (() -> Void)? {
        let words = does.split(separator: " ")
        guard words.count == 2, words[0] == "write" else { return nil }
        let target = words[1].split(separator: ".").map(String.init)
        guard target.count == 2, let classDef = bind.classDef(for: target[0]),
              let object = engine.store.objects(of: classDef).first(where: { $0.title == item }),
              let record = try? engine.perform(RoomWriteField(object: object.id, key: target[1]), by: .user).record
        else { return nil }
        return { [engine] in engine.undo(record) }
    }
}
