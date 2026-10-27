import SwiftUI

/// What the screen asks of its host; the host writes to the engine (the state is only the screen's own bookkeeping).
struct WorkoutModeActions {
    var close: () -> Void = {}
    /// A set was logged: the lift's id, its weight and reps.
    var logged: (_ liftID: String, _ weight: Double, _ reps: Int) -> Void = { _, _, _ in }
    var finished: () -> Void = {}
    /// The state changed (Live Activity, resume).
    var changed: (WorkoutModeState) -> Void = { _ in }
}

/// Workout mode, the whole blackboard (sheets 327 and 325): slate full bleed, everything in chalk. Top to bottom: what
/// this is, the one big thing, the facts that serve it; the bottom third is the thumb's (verb bottom left, the lifts
/// down the right edge). Every line is a fixed slot: one line, shrinks to fit, never wraps or pushes its neighbours.
///
/// The visuals read only `WorkoutModeState`'s derived values (`scoreboard`, `board`, `summary`, `band`), so a revision
/// of the look slots in here without touching the words.
struct WorkoutModeScreen: View {
    @State var state: WorkoutModeState
    var actions = WorkoutModeActions()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cue = HapticCue()
    @State private var receipt: String?
    @State private var dragSteps = 0
    @State private var dust = 0
    @State private var finishHold = false
    /// Sheet 336: the clip over the new-best line (0 closed, 1 open), widened over 720 ms.
    @State private var bestReveal = 0.0

    private static let slate = Color(hex: 0x1F2524)
    private let dragStep: CGFloat = 26

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let now = AppClock.now
            content(now: now)
                .onChange(of: now.timeIntervalSinceReferenceDate.rounded()) { _, _ in tick(now) }
        }
        .background(alignment: .center) { slate }
        .tesseraFeedback(cue)
        .gesture(swipe)
        .preferredColorScheme(.dark)
        .statusBarHidden(false)
        // Fixed slots: the lines scale with Dynamic Type up to here, and the 170 pt numerals shrink to fit instead.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var slate: some View {
        BlackboardSlate(dark: true).drawingGroup().ignoresSafeArea()
    }

    // MARK: Layout

    private func content(now: Date) -> some View {
        let board = state.scoreboard(at: now)
        return VStack(alignment: .leading, spacing: 0) {
            top(now: now)
                .frame(height: 64)
            middle(board: board, now: now)
            Spacer(minLength: 8)
            if let receipt {
                Text(receipt)
                    .font(Chalk.font(20, relativeTo: .callout))
                    .foregroundStyle(Chalk.quiet)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(height: 28)
                    .accessibilityIdentifier("mode.receipt")
                    .transition(.opacity)
            } else {
                Color.clear.frame(height: 28)
            }
            thumb(board: board, now: now)
                .frame(height: 190)
        }
        .padding(.horizontal, 22)
        .tesseraAnimation(value: receipt)
    }

    private func top(now: Date) -> some View {
        let band = state.band(at: now)
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Button(action: actions.close) {
                    Text(state.title).font(Chalk.font(34, relativeTo: .title)).foregroundStyle(Chalk.blue)
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .frame(minHeight: 44, alignment: .leading)
                }
                .accessibilityLabel("\(state.title), back")
                .accessibilityIdentifier("mode.title")
                Text("hold to finish").font(Chalk.font(16)).foregroundStyle(Chalk.faint).lineLimit(1)
                    .onLongPressGesture(minimumDuration: 0.6) { finish(now) }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Hold to finish")
                    .accessibilityIdentifier("mode.hold")
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text(band.clock).font(Chalk.font(34, relativeTo: .title)).monospacedDigit().foregroundStyle(Chalk.white)
                    .lineLimit(1).accessibilityIdentifier("mode.clock")
                Text(band.doneAbout.lowercased()).font(Chalk.font(16)).foregroundStyle(Chalk.quiet)
                    .lineLimit(1).minimumScaleFactor(0.7).accessibilityIdentifier("mode.doneAbout")
            }
        }
    }

    @ViewBuilder
    private func middle(board: WorkoutModeState.Scoreboard, now: Date) -> some View {
        let lift = state.current
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(board.header).font(Chalk.font(18, relativeTo: .callout)).tracking(2).foregroundStyle(Chalk.quiet)
                Spacer()
                if let best = state.restNewBest {
                    newBestLine(best)
                } else {
                    Text(board.trailing).font(Chalk.font(18, relativeTo: .callout)).tracking(1)
                        .foregroundStyle(Chalk.quiet)
                }
            }
            .lineLimit(1).minimumScaleFactor(0.7)
            .frame(height: 24)
            if board.isRest {
                restBody(board: board, now: now)
            } else if state.isDone {
                doneBody(board: board)
            } else {
                setBody(board: board, lift: lift, now: now)
            }
        }
    }

    private func setBody(board: WorkoutModeState.Scoreboard, lift: WorkoutModeState.Lift, now: Date) -> some View {
        let model = state.board(at: now)
        return VStack(alignment: .leading, spacing: 6) {
            Text(lift.name).font(Chalk.font(34, relativeTo: .title)).foregroundStyle(Chalk.white)
                .lineLimit(1).minimumScaleFactor(0.5).frame(height: 40, alignment: .leading)
                .accessibilityIdentifier("mode.lift")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(board.main).font(Chalk.font(170)).foregroundStyle(Chalk.white)
                    .lineLimit(1).minimumScaleFactor(0.4).monospacedDigit()
                    .contentTransition(.numericText())
                    .tesseraAnimation(Theme.Motion.snappy, value: board.main)
                VStack(alignment: .leading, spacing: 0) {
                    Text(board.unit).font(Chalk.font(48)).foregroundStyle(Chalk.blue)
                    Text(board.multiplier).font(Chalk.font(48)).foregroundStyle(Chalk.blue)
                }
                .lineLimit(1).minimumScaleFactor(0.5)
            }
            .frame(height: 124, alignment: .leading)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .contentShape(Rectangle())
            .gesture(weightDrag)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("mode.weight")
            .accessibilityLabel(
                "\(board.main) \(board.unit), \(board.multiplier.replacingOccurrences(of: "×", with: "times"))"
            )
            .accessibilityAdjustableAction { direction in
                state.drag(steps: direction == .increment ? 1 : -1)
                actions.changed(state)
            }
            barAndPlates(model: model)
            chips(model: model)
            infoLines(board: board)
        }
    }

    @ViewBuilder
    private func barAndPlates(model: WorkoutModeState.Board) -> some View {
        Group {
            if let plates = model.plates {
                PlateBar(load: plates, inventory: state.inventory).accessibilityIdentifier("mode.bar")
            } else if state.current.isWarmUp {
                Color.clear
            } else {
                Text("Pin on the stack").font(Chalk.font(20)).foregroundStyle(Chalk.quiet)
                    .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            }
        }
        .frame(height: 76)
        Text(model.plates.map { $0.line.prefix(1).uppercased() + $0.line.dropFirst() } ?? " ")
            .font(Chalk.font(22, relativeTo: .callout)).foregroundStyle(Chalk.white)
            .lineLimit(1).minimumScaleFactor(0.6).frame(height: 26, alignment: .leading)
            .accessibilityIdentifier("mode.platesLine")
    }

    private func chips(model: WorkoutModeState.Board) -> some View {
        let rows = state.summary(at: AppClock.now).rows
        return HStack(spacing: 14) {
            ForEach(Array(zip(model.chips, rows)), id: \.0.id) { chip, row in
                HStack(spacing: 4) {
                    if chip.state == .done {
                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                    }
                    Text(chip.text + (row.felt.isEmpty ? "" : " \(row.felt.lowercased())"))
                }
                .font(Chalk.font(chip.state == .current ? 26 : 20, relativeTo: .callout))
                .foregroundStyle(chip.state == .left ? Chalk
                    .faint : (chip.state == .current ? Chalk.blue : Chalk.white))
                .lineLimit(1).minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 32)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mode.chips")
    }

    private func infoLines(board: WorkoutModeState.Scoreboard) -> some View {
        let estimate = state.estimatedMax.map { "est. max \(PlateLoad.number($0.rounded()))" } ?? ""
        return VStack(alignment: .leading, spacing: 2) {
            Text(board.info2).font(Chalk.font(22, relativeTo: .callout)).foregroundStyle(Chalk.quiet)
                .lineLimit(1).minimumScaleFactor(0.6).frame(height: 26, alignment: .leading)
                .accessibilityIdentifier("mode.lastTime")
            Text(estimate).font(Chalk.font(22, relativeTo: .callout)).foregroundStyle(Chalk.quiet)
                .lineLimit(1).frame(height: 26, alignment: .leading)
                .accessibilityIdentifier("mode.estimate")
        }
    }

    // MARK: Rest

    private func restBody(board: WorkoutModeState.Scoreboard, now: Date) -> some View {
        let model = state.board(at: now)
        return VStack(alignment: .leading, spacing: 6) {
            Text(board.main).font(Chalk.font(178)).foregroundStyle(Chalk.white).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.4)
                .contentTransition(.numericText(countsDown: true))
                .tesseraAnimation(Theme.Motion.snappy, value: board.main)
                .frame(height: 150, alignment: .leading)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityIdentifier("mode.restTime")
            chalkStrokes(now: now).accessibilityIdentifier("mode.strokes")
            Text(board.info1).font(Chalk.font(24, relativeTo: .title3)).foregroundStyle(Chalk.white)
                .lineLimit(1).minimumScaleFactor(0.6).frame(height: 30, alignment: .leading)
                .accessibilityIdentifier("mode.restNext")
            Text(model.loadNext ?? " ").font(Chalk.font(22, relativeTo: .callout)).foregroundStyle(Chalk.quiet)
                .lineLimit(1).minimumScaleFactor(0.6).frame(height: 26, alignment: .leading)
                .accessibilityIdentifier("mode.loadNext")
            Text("How did it feel").font(Chalk.font(40, relativeTo: .title)).foregroundStyle(Chalk.blue)
                .lineLimit(1).minimumScaleFactor(0.6).frame(height: 46, alignment: .leading)
                .accessibilityIdentifier("mode.howFelt")
            HStack(spacing: 10) {
                ForEach(WorkoutModeState.Felt.allCases, id: \.self) { felt in
                    Button { applyFelt(felt) } label: {
                        Text(felt.word).font(Chalk.font(34, relativeTo: .title2)).foregroundStyle(Chalk.white)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Chalk.quiet, lineWidth: 2))
                    }
                    .accessibilityLabel(felt.word)
                    .accessibilityIdentifier("mode.felt.\(felt.rawValue)")
                    .accessibilityHint(hint(for: felt))
                }
            }
        }
    }

    /// Twelve chalk strokes for the rest, one wiped every ten seconds (sheet 321).
    private func chalkStrokes(now: Date) -> some View {
        let total = max(state.restTotal, 1)
        let left = state.restRemaining(at: now) ?? 0
        let shown = min(12, Int((left / total * 12).rounded(.up)))
        return HStack(spacing: 6) {
            ForEach(0 ..< 12, id: \.self) { index in
                Capsule().fill(index < shown ? Chalk.white : Chalk.faint.opacity(0.4)).frame(width: 3, height: 18)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 22)
        .accessibilityHidden(true)
    }

    private func hint(for felt: WorkoutModeState.Felt) -> String {
        switch felt {
        case .easy: "Adds \(PlateLoad.number(state.step)) \(state.unit.symbol) to the sets left"
        case .right: "Keeps the weight"
        case .hard: "Takes \(PlateLoad.number(state.step)) \(state.unit.symbol) off the sets left"
        }
    }

    /// "new best, est. 216 lb" top right in accent chalk, the unit at half size. The clip widens over 720 ms; under
    /// Reduce Motion it is simply there.
    private func newBestLine(_ best: WorkoutModeState.NewBest) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("new best, est.").font(Chalk.font(20, relativeTo: .callout))
            Text(best.number).font(Chalk.font(28, relativeTo: .title3))
            Text(state.unit.symbol).font(Chalk.font(14, relativeTo: .caption))
        }
        .foregroundStyle(Chalk.blue)
        .lineLimit(1)
        .fixedSize()
        .mask(alignment: .leading) {
            GeometryReader { proxy in
                Rectangle().frame(width: proxy.size.width * (reduceMotion ? 1 : bestReveal))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New best, estimated \(best.number) \(state.unit.symbol)")
        .accessibilityIdentifier("mode.newBest")
        .onAppear { revealBest() }
    }

    private func revealBest() {
        guard !reduceMotion else {
            bestReveal = 1
            return
        }
        bestReveal = 0
        withAnimation(.easeOut(duration: 0.72)) { bestReveal = 1 }
        BestBuzz.play()
    }

    private func doneBody(board: WorkoutModeState.Scoreboard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(board.main).font(Chalk.font(170)).foregroundStyle(Chalk.white).lineLimit(1).minimumScaleFactor(0.4)
                .frame(height: 124, alignment: .leading)
            Text(state.finishLine(at: AppClock.now)).font(Chalk.font(26, relativeTo: .title3))
                .foregroundStyle(Chalk.white)
                .lineLimit(2).minimumScaleFactor(0.6).frame(height: 64, alignment: .leading)
            // The session's real new bests, from the ledger's best per lift; else steady work.
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(state.doneBestLines.prefix(3).enumerated()), id: \.offset) { _, line in
                    Text(line).font(Chalk.font(24, relativeTo: .title3)).foregroundStyle(Chalk.blue)
                        .lineLimit(1).minimumScaleFactor(0.6).frame(height: 30, alignment: .leading)
                }
            }
            .accessibilityIdentifier("mode.doneBests")
        }
    }

    // MARK: Thumb zone

    private func thumb(board: WorkoutModeState.Scoreboard, now: Date) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Spacer(minLength: 0)
                if !board.isRest, !state.isDone {
                    summaryLedger(now: now)
                }
                Button(action: { verb(now) }) {
                    Text(verbWord(board)).font(Chalk.font(44, relativeTo: .largeTitle)).foregroundStyle(Chalk.blue)
                        .lineLimit(1).minimumScaleFactor(0.6).frame(minHeight: 56, alignment: .leading)
                }
                .accessibilityHint("Or swipe up")
                .accessibilityIdentifier("mode.verb")
            }
            Spacer(minLength: 8)
            steps()
        }
    }

    private func verbWord(_ board: WorkoutModeState.Scoreboard) -> String {
        if state.isDone {
            return "Close"
        }
        return board.isRest ? "Start now" : "Done"
    }

    private func summaryLedger(now: Date) -> some View {
        let summary = state.summary(at: now)
        return Text(summary.footer.isEmpty ? " " : summary.footer).font(Chalk.font(20, relativeTo: .callout))
            .foregroundStyle(Chalk.quiet).lineLimit(1).minimumScaleFactor(0.6).frame(height: 24, alignment: .leading)
            .accessibilityIdentifier("mode.footer")
    }

    /// The lifts down the right edge, above Tess's corner: tap one to jump.
    private func steps() -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            ForEach(Array(state.lifts.enumerated()), id: \.element.id) { index, lift in
                Button {
                    state.select(lift: index)
                    cue.play(.selection)
                    actions.changed(state)
                } label: {
                    HStack(spacing: 6) {
                        if lift.isComplete {
                            Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
                        }
                        Text(lift.name)
                        Text(lift.isComplete ? "" : "\(lift.setsLeft)").foregroundStyle(Chalk.quiet)
                    }
                    .font(Chalk.font(index == state.focus ? 26 : 22, relativeTo: .callout))
                    .foregroundStyle(index == state.focus ? Chalk.blue : (lift.isComplete ? Chalk.faint : Chalk.white))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(minHeight: 40, alignment: .trailing)
                }
                .accessibilityLabel("\(lift.name), \(lift.setsLeft) sets left")
                .accessibilityIdentifier("mode.step.\(index)")
            }
        }
        .frame(maxWidth: 190, alignment: .trailing)
        .padding(.bottom, 56)
    }

    // MARK: Gestures

    private var weightDrag: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                let steps = Int((-value.translation.height / dragStep).rounded(.towardZero))
                let delta = steps - dragSteps
                guard delta != 0 else { return }
                dragSteps = steps
                if state.drag(steps: delta) {
                    cue.play(.selection); actions.changed(state)
                }
            }
            .onEnded { _ in dragSteps = 0 }
    }

    /// Swipe up anywhere does the verb; across turns to the next or previous lift.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                let dx = value.translation.width, dy = value.translation.height
                if abs(dy) > abs(dx), dy < -80 {
                    verb(AppClock.now)
                } else if abs(dx) > abs(dy), abs(dx) > 70 {
                    let next = state.focus + (dx < 0 ? 1 : -1)
                    state.select(lift: next)
                    cue.play(.selection)
                    actions.changed(state)
                }
            }
    }

    // MARK: Moves

    private func verb(_ now: Date) {
        if state.isDone {
            actions.close(); return
        }
        if case .rest = state.phase {
            withTesseraAnimation(reduceMotion: reduceMotion) { state.endRest(at: now) }
            actions.changed(state)
            return
        }
        let liftID = state.current.id
        guard let index = state.current.nextIndex else { return }
        let planned = state.current.sets[index]
        withTesseraAnimation(reduceMotion: reduceMotion) { _ = state.logSet(at: now) }
        cue.play(state.isDone ? .done : .setLogged)
        dust += 1
        actions.logged(liftID, planned.weight, planned.reps)
        actions.changed(state)
        if state.isDone {
            actions.finished()
        }
    }

    private func applyFelt(_ felt: WorkoutModeState.Felt) {
        guard let result = state.apply(felt: felt) else { return }
        cue.play(.selection)
        receipt = result.text
        actions.changed(state)
    }

    private func finish(_ now: Date) {
        state.finish(at: now)
        cue.play(.done)
        actions.changed(state)
        actions.finished()
    }

    private func tick(_ now: Date) {
        let before = state.phase
        state.tick(at: now)
        if before != state.phase {
            cue.play(.timeUp)
            receipt = nil
            actions.changed(state)
        }
    }
}

extension WorkoutModeState {
    /// The rest's length, for the chalk strokes.
    var restTotal: TimeInterval {
        if case let .rest(_, total, _) = phase {
            total
        } else {
            0
        }
    }
}
