import Foundation

/// What the phone and the wrist say to each other (docs/design/watch-set-logging-105.md). The phone is the source of
/// truth: it owns the workout and every write; the Watch shows the last `WatchSnapshot` and sends `WatchCommand`s.
/// Compiled into the app and the Watch app; nothing here needs a framework beyond Foundation.
enum WatchLink {
    /// `WCSession.updateApplicationContext` / message keys.
    static let snapshotKey = "snapshot"
    static let commandKey = "command"
}

/// The one screen's state, built on the phone and masked at source: a private workout carries no exercise name.
struct WatchSnapshot: Codable, Equatable, Sendable {
    enum Phase: String, Codable, Sendable {
        /// No workout is running: the Watch says so and offers nothing to log.
        case idle
        /// Dialling a set.
        case set
        /// Resting after a set.
        case rest
        /// Every set is done; the finish face.
        case finished
    }

    var phase: Phase
    /// The exercise as the wrist shows it; "Private workout" when the workout is private.
    var exercise: String
    var setNumber: Int
    var setCount: Int
    var weight: Double
    var reps: Int
    var unit: String
    /// The crown's step in `unit`: the plate step for this lift.
    var weightStep: Double
    var restEndsAt: Date?
    var restTotal: TimeInterval
    /// Sets logged so far on this exercise, newest first, as "82.5 x 8".
    var sets: [String]
    /// The id of each of those sets, in the same order: an undo names the set it means.
    var setIDs: [String] = []
    var isPrivate: Bool
    /// Bumped on every phone-side change so the Watch ignores an older delivery.
    var revision: Int

    static let idle = WatchSnapshot(phase: .idle, exercise: "", setNumber: 0, setCount: 0, weight: 0, reps: 0,
                                    unit: "kg", weightStep: 2.5, restEndsAt: nil, restTotal: 0, sets: [],
                                    isPrivate: false, revision: 0)

    /// "82.5": whole numbers drop the decimal.
    static func number(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%g", value)
    }

    /// The line for a logged set: "82.5 x 8".
    static func line(weight: Double, reps: Int) -> String {
        "\(number(weight)) x \(reps)"
    }

    /// The shorter forms a name shrinks to before it would truncate mid-word, longest first:
    /// "Incline Dumbbell Press" → "Dumbbell Press" → "Incline". A one-word name has none.
    static func shortNames(_ name: String) -> [String] {
        let words = name.split(separator: " ").map(String.init)
        guard words.count > 1 else { return [] }
        var forms: [String] = []
        if words.count > 2 {
            forms.append(words.suffix(2).joined(separator: " "))
        }
        forms.append(words[0])
        return forms
    }
}

/// What the wrist asks the phone to do. Every one maps to an action the phone already has.
enum WatchCommand: Codable, Equatable, Sendable {
    case logSet(weight: Double, reps: Int)
    /// Take out the set with this id, and only that one: nothing happens if the latest set is another one.
    case undo(setID: String)
    case extendRest(seconds: Int)
    case skipRest
    /// The Watch just woke: send a fresh snapshot.
    case hello

    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(_ data: Data) -> WatchCommand? {
        try? JSONDecoder().decode(WatchCommand.self, from: data)
    }
}

extension WatchSnapshot {
    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(_ data: Data) -> WatchSnapshot? {
        try? JSONDecoder().decode(WatchSnapshot.self, from: data)
    }
}

/// What taking a set out from the wrist means, in one place for both ends: the wrist names the latest set it can
/// see, remembers exactly its numbers, and the phone removes it only if it is still the latest.
enum WatchUndo {
    struct Removal: Equatable {
        let setID: String
        let weight: Double
        let reps: Int
    }

    /// The set the wrist would remove: the newest in its snapshot, with the numbers that snapshot shows for it.
    static func removal(in snapshot: WatchSnapshot) -> Removal? {
        guard let id = snapshot.setIDs.first, let line = snapshot.sets.first else { return nil }
        let parts = line.split(separator: " ").filter { $0 != "x" && $0 != "×" }
        guard parts.count == 2, let weight = Double(parts[0]), let reps = Int(parts[1]) else { return nil }
        return Removal(setID: id, weight: weight, reps: reps)
    }

    /// Whether the phone should take the set out: only when it is the one the wrist named.
    static func accepts(requested: String, latest: String?) -> Bool {
        latest == requested
    }
}
