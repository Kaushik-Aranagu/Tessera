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
    /// Rewording the rules' plan for the day.
    case plan
    /// Checking a pasted Claude key (Settings: Claude).
    case keyCheck
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
}

/// What a route did with a request.
public enum TessResult {
    /// The route understood it; the capture holds its (pending) records and Tess's line.
    case handled(TessCapture)
    /// The route tried and didn't understand it; the next route gets a go.
    case missed
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

    public init(engine: ActionEngine, models: [any TessModel]) {
        self.engine = engine
        self.models = models
    }

    public func run(_ request: TessRequest) async -> TessCapture {
        // A Claude key pasted into the Ask bar never reaches a route (it would become a note, then every backup).
        if looksLikeClaudeKey(request.text) {
            return TessCapture(records: [], line: "That looks like a Claude key. Paste it in Settings.", source: .none)
        }
        for model in models where model.isAvailable(for: request.use) {
            engine.attribution = (model.route, model.modelName)
            let result = await model.run(request, engine: engine)
            engine.attribution = nil
            if case let .handled(capture) = result {
                return capture
            }
        }
        return TessCapture(records: [], line: "Didn't catch that. Try \u{201C}bench 80 x 8\u{201D}.", source: .none)
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
        capture.grammarCapture(request.text, context: request.context).map(TessResult.handled) ?? .missed
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
