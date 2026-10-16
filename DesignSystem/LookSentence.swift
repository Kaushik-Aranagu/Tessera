import SwiftUI

/// LOOK (themes.md "Switching", copy from docs/research/theme-names.md): one sentence with value words, "Porcelain by
/// day, Obsidian by night." A tap moves a name to the next look of its kind, a hold keeps it day and night
/// ("Obsidian always."), and a hold again lets it follow light and dark mode. No Tess line and no UNDO: a look isn't
/// a record, and tapping again goes back.
struct LookSentence: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taps = 0
    @State private var pins = 0

    var body: some View {
        let store = ThemeStore.shared
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Look")
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            if let pinned = store.pinned {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    name(pinned, slot: "Look") { store.cycle(pinned: pinned) }
                    Text(" always.")
                }
                hint("Hold it again to follow light and dark mode.")
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        name(store.day, slot: "Day look") { store.cycleDay() }
                        Text(" by day, ")
                        name(store.night, slot: "Night look") { store.cycleNight() }
                        Text(" by night.")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            name(store.day, slot: "Day look") { store.cycleDay() }
                            Text(" by day,")
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            name(store.night, slot: "Night look") { store.cycleNight() }
                            Text(" by night.")
                        }
                    }
                }
                hint("Hold a name to keep it day and night.")
            }
        }
        .textRole(.body)
        .foregroundStyle(Theme.Colors.ink)
        .sensoryFeedback(.selection, trigger: taps)
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: pins)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .textRole(.body)
            .foregroundStyle(Theme.Colors.inkSecondary)
    }

    private func name(_ look: Look, slot: String, cycle: @escaping () -> Void) -> some View {
        let isPinned = ThemeStore.shared.pinned == look
        return Button {
            taps += 1
            change(cycle)
        } label: {
            Text(look.name)
                .fontWeight(.semibold)
        }
        .buttonStyle(.valueWash)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
            pins += 1
            change { ThemeStore.shared.togglePin(look) }
        })
        .accessibilityLabel(slot)
        .accessibilityValue(Text(Self.spoken(look)))
        .accessibilityHint(look.line)
        .accessibilityAdjustableAction { _ in
            taps += 1
            change(cycle)
        }
        .accessibilityAction(named: isPinned ? "Follow light and dark mode" : "Keep \(look.name) day and night") {
            pins += 1
            change { ThemeStore.shared.togglePin(look) }
        }
    }

    /// "Plein" said "plen", not "plain".
    private static func spoken(_ look: Look) -> AttributedString {
        var name = AttributedString(look.name)
        if look == .plein {
            name.accessibilitySpeechPhoneticNotation = "plɛn"
        }
        return name
    }

    /// The new ground crossfades in (the soul's flood comes with Settings).
    private func change(_ body: () -> Void) {
        withTesseraAnimation(.easeInOut(duration: reduceMotion ? 0.25 : 0.7), reduceMotion: reduceMotion) { body() }
    }
}

extension ThemeStore {
    /// A pinned name taps through all five looks, light and dark.
    func cycle(pinned look: Look) {
        let index = Look.all.firstIndex(of: look) ?? -1
        togglePin(look)
        togglePin(Look.all[(index + 1) % Look.all.count])
    }
}
