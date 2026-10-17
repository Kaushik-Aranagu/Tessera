import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Tess model layer T1: the router, and route/model on the op log.
@MainActor
struct TessRouterTests {
    /// A stand-in model route that logs a task the way a model's tool call would.
    struct FakeModelRoute: TessModel {
        var route: OpRoute = .claude
        var modelName: String? = "claude-haiku-5-5"
        func isAvailable(for use: TessUse) -> Bool {
            use == .capture
        }

        func run(_ request: TessRequest, engine: ActionEngine) async -> TessResult {
            guard let record = try? engine.perform(CreateTask(title: request.text), by: .tess, pending: true).record
            else { return .missed }
            return .handled(TessCapture(records: [record], line: "Added.", source: .model))
        }
    }

    @Test func routesRunInOrderAndStampTheirOps() async throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let tess = TessCaptureEngine(engine: engine)
        let context = TessContext(now: .now)

        // Grammar takes what it reads, and its ops say so.
        let grammar = await tess.router.run(TessRequest(text: "buy milk", context: context, use: .capture))
        #expect(grammar.records.first?.route == .grammar && grammar.records.first?.model == nil)

        // A miss falls through to the next route, whose ops carry its route and model.
        let router = TessRouter(engine: engine, models: [GrammarTessModel(capture: tess), FakeModelRoute()])
        let claude = await router.run(TessRequest(text: "ring the gym about chalk", context: context, use: .capture))
        let record = try #require(claude.records.first)
        #expect(record.route == .claude && record.model == "claude-haiku-5-5")
        #expect(engine.attribution == nil)

        // Ops not done by Tess carry no route.
        let mine = try engine.perform(CreateTask(title: "Mine"), by: .user).record
        #expect(mine.route == nil)

        // Nothing takes it: Tess says so.
        let none = await TessRouter(engine: engine, models: []).run(TessRequest(
            text: "x",
            context: context,
            use: .capture
        ))
        #expect(none.source == .none && none.records.isEmpty)
    }

    @Test func routeAndModelSurviveAReopenAndAnExport() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("tessera.sqlite")
        let id: UUID
        do {
            let store = try ObjectStore(context: TesseraContext(url: url))
            let classes = try store.prepareCatalog()
            let engine = ActionEngine(store: store, classes: classes)
            engine.attribution = (.claude, "claude-haiku-5-5")
            id = try engine.perform(CreateTask(title: "Call the gym"), by: .tess).record.id
            engine.attribution = nil
            store.save()
        }
        let reopened = try TesseraContext(url: url)
        let record = try #require(reopened.all(OpRecord.self).first { $0.id == id })
        #expect(record.route == .claude && record.model == "claude-haiku-5-5")

        // Test-only lossless export (maskingPrivate: false); the app never does this.
        let data = try TesseraExport(context: reopened, maskingPrivate: false).encoded()
        let copy = try TesseraContext(url: nil)
        try TesseraExport.decode(data).restore(into: copy)
        #expect(copy.all(OpRecord.self).first { $0.id == id }?.model == "claude-haiku-5-5")
    }
}
