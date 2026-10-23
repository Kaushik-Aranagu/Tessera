import SwiftUI

/// One preference as a sentence line (sheet 203): the words on the left, the value right-aligned in ink 2. A tap opens
/// its choices in place as words; the chosen word is underlined at 1 pt, 5 pt off the baseline, with an optional ink 3
/// "why" line under them. No card, no pill, no switch.
struct SettingsLine: View {
    struct Option: Identifiable, Equatable {
        let id: String
        let name: String
    }

    let sentence: String
    let options: [Option]
    let selected: String
    var why: String?
    var valueColor: Color = Theme.Colors.inkSecondary
    let choose: (Option) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var open = false
    @State private var ticks = 0

    private var valueName: String {
        options.first { $0.id == selected }?.name ?? selected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Button {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { open.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                    Text(sentence)
                        .foregroundStyle(Theme.Colors.ink)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: Theme.Spacing.s)
                    Text(valueName)
                        .foregroundStyle(valueColor)
                        .multilineTextAlignment(.trailing)
                }
                .textRole(.body)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(sentence)
            .accessibilityValue(valueName)
            .accessibilityHint(open ? "Closes the choices" : "Shows the choices")

            if open {
                TrailingWrap(spacing: Theme.Spacing.l, lineSpacing: Theme.Spacing.xs) {
                    ForEach(options) { option in
                        Button {
                            guard option.id != selected else { return }
                            ticks += 1
                            choose(option)
                        } label: {
                            Text(option.name)
                                .textRole(.body)
                                .foregroundStyle(option.id == selected ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                                .overlay(alignment: .bottom) {
                                    Rectangle().fill(Theme.Colors.ink).frame(height: 1)
                                        .offset(y: 5)
                                        .opacity(option.id == selected ? 1 : 0)
                                }
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(option.id == selected ? .isSelected : [])
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(reduceMotion ? .identity : .move(edge: .top))
                if let why {
                    Text(why)
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .transition(reduceMotion ? .identity : .move(edge: .top))
                }
            }
        }
        .tesseraFeedback(.selection, trigger: ticks)
    }
}

/// A line that opens its own page: the words on the left, a quiet value on the right (a count, a time, or nothing).
struct SettingsPageLine<Destination: View>: View {
    let sentence: String
    var value: String?
    var valueColor: Color = Theme.Colors.inkSecondary
    var hint: String?
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Text(sentence)
                    .foregroundStyle(Theme.Colors.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Theme.Spacing.s)
                if let value {
                    Text(value)
                        .foregroundStyle(valueColor)
                        .multilineTextAlignment(.trailing)
                }
            }
            .textRole(.body)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sentence)
        .accessibilityValue(value ?? "")
        .accessibilityHint(hint ?? "Opens it")
    }
}
