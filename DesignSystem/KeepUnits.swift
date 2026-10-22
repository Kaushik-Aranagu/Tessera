import Foundation

extension String {
    /// A number and its unit never split across lines: "30 min" keeps its space as a no-break space (U+00A0). Done
    /// where a string is drawn, so the helpers (and their tests) keep their plain spaces.
    var keepingUnits: String {
        replacing(/(\d) (min|h|hr|kg|lb|s)\b/) { "\($0.1)\u{00A0}\($0.2)" }
    }
}
