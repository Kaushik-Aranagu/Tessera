import SwiftUI
import TesseraCore

/// A number you scroll (sheet 230; no - + steppers anywhere): drag up or down on it, 16 pt a step, a light selection
/// tick per value; while the finger is down the next and previous values show faintly above and below. A tap opens the
/// dial, a full-room depth wheel of every value, with Done at the bottom left (Esc or Done keeps the focused value).
/// Every number is an accessibility adjustable element.
///
/// A drag that starts here never moves a wheel behind it: the number claims the touch on `wheelTouchGate`.
struct ScrollingNumber: View {
    @Binding var value: Double
    var step: Double
    var range: ClosedRange<Double>
    /// What a value reads as ("185", "5"); the same text the dial shows.
    var format: (Double) -> String
    /// What the dial is called ("Weight") and what VoiceOver says the number is.
    var name: String
    /// The unit word VoiceOver adds ("pounds"); nil for reps and sets.
    var spokenUnit: String?
    /// The unit the dial shows beside every value, at half size ("lb"); nil for reps and sets.
    var dialUnit: String?
    var font: Font
    var color: Color = Theme.Colors.Accent.training
    /// The slot the number is drawn in; the number never changes it as digits come and go.
    var width: CGFloat?
    var alignment: Alignment = .leading
    /// Something else (a unit change, a set logged) wants to know the value moved.
    var onChange: (Double) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.wheelTouchGate) private var gate
    @State private var startValue: Double?
    @State private var cue = HapticCue()
    @State private var isOpen = false

    var body: some View {
        ZStack(alignment: alignment) {
            neighbour(-1)
            neighbour(1)
            Text(format(value))
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
                .contentTransition(.numericText(value: value))
                .tesseraAnimation(Theme.Motion.snappy, value: value)
        }
        .frame(width: width, alignment: alignment)
        .fixedSize(horizontal: width == nil, vertical: false)
        .contentShape(Rectangle())
        .onTapGesture { isOpen = true }
        .gesture(scrollGesture)
        .tesseraFeedback(cue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue([format(value), spokenUnit].compactMap(\.self).joined(separator: " "))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Adjustable. Double tap to open the dial.")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(by: 1)
            case .decrement: move(by: -1)
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Open the dial") { isOpen = true }
        .fullScreenCover(isPresented: $isOpen) {
            NumberDial(value: $value, step: step, range: range, format: format, name: name, unit: dialUnit) {
                onChange(value)
            }
        }
    }

    /// The value one step above or below, faint, only while a finger is down on the number.
    private func neighbour(_ direction: Int) -> some View {
        let next = NumberScroll.stepped(value, by: direction, step: step, in: range)
        return Text(format(next))
            .font(font)
            .foregroundStyle(Theme.Colors.inkSecondary)
            .lineLimit(1)
            .opacity(startValue != nil && next != value ? 0.3 : 0)
            .offset(y: CGFloat(-direction) * 0.9 * neighbourPitch)
            .tesseraAnimation(Theme.Motion.snappy, value: startValue != nil)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    /// How far a faint neighbour sits from the value: a little less than a line.
    private var neighbourPitch: CGFloat {
        UIFontMetrics(forTextStyle: .title1).scaledValue(for: 40)
    }

    private var scrollGesture: some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { drag in
                gate?.claim()
                if startValue == nil {
                    startValue = value
                }
                guard let start = startValue else { return }
                let next = NumberScroll.value(start: start, translation: drag.translation.height, step: step,
                                              in: range)
                guard next != value else { return }
                value = next
                cue.play(.selection)
                onChange(next)
            }
            .onEnded { _ in
                startValue = nil
                gate?.release()
            }
    }

    private func move(by direction: Int) {
        let next = NumberScroll.stepped(value, by: direction, step: step, in: range)
        guard next != value else { return }
        value = next
        cue.play(.selection)
        onChange(next)
    }
}

// MARK: - The dial

/// The dial a tap opens: every value of the number on a depth wheel filling the room, the focused one in the accent.
/// Done sits at the bottom left; Esc does the same. Either keeps the focused value (it already is the number).
struct NumberDial: View {
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let format: (Double) -> String
    let name: String
    var unit: String?
    var onDone: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus = 0
    @FocusState private var keyboardFocus: Bool

    private struct Entry: Identifiable {
        let id: Int
        let value: Double
    }

    private var entries: [Entry] {
        NumberScroll.values(in: range, step: step).enumerated().map { Entry(id: $0.offset, value: $0.element) }
    }

    var body: some View {
        let entries = entries
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .font(Theme.Training.words(16, weight: .semibold, relativeTo: .callout))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .padding(.top, Theme.Spacing.xl)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            DepthWheel(items: entries, focus: $focus, home: focus, style: .dial, label: name) { entry, state in
                MeasuredNumber(number: format(entry.value), unit: unit ?? "", size: WheelStyle.dial.sizes[0],
                               color: state.isFocused ? Theme.Colors.Accent.training : Theme.Colors.inkSecondary)
                    .accessibilityLabel("\(name) \(format(entry.value)) \(unit ?? "")")
            }
            Spacer(minLength: 0)
            Button {
                finish()
            } label: {
                Text("Done")
                    .font(Theme.Training.words(22, weight: .semibold, relativeTo: .title3))
                    .foregroundStyle(Theme.Colors.Accent.training)
                    .frame(minWidth: 88, minHeight: 56, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, Theme.Spacing.l)
            .accessibilityHint("Keeps \(name) as it is")
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.Colors.paper.ignoresSafeArea())
        .focusable()
        .focused($keyboardFocus)
        .onKeyPress(.escape) {
            finish()
            return .handled
        }
        .onKeyPress(.upArrow) { nudge(-1) }
        .onKeyPress(.downArrow) { nudge(1) }
        .onAppear {
            focus = entries.min { abs($0.value - value) < abs($1.value - value) }?.id ?? 0
            keyboardFocus = true
        }
        .onChange(of: focus) { _, new in
            if entries.indices.contains(new), entries[new].value != value {
                value = entries[new].value
            }
        }
    }

    private func nudge(_ direction: Int) -> KeyPress.Result {
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
            focus = min(max(focus + direction, 0), max(entries.count - 1, 0))
        }
        return .handled
    }

    private func finish() {
        onDone()
        dismiss()
    }
}
