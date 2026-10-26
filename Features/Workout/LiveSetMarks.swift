import SwiftUI
import TesseraCore

private typealias Paint = WorkoutPaint

/// The glint motif, only while a set could be a new best.
struct GlintIf: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.modifier(Glint(period: 3))
        } else {
            content
        }
    }
}

// MARK: - Sets as ink-drop marks (y)

/// The live mark (Design sheet 108): five ink drops that move like liquid, and under them one brush circle per set.
/// Logging a set plays its reps (a soft pull together each, the last two slower and trembling), then one drop's
/// circle draws, closes (the one haptic) and flies to its slot. Tap a circle for its exact line. Reduce Motion and
/// Low Power: no drops, the finished circle appears with a 150 ms crossfade. A private workout shows no values.
struct LiveSetMarks: View {
    let session: WorkoutSession
    let phase: WorkoutSession.Phase
    var onEdit: (UUID) -> Void = { _ in }
    /// The circle just closed: the moment for the one haptic.
    var onClosed: (SetMarkSpec) -> Void = { _ in }
    /// A set that was playing was undone before its circle closed: its pending haptic should be dropped.
    var onCancelled: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.lowPowerMotion) private var lowPower
    @Namespace private var flight
    @State private var swarm = InkDropSwarm()
    @State private var queue = SetMarkQueue()
    @State private var seeded = false
    @State private var detail: UUID?

    private var play: SetMarkQueue.Play? {
        queue.current
    }

    private var settled: Set<UUID> {
        queue.settled
    }

    private var calm: Bool {
        reduceMotion || lowPower
    }

    private var isPrivate: Bool {
        session.shownTitle != session.workout.title
    }

    var body: some View {
        let entry = session.currentEntry
        let rows = entry.map(session.setRows(of:)) ?? []
        let target = entry.map(session.targetSets(of:)) ?? 0
        let specs = specs(rows: rows, entry: entry)
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // The circles collect on the left; the drops live at the right of the same line (the page keeps its
            // height).
            HStack(alignment: .center, spacing: Theme.Spacing.s) {
                circles(specs: specs, target: target)
                Spacer(minLength: Theme.Spacing.s)
                stage(specs: specs)
            }
            detailLine(specs: specs)
        }
        .id(entry?.id)
        .transition(.opacity)
        .onAppear {
            guard !seeded else { return }
            seeded = true
            queue.seed(rows.map(\.id))
        }
        .onDisappear {
            // Leaving the page (or the exercise) while a circle is still drawing: it lands now, with its haptic.
            if let running = queue.current?.spec {
                queue.finish(running.id)
                onClosed(running)
            }
        }
        .onChange(of: rows.map(\.id)) { old, new in
            if queue.forget(keeping: new) {
                onCancelled()
            }
            guard let added = new.last, new.count > old.count, !queue.settled.contains(added),
                  let spec = specs.first(where: { $0.id == added })
            else { return }
            if calm {
                withTesseraAnimation(.easeInOut(duration: 0.15), reduceMotion: false) { queue.settleNow(added) }
                onClosed(spec)
            } else if let interrupted = queue.start(spec, at: .now) {
                // A second set before the first circle closed: the first lands (and fires its haptic) now.
                onClosed(interrupted)
            }
        }
        .task(id: play?.spec.id) {
            guard let play else { return }
            let spec = play.spec
            try? await Task.sleep(for: .seconds(SetMarkClock.closes(reps: spec.reps)))
            guard !Task.isCancelled else { return }
            withTesseraAnimation(.spring(response: 0.5, dampingFraction: 0.82), reduceMotion: false) {
                if queue.finish(spec.id) {
                    onClosed(spec)
                }
            }
        }
    }

    // MARK: Parts

    private func specs(rows: [WorkoutSession.SetRow], entry: ObjectRecord?) -> [SetMarkSpec] {
        let target = entry.map { Int(session.targetReps(of: $0)) } ?? 8
        let heaviest = max(rows.map(\.weight).max() ?? 0, entry.flatMap(session.targetWeight(of:)) ?? 0)
        let bests = Set(session.bests.map(\.setID))
        return rows.map { row in
            SetMarkSpec(id: row.id, number: row.number, reps: Int(row.reps), target: target, weight: row.weight,
                        heaviest: heaviest, isBest: bests.contains(row.id), isPrivate: isPrivate)
        }
    }

    /// The drops, and while a set is playing the circle drawing at the stage's centre.
    private func stage(specs _: [SetMarkSpec]) -> some View {
        ZStack {
            if !calm {
                LiveClock(LiveFeatures.workoutSetMarks, minimumInterval: nil) { context in
                    let motion = motion(at: context.date)
                    InkDropView(swarm: swarm, rep: motion.rep, warmth: motion.warmth)
                }
                if let play {
                    LiveClock(LiveFeatures.workoutSetMarks, minimumInterval: nil) { context in
                        let elapsed = context.date.timeIntervalSince(play.started)
                        let repsDone = SetMarkClock.closes(reps: play.spec.reps) - SetMarkClock.draw
                        let drawn = min(max((elapsed - repsDone) / SetMarkClock.draw, 0), 1)
                        if drawn > 0 {
                            SetMarkCircle(spec: play.spec, side: 88, drawn: drawn,
                                          age: max(elapsed - SetMarkClock.closes(reps: play.spec.reps), 0))
                                .matchedGeometryEffect(id: play.spec.id, in: flight)
                        }
                    }
                }
            }
        }
        .frame(width: calm ? 0 : 110, height: 34)
        .accessibilityHidden(true)
    }

    /// The rep under way and how warm (wet) the drops are, at `date`.
    private func motion(at date: Date) -> (rep: SwarmRep?, warmth: Double) {
        guard let play else { return (nil, 0) }
        let elapsed = date.timeIntervalSince(play.started)
        guard let rep = SetMarkClock.rep(at: elapsed, reps: play.spec.reps) else { return (nil, 0.4) }
        return (SwarmRep(index: rep.index, phase: rep.phase, reps: play.spec.reps), 1)
    }

    /// One circle per planned set: a brush circle for a logged one (flown in), a faint ring for one to come.
    private func circles(specs: [SetMarkSpec], target: Int) -> some View {
        HStack(spacing: 12) {
            ForEach(0 ..< max(target, specs.count), id: \.self) { index in
                if index < specs.count, settled.contains(specs[index].id) {
                    let spec = specs[index]
                    Button { tap(spec) } label: {
                        SetMarkCircle(spec: spec, side: 28)
                            .matchedGeometryEffect(id: spec.id, in: flight)
                            .offset(y: detail == spec.id ? -2 : 0)
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(spec.spoken { spokenMass($0) })
                    .accessibilityHint("Shows the set's line")
                } else if index < specs.count {
                    Color.clear.frame(width: 34, height: 34)
                } else {
                    Circle()
                        .stroke(Paint.cream.opacity(index == specs.count && phase == .set ? 0.45 : 0.2), lineWidth: 1.4)
                        .frame(width: 24, height: 24)
                        .frame(width: 34, height: 34)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: 34, alignment: .leading)
        .tesseraAnimation(.snappy(duration: 0.2), value: detail)
    }

    /// The tapped circle's exact line, in secondary ink at 16, with the old edit action beside it.
    @ViewBuilder
    private func detailLine(specs: [SetMarkSpec]) -> some View {
        if let id = detail, let spec = specs.first(where: { $0.id == id }) {
            HStack(spacing: Theme.Spacing.m) {
                if let line = spec.detailLine(format: { Format.mass($0) }) {
                    Text(line)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                Button("Edit") { onEdit(spec.id) }
                    .buttonStyle(.plain)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
            }
            .transition(.opacity)
        }
    }

    /// "82.5 kilograms" or "180 pounds", in the app's unit (stored weights are kilograms).
    private func spokenMass(_ kilograms: Double) -> String {
        let shown = Format.kilograms(Format.unit.fromKilograms(kilograms))
        return "\(shown) \(Format.unit == .kilograms ? "kilograms" : "pounds")"
    }

    private func tap(_ spec: SetMarkSpec) {
        detail = detail == spec.id ? nil : spec.id
    }
}
