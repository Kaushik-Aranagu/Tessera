import SwiftUI
import TesseraCore

/// Live workout, a foreground process (it rises as a full-screen cover). One screen, three axes:
/// x = the exercises of the session (a paged lane; the next name peeks in), y = the sets of the current exercise
/// (seated sets stack above, the dialled set sits at eye level, the remaining one waits below), z = tap the exercise
/// name to zoom into its page. The set block changes role: after a set is seated, the weight numeral and the dial
/// become the rest countdown, so nothing new appears.
///
/// Round 6 "Plein air" (docs/design/workout-v1.md): dark painterly ground, one exercise, one number, one action.
struct WorkoutModeView: View {
    @Environment(AppModel.self) private var model
    @Namespace private var zoom

    var body: some View {
        @Bindable var model = model
        if let session = model.session {
            NavigationStack(path: $model.workoutPath) {
                WorkoutContent(session: session)
                    .toolbarVisibility(.hidden, for: .navigationBar)
                    .navigationDestination(for: Route.self) { route in
                        ObjectPage(route: route)
                            .environment(\.animateEntrance, model.consumeFirstVisit(route))
                            .modifier(ArrivalTransition(
                                id: route,
                                arrival: model.arrivals[route] ?? .crossFade,
                                namespace: zoom
                            ))
                    }
            }
            .environment(\.zoomNamespace, zoom)
        } else {
            Color.clear.onAppear { model.isWorkoutPresented = false }
        }
    }
}

private typealias Palette = Theme.Colors.Workout

/// Paint for the workout's dark ground: colours that mean something.
private enum Paint {
    static let live = Color(hex: 0xD9563F)
    static let tess = Color(hex: 0x9DBFE6)
    static let tessBar = Color(hex: 0xC9D9EE)
    static let now = Color(hex: 0xE8BD4C)
    static let health = Color(hex: 0x7FB07A)
    static let cobalt = Color(hex: 0x3F7FC0)
    static let secondary = Color(hex: 0xA79FB5)
    static let cream = Color(hex: 0xF3ECE0)

    /// Each logged set leaves a stroke; the colour cycles set to set.
    static func set(_ number: Int) -> Color {
        [live, cobalt, now, health][(number - 1) % 4]
    }
}

private struct WorkoutContent: View {
    @Bindable var session: WorkoutSession
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.zoomNamespace) private var zoomNamespace

    /// The lane's scroll position (x). Kept in step with `session.currentIndex` both ways.
    @State private var laneIndex: Int?
    @State private var tessMode: TessSoul.Mode = .idle
    @State private var lockHaptic = 0
    @State private var celebrated = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = AppClock.adjust(context.date)
            let phase = session.phase(at: now)
            VStack(alignment: .leading, spacing: 0) {
                header(now: now)
                    .padding(.horizontal, Theme.Spacing.gutter)
                    .padding(.top, Theme.Spacing.m)
                lane.padding(.top, Theme.Spacing.m)
                SetStrokes(session: session, phase: phase)
                    .padding(.horizontal, Theme.Spacing.gutter)
                    .padding(.top, Theme.Spacing.l)
                subline(phase: phase)
                    .padding(.horizontal, Theme.Spacing.gutter)
                    .padding(.top, Theme.Spacing.m)
                numberRow(phase: phase, now: now)
                    .padding(.horizontal, Theme.Spacing.gutter)
                    .padding(.top, Theme.Spacing.xl)
                Spacer(minLength: Theme.Spacing.m)
                WeightDial(
                    weight: $session.weight,
                    isLocked: phase != .set,
                    restFraction: session.restFraction(at: now)
                )
                Spacer(minLength: Theme.Spacing.m)
                keyRow(phase: phase)
                    .padding(.horizontal, Theme.Spacing.gutter)
                tessBar(phase: phase)
                    .padding(.horizontal, 14)
                    .padding(.top, Theme.Spacing.l)
            }
        }
        .overlay(alignment: .top) {
            ProcessSeam(color: Paint.live).ignoresSafeArea(edges: .top)
        }
        .background { PleinGround() }
        .preferredColorScheme(.dark)
        .onAppear { laneIndex = session.currentIndex }
        .onChange(of: laneIndex) { _, index in
            guard let index, index != session.currentIndex else { return }
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { session.select(entryAt: index) }
        }
        .onChange(of: session.currentIndex) { _, index in
            guard laneIndex != index else { return }
            withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) { laneIndex = index }
        }
        .onChange(of: session.lastSeated) { _, seated in
            guard let seated else { return }
            Task { @MainActor in
                // The key lands the set (rigid); it locks (success) once its stroke has painted in.
                try? await Task.sleep(for: .milliseconds(700))
                lockHaptic += 1
            }
            if seated.records.isEmpty {
                play(.done)
            } else {
                celebrated += 1
                play(.thinking, then: .done, after: 1.2)
            }
        }
        .sensoryFeedback(.success, trigger: lockHaptic)
    }

    private func play(_ mode: TessSoul.Mode, then next: TessSoul.Mode? = nil, after delay: Double = 0) {
        tessMode = mode
        Task { @MainActor in
            if let next {
                try? await Task.sleep(for: .seconds(delay))
                tessMode = next
            }
            try? await Task.sleep(for: .seconds(1.8))
            tessMode = .idle
        }
    }

    // MARK: Header and lane (x)

    private func header(now: Date) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(session.workout.title), \(Format.duration(now.timeIntervalSince(session.startedAt)))")
                .font(Theme.voice)
                .foregroundStyle(Paint.secondary)
                .contentTransition(.numericText())
            Spacer()
            Text("\((laneIndex ?? session.currentIndex) + 1) / \(session.entries.count)")
                .textRole(.label)
                .foregroundStyle(Paint.secondary)
            Button {
                model.isWorkoutPresented = false
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Paint.cream)
                    .frame(width: 44, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Minimise workout")
        }
        .accessibilityElement(children: .contain)
    }

    private var lane: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(session.entries.enumerated()), id: \.offset) { index, entry in
                    let exercise = session.exerciseClass(of: entry)
                    let isCurrent = index == (laneIndex ?? session.currentIndex)
                    Button {
                        if let exercise {
                            model.open(.classDef(exercise.id), .deeper)
                        }
                    } label: {
                        Text(exercise?.name ?? "Exercise")
                            .textRole(.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(Paint.cream.opacity(isCurrent ? 1 : 0.28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .modifier(ZoomSource(id: exercise.map { Route.classDef($0.id) }, namespace: zoomNamespace))
                    .containerRelativeFrame(.horizontal) { width, _ in width - Theme.Spacing.gutter - 46 }
                    .id(index)
                    .accessibilityHint(isCurrent ? "Opens the exercise page" : "")
                    .tesseraAnimation(.easeOut(duration: 0.24), value: isCurrent)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.leading, Theme.Spacing.gutter, for: .scrollContent)
        .contentMargins(.trailing, 46, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .scrollPosition(id: $laneIndex, anchor: .leading)
        .scrollIndicators(.hidden)
        .frame(height: 64)
    }

    // MARK: y, in words and numbers

    private func subline(phase: WorkoutSession.Phase) -> some View {
        let (text, color) = sublineText(phase: phase)
        return Text(text)
            .font(Theme.voice)
            .foregroundStyle(color)
            .contentTransition(.opacity)
            .tesseraAnimation(value: text)
    }

    private func sublineText(phase: WorkoutSession.Phase) -> (String, Color) {
        guard let entry = session.currentEntry else { return ("", Paint.secondary) }
        let target = session.targetSets(of: entry)
        let rows = session.setRows(of: entry)
        let tenth = { (value: Double) in Format.kilograms((value * 10).rounded() / 10) }
        switch phase {
        case .rest:
            if let seated = session.lastSeated, !seated.records.isEmpty, let e1RM = seated.e1RM {
                return ("a new best: e1RM \(tenth(e1RM))", Paint.now)
            }
            return ("set \(rows.count) seated", Paint.secondary)
        case .exerciseDone:
            return ("all \(target) sets in. Swipe for the next.", Paint.secondary)
        case .workoutDone:
            return ("every set is in", Paint.secondary)
        case .set:
            if session.isPersonalRecord {
                return ("set \(session.currentSetNumber): this would be a new best", Paint.now)
            }
            let last = rows.last.map { ", last was \(Format.kilograms($0.weight)) × \(Int($0.reps))" } ?? ""
            return ("set \(session.currentSetNumber) of \(target)\(last)", Paint.secondary)
        }
    }

    private func numberRow(phase: WorkoutSession.Phase, now: Date) -> some View {
        HStack(alignment: .top) {
            if case let .rest(end) = phase {
                let remaining = max(0, end.timeIntervalSince(now)).rounded(.up)
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(Format.duration(remaining))
                            .font(Theme.numeral(72))
                            .foregroundStyle(Paint.now)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(MotionPolicy.resolve(Theme.Motion.snappy, reduceMotion: reduceMotion),
                                       value: remaining)
                        Text("rest").font(Theme.voice).foregroundStyle(Paint.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Rest, \(Int(remaining)) seconds left")
                    Text("Rest lives in the dial. When it empties, it turns back into weight.")
                        .font(Theme.voice)
                        .foregroundStyle(Paint.tess)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity.combined(with: .blurReplace))
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(Format.kilograms(session.weight))
                            .font(Theme.numeral(72))
                            .foregroundStyle(Paint.cream)
                            .contentTransition(.numericText(value: session.weight))
                            .animation(MotionPolicy.resolve(Theme.Motion.snappy, reduceMotion: reduceMotion),
                                       value: session.weight)
                            .modifier(GlintIf(isOn: phase == .set && session.isPersonalRecord))
                        Text("kg").font(Theme.voice).foregroundStyle(Paint.secondary)
                    }
                    .accessibilityHidden(true)
                    PlateStack(weight: session.weight)
                }
                Spacer(minLength: Theme.Spacing.s)
                VStack(spacing: 2) {
                    RepsDrum(reps: repsBinding, ghost: lastReps)
                        .disabled(phase != .set)
                    Text("reps").font(Theme.voice(size: 18)).foregroundStyle(Paint.cream.opacity(0.55))
                }
                .transition(.opacity)
            }
        }
        .frame(height: 170, alignment: .top)
        .tesseraAnimation(.easeOut(duration: 0.32), value: phase == .set)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.8), trigger: celebrated)
    }

    private var repsBinding: Binding<Int> {
        Binding(get: { Int(session.reps) }, set: { session.reps = Double($0) })
    }

    private var lastReps: Int? {
        guard let entry = session.currentEntry else { return nil }
        return session.setRows(of: entry).last.map { Int($0.reps) } ?? Int(session.targetReps(of: entry))
    }

    // MARK: The key

    private func keyRow(phase: WorkoutSession.Phase) -> some View {
        HStack(spacing: Theme.Spacing.l) {
            switch phase {
            case .set:
                PaintKey(finish: .cream, paint: Paint.live, duration: 0.8, height: 62) {
                    withTesseraAnimation(reduceMotion: reduceMotion) { session.logSet() }
                } label: { holding in
                    Text(holding ? "Keep holding" : "Hold to log").textRole(.bodyStrong)
                }
                .frame(width: 240)
                .accessibilityLabel(
                    "Hold to log set \(session.currentSetNumber), \(Format.kilograms(session.weight)) kilograms for \(Int(session.reps)) reps"
                )
                Text("\(Format.kilograms(session.weight)) × \(Int(session.reps))")
                    .textRole(.label)
                    .foregroundStyle(Paint.cream)
            case .rest:
                PaintKey(finish: .cream, paint: Paint.now, isTap: true, height: 62) {
                    withTesseraAnimation(reduceMotion: reduceMotion) { session.skipRest() }
                } label: { _ in
                    Text("Skip rest").textRole(.bodyStrong)
                }
                .frame(width: 240)
                Button("+15s") { session.extendRest(by: 15) }
                    .textRole(.label)
                    .foregroundStyle(Paint.cream)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Add 15 seconds of rest")
            case .exerciseDone:
                PaintKey(finish: .cream, paint: Paint.cobalt, isTap: true, height: 62) {
                    if let next = session.nextUnfinishedIndex {
                        withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) { laneIndex = next }
                    }
                } label: { _ in
                    Text("Next exercise").textRole(.bodyStrong)
                }
                .frame(width: 240)
            case .workoutDone:
                PaintKey(finish: .cream, paint: Paint.live, height: 62) {
                    model.endWorkout()
                } label: { holding in
                    Text(holding ? "Keep holding" : "Hold to finish").textRole(.bodyStrong)
                }
                .frame(width: 240)
                Text("\(session.entries.reduce(0) { $0 + session.setRows(of: $1).count }) sets")
                    .textRole(.label)
                    .foregroundStyle(Paint.cream)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 62)
    }

    // MARK: Tess

    private func tessBar(phase: WorkoutSession.Phase) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return HStack(spacing: Theme.Spacing.s) {
            TessSoul(mode: tessMode)
                .scaleEffect(0.5)
                .frame(width: 56, height: 56)
                .blendMode(.screen)
            Text(tessLine(phase: phase))
                .font(Theme.voice)
                .foregroundStyle(Paint.tessBar)
                .lineLimit(2)
                .contentTransition(.opacity)
                .tesseraAnimation(value: tessLine(phase: phase))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 66)
        .background(shape.fill(.white.opacity(0.07)))
        .glassEffect(.regular, in: shape)
        .overlay {
            shape.strokeBorder(LinearGradient(stops: [.init(color: .white.opacity(0.16), location: 0),
                                                      .init(color: .clear, location: 0.06)],
                                              startPoint: .top, endPoint: .bottom), lineWidth: 1)
        }
        .overlay { shape.stroke(.black.opacity(0.6), lineWidth: 0.5) }
        .accessibilityElement(children: .combine)
    }

    private func tessLine(phase: WorkoutSession.Phase) -> String {
        if case .rest = phase, let seated = session.lastSeated {
            return seated.records.isEmpty ? "Seated. Next set when the dial empties." : "That one goes on the wall."
        }
        switch phase {
        case .exerciseDone: return "\(session.currentExercise?.name ?? "That") is done."
        case .workoutDone: return "Everything's in. Hold to finish."
        default:
            if session.isPersonalRecord {
                return "Go on. You have this."
            }
            if let best = session.previousBest {
                return "Last best was \(Format.kilograms(best.weight)) × \(Int(best.reps))."
            }
            return "Same as last time is fine."
        }
    }
}

/// The glint motif, only while a set could be a new best.
private struct GlintIf: ViewModifier {
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
private struct SetStrokes: View {
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
                            if index == rows.count - 1 {
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
                withAnimation(.timingCurve(0.3, 0.7, 0.2, 1, duration: 0.7)) { progress = 1 }
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
