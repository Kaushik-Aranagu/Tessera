import Foundation
import TesseraCore

/// The room job (Chart room R1 spec section 2): turns one free sentence into a `patchRoom` call and runs it. The model
/// plans in plain words and then calls the strict tool once. What it is sent: the sentence, the room's parts (kind,
/// place, props, bind; no object values), the kit generated from code, the class catalog (names, fields, kinds), what
/// he last touched within 30 s, and the look traits. While a place is picked, that place's parts come first. Everything
/// may go to Claude except the key (his Oct 27 rule). A plain rejection goes back once; a second is shown to him.
@MainActor
public enum RoomJob {
    public enum Result {
        case applied(OpRecord, PatchRoom.Output)
        /// Tess's words, an offer when the rules allow a nearest thing, or a part queued for the next install.
        case refused(RoomRefusal, queued: OpRecord?)
        /// The model gave no patch.
        case noAnswer
    }

    static let instructions = """
    You change a room he is building by talking, one sentence at a time. Think in plain words first about what he \
    means, which places and parts it touches and what the kit allows, then call patchRoom once. Use only the kit and \
    the look traits listed; name a part by its id; a colour is a role, never a hex. If the kit has no such part, still \
    call patchRoom with the part he named so it can be queued. Lines have no full stop at the end. Never write money.
    """

    /// The class catalog: his own classes by name, their fields and kinds.
    static func classCatalog(_ store: ObjectStore) -> String {
        store.allClasses().filter { $0.systemKey == nil }.sorted { $0.name < $1.name }.map { classDef in
            let fields = ClassResolver.effectiveFields(of: classDef).map { "\($0.key) (\($0.kind.rawValue))" }
            return "- \(classDef.name): " + fields.joined(separator: ", ")
        }.joined(separator: "\n")
    }

    static func traits() -> String {
        var all = RoomPatchValidator.traitValues
        for (name, values) in RoomKit.roomTraits {
            all[name, default: []].formUnion(values)
        }
        return all.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value.sorted().joined(separator: ", "))" }
            .joined(separator: "; ")
    }

    /// The room as the model reads it: parts only, the picked place's first.
    static func roomText(_ document: RoomDocument, picked: String?) -> String {
        let parts = document.parts.sorted { ($0.place == picked ? 0 : 1) < ($1.place == picked ? 0 : 1) }
        let lines = parts.map { part -> String in
            let props = RoomDocument.text(part.props)
            return "- \(part.id): \(part.kind) in \(part.place), props \(props)" +
                (part.bind.map { ", bind \($0)" } ?? "")
        }
        return "Room \(document.name), colour \(document.color), look \(RoomDocument.text(document.look)), "
            + "reach \(document.reach).\n" + (lines.isEmpty ? "No parts yet." : lines.joined(separator: "\n"))
    }

    public static func request(sentence: String, room: String, picked: String? = nil, lastTouched: [String] = [],
                               engine: ActionEngine) -> BrainRequest
    {
        let book = RoomBook(store: engine.store, classes: engine.classes)
        let document = book.room(named: room).map(book.document(of:)) ?? RoomDocument(name: room)
        var context = [
            RoomKit.description,
            "Look traits: " + traits(),
            "Classes:\n" + classCatalog(engine.store),
            roomText(document, picked: picked),
        ]
        if let picked {
            context.append("He has picked the \(picked) place: change only that place.")
        }
        if !lastTouched.isEmpty {
            context.append("He last touched: " + lastTouched.joined(separator: ", "))
        }
        context.append("He said: \(sentence)")
        let tool = TessTools.tool(named: "patchRoom")
        let spec = tool.flatMap { tool in
            (try? JSONSerialization.data(withJSONObject: tool.input.json)).map {
                ToolSpec(name: tool.name, description: tool.description, schema: $0, strict: true)
            }
        }
        return BrainRequest(system: [TextBlock(instructions)],
                            messages: [BrainMessage(.user, text: context.joined(separator: "\n\n"))],
                            tools: spec.map { [$0] } ?? [], toolChoice: .auto, maxTokens: 4096, effort: .low,
                            thinking: true, deadline: .seconds(45))
    }

    /// One round: the patchRoom call the model made, if any, with the whole assistant message to replay.
    static func ask(_ brain: any Brain,
                    _ request: BrainRequest) async -> (call: (id: String, input: Data)?, raw: [Data])
    {
        var call: (id: String, input: Data)?
        var raw: [Data] = []
        do {
            for try await event in brain.stream(request) {
                switch event {
                case let .toolUse(id, name, input) where name == "patchRoom" && call == nil: call = (id, input)
                case let .assistant(blocks): raw = blocks
                default: break
                }
            }
        } catch {
            return (nil, raw)
        }
        return (call, raw)
    }

    static func patch(from input: Data) -> RoomPatch? {
        guard let object = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any],
              let room = object["room"] as? String, let say = object["say"] as? String,
              let steps = try? (object["ops"] as? [[String: Any]] ?? []).map(TessTools.roomStep) else { return nil }
        return RoomPatch(room: room, say: say, ops: steps)
    }

    /// Runs a sentence: asks the model, applies its patch, and on a plain rejection asks once more with the reason.
    public static func run(sentence: String, room: String, picked: String? = nil, lastTouched: [String] = [],
                           brain: any Brain, engine: ActionEngine, pending: Bool = true) async -> Result
    {
        var request = request(sentence: sentence, room: room, picked: picked, lastTouched: lastTouched, engine: engine)
        for attempt in 0 ..< 2 {
            let answer = await ask(brain, request)
            guard let call = answer.call, let patch = patch(from: call.input) else { return .noAnswer }
            guard let outcome = try? RoomPatcher.apply(patch, sentence: sentence, picked: picked, engine: engine,
                                                       pending: pending) else { return .noAnswer }
            switch outcome {
            case let .applied(record, output): return .applied(record, output)
            case let .refused(refusal, queued):
                // A rule with an offer, or a queued part, is Tess's answer. A plain rejection goes back once.
                if attempt == 1 || refusal.offer != nil || refusal.queue != nil {
                    return .refused(refusal, queued: queued)
                }
                request.messages.append(BrainMessage(.assistant, answer.raw.map { .raw($0) }))
                request.messages.append(BrainMessage(.user, [.toolResult(id: call.id, content: refusal.line,
                                                                         isError: true)]))
            }
        }
        return .noAnswer
    }
}
