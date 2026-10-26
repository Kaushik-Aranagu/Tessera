import Foundation
import TesseraCore

/// B4: the one read tool of the Tess loop. `open(handle, depth)` reads an object by a short handle that appeared in the
/// pack (never a UUID): its sentence, and the shown names of what it links to (depth 2 adds their links). Read only,
/// at most 1,200 characters. Under strict, an object of a money, health, body, calorie or calendar class reads
/// "on this phone only"; under lab it reads as it is. A private object reads by its shown label.
@MainActor
public enum TessOpenTool {
    public static let name = "open"
    public static let maxCharacters = 1200

    public static var spec: ToolSpec {
        let schema: [String: Any] = [
            "type": "object", "additionalProperties": false, "required": ["handle", "depth"],
            "properties": [
                "handle": [
                    "type": "string",
                    "description": "A short handle from the pack, like o1, or a path from recall",
                ],
                "depth": [
                    "type": "integer",
                    "enum": [1, 2],
                    "description": "1 reads the object, 2 adds what its links link to",
                ],
            ],
        ]
        return ToolSpec(name: name, description: "Read an object by its handle or its path; read only",
                        schema: (try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys]))
                            ?? Data("{}".utf8))
    }

    /// The text the tool returns. `handles` maps the pack's handles to objects; `index` (the agent's memory slice, M2)
    /// resolves a path from recall. A path outside the slice reads as no object at all.
    public static func run(arguments: Data, handles: [String: UUID], engine: ActionEngine, policy: DoorPolicy,
                           calendar: Calendar = .current, index: MemoryIndex? = nil) -> (text: String, isError: Bool)
    {
        let object = (try? JSONSerialization.jsonObject(with: arguments)) as? [String: Any]
        let handle = object?["handle"] as? String ?? ""
        let entry = handles[handle] == nil ? index?.entry(handle) : nil
        if let entry, entry.kind == .belief {
            // A belief reads as she would say it, with the paths of what shows it.
            let evidence = TessBeliefStore(engine: engine).belief(entry.id)?.evidence ?? []
            let shows = evidence.compactMap { index?.path(of: $0) }
            var text = ([entry.digest] + shows.map { "shown by: \($0)" }).joined(separator: "\n")
            if text.count > maxCharacters {
                text = String(text.prefix(maxCharacters - 1)) + "…"
            }
            return (text, false)
        }
        guard let object, let id = handles[handle] ?? entry?.id,
              let target = engine.store.object(id: id), !target.isDeleted
        else {
            return ("No object has that handle", true)
        }
        let depth = (object["depth"] as? Int) == 2 ? 2 : 1
        func line(_ record: ObjectRecord) -> String {
            let store = engine.store, classes = engine.classes
            if TessAskRouter.isUnnameable(record, classes: classes), policy == .strict {
                return "on this phone only"
            }
            return ObjectPrivacy.shownLabel(of: record, in: store, classes: classes)
                ?? TessAskRouter.shownSentence(record, in: store, classes: classes, calendar: calendar)
                ?? (record.title.isEmpty ? record.classDef?.name ?? "an object" : record.title)
        }
        var out = [line(target)]
        var seen: Set<UUID> = [target.id]
        var frontier = [target]
        for level in 1 ... depth {
            var next: [ObjectRecord] = []
            for record in frontier {
                for link in record.outgoingLinks ?? [] {
                    guard let linked = link.toObject, !linked.isDeleted,
                          seen.insert(linked.id).inserted else { continue }
                    out.append("\(level == 1 ? "links" : "then"): \(line(linked))")
                    next.append(linked)
                }
            }
            frontier = next
        }
        var text = out.joined(separator: "\n")
        if text.count > maxCharacters {
            text = String(text.prefix(maxCharacters - 1)) + "…"
        }
        return (text, false)
    }
}
