import SwiftUI

// Design 137, "the fan": pull up from the bottom edge and the apps rise as words, each with its live line. The word
// under the finger grows and takes its app's accent; let go on one to open it, let go low to close the fan.

/// The Review switch behind the fan (Settings > Review > Home v2), default Off.
enum FanSwitch {
    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: "homeV2") == "On"
    }
}

/// The fan's geometry, pure so it can be tested. A pull is how far the finger has moved up from where it started.
enum FanMath {
    /// The pull that opens the fan and the first title's place: under it, a release closes.
    static let threshold: CGFloat = 24
    /// The drag must begin this close to the bottom edge.
    static let startZone: CGFloat = 40
    /// Distance between two titles.
    static let step: CGFloat = 76
    static let titleSize: CGFloat = 30
    static let focusedSize: CGFloat = 40
    static let rise: CGFloat = 30
    static let stagger: Double = 0.035

    static func isOpen(pull: CGFloat) -> Bool {
        pull > threshold
    }

    static func begins(atDistanceFromBottom distance: CGFloat) -> Bool {
        distance >= 0 && distance <= startZone
    }

    /// Titles stack bottom up: the lowest (the last area) sits just above the threshold, and each `step` of pull
    /// reaches the title above it. Nil when the pull is under the threshold (below the first title).
    static func index(under pull: CGFloat, count: Int) -> Int? {
        guard count > 0, isOpen(pull: pull) else { return nil }
        let above = Int(((pull - threshold) / step).rounded(.down))
        return max(0, count - 1 - above)
    }

    /// The area a release picks: the one under the finger, nothing (close) below the first title.
    static func release(pull: CGFloat, count: Int) -> Int? {
        index(under: pull, count: count)
    }

    /// The stagger of a title's rise: the lowest rises first.
    static func delay(row: Int, count: Int) -> Double {
        Double(max(0, count - 1 - row)) * stagger
    }
}

struct AppFanEntry: Identifiable {
    let id: Int
    let title: String
    let line: String
    let accent: Color
}

/// The fan's layer: the bottom strip that takes the pull, the dim and the rising titles.
struct AppFan: View {
    let entries: [AppFanEntry]
    let onPick: (Int) -> Void
    let onOpenIndex: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var pull: CGFloat = 0
    @State private var sticky = false

    private var open: Bool {
        FanMath.isOpen(pull: pull) || sticky
    }

    private var focused: Int? {
        sticky ? nil : FanMath.index(under: pull, count: entries.count)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // The page dims toward ink 3.
            Theme.Colors.paper
                .opacity(open ? 0.9 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(sticky)
                .onTapGesture { close() }
                .accessibilityHidden(true)
            list
            strip
        }
        .tesseraAnimation(value: open)
        .sensoryFeedback(.selection, trigger: focused)
    }

    @ViewBuilder
    private var list: some View {
        let rows = VStack(alignment: .leading, spacing: 0) {
            ForEach(entries) { entry in
                row(entry)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.bottom, FanMath.threshold + 20)
        if typeSize.isAccessibilitySize {
            ScrollView { rows.padding(.top, Theme.Spacing.xl) }
                .scrollIndicators(.hidden)
                .opacity(open ? 1 : 0)
                .allowsHitTesting(sticky)
        } else {
            rows.allowsHitTesting(false)
        }
    }

    private func row(_ entry: AppFanEntry) -> some View {
        let isFocused = focused == entry.id
        let delay = FanMath.delay(row: entry.id, count: entries.count)
        let shown = open
        return Button { pick(entry.id) } label: {
            VStack(alignment: .leading, spacing: 2) {
                if typeSize.isAccessibilitySize {
                    Text(entry.title).textRole(.label).foregroundStyle(Theme.Colors.ink)
                } else {
                    Text(entry.title)
                        .font(Theme.Typography.face(Theme.activeFonts.ui,
                                                    size: isFocused ? FanMath.focusedSize : FanMath.titleSize,
                                                    relativeTo: .title, serif: false)
                                .weight(.medium))
                        .foregroundStyle(isFocused ? entry.accent : Theme.Colors.ink)
                        .lineLimit(1)
                }
                Text(entry.line)
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: FanMath.step, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(shown ? 1 : 0)
        .offset(y: shown || reduceMotion ? 0 : FanMath.rise)
        .animation(reduceMotion ? MotionPolicy.reducedMotionFade
            : Theme.Motion.house.delay(shown ? delay : 0), value: shown)
        .tesseraAnimation(.snappy(duration: 0.18), value: isFocused)
        .accessibilityHidden(true)
    }

    /// The bottom 40 pt: the only place a pull can begin, so it never fights the pager or a page's own scroll.
    private var strip: some View {
        Color.clear
            .frame(height: FanMath.startZone)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard !sticky else { return }
                        pull = max(0, -value.translation.height)
                    }
                    .onEnded { value in
                        let final = max(0, -value.translation.height)
                        if typeSize.isAccessibilitySize {
                            // A scroll of label-size titles: it stays open for a tap.
                            sticky = FanMath.isOpen(pull: final)
                            pull = 0
                        } else if let index = FanMath.release(pull: final, count: entries.count) {
                            pull = 0
                            onPick(index)
                        } else {
                            close()
                        }
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("Apps")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onOpenIndex() }
    }

    private func pick(_ index: Int) {
        sticky = false
        pull = 0
        onPick(index)
    }

    private func close() {
        sticky = false
        pull = 0
    }
}
