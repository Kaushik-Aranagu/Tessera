import Foundation
@testable import TesseraCore
import Testing

/// The op round-trip suite (sheet 288, section 6): every action that can run on a sample world performs, undoes to the
/// exact state before, and redoes to the exact state after. Arguments come from the action's own descriptor (a word, a
/// number, a date, an object or a class from the sample world); an action no sample reaches must say why in `reasons`,
/// so a new action either round-trips or is named here.
@MainActor
struct ActionRoundTripTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        engine.now = { Date(timeIntervalSince1970: 1_792_670_400) }
        engine.zone = { TimeZone(identifier: "UTC")! }
    }

    /// Why an action has no sample here (checked for being a real action, and the list must not outlive its reasons).
    static let reasons: [String: String] = [:]

    // MARK: Fingerprint

    /// Live objects (title, class, parent, order, values) and the links between live objects; no timestamps, no ops.
    func fingerprint() -> [String] {
        let context = store.context
        var lines: [String] = []
        for object in context.objects.values where !object.isDeleted && !object.isClassObject {
            let values = object.values.storage.keys.sorted()
                .map { "\($0)=\(String(describing: object.values.storage[$0]!))" }
            lines.append("o \(object.id) \(object.title) \(object.classDef?.id.uuidString ?? "-") "
                + "\(object.parent?.id.uuidString ?? "-") \(object.sortIndex) \(values.joined(separator: ";"))")
        }
        for link in context.links.values {
            guard let from = link.from, !from.isDeleted else { continue }
            if let to = link.toObject, to.isDeleted {
                continue
            }
            lines.append("l \(link.fieldID) \(from.id) \(link.toObject?.id.uuidString ?? "-") "
                + "\(link.toClass?.id.uuidString ?? "-") \(link.sortIndex)")
        }
        return lines.sorted()
    }

    // MARK: The sample world

    func sampleObjects() -> [ObjectRecord] {
        var made: [ObjectRecord] = []
        var byClass: [UUID: ObjectRecord] = [:]
        for object in store.context.objects.values where !object.isDeleted && !object.isClassObject {
            if let id = object.classDef?.id, byClass[id] == nil {
                byClass[id] = object
            }
        }
        made = byClass.values.sorted { $0.id.uuidString < $1.id.uuidString }
        return made
    }

    func makeWorld() throws {
        // One live object of every system class that has none, so an object argument has something of each kind to be.
        for key in SystemCatalog.Key.allCases {
            guard let classDef = classes[key], store.objects(of: classDef).allSatisfy(\.isDeleted) else { continue }
            _ = store.create(classDef, title: "Sample \(key.rawValue)")
        }
    }

    // MARK: Arguments

    func candidates(for parameter: ActionDescriptor.Parameter, objects: [ObjectRecord]) -> [Any] {
        switch parameter.kind {
        case .string:
            switch parameter.name {
            case "currency": ["USD"]
            case "kind": ["push", "pull", "rest", "morning"]
            case "place": ["fridge", "home"]
            default: ["Sample", "milk", "2 eggs"]
            }
        case .number, .integer: [3, 1, 100]
        case .boolean: [true]
        case .date: [ISO8601DateFormatter().string(from: engine.now())]
        case .object: objects.map(\.id.uuidString)
        case .classRef: classes.values.map(\.id.uuidString).sorted()
        case .json: [[String: Any]()]
        }
    }

    /// Argument sets to try, in order, capped: the first candidate of every parameter, then each parameter's others one
    /// at
    /// a time against the first of the rest, then pairs of object parameters.
    func attempts(for descriptor: ActionDescriptor, objects: [ObjectRecord]) -> [[String: Any]] {
        let required = descriptor.parameters.filter(\.isRequired)
        let options = required.map { candidates(for: $0, objects: objects) }
        guard !options.contains(where: \.isEmpty) else { return [] }
        var results: [[String: Any]] = []
        func build(_ picks: [Int]) -> [String: Any] {
            var arguments: [String: Any] = [:]
            for (index, parameter) in required.enumerated() {
                arguments[parameter.name] = options[index][picks[index]]
            }
            return arguments
        }
        let objectSlots = required.indices.filter { required[$0].kind == .object || required[$0].kind == .classRef }
        let base = [Int](repeating: 0, count: required.count)
        results.append(build(base))
        for slot in required.indices {
            for pick in 1 ..< max(options[slot].count, 1) {
                var picks = base
                picks[slot] = pick
                results.append(build(picks))
            }
        }
        if objectSlots.count >= 2 {
            let first = objectSlots[0], second = objectSlots[1]
            for one in 0 ..< options[first].count {
                for two in 0 ..< options[second].count {
                    var picks = base
                    picks[first] = one
                    picks[second] = two
                    results.append(build(picks))
                }
            }
        }
        return Array(results.prefix(700))
    }

    // MARK: The suite

    struct Outcome {
        var covered: [String] = []
        var unreached: [String] = []
        var failures: [String] = []
    }

    func run() throws -> Outcome {
        try makeWorld()
        let objects = sampleObjects()
        var outcome = Outcome()
        for descriptor in ActionRegistry.descriptors {
            var reached = false
            for arguments in attempts(for: descriptor, objects: objects) {
                guard let data = try? JSONSerialization.data(withJSONObject: arguments) else { continue }
                let before = fingerprint()
                guard let record = try? engine.perform(named: descriptor.name, arguments: data, by: .user),
                      record.state == .committed, !record.ops.isEmpty else { continue }
                reached = true
                let after = fingerprint()
                if after == before {
                    // It ran and changed nothing visible (a no-op on this world): not a round-trip.
                    reached = false
                    engine.undo(record)
                    continue
                }
                engine.undo(record)
                if fingerprint() != before {
                    outcome.failures.append("\(descriptor.name): undo did not restore \(arguments)")
                }
                engine.redo(record)
                if fingerprint() != after {
                    outcome.failures.append("\(descriptor.name): redo did not restore \(arguments)")
                }
                engine.undo(record)
                break
            }
            if reached {
                outcome.covered.append(descriptor.name)
            } else {
                outcome.unreached.append(descriptor.name)
            }
        }
        return outcome
    }

    @Test func everyReachableActionRoundTripsAndTheRestSaysWhy() throws {
        let outcome = try run()
        print("ROUNDTRIP covered \(outcome.covered.count) unreached \(outcome.unreached.count)")
        print("ROUNDTRIP unreached: \(outcome.unreached.joined(separator: ", "))")
        #expect(outcome.failures.isEmpty, "\(outcome.failures)")
        let unexplained = outcome.unreached.filter { Self.reasons[$0] == nil }
        #expect(unexplained.isEmpty, "no sample and no reason: \(unexplained)")
        let stale = Self.reasons.keys
            .filter { outcome.covered.contains($0) || !ActionRegistry.descriptors.map(\.name).contains($0) }
        #expect(stale.isEmpty, "reasons for actions that round-trip or don't exist: \(stale)")
    }
}
