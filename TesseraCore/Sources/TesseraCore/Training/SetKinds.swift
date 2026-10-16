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
