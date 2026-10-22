import Foundation

public enum SetKind: String, Codable, Sendable, CaseIterable {
    case warmup, working, drop, failure

    /// Warm-ups never count toward records or weekly volume.
    public var counts: Bool {
        self != .warmup
    }
}

/// How a set was logged, for trust and debugging ("logged from the Lock Screen").
public enum SetSource: String, Codable, Sendable, CaseIterable {
    case hold, dial, lockScreen, tess, manual, intent
}

public extension ObjectStore {
    /// The set's kind; the older warm-up flag still counts. One rule for the ledger and for where a workout stands.
    func setKind(of set: ObjectRecord) -> SetKind {
        if value("isWarmup", of: set) == .bool(true) {
            return .warmup
        }
        return value("kind", of: set)?.stringValue.flatMap(SetKind.init(rawValue:)) ?? .working
    }
}
