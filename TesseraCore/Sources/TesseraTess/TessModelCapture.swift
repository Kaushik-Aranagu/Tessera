import Foundation
import FoundationModels
import TesseraCore

/// The on-device model step: a short Tess session whose tools are generated from the action registry.
/// Every tool call runs the real typed action as Tess (pending by default), so the model can only do what the
/// UI can do, validation included, and everything it does shows as a ghost row with undo.
@MainActor
public final class TessModelCapture: TessModelCapturing {
    private let model: SystemLanguageModel

    public init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    public var isAvailable: Bool {
        model.isAvailable
    }

    public func capture(_ phrase: String, context: TessContext, engine: ActionEngine) async -> TessCapture {
        let recorder = TessToolRecorder()
        let grammar = TessGrammar(store: engine.store, classes: engine.classes)
        let tools = TessToolCatalog.descriptors.map { descriptor in
            RegistryTool(descriptor: descriptor, engine: engine, grammar: grammar,
                         pending: !context.commitImmediately, recorder: recorder)
        }
        let session = LanguageModelSession(
            model: model,
            tools: tools,
            instructions: TessVoice.instructions(
                today: Self.today(context), currentWorkout: Self.workout(context, engine: engine),
                lastSet: Self.lastSet(context, engine: engine)
            )
        )
        do {
            let response = try await session.respond(to: phrase)
            let line = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            // Never claim an action that wasn't called: with no tool call, the line can't say "done".
            if recorder.records.isEmpty {
                return TessCapture(records: [], line: TessVoice.violations(in: line).isEmpty && !line.isEmpty
                    ? line : "Didn't catch that.", source: .none)
            }
            let safe = TessVoice.violations(in: line).isEmpty && !line.isEmpty
            return TessCapture(records: recorder.records, line: safe ? line : recorder.records.last?.summary ?? "",
                               source: .model)
        } catch {
            // Roll back anything a failed session started.
            for record in recorder.records where record.state == .pending {
                try? engine.discard(record)
            }
            return TessCapture(records: [], line: "Didn't catch that.", source: .none)
        }
    }

    static func today(_ context: TessContext) -> String {
        let formatter = DateFormatter()
        formatter.calendar = context.calendar
        formatter.timeZone = context.calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE d MMMM yyyy, HH:mm"
        return "today is \(formatter.string(from: context.now))"
    }

    static func workout(_ context: TessContext, engine: ActionEngine) -> String {
        guard let entry = context.entry.flatMap({ engine.store.object(id: $0) }),
              let exercise = engine.store.linkedClass("exercise", of: entry) else { return "no workout in focus" }
        return "current exercise \(exercise.name)"
    }

    static func lastSet(_ context: TessContext, engine: ActionEngine) -> String {
        let store = engine.store
        guard let entry = context.entry.flatMap({ store.object(id: $0) }),
              let set = entry.orderedChildren.last,
              let weight = store.number("weight", of: set), let reps = store.number("reps", of: set)
        else { return "no last set" }
        return "last set \(TessVoice.number(weight)) kg x \(TessVoice.number(reps))"
    }
}

/// Which registry actions the model may call: ones whose arguments it can fill from words alone
/// (no object ids), and nothing destructive.
public enum TessToolCatalog {
    public static var descriptors: [ActionDescriptor] {
        ActionRegistry.descriptors.filter { descriptor in
            !descriptor.isDestructive && descriptor.parameters.allSatisfy { $0.kind != .object && $0.kind != .json }
                && !descriptor.name.hasSuffix("Process")
        }
    }
}

/// Collects what the model's tool calls actually did.
@MainActor
final class TessToolRecorder {
    var records: [OpRecord] = []
}

/// One registry action as a Foundation Models tool, with a schema generated from its descriptor.
struct RegistryTool: Tool {
    typealias Arguments = GeneratedContent

    let name: String
    let description: String
    let parameters: GenerationSchema
    private let descriptor: ActionDescriptor
    private let engine: ActionEngine
    private let grammar: TessGrammar
    private let pending: Bool
    private let recorder: TessToolRecorder

    @MainActor
    init(descriptor: ActionDescriptor, engine: ActionEngine, grammar: TessGrammar, pending: Bool,
         recorder: TessToolRecorder)
    {
        name = descriptor.name
        description = descriptor.summary
        self.descriptor = descriptor
        self.engine = engine
        self.grammar = grammar
        self.pending = pending
        self.recorder = recorder
        parameters = (try? Self.schema(for: descriptor)) ?? GenerationSchema(
            type: GeneratedContent.self, description: descriptor.summary, properties: []
        )
    }

    /// Ids aren't something a model can know, so class references are asked for by name and resolved here.
    static func schema(for descriptor: ActionDescriptor) throws -> GenerationSchema {
        let properties = descriptor.parameters.map { parameter -> DynamicGenerationSchema.Property in
            let schema = switch parameter.kind {
            case .number: DynamicGenerationSchema(type: Double.self)
            case .integer: DynamicGenerationSchema(type: Int.self)
            case .boolean: DynamicGenerationSchema(type: Bool.self)
            case .string, .date, .classRef, .object, .json: DynamicGenerationSchema(type: String.self)
            }
            let hint = switch parameter.kind {
            case .date: " (ISO 8601 date-time)"
            case .classRef: " (its name, e.g. Bench Press)"
            default: ""
            }
            return DynamicGenerationSchema.Property(
                name: parameter.name, description: parameter.summary + hint, schema: schema,
                isOptional: !parameter.isRequired
            )
        }
        let root = DynamicGenerationSchema(name: descriptor.name, description: descriptor.summary,
                                           properties: properties)
        return try GenerationSchema(root: root, dependencies: [])
    }

    func call(arguments: GeneratedContent) async throws -> String {
        let json = arguments.jsonString
        return await MainActor.run { perform(json) }
    }

    @MainActor
    private func perform(_ json: String) -> String {
        guard var object = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any] else {
            return "Error: unreadable arguments"
        }
        for parameter in descriptor.parameters where parameter.kind == .classRef {
            guard let name = object[parameter.name] as? String else { continue }
            guard let classDef = grammar.resolveExercise(name) else {
                return "Error: no exercise called \(name)"
            }
            object[parameter.name] = classDef.id.uuidString
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: object)
            let record = try engine.perform(named: name, arguments: data, by: .tess, pending: pending)
            recorder.records.append(record)
            return "Done: \(record.summary)"
        } catch {
            return "Error: \(error)"
        }
    }
}
