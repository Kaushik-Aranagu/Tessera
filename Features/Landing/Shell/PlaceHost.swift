import SwiftUI

/// One persistent place of the shell. It is created once and never torn down; it renders whatever content it is
/// handed with `.id(content.id)` and its own transition, so SwiftUI's insertion and removal drive the swap. Nil
/// content keeps the place, empty and touch-free.
struct PlaceHost: View {
    let place: Place
    let content: SlotContent?
    let style: PlaceStyle
    let size: CGSize
    let reduceMotion: Bool
    let navigator: ShellNavigator
    let act: (ShellIntent) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let content {
                PlaceRenderer(place: place, content: content, style: style, size: size, reduceMotion: reduceMotion,
                              navigator: navigator, act: act)
                    .id(content.id)
                    .transition(PlaceTransition.make(place, style, reduceMotion: reduceMotion))
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}

/// Draws one piece of content in its place, reusing the landing kit's views (sheet 283).
private struct PlaceRenderer: View {
    let place: Place
    let content: SlotContent
    let style: PlaceStyle
    let size: CGSize
    let reduceMotion: Bool
    let navigator: ShellNavigator
    let act: (ShellIntent) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.shellGlyphRoom) private var glyphRoom

    var body: some View {
        switch content.payload {
        case let .title(text, accent):
            FitLine(forms: FitLine.cuts(text), size: 40, color: accent, weight: .bold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .frame(width: size.width, height: size.height, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
        case let .navWord(word):
            Button { act(.back) } label: {
                Text(word)
                    .font(.custom("Figtree", size: 15, relativeTo: .callout).weight(.medium))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .fixedSize()
                    // The word's right edge lines up with the page's 24 pt margin (x 378), never flush on the edge.
                    .frame(width: size.width - 16, height: size.height, alignment: .trailing)
                    .frame(width: size.width, height: size.height, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .accessibilityLabel("Back to \(word)")
        case let .lines(lines):
            linesView(lines)
        case let .switcher(across, vertical):
            LandingSwitcher(across: across, vertical: vertical,
                            acrossIndex: navigator.binding(\.switcherIndex),
                            verticalIndex: navigator.binding(\.switcherVerticalIndex))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityIdentifier("shell.switcher")
        case let .wall(words, label):
            ShellKeystone(words: words, label: label, act: act)
        case let .scene(key, label):
            if place == .keystone {
                ShellSceneKeystone(key: key, label: label)
            } else {
                // Any other place drawn by the room itself (Bridge's board, one-thing box, apps dial, undo line).
                ShellScenePlace(key: key)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
            }
        case let .widget(items):
            LandingWidget(items: items, index: navigator.binding(\.widgetIndex),
                          open: { act(.openItem($0.id)) }, strike: { act(.done($0.id)) }, glyph: { _ in Color.clear })
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        case let .glyph(item, color):
            LandingGlyph(item: item, color: color, formDelay: style.context == .merge ? 0.05 : 0.33, room: glyphRoom)
        case let .dial(doors):
            ShellDial(doors: doors, reelFrom: reduceMotion ? [] : style.reelFrom, navigator: navigator, act: act)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        case let .summary(door):
            DoorSummary(door: door, ownMove: false)
                .padding(.top, 12)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        case let .doorTitle(name, line, color):
            doorTitle(name: name, line: line, color: color)
        case let .list(rows):
            ShellPage(rows: rows, settle: style.context != .state, reduceMotion: reduceMotion,
                      start: style.context == .route ? 0.2 : 0, act: act)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        case let .action(steps, accent):
            LandingActionWord(action: footAction(steps), accent: accent,
                              arrival: style.context == .route && style.move != .untouched ? 0.42 : nil)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        }
    }

    /// Needs: two 15/24 lines, the first 600 ink (hidden at accessibility sizes, as on the scaffold). The caption: one
    /// 15 pt ink 2 line on how to touch the keystone.
    @ViewBuilder
    private func linesView(_ lines: [String]) -> some View {
        if place == .needs {
            if !typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.prefix(2).enumerated()), id: \.offset) { index, line in
                        FitLine(forms: FitLine.cuts(line), size: 15,
                                color: index == 0 ? Theme.Colors.ink : Theme.Colors.inkSecondary,
                                weight: index == 0 ? .semibold : .regular)
                            .frame(width: size.width, height: 24, alignment: .leading)
                    }
                }
                .padding(.top, 6)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        } else {
            FitLine(forms: FitLine.cuts(lines.first ?? ""), size: 15, color: Theme.Colors.inkSecondary)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .frame(width: size.width, height: size.height, alignment: .leading)
        }
    }

    /// The Door title, made from the Switcher and Needs: the door's name in the switcher's own type (Figtree 300 38)
    /// with one 15 pt line under it.
    private func doorTitle(name: String, line: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FitLine(forms: FitLine.cuts(name), size: 38, color: color, weight: .light)
                .frame(height: 46, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("shell.doorTitle")
            FitLine(forms: FitLine.cuts(line), size: 15, color: Theme.Colors.inkSecondary, weight: .medium)
                .frame(height: 24, alignment: .leading)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func footAction(_ steps: [ShellStep]) -> LandingFootAction {
        let first = steps.first ?? ShellStep(id: "", verb: "")
        let alternates = steps.dropFirst().map { step in
            LandingFootAction.Step(verb: step.verb, object: step.object, hold: step.hold) { act(.action(step.id)) }
        }
        return LandingFootAction(word: first.verb, object: first.object, hold: first.hold, hint: first.object,
                                 alternates: Array(alternates)) { act(.action(first.id)) }
    }
}

/// The keystone place holding the word wall. Under the simulator's `-shellProbe` it also shows a token made once per
/// view identity, so a UI test can tell the keystone was kept (same token) from recreated (a new one).
private struct ShellKeystone: View {
    let words: [WallWord]
    let label: String
    let act: (ShellIntent) -> Void

    @State private var token = String(UUID().uuidString.prefix(8))

    var body: some View {
        LandingKeystone(label: label) {
            WordWallView(words: words) { act(.openItem($0)) }
        }
        .overlay(alignment: .topLeading) {
            if ShellProbe.enabled {
                Text(token)
                    .font(.system(size: 1))
                    .opacity(0.02)
                    .frame(width: 2, height: 2)
                    .accessibilityIdentifier("shell.keystone.token")
                    .accessibilityLabel(token)
            }
        }
    }
}

/// The keystone place holding a room's own drawing: the room's host renders `key` through `shellScene`. The same
/// key on both sides keeps the view (and its state), as the word wall does. A probe token, as on `ShellKeystone`.
private struct ShellSceneKeystone: View {
    let key: String
    let label: String

    @Environment(\.shellScene) private var scene
    @State private var token = String(UUID().uuidString.prefix(8))

    var body: some View {
        LandingKeystone(label: label) {
            scene(key)
        }
        .overlay(alignment: .topLeading) {
            if ShellProbe.enabled {
                Text(token)
                    .font(.system(size: 1))
                    .opacity(0.02)
                    .frame(width: 2, height: 2)
                    .accessibilityIdentifier("shell.keystone.token")
                    .accessibilityLabel(token)
            }
        }
    }
}

/// The dial place: the landing dial bound to the navigator's focus, with the reel over it when the doors change.
private struct ShellDial: View {
    let doors: [DialDoor]
    let reelFrom: [String]
    let navigator: ShellNavigator
    let act: (ShellIntent) -> Void

    @State private var shown = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            DoorsDial(
                doors: doors,
                focus: navigator.binding(\.dialFocus),
                open: { act(.openDoor($0.id)) },
                style: .landing
            )
            .frame(width: 160)
            .opacity(reelFrom.isEmpty || shown ? 1 : 0)
            if !reelFrom.isEmpty {
                DialReel(from: reelFrom, to: doors.map(\.name))
            }
        }
        .onAppear {
            guard !reelFrom.isEmpty else { return }
            withAnimation(MotionPolicy.resolve(
                .easeOut(duration: 0.14).delay(ShellTiming.reel - 0.14),
                reduceMotion: false
            )) {
                shown = true
            }
        }
    }
}

/// The Page, made from the Widget, Glyph, Dial and Door summary: a door's own list, newest first. Rows settle in
/// from the top down (30 ms apart); a private row never shows its note's words.
private struct ShellPage: View {
    let rows: [ShellRow]
    let settle: Bool
    let reduceMotion: Bool
    let start: Double
    let act: (ShellIntent) -> Void

    @State private var settled = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    ShellPageRow(row: row, act: act) { rowView(row) }
                        .offset(y: settled || !settle ? 0 : -10)
                        .opacity(settled || !settle ? 1 : 0)
                        .animation(rowAnimation(index), value: settled)
                        .accessibilityLabel(row.detail.isEmpty ? row.title : "\(row.title), \(row.detail)")
                }
            }
        }
        .scrollIndicators(.hidden)
        .onAppear { settled = true }
    }

    private func rowAnimation(_ index: Int) -> Animation? {
        guard settle else { return nil }
        let delay = start + Double(min(index, ShellTiming.rowsShown)) * ShellTiming.rowStagger
        return MotionPolicy.resolve(.timingCurve(0.2, 0.8, 0.2, 1, duration: ShellTiming.rowSeconds).delay(delay),
                                    reduceMotion: reduceMotion)
    }

    private func rowView(_ row: ShellRow) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FitLine(forms: FitLine.cuts(row.title), size: 20,
                    color: row.isPrivate ? Theme.Colors.inkSecondary : Theme.Colors.ink, weight: .medium)
            if !row.detail.isEmpty {
                FitLine(forms: FitLine.cuts(row.detail), size: 13, color: Theme.Colors.inkSecondary)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// The simulator's test probes (`-shellProbe`): never on the phone (LaunchFlags is simulator-only).
enum ShellProbe {
    static let enabled = LaunchFlags.has("-shellProbe")
    /// `-shellReduceMotion` plays the shell's Reduce Motion path without changing the simulator's settings.
    static let reduceMotion = LaunchFlags.has("-shellReduceMotion")
}

/// A place drawn by its room through `shellScene`, at the place's origin (not clipped: Bridge's board rides above its
/// place, as on the page).
private struct ShellScenePlace: View {
    let key: String

    @Environment(\.shellScene) private var scene

    var body: some View {
        scene(key)
    }
}

/// One row of a door page. A tap opens it; a row that can be swiped follows the finger and, through GestureKit's one
/// policy, a swipe right is Done (or starts it) and a swipe left is Not now.
private struct ShellPageRow<Label: View>: View {
    let row: ShellRow
    let act: (ShellIntent) -> Void
    @ViewBuilder let label: () -> Label

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pull: CGFloat = 0
    @State private var swiped = false
    @State private var cue = HapticCue()

    var body: some View {
        let button = Button {
            guard !swiped else { return }
            act(.openItem(row.id))
        } label: { label() }
            .buttonStyle(.plain)
        if row.swipe {
            button
                .offset(x: pull)
                .rowSwipe(.both, limit: 150) { event in swipe(event) }
                .tesseraFeedback(cue)
                .accessibilityAction(named: "Done") { act(.done(row.id)) }
                .accessibilityAction(named: "Not now") { act(.notNow(row.id)) }
                .accessibilityIdentifier("shell.row.\(row.id)")
        } else {
            button
        }
    }

    private func swipe(_ event: RowSwipeEvent) {
        switch event {
        case let .pulled(value):
            swiped = true
            pull = value
        case let .committed(side):
            cue.play(side == .leading ? .done : .selection)
            act(side == .leading ? .done(row.id) : .notNow(row.id))
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pull = 0 }
        case .cancelled:
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pull = 0 }
        case .ended:
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                swiped = false
            }
        case .armed, .disarmed:
            break
        }
    }
}
