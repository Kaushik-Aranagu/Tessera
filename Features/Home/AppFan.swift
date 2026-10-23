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
    /// The page's words while the fan is open: ink 3's own alpha from the Theme (never a number of its own).
    @MainActor static func pageDim(isDark: Bool) -> Double {
        Theme.Colors.inkTertiaryAlpha(isDark: isDark)
    }

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

/// What the pull is doing. The gesture lives on the page (so the dock, the write line and Tess's corner keep every
/// tap);
/// the layer only draws this.
@Observable
@MainActor
final class FanState {
    var pull: CGFloat = 0
    var sticky = false

    var open: Bool {
        FanMath.isOpen(pull: pull) || sticky
    }

    func close() {
        sticky = false
        pull = 0
    }
}

/// Puts the fan on a page: a pull that begins in the bottom strip draws the layer; nothing is laid over the strip, so
/// taps still reach what is under it. The identity with the switch Off.
struct FanHost: ViewModifier {
    let entries: [AppFanEntry]
    let onPick: (Int) -> Void
    let onOpenIndex: () -> Void
    @State private var state = FanState()
    @State private var height: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        if FanSwitch.isOn {
            content
                // The page's own words go to ink 3 while the fan is open (no veil over it), on the house spring.
                .opacity(state.open ? FanMath.pageDim(isDark: scheme == .dark) : 1)
                .tesseraAnimation(Theme.Motion.house, value: state.open)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8, coordinateSpace: .local)
                        .onChanged { value in
                            guard !state.sticky,
                                  FanMath.begins(atDistanceFromBottom: height - value.startLocation.y) else { return }
                            state.pull = max(0, -value.translation.height)
                        }
                        .onEnded { value in
                            guard !state.sticky,
                                  FanMath.begins(atDistanceFromBottom: height - value.startLocation.y) else { return }
                            let final = max(0, -value.translation.height)
                            if typeSize.isAccessibilitySize {
                                // A scroll of label-size titles: it stays open for a tap.
                                state.sticky = FanMath.isOpen(pull: final)
                                state.pull = 0
                            } else if let index = FanMath.release(pull: final, count: entries.count) {
                                state.pull = 0
                                onPick(index)
                            } else {
                                state.close()
                            }
                        }
                )
                .overlay(alignment: .bottom) {
                    AppFan(entries: entries, state: state, onPick: onPick)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Apps")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { onOpenIndex() }
                }
        } else {
            content
        }
    }
}

extension View {
    /// Design 137, the fan, behind the Review switch `homeV2` (Off: nothing changes).
    func appFan(entries: [AppFanEntry], onPick: @escaping (Int) -> Void,
                onOpenIndex: @escaping () -> Void) -> some View
    {
        modifier(FanHost(entries: entries, onPick: onPick, onOpenIndex: onOpenIndex))
    }
}

/// The fan's layer: the dim and the rising titles. It takes no touch unless it is held open (accessibility sizes).
struct AppFan: View {
    let entries: [AppFanEntry]
    let state: FanState
    let onPick: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    private var open: Bool {
        state.open
    }

    private var focused: Int? {
        state.sticky ? nil : FanMath.index(under: state.pull, count: entries.count)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Held open (accessibility sizes), a tap anywhere else closes it; there is no veil.
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .allowsHitTesting(state.sticky)
                .onTapGesture { state.close() }
            list
        }
        .tesseraAnimation(value: open)
        // A selection tick when the finger moves onto a title; none when the fan closes.
        .sensoryFeedback(.selection, trigger: focused) { _, new in new != nil }
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
                .allowsHitTesting(state.sticky)
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
                        // The one under the finger takes its accent; the others drop to ink 3.
                        .foregroundStyle(isFocused ? entry
                            .accent : (focused == nil ? Theme.Colors.ink : Theme.Colors.inkTertiary))
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
        .tesseraAnimation(Theme.Motion.house.delay(shown ? delay : 0), value: shown)
        .tesseraAnimation(.snappy(duration: 0.18), value: isFocused)
        .accessibilityHidden(true)
    }

    private func pick(_ index: Int) {
        state.close()
        onPick(index)
    }
}
