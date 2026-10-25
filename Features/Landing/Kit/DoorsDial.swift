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
    /// Up to four short lines beside the focus, the first bold (16 pt): the door's own summary, in the room's way.
    var lines: [String] = []
}

/// The landing dial: 3 places (focus plus one above, one below), 48 pt slots, loops, a tick per door, a spring
/// settle, depth blur up to 1.8 pt on the neighbours (none under Reduce Motion, Reduce Transparency, Low Power).
/// Drag vertically to turn; tap the focus to open; tap a neighbour to turn to it. It owns vertical drags in its rect.
struct DoorsDial: View {
    let doors: [DialDoor]
    @Binding var focus: Int
    var open: (DialDoor) -> Void
    var style: Style = .notes

    /// The Log's 246 dial (48 pt places, facts inside) or the landing dial of sheet 283 (Bridge's: 40 pt places,
    /// focus 26 pt, neighbours 20 pt, 1.6 pt blur, 160 pt wide; the summary is drawn apart by `DoorSummary`).
    enum Style { case notes, landing }
    static let slot: CGFloat = 48
    private var placeHeight: CGFloat { style == .landing ? 40 : Self.slot }
    private var focusSize: CGFloat { style == .landing ? 26 : 28 }
    private var neighbourSize: CGFloat { style == .landing ? 20 : 21 }
    private var maxBlur: CGFloat { style == .landing ? 1.6 : 1.8 }

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var drag: CGFloat = 0
    @State private var cue = HapticCue()
    @State private var settledAt = Date.distantPast
    @ScaledMetric(relativeTo: .title3) private var scale: CGFloat = 1

    private var large: Bool {
        typeSize.isAccessibilitySize
    }

    private var slotHeight: CGFloat {
        placeHeight * max(1, min(scale, large ? 1.25 : 1.9))
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
                if style == .notes { facts }
            }
        }
        .frame(height: slotHeight * CGFloat(places(count).count == 3 ? 3 : (large ? 2 : 3)))
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
        // At accessibility sizes the dial keeps the focus and the next door so it never runs over the foot.
        switch count {
        case 0, 1: [0]
        case 2: [0, 1]
        default: large ? [0, 1] : [-1, 0, 1]
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
                Text(door.name)
                    .font(.custom("Figtree", size: focusSize - (focusSize - neighbourSize) * distance, relativeTo: .title3).weight(.bold))
                    .foregroundStyle(isFocus ? door.color : Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                if isFocus, let count = door.count {
                    Text(count)
                        .font(.custom("Outfit", size: 14, relativeTo: .caption).weight(.regular))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }
            .frame(height: slotHeight, alignment: .leading)
            .blur(radius: blurOn ? maxBlur * distance : 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: style == .landing ? 160 : 190, alignment: .leading)
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
                    Text(label)
                        .font(.custom("Figtree", size: 13, relativeTo: .caption).weight(.regular))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                }
                ForEach(Array(door.lines.prefix(4).enumerated()), id: \.offset) { index, line in
                    Text(line)
                        .font(.custom("Figtree", size: 16, relativeTo: .body).weight(index == 0 ? .bold : .regular))
                        .foregroundStyle(Theme.Colors.ink)
                        .lineLimit(1)
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

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(
            Swift.max(self, range.lowerBound),
            range.upperBound
        )
    }
}

/// The door summary beside the landing dial (sheet 283): x 186, top 652; a 13 pt ink 2 label and up to three
/// 16/24 lines, the first 700. It rises 6 pt by a clip when the focus changes. Not blurred; each room fills it its way.
struct DoorSummary: View {
    let door: DialDoor?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let door, door.label != nil || !door.lines.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                if let label = door.label {
                    Text(label)
                        .font(.custom("Figtree", size: 13, relativeTo: .caption).weight(.regular))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .frame(height: 20, alignment: .leading)
                }
                ForEach(Array(door.lines.prefix(3).enumerated()), id: \.offset) { index, line in
                    FitLine(forms: FitLine.cuts(line), size: 16, color: Theme.Colors.ink, weight: index == 0 ? .bold : .regular)
                        .frame(width: 192, height: 24, alignment: .leading)
                }
            }
            .frame(width: 192, alignment: .leading)
            .id(door.id)
            .transition(.offset(y: reduceMotion ? 0 : 6))
            .tesseraAnimation(Theme.Motion.firm, value: door.id)
            .accessibilityElement(children: .combine)
        }
    }
}
