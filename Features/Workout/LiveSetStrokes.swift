import SwiftUI

private typealias Paint = WorkoutPaint

/// The glint motif, only while a set could be a new best.
struct GlintIf: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.modifier(Glint(period: 3, sheen: Color(hex: 0xFFE2A8)))
        } else {
            content
        }
    }
}

// MARK: - Sets as brushstrokes (y)

/// One stroke per planned set: logged sets are 9 pt strokes in their paint, the current set a breathing dashed cream
/// guide, later sets a faint guide. A freshly logged set paints in over 700 ms. Long-press a logged stroke to undo it.
struct LiveSetStrokes: View {
    let session: WorkoutSession
    let phase: WorkoutSession.Phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let entry = session.currentEntry
        let rows = entry.map(session.setRows(of:)) ?? []
        let target = entry.map(session.targetSets(of:)) ?? 0
        HStack(spacing: 10) {
            ForEach(0 ..< max(target, rows.count), id: \.self) { index in
                if index < rows.count {
                    LoggedStroke(number: index + 1, isFresh: session.lastSeated?.setID == rows[index].id)
                        .contextMenu {
                            if index == rows.count - 1, session.undoable?.setID == rows[index].id, session.canUndo {
                                Button("Undo set \(index + 1)", systemImage: "arrow.uturn.backward") {
                                    withTesseraAnimation(reduceMotion: reduceMotion) { session.undoLastSet() }
                                }
                            }
                        }
                        .accessibilityLabel(
                            "Set \(index + 1), \(Format.kilograms(rows[index].weight)) by \(Int(rows[index].reps))"
                        )
                } else {
                    GuideStroke(isCurrent: index == rows.count && phase == .set)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: 20)
        .id(entry?.id)
        .transition(.opacity)
    }
}

private struct LoggedStroke: View {
    let number: Int
    let isFresh: Bool
    @State private var progress: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Brushstroke(progress: progress)
            .stroke(Paint.set(number), style: StrokeStyle(lineWidth: 9, lineCap: .round))
            .frame(width: 64, height: 20)
            .blur(radius: 0.4)
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
