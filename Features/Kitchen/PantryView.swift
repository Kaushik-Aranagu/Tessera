import SwiftUI
import TesseraCore

/// Pantry's front (sheet 78; pantry-acceptance.md): what is out and what is low, and nothing else. The page frame
/// (Title 44, then the context, then the hero in digits) until Product rules the area entry. OUT, then LOW, each
/// thing one plain line with its state word at the right; out lines carry the recipe page's faint ring. A thing that
/// becomes in leaves the page. A name opens its ingredient (a private one opens nothing); a left swipe on a line
/// adds it to Groceries. Tess's band carries what the last cook used up. Never a badge, a notification or a total,
/// and nothing leaves the phone.
///
/// Waiting on Core: USUALLY HAVE (Research R), the tap-to-cycle state words (a stored `Ingredient.state`), and the
/// OUT AND LOW side (SideHost).
struct PantryView: View {
    var body: some View {
        NavigationStack {
            PantryPage()
                .navigationDestination(for: Route.self) { ObjectPage(route: $0) }
        }
        .environment(\.animateEntrance, true)
    }
}

private struct PantryPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var ledger: PantryLedger {
        PantryLedger(store: model.store, classes: model.classes)
    }

    var body: some View {
        let _ = model.revision
        let front = PantryFront(ledger: ledger, now: AppClock.now)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Pantry")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(0)
                if let context = front.context {
                    Text(context)
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.context)
                        .padding(.top, Theme.Spacing.s)
                        .entrance(1)
                }
                Text(front.hero)
                    .textRole(.hero)
                    .wordFit(front.hero)
                    .foregroundStyle(Theme.Colors.ink)
                    .contentTransition(.identity)
                    .padding(.top, Theme.Spacing.xs)
                    .entrance(1)
                if front.isEmpty {
                    Text(PantryCopy.emptyBody)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.l)
                        .entrance(2)
                }
                ForEach([(PantryLedger.State.out, front.out), (.low, front.low)], id: \.0) { state, lines in
                    if !lines.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(state.word.uppercased())
                                .textRole(.labelStrong)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.bottom, Theme.Spacing.s)
                            ForEach(lines) { entry in
                                PantryLine(entry: entry, onAdd: { add(entry) })
                            }
                        }
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(2)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.l)
            .tesseraAnimation(value: (front.out + front.low).map(\.id))
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { speak(front) }
    }

    /// Her band: what the last cook used up.
    private func speak(_ front: PantryFront) {
        // Never over an open UNDO: that line keeps its window (QA L2 on #727).
        if let note = TessVoice.shared.note, note.undo != nil || note.takeBack != nil {
            return
        }
        // An empty page has no Tess line until Core's grammar reads "out of milk" (Product).
        if let tess = front.tess {
            TessVoice.shared.say(tess)
        }
    }

    /// A left swipe: onto Groceries as a new line, "Milk, on Groceries." with UNDO 4 s (a new add; 10 s under
    /// VoiceOver). The line stays on the page: buying it is what makes it in.
    /// Whether it landed: the swipe's haptic plays only for a real add (Design on #727).
    @discardableResult
    private func add(_ entry: PantryLedger.Entry) -> Bool {
        let groceries = Groceries(store: model.store, classes: model.classes)
        // Already there: no second row and no UNDO (S10).
        if case let .already(receipt) = PantryFront.swipe(entry, groceries: groceries, store: model.store) {
            TessVoice.shared.say(receipt)
            return false
        }
        let name = model.store.displayTitle(of: entry.ingredient)
        guard let record = try? model.engine.perform(AddGroceries(lines: [name]), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return false
        }
        model.touch()
        TessVoice.shared.say(PantryCopy.added(entry.label), undo: record, holds: .seconds(4))
        return true
    }
}

/// One thing: the name in ink, its state word at the right (out heavier than low), the faint ring on out lines.
struct PantryLine: View {
    let entry: PantryLedger.Entry
    var onAdd: () -> Bool = { false }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var pull: CGFloat = 0
    @State private var added = 0

    /// A private row opens nothing: its page would show the name (pantry-acceptance S15, K26.16; QA on #724).
    static func opens(_ entry: PantryLedger.Entry) -> Bool {
        !entry.isPrivate
    }

    var body: some View {
        // Never the name of a walled thing: "Private item" (QA M1 on #722).
        let name = entry.label
        Group {
            if Self.opens(entry) {
                NavigationLink(value: Route.object(entry.ingredient.id)) { row(name) }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityHint("Opens \(name)")
            } else {
                row(name)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(entry.state.word)")
        .accessibilityAction(named: "Add to Groceries") { _ = onAdd() }
        .offset(x: pull)
        // The ghost row behind the swipe: where the line is going (Design on #727).
        .background(alignment: .trailing) {
            Text("Groceries")
                .textRole(.labelStrong)
                .foregroundStyle(Theme.Colors.ink.opacity(min(abs(pull) / 72, 1) * 0.42))
                .accessibilityHidden(true)
        }
        .tesseraFeedback(.made, trigger: added)
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onChanged { value in
                    guard value.translation.width < 0, abs(value.translation.width) > abs(value.translation.height)
                    else { return }
                    pull = max(value.translation.width, -96)
                }
                .onEnded { _ in
                    if pull <= -72 {
                        if onAdd() {
                            added += 1
                        }
                    }
                    withTesseraAnimation(reduceMotion: reduceMotion) { pull = 0 }
                }
        )
    }

    private func row(_ name: String) -> some View {
        // At accessibility sizes the state word goes under the name, one column, nothing clipped (S16).
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.s))
        return layout {
            Text(name)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !typeSize.isAccessibilitySize {
                Spacer(minLength: Theme.Spacing.m)
            }
            Text(entry.state.word)
                .textRole(.body)
                .fontWeight(entry.state == .out ? .bold : .semibold)
                // Ink, no ochre (Design sheet 99): out reads heavier than low by weight alone.
                .foregroundStyle(Theme.Colors.ink)
        }
        .padding(.leading, 24)
        .overlay(alignment: .leading) {
            if entry.state == .out {
                Circle()
                    .stroke(Theme.Colors.ink.opacity(0.42), lineWidth: 1.3)
                    .frame(width: 11, height: 11)
                    .padding(.leading, 6)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 40)
        .contentShape(Rectangle())
    }
}
