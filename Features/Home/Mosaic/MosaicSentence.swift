import SwiftUI
import TesseraCore

/// The three lines (sheet 199): Core's HomeSentence clauses, one per line, right-aligned, Figtree 24 at 400. The app
/// word is 500 in its app's accent and opens what it names; a number is Outfit 300. No underline at rest, a 1 pt
/// one in the accent while pressed. Colour on Home sits on these words only.
struct MosaicSentence: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openHomeLink) private var openLink
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Core's picked lines as clauses (sheets 200 and 201: accents, masked words plain); nil draws the day sentence.
    var pickedClauses: [HomeSentence.Clause]?
    /// The day's clauses, read once per refresh by the page (with Core's loaders).
    var dayClauses: [HomeSentence.Clause]?
    /// Builder A's doorway (sheet 206): when set, a tapped door hands over its clause and the word's frame in window
    /// space (the wave starts there) instead of opening the page directly.
    var onDoor: ((HomeSentence.Clause, CGRect) -> Void)?
    /// Core's ranked notices (sheet 212): lines two and three of the board.
    var noticeList: [HomeNotice] = []
    /// Builder A's doorway for a room (sheet 206): the word's frame in window space; nil opens the page directly.
    var onRoom: ((AppID, CGRect) -> Void)?
    /// "Sunset" swipes the mosaic to its weather page and washes it to dusk (Builder A); nil opens Today meanwhile.
    var onSky: (() -> Void)?
    /// The facts the sunset notice reads.
    var facts: MosaicFacts?
    /// The rotation stops in the background and during a doorway.
    var paused = false
    @State private var rotation = 0
    /// The row's measured width; lines and the date are chosen to fit it.
    @State private var rowWidth = HomeBoard.defaultWidth

    private struct RotationKey: Hashable {
        let paused: Bool
        let count: Int
    }

    static let size: CGFloat = 23
    static let lineGap: CGFloat = 4

    var body: some View {
        let _ = model.revision
        let clauses = dayClauses ?? HomeMosaic.firstThree(HomeSentence.compose(HomeSentence.inputs(engine: model.engine,
                                                                                                   plan: model.plan,
                                                                                                   now: AppClock.now)))
        if HomeMosaic.moodsIsOn {
            // Sheet 212: the date, then two notices that roll every 6 s; every change letter-flips on the board.
            let notices = HomeBoard.notices(from: noticeList, width: rowWidth)
            let board = HomeBoard.lines(
                date: HomeBoard.date(now: AppClock.now, width: rowWidth),
                notices: notices,
                rotation: rotation,
                moment: pickedClauses?.first
            )
            DepartureBoard(lines: board.map(\.segments)) { index, frame in
                guard index < board.count else { return }
                switch board[index].target {
                case .today:
                    openLink(.today)
                case let .clause(clause):
                    if let onDoor {
                        onDoor(clause, frame)
                    } else {
                        DaySentence.open(clause, model: model, openLink: openLink)
                    }
                case let .room(app):
                    // The notice's own target, never `clause.opens` (Core marks it unused).
                    if let onRoom {
                        onRoom(app, frame)
                    } else {
                        switch HomeApp(appID: app) {
                        case .kitchen: openLink(.recipes)
                        case .money: openLink(.money)
                        case .notes: openLink(.notes)
                        case .lists: openLink(.lists)
                        case .training: openLink(.training)
                        default: openLink(.review)
                        }
                    }
                case .weather:
                    // The mosaic's weather page and a dusk wash are Builder A's; Today until they are hooked up.
                    if let onSky {
                        onSky()
                    } else {
                        openLink(.today)
                    }
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
            .task(id: RotationKey(paused: paused || reduceMotion, count: notices.count)) {
                // Under Reduce Motion the rotation is paused: the board swaps plainly only when the top notice changes.
                guard !paused, !reduceMotion, notices.count > 1 else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(HomeBoard.rotationSeconds))
                    guard !Task.isCancelled else { return }
                    rotation += 1
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

/// An app word: its accent at rest, with a 1 pt underline in the accent at offset 5 (shown at rest, not only pressed).
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
