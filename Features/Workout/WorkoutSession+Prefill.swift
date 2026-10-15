import Foundation
import TesseraCore

/// Where the dialled set came from (Core's prefill), in words, and whether one hold can log it as is.
extension WorkoutSession {
    /// Why the dial opened where it did, in Tess's words.
    static func reason(for prefill: SetPrefill) -> String? {
        if prefill.isFirstTime, prefill.source != .thisSession {
            return "First time. Start light, \(prefill.reps) reps"
        }
        return switch prefill.source {
        case .lastTime:
            prefill.weight.map { "Same as last time, \(Format.kilograms($0)) × \(prefill.reps)" }
        case .thisSession: nil
        case .target: "From the plan"
        case .none: nil
        }
    }

    /// The dial still holds the prefill exactly, so Core's LogNextSet can log it as is.
    var isAtPrefill: Bool {
        guard let entry = currentEntry, rpe == nil, Format.unit == .kilograms else { return false }
        let prefill = model.ledger.prefill(for: entry)
        guard let weight = prefill.weight else { return false }
        return abs(weight - self.weight) < 0.001 && prefill.reps == Int(reps)
    }
}
