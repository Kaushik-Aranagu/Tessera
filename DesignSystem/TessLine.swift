import SwiftUI

// The one shared Tess line (Design sheet 383). A new line of hers on a page arrives word by word, about 60 ms a word,
// with a breath after each comma, and her face blinks once as she starts. A page's opening line, and his own drying
// words, appear whole. The text is whole from the first frame for accessibility: the reveal is only each word's
// opacity, so VoiceOver reads it at once and the layout never reflows while it comes in. Reduce Motion: whole at once,
// no blink. She speaks in her own face (`TessFont`).

enum TessLineTiming {
    /// Seconds between one word's start and the next.
    static let perWord = 0.06
    /// The extra beat after a word that ends in a comma.
    static let breath = 0.12

    /// When each word starts, in seconds after the line starts: 60 ms a word, with a breath after each comma.
    static func starts(_ text: String) -> [Double] {
        var time = 0.0
        var out: [Double] = []
        for word in text.split(separator: " ") {
            out.append(time)
            time += perWord + (word.hasSuffix(",") ? breath : 0)
        }
        return out
    }

    /// How long the whole line takes to arrive.
    static func total(_ text: String) -> Double {
        guard let last = starts(text).last else { return 0 }
        return last + perWord
    }

    /// How many words have come in `time` seconds after the line started.
    static func shown(_ text: String, at time: Double) -> Int {
        starts(text).filter { $0 <= time }.count
    }
}

/// A line of hers. `arrives` false (an opening line, his own words) shows it whole; true brings it in word by word.
struct TessLine: View {
    let text: String
    var arrives = true
    var size: CGFloat = TessFont.layerSize
    var color: Color = Theme.Colors.inkSecondary
    /// Called once as the line starts (her face blinks): the room hooks the soul's blink here.
    var onStart: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    private var animated: Bool {
        arrives && !reduceMotion
    }

    var body: some View {
        TimelineView(.animation(
            minimumInterval: 1 / 30,
            paused: !animated || elapsed(Date.now) > TessLineTiming.total(text)
        )) {
            context in
            Text(attributed(shown: animated ? TessLineTiming.shown(text, at: elapsed(context.date)) : .max))
                .font(TessFont.line(size, relativeTo: .callout))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Whole for VoiceOver from the first frame.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .onChange(of: text, initial: true) { _, _ in
            start = .now
            if animated {
                onStart()
            }
        }
    }

    private func elapsed(_ date: Date) -> Double {
        date.timeIntervalSince(start)
    }

    /// The whole text, with the words not yet arrived at no opacity (same layout either way).
    private func attributed(shown: Int) -> AttributedString {
        var out = AttributedString()
        let words = text.split(separator: " ").map(String.init)
        for (index, word) in words.enumerated() {
            var piece = AttributedString(index < words.count - 1 ? word + " " : word)
            piece.foregroundColor = index < shown ? color : color.opacity(0)
            out += piece
        }
        return out
    }
}
