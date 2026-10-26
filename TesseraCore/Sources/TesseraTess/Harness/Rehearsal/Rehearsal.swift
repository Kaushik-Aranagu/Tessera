import Foundation
import TesseraCore

/// Tess tries it first (docs/ai/harness/rehearsal.md): Tess's own tools run on an in-memory copy of his store, where
/// he can't see them, and what came out is checked before she makes the real change the usual way (pending, with a
/// ghost row and a 10 s Undo). A rehearsal never touches his store, his screen, his notifications, Health, his widgets
/// or the network: the copy has its own engine with no observers, and it is thrown away with the `Rehearsal`.
///
/// She never copies a rehearsal back. She runs the change again on the real engine, so the op log is the real one.
@MainActor
public final class Rehearsal {
    /// One tool call to try: a tool name and its arguments as JSON.
    public struct Call: Sendable, Equatable {
        public var name: String
        public var arguments: Data

        public init(name: String, arguments: Data) {
            self.name = name
            self.arguments = arguments
        }

        public init(name: String, json: String) {
            self.init(name: name, arguments: Data(json.utf8))
        }
    }

    /// What one call said: its receipt, or the line it was refused with.
    public struct Receipt: Sendable, Equatable {
        public var tool: String
        public var line: String
        public var refused: Bool
    }

    /// One thing the rehearsal made, changed or deleted, by its shown name (a private thing is its label). `details`
    /// are its changed fields, old to new; a change that holds money, body or private words is `deviceOnly`.
    public struct Change: Sendable, Equatable {
        public enum Kind: String, Sendable { case made, changed, deleted }
        public var kind: Kind
        public var name: String
        public var details: [String]
        public var taint: Taint
        let id: UUID

        /// How the Door reads it: "made Task Call the bank", "changed Push A, title: Push A -> Push B".
        public var fragment: PackFragment {
            PackFragment((["\(kind.rawValue) \(name)"] + details).joined(separator: ", "), taint: taint)
        }
    }

    /// A check the rehearsal failed.
    public enum Failure: Sendable, Equatable {
        case refused(tool: String, line: String)
        case danglingLink(String)
        case orphan(String)
        case count(expected: Int, got: Int)
        case outOfScope(String)
        case moneyOffPhone(String)

        public var line: String {
            switch self {
            case let .refused(tool, line): "\(tool) was refused: \(line)"
            case let .danglingLink(name): "\(name) now points at something that is gone"
            case let .orphan(name): "\(name) was left without its parent"
            case let .count(expected, got): "Expected \(expected) changed, got \(got)"
            case let .outOfScope(name): "\(name) is outside what this agent may change"
            case let .moneyOffPhone(tool): "\(tool) is a money action and only the phone's own rung may run it"
            }
        }
    }

    public struct Result: Sendable, Equatable {
        public var receipts: [Receipt]
        public var diff: [Change]
        public var failed: [Failure]
        public var passed: Bool {
            failed.isEmpty
        }

        /// The diff and the failed checks as Door fragments (the diff's taint rides on each).
        public var fragments: [PackFragment] {
            diff.map(\.fragment) + failed.map { PackFragment($0.line) }
        }

        /// Receipts, the diff and the failed checks as text for Tess, the diff's tainted lines included. Only the
        /// phone's own model reads this whole; anything for Claude goes through `fragments` and the Door.
        public var text: String {
            var lines = receipts.map { "\($0.tool): \($0.line)" }
            lines += diff.map(\.fragment.text)
            lines += failed.isEmpty ? ["All checks passed."] : failed.map { "Failed: \($0.line)" }
            return lines.joined(separator: "\n")
        }
    }

    /// At most this many tries per ask.
    public static let budget = 3
    /// The tools a rehearsal never runs: itself.
    static let neverTried: Set<String> = ["rehearse"]

    private let real: ActionEngine
    private var copy: (engine: ActionEngine, store: ObjectStore)?
    public private(set) var tries = 0

    public init(engine: ActionEngine) {
        real = engine
    }

    /// The copy, made once per run (three tries cost one copy) and made again fresh for each try, so a try never sees
    /// what the one before did.
    private func freshCopy() throws -> (engine: ActionEngine, store: ObjectStore) {
        let store = try real.store.fork()
        let classes = try SystemCatalog.seed(in: store.context)
        let engine = ActionEngine(store: store, classes: classes)
        engine.now = real.now
        engine.zone = real.zone
        copy = (engine, store)
        return (engine, store)
    }

    /// Runs `calls` on a copy and reports. `expecting` is the count the ask names ("move my 5 tasks"); `scope` is
    /// the agent's memory slice; `onDevice` is whether the phone's own rung is the one asking, since a money tool
    /// off the phone is a failed check whatever it did.
    public func `try`(_ calls: [Call], expecting expected: Int? = nil, scope: MemoryScope? = nil,
                      onDevice: Bool = true) -> Result
    {
        tries += 1
        guard tries <= Self.budget else {
            return Result(receipts: [], diff: [],
                          failed: [.refused(
                              tool: "rehearse",
                              line: "That's three tries; ask him instead of guessing."
                          )])
        }
        guard let (engine, store) = try? freshCopy() else {
            return Result(receipts: [], diff: [], failed: [.refused(tool: "rehearse", line: "No copy could be made.")])
        }
        var receipts: [Receipt] = []
        var failed: [Failure] = []
        let before = Set(engine.history(limit: .max).map(\.id))
        for call in calls {
            if Self.neverTried.contains(call.name) {
                receipts.append(Receipt(tool: call.name, line: "A rehearsal doesn't rehearse.", refused: true))
                failed.append(.refused(tool: call.name, line: "A rehearsal doesn't rehearse."))
                continue
            }
            if !onDevice, TessTools.tool(named: call.name)?.deviceOnly == true {
                receipts.append(Receipt(tool: call.name, line: "That isn't a call I can make here.", refused: true))
                failed.append(.moneyOffPhone(call.name))
                continue
            }
            do {
                let records = try TessTools.run(call.name, arguments: call.arguments, engine: engine, pending: false,
                                                now: engine.now(), calendar: engine.calendar())
                receipts.append(Receipt(tool: call.name, line: records.compactMap(\.receipt).joined(separator: " "),
                                        refused: false))
            } catch let answer as TessToolAnswer {
                receipts.append(Receipt(tool: call.name, line: answer.line, refused: false))
            } catch {
                let line = (error as? TessToolError)?.description ?? "That didn't work."
                receipts.append(Receipt(tool: call.name, line: line, refused: true))
                failed.append(.refused(tool: call.name, line: line))
            }
        }
        let made = engine.history(limit: .max).filter { !before.contains($0.id) }.sorted { $0.createdAt < $1.createdAt }
        let diff = Self.diff(of: made, in: engine)
        failed += Self.integrity(of: made, in: engine)
        if let expected, diff.count != expected {
            failed.append(.count(expected: expected, got: diff.count))
        }
        if let scope {
            for change in diff {
                if let object = store.object(id: change.id), !scope.reads(object.classDef, classes: engine.classes) {
                    failed.append(.outOfScope(change.name))
                }
            }
        }
        return Result(receipts: receipts, diff: diff, failed: failed)
    }

    // MARK: Reading what happened

    static func diff(of records: [OpRecord], in engine: ActionEngine) -> [Change] {
        struct Touch {
            var made = false
            var deleted = false
            var details: [String] = []
        }
        var touched: [UUID: Touch] = [:]
        var order: [UUID] = []
        func touch(_ id: UUID, _ body: (inout Touch) -> Void) {
            if touched[id] == nil {
                touched[id] = Touch()
                order.append(id)
            }
            body(&touched[id]!)
        }
        let store = engine.store
        for record in records {
            for op in record.ops {
                switch op {
                case let .create(object, _, _, _): touch(object) { $0.made = true }
                case let .softDelete(object): touch(object) { $0.deleted = true }
                case let .restore(object): touch(object) { $0.deleted = false }
                case let .setTitle(object, old, new): touch(object) { $0.details.append("title: \(old) -> \(new)") }
                case let .setValue(object, field, old, new):
                    let name = store.context.fields[field]?.name ?? "field"
                    touch(object) { $0.details.append("\(name): \(text(old)) -> \(text(new))") }
                case let .setLinks(object, field, old, new):
                    let name = store.context.fields[field]?.name ?? "link"
                    touch(object) { $0.details.append("\(name): \(old.count) -> \(new.count) links") }
                case let .setSortIndex(object, _, _): touch(object) { $0.details.append("moved") }
                case .createClass, .deleteClass: break
                }
            }
        }
        let last = BodyWeight.lastKg(in: store)
        return order.compactMap { id -> Change? in
            guard let item = touched[id], let object = store.context.objects[id] else { return nil }
            // Made and deleted inside the one try is nothing at all.
            if item.made, item.deleted {
                return nil
            }
            let label = ObjectPrivacy.shownLabel(of: object, in: store, classes: engine.classes)
            let name = label ?? object.title
            let walled = label != nil || TessAskRouter.isUnnameable(object, classes: engine.classes)
                || ([object.title] + item.details).contains { PrivateFacts.isWalled($0, lastWeightKg: last) }
            let kind: Change.Kind = item.made ? .made : item.deleted ? .deleted : .changed
            // A private thing says that it changed, never what it changed from and to.
            return Change(kind: kind, name: name, details: label == nil ? item.details : [],
                          taint: walled ? .deviceOnly : .claudeSafe, id: id)
        }
    }

    static func text(_ value: FieldValue?) -> String {
        switch value {
        case nil: "none"
        case let .text(text), let .choice(text), let .richText(text): text
        case let .number(number), let .mass(number), let .duration(number): String(number)
        case let .bool(flag): flag ? "yes" : "no"
        case let .date(date): date.formatted(.iso8601)
        }
    }

    /// No link left pointing at a deleted object, and nothing made under a parent that is gone.
    static func integrity(of records: [OpRecord], in engine: ActionEngine) -> [Failure] {
        let store = engine.store
        var failures: [Failure] = []
        for record in records {
            for op in record.ops {
                switch op {
                case let .setLinks(object, _, _, new):
                    let name = store.context.objects[object].map(\.title) ?? "An object"
                    for case let .object(target) in new where store.context.objects[target]?.isDeleted != false {
                        failures.append(.danglingLink(name))
                    }
                case let .create(object, _, parent, _):
                    guard let parent else { continue }
                    if store.context.objects[parent]?.isDeleted != false {
                        failures.append(.orphan(store.context.objects[object]?.title ?? "An object"))
                    }
                default: break
                }
            }
        }
        // Whatever is still live in the copy must not sit under a deleted parent.
        for record in records {
            for case let .softDelete(id) in record.ops {
                for child in store.context.objects.values where child.parent?.id == id && !child.isDeleted {
                    failures.append(.orphan(child.title))
                }
            }
        }
        return failures
    }
}
