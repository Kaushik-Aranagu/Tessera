import SwiftUI

/// A line of words with numbers in their own face (sheet 211): words in Figtree, any word with a digit in Outfit 300,
/// so "12:25 pm" and "Groceries, 0 of 11 done" never draw in the heavy, widely spaced data face.
struct NumberedText: View {
    let text: String
    var size: CGFloat = 16
    var body: some View {
        // Both faces scale with the reader's text size on their own (Theme.voice and Theme.numeral); no second scale.
        Text(Self.attributed(text, size: size))
    }

    static func attributed(_ text: String, size: CGFloat) -> AttributedString {
        var out = AttributedString()
        let tokens = text.split(separator: " ", omittingEmptySubsequences: false)
        for (index, token) in tokens.enumerated() {
            var run = AttributedString(String(token))
            run.font = token.contains(where: \.isNumber) ? Theme.numeral(size, weight: .light) : Theme.voice(size: size)
            out += run
            if index < tokens.count - 1 {
                var space = AttributedString(" ")
                space.font = Theme.voice(size: size)
                out += space
            }
        }
        return out
    }
}
