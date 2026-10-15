import SwiftUI
import TesseraCore

/// A routine's own page, and its editor (ship list slice 10). One row per exercise, separated by space; tap a row to
/// open it in place: sets and the rep range on bare − / + keys, move it earlier or later, swap it for another
/// exercise, or take it out. "Add an exercise" opens the library under the list, grouped by movement pattern.
/// Every change is a Core action (EditSlot, MoveSlot, SwapSlotExercise, AddSlot, DeleteObject) in the op log, and
/// the last one can be undone from Tess's line at the bottom.
struct RoutineEditor: View {
    let routine: ObjectRecord
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The slot opened in place.
    @State private var openSlot: UUID?
    /// The library under the list: adding a new exercise, or choosing a swap for a slot.
    @State private var library: LibraryMode?
    /// The last change, for Undo and Tess's line.
    @State private var last: OpRecord?
    @State private var line: String?
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
        }
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: haptic)
    }

    // MARK: Parts

    private func header(slots: [ObjectRecord]) -> some View {
        let sets = slots.reduce(0) { $0 + Int(model.store.number("sets", of: $1) ?? 3) }
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if let plan = model.plan {
                ObjectHandle(title: plan.title, route: .object(plan.id), relation: .up, role: .label,
                             color: Theme.Colors.inkSecondary)
                    .entrance(1)
            }
            HeroText(text: routine.title) { $0 }
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .entrance(2, hero: true)
            Text("\(slots.count) \(slots.count == 1 ? "exercise" : "exercises"), \(sets) sets. Tap one to change it.")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .fixedSize(horizontal: false, vertical: true)
            tessLine
        }
    }

    @ViewBuilder
    private var tessLine: some View {
        if let line {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Text(line)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.tess)
                    .lineLimit(2)
                Spacer(minLength: Theme.Spacing.s)
                if last != nil {
                    Button("Undo") { undo() }
                        .textRole(.labelStrong)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(minWidth: 60, minHeight: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .accessibilityLabel("Undo the last change")
                }
            }
            .transition(.opacity)
        }
    }

    private func libraryTitle(_ mode: LibraryMode, slots: [ObjectRecord]) -> String {
        switch mode {
        case .add: return "Add to \(routine.title)"
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
        guard let record = run(action) else { return }
        haptic += 1
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            last = record
            line = action.summary(in: model.store) + "."
        }
        model.touch()
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

    private func undo() {
        guard let last else { return }
        model.engine.undo(last)
        haptic += 1
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            self.last = nil
            line = "Undone."
        }
        model.touch()
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
