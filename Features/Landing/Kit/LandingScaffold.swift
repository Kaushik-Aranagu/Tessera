import SwiftUI

/// The one landing layout of sheet 283 (Kaushik approved it Oct 25, 2:48 PM PDT): seven named sections in the same
/// place on Bridge and in every room. A room supplies content only. Positions are design points on 402 x 874; slots
/// keep their size and only the gaps scale on other screens.
///
/// Status bar 0-44 (the system's) · Masthead 44-182 · Keystone 196-378 · Caption 388 · Widget 400-612 · Doors 640
/// (dial x 24-184, summary x 186) · Foot (action word left, Tess right).
struct LandingScaffold<Keystone: View, Glyph: View>: View {
    let title: String
    let accent: Color
    /// The previous screen's name (15 pt 500 ink 2, right edge, top 56); tapping it goes back.
    var navWord: String?
    var onBack: (() -> Void)?
    var onTitle: (() -> Void)?
    var switcher: [String] = []
    var switcherVertical: [String] = []
    @Binding var switcherIndex: Int
    @Binding var switcherVerticalIndex: Int
    /// Two 15/24 lines at x 228, top 124; the first 600 ink. They change with the switcher.
    var needs: [String] = []
    @ViewBuilder let keystone: Keystone
    var caption: [String] = []
    let widget: [WidgetItem]
    @Binding var widgetIndex: Int
    var openWidget: (WidgetItem) -> Void = { _ in }
    var strikeWidget: (WidgetItem) -> Void = { _ in }
    @ViewBuilder let glyph: (WidgetItem) -> Glyph
    let doors: [DialDoor]
    @Binding var focus: Int
    var openDoor: (DialDoor) -> Void
    var action: LandingFootAction?
    var onSwitcherChange: () -> Void = {}
    /// The page behind the sections; nil is the theme's page colour. Lookout draws its sky here.
    var backdrop: AnyView?
    /// How the door summary changes when the dial turns (283 v6). nil keeps the environment's `doorSummaryStyle`
    /// (plain unless the room set one); a value sets that environment value for the summary.
    var summaryStyle: DoorSummaryStyle?

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { proxy in
            let k = max(0.86, min(1.1, proxy.size.height / 874))
            let width = proxy.size.width
            ZStack(alignment: .topLeading) {
                masthead(width: width, k: k)
                keystone
                    .frame(width: LandingKeystone<EmptyView>.size.width, height: LandingKeystone<EmptyView>.size.height)
                    .landingSection(.keystone)
                    .offset(x: (width - LandingKeystone<EmptyView>.size.width) / 2, y: 196 * k)
                if !caption.isEmpty {
                    FitLine(forms: caption, size: 15, color: Theme.Colors.inkSecondary)
                        .frame(width: width - 48, alignment: .leading)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .landingSection(.caption)
                        .offset(x: 24, y: 388 * k)
                }
                LandingWidget(items: widget, index: $widgetIndex, open: openWidget, strike: strikeWidget, glyph: glyph)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .landingSection(.widget)
                    .offset(x: 24, y: LandingWidget<Glyph>.top * k)
                DoorsDial(doors: doors, focus: $focus, open: openDoor, style: .landing)
                    .frame(width: 160)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .landingSection(.doors)
                    .offset(x: 24, y: 640 * k)
                DoorSummary(door: doors.isEmpty ? nil : doors[((focus % doors.count) + doors.count) % doors.count])
                    .modifier(SummaryStyleOverride(style: summaryStyle))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .landingSection(.doors)
                    .offset(x: 186, y: 652 * k)
                if let action {
                    LandingActionWord(action: action, accent: accent)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .landingSection(.foot)
                        .offset(x: 24, y: proxy.size.height - 22 - 64)
                }
                if let onBack {
                    Color.clear.frame(width: 24, height: proxy.size.height)
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
        .background {
            if let backdrop {
                backdrop.ignoresSafeArea()
            } else {
                ThemedBackground()
            }
        }
    }

    private func masthead(width: CGFloat, k: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let onTitle {
                    Button(action: onTitle) { titleText }.buttonStyle(.plain).accessibilityHint("Opens the index")
                } else {
                    titleText
                }
            }
            .frame(height: 56, alignment: .leading)
            .offset(x: 24, y: 54 * k - 8)
            if let navWord, let onBack {
                Button(action: onBack) {
                    Text(navWord)
                        .font(.custom("Figtree", size: 15, relativeTo: .callout).weight(.medium))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .fixedSize()
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to \(navWord)")
                .frame(width: 120, alignment: .trailing)
                .offset(x: width - 24 - 120, y: 56 * k - 12)
            }
            if !switcher.isEmpty {
                LandingSwitcher(across: switcher, vertical: switcherVertical, acrossIndex: $switcherIndex,
                                verticalIndex: $switcherVerticalIndex, changed: onSwitcherChange)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .offset(x: 24, y: 106 * k)
            }
            if !needs.isEmpty, !typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(needs.prefix(2).enumerated()), id: \.offset) { index, line in
                        FitLine(forms: FitLine.cuts(line), size: 15,
                                color: index == 0 ? Theme.Colors.ink : Theme.Colors.inkSecondary,
                                weight: index == 0 ? .semibold : .regular)
                            .frame(width: 150, height: 24, alignment: .leading)
                    }
                }
                .frame(width: 150, alignment: .leading)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .offset(x: 228, y: 124 * k)
                .id(switcherIndex)
            }
        }
        .frame(width: width, height: 182 * k, alignment: .topLeading)
        .landingSection(.masthead)
    }

    private var titleText: some View {
        Text(title)
            .font(.custom("Figtree", size: 40, relativeTo: .largeTitle).weight(.bold))
            .foregroundStyle(accent)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Sets `doorSummaryStyle` only when the scaffold was given one, so a room's own environment value stands otherwise.
private struct SummaryStyleOverride: ViewModifier {
    let style: DoorSummaryStyle?

    func body(content: Content) -> some View {
        if let style {
            content.environment(\.doorSummaryStyle, style)
        } else {
            content
        }
    }
}
