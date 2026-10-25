import SwiftUI

/// The one fixed landing frame (landing contract §1): header, keystone slot, doors dial, brief, foot, all placed on
/// the 402 x 874 frame. Slots keep their size; only the gaps scale on other screens. No ScrollView.
struct LandingFrame<Keystone: View, Brief: View>: View {
    let title: String
    let accent: Color
    /// One line, longest form first; the frame shows the longest that fits and never wraps or ellipsizes.
    let stateLine: [String]
    var onTitle: (() -> Void)?
    @ViewBuilder let keystone: Keystone
    let doors: [DialDoor]
    @Binding var focus: Int
    var openDoor: (DialDoor) -> Void
    @ViewBuilder let brief: Brief
    var action: LandingFootAction?

    static var designHeight: CGFloat { 874 }

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
                .offset(x: 24, y: 54 * k - 8)

                FitLine(forms: stateLine, size: 16, color: Theme.Colors.inkSecondary)
                    .frame(width: width - 48, alignment: .leading)
                    .offset(x: 24, y: 112 * k)

                keystone
                    .frame(width: slot.width, height: slot.height)
                    .offset(x: (width - slot.width) / 2, y: 180 * k)

                DoorsDial(doors: doors, focus: $focus, open: openDoor)
                    .frame(width: width - 48)
                    .offset(x: 24, y: 432 * k)

                brief
                    .frame(width: width - 48, alignment: .leading)
                    .offset(x: 24, y: 612 * k)

                if let action {
                    LandingActionWord(action: action, accent: accent)
                        .offset(x: 28, y: 786 * k - 8)
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

/// One line of fixed width: the longest of `forms` that fits, never wrapped, never ellipsized. The last form is
/// the one the phone (or the on-device model) wrote short enough to always fit; it may step down to 0.8x.
struct FitLine: View {
    let forms: [String]
    var size: CGFloat = 16
    var color: Color = Theme.Colors.inkSecondary
    var weight: Font.Weight = .regular

    var body: some View {
        ViewThatFits(in: .horizontal) {
            ForEach(Array(forms.dropLast().enumerated()), id: \.offset) { _, form in text(form).fixedSize(horizontal: true, vertical: false) }
            text(forms.last ?? "").lineLimit(1).minimumScaleFactor(0.8)
        }
        .accessibilityLabel(forms.first ?? "")
    }

    private func text(_ form: String) -> Text {
        Text(form).font(.custom("Figtree", size: size, relativeTo: .body).weight(weight)).foregroundStyle(color)
    }
}
