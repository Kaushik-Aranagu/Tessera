import Foundation

/// A typed action: the only way the UI, Tess and App Intents change data ("system calls").
/// Declared once; its descriptor generates the tool schema Tess and Claude see, and App Intents wrap it.
public protocol EngineAction: Codable, Sendable {
    associatedtype Output = Void
    static var descriptor: ActionDescriptor { get }
    /// Applies the action. Anything it writes goes through `transaction` and is logged.
    @MainActor func apply(_ transaction: inout Transaction) throws -> Output
    /// A one-line receipt, written after `apply` succeeded: "Logged bench press 82.5 × 8". Verb first: it's log text
    /// (the Day log, the op history), never read aloud raw (Product, 12:01 PM PT Oct 16).
    @MainActor func summary(in store: ObjectStore) -> String
    /// What Tess says for it, thing first: "Films, made.", "Milk, on Groceries." Nil when it has no spoken form yet;
    /// the caller then falls back (Research receipts-thing-first RC23).
    @MainActor func receipt(in store: ObjectStore) -> String?
}

public extension EngineAction {
    @MainActor func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

/// The schema of an action's arguments, used for validation hints and tool definitions.
public struct ActionDescriptor: Sendable, Hashable {
    public enum Kind: String, Sendable, Codable {
        case string, number, integer, boolean
        /// ISO 8601 date-time.
        case date
        /// The id of an object (a workout, a set, a task).
        case object
        /// The id of a class (an exercise such as Bench Press).
        case classRef
        /// A structured JSON object.
        case json
    }

    public struct Parameter: Sendable, Hashable {
        public let name: String
        public let kind: Kind
        public let summary: String
        public let isRequired: Bool

        public init(_ name: String, _ kind: Kind, _ summary: String, required: Bool = true) {
            self.name = name
            self.kind = kind
            self.summary = summary
            isRequired = required
        }
    }

    public let name: String
    public let summary: String
    public let parameters: [Parameter]
    /// Destructive actions need a confirmation when Tess or an intent runs them.
    public let isDestructive: Bool
    /// False for actions that stay registered (decoding, the op log) but are never offered to Tess or Siri.
    public let isOfferedToModel: Bool

    public init(
        name: String,
        summary: String,
        parameters: [Parameter],
        isDestructive: Bool = false,
        isOfferedToModel: Bool = true
    ) {
        self.name = name
        self.summary = summary
        self.parameters = parameters
        self.isDestructive = isDestructive
        self.isOfferedToModel = isOfferedToModel
    }

    /// One compact line for the on-device model's prompt: `logSet(entry: object, weight: number, …) — Log a set`.
    public var catalogLine: String {
        let arguments = parameters.map { "\($0.name)\($0.isRequired ? "" : "?"): \($0.kind.rawValue)" }
        return "\(name)(\(arguments.joined(separator: ", "))) — \(summary)"
    }

    /// A tool definition in the shape Claude's tool use expects: name, description, input_schema.
    public var toolDefinition: ToolDefinition {
        ToolDefinition(
            name: name,
            description: summary,
            inputSchema: .init(
                properties: Dictionary(uniqueKeysWithValues: parameters.map { ($0.name, .init($0)) }),
                required: parameters.filter(\.isRequired).map(\.name)
            )
        )
    }
}

public struct ToolDefinition: Encodable, Sendable, Hashable {
    public struct Schema: Encodable, Sendable, Hashable {
        public let type = "object"
        public let properties: [String: Property]
        public let required: [String]
    }

    public struct Property: Encodable, Sendable, Hashable {
        public let type: String
        public let format: String?
        public let description: String

        init(_ parameter: ActionDescriptor.Parameter) {
            switch parameter.kind {
            case .string: (type, format) = ("string", nil)
            case .number: (type, format) = ("number", nil)
            case .integer: (type, format) = ("integer", nil)
            case .boolean: (type, format) = ("boolean", nil)
            case .date: (type, format) = ("string", "date-time")
            case .object, .classRef: (type, format) = ("string", "uuid")
            case .json: (type, format) = ("object", nil)
            }
            description = parameter.summary
        }
    }

    public let name: String
    public let description: String
    public let inputSchema: Schema

    enum CodingKeys: String, CodingKey {
        case name, description
        case inputSchema = "input_schema"
    }
}
