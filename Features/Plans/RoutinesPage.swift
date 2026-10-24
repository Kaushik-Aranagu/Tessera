import SwiftUI
import TesseraCore

/// A plan's routines (docs/design/training-mode.md, "Routines"): the back word, Title 44, the context line, one 62 pt
/// row per routine in cycle order, "Make a routine" as a writing line, and the plan's mode as two value words.
/// Hold a row to move it in the cycle; swipe it left to drop it. Tess says each change in her band beside the soul,
/// with UNDO (`TessVoice`), like every other page's receipt.
struct RoutinesPage: View {
    let plan: ObjectRecord
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var making = false
    @State private var draft = ""
    @FocusState private var draftFocused: Bool
    @State private var haptic = HapticCue()
    /// The row being moved by a hold-and-drag, and how far it has travelled.
    @State private var moving: UUID?
    @State private var moveOffset: CGFloat = 0

    private static let rowHeight: CGFloat = 62

    var body: some View {
        let _ = model.revision
        let routines = model.store.linkedObjects("routines", of: plan)
        let mode = PlanSchedule.mode(of: plan, store: model.store)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // The back word names the page he came from; no system chevron anywhere (back-word.md).
                Button { dismiss() } label: {
                    Text("‹ Training")
                        .textRole(.label)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityLabel("Back to Training")
                .padding(.bottom, Theme.Spacing.m)
                Text("Routines")
                    .textRole(.title)
                    .wordFit("Routines")
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, Theme.Spacing.s)
                    .entrance(0, hero: true)
                Text("\(plan.title), \(mode == .fixed ? "fixed days" : "rolls on")")
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .contentTransition(.opacity)
                    .padding(.bottom, Theme.Spacing.xl)
                    .entrance(1)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(routines.enumerated()), id: \.element.id) { index, routine in
                        RoutineRow(routine: routine, isNext: routine.id == next?.id, mode: mode,
                                   onDrop: { drop(routine) })
                            .offset(y: moving == routine.id ? moveOffset : shift(for: index, in: routines))
                            .zIndex(moving == routine.id ? 1 : 0)
                            .scaleEffect(moving == routine.id && !reduceMotion ? 1.02 : 1)
                            .gesture(reorder(routine, at: index, count: routines.count))
                    }
                }
                .tesseraAnimation(.spring(response: 0.3, dampingFraction: 0.82), value: moving)
                .entrance(2)

                makeLine
                    .padding(.top, Theme.Spacing.s)
                    .entrance(3)

                modeWords(mode)
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(4)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, 180)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        // Hiding the system back button also drops the edge swipe; keep it (QA K1).
        .background { EdgeSwipeBack() }
        .tesseraFeedback(haptic)
    }

    private var next: ObjectRecord? {
        model.ledger.nextRoutine(in: plan, now: AppClock.now)
    }

    // MARK: Make a routine

    /// "Make a routine" at Body 21, ink 70%; tap it and it becomes the cobalt writing line with a caret.
    @ViewBuilder
    private var makeLine: some View {
        if making {
            HStack(spacing: Theme.Spacing.s) {
                Capsule().fill(Theme.Colors.tess).frame(width: 3, height: 26)
                TextField("Name it", text: $draft)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.ink)
                    .tint(Theme.Colors.tess)
                    .focused($draftFocused)
                    .submitLabel(.done)
                    .onSubmit(make)
            }
            .frame(minHeight: Self.rowHeight)
            .overlay(alignment: .bottom) { Theme.Colors.tess.opacity(0.6).frame(height: 1) }
            .onAppear { draftFocused = true }
            .onChange(of: draftFocused) { _, focused in
                if !focused, draft.trimmingCharacters(in: .whitespaces).isEmpty {
                    withTesseraAnimation(reduceMotion: reduceMotion) { making = false }
                }
            }
            .transition(.opacity)
        } else {
            Button {
                withTesseraAnimation(reduceMotion: reduceMotion) { making = true }
            } label: {
                Text("Make a routine")
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.ink.opacity(0.7))
                    .frame(maxWidth: .infinity, minHeight: Self.rowHeight, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
        }
    }

    private func make() {
        let title = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              let made = try? model.engine.perform(CreateRoutine(title: title), by: .user) else { return }
        guard let added = try? model.engine.perform(AddRoutineToPlan(plan: plan.id, routine: made.output.id),
                                                    by: .user)
        else {
            model.engine.undo(made.record)
            return
        }
        draft = ""
        making = false
        // Making a routine is two ops; UNDO takes both back and leaves the new routine's page if he's on it.
        let route = Route.object(made.output.id)
        said("\(title) made.", records: [made.record, added.record], haptic: .made) { [model] in
            if model.path.last == route {
                model.path.removeLast()
            }
            return Receipt.takenBack(title)
        }
        // The new routine opens empty, "Add an exercise" ready.
        model.open(.object(made.output.id))
    }

    // MARK: Mode

    /// ROLLS ON and FIXED DAYS: the current one in ink, the other at 38%; tap the other to switch.
    private func modeWords(_ mode: ScheduleMode) -> some View {
        HStack(spacing: 30) {
            ForEach([ScheduleMode.rolling, .fixed], id: \.self) { option in
                Button {
                    guard option != mode else { return }
                    setMode(option)
                } label: {
                    Text(option == .fixed ? "Fixed days" : "Rolls on")
                        .textRole(.labelStrong)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Colors.ink.opacity(option == mode ? 1 : 0.38))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == mode ? .isSelected : [])
            }
        }
        .tesseraAnimation(.easeOut(duration: 0.22), value: mode)
    }

    private func setMode(_ mode: ScheduleMode) {
        guard let result = try? model.engine.perform(SetScheduleMode(plan: plan.id, mode: mode), by: .user) else {
            return
        }
        said(
            "\(plan.title) \(mode == .fixed ? "on fixed days" : "rolls on").",
            records: [result.record],
            haptic: .selection
        ) { Receipt.takenBack(plan.title) }
    }

    // MARK: Reorder and drop

    /// Hold a row (0.35 s), then drag it up or down; it lands in the slot it's over when he lets go.
    private func reorder(_ routine: ObjectRecord, at index: Int, count: Int) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .onEnded { _ in
                moving = routine.id
                moveOffset = 0
                haptic.play(.pickedUp)
            }
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case let .second(true, drag?) = value else { return }
                moveOffset = drag.translation.height
            }
            .onEnded { _ in
                guard moving == routine.id else { return }
                let target = min(max(index + Int((moveOffset / Self.rowHeight).rounded()), 0), count - 1)
                moving = nil
                moveOffset = 0
                guard target != index,
                      let result = try? model.engine.perform(MoveRoutineInPlan(plan: plan.id, routine: routine.id,
                                                                               to: target), by: .user)
                else { return }
                said("\(routine.title) moved.", records: [result.record], haptic: .selection) {
                    Receipt.takenBack(routine.title)
                }
            }
    }

    /// The other rows part to show where the held row would land.
    private func shift(for index: Int, in routines: [ObjectRecord]) -> CGFloat {
        guard let moving, let from = routines.firstIndex(where: { $0.id == moving }) else { return 0 }
        let target = min(max(from + Int((moveOffset / Self.rowHeight).rounded()), 0), routines.count - 1)
        if from < target, index > from, index <= target {
            return -Self.rowHeight
        }
        if from > target, index >= target, index < from {
            return Self.rowHeight
        }
        return 0
    }

    private func drop(_ routine: ObjectRecord) {
        guard let result = try? model.engine.perform(DropRoutineFromPlan(plan: plan.id, routine: routine.id),
                                                     by: .user) else { return }
        let title = routine.title
        said(Receipt.dropped(title), records: [result.record], haptic: .notNow) { Receipt.backOnPlan(title) }
    }

    // MARK: Tess

    /// Tess says the change in her band beside the soul (`TessVoice`, read by `BottomChrome`), with UNDO. UNDO takes
    /// back every op of the change, newest first, then she says what came back (`undone` runs after the ops).
    private func said(_ words: String, records: [OpRecord], haptic moment: Haptic,
                      undone: @escaping @MainActor () -> String)
    {
        haptic.play(moment)
        model.touch()
        TessVoice.shared.say(words, takeBack: { [model] in
            for record in records.reversed() {
                model.engine.undo(record)
            }
            let back = undone()
            // The band clears its line right after UNDO runs; her receipt for the undo follows it.
            Task { @MainActor in TessVoice.shared.say(back) }
        })
    }
}

/// "Push A" at Body 21/500, under it "5 exercises, about 55 min" (on fixed days the days first, "Mon, Thu. …").
/// Swipe left to drop: DROP rises in liveInk past 90 pt.
struct RoutineRow: View {
    let routine: ObjectRecord
    var isNext = false
    var mode: ScheduleMode = .rolling
    var onDrop: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace
    @State private var pull: CGFloat = 0
    /// A sideways drag owns the touch: the row doesn't also open on the lift (the walk showed a drop opening it).
    @State private var swiped = false

    private static let arm = CGFloat(GestureTuning.armDistance)

    var body: some View {
        let slots = routine.orderedChildren
        let sets = slots.reduce(0) { $0 + Int(model.store.number("sets", of: $1) ?? 3) }
        Button {
            guard !swiped else { return }
            model.open(.object(routine.id))
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(routine.title)
                        .font(Theme.voice(size: 21).weight(.medium))
                        .foregroundStyle(Theme.Colors.ink)
                    Spacer(minLength: Theme.Spacing.s)
                    if isNext {
                        Text("Next")
                            .textRole(.label)
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                }
                Text(detail(slots: slots.count, sets: sets))
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .modifier(ZoomSource(id: Route.object(routine.id), namespace: namespace))
        .offset(x: min(pull, 0))
        .background(alignment: .trailing) {
            Text("Drop")
                .textRole(.labelStrong)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Colors.liveInk)
                .opacity(pull < -Self.arm ? 1 : Double(min(-pull / Self.arm, 1)) * 0.5)
                .accessibilityHidden(true)
        }
        .rowSwipe(.trailing, arm: Self.arm) { event in
            switch event {
            case let .pulled(value):
                swiped = true
                pull = value
            case .committed:
                onDrop()
            case .ended:
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { pull = 0 }
                // After the button has seen the lift, a tap opens the row again.
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    swiped = false
                }
            case .cancelled, .armed, .disarmed: break
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(routine.title)")
        .accessibilityAction(named: "Drop from the plan", onDrop)
    }

    private func detail(slots: Int, sets: Int) -> String {
        let days = mode == .fixed
            ? Weekdays.ordered(PlanSchedule.weekdays(of: routine, store: model.store)) : nil
        return Self.detail(slots: slots, about: TrainingPage.about(sets: sets), fixedDays: days)
    }

    /// "5 exercises, about 40 min"; on fixed days the days first, then a period: "Mon, Thu. 5 exercises, ..."
    /// and "No days. 5 exercises, ..." when none are set. `fixedDays` is nil on a rolling plan.
    static func detail(slots: Int, about: String, fixedDays: [Int]?) -> String {
        let body = slots > 0
            ? "\(slots) \(slots == 1 ? "exercise" : "exercises"), \(about)"
            : "no exercises yet"
        guard let fixedDays else { return body }
        let sentence = body.prefix(1).uppercased() + body.dropFirst()
        guard !fixedDays.isEmpty else { return "No days. " + sentence }
        return fixedDays.map { Weekdays.short[$0 - 1] }.joined(separator: ", ") + ". " + sentence
    }
}
