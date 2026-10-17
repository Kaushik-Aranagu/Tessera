import SwiftUI
import TesseraCore

/// Pantry (pantry-acceptance.md, kitchen v2): what he has, as the phone has seen it. The counts line is the hero's
/// voice; then OUT, LOW and IN in the margin, each ingredient one plain line in the shop's walk order, and IN says
/// when it was bought. A line opens its ingredient. It's a view, not a list: nothing to tick, nothing to remove, no
/// badge, and nothing leaves the phone. Unknown ingredients (the long tail) aren't listed.
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

    var body: some View {
        let _ = model.revision
        let entries = PantryLedger(store: model.store, classes: model.classes).entries()
        let now = AppClock.now
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Pantry")
                    .textRole(.hero)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(0)
                Text(PantryLedger.countsLine(entries))
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.top, Theme.Spacing.xs)
                    .entrance(1)
                if entries.isEmpty {
                    Text("Clear a shop or finish a cook and this fills in.")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(2)
                }
                ForEach([PantryLedger.State.out, .low, .have], id: \.self) { state in
                    let lines = entries.filter { $0.state == state }
                    if !lines.isEmpty {
                        MarginSection(label: state.word.capitalized) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(lines) { entry in
                                    PantryLine(entry: entry, now: now)
                                }
                            }
                        }
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(2)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.l)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// One ingredient: its name in ink (in sits back a step), and for in, when it was bought.
private struct PantryLine: View {
    let entry: PantryLedger.Entry
    let now: Date

    var body: some View {
        // Never the name of a walled thing: "Private item" (QA M1 on #722).
        let name = entry.label
        NavigationLink(value: Route.object(entry.ingredient.id)) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                Text(name)
                    .textRole(.body)
                    .foregroundStyle(entry.state == .have ? Theme.Colors.inkSecondary : Theme.Colors.ink)
                if entry.state == .have, let bought = entry.lastBoughtAt {
                    Text(PantryDayWord.bought(bought, now: now))
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label(name))
        .accessibilityHint("Opens \(name)")
    }

    private func label(_ name: String) -> String {
        if entry.state == .have, let bought = entry.lastBoughtAt {
            return "\(name), in, \(PantryDayWord.spoken(bought, now: now))"
        }
        return "\(name), \(entry.state.word)"
    }
}
