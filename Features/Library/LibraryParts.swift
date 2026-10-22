import SwiftUI
import TesseraCore

/// Two or three words, one in ink and the rest at 30%: a knob (Design 124, 128). Tap a word to turn it.
struct KnobWords<Value: Hashable>: View {
    let values: [Value]
    @Binding var selection: Value
    let word: (Value) -> String
    var spoken: String

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            ForEach(values, id: \.self) { value in
                Button {
                    selection = value
                } label: {
                    Text(word(value))
                        .font(Theme.voice(size: 21).weight(.medium))
                        .foregroundStyle(Theme.Colors.ink.opacity(value == selection ? 1 : 0.3))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(value == selection ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(spoken)
    }
}

/// The primary word of a page: ink, with a hot underline that draws in on touch ("Try today", "Start").
struct HotWordStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.labelStrong)
            .foregroundStyle(Theme.Colors.ink)
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.Colors.live).frame(height: 1.5)
                    .opacity(configuration.isPressed ? 1 : 0.85)
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// A quiet action word: ink secondary, no underline ("Save", "Just today").
struct QuietWordStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.labelStrong)
            .foregroundStyle(Theme.Colors.inkSecondary)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ReadyWorkout {
    /// "6 exercises, about 25 min".
    var subtitle: String {
        "\(slots.count) exercises, about \(minutes) min"
    }

    /// "4 x 6-8", "3 x 10", "2 x 45 s": the sets and reps of a slot as a line says them.
    func setsWord(_ slot: Slot) -> String {
        let reps = slot.repMin == slot.repMax ? "\(slot.repMax)" : "\(slot.repMin)-\(slot.repMax)"
        return "\(slot.sets) × \(reps)"
    }
}

/// Under today's name after "Try today": what it is, what it replaced, and for ten seconds the word to take it back.
struct TriedTodayLine: View {
    let tried: TriedToday
    var undo: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let open = tried.undoIsOpen(now: AppClock.adjust(context.date))
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(tried.line())
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if open {
                    Button("Undo", action: undo)
                        .buttonStyle(QuietWordStyle())
                        .transition(.opacity)
                }
            }
            .tesseraAnimation(value: open)
            .accessibilityElement(children: .combine)
        }
    }
}
