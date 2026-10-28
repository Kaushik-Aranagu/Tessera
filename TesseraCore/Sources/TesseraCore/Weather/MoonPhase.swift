import Foundation

/// The moon's phase, worked out on the phone from the date alone (no request, no place): the mean synodic month from a
/// known new moon. Good to about half a day, which is plenty for "Waxing, half".
public struct MoonPhase: Equatable, Sendable {
    /// Days since the last new moon, 0 to 29.53.
    public let age: Double
    /// 0 to 1: 0 is new, 0.5 full.
    public var cycle: Double {
        age / Self.synodicMonth
    }

    /// The lit share of the disc, 0 to 1.
    public var illumination: Double {
        (1 - cos(2 * .pi * cycle)) / 2
    }

    public var isWaxing: Bool {
        cycle < 0.5
    }

    public static let synodicMonth = 29.530_588_861
    /// A new moon: 2000-01-06 18:14 UTC.
    static let reference = Date(timeIntervalSince1970: 947_182_440)

    public init(on date: Date) {
        let days = date.timeIntervalSince(Self.reference) / 86400
        let wrapped = days.truncatingRemainder(dividingBy: Self.synodicMonth)
        age = wrapped < 0 ? wrapped + Self.synodicMonth : wrapped
    }

    /// New, Waxing crescent, First quarter, Waxing gibbous, Full, Waning gibbous, Last quarter, Waning crescent.
    public var name: String {
        switch Int((cycle * 8).rounded()) % 8 {
        case 0: "New"
        case 1: "Waxing crescent"
        case 2: "First quarter"
        case 3: "Waxing gibbous"
        case 4: "Full"
        case 5: "Waning gibbous"
        case 6: "Last quarter"
        default: "Waning crescent"
        }
    }

    /// The sub line: "Waxing, half" for a quarter, "Waxing, crescent", "Waning, gibbous"; "New" and "Full" alone.
    public var line: String {
        switch Int((cycle * 8).rounded()) % 8 {
        case 0: "New"
        case 4: "Full"
        case 2, 6: "\(isWaxing ? "Waxing" : "Waning"), half"
        case 1, 7: "\(isWaxing ? "Waxing" : "Waning"), crescent"
        default: "\(isWaxing ? "Waxing" : "Waning"), gibbous"
        }
    }

    /// The value: "New", "Crescent", "Half", "Gibbous" or "Full".
    public var value: String {
        switch Int((cycle * 8).rounded()) % 8 {
        case 0: "New"
        case 4: "Full"
        case 2, 6: "Half"
        case 1, 7: "Crescent"
        default: "Gibbous"
        }
    }
}
