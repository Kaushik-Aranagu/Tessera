import SwiftUI

/// The one fixed landing frame (landing contract §1): header, keystone slot, doors dial, brief, foot, all placed on
/// the 402 x 874 frame. Slots keep their size; only the gaps scale on other screens. No ScrollView.
struct LandingFrame<Keystone: View, Brief: View>: View {
    let title: String
    let accent: Color
    /// One line, longest form first; the frame shows the longest that fits and never wraps or ellipsizes.
    let stateLine: [String]
    /// 16 pt for the Log (246); the other rooms speak a 26 pt light sentence (hub 282).
    var stateSize: CGFloat = 16
    /// Where the doors start; 432 for the Log dial (246), 540 under a caption and two update rows (hub 282).
    var doorsTop: CGFloat = 432
    var onTitle: (() -> Void)?
    @ViewBuilder let keystone: Keystone
    let doors: [DialDoor]
    @Binding var focus: Int
    var openDoor: (DialDoor) -> Void
    /// The caption line under the keystone (y 390), one line, never wrapped.
    var caption: [String] = []
    /// Where the brief or the two update rows start: 612 under the Log dial (246), 424 on the hub 282 stack.
    var briefTop: CGFloat = 612
    @ViewBuilder let brief: Brief
    var action: LandingFootAction?
    /// The left edge (x 0-24) goes back; nil on a root.
    var onBack: (() -> Void)?

    static var designHeight: CGFloat {
        874
    }

    var body: some View {
        GeometryReader { proxy in
            let k = max(0.86, min(1.1, proxy.size.height / Self.designHeight))
            let width = proxy.size.width
            let slot = LandingKeystone<EmptyView>.size
            ZStack(alignment: .topLeading) {
                Group {
                    if let onTitle {
                        Button(action: onTitle) { titleText }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens the index")
                    } else {
                        titleText
                    }
                }
                .frame(height: 56, alignment: .leading)
                .landingSection(.masthead)
                .offset(x: 24, y: 54 * k - 8)

                FitLine(forms: stateLine, size: stateSize, color: Theme.Colors.inkSecondary,
                        weight: stateSize > 20 ? .light : .regular)
                    .frame(width: width - 48, alignment: .leading)
                    .landingSection(.masthead)
                    .offset(x: 24, y: (stateSize > 20 ? 106 : 112) * k)

                keystone
                    .frame(width: slot.width, height: slot.height)
                    .landingSection(.keystone)
                    .offset(x: (width - slot.width) / 2, y: LandingKeystone<EmptyView>.top * k)

                if !caption.isEmpty {
                    FitLine(forms: caption, size: 15, color: Theme.Colors.inkSecondary)
                        .frame(width: width - 48, alignment: .leading)
                        .landingSection(.caption)
                        .offset(x: 24, y: 390 * k)
                }

                DoorsDial(doors: doors, focus: $focus, open: openDoor)
                    .frame(width: width - 48)
                    .landingSection(.doors)
                    .offset(x: 24, y: doorsTop * k)

                brief
                    .frame(width: width - 48, alignment: .leading)
                    .landingSection(.caption)
                    .offset(x: 24, y: briefTop * k)

                if let action {
                    LandingActionWord(action: action, accent: accent)
                        .landingSection(.foot)
                        .offset(x: 28, y: 786 * k - 8)
                }
            }
            .overlay(alignment: .leading) {
                if let onBack {
                    Color.clear.frame(width: 24)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 10).onEnded { value in
                            if value.translation.width > 50, abs(value.translation.height) < 80 {
                                onBack()
                            }
                        })
                }
            }
            .frame(width: width, height: proxy.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .background { ThemedBackground() }
    }

    private var titleText: some View {
        Text(title)
            .font(.custom("Figtree", size: 40, relativeTo: .largeTitle).weight(.bold))
            .foregroundStyle(accent)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .accessibilityAddTraits(.isHeader)
    }
}

extension FitLine {
    private static let small: Set<String> = [
        "and",
        "the",
        "a",
        "an",
        "of",
        "to",
        "by",
        "in",
        "on",
        "or",
        "for",
        "with",
        "at",
        "is",
    ]

    /// Words a cut never ends on: a line that stops on "opens", "around" or "this" says nothing (AX5 QA).
    private static let weak: Set<String> = [
        "opens", "open", "is", "are", "was", "were", "around", "about", "this", "next", "from", "until", "since",
        "than", "starts", "start", "last", "then", "so", "but", "your", "my", "his", "her",
    ]

    /// A bare number ("5", "12", "6:10", "82.5", "+10"), which never stands alone at the end of a cut.
    static func isNumber(_ word: String) -> Bool {
        let core = word.trimmingCharacters(in: CharacterSet(charactersIn: ",;:.!?()+-−°"))
        guard let first = core.unicodeScalars.first, CharacterSet.decimalDigits.contains(first) else { return false }
        return core.unicodeScalars
            .allSatisfy { CharacterSet.decimalDigits.contains($0) || ":.,".unicodeScalars.contains($0) }
    }

    /// Words grouped so a cut never splits them: a number travels with the word after it ("40 min", "5 lifts",
    /// "6:10 pm", "82.5 kg", "12 hours"), unless that word is a small one ("3 to go" keeps "3" apart).
    static func tokens(_ text: String) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        var tokens: [String] = []
        var index = 0
        while index < words.count {
            let word = words[index]
            let endsClause = word.last.map { ",;:.!?".contains($0) } ?? false
            if isNumber(word), !endsClause, index + 1 < words.count {
                let next = words[index + 1]
                let bare = next.lowercased().trimmingCharacters(in: .punctuationCharacters)
                if !small.contains(bare), !weak.contains(bare) {
                    tokens.append(word + " " + next)
                    index += 2
                    continue
                }
            }
            tokens.append(word)
            index += 1
        }
        return tokens
    }

    private static func bareLast(_ kept: [String]) -> String {
        let last = kept[kept.count - 1].split(separator: " ").last.map(String.init) ?? ""
        return last.lowercased().trimmingCharacters(in: .punctuationCharacters)
    }

    /// The longest form first, then every shorter whole-word cut: trailing small and weak words, lone numbers, commas
    /// and full stops are dropped, a number keeps its unit and a time its am or pm, so a fixed slot shows a clean
    /// shorter line, never "..." and never a fragment like "About 40 min, 5" or "Starts around 6:10".
    static func cuts(_ text: String) -> [String] {
        // Sentence case: a line starts with a capital ("cook at 6:45 pm" reads "Cook at 6:45 pm").
        let text = text.prefix(1).uppercased() + text.dropFirst()
        let tokens = tokens(text)
        guard tokens.count > 1 else { return [text] }
        var forms = [text]
        for count in stride(from: tokens.count - 1, through: 1, by: -1) {
            var kept = Array(tokens.prefix(count))
            while kept.count > 1 {
                let last = kept[kept.count - 1]
                let bare = bareLast(kept)
                if small.contains(bare) || weak.contains(bare) || (isNumber(last) && !last.contains(" ")) {
                    kept.removeLast()
                } else {
                    break
                }
            }
            if kept.count == 1 {
                // A form of one lone small, weak or number word says nothing.
                let only = kept[0]
                let bare = bareLast(kept)
                if small.contains(bare) || weak.contains(bare) || (isNumber(only) && !only.contains(" ")) {
                    continue
                }
            }
            let form = kept.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: ",;:.- "))
            if !form.isEmpty, !forms.contains(form) {
                forms.append(form)
            }
        }
        return forms
    }
}

/// One line of fixed width: the longest of `forms` that fits, never wrapped, never ellipsized. The last form is
/// the one the phone (or the on-device model) wrote short enough to always fit; it may step down to 0.8x.
struct FitLine: View {
    let forms: [String]
    var size: CGFloat = 16
    var color: Color = Theme.Colors.inkSecondary
    var weight: Font.Weight = .regular
    /// The face; Figtree unless a room writes in its own (Deck's door summary in Barlow Condensed).
    var family = "Figtree"
    /// The room's own short form: at accessibility sizes it is shown directly (contract §8: AX3 and up use the short
    /// form), instead of the longest cut that happens to fit.
    var short: String?
    /// At accessibility sizes, show the last of `forms` directly (a room that supplied its own forms, short last).
    var shortAtAccessibility = false

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize, let shown = short ?? (shortAtAccessibility ? forms.last : nil) {
            text(shown).lineLimit(1).minimumScaleFactor(0.5)
                .accessibilityLabel(forms.first ?? shown)
        } else {
            fitted
        }
    }

    private var fitted: some View {
        ViewThatFits(in: .horizontal) {
            ForEach(Array(forms.dropLast().enumerated()), id: \.offset) { _, form in text(form).fixedSize(
                horizontal: true,
                vertical: false
            ) }
            text(forms.last ?? "").lineLimit(1).minimumScaleFactor(0.5)
        }
        .accessibilityLabel(forms.first ?? "")
    }

    private func text(_ form: String) -> Text {
        Text(form).font(.custom(family, size: size, relativeTo: .body).weight(weight)).foregroundStyle(color)
    }
}
