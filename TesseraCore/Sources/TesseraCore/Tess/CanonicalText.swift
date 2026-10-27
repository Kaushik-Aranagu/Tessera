import Foundation

/// The form every wall reads (docs/ai/harness/input-hygiene.md, stage 2). A wall that reads text as typed can be
/// walked past with a character he never sees: a zero-width space inside "password", full-width letters, or a curly
/// quote around a word, which the phone's keyboard types by default. Callers keep the text as typed and judge this
/// form; it is never stored or shown.
public enum CanonicalText {
    /// Unicode compatibility folding (full-width and styled letters become plain ones), invisible characters removed,
    /// every dash and quote folded to one, line breaks made "\n" and each run of other spaces made one space.
    public static func of(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        var lastWasSpace = false
        let folded = text.replacingOccurrences(of: "\r\n", with: "\n").precomposedStringWithCompatibilityMapping
        for scalar in folded.unicodeScalars where !isInvisible(scalar) {
            if lineBreaks.contains(scalar) {
                out.append("\n")
                lastWasSpace = false
            } else if scalar.properties.isWhitespace {
                if !lastWasSpace {
                    out.append(" ")
                }
                lastWasSpace = true
            } else {
                out.append(fold(scalar))
                lastWasSpace = false
            }
        }
        return String(out)
    }

    /// Characters that draw nothing: format characters (zero-width spaces and joiners, the soft hyphen, direction
    /// marks and overrides, tags, the byte-order mark), variation selectors, the grapheme joiner and Hangul fillers.
    static func isInvisible(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.generalCategory == .format || (0xFE00 ... 0xFE0F).contains(scalar.value)
            || [0x034F, 0x115F, 0x1160, 0x3164, 0xFFA0].contains(scalar.value)
    }

    static let lineBreaks: Set<Unicode.Scalar> = ["\n", "\r", "\u{0B}", "\u{0C}", "\u{85}", "\u{2028}", "\u{2029}"]
    static let singleQuotes: Set<Unicode.Scalar> = ["\u{2018}", "\u{2019}", "\u{201A}", "\u{201B}", "\u{2032}",
                                                    "\u{2039}", "\u{203A}", "\u{FF07}"]
    static let doubleQuotes: Set<Unicode.Scalar> = ["\u{201C}", "\u{201D}", "\u{201E}", "\u{201F}", "\u{2033}",
                                                    "\u{AB}", "\u{BB}", "\u{FF02}"]

    /// Every dash and the minus sign to "-", every quote to ' or ".
    static func fold(_ scalar: Unicode.Scalar) -> Unicode.Scalar {
        if scalar.properties.generalCategory == .dashPunctuation || scalar == "\u{2212}" {
            return "-"
        }
        if singleQuotes.contains(scalar) {
            return "'"
        }
        return doubleQuotes.contains(scalar) ? "\"" : scalar
    }
}
