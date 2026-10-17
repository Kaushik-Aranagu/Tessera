import SwiftUI
import TesseraCore

/// A routine's own page, and its editor (ship list slice 10). One row per exercise, separated by space; tap a row to
/// open it in place: sets and the rep range on bare − / + keys, move it earlier or later, swap it for another
/// exercise, or take it out. "Add an exercise" opens the library under the list, grouped by movement pattern.
/// Every change is a Core action (EditSlot, MoveSlot, SwapSlotExercise, AddSlot, DeleteObject) in the op log, and
/// the last one can be undone from Tess's line in her band beside the soul (`TessVoice`).
struct RoutineEditor: View {
    let routine: ObjectRecord
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    /// The slot opened in place.
    @State private var openSlot: UUID?
    /// The library under the list: adding a new exercise, or choosing a swap for a slot.
    @State private var library: LibraryMode?
    @State private var haptic = 0

    enum LibraryMode: Equatable {
        case add
        case swap(UUID)
    }

    var body: some View {
        let _ = model.revision
        let slots = routine.orderedChildren
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header(slots: slots)
                        .padding(.bottom, Theme.Spacing.xl)

                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                            SlotEditorRow(
                                slot: slot,
                                isOpen: openSlot == slot.id,
                                isFirst: index == 0,
                                isLast: index == slots.count - 1,
                                onToggle: { toggle(slot.id) },
                                perform: perform,
                                onSwap: { setLibrary(.swap(slot.id)) },
                                index: index
                            )
                        }
                    }
                    .entrance(3)

                    Button {
                        setLibrary(library == .add ? nil : .add)
                    } label: {
                        Text(library == .add ? "Close the library" : "Add an exercise →")
                            .textRole(.bodyStrong)
                            .foregroundStyle(Theme.Colors.ink)
                            .frame(minHeight: 60)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HandleButtonStyle())
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(4)

                    if let library {
                        ExerciseLibraryList(title: libraryTitle(library, slots: slots)) { exercise in
                            choose(exercise, for: library)
                        }
                        .id("library")
                        .padding(.top, Theme.Spacing.m)
                        .transition(.opacity.combined(with: .offset(y: 12)))
                        .onAppear {
                            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
                                proxy.scrollTo("library", anchor: .top)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, 200)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            // Tess's band (her line and UNDO beside the soul) is never a place a row comes to rest.
            .contentMargins(.bottom, 84, for: .scrollContent)
        }
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .background { EdgeSwipeBack() }
        .sensoryFeedback(.selection, trigger: haptic)
    }

    /// "Routines" when he came from the Routines page, else "Training".
    private var cameFrom: String {
        let stack = model.isWorkoutPresented ? model.workoutPath : model.path
        guard stack.count >= 2 else { return "Training" }
        if case .routines = stack[stack.count - 2] {
            return "Routines"
        }
        return model.title(of: stack[stack.count - 2])
    }

    // MARK: Parts

    private func header(slots: [ObjectRecord]) -> some View {
        let sets = slots.reduce(0) { $0 + Int(model.store.number("sets", of: $1) ?? 3) }
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            // The back word names the page he came from (back-word.md); no system chevron.
            Button { dismiss() } label: {
                Text("‹ \(cameFrom)")
                    .textRole(.label)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(minHeight: 44)
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityLabel("Back to \(cameFrom)")
            .entrance(1)
            HeroText(text: model.store.displayTitle(of: routine)) { $0 }
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .entrance(2, hero: true)
            Text("\(slots.count) \(slots.count == 1 ? "exercise" : "exercises"), \(sets) sets. Tap one to change it.")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .fixedSize(horizontal: false, vertical: true)
            // The day words play their own tick; no second haptic here (QA #359 F1).
            DaysLine(routine: routine, onChange: { record, words in
                model.touch()
                say(words, undo: record)
            })
        }
    }

    private func libraryTitle(_ mode: LibraryMode, slots: [ObjectRecord]) -> String {
        switch mode {
        case .add: return "Add to \(model.store.displayTitle(of: routine))"
        case let .swap(id):
            let name = slots.first { $0.id == id }.flatMap { model.store.linkedClass("exercise", of: $0)?.name }
            return "Instead of \(name ?? "this")"
        }
    }

    // MARK: Actions

    private func toggle(_ id: UUID) {
        haptic += 1
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            openSlot = openSlot == id ? nil : id
        }
    }

    private func setLibrary(_ mode: LibraryMode?) {
        haptic += 1
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { library = mode }
    }

    /// Runs a Core action, keeps it for Undo and says what changed in Tess's words.
    private func perform(_ action: any EngineAction) {
        let exercise = Receipt.exercise(of: action, in: model.store)
        guard let record = run(action) else { return }
        haptic += 1
        model.touch()
        say(Receipt.routineEdit(action, exercise: exercise, summary: action.summary(in: model.store)), undo: record)
    }

    private func run(_ action: some EngineAction) -> OpRecord? {
        try? model.engine.perform(action, by: .user).record
    }

    private func choose(_ exercise: ClassDef, for mode: LibraryMode) {
        switch mode {
        case .add:
            let low = model.store.classValue("repMin", of: exercise)?.numericValue ?? 8
            let high = model.store.classValue("repMax", of: exercise)?.numericValue ?? max(low, 12)
            perform(AddSlot(routine: routine.id, exercise: exercise.id, sets: 3, repMin: low, repMax: max(low, high)))
        case let .swap(slot):
            perform(SwapSlotExercise(slot: slot, exercise: exercise.id))
        }
        setLibrary(nil)
    }

    /// Tess says the change in her band (`TessVoice`, read by `BottomChrome`); its UNDO takes the op back, then she
    /// says so ("Push A, taken back.").
    private func say(_ words: String, undo record: OpRecord) {
        let title = model.store.displayTitle(of: routine)
        TessVoice.shared.say(words, takeBack: { [model] in
            model.engine.undo(record)
            // The band clears its line right after UNDO runs; her receipt for the undo follows it.
            Task { @MainActor in TessVoice.shared.say(Receipt.takenBack(title)) }
        })
    }
}

// MARK: - One slot

private struct SlotEditorRow: View {
    let slot: ObjectRecord
    let isOpen: Bool
    let isFirst: Bool
    let isLast: Bool
    var onToggle: () -> Void
    var perform: (any EngineAction) -> Void
    var onSwap: () -> Void
    let index: Int
    @Environment(AppModel.self) private var model

    var body: some View {
        let exercise = model.store.linkedClass("exercise", of: slot)
        let sets = model.store.number("sets", of: slot) ?? 3
        let low = model.store.number("repMin", of: slot) ?? 8
        let high = model.store.number("repMax", of: slot) ?? low
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Button(action: onToggle) {
                HStack(alignment: .firstTextBaseline) {
                    Text(exercise?.name ?? "Exercise")
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .lineLimit(2)
                    Spacer(minLength: Theme.Spacing.m)
                    Text(TrainingPage.scheme(sets: sets, repMin: low, repMax: high))
                        .textRole(.label)
                        .foregroundStyle(isOpen ? Theme.Colors.live : Theme.Colors.inkSecondary)
                        .monospacedDigit()
                }
                .frame(minHeight: 50)
                .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityLabel("\(exercise?.name ?? "Exercise"), \(Int(sets)) sets of \(Int(low)) to \(Int(high))")
            .accessibilityHint(isOpen ? "Closes it" : "Opens it to change")

            if isOpen {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    StepLine(label: "Sets", value: Int(sets), range: 1 ... 20) {
                        perform(EditSlot(slot: slot.id, sets: Double($0)))
                    }
                    StepLine(label: "Reps from", value: Int(low), range: 1 ... Int(high)) {
                        perform(EditSlot(slot: slot.id, repMin: Double($0)))
                    }
                    StepLine(label: "Reps to", value: Int(high), range: Int(low) ... 50) {
                        perform(EditSlot(slot: slot.id, repMax: Double($0)))
                    }
                    HStack(spacing: Theme.Spacing.l) {
                        if !isFirst {
                            word("Earlier") { perform(MoveSlot(slot: slot.id, toIndex: index - 1)) }
                        }
                        if !isLast {
                            word("Later") { perform(MoveSlot(slot: slot.id, toIndex: index + 1)) }
                        }
                        word("Swap", action: onSwap)
                        Spacer(minLength: 0)
                        word("Take out", color: Theme.Colors.live) { perform(DeleteObject(object: slot.id)) }
                    }
                }
                .padding(.leading, Theme.Spacing.m)
                .overlay(alignment: .leading) {
                    // A painted margin rule ties the controls to their exercise.
                    Theme.Colors.live.opacity(0.6).frame(width: 2).blur(radius: 0.4)
                }
                .transition(.opacity.combined(with: .offset(y: -6)))
            }
        }
    }

    private func word(_ title: String, color: Color = Theme.Colors.ink,
                      action: @escaping () -> Void) -> some View
    {
        Button(action: action) {
            Text(title)
                .textRole(.bodyStrong)
                .foregroundStyle(color)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
    }
}

/// "Sets   −  4  +" on bare glyph keys, 44 pt each.
private struct StepLine: View {
    let label: String
    let value: Int
    let range: ClosedRange<Int>
    var onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
            Spacer(minLength: Theme.Spacing.m)
            key("−", enabled: value > range.lowerBound) { onChange(value - 1) }
            Text("\(value)")
                .font(Theme.numeral(28))
                .foregroundStyle(Theme.Colors.ink)
                .monospacedDigit()
                .frame(minWidth: 44)
                .contentTransition(.numericText(value: Double(value)))
            key("+", enabled: value < range.upperBound) { onChange(value + 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if value < range.upperBound {
                    onChange(value + 1)
                }
            case .decrement: if value > range.lowerBound {
                    onChange(value - 1)
                }
            @unknown default: break
            }
        }
    }

    private func key(_ glyph: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(Theme.numeral(28))
                .foregroundStyle(Theme.Colors.ink.opacity(enabled ? 0.85 : 0.2))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - The library, by movement pattern

/// Every exercise under its movement pattern (the library's spine): a pattern heading, then names. Tap one to pick it.
struct ExerciseLibraryList: View {
    let title: String
    var onPick: (ClassDef) -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        let groups = Self.groups(model)
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Text(title)
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
            ForEach(groups, id: \.pattern.id) { group in
                VStack(alignment: .leading, spacing: 0) {
                    Text(group.pattern.name)
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.bottom, Theme.Spacing.xs)
                    ForEach(group.exercises, id: \.id) { exercise in
                        Button { onPick(exercise) } label: {
                            Text(exercise.name)
                                .textRole(.body)
                                .foregroundStyle(Theme.Colors.ink)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(HandleButtonStyle())
                    }
                }
            }
        }
    }

    /// Movement patterns (the library's spine classes, "library.pattern.*") with the exercises below each, by name.
    static func groups(_ model: AppModel) -> [(pattern: ClassDef, exercises: [ClassDef])] {
        guard let root = model.classDef(.exercise) else { return [] }
        return ClassResolver.descendants(of: root)
            .filter { $0.systemKey?.hasPrefix("library.pattern.") == true }
            .map { pattern in
                let leaves = ClassResolver.descendants(of: pattern).dropFirst()
                    .filter { ($0.subclasses ?? []).isEmpty && $0.systemKey?.hasPrefix("library.group.") != true }
                return (pattern, leaves.sorted { $0.name < $1.name })
            }
            .filter { !$0.1.isEmpty }
    }
}

// MARK: - Days

/// DAYS (training-mode.md, "A routine's days"): on a rolling plan "rolls on", not tappable; on fixed days the chosen
/// days ("Mon, Thu"). Tap it and the week unfolds in place at 49 pt pitch, Monday first; tap a day to pick or unpick
/// it. A day another routine had moves here, and Tess says so. One routine per day.
private struct DaysLine: View {
    let routine: ObjectRecord
    var onChange: (OpRecord, String) -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var open = false
    /// The day just picked, wet in tess until it dries (900 ms).
    @State private var wet: Int?
    @State private var ticks = 0

    var body: some View {
        let plan = model.plan
        let fixed = plan.map { PlanSchedule.mode(of: $0, store: model.store) == .fixed } ?? false
        let chosen = PlanSchedule.weekdays(of: routine, store: model.store)
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Tap DAYS (or leave the page) to fold the week back to "Mon, Thu".
            Text("Days")
                .textRole(.label)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(minHeight: 24, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard open else { return }
                    withTesseraAnimation(reduceMotion: reduceMotion) { open = false }
                }
                .accessibilityAddTraits(open ? .isButton : [])
                .accessibilityHint(open ? "Folds the week" : "")
            if !fixed {
                Text("rolls on")
                    .font(Theme.voice(size: 21).weight(.semibold))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            } else if open {
                week(chosen)
                    .transition(.opacity)
            } else {
                Button {
                    withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.32), reduceMotion: reduceMotion) {
                        open = true
                    }
                } label: {
                    // Fixed days with none picked gives no next routine: steer him to pick one.
                    Text(chosen.isEmpty ? "Pick a day" : Weekdays.ordered(chosen).map { Weekdays.short[$0 - 1] }
                        .joined(separator: ", "))
                        .font(Theme.voice(size: 21).weight(.semibold))
                        .foregroundStyle(chosen.isEmpty ? Theme.Colors.ink.opacity(0.7) : Theme.Colors.ink)
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityHint("Shows the week to pick days")
            }
        }
        .tesseraFeedback(.selection, trigger: ticks)
        .padding(.vertical, open ? 5 : 0)
        .onDisappear { open = false }
    }

    /// The seven day words, Monday first, chosen in ink and the rest at 38%; tap away to fold.
    private func week(_ chosen: Set<Int>) -> some View {
        HStack(spacing: 0) {
            ForEach(Array([2, 3, 4, 5, 6, 7, 1].enumerated()), id: \.element) { order, weekday in
                let picked = chosen.contains(weekday)
                Button { toggle(weekday, in: chosen) } label: {
                    Text(Weekdays.short[weekday - 1])
                        .font(Theme.voice(size: 21).weight(.semibold))
                        .foregroundStyle(wet == weekday ? Theme.Colors.tess
                            : Theme.Colors.ink.opacity(picked ? 1 : 0.38))
                        .scaleEffect(wet == weekday && !reduceMotion ? 1.08 : 1)
                        .frame(width: 49, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Weekdays.name(weekday))
                .accessibilityAddTraits(picked ? .isSelected : [])
                .transition(.opacity.animation(.easeOut(duration: 0.2).delay(Double(order) * 0.04)))
            }
            Spacer(minLength: 0)
        }
        .tesseraAnimation(.spring(response: 0.3, dampingFraction: 0.6), value: wet)
    }

    private func toggle(_ weekday: Int, in chosen: Set<Int>) {
        var next = chosen
        if next.contains(weekday) {
            next.remove(weekday)
        } else {
            next.insert(weekday)
        }
        guard let result = try? model.engine.perform(
            SetRoutineWeekdays(routine: routine.id, weekdays: Weekdays.ordered(next)), by: .user
        ) else { return }
        ticks += 1
        let picked = next.contains(weekday)
        if picked {
            wet = weekday
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(900))
                if wet == weekday {
                    wet = nil
                }
            }
        }
        // "Thursday was Pull A's. Push A has it now." else "Push A on Mondays and Thursdays."
        let shown = model.store.displayTitle(of: routine)
        let words = result.output.first.map { $0.line(to: shown) } ?? Self.receipt(shown, next)
        onChange(result.record, words)
    }

    static func receipt(_ title: String, _ days: Set<Int>) -> String {
        let words = Weekdays.ordered(days).map { Weekdays.name($0) + "s" }
        switch words.count {
        case 0: return "\(title) has no fixed day."
        case 1: return "\(title) on \(words[0])."
        default: return "\(title) on \(words.dropLast().joined(separator: ", ")) and \(words[words.count - 1])."
        }
    }
}
