import Foundation
import TesseraCore

/// SQ8 (Product, 7:53 PM PT Oct 15): a bare "2x10" in a live workout that may be 2 sets of 10 or 2 kg x 10. Tess asks
/// "2 × 10: 2 sets, or 2 kg?" and writes nothing until he answers: a tap on either answer, or saying it.
public struct TessSetCountAsk: Sendable, Equatable {
    public enum Choice: Sendable, Equatable {
        /// N sets of M at the last set's weight.
        case sets
        /// One set of N kg (added load on a bodyweight lift) x M, snapped to the kit.
        case kilograms
    }

    /// The exercise entry in focus when he said it.
    public let entry: UUID
    public let count: Int
    public let reps: Double
    /// A bodyweight lift: the weight answer is added load ("+5 kg").
    public let bodyweight: Bool

    public init(entry: UUID, count: Int, reps: Double, bodyweight: Bool) {
        self.entry = entry
        self.count = count
        self.reps = reps
        self.bodyweight = bodyweight
    }

    /// "2 × 10: 2 sets, or 2 kg?" (exact, Research's Q01 to Q19).
    public var line: String {
        "\(count) × \(TessVoice.number(reps)): \(setsAnswer), or \(kilogramsAnswer)?"
    }

    /// The two answers' words, for the ghost rows: "2 sets" and "2 kg" (or "+5 kg").
    public var setsAnswer: String {
        "\(count) sets"
    }

    public var kilogramsAnswer: String {
        "\(bodyweight ? "+" : "")\(count) kg"
    }

    /// A said answer: "sets", "2 sets", "kg", "2 kg", "+2 kg", "kilos". Nil for anything else (the ask then drops).
    @MainActor public func choice(for phrase: String) -> Choice? {
        let text = TessGrammar.normalize(phrase).replacing(/\bkilos?\b|\bkgs\b/, with: "kg")
        let said = text.replacing(/^\+/, with: "").replacing(/(\d)kg$/) { "\($0.1) kg" }
        let count = String(count)
        if said == "sets" || said == "\(count) sets" {
            return .sets
        }
        if said == "kg" || said == "\(count) kg" {
            return .kilograms
        }
        return nil
    }
}

extension TessGrammar.Parse {
    /// A question, not a write: a guarded phrase or the SQ8 ask.
    var isAsk: Bool {
        switch self {
        case .ask, .askSetCount: true
        default: false
        }
    }
}
