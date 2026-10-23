import SwiftUI

/// Settings › Home (sheet 199): "What Home shows." with the Mosaic and Apps list switches, in the Review row style.
/// Drawn only while the Mosaic Home is On, so Settings reads as today with the switch Off.
struct HomeSettingsSection: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flips = 0

    var body: some View {
        let ids = [HomeMosaic.choiceID, HomeMosaic.appsListID]
        let rows = ids.compactMap { id in ReviewChoices.all.first { $0.id == id } }
        frame {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text("What Home shows.")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(rows) { choice in
                    row(choice)
                }
            }
        }
        .tesseraFeedback(.selection, trigger: flips)
    }

    @ViewBuilder
    private func frame(@ViewBuilder content: () -> some View) -> some View {
        if SettingsV2.isOn {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                SettingsV2Label(text: "Home")
                content()
            }
        } else {
            MarginSection(label: "Home", content: content)
        }
    }

    private func row(_ choice: ReviewChoices.Choice) -> some View {
        let choices = ReviewChoices.shared
        let value = choices.value(of: choice)
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(choice.name): ")
                .foregroundStyle(Theme.Colors.ink)
            Button { flip(choice, forward: true) } label: {
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.valueWash)
            .contentTransition(.opacity)
            Text(".")
            Spacer(minLength: 0)
        }
        .textRole(.body)
        .frame(minHeight: 44, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(choice.name)
        .accessibilityValue(value)
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            flip(choice, forward: direction != .decrement)
        }
        .accessibilityAction { flip(choice, forward: true) }
    }

    private func flip(_ choice: ReviewChoices.Choice, forward: Bool) {
        let choices = ReviewChoices.shared
        let before = choices.value(of: choice)
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            choices.step(choice, forward: forward)
        }
        flips += 1
        AccessibilityNotification.Announcement(choices.beforeAfter(choice, before: before)).post()
    }
}
