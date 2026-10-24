import SwiftUI
import TesseraCore

/// The Library (sheet 230 v3). The title "Library" in the Training accent. Under it one row, on the right: one
/// category at a time with its count and no label or axis tag. Swipe it sideways and the category changes; swipe it up
/// or down and the sort changes (kind, length, day); both follow the finger 1:1, with no lens. Then the "What" dial
/// (Routines, Exercises, Programs,
/// Goals, a count in each), a two-line brief, and an "In here" depth wheel of that cell's items: a tap focuses one, a
/// tap on the focused one opens it. One action word at the foot says what adds to the cell.
struct TrainingLibraryV2: View {
    var openToday: () -> Void = {}
    var goals: LibraryGoalsSource = NoGoalsYet()

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var what = LibraryWhat.routines
    /// The sort (kind, length, day) and the category kept for each: no label says which. Up and down on the category
    /// row turns the sort; sideways turns the category.
    @State private var axisIndex = 0
    @State private var memory = [0, 0, 0]
    @State private var focus = 1
    @State private var cue = HapticCue()
    @State private var routine: LibraryEntry?

    var body: some View {
        let _ = model.revision
        let all = LibraryData.items(model: model, goals: goals)
        let axis = LibraryAxis.allCases[axisIndex]
        let category = memory[axisIndex]
        let inCell = all.filter { $0.what == what }
        let shown = inCell.filter { LibraryFilter.matches(
            $0,
            axis: axis,
            category: axis.categories[min(category, axis.categories.count - 1)]
        ) }
        ZStack {
            if let routine {
                LibraryRoutinePage(item: routine, close: { closeRoutine() }, openToday: openToday)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))
                    .zIndex(1)
            } else {
                library(all: all, inCell: inCell, shown: shown)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(x: -40)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .tesseraFeedback(cue)
    }

    private func closeRoutine() {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { routine = nil }
    }

    // MARK: The page

    private func library(all: [LibraryEntry], inCell: [LibraryEntry], shown: [LibraryEntry]) -> some View {
        let counts = LibraryAxis.allCases.map { LibraryFilter.counts(inCell, axis: $0) }
        return VStack(alignment: .leading, spacing: 0) {
            Text("Library")
                .font(Theme.Training.words(40, weight: .semibold, relativeTo: .largeTitle))
                .foregroundStyle(Theme.Colors.Accent.training)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            categoryRow(counts: counts)
                .padding(.top, Theme.Spacing.m)
            whatDial(all: all)
                .padding(.top, Theme.Spacing.m)
            brief(for: focusedItem(shown))
                .frame(height: 52, alignment: .topLeading)
                .padding(.top, Theme.Spacing.m)
            wheel(shown)
            foot
                .frame(height: 36)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, HomeSpatialView.dockClearance)
        }
        .frame(maxWidth: .infinity, minHeight: 600, alignment: .topLeading)
        .onChange(of: what) { _, _ in focus = 1 }
        .onChange(of: memory) { _, _ in focus = 1 }
        .onChange(of: axisIndex) { _, _ in focus = 1 }
    }

    // MARK: The category row

    /// One category on the right, nothing else: no axis tag, no label. The reel turns the sort and the category.
    private func categoryRow(counts: [[Int]]) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer(minLength: 0)
            CategoryReel(labels: LibraryAxis.allCases.map(\.categories), counts: counts, axisIndex: $axisIndex,
                         memory: $memory, axisNames: LibraryAxis.allCases.map(\.rawValue), countColor: what.color)
        }
    }

    // MARK: The What dial

    private func whatDial(all: [LibraryEntry]) -> some View {
        let cells = LibraryWhat.allCases
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.s))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 0))
        return layout {
            ForEach(cells) { cell in
                let count = all.count { $0.what == cell }
                Button {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { what = cell }
                    cue.play(.selection)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(cell.rawValue)
                            .font(Theme.Training.words(17, weight: what == cell ? .semibold : .regular))
                            .foregroundStyle(what == cell ? cell.color : Theme.Colors.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("\(count)")
                            .font(Theme.Training.number(26, weight: .light))
                            .foregroundStyle(what == cell ? cell.color : Theme.Colors.inkSecondary)
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(cell.rawValue), \(count)")
                .accessibilityAddTraits(what == cell ? .isSelected : [])
            }
        }
    }

    // MARK: Brief and wheel

    private func focusedItem(_ shown: [LibraryEntry]) -> LibraryEntry? {
        // Row 0 is the header.
        shown.indices.contains(focus - 1) ? shown[focus - 1] : nil
    }

    private func brief(for item: LibraryEntry?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let item {
                ForEach(Array(item.lines.filter { !$0.isEmpty }.prefix(2).enumerated()), id: \.offset) { _, line in
                    MeasureLine.text(line, size: 17)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            } else {
                Text("Nothing here yet.")
                    .font(Theme.Training.words(17))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
        }
        .contentTransition(.opacity)
        .tesseraAnimation(Theme.Motion.house, value: item?.id)
    }

    private struct WheelEntry: Identifiable {
        let id: String
        let item: LibraryEntry?
        let count: Int
    }

    private func wheel(_ shown: [LibraryEntry]) -> some View {
        let entries = [WheelEntry(id: "header", item: nil, count: shown.count)]
            + shown.map { WheelEntry(id: $0.id, item: $0, count: shown.count) }
        return DepthWheel(items: entries, focus: $focus, home: 1, style: .plan, minFocus: 1, label: "In here",
                          onTap: { entry, wasFocused in
                              guard wasFocused, let item = entry.item else { return }
                              open(item)
                          },
                          rowIdentifier: { "library-\($0.id)" })
        { entry, state in
            if let item = entry.item {
                Text(item.title)
                    .font(Theme.Training.words(30, weight: state.isFocused ? .semibold : .regular, relativeTo: .title))
                    .foregroundStyle(state.isFocused ? focusColor(item) : Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else {
                HStack(spacing: Theme.Spacing.m) {
                    Text("In here")
                    Text("\(entry.count) \(entry.count == 1 ? "item" : "items")")
                }
                .font(Theme.Training.words(15, weight: .semibold, relativeTo: .footnote))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(Theme.Colors.Slate.label)
                .lineLimit(1)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
        }
    }

    /// The focused row wears its kind's colour: a routine its split (Push clay, Pull teal, Legs plum), the rest the
    /// colour of their cell.
    private func focusColor(_ item: LibraryEntry) -> Color {
        item.what == .routines ? Theme.Colors.Split.color(forKind: item.kind) : item.what.color
    }

    private func open(_ item: LibraryEntry) {
        switch item.what {
        case .routines:
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { routine = item }
        case .exercises:
            if let id = item.classID {
                model.open(.classDef(id))
            }
        case .programs:
            if let id = item.planID {
                model.open(.object(id))
            }
        case .goals:
            break
        }
        cue.play(.pageTurn)
    }

    // MARK: The foot

    private var foot: some View {
        ActionWord(word: what.actionWord) {
            model.commandDraft = what.draft
            withTesseraAnimation(reduceMotion: reduceMotion) { model.isCommandExpanded = true }
        }
    }
}

// MARK: - The category reel

/// One category at a time, on the right, with its count, and no label for the sort. A drag sideways turns the category
/// and a drag up or down turns the sort (kind, length, day); both move 1:1 under the finger, no lens, no magnifier. The
/// next label comes in from the direction of the drag; letting go settles on the nearest, and a flick moves exactly
/// one.
struct CategoryReel: View {
    let labels: [[String]]
    let counts: [[Int]]
    @Binding var axisIndex: Int
    @Binding var memory: [Int]
    /// Only for VoiceOver ("by kind"); nothing visible says it.
    var axisNames: [String] = []
    /// The count takes the colour of the cell showing (v3.3).
    var countColor: Color = Theme.Colors.inkSecondary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: (start: Double, position: Double)?
    @State private var horizontal = true
    @State private var lastTick = 0
    @State private var cue = HapticCue()

    private let extent: CGFloat = 170
    private let height: CGFloat = 44

    private var categoryRange: ClosedRange<Int> {
        0 ... max((labels.indices.contains(axisIndex) ? labels[axisIndex].count : 1) - 1, 0)
    }

    private var axisRange: ClosedRange<Int> {
        0 ... max(labels.count - 1, 0)
    }

    private var activeRange: ClosedRange<Int> {
        horizontal ? categoryRange : axisRange
    }

    var body: some View {
        let position = drag?.position ?? Double(horizontal ? memory[axisIndex] : axisIndex)
        ZStack(alignment: .trailing) {
            if horizontal {
                ForEach(WheelMath.window(position: position, visibleRows: 3, in: categoryRange), id: \.self) { index in
                    let distance = Double(index) - position
                    label(axisIndex, index)
                        .opacity(max(0, 1 - abs(distance)))
                        .offset(x: CGFloat(distance) * extent)
                }
            } else {
                ForEach(WheelMath.window(position: position, visibleRows: 3, in: axisRange), id: \.self) { sort in
                    let distance = Double(sort) - position
                    label(sort, memory[sort])
                        .opacity(max(0, 1 - abs(distance)))
                        .offset(y: CGFloat(distance) * height)
                }
            }
        }
        .frame(width: extent, height: height, alignment: .trailing)
        .clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(gesture)
        .tesseraFeedback(cue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Category")
        .accessibilityValue(spoken)
        .accessibilityAdjustableAction { direction in
            let current = memory[axisIndex]
            switch direction {
            case .increment: memory[axisIndex] = min(current + 1, categoryRange.upperBound)
            case .decrement: memory[axisIndex] = max(current - 1, categoryRange.lowerBound)
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Next sort") { axisIndex = (axisIndex + 1) % max(labels.count, 1) }
    }

    private func label(_ axis: Int, _ index: Int) -> some View {
        let names = labels.indices.contains(axis) ? labels[axis] : []
        let numbers = counts.indices.contains(axis) ? counts[axis] : []
        return HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
            Text(names.indices.contains(index) ? names[index] : "")
                .font(Theme.Training.words(22, weight: .semibold, relativeTo: .title3))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(numbers.indices.contains(index) ? "\(numbers[index])" : "")
                .font(Theme.Training.number(22, weight: .light))
                .foregroundStyle(countColor)
        }
        .frame(width: extent, alignment: .trailing)
    }

    private var spoken: String {
        let names = labels.indices.contains(axisIndex) ? labels[axisIndex] : []
        let numbers = counts.indices.contains(axisIndex) ? counts[axisIndex] : []
        let index = memory[axisIndex]
        guard names.indices.contains(index) else { return "" }
        let sort = axisNames.indices.contains(axisIndex) ? ", \(axisNames[axisIndex])" : ""
        return "\(names[index]), \(numbers.indices.contains(index) ? numbers[index] : 0)\(sort)"
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart), coordinateSpace: .global)
            .onChanged { value in
                if drag == nil {
                    horizontal = abs(value.translation.width) >= abs(value.translation.height)
                    let start = Double(horizontal ? memory[axisIndex] : axisIndex)
                    drag = (start, start)
                    lastTick = Int(start)
                }
                guard let start = drag?.start else { return }
                let travel = horizontal ? value.translation.width : value.translation.height
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    drag?.position = WheelMath.position(start: start, translation: travel,
                                                        pitch: horizontal ? extent : height, in: activeRange)
                }
                let row = WheelMath.nearest(position: drag?.position ?? start, in: activeRange)
                if row != lastTick {
                    lastTick = row
                    cue.play(.selection)
                }
            }
            .onEnded { value in
                guard let current = drag else { return }
                let travel = horizontal ? value.translation.width : value.translation.height
                let speed = horizontal ? value.velocity.width : value.velocity.height
                let target = WheelMath.release(position: current.position, translation: travel, velocity: speed,
                                               pitch: horizontal ? extent : height, in: activeRange)
                withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
                    if horizontal {
                        memory[axisIndex] = target
                    } else {
                        axisIndex = target
                    }
                    drag = nil
                }
            }
    }
}

// MARK: - A routine's page

/// A routine: its exercises, each with its usual sets as stack marks. The action word "Do it today"; for today's
/// routine ("Push A") it opens Today's workout.
struct LibraryRoutinePage: View {
    let item: LibraryEntry
    var close: () -> Void
    var openToday: () -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var brief: (id: UUID, text: String, undo: (() -> Void)?)?
    @State private var cue = HapticCue()

    private var routine: ObjectRecord? {
        item.routineID.flatMap { model.object($0) }
    }

    private var isTodays: Bool {
        guard let routine else { return false }
        return model.todaysRoutine()?.id == routine.id || model.triedRoutine()?.id == routine.id
            || model.tonightWorkout().flatMap { model.store.linkedObjects("routine", of: $0).first?.id } == routine.id
    }

    var body: some View {
        let slots = routine?.orderedChildren.filter { !$0.isDeleted } ?? []
        VStack(alignment: .leading, spacing: 0) {
            BackWord(title: "Library", action: close)
            FittedTitle(text: item.title, color: Theme.Colors.Accent.training)
                .frame(minHeight: 44)
                .accessibilityAddTraits(.isHeader)
            Text(item.lines.first ?? "")
                .font(Theme.Training.words(17))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .lineLimit(1)
                .padding(.bottom, Theme.Spacing.l)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(slots, id: \.id) { slot in
                    exerciseRow(slot)
                }
            }
            Spacer(minLength: Theme.Spacing.l)
            briefLine
                .frame(height: 40, alignment: .leading)
            ActionWord(word: "Do it today", action: doIt)
                .frame(height: 36)
                .padding(.bottom, HomeSpatialView.dockClearance)
        }
        .frame(maxWidth: .infinity, minHeight: 560, alignment: .topLeading)
        .tesseraFeedback(cue)
    }

    /// An exercise with its usual sets as stacks (sets x the top of the rep range).
    private func exerciseRow(_ slot: ObjectRecord) -> some View {
        let exercise = model.store.linkedClass("exercise", of: slot)
        let sets = Int(model.store.number("sets", of: slot) ?? 3)
        let reps = Int(model.store.number("repMax", of: slot) ?? model.store.number("repMin", of: slot) ?? 8)
        return Button {
            if let exercise {
                model.open(.classDef(exercise.id))
            }
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                Text(exercise?.name ?? "Exercise")
                    .font(Theme.Training.words(22, weight: .medium, relativeTo: .title3))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: Theme.Spacing.s)
                StackRow(sets: (0 ..< sets).map { _ in StackMarkSpec(reps: reps, lifted: 0) },
                         spoken: "\(sets) sets of \(reps)")
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(exercise?.name ?? "Exercise"), \(sets) sets of \(reps)")
    }

    @ViewBuilder
    private var briefLine: some View {
        if let brief {
            HStack(spacing: Theme.Spacing.m) {
                Text(brief.text)
                    .font(Theme.Training.words(17))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let undo = brief.undo {
                    Button {
                        cue.play(.undo)
                        undo()
                        self.brief = nil
                    } label: {
                        Text("Undo")
                            .font(Theme.Training.words(17, weight: .semibold))
                            .foregroundStyle(Theme.Colors.Accent.training)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            Color.clear
        }
    }

    private func doIt() {
        // Push A, when it is today's, opens Today's workout.
        if isTodays {
            openToday()
            return
        }
        guard let routine else { return }
        guard let undo = model.doRoutineToday(routine) else {
            say("Today is already decided.", undo: nil)
            return
        }
        cue.play(.made)
        say("\(item.title) is today's workout.", undo: undo)
    }

    private func say(_ text: String, undo: (() -> Void)?) {
        let id = UUID()
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { brief = (id, text, undo) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(undo == nil ? 4 : GestureTuning.undoSeconds))
            if brief?.id == id {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { brief = nil }
            }
        }
    }
}
