import Foundation
import TesseraCore

/// What Tess is being asked to do; each use decides which routes may take it and how much context leaves the phone.
public enum TessUse: String, Sendable, CaseIterable {
    /// A typed or spoken phrase from the ghost row.
    case capture
    /// A question about the log ("best bench at 5").
    case question
    /// Pasted text the deterministic parsers couldn't read.
    case paste
    /// Reading a recipe link's page (his own READ tap). Receipts say "Recipe link", never "A paste" (G31).
    case recipeLink
    /// Rewording the rules' plan for the day.
    case plan
    /// Checking a pasted Claude key (Settings: Claude).
    case keyCheck
    /// Home's done job: a finished workout's two slots (board 0al).
    case lines
}

/// One request through the routes.
public struct TessRequest: Sendable {
    public var text: String
    public var context: TessContext
    public var use: TessUse

    public init(text: String, context: TessContext, use: TessUse) {
        self.text = text
        self.context = context
        self.use = use
    }

    /// His last weight for the bare-number wall, or nil with a set in focus (a number is then the bar; Product 4:46 PM
    /// PT).
    @MainActor
    func lastWeightKg(_ engine: ActionEngine) -> Double? {
        Self.lastWeightKg(context, engine: engine)
    }

    @MainActor
    static func lastWeightKg(_ context: TessContext, engine: ActionEngine) -> Double? {
        context.entry == nil ? BodyWeight.lastKg(in: engine.store) : nil
    }
}

/// What a route did with a request.
public enum TessResult {
    /// The route understood it; the capture holds its (pending) records and Tess's line.
    case handled(TessCapture)
    /// The route tried and didn't understand it; the next route gets a go.
    case missed
    /// The route didn't write but has a question ("81: 81 kg, or 81 reps?"): the next route gets a go, and the
    /// question is the answer if none understands it.
    case asked(TessCapture)
}

/// One of Tess's routes: the grammar, the on-device model, or Claude. The router asks each in order.
@MainActor
public protocol TessModel {
    var route: OpRoute { get }
    /// The model's name for the op log ("claude-haiku-5-5"), nil for the grammar.
    var modelName: String? { get }
    func isAvailable(for use: TessUse) -> Bool
    func run(_ request: TessRequest, engine: ActionEngine) async -> TessResult
}

/// Runs the routes in order (docs/research/tess-model-layer.md section 5) and stamps every op a route performs with
/// that route and model, so receipts can say "via Claude" and evals can tell routes apart.
@MainActor
public struct TessRouter {
    public let engine: ActionEngine
    public let models: [any TessModel]

    /// A key typed into Ask: where it goes instead (it lives in Review, under Claude; lines audit item 4).
    public static let keyLine = claudeKeyLine

    public init(engine: ActionEngine, models: [any TessModel]) {
        self.engine = engine
        self.models = models
    }

    /// A cook timer never leaves the phone (Research #880): a phrase about a timer is read here or not at all. While a
    /// cook is running, what he says belongs to the cook ("8 mins", "pasta 10", "step 3", "how long left", "stop the
    /// rice"): read on the phone or not at all (N21 to N26). The router and the offline inbox's drain both ask this.
    public static func staysOnPhone(_ text: String, engine: ActionEngine) -> Bool {
        let words = text.lowercased().split { !$0.isLetter }
        if words.contains("timer") || words.contains("timers") {
            return true
        }
        return ProcessTable(engine: engine).running().flatMap(\.subject).map { subject in
            engine.classes[.cook].map { subject.classDef?.id == $0.id } ?? false
        } ?? false
    }

    public func run(_ request: TessRequest) async -> TessCapture {
        // A Claude key pasted into the Ask bar never reaches a route (it would become a note, then every backup).
        if looksLikeClaudeKey(request.text) {
            return TessCapture(records: [], line: TessRouter.keyLine, source: .none)
        }
        var asked: TessCapture?
        // A capture the grammar and the on-device model could not read goes whole to Claude, money, body, health and
        // secret words included (his "yes, all but the key", Oct 17 12:32 PM PT; docs/ai/architecture.md). Only a key
        // or key-shaped text stays on the phone: refused above and again in the Claude route. Every other Claude job
        // keeps its own walls.
        // The exception is for what the grammar cannot read. A walled phrase it understood and answered with a question
        // or a refusal ("I don't keep sums of money.", "$212.37 at Costco?") is its own, and stays on the phone.
        let secret = SecretWords.mentions(request.text)
        let walled = PrivateFacts.isWalled(request.text, lastWeightKg: request.lastWeightKg(engine))
        let stayHome = Self.staysOnPhone(request.text, engine: engine)
        for model in models where model.isAvailable(for: request.use)
            && !((secret || walled) && model.route == .claude && asked?.source == .grammar)
            && !(stayHome && model.route == .claude)
        {
            engine.attribution = (model.route, model.modelName)
            let result = await model.run(request, engine: engine)
            engine.attribution = nil
            switch result {
            case let .handled(capture): return capture
            case let .asked(capture): asked = asked ?? capture
            case .missed: break
            }
        }
        if let asked {
            return asked
        }
        // An example only where it fits: a set in a workout, things while shopping (Design's Speak review).
        let example = if request.context.entry != nil {
            " Try \u{201C}80 × 8\u{201D}."
        } else if request.context.process == Groceries.listID {
            " Try \u{201C}milk, eggs\u{201D}."
        } else {
            ""
        }
        return TessCapture(records: [], line: "Didn't catch that.\(example)", source: .none)
    }
}

/// The deterministic grammar: instant, offline, free. Takes captures only.
@MainActor
public struct GrammarTessModel: TessModel {
    let capture: TessCaptureEngine

    public init(capture: TessCaptureEngine) {
        self.capture = capture
    }

    public var route: OpRoute {
        .grammar
    }

    public var modelName: String? {
        nil
    }

    public func isAvailable(for use: TessUse) -> Bool {
        use == .capture
    }

    public func run(_ request: TessRequest, engine _: ActionEngine) async -> TessResult {
        guard let result = capture.grammarCapture(request.text, context: request.context) else { return .missed }
        return result.asking == .line ? .asked(result) : .handled(result)
    }
}

/// The on-device model step (any `TessModelCapturing`, usually `TessModelCapture`). Takes captures when the model is
/// available on this phone; a capture that performed nothing counts as missed.
@MainActor
public struct OnDeviceTessModel: TessModel {
    let model: any TessModelCapturing

    public init(_ model: any TessModelCapturing) {
        self.model = model
    }

    public var route: OpRoute {
        .onDevice
    }

    public var modelName: String? {
        "apple-on-device"
    }

    public func isAvailable(for use: TessUse) -> Bool {
        use == .capture && model.isAvailable
    }

    public func run(_ request: TessRequest, engine: ActionEngine) async -> TessResult {
        let capture = await model.capture(request.text, context: request.context, engine: engine)
        // A model that answered without acting still gets its line shown (it's the last route today).
        return capture.understood || capture.source != .none ? .handled(capture) : .missed
    }
}
