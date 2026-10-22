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
            .textRole(.keyWord)
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

/// Words that wrap onto the next line instead of running past the page edge (the filter words).
struct WordFlow: Layout {
    var spacing: CGFloat = Theme.Spacing.l
    var lineSpacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        return CGSize(width: rows.map(\.width).max() ?? 0, height: rows.reduce(0) { $0 + $1.height } +
            lineSpacing * CGFloat(max(rows.count - 1, 0)))
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if needed > width, !row.indices.isEmpty {
                rows.append(row)
                row = Row()
            }
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
        }
        if !row.indices.isEmpty {
            rows.append(row)
        }
        return rows
    }
}

/// A quiet action word: ink secondary, no underline ("Save", "Just today").
struct QuietWordStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.keyWord)
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
        let reps = slot.repMin == slot.repMax ? "\(slot.repMax)" : "\(slot.repMin)–\(slot.repMax)"
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
                // The big number leads: the minutes it takes.
                HStack(alignment: .firstTextBaseline, spacing: MeasureStyle.gap) {
                    Text("\(tried.minutes)")
                        .numeral(72, weight: .thin)
                        .foregroundStyle(Theme.Colors.ink)
                    Text(MeasureStyle.unitText("min"))
                        .font(MeasureStyle.unit)
                        .tracking(MeasureStyle.unitTracking)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                .accessibilityHidden(true)
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
