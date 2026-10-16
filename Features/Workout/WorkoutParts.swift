import SwiftUI
import TesseraCore

private typealias Paint = WorkoutPaint

// MARK: - The exercise lane (x)

/// One name per page; the next peeks in. Tap the name to zoom into the exercise. Pull down on it for the swap panel:
/// the name follows the finger (rubber-banded to about 10 pt). The pager keeps horizontal.
struct ExerciseLane: View {
    let session: WorkoutSession
    @Binding var laneIndex: Int?
    let isSwapOpen: Bool
    var setSwap: (Bool) -> Void

    @State private var namePull: CGFloat = 0
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.zoomNamespace) private var zoomNamespace

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(session.entries.enumerated()), id: \.element.id) { index, entry in
                    let exercise = session.exerciseClass(of: entry)
                    let isCurrent = index == (laneIndex ?? session.currentIndex)
                    let name = exercise?.name ?? "Exercise"
                    Button {
                        if let exercise {
                            model.open(.classDef(exercise.id), .deeper)
                        }
                    } label: {
                        Text(name)
                            .textRole(.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                            .foregroundStyle(Paint.cream.opacity(isCurrent ? 1 : 0.28))
                            // A long name steps down a size and keeps clear of the next one peeking in.
                            .padding(.trailing, Theme.Spacing.m)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(name)
                            .transition(reduceMotion ? .opacity
                                : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                              removal: .opacity))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .modifier(ZoomSource(id: exercise.map { Route.classDef($0.id) }, namespace: zoomNamespace))
                    .containerRelativeFrame(.horizontal) { width, _ in width - Theme.Spacing.gutter - 46 }
                    .id(index)
                    .offset(y: isCurrent ? Self.rubberBand(namePull) : 0)
                    .contextMenu {
                        if isCurrent {
                            Button("Swap within the movement", systemImage: "arrow.left.arrow.right") {
                                setSwap(true)
                            }
                        }
                    }
                    .accessibilityHint(isCurrent ? "Opens the exercise page" : "")
                    .accessibilityAction(named: "Swap within the movement") { setSwap(true) }
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
        // Pull down on the name for alternatives; the pager keeps horizontal.
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .onChanged { drag in
                    guard session.finishedAt == nil, drag.translation.height > abs(drag.translation.width) else {
                        return
                    }
                    namePull = drag.translation.height
                }
                .onEnded { drag in
                    let pulled = drag.translation.height > 44 && drag.translation.height > abs(drag.translation.width)
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { namePull = 0 }
                    if pulled {
                        setSwap(!isSwapOpen)
                    } else if drag.translation.height < -30, isSwapOpen {
                        setSwap(false)
                    }
                }
        )
    }

    /// The name follows the finger up to about 10 pt, rubber-banded.
    private static func rubberBand(_ pull: CGFloat) -> CGFloat {
        guard pull > 0 else { return 0 }
        return 10 * (1 - exp(-pull / 40))
    }
}

// MARK: - Lines

/// The subline and Tess's line, in words, from the session's state.
@MainActor
enum WorkoutLines {
    static func subline(_ session: WorkoutSession, phase: WorkoutSession.Phase) -> (String, Color, wet: Bool) {
        // `wet`: the line arrives in cadmium and dries to the context colour (sweep-19).
        guard let entry = session.currentEntry else { return ("", Paint.secondary, false) }
        if let row = session.editingRow {
            return (
                "set \(row.number), as logged: \(Format.kilograms(row.weight)) × \(Int(row.reps))",
                Paint.tess,
                false
            )
        }
        let target = session.targetSets(of: entry)
        let rows = session.setRows(of: entry)
        let tenth = { (value: Double) in Format.kilograms((value * 10).rounded() / 10) }
        switch phase {
        case .rest:
            if let seated = session.lastSeated, !seated.records.isEmpty, let e1RM = seated.e1RM {
                return ("a new best: e1RM \(tenth(e1RM))", Paint.now, true)
            }
            return ("set \(rows.count) seated", Paint.secondary, false)
        case .exerciseDone:
            return ("all \(target) sets in. Swipe for the next.", Paint.secondary, false)
        case .workoutDone:
            return ("every set is in", Paint.secondary, false)
        case .set:
            if let rpe = session.rpe {
                return ("RPE \(RPEStops.formatted(rpe)), \(RPEStops.words(for: rpe))", Paint.now, true)
            }
            if let hint = session.recordHint {
                let previous = hint.previous.map { ", \($0)" } ?? ""
                return ("set \(session.currentSetNumber): \(hint.text)\(previous)", Paint.now, true)
            }
            if session.swappedFrom != nil, rows.isEmpty {
                return ("swapped for today, set \(session.currentSetNumber) of \(target)", Paint.tess, false)
            }
            let last = rows.last.map { ", last was \(Format.kilograms($0.weight)) × \(Int($0.reps))" } ?? ""
            return ("set \(session.currentSetNumber) of \(target)\(last)", Paint.secondary, false)
        }
    }

    static func tess(_ session: WorkoutSession, phase: WorkoutSession.Phase, summary: String?) -> String {
        if session.finishedAt != nil {
            return summary ?? ""
        }
        if session.isEditing {
            return "Dial it in, then save."
        }
        if let note = session.editNote {
            return note
        }
        if case .rest = phase, let seated = session.lastSeated {
            // tess-voice: "Set 3. 80 x 8." and "New best: 85 x 5. e1RM 99."
            let set = "\(Format.kilograms(seated.weight)) × \(Int(seated.reps))"
            if seated.records.isEmpty {
                return "Set \(seated.number). \(set)."
            }
            return "New best: \(set)." +
                (seated.e1RM.map { " e1RM \(Format.kilograms(($0 * 10).rounded() / 10))." } ?? "")
        }
        switch phase {
        case .exerciseDone: return "\(session.currentExercise?.name ?? "That") is done."
        case .workoutDone: return "Last one. Hold to finish."
        default:
            return setLine(session)
        }
    }

    /// While dialling a set.
    private static func setLine(_ session: WorkoutSession) -> String {
        if let from = session.swappedFrom, let entry = session.currentEntry, session.setRows(of: entry).isEmpty {
            return "\(SwapPanel.short(from)) stays in the plan."
        }
        // The subline carries the numbers; Tess says what it would mean, once, quietly.
        if let hint = session.recordHint {
            let reps = hint.kinds.compactMap { kind -> Int? in
                if case let .repMax(count) = kind {
                    return count
                }
                return nil
            }.first
            let name = session.currentExercise?.name.lowercased() ?? "lift"
            return reps.map { "Best \($0)-rep \(name) yet, if it goes." } ?? "Best e1RM yet, if it goes."
        }
        if let note = session.restNote, note.hasPrefix("Skipped") {
            return note
        }
        if session.canUndo {
            return "Logged."
        }
        if let reason = session.targetReason, session.currentSetNumber == 1 {
            return reason + "."
        }
        if let best = session.previousBest {
            return "Last best was \(Format.kilograms(best.weight)) × \(Int(best.reps))."
        }
        return "Set \(session.currentSetNumber). \(Format.kilograms(session.weight)) × \(Int(session.reps))."
    }
}

// MARK: - Effort handle

/// Pull up on the reps (or tap "reps") to slide the effort stop-slider out; pull down to put it away.
struct EffortHandle: View {
    let isShown: Bool
    let enabled: Bool
    var setShown: (Bool) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("reps").font(Theme.voice(size: 16)).foregroundStyle(Paint.cream.opacity(0.55))
            Text("effort")
                .textRole(.label)
                .foregroundStyle((isShown ? Paint.now : Paint.secondary).opacity(0.7))
        }
        .frame(minWidth: 92, minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            if enabled {
                setShown(!isShown)
            }
        }
        .gesture(DragGesture(minimumDistance: 10).onEnded { drag in
            guard enabled else { return }
            if drag.translation.height < -20 {
                setShown(true)
            } else if drag.translation.height > 20 {
                setShown(false)
            }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isShown ? "Hide effort" : "Add effort")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            if enabled {
                setShown(!isShown)
            }
        }
    }
}

// MARK: - Edit keys

/// While a logged set is on the dial: Save set N (Core's EditSet) and a plain Cancel.
struct EditSetKeys: View {
    let session: WorkoutSession
    var onSave: () -> Void
    var onRemove: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let row = session.editingRow {
            // A tap in that set's own paint; the meta follows the dial and drum.
            PaintKey(paint: Paint.set(row.number), isTap: true, height: 64) {
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { session.saveEdit() }
                onSave()
            } label: { _ in
                Text("Save set \(row.number)")
            } meta: {
                Text("\(Format.kilograms(session.weight)) × \(Int(session.reps))")
            }
            .accessibilityLabel("Save set \(row.number) as \(Format.kilograms(session.weight)) by \(Int(session.reps))")
            Spacer(minLength: 0)
            HStack(spacing: 30) {
                Button("Remove") {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { session.removeEditing() }
                    onRemove()
                }
                .buttonStyle(.labelWord(Theme.Colors.liveInk))
                .accessibilityLabel("Remove set \(row.number)")
                Button("Cancel") {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { session.endEditing() }
                }
                .buttonStyle(.labelWord(Paint.secondary))
            }
        }
    }
}

// MARK: - Typing to Tess in live mode

/// Typed capture during a workout ("log bench 80x8", "8", "same"): a field that sits on the keyboard, sends the
/// phrase through Core's capture engine (the set shows as a ghost stroke, then seats), and closes.
struct LiveAskField: View {
    @Binding var isShown: Bool
    var onAsk: (String) -> Void
    /// A key was cleared: say where it goes, as Ask does.
    var onRefuse: () -> Void = {}
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
            TextField("log bench 80x8, or ask", text: $draft)
                .font(InkWordType.font)
                .foregroundStyle(Paint.cream)
                .focused($focused)
                .submitLabel(.go)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(submit)
                // A Claude key pasted here is cleared the moment it lands: no ghost, no set, no miss log.
                .onChange(of: draft) { _, text in
                    if LiveAskField.refuses(text) {
                        draft = ""
                        onRefuse()
                    }
                }
            Button("Close") { close() }
                .buttonStyle(.labelWord(Paint.secondary))
        }
        // A writing line, not a field: 0.5 pt under the words (no-buttons.md, "Write").
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) { Rectangle().fill(Paint.tess.opacity(0.6)).frame(height: 0.5) }
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.top, Theme.Spacing.s)
        .frame(maxHeight: .infinity, alignment: .top)
        .preferredColorScheme(ThemeStore.shared.workoutLook.isDark ? .dark : .light)
        .onAppear { focused = true }
    }

    /// Anything holding "sk-ant-", in any case (the guard Ask uses, BottomChrome.looksLikeClaudeKey).
    static func refuses(_ text: String) -> Bool {
        looksLikeClaudeKey(text)
    }

    private func submit() {
        let phrase = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        if !phrase.isEmpty, !Self.refuses(phrase) {
            onAsk(phrase)
        }
        close()
    }

    private func close() {
        focused = false
        isShown = false
    }
}
