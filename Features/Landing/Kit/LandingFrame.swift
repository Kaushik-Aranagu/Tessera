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
        .ignoresSafeArea(.container, edges: .top)
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
    private static let small: Set<String> = ["and", "the", "a", "an", "of", "to", "by", "in", "on", "or", "for", "with", "at", "is"]

    /// The longest form first, then every shorter whole-word cut: trailing small words, commas and full stops are
    /// dropped, so a fixed slot shows a clean shorter line, never "...".
    static func cuts(_ text: String) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        guard words.count > 1 else { return [text] }
        var forms = [text]
        for count in stride(from: words.count - 1, through: 1, by: -1) {
            var kept = Array(words.prefix(count))
            while kept.count > 1, small.contains(kept[kept.count - 1].lowercased().trimmingCharacters(in: .punctuationCharacters)) {
                kept.removeLast()
            }
            let form = kept.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: ",;:.-"))
            if !form.isEmpty, form != forms.last { forms.append(form) }
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

    var body: some View {
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
        Text(form).font(.custom("Figtree", size: size, relativeTo: .body).weight(weight)).foregroundStyle(color)
    }
}
