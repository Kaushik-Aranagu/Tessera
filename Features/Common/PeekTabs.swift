import SwiftUI

/// Named pages you swipe between, with the neighbours peeking (Design sheet 108). The current tab's name sits in the
/// middle at body size, 600; up to two neighbours on each side at label size in 38% ink, blurred (or crisp) by the
/// Review switch "Tab neighbours"; a 28 x 5 ink bar under the current name. A swipe on the tab row or the page moves
/// one tab; a tap on a neighbour goes to it. Reduce Motion: a 150 ms crossfade. At accessibility sizes only the
/// current name shows, with "next: <name>" under it. Shared: Settings › Review now, Plans and Exercise next.
struct PeekTabs<Content: View>: View {
    let tabs: [String]
    @Binding var selection: Int
    /// A page turn style other than Today: one page shows at a time and turns in that style (the content plays it,
    /// e.g. through `PageTurnRows`); a side swipe on the page still moves one tab. Nil or Today: pages slide as now.
    var turns: PageTurnStyle?
    @ViewBuilder var content: (Int) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var scrolled: Int?
    /// Each tab word's drawn width, for the measured layout.
    @State private var widths: [Int: CGFloat] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if typeSize.isAccessibilitySize {
                accessibleRow
            } else {
                tabRow
            }
            pages
        }
        .onAppear { scrolled = selection }
        .onChange(of: selection) { _, new in
            guard scrolled != new else { return }
            withTesseraAnimation(reduceMotion: reduceMotion) { scrolled = new }
        }
        .onChange(of: scrolled) { _, new in
            if let new, new != selection {
                selection = new
            }
        }
        .tesseraFeedback(.selection, trigger: selection)
    }

    // MARK: The row

    private var tabRow: some View {
        GeometryReader { proxy in
            let mid = proxy.size.width / 2
            ZStack {
                // Each word sits a fixed gap from its neighbour, measured, with the current one centred, so a long
                // name never runs into the next (sheet 108).
                let centers = PeekTabsLayout.centers(widths: tabs.indices.map { widths[$0] ?? 0 }, selection: selection)
                ForEach(tabs.indices, id: \.self) { index in
                    let distance = index - selection
                    tabWord(index, distance: distance)
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { widths[index] = $0 }
                        .position(x: mid + centers[index], y: 18)
                        .opacity(abs(distance) <= 2 ? 1 : 0)
                        .accessibilityHidden(abs(distance) > 2)
                }
                Capsule(style: .continuous)
                    .fill(Theme.Colors.ink)
                    .frame(width: 28, height: 5)
                    .position(x: mid, y: 40)
                    .accessibilityHidden(true)
            }
            .tesseraAnimation(value: selection)
            // Hidden until every word is measured, so no frame shows them stacked (Design on #1137).
            .opacity(widths.count == tabs.count ? 1 : 0)
        }
        .frame(height: 48)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 24).onEnded { drag in
            guard abs(drag.translation.width) > abs(drag.translation.height) else { return }
            step(drag.translation.width < 0 ? 1 : -1)
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PeekTabsCopy.spoken(tabs, selection))
        .accessibilityAddTraits(.isHeader)
        .accessibilityAdjustableAction { direction in
            step(direction == .increment ? 1 : -1)
        }
    }

    private func tabWord(_ index: Int, distance: Int) -> some View {
        let current = distance == 0
        // Kaushik's pick (4:38 PM): neighbours blurred by default; crisp under Reduce Transparency or the Crisp switch.
        let blurred = !current && !reduceTransparency
            && ReviewChoices.shared.value(of: "tabs.neighbours") != "Crisp"
        return Button { go(index) } label: {
            Text(tabs[index])
                .font(current ? Theme.Typography.font(Theme.concept.scale.body, weight: .semibold)
                    : Theme.Typography.font(PeekTabsLayout.neighbourSpec))
                .foregroundStyle(Theme.Colors.ink.opacity(current ? 1 : 0.38))
                .lineLimit(1)
                .fixedSize()
                .blur(radius: blurred ? 1.6 : 0)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .disabled(current)
    }

    /// At accessibility sizes: the current name, then "next: Workout" as a word that goes there.
    private var accessibleRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(tabs[selection])
                .textRole(.bodyStrong)
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            if let next = PeekTabsCopy.next(tabs, selection) {
                Button(next) { step(1) }
                    .buttonStyle(.labelWord(Theme.Colors.inkSecondary))
                    .frame(minHeight: 44)
            }
        }
        .accessibilityAdjustableAction { direction in
            step(direction == .increment ? 1 : -1)
        }
    }

    // MARK: The pages

    @ViewBuilder private var pages: some View {
        if reduceMotion || PowerState.isLowPower {
            // Reduce Motion or Low Power: the page cuts with a 150 ms crossfade, never slides (Design on #1137), and a
            // side swipe still steps a tab (QA on #1184).
            inPlace(content(selection)
                .id(selection)
                .transition(.opacity.animation(PageTurnTiming.reduced)))
        } else if let turns, turns != .today {
            // One page at a time, turning in place: the content sees the new index and plays the turn.
            inPlace(content(selection))
        } else {
            slidingPages
        }
    }

    /// A page that stays put while a side swipe steps the tab. The swipe runs alongside the scroll, so a vertical drag
    /// from a row still scrolls Settings (Design on #1184).
    private func inPlace(_ page: some View) -> some View {
        ScrollView(.horizontal) {
            page
                .containerRelativeFrame(.horizontal)
                .contentShape(Rectangle())
        }
        .scrollBounceBehavior(.always, axes: .horizontal)
        .scrollIndicators(.hidden)
        .simultaneousGesture(sideSwipe)
        // The zoomed cover Review sits in closes on a pan in any direction; while pages turn in place, a side swipe
        // is the tab's, so the cover closes by its Close word (#1184).
        .interactiveDismissDisabled()
        .accessibilityElement(children: .contain)
    }

    /// A clearly sideways drag steps one tab; anything more vertical is left to the scroll.
    private var sideSwipe: some Gesture {
        DragGesture(minimumDistance: 24).onEnded { value in
            guard PeekTabsLayout.isSideSwipe(value.translation) else { return }
            step(value.translation.width < 0 ? 1 : -1)
        }
    }

    private var slidingPages: some View {
        ScrollView(.horizontal) {
            // A plain stack (a handful of pages): the pager is as tall as its tallest page, so every tab shows all
            // its rows (Builder A's clip on #1173: Cook notes was cut under a three-row first page).
            HStack(alignment: .top, spacing: 0) {
                ForEach(tabs.indices, id: \.self) { index in
                    content(index)
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                            view.opacity(phase.isIdentity ? 1 : 0.25)
                        }
                        .accessibilityElement(children: .contain)
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolled)
        .scrollIndicators(.hidden)
    }

    // MARK: Moving

    private func step(_ offset: Int) {
        go(selection + offset)
    }

    private func go(_ index: Int) {
        let target = min(max(index, 0), tabs.count - 1)
        guard target != selection else { return }
        withTesseraAnimation(reduceMotion: reduceMotion) {
            selection = target
            scrolled = target
        }
    }
}

/// Where the names sit: the current one centred, neighbours a fixed share of the width out, two on each side.
enum PeekTabsLayout {
    /// Label size in the UI face: the neighbours' size (sheet 108).
    static var neighbourSpec: ThemeConcept.TypeSpec {
        var spec = Theme.concept.scale.body
        spec.size = Theme.concept.scale.label.size
        spec.weight = .regular
        return spec
    }

    /// A drag that steps a tab: more than 40 pt sideways and at least twice as wide as it is tall.
    static func isSideSwipe(_ translation: CGSize) -> Bool {
        abs(translation.width) > 40 && abs(translation.width) >= 2 * abs(translation.height)
    }

    /// The space between two tab words.
    static let gap: CGFloat = 22

    /// Each word's centre relative to the current word's centre, from the words' drawn widths: neighbours sit `gap`
    /// apart edge to edge, so nothing overlaps whatever the names' lengths.
    static func centers(widths: [CGFloat], selection: Int) -> [CGFloat] {
        guard widths.indices.contains(selection) else { return widths.map { _ in 0 } }
        var centers = Array(repeating: CGFloat(0), count: widths.count)
        var edge = widths[selection] / 2
        for index in (selection + 1) ..< widths.count {
            centers[index] = edge + gap + widths[index] / 2
            edge = centers[index] + widths[index] / 2
        }
        edge = -widths[selection] / 2
        for index in stride(from: selection - 1, through: 0, by: -1) {
            centers[index] = edge - gap - widths[index] / 2
            edge = centers[index] - widths[index] / 2
        }
        return centers
    }
}

enum PeekTabsCopy {
    /// "Workout, tab 2 of 5".
    static func spoken(_ tabs: [String], _ selection: Int) -> String {
        guard tabs.indices.contains(selection) else { return "" }
        return "\(tabs[selection]), tab \(selection + 1) of \(tabs.count)"
    }

    /// "next: Kitchen", or nil on the last tab.
    static func next(_ tabs: [String], _ selection: Int) -> String? {
        tabs.indices.contains(selection + 1) ? "next: \(tabs[selection + 1])" : nil
    }
}
