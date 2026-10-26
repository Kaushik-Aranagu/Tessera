import Foundation

/// Kaushik, Oct 26: no full stop at the end of any shown line, unless it is part of a note or a document. Tess's
/// replies, her Home done lines and the director's why pass through `unstopped` here; the app's own lines (the board,
/// receipts, Undo lines) take it in their views. His notes and documents never do: they keep his punctuation.
public enum ShownLine {
    /// The line as shown: the closing full stop dropped, and a full stop between two sentences turned into a line
    /// break, so a two-sentence line shows as two lines with no stops. A one-line slot (a board row) passes
    /// `between: ", "` instead. A question mark, an ellipsis, a decimal ("2.5 km") and a stop inside a word ("e.g")
    /// stay.
    public static func unstopped(_ line: String, between: String = "\n") -> String {
        let text = sentenceBreaks(line.trimmingCharacters(in: .whitespacesAndNewlines))
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { piece in
            var shown = String(piece).trimmingCharacters(in: .whitespaces)
            if shown.hasSuffix("."), !shown.hasSuffix("..") {
                shown.removeLast()
            }
            return shown
        }
        return lines.joined(separator: between)
    }

    /// Words a stop follows without ending a sentence ("Dr. Lin", "St. Louis"); a single letter ("U.S. Open") too.
    static let abbreviations: Set<String> = ["dr", "mr", "mrs", "ms", "st", "vs", "jr", "sr", "mt"]

    /// A full stop that ends a sentence inside the line (". " before a capital or a digit) becomes a line break; a
    /// stop after an abbreviation or a single letter stays.
    static func sentenceBreaks(_ text: String) -> String {
        let chars = Array(text)
        var out = ""
        var index = 0
        while index < chars.count {
            let char = chars[index]
            if char == ".", index > 0, chars[index - 1] != ".", !followsAbbreviation(chars, at: index) {
                var next = index + 1
                while next < chars.count, chars[next] == " " {
                    next += 1
                }
                if next > index + 1, next < chars.count, chars[next].isUppercase || chars[next].isNumber {
                    out.append("\n")
                    index = next
                    continue
                }
            }
            out.append(char)
            index += 1
        }
        return out
    }

    /// Whether the word just before the stop at `index` is an abbreviation or a single letter.
    static func followsAbbreviation(_ chars: [Character], at index: Int) -> Bool {
        var start = index
        while start > 0, chars[start - 1].isLetter {
            start -= 1
        }
        let word = String(chars[start ..< index]).lowercased()
        return word.count == 1 || abbreviations.contains(word)
    }

    /// Whether a line is already as it should be shown.
    public static func isUnstopped(_ line: String) -> Bool {
        unstopped(line) == line
    }
}
