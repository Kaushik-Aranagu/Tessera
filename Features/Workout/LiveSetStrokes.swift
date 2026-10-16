import SwiftUI

private typealias Paint = WorkoutPaint

/// The glint motif, only while a set could be a new best.
struct GlintIf: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.modifier(Glint(period: 3, sheen: Paint.sheen))
        } else {
            content
        }
    }
}

// MARK: - Sets as brushstrokes (y)

/// One stroke per planned set: logged sets are 9 pt strokes in their paint, the current set a breathing dashed cream
/// guide, later sets a faint guide. A freshly logged set paints in over 700 ms. Tap a logged stroke to change it on
/// the dial and drum (it lifts, thickens and wets while the others dim); tap it again to leave. No context menu:
/// Undo lives only in Tess's line (docs/design/edit-set.md).
struct LiveSetStrokes: View {
    let session: WorkoutSession
    let phase: WorkoutSession.Phase
    var onEdit: (UUID) -> Void = { _ in }

    var body: some View {
        let entry = session.currentEntry
        let rows = entry.map(session.setRows(of:)) ?? []
        let target = entry.map(session.targetSets(of:)) ?? 0
        let editingID = session.isEditing ? session.editingSetID : nil
        HStack(spacing: 0) {
            ForEach(0 ..< max(target, rows.count), id: \.self) { index in
                if index < rows.count {
                    let row = rows[index]
                    Button { onEdit(row.id) } label: {
                        LoggedStroke(number: index + 1, isFresh: session.lastSeated?.setID == row.id,
                                     isEditing: editingID == row.id,
                                     isDimmed: editingID != nil && editingID != row.id,
                                     isGhost: session.model.isGhost(row.id))
                            .frame(width: 74, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        "Set \(index + 1), \(Format.kilograms(row.weight)) kilograms by \(Int(row.reps)). Edit."
                    )
                } else {
                    GuideStroke(isCurrent: index == rows.count && phase == .set)
                        .frame(width: 74, height: 44)
                        .opacity(editingID == nil ? 1 : 0.3)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: 44)
        .id(entry?.id)
        .transition(.opacity)
    }
}

private struct LoggedStroke: View {
    let number: Int
    let isFresh: Bool
    var isEditing = false
    /// Another stroke is being edited: this one steps back to 30 %.
    var isDimmed = false
    /// Typed in the Bar and still drying: drawn wet in Tess's cobalt until it commits.
    var isGhost = false
    @State private var progress: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Reduce Motion: no lift or wet, only the dim cross-fades.
        let lifted = isEditing && !reduceMotion
        Brushstroke(progress: progress)
            .stroke(isGhost ? Paint.tess.opacity(0.55) : Paint.set(number),
                    style: StrokeStyle(lineWidth: lifted ? 13 : 9, lineCap: .round))
            .frame(width: 64, height: 20)
            .blur(radius: lifted ? 1 : 0.4)
            .offset(y: lifted ? -4 : 0)
            .opacity(isDimmed ? 0.3 : isEditing ? 1 : 0.92)
            .tesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.22), value: isEditing)
            .tesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.22), value: isDimmed)
            .onAppear {
                guard isFresh, !reduceMotion else { return }
                progress = 0
                withTesseraAnimation(.timingCurve(0.3, 0.7, 0.2, 1, duration: 0.7), reduceMotion: reduceMotion) {
                    progress = 1
                }
            }
    }
}

private struct GuideStroke: View {
    let isCurrent: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !isCurrent || reduceMotion)) { context in
            let breath = (sin(context.date.timeIntervalSinceReferenceDate / 2.4 * 2 * .pi) + 1) / 2
            Brushstroke()
                .stroke(Paint.cream, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 5]))
                .opacity(isCurrent ? 0.45 + 0.45 * breath : 0.22)
        }
        .frame(width: 64, height: 20)
    }
}
