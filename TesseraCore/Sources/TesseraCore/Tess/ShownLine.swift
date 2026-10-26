import Foundation

/// Kaushik, Oct 26: no full stop at the end of any shown line, unless it is part of a note or a document. Every
/// line the app shows (Tess's replies, Home's lines, the board, receipts and Undo lines) passes through `unstopped`
/// before it is drawn. His own notes and documents never do: they keep his punctuation.
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

    /// A full stop that ends a sentence inside the line (". " before a capital or a digit) becomes a line break.
    static func sentenceBreaks(_ text: String) -> String {
        let chars = Array(text)
        var out = ""
        var index = 0
        while index < chars.count {
            let char = chars[index]
            if char == ".", index > 0, chars[index - 1] != "." {
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

    /// Whether a line is already as it should be shown.
    public static func isUnstopped(_ line: String) -> Bool {
        unstopped(line) == line
    }
}
