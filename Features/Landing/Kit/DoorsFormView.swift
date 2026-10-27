import SwiftUI

/// The dial's index and sentence forms (sheet 292). Every door's word is one view keyed by its door id, placed from
/// `DoorForms`, so a switch between the two lets shared names travel (520 ms) while the joiners ("and", "and 4
/// more") fade in at 260 ms. Doors a form folds away stay where the index would put them, invisible. Under Reduce
/// Motion nothing travels: the form swaps in a 150 ms crossfade. Unseen, it arrives with no frames.
struct DoorsFormView: View {
    let doors: [DialDoor]
    let layout: DoorFormLayout
    let isShown: Bool
    var open: (DialDoor) -> Void
    /// Tapping a neighbour row of the index only turns the dial to it; it never opens a door.
    var turnTo: (DialDoor) -> Void
    /// A vertical drag anywhere on the dial turns it one door per row travelled.
    var turnBy: (Int) -> Void
    var showAll: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var origin: CGPoint {
        DoorForms.frame.origin
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(doors) { door in
                word(for: door)
            }
            ForEach(layout.placements.filter(\.isJoiner)) { placement in
                joiner(placement)
                    .transition(.opacity.animation(Theme.Motion.fadeIn))
            }
        }
        .id(reduceMotion ? layout.form.rawValue : "doors")
        .transition(.opacity)
        .animation(travelAnimation, value: layout)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 12).onEnded { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                let rows = max(1, Int((abs(value.translation.height) / DoorForms.indexPitch).rounded()))
                turnBy(value.translation.height < 0 ? rows : -rows)
            }
        )
        .accessibilityElement(children: .contain)
    }

    /// 520 ms travel; Reduce Motion's crossfade (through `MotionPolicy`); none when the dial is not shown.
    private var travelAnimation: Animation? {
        isShown ? MotionPolicy.resolve(Theme.Motion.travel, reduceMotion: reduceMotion) : nil
    }

    /// A door's word, at its place in this form (or, folded away, at its place in the index, hidden).
    private func word(for door: DialDoor) -> some View {
        let placement = layout.placements.first { $0.id == door.id && !$0.isJoiner }
        let rect = placement?.rect ?? hiddenRect(for: door)
        let size = placement?.size ?? 15
        let isIndexNeighbour = layout.form == .index && placement?.bold == false
        let height = layout.form == .index && placement?.bold == true
            ? DoorForms.focusTargetHeight : max(rect.height, DoorForms.linePitch)
        return Button {
            if isIndexNeighbour {
                turnTo(door)
            } else {
                open(door)
            }
        } label: {
            Text(door.name)
                .font(.custom("Figtree", fixedSize: size).weight(placement?.bold == true ? .semibold : .regular))
                .foregroundStyle(placement?.ink == .room ? door.color : Theme.Colors.ink)
                .lineLimit(1)
                .fixedSize()
                .frame(width: rect.width + 4, height: height, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(placement == nil)
        .opacity(placement == nil ? 0 : 1)
        .zIndex(placement?.bold == true ? 1 : 0)
        .offset(x: rect.minX - origin.x - 2, y: rect.midY - origin.y - height / 2)
        .accessibilityLabel(door.name)
        .accessibilityHidden(placement == nil)
        .accessibilityHint("Opens it")
    }

    /// A folded door keeps its index place, so it travels out of and back into view rather than appearing at 0, 0.
    private func hiddenRect(for door: DialDoor) -> CGRect {
        let names = doors.map { ($0.id, $0.name) }
        let index = DoorForms.index(names: names, focus: 0, size: 13, gap: 8)
        return index.placements.first { $0.id == door.id }?.rect
            ?? CGRect(x: DoorForms.frame.maxX - 40, y: DoorForms.frame.minY, width: 40, height: 16)
    }

    @ViewBuilder
    private func joiner(_ placement: DoorPlacement) -> some View {
        let height = max(placement.rect.height, DoorForms.linePitch)
        let text = Text(placement.text)
            .font(.custom("Figtree", fixedSize: placement.size))
            .foregroundStyle(Theme.Colors.inkSecondary)
            .lineLimit(1)
            .fixedSize()
        if placement.opensIndex {
            Button(action: showAll) {
                text
                    .frame(width: placement.rect.width + 4, height: height)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: placement.rect.minX - origin.x - 2, y: placement.rect.midY - origin.y - height / 2)
            .accessibilityLabel("\(placement.text), shows every door")
        } else {
            text
                .frame(width: placement.rect.width + 4, height: height)
                .offset(x: placement.rect.minX - origin.x - 2, y: placement.rect.midY - origin.y - height / 2)
                .accessibilityHidden(true)
        }
    }
}

extension DoorPlacement: Identifiable {}
