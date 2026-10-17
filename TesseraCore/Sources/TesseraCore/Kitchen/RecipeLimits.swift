import Foundation

/// The sizes a recipe may hold, from any source (paste, link, Claude, an edit, a stored value; Kitchen gap hunt 9,
/// G62): serves 1 to 100, times 1 to 1440 minutes. Every conversion to `Int` goes through here, so a huge, NaN or
/// infinite value can never crash a page; it is clamped, or read as nothing.
public enum RecipeLimits {
    public static let serves: ClosedRange<Int> = 1 ... 100
    public static let minutes: ClosedRange<Double> = 1 ... 1440

    /// A serving size inside 1 to 100; nil for nothing, zero or less, NaN or infinity.
    public static func serves(_ value: Double?) -> Int? {
        guard let value, value.isFinite, value >= 0.5 else { return nil }
        return Int(min(value.rounded(), Double(serves.upperBound)))
    }

    public static func serves(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return min(value, serves.upperBound)
    }

    /// A time inside 1 to 1440 minutes; nil for nothing, zero or less, NaN or infinity.
    public static func minutes(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value > 0 else { return nil }
        return min(max(value, minutes.lowerBound), minutes.upperBound)
    }

    /// `Int(value)` that never traps: nil for NaN, infinity or anything outside ±1e15.
    public static func whole(_ value: Double) -> Int? {
        guard value.isFinite, abs(value) < 1e15 else { return nil }
        return Int(value)
    }
}
