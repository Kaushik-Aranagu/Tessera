import Foundation
import TesseraCore

/// What Tess says beside her on Home, one line at a time (sheet 209). Short, an offer and never an order, never guilt.
/// Until Core feeds her real thoughts these are fixed, built only from the day's own sentence.
enum TessThoughts {
    static func lines(facts: MosaicFacts?, asksClaude: Bool) -> [String] {
        var lines: [String] = []
        if let facts {
            lines.append(facts.caption(for: .day))
        }
        if asksClaude {
            lines.append("I can plan the rest of the day if you like.")
        }
        return lines
    }
}
