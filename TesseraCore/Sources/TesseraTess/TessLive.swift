import Foundation
import TesseraCore

/// The live Tess (harness wired into the app): what he says to Tess goes through `TessRun` and the Door, with the
/// Claude key from the phone's Keychain and the on-device model as the other rung. The app builds one of these at
/// launch (never in a demo) and asks it after the phone's own grammar has had its turn; the ledger, the sent log and
/// the trace live in his own store and Application Support, so every call is counted and shown under "What was sent".
///
/// The key is read by the Keychain call inside `ClaudeBrain` and goes into one request's header, never anywhere else.
@MainActor
public final class TessLive {
    /// What an ask turned into: the ghost rows she made (pending, with Undo), her words, a view change the host plays.
    public struct Answer {
        public var records: [OpRecord] = []
        public var line = ""
        public var shell: [ShellIntent] = []
        /// The run could not answer (no key, offline, over the cap): `line` is the phone-made line, never a raw error.
        public var failed = false
        /// Why, when it failed because of Claude (the key, the network, the cap); nil for anything else.
        public var failure: ClaudeFailure?
    }

    public let run: TessRun
    public let door: Door
    private let engine: ActionEngine
    private let keys: any TessKeychain
    /// Why the last ask got no answer from Claude; nil after one that did.
    public private(set) var lastFailure: ClaudeFailure?

    /// - keys: where the Claude key lives (`SystemKeychain` in the app, a fake in tests).
    /// - asksClaude: the one switch "Tess asks Claude", read at every call.
    /// - policy: lab (Claude may see everything but the key) or strict.
    /// - folder: where the trace and the unfinished runs are kept (Application Support/Tessera); nil keeps them in
    ///   memory, for a test.
    /// - router: a test passes its own brains; the app leaves it nil and gets Claude and the on-device model.
    public init(engine: ActionEngine, keys: any TessKeychain, asksClaude: @escaping @MainActor () -> Bool,
                policy: @escaping @MainActor () -> DoorPolicy = { .lab }, folder: URL? = nil,
                router: BrainRouter? = nil)
    {
        self.engine = engine
        self.keys = keys
        let store = engine.store
        let ledger = TessUsageLedger(store: store, classes: engine.classes)
        let sentLog = TessSentLog(store: store, classes: engine.classes)
        let trace = RunTrace(url: folder.map { $0.appendingPathComponent("tess-trace.json") })
        let brains = router ?? BrainRouter { id in
            switch id {
            case .haiku: ClaudeBrain(model: .haiku, keys: keys)
            case .sonnet: ClaudeBrain(model: .sonnet, keys: keys)
            case .opus: ClaudeBrain(model: .opus, keys: keys)
            case .appleOnDevice: AppleBrain()
            default: nil
            }
        }
        door = Door(ledger: ledger, sentLog: sentLog, trace: trace, router: brains, policy: policy,
                    asksClaude: asksClaude)
        let runs = TessRunStore(url: folder.map { $0.appendingPathComponent("tess-runs.json") })
        run = TessRun(door: door, engine: engine, conversation: TessConversation(store: store, classes: engine.classes),
                      trace: trace, runs: runs)
    }

    /// Asks Tess and waits for her whole answer. Writes land as ghost rows (pending) she reports in `records`.
    public func ask(_ phrase: String, about: [ObjectRecord] = [], screen: String? = nil) async -> Answer {
        var answer = Answer()
        var ghosts: [UUID] = []
        for await event in run.ask(phrase, about: about, screen: screen) {
            switch event {
            case let .ghost(id): ghosts.append(id)
            case let .shell(intent): answer.shell.append(intent)
            case let .finished(text): answer.line = text
            case let .failed(line):
                answer.line = line
                answer.failed = true
            case .waiting, .words: break
            }
        }
        if answer.failed {
            answer.failure = await failure()
        }
        lastFailure = answer.failure
        let wanted = Set(ghosts)
        answer.records = engine.store.context.all(OpRecord.self).filter { wanted.contains($0.id) }
            .sorted { $0.createdAt < $1.createdAt }
        return answer
    }

    /// Why the last call to Claude failed, from the trace's last rung and whether a key is saved (presence only: the
    /// key's text is read by the Keychain call and dropped, never kept).
    private func failure() async -> ClaudeFailure? {
        if keys.read() == nil {
            return .noKey
        }
        let spans = await door.trace.all().filter { $0.kind == .brain }
        guard let last = spans.last else { return door.asksClaude() ? nil : nil }
        return ClaudeFailure(outcome: last.outcome.split(separator: " ").first.map(String.init) ?? last.outcome)
    }

    /// As a capture the Ask bar already lands: ghost rows dry, the line is shown, Undo takes them back.
    public func capture(_ phrase: String, about: [ObjectRecord] = [], screen: String? = nil) async -> TessCapture {
        let answer = await ask(phrase, about: about, screen: screen)
        return TessCapture(records: answer.records, line: answer.line, source: .claude)
    }
}
