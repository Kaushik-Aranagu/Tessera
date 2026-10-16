import SwiftUI

/// Settings, Look (themes.md, "Switching"): one sentence, "Porcelain by day, Obsidian by night". Each name is a value
/// word: a tap cycles it through the light looks (or the dark ones), a hold pins it ("Obsidian always"), and a hold
/// again unpins. No new controls.
struct LookSentence: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pins = 0

    var body: some View {
        let store = ThemeStore.shared
        Group {
            if let pinned = store.pinned {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    name(pinned) { change { store.cycle(pinned: pinned) } }
                    Text(" always")
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) { sentence(store) }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            name(store.day) { change { store.cycleDay() } }
                            Text(" by day,")
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            name(store.night) { change { store.cycleNight() } }
                            Text(" by night")
                        }
                    }
                }
            }
        }
        .textRole(.body)
        .foregroundStyle(Theme.Colors.ink)
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: pins)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private func sentence(_ store: ThemeStore) -> some View {
        name(store.day) { change { store.cycleDay() } }
        Text(" by day, ")
        name(store.night) { change { store.cycleNight() } }
        Text(" by night")
    }

    private func name(_ look: Look, cycle: @escaping () -> Void) -> some View {
        Button(look.name, action: cycle)
            .buttonStyle(.valueWash)
            .fontWeight(.semibold)
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                pins += 1
                change { ThemeStore.shared.togglePin(look) }
            })
            .accessibilityHint("Changes the look. Hold to keep it day and night.")
            .accessibilityAction(named: ThemeStore.shared.pinned == look ? "Follow day and night" : "Keep always") {
                change { ThemeStore.shared.togglePin(look) }
            }
    }

    /// The new ground crossfades in (the soul's flood comes with the Settings page).
    private func change(_ body: () -> Void) {
        withTesseraAnimation(.easeInOut(duration: reduceMotion ? 0.25 : 0.7), reduceMotion: reduceMotion) { body() }
    }
}

extension ThemeStore {
    /// Tapping a pinned name cycles through every look.
    func cycle(pinned look: Look) {
        let index = Look.all.firstIndex(of: look) ?? -1
        togglePin(look)
        togglePin(Look.all[(index + 1) % Look.all.count])
    }
}
