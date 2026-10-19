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

    /// A phrase still unsent after this long is deleted: Claude never reads a week-old "tomorrow".
    public static let maxAge: TimeInterval = 7 * 24 * 3600

    /// Deletes every waiting phrase older than `maxAge`.
    func expire(now: Date) {
        for item in waiting() where now.timeIntervalSince(item.createdAt) > Self.maxAge {
            remove(item)
        }
    }

    /// Oldest first.
    public func waiting() -> [ObjectRecord] {
        guard let waitingClass = classes[.tessWaiting] else { return [] }
        return store.objects(of: waitingClass).filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    func add(_ phrase: String, at date: Date) -> ObjectRecord? {
        let text = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        // Never a key, a secret, money or a body fact (it would go to Claude later; MU2, Research 138 MW4 and 139),
        // never the same phrase twice.
        guard let waitingClass = classes[.tessWaiting], !text.isEmpty, !looksLikeClaudeKey(text),
              !SecretWords.mentions(text), !PrivateFacts.isWalled(text, lastWeightKg: BodyWeight.lastKg(in: store)),
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
    /// The most ghosts one drain lands.
    static let maxDrainedGhosts = 3

    /// How many phrases wait for Claude ("1 waiting for Tess").
    var waitingCount: Int {
        TessInbox(store: engine.store, classes: engine.classes).waiting().count
    }

    /// Lets the waiting phrases go without reading them (with the switch off they would wait forever; QA L4 on #305).
    func clearWaiting() {
        let inbox = TessInbox(store: engine.store, classes: engine.classes)
        inbox.waiting().forEach(inbox.remove)
    }

    /// Reads the waiting phrases with Claude, oldest first, each as its own pending ghost. A phrase leaves the inbox
    /// once Claude has read it (whatever it made of it); one that's offline again stays. The app calls it each time
    /// it comes to the foreground (`AppModel.drainWaitingPhrases`), never on a timer.
    func readWaiting(context: TessContext) async -> [TessCapture] {
        let inbox = TessInbox(store: engine.store, classes: engine.classes)
        // A week unsent and it goes, whether or not Claude is on.
        inbox.expire(now: context.now)
        guard var claude, !context.commitImmediately else { return [] }
        claude.retrying = true
        var captures: [TessCapture] = []
        for item in inbox.waiting() where claude.isAvailable(for: .capture) {
            // At most 3 ghosts per foreground: commit acts on the whole group, so every one has to be on screen.
            // The rest keep waiting and drain after the group is kept or dropped.
            if captures.count >= TessCaptureEngine.maxDrainedGhosts {
                break
            }
            // Queued before the walls (Research 139): a secret, money or body phrase leaves the inbox unread.
            if SecretWords.mentions(item.title) || PrivateFacts.isWalled(
                item.title,
                lastWeightKg: BodyWeight.lastKg(in: engine.store)
            ) {
                inbox.remove(item)
                continue
            }
            // A timer phrase, or anything said while a cook runs, is read on the phone or not at all: it stays (until
            // its week is up) and is never sent.
            if TessRouter.staysOnPhone(item.title, engine: engine) {
                continue
            }
            var request = TessRequest(text: item.title, context: context, use: .capture)
            request.context.commitImmediately = false
            engine.attribution = (claude.route, claude.modelName)
            let result = await claude.run(request, engine: engine)
            engine.attribution = nil
            // Gone only once Claude has read it (a result, or read and understood nothing). Busy, slow, a bad key,
            // the cap or still offline: it stays, and the rest wait for next time (QA S1 on #305).
            switch result {
            case let .handled(capture):
                inbox.remove(item)
                captures.append(capture)
            case .missed:
                inbox.remove(item)
            case .asked:
                return captures
            }
        }
        return captures
    }
}
