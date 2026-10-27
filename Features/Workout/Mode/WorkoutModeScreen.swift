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
    /// Sheet 338: the rest board as it was, wiped off by the eraser band when the rest ends.
    @State private var wipeImage: Image?
    @State private var wipeTime = 0.0
    @State private var wipeDirection = EraserBand.Direction.leftToRight
    @State private var middleSize = CGSize.zero
    /// Sheet 348: the set just logged waits for its tick until the rest ends, then it is drawn on.
    @State private var tickLift: String?
    @State private var tickSet = 0
    @State private var tickValue = 1.0
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Slot heights follow the type they hold (the lines themselves stay one line, shrunk to fit).
    @ScaledMetric(relativeTo: .callout) private var line = 26.0
    @ScaledMetric(relativeTo: .title) private var title = 40.0

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
        // The lines scale with Dynamic Type up to xxxLarge (AX sizes use that layout); the display numerals never
        // scale.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var slate: some View {
        BlackboardSlate(dark: true).drawingGroup().ignoresSafeArea()
    }

    // MARK: Layout

    /// Sheet 327's positions on its 874 pt screen, scaled by the screen's height: the lifts list from y 640 in 26 pt
    /// rows (hidden in a rest and when type grows), the receipt at 704, the verb's baseline at 790. The top block and
    /// the
    /// middle flow from the top; the middle shows as many of its secondary lines as fit above the list.
    private enum Spot {
        static let designHeight: CGFloat = 874
        static let list: CGFloat = 640
        static let receipt: CGFloat = 704
        static let verbBaseline: CGFloat = 790
        static let verbHeight: CGFloat = 56
        static let row: CGFloat = 26
        /// The title (44 pt target) and the hold-to-finish words (44 pt target) under it.
        static let top: CGFloat = 92
    }

    private static var windowTopInset: CGFloat {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
            .first(where: \.isKeyWindow)?.safeAreaInsets.top ?? 0
    }

    private func content(now: Date) -> some View {
        let board = state.scoreboard(at: now)
        return GeometryReader { proxy in
            let scale = proxy.size.height / Spot.designHeight
            // The window's own inset covers a cover that reports none to its content.
            let inset = max(proxy.safeAreaInsets.top, Self.windowTopInset)
            let listTop = Spot.list * scale
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    top(now: now).frame(height: Spot.top)
                    ViewThatFits(in: .vertical) {
                        middle(board: board, now: now, level: 0)
                        middle(board: board, now: now, level: 1)
                        middle(board: board, now: now, level: 2)
                        middle(board: board, now: now, level: 3)
                    }
                    .frame(maxHeight: max(listTop - inset - Spot.top - 8, 0), alignment: .top)
                }
                .padding(.top, inset)
                if showsLifts(board) {
                    steps()
                        .frame(width: 190, alignment: .trailing)
                        .offset(x: proxy.size.width - 44 - 190, y: listTop)
                }
                Text(receipt ?? " ")
                    .font(Chalk.font(20, relativeTo: .callout))
                    .foregroundStyle(Chalk.quiet)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(height: line * 1.1, alignment: .leading)
                    .accessibilityIdentifier("mode.receipt")
                    .accessibilityHidden(receipt == nil)
                    .offset(y: Spot.receipt * scale)
                Button(action: { verb(now) }) {
                    Text(verbWord(board)).font(Chalk.font(44, relativeTo: .largeTitle)).foregroundStyle(Chalk.blue)
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .frame(height: Spot.verbHeight, alignment: .leading)
                }
                .accessibilityHint("Or swipe up")
                .accessibilityIdentifier("mode.verb")
                .offset(y: (Spot.verbBaseline + 14) * scale - Spot.verbHeight)
                // What the sizes drop from the screen is still said: VoiceOver reads everything.
                Text(spoken(board, now: now))
                    .font(.system(size: 1)).opacity(0.01)
                    .frame(width: 2, height: 2)
                    .accessibilityLabel(spoken(board, now: now))
                    .accessibilityIdentifier("mode.spoken")
            }
            .padding(.horizontal, 22)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .tesseraAnimation(value: receipt)
        }
        .ignoresSafeArea()
    }

    /// The lifts list shows at default type and not in a rest or Done; it is the first thing larger type drops.
    private func showsLifts(_ board: WorkoutModeState.Scoreboard) -> Bool {
        !board.isRest && !state.isDone && typeSize <= .large
    }

    /// Everything the screen may drop, as one line for VoiceOver.
    private func spoken(_ board: WorkoutModeState.Scoreboard, now _: Date) -> String {
        let lifts = state.lifts.map { "\($0.name), \($0.setsLeft) sets left" }.joined(separator: ". ")
        let estimate = state.estimatedMax.map { "Estimated max \(PlateLoad.number($0.rounded()))" } ?? ""
        return [board.header, board.info1, board.info2, estimate, lifts].filter { !$0.isEmpty }.joined(separator: ". ")
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
                HoldToFinishWords { finish(now) }
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
    private func middle(board: WorkoutModeState.Scoreboard, now: Date, level: Int = 0) -> some View {
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
            .frame(height: line * 0.95)
            if board.isRest {
                restBody(board: board, now: now)
            } else if state.isDone {
                doneBody(board: board)
            } else {
                setBody(board: board, lift: lift, now: now, level: level)
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { middleSize = $0 }
        .overlay(alignment: .topLeading) {
            if let wipeImage {
                AnimatedEraserWipe(snapshot: wipeImage, time: wipeTime, direction: wipeDirection)
            }
        }
    }

    private func setBody(board: WorkoutModeState.Scoreboard, lift: WorkoutModeState.Lift, now: Date, level: Int)
        -> some View
    {
        let model = state.board(at: now)
        return VStack(alignment: .leading, spacing: 6) {
            Text(lift.name).font(Chalk.font(34, relativeTo: .title)).foregroundStyle(Chalk.white)
                .lineLimit(1).minimumScaleFactor(0.5).frame(height: title, alignment: .leading)
                .accessibilityIdentifier("mode.lift")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(board.main).font(Chalk.numerals(170)).foregroundStyle(Chalk.white)
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
            if level < 3 {
                chips(model: model)
            }
            infoLines(board: board, level: level)
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
            .lineLimit(1).minimumScaleFactor(0.6).frame(height: line, alignment: .leading)
            .accessibilityIdentifier("mode.platesLine")
    }

    private func chips(model: WorkoutModeState.Board) -> some View {
        let rows = state.summary(at: AppClock.now).rows
        return HStack(spacing: 14) {
            ForEach(Array(zip(model.chips, rows)), id: \.0.id) { chip, row in
                HStack(spacing: 4) {
                    if chip.state == .done {
                        // The set you just did gets its tick drawn on as the rest ends; the slot is always there.
                        DrawnTick(progress: tickProgress(forSet: chip.id))
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
        .frame(height: line * 1.25)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mode.chips")
    }

    /// Last time and the estimated max, the two lines that go when space runs out: the estimate first, then last time.
    private func infoLines(board: WorkoutModeState.Scoreboard, level: Int) -> some View {
        let estimate = state.estimatedMax.map { "est. max \(PlateLoad.number($0.rounded()))" } ?? ""
        return VStack(alignment: .leading, spacing: 2) {
            if level < 2 {
                Text(board.info2).font(Chalk.font(22, relativeTo: .callout)).foregroundStyle(Chalk.quiet)
                    .lineLimit(1).minimumScaleFactor(0.6).frame(height: line, alignment: .leading)
                    .accessibilityIdentifier("mode.lastTime")
            }
            if level < 1 {
                Text(estimate).font(Chalk.font(22, relativeTo: .callout)).foregroundStyle(Chalk.quiet)
                    .lineLimit(1).frame(height: line, alignment: .leading)
                    .accessibilityIdentifier("mode.estimate")
            }
        }
    }

    // MARK: Rest

    private func restBody(board: WorkoutModeState.Scoreboard, now: Date) -> some View {
        let model = state.board(at: now)
        return VStack(alignment: .leading, spacing: 6) {
            Text(board.main).font(Chalk.numerals(178)).foregroundStyle(Chalk.white).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.4)
                .contentTransition(.numericText(countsDown: true))
                .tesseraAnimation(Theme.Motion.snappy, value: board.main)
                .frame(height: 150, alignment: .leading)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityIdentifier("mode.restTime")
            chalkStrokes(now: now).accessibilityIdentifier("mode.strokes")
            restNextLine(board: board)
                .font(Chalk.font(24, relativeTo: .title3))
                .minimumScaleFactor(0.6).frame(height: line * 1.15, alignment: .leading)
                .accessibilityIdentifier("mode.restNext")
            Text(model.loadNext ?? " ").font(Chalk.font(22, relativeTo: .callout)).foregroundStyle(Chalk.quiet)
                .lineLimit(1).minimumScaleFactor(0.6).frame(height: line, alignment: .leading)
                .accessibilityIdentifier("mode.loadNext")
            Text("How did it feel").font(Chalk.font(40, relativeTo: .title)).foregroundStyle(Chalk.blue)
                .lineLimit(1).minimumScaleFactor(0.6).frame(height: title * 1.15, alignment: .leading)
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

    /// "Next, bench press, 185 lb x 5"; once Felt changed the weight, the old number is struck and the new written
    /// after.
    @ViewBuilder
    private func restNextLine(board: WorkoutModeState.Scoreboard) -> some View {
        if let change = state.restNextChange, case let .rest(_, _, lift) = state.phase,
           let next = state.nextUp(after: lift)
        {
            FeltChangeLine(
                prefix: "Next, \(next.lift.name.lowercased()),", old: PlateLoad.number(change.old),
                new: PlateLoad.number(change.new), suffix: "\(state.unit.symbol) \u{00D7} \(next.set.reps)"
            )
        } else {
            Text(board.info1).foregroundStyle(Chalk.white).lineLimit(1)
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
            Text(board.main).font(Chalk.numerals(150)).foregroundStyle(Chalk.white).lineLimit(1).minimumScaleFactor(0.4)
                .frame(height: 124, alignment: .leading)
            // Minutes and sets stay still; the total counts up (sheet 349).
            Text(state.finishHead(at: AppClock.now)).font(Chalk.font(26, relativeTo: .title3))
                .foregroundStyle(Chalk.white)
                .lineLimit(1).minimumScaleFactor(0.6).frame(height: line * 1.3, alignment: .leading)
            CountUpRow(final: (state.volume / 5).rounded() * 5, unit: state.unit.symbol)
                .frame(height: 56, alignment: .leading)
                .accessibilityIdentifier("mode.doneTotal")
            // The session's real new bests, from the ledger's best per lift; else steady work.
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(state.doneBestLines.prefix(3).enumerated()), id: \.offset) { _, bestLine in
                    Text(bestLine).font(Chalk.font(24, relativeTo: .title3)).foregroundStyle(Chalk.blue)
                        .lineLimit(1).minimumScaleFactor(0.6).frame(height: line * 1.15, alignment: .leading)
                }
            }
            .accessibilityIdentifier("mode.doneBests")
        }
    }

    // MARK: Thumb zone

    private func verbWord(_ board: WorkoutModeState.Scoreboard) -> String {
        if state.isDone {
            return "Close"
        }
        return board.isRest ? "Start now" : "Done"
    }

    /// The lifts down the right edge, above Tess's corner: tap one to jump.
    private func steps() -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(state.lifts.enumerated()), id: \.element.id) { index, lift in
                Button {
                    changeLift(to: index, direction: .forTap(from: state.focus, to: index))
                } label: {
                    HStack(spacing: 6) {
                        if lift.isComplete {
                            Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
                        }
                        Text(lift.name)
                        Text(lift.isComplete ? "" : "\(lift.setsLeft)").foregroundStyle(Chalk.quiet)
                    }
                    .font(Chalk.font(index == state.focus ? 24 : 21, relativeTo: .callout))
                    .foregroundStyle(index == state.focus ? Chalk.blue : (lift.isComplete ? Chalk.faint : Chalk.white))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(height: Spot.row, alignment: .trailing)
                }
                .accessibilityLabel("\(lift.name), \(lift.setsLeft) sets left")
                .accessibilityIdentifier("mode.step.\(index)")
            }
        }
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
                    changeLift(to: state.focus + (dx < 0 ? 1 : -1), direction: .forSwipe(dx: dx))
                }
            }
    }

    // MARK: Moves

    private func verb(_ now: Date) {
        if state.isDone {
            actions.close(); return
        }
        if case .rest = state.phase {
            wipeRestBoard(now)
            drawTick()
            withTesseraAnimation(reduceMotion: reduceMotion) { state.endRest(at: now) }
            actions.changed(state)
            return
        }
        let liftID = state.current.id
        guard let index = state.current.nextIndex else { return }
        let planned = state.current.sets[index]
        withTesseraAnimation(reduceMotion: reduceMotion) { _ = state.logSet(at: now) }
        tickLift = liftID
        tickSet = index
        tickValue = 0
        if state.isDone {
            drawTick()
        }
        cue.play(state.isDone ? .done : .setLogged)
        dust += 1
        actions.logged(liftID, planned.weight, planned.reps)
        actions.changed(state)
        if state.isDone {
            actions.finished()
        }
    }

    /// Changing lift in the lift phase wipes the board with the eraser (a swipe left sweeps right to left, a tap on a
    /// later
    /// lift the same, an earlier one the other way). During a rest it only queues the lift: no wipe, it turns when the
    /// rest ends.
    private func changeLift(to index: Int, direction: EraserBand.Direction) {
        guard state.lifts.indices.contains(index), !state.isDone else { return }
        if case .rest = state.phase {
            state.select(lift: index)
        } else {
            guard index != state.focus else { return }
            wipeBoard(AppClock.now, direction: direction)
            state.select(lift: index)
        }
        cue.play(.selection)
        actions.changed(state)
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

    /// Flattens the rest board and wipes it off with the eraser band (460 ms), revealing the next lift's board, which
    /// is
    /// already live behind it. Called just before the rest ends. Reduce Motion: a plain swap (nothing is made).
    private func wipeRestBoard(_ now: Date) {
        guard case .rest = state.phase else { return }
        wipeBoard(now, direction: .leftToRight)
    }

    /// Wipes the board as it is now off with the eraser, in `direction`, revealing what the state changes to behind it
    /// (called just before the change). Reduce Motion: nothing is made, the swap is plain.
    private func wipeBoard(_ now: Date, direction: EraserBand.Direction) {
        guard !reduceMotion, middleSize.width > 0, middleSize.height > 0 else { return }
        wipeDirection = direction
        let board = state.scoreboard(at: now)
        let layer = middle(board: board, now: now)
            .frame(width: middleSize.width, height: middleSize.height, alignment: .topLeading)
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: layer)
        renderer.scale = displayScale
        guard let image = renderer.uiImage else { return }
        wipeImage = Image(uiImage: image)
        wipeTime = 0
        withAnimation(.linear(duration: EraserBand.duration)) { wipeTime = 1 }
        Task {
            try? await Task.sleep(for: .seconds(EraserBand.duration + 0.05))
            wipeImage = nil
        }
    }

    /// The drawn fraction of the tick on a done set: 1 for any set but the one waiting for its tick.
    private func tickProgress(forSet index: Int) -> Double {
        tickLift == state.current.id && tickSet == index ? tickValue : 1
    }

    /// The rest ended: 380 ms on, the waiting tick is drawn over 260 ms (the eraser passes as it lands). Reduce Motion:
    /// it appears without being drawn.
    private func drawTick() {
        guard tickLift != nil, tickValue < 1 else { return }
        guard !reduceMotion else {
            tickValue = 1
            return
        }
        Task {
            try? await Task.sleep(for: .seconds(TickDraw.delay))
            withAnimation(.linear(duration: TickDraw.duration)) { tickValue = 1 }
        }
    }

    private func tick(_ now: Date) {
        if case let .rest(endsAt, _, _) = state.phase, endsAt <= now {
            wipeRestBoard(now)
            drawTick()
        }
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
