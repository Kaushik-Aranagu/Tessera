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
    /// Sheet 320: ledger rows (name, right-aligned number, unit). When present `DoorSummary` draws the ledger
    /// (`DoorLedger`) with `label` above and `more` below, instead of `lines`.
    var rows: [Row] = []
    /// The quiet last line of the ledger (12 pt): what opening the door adds.
    var more: String?
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
    private var placeHeight: CGFloat {
        style == .landing ? 40 : Self.slot
    }

    private var focusSize: CGFloat {
        style == .landing ? 26 : 28
    }

    private var neighbourSize: CGFloat {
        style == .landing ? 20 : 21
    }

    private var maxBlur: CGFloat {
        style == .landing ? 1.6 : 1.8
    }

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var drag: CGFloat = 0
    @State private var cue = HapticCue()
    @State private var settledAt = Date.distantPast
    /// Sheet 290, the detent: the new focus word settles 3 pt past its slot and back in 280 ms, like a dial clicking
    /// into place. Zero at rest.
    @State private var detent: CGFloat = 0
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

    @Environment(\.doorsForm) private var requestedForm
    @Environment(\.liveScope) private var isShown
    /// "and N more" turns the place into the index form until the shell asks for another form.
    @State private var turnedToIndex = false

    /// The form on screen: the requested one, the index when "and N more" was tapped, and the reel again when the
    /// form does not fit (a large Dynamic Type size, or doors that cannot be set in 160 pt) so a door is never lost.
    private var formLayout: DoorFormLayout? {
        guard style == .landing, !large else { return nil }
        let form = turnedToIndex && requestedForm == .sentence ? DoorsForm.index : requestedForm
        guard form != .reel, !doors.isEmpty else { return nil }
        return DoorForms.fit(form, names: doors.map { ($0.id, $0.name) }, focus: wrapped(focus), scale: scale)
    }

    var body: some View {
        Group {
            if let layout = formLayout {
                DoorsFormView(doors: doors, layout: layout, isShown: isShown, open: open) {
                    turnedToIndex = true
                }
                .frame(width: DoorForms.frame.width, height: DoorForms.frame.height, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                reelBody
            }
        }
        .onChange(of: requestedForm) { turnedToIndex = false }
        .tesseraAnimation(isShown ? Theme.Motion.fadeIn : .linear(duration: 0), value: formLayout?.form)
    }

    @ViewBuilder
    private var reelBody: some View {
        let count = doors.count
        ZStack(alignment: .leading) {
            if count > 0 {
                ForEach(places(count), id: \.self) { place in
                    row(for: wrapped(focus + place), place: place)
                }
                if style == .notes {
                    facts
                }
            }
        }
        .frame(height: slotHeight * CGFloat(places(count).count == 3 ? 3 : (large ? 2 : 3)))
        .frame(maxWidth: .infinity, alignment: style == .landing ? .trailing : .leading)
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
                    .font(.custom(
                        "Figtree",
                        size: focusSize - (focusSize - neighbourSize) * distance,
                        relativeTo: .title3
                    ).weight(.bold))
                    .foregroundStyle(isFocus ? door.color : Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                if isFocus, let count = door.count {
                    Text(count)
                        .font(.custom("Outfit", size: 14, relativeTo: .caption).weight(.regular))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }
            .frame(height: slotHeight, alignment: style == .landing ? .trailing : .leading)
            .blur(radius: blurOn ? maxBlur * distance : 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: style == .landing ? 160 : 190, alignment: style == .landing ? .trailing : .leading)
        .offset(y: offset + (place == 0 ? detent : 0))
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
        click(delta)
    }

    /// The detent: as the spring arrives, the word goes 3 pt on in the direction it travelled (the list moves up when
    /// the next door comes to the focus) and back, inside 280 ms. Reduce Motion drops it.
    private func click(_ delta: Int) {
        guard !reduceMotion else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            withTesseraAnimation(.easeOut(duration: 0.06), reduceMotion: reduceMotion) { detent = delta > 0 ? -3 : 3 }
            try? await Task.sleep(for: .milliseconds(60))
            withTesseraAnimation(.easeInOut(duration: 0.12), reduceMotion: reduceMotion) { detent = 0 }
        }
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
/// 16/24 lines, the first 700. Not blurred; each room fills it its way, and (283 v6) each room changes it its way when
/// the dial turns: the style comes from the environment value `doorSummaryStyle` (see `DoorSummaryStyle`).
struct DoorSummary: View {
    let door: DialDoor?
    /// The summary's own move on a focus change. The standing shell turns it off: there the place plays the move and
    /// the summary keeps one identity.
    var ownMove = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.doorSummaryStyle) private var style

    struct Row: Identifiable, Equatable {
        let id: String
        let text: String
        let isLabel: Bool
        let isFirst: Bool
        let index: Int
        let y: CGFloat
    }

    /// The rows of the per-row styles (chalk, fog, grow), each in its fixed place, keyed by door so a turn swaps them.
    static func rows(_ door: DialDoor, key: String? = nil) -> [Row] {
        let key = key ?? door.id
        var rows: [Row] = []
        var y: CGFloat = 0
        if let label = door.label {
            rows.append(Row(id: "\(key)#label", text: label, isLabel: true, isFirst: false, index: 0, y: 0))
            y = 20
        }
        for (index, line) in door.lines.prefix(3).enumerated() {
            rows.append(Row(id: "\(key)#\(index)", text: line, isLabel: false, isFirst: index == 0,
                            index: rows.count, y: y + CGFloat(index) * 24))
        }
        return rows
    }

    var body: some View {
        if let door, !door.rows.isEmpty {
            DoorLedger(label: door.label, rows: door.rows, more: door.more)
        } else if let door, door.label != nil || !door.lines.isEmpty {
            switch style {
            case .plain:
                // The standing shell plays the move itself (`ownMove` false): then the summary keeps one identity.
                lines(door)
                    .id(ownMove ? door.id : "summary")
                    .transition(.offset(y: reduceMotion || !ownMove ? 0 : 6))
                    .tesseraAnimation(Theme.Motion.firm, value: ownMove ? door.id : "summary")
            case .ticket:
                // Galley: the new summary comes down like a ticket out of the printer; the old one lifts away.
                lines(door)
                    .id(ownMove ? door.id : "summary")
                    .transition(reduceMotion || !ownMove ? .identity
                        : .asymmetric(insertion: .push(from: .top),
                                      removal: .offset(y: -14).combined(with: .opacity)))
                    .tesseraAnimation(Theme.Motion.firm, value: door.id)
            case .meter:
                // One identity across doors: the digits roll, the words cross-fade in place.
                lines(door)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .tesseraAnimation(Theme.Motion.firm, value: door.id)
            case .chalk, .fog, .grow:
                staged(door)
            }
        }
    }

    private func lines(_ door: DialDoor) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label = door.label {
                FitLine(forms: FitLine.cuts(label), size: 13, color: Theme.Colors.inkSecondary)
                    .frame(width: 192, height: 20, alignment: .leading)
            }
            ForEach(Array(door.lines.prefix(3).enumerated()), id: \.offset) { index, line in
                FitLine(
                    forms: FitLine.cuts(line),
                    size: 16,
                    color: Theme.Colors.ink,
                    weight: index == 0 ? .bold : .regular
                )
                .frame(width: 192, height: 24, alignment: .leading)
            }
        }
        .frame(width: 192, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// Deck, Lookout and Watch: each row has its own place, so the old and new rows overlap while they change and
    /// nothing moves the layout. Without its own move the rows keep one identity and change in place.
    private func staged(_ door: DialDoor) -> some View {
        let rows = Self.rows(door, key: ownMove ? nil : "summary")
        return ZStack(alignment: .topLeading) {
            ForEach(rows) { row in
                rowView(row)
                    .offset(y: row.y)
                    .transition(ownMove
                        ? style.transition(index: row.index, count: rows.count, reduceMotion: reduceMotion)
                        : .identity)
            }
        }
        .frame(width: 192, height: 92, alignment: .topLeading)
        .tesseraAnimation(style.animation(rows: rows.count), value: ownMove ? door.id : "summary")
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func rowView(_ row: Row) -> some View {
        if row.isLabel {
            // Whole-word cuts, never "..." (contract §7).
            FitLine(forms: FitLine.cuts(row.text), size: 13, color: Theme.Colors.inkSecondary)
                .frame(width: 192, height: 20, alignment: .leading)
        } else {
            FitLine(forms: FitLine.cuts(row.text), size: style.lineSize, color: Theme.Colors.ink,
                    weight: row.isFirst ? .bold : .regular, family: style.family)
                .frame(width: 192, height: 24, alignment: .leading)
        }
    }
}
