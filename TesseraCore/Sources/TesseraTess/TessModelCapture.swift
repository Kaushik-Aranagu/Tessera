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
        // The same tools Claude gets (TessTools), converted to the on-device schema.
        let tools = TessTools.all.map { tool in
            CatalogTool(tool: tool, engine: engine, pending: !context.commitImmediately, now: context.now,
                        recorder: recorder)
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

/// Collects what the model's tool calls actually did.
@MainActor
final class TessToolRecorder {
    var records: [OpRecord] = []
}

/// One TessTools tool as a Foundation Models tool.
struct CatalogTool: Tool {
    typealias Arguments = GeneratedContent

    let name: String
    let description: String
    let parameters: GenerationSchema
    private let engine: ActionEngine
    private let pending: Bool
    private let now: Date
    private let recorder: TessToolRecorder

    @MainActor
    init(tool: TessTools.Tool, engine: ActionEngine, pending: Bool, now: Date, recorder: TessToolRecorder) {
        name = tool.name
        description = tool.description
        self.engine = engine
        self.pending = pending
        self.now = now
        self.recorder = recorder
        parameters = (try? GenerationSchema(root: Self.dynamic(tool.input, name: tool.name,
                                                               summary: tool.description), dependencies: []))
            ?? GenerationSchema(type: GeneratedContent.self, description: tool.description, properties: [])
    }

    /// TessSchema to the on-device schema: nullable fields become optional properties.
    static func dynamic(_ schema: TessSchema, name: String, summary: String = "") -> DynamicGenerationSchema {
        switch schema {
        case .string: DynamicGenerationSchema(type: String.self)
        case .number: DynamicGenerationSchema(type: Double.self)
        case .integer: DynamicGenerationSchema(type: Int.self)
        case .boolean: DynamicGenerationSchema(type: Bool.self)
        case let .choice(options, text): DynamicGenerationSchema(name: name, description: text, anyOf: options)
        case let .array(item): DynamicGenerationSchema(arrayOf: dynamic(item, name: name + "Item"))
        case let .nullable(inner): dynamic(inner, name: name)
        case let .object(properties):
            DynamicGenerationSchema(name: name, description: summary, properties: properties.map { key, value in
                let optional = if case .nullable = value {
                    true
                } else {
                    false
                }
                return DynamicGenerationSchema.Property(name: key, description: value.summary,
                                                        schema: dynamic(value, name: name + key.capitalized),
                                                        isOptional: optional)
            })
        }
    }

    func call(arguments: GeneratedContent) async throws -> String {
        let json = arguments.jsonString
        return await MainActor.run { perform(json) }
    }

    @MainActor
    private func perform(_ json: String) -> String {
        do {
            let records = try TessTools.run(name, arguments: Data(json.utf8), engine: engine, pending: pending,
                                            now: now)
            recorder.records += records
            return "Done: " + records.map(\.summary).joined(separator: "; ")
        } catch let answer as TessToolAnswer {
            return "Answer: \(answer.line)"
        } catch {
            return "Error: \(error)"
        }
    }
}

/// Builds a tool's on-device schema (tests use it to prove every TessTools tool converts).
enum GenerationSchemaCheck {
    @MainActor
    static func make(_ tool: TessTools.Tool) throws -> GenerationSchema {
        try GenerationSchema(root: CatalogTool.dynamic(tool.input, name: tool.name, summary: tool.description),
                             dependencies: [])
    }
}
