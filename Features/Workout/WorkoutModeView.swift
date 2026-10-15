import SwiftUI
import TesseraCore

/// Full-screen live logging in a dark green-black environment. Numbers roll, plates rebuild per side,
/// holding logs a set with a stamp and a success haptic, then the rest ring counts down.
struct WorkoutModeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let session = model.session {
            WorkoutContent(session: session)
        } else {
            Color.clear.onAppear { model.isWorkoutPresented = false }
        }
    }
}

private typealias Palette = Theme.Colors.Workout

private struct WorkoutContent: View {
    @Bindable var session: WorkoutSession
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                topBar
                titleBlock.entrance(0)
                exerciseBlock.entrance(1)
                numberBlock.entrance(2, hero: true)
                PlateView(weight: session.weight)
                    .frame(maxWidth: .infinity)
                    .frame(height: 76)
                    .entrance(3)
                steppers.entrance(4)
                recordHint
                RestRow(session: session)
                logControl.entrance(5)
                doneSets
                upNext
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background(background)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: session.loggedCount)
        .sensoryFeedback(.selection, trigger: session.weight)
        .sensoryFeedback(.selection, trigger: session.reps)
    }

    private var background: some View {
        ZStack(alignment: .top) {
            Palette.ground
            RadialGradient(
                colors: [Palette.groundRaised, Palette.ground],
                center: .top,
                startRadius: 20,
                endRadius: 520
            )
            .frame(height: 520)
        }
        .ignoresSafeArea()
    }

    // MARK: Sections

    private var topBar: some View {
        HStack {
            Button {
                model.isWorkoutPresented = false
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Minimise workout")
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = AppClock.adjust(context.date).timeIntervalSince(session.startedAt)
                Text(Format.duration(elapsed))
                    .textRole(.data)
                    .foregroundStyle(Palette.inkSecondary)
                    .contentTransition(.numericText())
                    .animation(
                        MotionPolicy.resolve(Theme.Motion.house, reduceMotion: reduceMotion),
                        value: Int(elapsed)
                    )
            }
            Spacer()
            Button("Finish") { model.endWorkout() }
                .textRole(.bodyStrong)
                .frame(height: 44)
        }
        .foregroundStyle(Palette.ink)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Eyebrow(text: "Workout · live", color: Palette.signal)
            Text(session.workout.title)
                .textRole(.title)
                .foregroundStyle(Palette.ink)
        }
    }

    private var exerciseBlock: some View {
        let entry = session.currentEntry
        let logged = entry.map { session.loggedSets(of: $0).count } ?? 0
        let target = entry.map(session.targetSets(of:)) ?? 0
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Hairline(color: Palette.hairline)
            HStack {
                Eyebrow(
                    text: "Exercise \(session.currentIndex + 1) of \(session.entries.count)",
                    color: Palette.inkTertiary
                )
                Spacer()
                Eyebrow(text: "Set \(min(logged + 1, max(target, logged + 1))) of \(max(target, logged))",
                        color: Palette.inkSecondary)
                    .contentTransition(.numericText())
            }
            Text(session.currentExercise?.name ?? "Exercise")
                .textRole(.title)
                .foregroundStyle(Palette.ink)
                .id(session.currentIndex)
                .transition(.opacity.combined(with: .offset(y: 8)))
            if let exercise = session.currentExercise {
                Text(classLine(exercise))
                    .textRole(.data)
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
        .tesseraAnimation(value: session.currentIndex)
    }

    private func classLine(_ exercise: ClassDef) -> String {
        let parent = exercise.parent.map { Format.identifier($0.name, upperFirst: true) } ?? "Exercise"
        return "\(Format.identifier(exercise.name, upperFirst: true)) : \(parent) · rest \(Format.duration(session.restSeconds)) ↑"
    }

    private var numberBlock: some View {
        VStack(spacing: Theme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(Format.kilograms(session.weight))
                    .contentTransition(.numericText(value: session.weight))
                Text("×")
                    .textRole(.titleNumber)
                    .foregroundStyle(Palette.inkTertiary)
                Text("\(Int(session.reps))")
                    .contentTransition(.numericText(value: session.reps))
            }
            .textRole(.heroNumber)
            .foregroundStyle(Palette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .tesseraAnimation(Theme.Motion.snappy, value: session.weight)
            .tesseraAnimation(Theme.Motion.snappy, value: session.reps)
            .frame(maxWidth: .infinity)
            .overlay { LoggedStamp(trigger: session.loggedCount) }
            HStack {
                Text("KG")
                Spacer()
                Text("REPS")
            }
            .textRole(.label)
            .tracking(1.4)
            .foregroundStyle(Palette.inkTertiary)
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Format.kilograms(session.weight)) kilograms for \(Int(session.reps)) reps")
    }

    private var steppers: some View {
        HStack {
            StepperPair(minus: "−2.5", plus: "+2.5", label: "weight") { session.adjustWeight(by: $0 ? 2.5 : -2.5) }
            Spacer()
            StepperPair(minus: "−1", plus: "+1", label: "reps") { session.adjustReps(by: $0 ? 1 : -1) }
        }
    }

    @ViewBuilder private var recordHint: some View {
        if let best = session.previousBest, let preview = session.previewE1RM {
            let tenth = { (value: Double) in Format.kilograms((value * 10).rounded() / 10) }
            HStack(spacing: 6) {
                Image(systemName: session.isPersonalRecord ? "arrow.up.forward" : "scope")
                Text(session.isPersonalRecord
                    ? "e1RM \(tenth(preview)) · new best (was \(tenth(best.e1RM)))"
                    :
                    "\(session.repsForRecord ?? 0) reps at \(Format.kilograms(session.weight)) beats your best e1RM \(tenth(best.e1RM))")
                    .contentTransition(.opacity)
            }
            .textRole(.body)
            .foregroundStyle(session.isPersonalRecord ? Palette.signal : Palette.inkSecondary)
            .tesseraAnimation(value: session.isPersonalRecord)
        }
    }

    private var logControl: some View {
        HoldToConfirm(tint: Palette.signal, fill: Palette.signal.opacity(0.28)) {
            session.logSet()
        } label: {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "checkmark")
                Text("Hold to log set")
            }
            .textRole(.bodyStrong)
            .foregroundStyle(Palette.ink)
        }
    }

    @ViewBuilder private var doneSets: some View {
        if let entry = session.currentEntry {
            let sets = session.loggedSets(of: entry)
            if !sets.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: Theme.Spacing.s) {
                        ForEach(Array(sets.enumerated()), id: \.offset) { _, set in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                                Text("\(Format.kilograms(set.weight))×\(Int(set.reps))")
                            }
                            .textRole(.data)
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .tesseraAnimation(value: sets.count)
            }
        }
    }

    @ViewBuilder private var upNext: some View {
        let upcoming = Array(session.entries.enumerated()).filter { $0.offset != session.currentIndex }
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: "Up next", color: Palette.inkTertiary).padding(.bottom, Theme.Spacing.s)
                ForEach(upcoming, id: \.element.id) { index, entry in
                    Button {
                        withTesseraAnimation(reduceMotion: reduceMotion) { session.select(entryAt: index) }
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(session.exerciseClass(of: entry)?.name ?? "Exercise")
                                .textRole(.body)
                            Spacer()
                            let logged = session.loggedSets(of: entry).count
                            Text(logged > 0 ? "\(logged)/\(session.targetSets(of: entry)) done"
                                : "\(session.targetSets(of: entry)) × \(Int(session.targetReps(of: entry)))")
                                .textRole(.label)
                                .foregroundStyle(Palette.inkSecondary)
                        }
                        .foregroundStyle(Palette.ink)
                        .padding(.vertical, Theme.Spacing.m)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Hairline(color: Palette.hairline)
                }
            }
            .padding(.top, Theme.Spacing.l)
        }
    }
}

// MARK: - Pieces

private struct StepperPair: View {
    let minus: String
    let plus: String
    let label: String
    let step: (Bool) -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            button(minus, up: false)
            button(plus, up: true)
        }
    }

    private func button(_ title: String, up: Bool) -> some View {
        Button { step(up) } label: {
            Text(title)
                .textRole(.labelStrong)
                .foregroundStyle(Palette.ink)
                .frame(width: 64, height: 44)
                .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(PressScaleStyle())
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel("\(up ? "Increase" : "Decrease") \(label) by \(title.dropFirst())")
    }
}

/// Plates per side for the current weight on a 20 kg bar.
struct PlateView: View {
    let weight: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let sizes: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    var body: some View {
        let plates = Self.plates(for: weight)
        HStack(spacing: 2) {
            ForEach(Array(plates.reversed().enumerated()), id: \.offset) { _, kg in plate(kg) }
            Capsule().fill(Palette.inkTertiary).frame(width: 14, height: 10)
            Rectangle().fill(Palette.inkSecondary).frame(width: 110, height: 4)
            Capsule().fill(Palette.inkTertiary).frame(width: 14, height: 10)
            ForEach(Array(plates.enumerated()), id: \.offset) { _, kg in plate(kg) }
        }
        .tesseraAnimation(value: plates)
        .accessibilityLabel("Per side: " + plates.map(Format.kilograms).joined(separator: ", "))
    }

    private func plate(_ kg: Double) -> some View {
        let height: CGFloat = [25: 72, 20: 66, 15: 58, 10: 48, 5: 36, 2.5: 28, 1.25: 22][kg] ?? 22
        return RoundedRectangle(cornerRadius: 2)
            .fill(Theme.Colors.plate(kg))
            .frame(width: kg >= 10 ? 11 : 7, height: height)
            .transition(.scale(scale: 0.2, anchor: .center).combined(with: .opacity))
    }

    static func plates(for weight: Double) -> [Double] {
        var perSide = max(0, (weight - 20) / 2)
        var result: [Double] = []
        for size in sizes {
            while perSide + 0.001 >= size {
                result.append(size)
                perSide -= size
            }
        }
        return result
    }
}

private struct RestRow: View {
    let session: WorkoutSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let end = session.restEndsAt {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
                let remaining = end.timeIntervalSince(AppClock.adjust(context.date))
                if remaining > 0 {
                    HStack(spacing: Theme.Spacing.l) {
                        ZStack {
                            Circle().stroke(Palette.hairline, lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: remaining / max(session.restTotal, 1))
                                .stroke(Palette.rest, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Eyebrow(text: "Rest", color: Palette.rest)
                            Text(Format.duration(remaining.rounded(.up)))
                                .textRole(.titleNumber)
                                .foregroundStyle(Palette.ink)
                                .contentTransition(.numericText(countsDown: true))
                                .animation(Theme.Motion.snappy, value: Int(remaining))
                        }
                        Spacer()
                        Button("Skip") { session.skipRest() }
                            .textRole(.bodyStrong)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

/// "LOGGED" stamp that slams in and fades on each logged set.
private struct LoggedStamp: View {
    let trigger: Int

    struct Values {
        var scale = 1.7
        var opacity = 0.0
        var rotation = -14.0
    }

    var body: some View {
        Text("LOGGED")
            .textRole(.titleNumber).fontWeight(.bold)
            .tracking(3)
            .foregroundStyle(Palette.signal)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Palette.signal, lineWidth: 2.5))
            .keyframeAnimator(initialValue: Values(), trigger: trigger) { content, value in
                content
                    .scaleEffect(value.scale)
                    .rotationEffect(.degrees(value.rotation))
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(0.92, duration: 0.18, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.2)
                    LinearKeyframe(1.0, duration: 0.5)
                    CubicKeyframe(1.08, duration: 0.3)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: 0.08)
                    LinearKeyframe(1, duration: 0.8)
                    LinearKeyframe(0, duration: 0.3)
                }
                KeyframeTrack(\.rotation) {
                    SpringKeyframe(-7, duration: 0.25)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
