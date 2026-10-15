import SwiftUI
import TesseraCore

/// Today: a greeting that writes itself in, a thin day strip, one hero ("Now"), a departures-board schedule
/// and tonight's workout. No cards — hierarchy comes from the four type sizes, margins and negative space.
struct TodayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let _ = model.revision
        let now = AppClock.now
        let schedule = model.schedule(around: now)
        let done = schedule.filter { !$0.isWorkout && $0.status(at: now) == .done }.count
        let total = schedule.filter { !$0.isWorkout }.count

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Eyebrow(text: now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())).entrance(0)
                    RevealText(text: greeting(for: now), role: .title, once: $model.hasRevealedGreeting).entrance(1)
                    Text("\(done) of \(total) done")
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .contentTransition(.numericText())
                        .tesseraAnimation(value: done)
                        .entrance(2)
                }
                .padding(.bottom, Theme.Spacing.xl)

                DayStrip(schedule: schedule).entrance(3)
                    .padding(.bottom, Theme.Spacing.section)

                NowSection().padding(.bottom, Theme.Spacing.section)

                DeparturesSection(schedule: schedule).padding(.bottom, Theme.Spacing.section)

                if let workout = model.tonightWorkout(around: now) {
                    TonightSection(workout: workout)
                }
            }
            .padding(.leading, Theme.Spacing.gutter - 6)
            .padding(.trailing, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, 180)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background { ThemedBackground() }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private func greeting(for date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5 ..< 12: "Good morning, Kaushik."
        case 12 ..< 17: "Good afternoon, Kaushik."
        case 17 ..< 23: "Good evening, Kaushik."
        default: "Still up, Kaushik?"
        }
    }
}

// MARK: - Day strip

/// A thin line for the waking day with a tick per item and a moving now-marker.
private struct DayStrip: View {
    let schedule: [ScheduleItem]
    private let startHour = 6.0, endHour = 24.0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let now = AppClock.adjust(context.date)
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .topLeading) {
                    Hairline().offset(y: 30)
                    ForEach(schedule) { item in
                        let status = item.status(at: now)
                        Capsule()
                            .fill(item.isWorkout ? Theme.Colors.training
                                : status == .done ? Theme.Colors.inkTertiary : Theme.Colors.ink)
                            .frame(width: max(4, width * span(item)), height: item.isWorkout ? 8 : 5)
                            .offset(x: width * position(item.start), y: item.isWorkout ? 26.5 : 28)
                    }
                    ForEach([6, 12, 18], id: \.self) { hour in
                        Text(String(format: "%02d", hour))
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .offset(x: width * fraction(Double(hour)), y: 40)
                    }
                    let x = width * position(now)
                    VStack(spacing: 3) {
                        Text(Format.clock(now))
                            .textRole(.data)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.Colors.live)
                            .fixedSize()
                        Rectangle().fill(Theme.Colors.live).frame(width: 2, height: 12)
                        Circle().fill(Theme.Colors.live).frame(width: 7, height: 7)
                    }
                    .frame(width: 60)
                    .offset(x: x - 30, y: -6)
                    .tesseraAnimation(value: x)
                }
            }
            .frame(height: 64)
            .accessibilityElement()
            .accessibilityLabel("Day timeline. Now \(Format.clock(now)).")
        }
    }

    private func fraction(_ hour: Double) -> CGFloat {
        CGFloat(min(max((hour - startHour) / (endHour - startHour), 0), 1))
    }

    private func position(_ date: Date) -> CGFloat {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return fraction(Double(parts.hour ?? 0) + Double(parts.minute ?? 0) / 60)
    }

    private func span(_ item: ScheduleItem) -> CGFloat {
        CGFloat(item.end.timeIntervalSince(item.start) / 3600 / (endHour - startHour))
    }
}

// MARK: - Now

private struct NowSection: View {
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finishingID: UUID?
    @State private var completion: Double = 0

    var body: some View {
        let _ = model.revision
        let task = model.currentTask()
        MarginSection(label: task.map { $0.start <= AppClock.now ? "Now" : "Next" } ?? "Now",
                      color: Theme.Colors.live)
        {
            Group {
                if let task {
                    content(task)
                        .id(task.id)
                        .transition(.asymmetric(
                            insertion: (reduceMotion ? AnyTransition.opacity
                                : AnyTransition.move(edge: .bottom).combined(with: .opacity))
                                .animation(Theme.Motion.house.delay(0.12)),
                            removal: AnyTransition.opacity.animation(.easeOut(duration: 0.14))
                        ))
                } else {
                    Text("Nothing scheduled. The evening is yours.")
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                }
            }
        }
        .entrance(4)
        .tesseraAnimation(value: task?.id)
    }

    private func content(_ task: ScheduleItem) -> some View {
        let finishing = finishingID == task.id
        let isNow = task.start <= AppClock.now
        return VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            Text("\(Format.clock(task.start)) – \(Format.clock(task.end))")
                .textRole(.data)
                .foregroundStyle(Theme.Colors.inkSecondary)

            Button {
                model.open(.object(task.id))
            } label: {
                RevealingHero(text: task.title, completion: finishing ? completion : 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(HandleButtonStyle())
            .modifier(ZoomSource(id: Route.object(task.id), namespace: namespace))
            // The check sits in the margin-free corner so it never re-wraps the hero.
            .overlay(alignment: .bottomTrailing) {
                if finishing {
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Theme.Colors.live)
                        .transition(.symbolEffect(.drawOn))
                        .offset(y: 4)
                }
            }
            .entrance(5, hero: true)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let now = AppClock.adjust(context.date)
                let remaining = isNow ? task.end.timeIntervalSince(now) : task.start.timeIntervalSince(now)
                let progress = min(
                    max(now.timeIntervalSince(task.start) / task.end.timeIntervalSince(task.start), 0),
                    1
                )
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                        Text(Format.duration(remaining))
                            .textRole(.titleNumber)
                            .foregroundStyle(Theme.Colors.ink)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(
                                MotionPolicy.resolve(Theme.Motion.house, reduceMotion: reduceMotion),
                                value: Int(remaining)
                            )
                        Text(isNow ? "left" : "until it starts")
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Hairline()
                            Rectangle().fill(Theme.Colors.live)
                                .frame(width: proxy.size.width * (isNow ? progress : 0), height: 3)
                        }
                    }
                    .frame(height: 3)
                }
            }

            HoldToConfirm(tint: Theme.Colors.ink, fill: Theme.Colors.live.opacity(0.2)) {
                finish(task)
            } label: {
                Text("Hold to finish")
                    .textRole(.bodyStrong)
                    .foregroundStyle(Theme.Colors.ink)
            }
            .disabled(finishing)
        }
    }

    private func finish(_ task: ScheduleItem) {
        completion = 0
        withAnimation(MotionPolicy.resolve(Theme.Motion.house, reduceMotion: reduceMotion)) { finishingID = task.id }
        withAnimation(.easeInOut(duration: reduceMotion ? 0.01 : 0.6).delay(0.1)) { completion = 1 } completion: {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(450))
                withAnimation(MotionPolicy.resolve(Theme.Motion.house, reduceMotion: reduceMotion)) {
                    model.finish(taskID: task.id)
                    finishingID = nil
                }
            }
        }
    }
}

// MARK: - Departures

private struct DeparturesSection: View {
    let schedule: [ScheduleItem]

    var body: some View {
        MarginSection(label: "Today") {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                let now = AppClock.adjust(context.date)
                VStack(spacing: 0) {
                    ForEach(Array(schedule.enumerated()), id: \.element.id) { index, item in
                        DepartureRow(item: item, status: item.status(at: now))
                            .scrollTransition(.animated(Theme.Motion.house)) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.2)
                                    .blur(radius: phase.isIdentity ? 0 : 3)
                                    .offset(y: phase.value * 10)
                            }
                        if index < schedule.count - 1 {
                            RowSeparator()
                        }
                    }
                }
            }
        }
    }
}

private struct DepartureRow: View {
    let item: ScheduleItem
    let status: ScheduleItem.Status

    var body: some View {
        let dim = status == .done
        ObjectRow(
            title: item.title,
            route: .object(item.id),
            role: item.isWorkout ? .bodyStrong : .body,
            color: dim ? Theme.Colors.inkTertiary : item.isWorkout ? Theme.Colors.training : Theme.Colors.ink,
            underline: dim ? .clear : Theme.Colors.inkTertiary,
            showsArrow: false
        ) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.clock(item.start))
                    .textRole(.data)
                    .foregroundStyle(dim ? Theme.Colors.inkTertiary : Theme.Colors.ink)
                Text(status.rawValue)
                    .textRole(.labelStrong)
                    .foregroundStyle(color)
                    .contentTransition(.opacity)
            }
        }
    }

    private var color: Color {
        switch status {
        case .now, .boarding: Theme.Colors.live
        case .soon: Theme.Colors.ink
        case .later, .done: Theme.Colors.inkTertiary
        }
    }
}

// MARK: - Tonight

private struct TonightSection: View {
    let workout: ObjectRecord
    @Environment(AppModel.self) private var model

    var body: some View {
        let entries = workout.orderedChildren
        let scheduled: Date? = if case let .date(date)? = model.store.value("scheduledFor", of: workout) {
            date
        } else {
            nil
        }
        let isEvening = scheduled.map { Calendar.current.component(.hour, from: $0) >= 17 } ?? false
        let isActive = model.session?.workout.id == workout.id

        MarginSection(label: isEvening ? "Tonight" : "Later", color: Theme.Colors.training) {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text([scheduled.map(Format.clock), "Workout"].compactMap(\.self).joined(separator: " · "))
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.training)
                    ObjectHandle(title: workout.title, route: .object(workout.id), role: .title)
                }

                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        if let exercise = model.store.linkedClass("exercise", of: entry) {
                            ObjectRow(title: exercise.name, route: .classDef(exercise.id)) {
                                Text(target(entry))
                                    .textRole(.data)
                                    .foregroundStyle(Theme.Colors.inkSecondary)
                            }
                            if index < entries.count - 1 {
                                RowSeparator()
                            }
                        }
                    }
                }

                if let hint = recordHint(entries.first) {
                    Text(hint)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.progress)
                }

                Button {
                    model.startWorkout(workout)
                } label: {
                    HStack(spacing: Theme.Spacing.s) {
                        Text(isActive ? "Resume workout" : "Start workout")
                        Image(systemName: "arrow.up")
                    }
                    .textRole(.bodyStrong)
                    .foregroundStyle(Theme.Colors.paper)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.l)
                    .background(Theme.Colors.training, in: Capsule())
                }
                .buttonStyle(PressScaleStyle())
            }
        }
    }

    private func target(_ entry: ObjectRecord) -> String {
        let sets = Int(model.store.number("targetSets", of: entry) ?? 0)
        let reps = Int(model.store.number("targetReps", of: entry) ?? 0)
        let weight = model.store.number("targetWeight", of: entry).map(Format.kilograms) ?? ""
        return "\(sets)×\(reps)  \(weight)"
    }

    private func recordHint(_ entry: ObjectRecord?) -> String? {
        guard let entry, let exercise = model.store.linkedClass("exercise", of: entry),
              let weight = model.store.number("targetWeight", of: entry),
              let reps = model.store.number("targetReps", of: entry),
              let preview = model.previewE1RM(weight: weight, reps: reps),
              let best = model.bestSet(of: exercise), preview > best.e1RM else { return nil }
        return "\(Format.kilograms(weight)) × \(Int(reps)) on \(exercise.name.lowercased()) would be a new best."
    }
}
