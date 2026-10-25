import SwiftUI

/// One door on a landing's dial (landing contract §4).
struct DialDoor: Identifiable, Equatable {
    let id: String
    let name: String
    /// Outfit at half size, ink 2, beside the focus ("12"); nil for none.
    var count: String?
    /// The door's meaning colour (241), worn only while it is the focus.
    let color: Color
    /// The small label above the facts ("Newest 2 pm"), 13 pt ink 2.
    var label: String?
    /// Up to three short lines beside the focus, the first bold (16 pt).
    var lines: [String] = []
}

/// The landing dial: 3 places (focus plus one above, one below), 48 pt slots, loops, a tick per door, a spring
/// settle, depth blur up to 1.8 pt on the neighbours (none under Reduce Motion, Reduce Transparency, Low Power).
/// Drag vertically to turn; tap the focus to open; tap a neighbour to turn to it. It owns vertical drags in its rect.
struct DoorsDial: View {
    let doors: [DialDoor]
    @Binding var focus: Int
    var open: (DialDoor) -> Void

    static let slot: CGFloat = 48

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var drag: CGFloat = 0
    @State private var cue = HapticCue()
    @State private var settledAt = Date.distantPast
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title3) private var scale: CGFloat = 1

    /// The largest type the dial sets: past it the three places would run out of the 432-576 band into the brief.
    static let largestType = DynamicTypeSize.xxxLarge

    /// Slots grow with the (capped) type, at most 1.2x, so the dial ends above the brief at 612.
    private var slotHeight: CGFloat {
        Self.slot * max(1, min(scale, 1.2))
    }

    /// At accessibility sizes the facts column steps aside so the door name has the whole width.
    private var showsFacts: Bool {
        !typeSize.isAccessibilitySize
    }

    private var blurOn: Bool {
        !reduceMotion && !reduceTransparency && !ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        let count = doors.count
        ZStack(alignment: .leading) {
            if count > 0 {
                ForEach(places(count), id: \.self) { place in
                    row(for: wrapped(focus + place), place: place)
                }
                if showsFacts {
                    facts
                }
            }
        }
        .dynamicTypeSize(...Self.largestType)
        .frame(height: slotHeight * 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .highPriorityGesture(turn)
        .tesseraFeedback(cue)
        .accessibilityElement(children: .contain)
        .accessibilityAdjustableAction { direction in
            guard count > 1 else { return }
            move(direction == .increment ? 1 : -1)
        }
    }

    /// Focus plus one above and one below; with fewer than 3 doors a door is never shown twice.
    private func places(_ count: Int) -> [Int] {
        switch count {
        case 0, 1: [0]
        case 2: [0, 1]
        default: [-1, 0, 1]
        }
    }

    private func wrapped(_ index: Int) -> Int {
        let count = max(doors.count, 1)
        return ((index % count) + count) % count
    }

    private func row(for index: Int, place: Int) -> some View {
        let door = doors[index]
        let offset = CGFloat(place) * slotHeight + drag.clamped(to: -slotHeight ... slotHeight)
        let distance = min(abs(offset) / slotHeight, 1)
        let isFocus = distance < 0.5
        return Button {
            guard Date().timeIntervalSince(settledAt) > 0.12 else { return }
            if place == 0 {
                open(door)
            } else {
                move(place)
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                WholeWords(text: door.name,
                           font: .custom("Figtree", size: 28 - 7 * distance, relativeTo: .title3).weight(.bold),
                           color: isFocus ? door.color : Theme.Colors.inkSecondary)
                if isFocus, let count = door.count {
                    Text(count)
                        .font(.custom("Outfit", size: 14, relativeTo: .caption).weight(.regular))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }
            .frame(height: slotHeight, alignment: .leading)
            .blur(radius: blurOn ? 1.8 * distance : 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: showsFacts ? 190 : .infinity, alignment: .leading)
        .offset(y: offset)
        .accessibilityLabel("\(door.name)\(door.count.map { ", \($0)" } ?? "")")
        .accessibilityAddTraits(place == 0 ? .isSelected : [])
        .accessibilityHint(place == 0 ? "Opens it" : "Turns to it")
    }

    @ViewBuilder
    private var facts: some View {
        let door = doors[wrapped(focus)]
        if door.label != nil || !door.lines.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                if let label = door.label {
                    WholeWords(text: label, font: .custom("Figtree", size: 13, relativeTo: .caption).weight(.regular),
                               color: Theme.Colors.inkSecondary)
                }
                ForEach(Array(door.lines.prefix(3).enumerated()), id: \.offset) { index, line in
                    WholeWords(text: line,
                               font: .custom("Figtree", size: 16, relativeTo: .body)
                                   .weight(index == 0 ? .bold : .regular),
                               color: Theme.Colors.ink)
                }
            }
            .frame(width: 150, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .id(door.id)
            .transition(.offset(y: reduceMotion ? 0 : 6))
            .tesseraAnimation(Theme.Motion.firm, value: door.id)
            .accessibilityElement(children: .combine)
        }
    }

    private var turn: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                drag = value.translation.height
            }
            .onEnded { value in
                let step = (value.translation.height / slotHeight).rounded()
                let flick = abs(value.predictedEndTranslation.height) > slotHeight * 1.2
                var delta = Int(-step)
                if delta == 0, flick {
                    delta = value.translation.height < 0 ? 1 : -1
                }
                withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { drag = 0 }
                if delta != 0 {
                    move(delta)
                }
                settledAt = Date()
            }
    }

    private func move(_ delta: Int) {
        guard doors.count > 1 else { return }
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
            focus = wrapped(focus + delta)
        }
        cue.play(.selection)
        settledAt = Date()
    }
}

/// One line that never wraps and never ellipsizes: the longest whole-word cut of `text` that fits (contract §7).
/// VoiceOver reads the full text.
struct WholeWords: View {
    let text: String
    let font: Font
    let color: Color

    var body: some View {
        ViewThatFits(in: .horizontal) {
            ForEach(Array(WordCut.forms(text).enumerated()), id: \.offset) { _, form in
                Text(form).font(font).foregroundStyle(color).fixedSize()
            }
        }
        .accessibilityLabel(text)
    }
}

/// Whole-word cuts of a line, longest first: drop a word at a time, then trailing small words and punctuation.
/// Never "...", never an empty form.
enum WordCut {
    private static let small: Set<String> = ["and", "the", "a", "an", "of", "to", "by", "in", "on", "or", "for",
                                             "with", "at", "is"]

    static func forms(_ text: String) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        guard words.count > 1 else { return [text] }
        var forms: [String] = [text]
        for count in stride(from: words.count - 1, through: 1, by: -1) {
            var kept = Array(words.prefix(count))
            while kept.count > 1, let last = kept.last,
                  small.contains(last.lowercased().trimmingCharacters(in: .punctuationCharacters))
            {
                kept.removeLast()
            }
            let form = kept.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: ",;:."))
            if !form.isEmpty, forms.last != form {
                forms.append(form)
            }
        }
        return forms
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(
            Swift.max(self, range.lowerBound),
            range.upperBound
        )
    }
}
