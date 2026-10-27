import Foundation
import TesseraCore

extension TessTools {
    /// `rehearse(calls)`: Tess tries her own tools on a copy of his store and reads what would happen. It writes
    /// nothing and is never offered to Claude (what it returns can hold money, body and private values; the Door
    /// reads a rehearsal through `Rehearsal.Result.fragments` instead). It counts as a round, not as a ghost.
    static var rehearse: Tool {
        Tool(name: "rehearse", description: "Try changes on a hidden copy first and read what would happen",
             input: .object([("calls", .array(.object([
                 ("name", .string("The tool to try")),
                 ("arguments", .string("Its arguments as JSON text")),
             ]))), ("expecting", .nullable(.integer("How many things the ask says will change, if it says")))]),
             deviceOnly: true)
        { args, call in
            guard let list = args["calls"] as? [[String: Any]], !list.isEmpty else {
                throw TessToolError("calls is missing")
            }
            let calls = list.compactMap { entry -> Rehearsal.Call? in
                guard let name = entry["name"] as? String else { return nil }
                return Rehearsal.Call(name: name, json: entry["arguments"] as? String ?? "{}")
            }
            let rehearsal = Rehearsal(engine: call.engine)
            let result = rehearsal.try(calls, expecting: args["expecting"] as? Int)
            throw TessToolAnswer(line: result.text)
        }
    }
}
