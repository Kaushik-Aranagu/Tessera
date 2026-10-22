import SwiftUI
import TesseraCore

/// The shared landing frame (Design 131 §1, Kaushik's v2, Oct 22): every app's first page talks to him. A back word,
/// the title (a tap opens the app index), one sentence computed on the phone with its key words in the app's accent,
/// then the app's own lead form, then the bands that have something (Running, Waiting, New), the doors as plain ink
/// words, and one action word at the foot, the only thing underlined in the accent. A band with nothing in it isn't
/// drawn at all. No cards, pills, lines between rows, dots or caps; 22 pt gutter from here and nowhere else.
struct LandingPage<Lead: View>: View {
    var back: (title: String, action: () -> Void)?
    let title: String
    var onTitle: (() -> Void)?
    /// The app's sentence, its key words already in the accent (LandingSentence builds it).
    let sentence: AttributedString
    let accent: Color
    var running: [LandingLine] = []
    var waiting: [LandingLine] = []
    var new: [LandingLine] = []
    @ViewBuilder let lead: Lead
    var doors: [LandingDoor] = []
    /// The one action, underlined in the accent; a second word at the right stays plain ink.
    var action: LandingAction?
    var secondary: LandingAction?

    /// Its own page (a back word, the title, its own scroll and gutter); false inside Home's deck, which already
    /// draws the area's name (a tap opens the index), scrolls and keeps the gutter: the page adds none of its own.
    var standalone = true

    var body: some View {
        if standalone {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    content
                }
                // The page's one gutter (Kitchen G6): nothing inside adds its own sideways padding.
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.m)
                .padding(.bottom, Theme.Spacing.section)
            }
            .scrollIndicators(.hidden)
        } else {
            VStack(alignment: .leading, spacing: 0) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var content: some View {
        Text(sentence)
            .font(Theme.voice(size: 21))
            .foregroundStyle(Theme.Colors.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, standalone ? Theme.Spacing.s : 0)
            .entrance(1)
        band("Running", running)
        lead
            .padding(.top, Theme.Spacing.xxl)
            .entrance(2)
        band("Waiting", waiting)
        band("New", new)
        if !doors.isEmpty {
            LandingDoors(doors: doors)
                .padding(.top, Theme.Spacing.xl)
                .entrance(3)
        }
        if action != nil || secondary != nil {
            foot
                .padding(.top, Theme.Spacing.l)
                .entrance(4)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let back {
            Button(action: back.action) {
                Text("‹ \(back.title)")
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(minHeight: 44)
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityLabel("Back to \(back.title)")
            .entrance(0)
        }
        Group {
            if let onTitle {
                Button(action: onTitle) { titleText }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityHint("Opens the index")
            } else {
                titleText
            }
        }
        .accessibilityAddTraits(.isHeader)
        .entrance(0, hero: true)
    }

    private var titleText: some View {
        Text(title)
            .textRole(.title)
            .foregroundStyle(Theme.Colors.ink)
    }

    /// A margin word and up to three lines; nothing at all when empty (131 §1, no "nothing here" bands).
    @ViewBuilder
    private func band(_ label: String, _ lines: [LandingLine]) -> some View {
        if !lines.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Text(label)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(width: 64, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    ForEach(lines.prefix(3)) { line in
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(line.text)
                                .textRole(.body)
                                .foregroundStyle(Theme.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if let link = line.link {
                                Button(link.word, action: link.action)
                                    .buttonStyle(LandingLinkStyle(accent: accent))
                            }
                        }
                    }
                }
            }
            .padding(.top, Theme.Spacing.xl)
            .entrance(2)
        }
    }

    private var foot: some View {
        HStack(alignment: .firstTextBaseline) {
            if let action {
                Button(action.word, action: action.run)
                    .buttonStyle(LandingLinkStyle(accent: accent))
                    .accessibilityHint(action.hint)
            }
            Spacer(minLength: Theme.Spacing.m)
            if let secondary {
                Button(secondary.word, action: secondary.run)
                    .buttonStyle(LandingWordStyle())
                    .accessibilityHint(secondary.hint)
            }
        }
    }
}

/// The doors: plain ink words, wrapping onto a second line when they run out of room.
struct LandingDoors: View {
    let doors: [LandingDoor]

    var body: some View {
        LandingWrap(spacing: Theme.Spacing.l, lineSpacing: Theme.Spacing.s) {
            ForEach(doors) { door in
                Button(door.word, action: door.action)
                    .buttonStyle(LandingWordStyle())
            }
        }
    }
}

/// One line in a band, with an optional link word at its end ("Go on", "Link them").
struct LandingLine: Identifiable {
    let id = UUID()
    let text: String
    var link: (word: String, action: () -> Void)?
}

/// A door into one of the app's places.
struct LandingDoor: Identifiable {
    var id: String {
        word
    }

    let word: String
    let action: () -> Void
}

/// The foot's word.
struct LandingAction {
    let word: String
    let hint: String
    let run: () -> Void
}

/// An ink word with the accent line under it: the page's one action, and a band's link word.
struct LandingLinkStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.bodyStrong)
            .foregroundStyle(Theme.Colors.ink)
            .padding(.bottom, 3)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(accent)
                    .frame(height: 2)
            }
            .opacity(configuration.isPressed ? 0.6 : 1)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// A plain ink word: a door, or the foot's second word. Never grey (131 §1).
struct LandingWordStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// Words left to right, onto the next line when the next one wouldn't fit.
struct LandingWrap: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map { $0.reduce(0) { $0 + $1.size.width } + spacing * CGFloat(max($0.count - 1, 0)) }
            .max() ?? 0
        let height = rows.map { $0.map(\.size.height).max() ?? 0 }.reduce(0, +) + lineSpacing * CGFloat(max(
            rows.count - 1,
            0
        ))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            let height = row.map(\.size.height).max() ?? 0
            for item in row {
                subviews[item.index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += height + lineSpacing
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [[(index: Int, size: CGSize)]] {
        var rows: [[(index: Int, size: CGSize)]] = [[]]
        var used: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil))
            if !(rows.last?.isEmpty ?? true), used + spacing + size.width > width {
                rows.append([])
                used = 0
            }
            used += (rows.last?.isEmpty ?? true ? 0 : spacing) + size.width
            rows[rows.count - 1].append((index, size))
        }
        return rows
    }
}

/// Draws Core's landing sentence (LandingSentences, #1222): its words in ink, its key word in the app's accent.
enum LandingText {
    static func build(_ sentence: LandingSentence, accent: Color) -> AttributedString {
        var text = AttributedString(sentence.text)
        if let key = sentence.key, let range = text.range(of: key) {
            text[range].foregroundColor = accent
        }
        return text
    }
}

/// The Review switch that turns the landings on (131): "Landing pages", default Off, live.
enum LandingSwitch {
    nonisolated static let choiceID = "landingPages"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}
