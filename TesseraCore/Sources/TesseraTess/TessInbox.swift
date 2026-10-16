import Foundation
import TesseraCore

/// Phrases waiting for Claude (tess-model-layer.md section 7): a capture the grammar and the phone's model both missed
/// while Claude was out of reach. Kept as said ("1 waiting for Tess"); read by Claude the next time the app is open and
/// online, as pending ghosts he still has to keep. Written without ops: it isn't something he did, and undo shouldn't
/// see it.
@MainActor
public struct TessInbox {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// Oldest first.
    public func waiting() -> [ObjectRecord] {
        guard let waitingClass = classes[.tessWaiting] else { return [] }
        return store.objects(of: waitingClass).filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    func add(_ phrase: String, at date: Date) -> ObjectRecord? {
        let text = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        // Never a key, never the same phrase twice.
        guard let waitingClass = classes[.tessWaiting], !text.isEmpty, !looksLikeClaudeKey(text),
              !waiting().contains(where: { $0.title == text }) else { return nil }
        let item = store.create(waitingClass, title: text)
        item.createdAt = date
        try? store.set("saidAt", to: .date(date), on: item)
        return item
    }

    func remove(_ item: ObjectRecord) {
        store.softDelete(item)
    }
}

public extension TessCaptureEngine {
    /// How many phrases wait for Claude ("1 waiting for Tess").
    var waitingCount: Int {
        TessInbox(store: engine.store, classes: engine.classes).waiting().count
    }

    /// Reads the waiting phrases with Claude, oldest first, each as its own pending ghost. A phrase leaves the inbox
    /// once Claude has read it (whatever it made of it); one that's offline again stays. Call it when the app opens
    /// online, never on a timer.
    func readWaiting(context: TessContext) async -> [TessCapture] {
        guard var claude, !context.commitImmediately else { return [] }
        claude.retrying = true
        let inbox = TessInbox(store: engine.store, classes: engine.classes)
        var captures: [TessCapture] = []
        for item in inbox.waiting() where claude.isAvailable(for: .capture) {
            var request = TessRequest(text: item.title, context: context, use: .capture)
            request.context.commitImmediately = false
            engine.attribution = (claude.route, claude.modelName)
            let result = await claude.run(request, engine: engine)
            engine.attribution = nil
            switch result {
            case let .handled(capture):
                inbox.remove(item)
                captures.append(capture)
            case let .asked(capture) where capture.line == ClaudeTessModel.Failure.offline.line:
                return captures // still offline: keep the rest for next time
            case .asked, .missed:
                inbox.remove(item)
            }
        }
        return captures
    }
}
