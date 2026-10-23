import SwiftUI
import TesseraCore

/// The three lines (sheet 199): Core's HomeSentence clauses, one per line, right-aligned, Figtree 24 at 400. The app
/// word is 500 in its app's accent and opens what it names; a number is Outfit 300. No underline at rest, a 1 pt
/// one in the accent while pressed. Colour on Home sits on these words only.
struct MosaicSentence: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openHomeLink) private var openLink

    /// Core's picked lines as clauses (sheets 200 and 201: accents, masked words plain); nil draws the day sentence.
    var pickedClauses: [HomeSentence.Clause]?

    static let size: CGFloat = 23
    static let lineGap: CGFloat = 4

    var body: some View {
        let _ = model.revision
        let clauses = HomeMosaic.firstThree(HomeSentence.compose(HomeSentence.inputs(engine: model.engine,
                                                                                     plan: model.plan,
                                                                                     now: AppClock.now)))
        if HomeMosaic.moodsIsOn {
            // Sheet 200: the same clauses as a departure board (Core's MosaicMoodPicker lines replace them when it
            // lands).
            let shown = pickedClauses ?? clauses
            let lines = shown.isEmpty
                ? [[DepartureSegment(text: HomeSentence.quietDay, kind: .plain)]]
                : shown.map(DepartureLines.segments(of:))
            DepartureBoard(lines: lines) { index in
                if index < shown.count {
                    DaySentence.open(shown[index], model: model, openLink: openLink)
                }
            }
        } else {
            VStack(alignment: .trailing, spacing: Self.lineGap) {
                if clauses.isEmpty {
                    MosaicSentenceLine(text: HomeSentence.quietDay, words: DaySentence.words([]), clause: nil) {}
                }
                ForEach(Array(clauses.enumerated()), id: \.offset) { _, clause in
                    MosaicSentenceLine(text: clause.text, words: DaySentence.words([clause]), clause: clause) {
                        DaySentence.open(clause, model: model, openLink: openLink)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

/// One clause as words flowing from the right edge.
private struct MosaicSentenceLine: View {
    let text: String
    let words: [DaySentence.Word]
    let clause: HomeSentence.Clause?
    let open: () -> Void

    var body: some View {
        TrailingWrap(spacing: 6, lineSpacing: 2.4) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                if let app = word.app {
                    Button(action: open) {
                        Text(word.text)
                            .font(Theme.voice(size: MosaicSentence.size * 1.12).weight(.semibold))
                    }
                    .buttonStyle(MosaicWordStyle(accent: app.accent))
                } else if word.text.contains(where: \.isNumber) {
                    Text(word.text)
                        .numeral(MosaicSentence.size, weight: .light)
                        .foregroundStyle(Theme.Colors.ink)
                } else {
                    Text(word.text)
                        .font(Theme.voice(size: MosaicSentence.size))
                        .foregroundStyle(Theme.Colors.ink)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityActions {
            if let clause, let range = clause.keyWord {
                Button((clause.text as NSString).substring(with: NSRange(location: range.lowerBound,
                                                                         length: range.count)))
                {
                    open()
                }
            }
        }
    }
}

/// An app word: its accent at rest, no underline; a 1 pt underline in the accent while pressed.
struct MosaicWordStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(accent)
            .overlay(alignment: .bottom) {
                Rectangle().fill(accent).frame(height: 1)
                    .offset(y: 5)
            }
            // A touch target past the glyphs, without making the line taller.
            .contentShape(.interaction, Rectangle().inset(by: -8))
    }
}
