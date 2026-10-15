import SwiftUI
import TesseraCore

private typealias Paint = WorkoutPaint

// MARK: - The strip (the top seam)

/// The process seam on the top edge is the exercise strip: one 3 pt segment per exercise with 4 pt gaps, edge to
/// edge. Done is cream at 82%, the current one is lit vermilion with the process glint travelling along it every
/// 4.5 s, the rest are cream at 20%. No dots, no labels. When the workout is finished every segment is cream.
struct ExerciseStrip: View {
    enum Segment: Equatable {
        case done, current, remaining
    }

    let segments: [Segment]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let period = 4.5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(segments.indices, id: \.self) { index in
                segment(segments[index])
            }
        }
        .frame(height: 3)
        .tesseraAnimation(.easeOut(duration: 0.42), value: segments)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func segment(_ kind: Segment) -> some View {
        switch kind {
        case .done:
            Paint.cream.opacity(0.82)
        case .remaining:
            Paint.cream.opacity(0.2)
        case .current:
            TimelineView(.animation(minimumInterval: 1 / 60, paused: reduceMotion)) { context in
                let time = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: Self.period)
                    / Self.period
                // The glint crosses in the first 30% of each period, then the segment just glows.
                let sweep = reduceMotion ? -1 : min(time / 0.3, 1)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Paint.live
                        LinearGradient(colors: [Paint.live.opacity(0), Paint.sheen, Paint.live.opacity(0)],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: proxy.size.width * 0.5)
                            .offset(x: proxy.size.width * (1.5 * sweep) - proxy.size.width * 0.5)
                            .opacity(sweep >= 1 || sweep < 0 ? 0 : 1)
                    }
                    .clipped()
                }
            }
            .shadow(color: Paint.live.opacity(0.8), radius: 5)
        }
    }
}

// MARK: - Running order

/// Pull down on the seam (or tap it): the running order drops over the top of the screen as a dark glass sheet.
/// One row per exercise at a 64 pt pitch; the current row is cream with a lit vermilion bar and its set count in
/// cadmium. Hold a name and drag to reorder (for today only; the plan keeps its order): the row lifts and the others
/// close up around it. Tap a row to go to it. Swipe up or tap outside to close.
struct RunningOrderSheet: View {
    let session: WorkoutSession
    var topInset: CGFloat
    var onSelect: (Int) -> Void
    var onClose: () -> Void

    @State private var dragging: UUID?
    @State private var dragOffset: CGFloat = 0
    @State private var liftHaptic = 0
    @State private var slotHaptic = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let pitch: CGFloat = 64

    var body: some View {
        let entries = session.entries
        let from = dragging.flatMap { id in entries.firstIndex { $0.id == id } }
        let destination = from.map { target(from: $0, count: entries.count) }
        VStack(alignment: .leading, spacing: 0) {
            Text("Running order")
                .textRole(.label)
                .foregroundStyle(Paint.secondary)
                .padding(.bottom, Theme.Spacing.s)
                .accessibilityAddTraits(.isHeader)
            ZStack(alignment: .top) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    row(entry, index: index, count: entries.count)
                        .offset(y: CGFloat(index) * Self.pitch + shift(index, from: from, to: destination))
                        .zIndex(entry.id == dragging ? 1 : 0)
                }
            }
            .frame(height: CGFloat(entries.count) * Self.pitch, alignment: .top)
            .tesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.42), value: destination)
            Text("Hold a name and drag. Today only; the plan keeps its order.")
                .font(Theme.voice(size: 18))
                .foregroundStyle(Paint.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.m)
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.top, topInset + 18)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .workoutGlass(UnevenRoundedRectangle(bottomLeadingRadius: 34, bottomTrailingRadius: 34, style: .continuous))
        .simultaneousGesture(
            DragGesture(minimumDistance: 20).onEnded { drag in
                if dragging == nil, drag.translation.height < -40 {
                    onClose()
                }
            }
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: liftHaptic)
        .sensoryFeedback(.selection, trigger: slotHaptic)
        .onChange(of: destination) { _, new in
            if new != nil {
                slotHaptic += 1
            }
        }
        .accessibilityAction(.escape, onClose)
    }

    private func row(_ entry: ObjectRecord, index: Int, count: Int) -> some View {
        let isCurrent = index == session.currentIndex
        let isLifted = entry.id == dragging
        let name = session.exerciseClass(of: entry)?.name ?? "Exercise"
        let done = session.isFinished(entry)
        return HStack(spacing: 14) {
            Paint.live
                .frame(width: 3, height: 30)
                .shadow(color: Paint.live.opacity(0.8), radius: 5)
                .opacity(isCurrent ? 1 : 0)
            Text(name)
                .font(Theme.numeral(28, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Paint.cream.opacity(isCurrent || isLifted ? 1 : 0.5))
            Spacer(minLength: Theme.Spacing.s)
            if isCurrent, !done {
                Text("Set \(session.currentSetNumber) of \(session.targetSets(of: entry))")
                    .textRole(.label)
                    .foregroundStyle(Paint.now)
            } else {
                Text(done ? "Done" : session.scheme(of: entry))
                    .textRole(.label)
                    .foregroundStyle(Paint.secondary.opacity(isCurrent ? 1 : 0.7))
            }
        }
        .padding(.horizontal, 10)
        .frame(height: Self.pitch)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Paint.cream.opacity(isLifted ? 0.1 : 0))
                .shadow(color: .black.opacity(isLifted ? 0.4 : 0), radius: 14)
        }
        .scaleEffect(isLifted && !reduceMotion ? 1.03 : 1)
        .offset(y: isLifted ? dragOffset : 0)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(index)
        }
        .gesture(reorder(entry, index: index, count: count))
        .tesseraAnimation(Theme.Motion.snappy, value: isLifted)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Goes to this exercise")
        .accessibilityAction(named: "Move up") { session.move(entryID: entry.id, to: index - 1) }
        .accessibilityAction(named: "Move down") { session.move(entryID: entry.id, to: index + 1) }
    }

    private func reorder(_ entry: ObjectRecord, index _: Int, count _: Int) -> some Gesture {
        LongPressGesture(minimumDuration: 0.4, maximumDistance: 20)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case let .second(true, drag) = value else { return }
                if dragging != entry.id {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { dragging = entry.id }
                    liftHaptic += 1
                }
                dragOffset = drag?.translation.height ?? 0
            }
            .onEnded { _ in
                let entries = session.entries
                if let id = dragging, let from = entries.firstIndex(where: { $0.id == id }) {
                    let destination = target(from: from, count: entries.count)
                    withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.42), reduceMotion: reduceMotion) {
                        session.move(entryID: id, to: destination)
                        dragging = nil
                        dragOffset = 0
                    }
                } else {
                    dragging = nil
                    dragOffset = 0
                }
            }
    }

    private func target(from: Int, count: Int) -> Int {
        min(max(from + Int((dragOffset / Self.pitch).rounded()), 0), count - 1)
    }

    /// Rows between the lifted row's old and new place close up around it.
    private func shift(_ index: Int, from: Int?, to destination: Int?) -> CGFloat {
        guard let from, let destination, index != from else { return 0 }
        if from < destination, index > from, index <= destination {
            return -Self.pitch
        }
        if from > destination, index >= destination, index < from {
            return Self.pitch
        }
        return 0
    }
}
