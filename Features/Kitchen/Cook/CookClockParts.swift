import SwiftUI
import TesseraCore

// MARK: - Steps

/// This step large, the one before it dim above, the next two dim below. A vertical drag turns the lead track.
struct StepStack: View {
    let session: CookClockSession
    let calm: Bool
    let hintsLeft: Int
    let move: (Bool) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var drag: CGFloat = 0

    var body: some View {
        let current = session.current
        let before = (0 ..< current).reversed()
            .first { session.plan.steps[$0].lane == session.plan.steps[current].lane }
        let after = (current + 1 ..< session.steps.count)
            .filter { session.plan.steps[$0].lane == session.plan.steps[current].lane || !session.parallel }
            .prefix(2)
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if let before {
                Text(session.text(of: before))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.Workout.inkTertiary)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(session.text(of: current))
                    .textRole(.title)
                    .wordFit(session.text(of: current))
                    .foregroundStyle(Theme.Colors.Workout.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if current == 0 {
                    CookNoteLine(recipeID: session.recipeID, dark: true)
                }
            }
            .id(current)
            .transition(calm ? .opacity : .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(session.text(of: current))
            .accessibilityValue(value)
            ForEach(Array(after), id: \.self) { index in
                Text(session.text(of: index))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.Workout.inkTertiary)
                    .accessibilityHidden(true)
            }
            if hintsLeft > 0 {
                Text("Swipe up for the next step")
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.Workout.inkTertiary)
                    .padding(.top, Theme.Spacing.s)
                    .accessibilityHidden(true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .offset(y: calm ? 0 : drag * 0.25)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart))
                .onChanged { value in
                    let lead = CGFloat(GestureTuning.pagerBias)
                    guard abs(value.translation.height) >= abs(value.translation.width) * lead else { return }
                    drag = value.translation.height
                }
                .onEnded { value in
                    let pull = GestureTuning.pull(
                        dx: Double(value.translation.width), dy: Double(value.translation.height),
                        velocityY: Double(value.velocity.height)
                    )
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: calm) { drag = 0 }
                    // Up is the next step, down the one before.
                    if pull < 0 {
                        move(true)
                    } else if pull > 0 {
                        move(false)
                    }
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityAdjustableAction { direction in
            move(direction == .increment)
        }
        .accessibilityAction(named: Text("Next step")) { move(true) }
        .accessibilityAction(named: Text("Previous step")) { move(false) }
        .accessibilityHint(CookClockCopy.swipeHint)
    }

    private var value: String {
        let step = session.current
        var parts = ["Step \(step + 1) of \(session.steps.count)"]
        if let line = session.timer(ofStep: step) {
            parts.append(line.isDone(at: AppClock.now) ? "Time's up, waiting for you"
                : "Now, \(CookModeCopy.duration(line.remaining(at: AppClock.now))) left")
        } else {
            parts.append("Now")
        }
        return parts.joined(separator: ", ")
    }
}

/// The key figure: "33 MIN LEFT" from the clock's join, changing at the minute boundary of `endsAt`.
struct KeyFigure: View {
    let session: CookClockSession
    let now: Date

    var body: some View {
        let minutes = CookClockPlan.figure(minutesLeft: session.minutesLeft(at: now))
        let leadLine = session.timer(ofStep: session.current)
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
            Text(CookClockCopy.keyFigure(minutes: minutes))
                .textRole(.labelStrong)
                .foregroundStyle(Theme.Colors.Workout.ink)
                .contentTransition(.numericText())
                .monospacedDigit()
            if session.tracks.count > 1 {
                Text("the join")
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.Workout.inkTertiary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Time left")
        .accessibilityValue(CookClockCopy.spokenLeft(minutes: minutes, seconds: leadLine?.remaining(at: now)))
    }
}

// MARK: - The rail

/// The recipe laid on time: a vertical rail of minutes, each step a stroke (a second stroke beside it where a lane
/// opens), and a bead where he is. The lead bead breathes (x1.14, 2.4 s), once a ring leaves it when a timer ends;
/// the other holds still and dim, so there is one breath on the page. Reduce Motion and Low Power: nothing breathes,
/// the bead steps once a minute with a 150 ms fade.
struct ClockRail: View {
    let session: CookClockSession
    let calm: Bool
    let active: Bool

    var body: some View {
        let ends = session.timers.map(\.endsAt)
        ClockTick(ends: ends, calm: calm, active: active) { now in
            Canvas { context, size in
                draw(context: &context, size: size, now: now)
            }
        }
        .overlay { RingOverlay(session: session, calm: calm) }
        .drawingGroup(opaque: false)
    }

    private func draw(context: inout GraphicsContext, size: CGSize, now: Date) {
        let plan = session.plan
        guard plan.total > 0 else { return }
        let top: CGFloat = 6, height = size.height - 12
        func yAt(_ minute: Double) -> CGFloat {
            top + CGFloat(minute / plan.total) * height
        }
        let currentSteps = Set(session.tracks)
        for step in plan.steps {
            let x: CGFloat = step.lane == 0 ? 9 : 21
            var path = Path()
            path.move(to: CGPoint(x: x, y: yAt(step.start) + 1))
            path.addLine(to: CGPoint(x: x, y: max(yAt(step.end) - 1, yAt(step.start) + 2)))
            let isNow = currentSteps.contains(step.index)
            let past = step.index < (session.tracks.min() ?? 0) && !isNow
            let colour: Color = isNow ? Theme.Colors.Workout.signal
                : (past ? Theme.Colors.Workout.ink.opacity(0.55) : Theme.Colors.Workout.ink.opacity(0.22))
            context.stroke(path, with: .color(colour),
                           style: StrokeStyle(lineWidth: isNow ? 4 : 3, lineCap: .round,
                                              dash: step.isWait ? [2, 5] : []))
        }
        // Minute ticks every 15 minutes (hairlines, no numerals).
        var minute = 15.0
        while minute < plan.total {
            var tick = Path()
            tick.move(to: CGPoint(x: 0, y: yAt(minute)))
            tick.addLine(to: CGPoint(x: 4, y: yAt(minute)))
            context.stroke(tick, with: .color(Theme.Colors.Workout.hairline), lineWidth: 1)
            minute += 15
        }
        for index in session.tracks.indices {
            let step = plan.steps[session.tracks[index]]
            let minute = session.beadMinute(onTrack: index, at: now)
            let x: CGFloat = step.lane == 0 ? 9 : 21
            let isLead = index == session.lead
            let breathe = isLead && !calm ? 1 + 0.14 *
                (0.5 + 0.5 * sin(now.timeIntervalSinceReferenceDate * 2 * .pi / 2.4)) : 1
            let radius = 5.5 * breathe
            let rect = CGRect(x: x - radius, y: yAt(minute) - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect),
                         with: .color(isLead ? Theme.Colors.Workout.signal : Theme.Colors.Workout.ink.opacity(0.5)))
        }
    }
}

/// The timer-end ring: one ring leaves the lead bead and fades, played once, never looped (CCK item 58). None under
/// Reduce Motion or Low Power.
struct RingOverlay: View {
    let session: CookClockSession
    let calm: Bool

    var body: some View {
        let plan = session.plan
        GeometryReader { proxy in
            let step = plan.steps[session.current]
            let height = proxy.size.height - 12
            let y = 6 + CGFloat(step.start / max(plan.total, 1)) * height
            if !calm {
                Circle()
                    .stroke(Theme.Colors.Workout.signal, lineWidth: 1.5)
                    .frame(width: 11, height: 11)
                    .keyframeAnimator(initialValue: Ring(), trigger: session.rung.count) { circle, value in
                        circle.scaleEffect(value.scale).opacity(value.opacity)
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            LinearKeyframe(1, duration: 0)
                            LinearKeyframe(2.6, duration: 0.6, timingCurve: .easeOut)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(0.35, duration: 0)
                            LinearKeyframe(0, duration: 0.6, timingCurve: .easeOut)
                        }
                    }
                    .position(x: step.lane == 0 ? 9 : 21, y: y)
            }
        }
        .allowsHitTesting(false)
    }

    struct Ring {
        var scale = 1.0
        var opacity = 0.0
    }
}

// MARK: - Time-driven leaves

/// Redraws a leaf: 30 fps in normal motion (paused when the scene is inactive); in Reduce Motion and Low Power only at
/// the whole-minute boundaries of each `endsAt`, and every 10 s in the last minute. The page body never ticks.
struct ClockTick<Content: View>: View {
    let ends: [Date]
    let calm: Bool
    let active: Bool
    @ViewBuilder let content: (Date) -> Content

    var body: some View {
        if calm {
            // The schedule runs on real dates; the app clock may be shifted for a demo, so shift the list back.
            let shift = AppClock.now.timeIntervalSince(Date())
            let real = CookClockTimeline.dates(endsAt: ends, from: AppClock.now)
                .map { $0.addingTimeInterval(-shift) }
            TimelineView(.explicit(real)) { context in
                content(AppClock.adjust(context.date))
            }
        } else {
            LiveClock(LiveFeatures.cookClock, minimumInterval: 1.0 / 30, paused: !active) { context in
                content(AppClock.adjust(context.date))
            }
        }
    }
}

/// A horizon line from the top edge for each running timer (the lead's accent, the other's dimmer), burning down.
struct CookHorizons: View {
    let session: CookClockSession
    let calm: Bool
    let active: Bool

    var body: some View {
        let lines = session.trackTimers
        VStack(spacing: 5) {
            ForEach(lines) { line in
                ClockTick(ends: [line.endsAt], calm: calm, active: active) { now in
                    let fraction = line.isDone(at: now) ? 1.0 : line.remaining(at: now) / line.total
                    let lead = line.step == session.current
                    GeometryReader { proxy in
                        Capsule()
                            .fill(line.isDone(at: now) ? Theme.Colors.Workout.signal
                                : (lead ? Theme.Colors.Workout.signal : Theme.Colors.Workout.ink.opacity(0.45)))
                            .frame(width: max(2, proxy.size.width * fraction), height: lead ? 4 : 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 4)
                }
                .accessibilityHidden(true)
            }
        }
        .padding(.top, 2)
    }
}

/// A timer he spoke, on its own labelled line under the key row, outside the stroke ("Bread · 8 MIN").
struct SpokenTimerRow: View {
    let session: CookClockSession
    let line: CookClockSession.Line
    let calm: Bool
    let active: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ClockTick(ends: [line.endsAt], calm: calm, active: active) { now in
            let done = line.isDone(at: now)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                Text(CookClockCopy.line(line.label))
                    .textRole(.body)
                    .foregroundStyle(done ? Theme.Colors.Workout.signal : Theme.Colors.Workout.ink)
                Text("·").textRole(.label).foregroundStyle(Theme.Colors.Workout.inkTertiary)
                    .accessibilityHidden(true)
                if done {
                    Text("done").textRole(.label).foregroundStyle(Theme.Colors.Workout.signal)
                } else {
                    Text(
                        timerInterval: Date() ... max(Date(), line.realEnd),
                        pauseTime: nil,
                        countsDown: true,
                        showsHours: false
                    )
                    .textRole(.data)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.Workout.ink)
                    .accessibilityHidden(true)
                }
                Spacer()
            }
            .frame(minHeight: CookModeCopy.minTarget(accessibilitySize: typeSize.isAccessibilitySize) - 8)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(CookClockCopy.line(line.label)) timer")
            .accessibilityValue(CookClockCopy.spokenTimer(remaining: line.remaining(at: now), endsAt: line.endsAt))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: Text(CookClockCopy.stop)) { session.stop(line) }
            .rowSwipe(.trailing, arm: CGFloat(GestureTuning.armUndrawn)) { event in
                if case .committed = event {
                    session.stop(line)
                }
            }
            .onTapGesture {
                if done {
                    session.stop(line)
                }
            }
        }
    }
}

/// The ended timer's moment: its line flares, held until he stops it (tap it, or Stop). A band over the top of the
/// page, never the whole page, so the other timers stay drawn and counting. Normal: it slides back in 24 pt with the
/// blur 4 to 0; Reduce Motion and Low Power: a 150 ms crossfade.
struct FlareBand: View {
    let session: CookClockSession
    let calm: Bool

    var body: some View {
        let ended = session.timers.filter { session.flared.contains($0.id) }
        Group {
            if let line = ended.first(where: { $0.id == session.overlay }) ?? ended.first {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(CookModeCopy.timerDoneLine(line.label))
                            .textRole(.title)
                            .wordFit(CookModeCopy.timerDoneLine(line.label))
                            .foregroundStyle(Theme.Colors.Workout.signal)
                            .fixedSize(horizontal: false, vertical: true)
                        if ended.count > 1 {
                            Text("+\(ended.count - 1)")
                                .textRole(.label)
                                .foregroundStyle(Theme.Colors.Workout.inkSecondary)
                        }
                        Spacer()
                    }
                    HStack(spacing: Theme.Spacing.xl) {
                        Button(CookClockCopy.stop) { session.stop(line) }
                            .buttonStyle(.labelWord(Theme.Colors.Workout.signal))
                            .frame(minHeight: 44)
                            .accessibilityHint("Stops the alarm")
                        Button(CookClockCopy.more) { session.extend(line) }
                            .buttonStyle(.labelWord(Theme.Colors.Workout.ink))
                            .frame(minHeight: 44)
                    }
                }
                .padding(.vertical, Theme.Spacing.m)
                .background(Theme.Colors.Workout.ground.opacity(0.94))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("\(line.label) timer")
                .accessibilityValue("Done")
                .id(line.id)
                .transition(calm ? .opacity : .modifier(active: SlideBack(amount: 24, blur: 4), identity: SlideBack(
                    amount: 0, blur: 0
                )))
            }
        }
        .tesseraAnimation(calm ? .easeOut(duration: 0.15) : .smooth(duration: 0.42), value: ended.map(\.id))
    }

    struct SlideBack: ViewModifier {
        let amount: CGFloat
        let blur: CGFloat

        func body(content: Content) -> some View {
            content.offset(y: -amount).blur(radius: blur).opacity(amount == 0 ? 1 : 0)
        }
    }
}

// MARK: - Ingredients

/// The ingredients at this cook's size, 70% ink, in US units as written; a tap on an amount flips it to metric. Used
/// lines are not tracked here: the clock shows what the page scaled and nothing else.
struct IngredientPeek: View {
    let session: CookClockSession
    @Binding var metric: Bool
    let calm: Bool
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let book = RecipeBook(store: model.store, classes: model.classes)
        if let recipe = model.store.object(id: session.recipeID) {
            let lines = session.serves.map { book.scaledLines(of: recipe, serves: $0) } ?? book.lines(of: recipe)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(lines) { line in
                        let layout = typeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
                        layout {
                            Text(amount(line))
                                .textRole(.body)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .frame(width: typeSize.isAccessibilitySize ? nil : 96, alignment: .leading)
                            Text(session.isPrivate ? ShopTrip.privateLabel : line.line.name)
                                .textRole(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .foregroundStyle(Theme.Colors.Workout.ink.opacity(0.7))
                        .frame(minHeight: 44)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(session.isPrivate ? RecipeCopy.privateRow(amount(line))
                            : RecipeCopy.spokenRow(amount(line), line.line))
                        .accessibilityActions {
                            if line.line.metricText != nil {
                                Button(metric ? "Show in US units" : "Show in metric") { metric.toggle() }
                            }
                        }
                    }
                    if lines.contains(where: { $0.line.metricText != nil }) {
                        Button(metric ? "US units" : "Metric") {
                            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: calm) { metric.toggle() }
                        }
                        .buttonStyle(.labelWord(Theme.Colors.Workout.inkSecondary))
                        .frame(minHeight: 44)
                        .accessibilityLabel(metric ? "Show in US units" : "Show in metric")
                    }
                }
                .padding(.top, Theme.Spacing.m)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func amount(_ line: RecipeBook.Line) -> String {
        if metric, let text = line.line.metricText {
            return text
        }
        return line.line.quantityText ?? (line.line.toTaste ? "to taste" : "")
    }
}

// MARK: - Listening

/// The word that opens and shows the hands-free window: "Listen" at rest, "Listening" with a breathing hairline while
/// the mic is on (static under Reduce Motion and Low Power). No always-on ear: a tap opens it, 8 s of silence or
/// leaving the page closes it.
struct ListeningMark: View {
    let controller: HandsFreeController
    let calm: Bool
    @State private var breathe = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Button {
                Task { await controller.toggle() }
            } label: {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(controller.isOpen ? CookClockCopy.listening : CookClockCopy.listen)
                        .textRole(.label)
                        .foregroundStyle(controller.isOpen ? Theme.Colors.Workout.tess
                            : Theme.Colors.Workout.inkSecondary)
                    Rectangle()
                        .fill(Theme.Colors.Workout.tess)
                        .frame(width: 44 * (calm || !breathe ? 1 : 1.2), height: 1)
                        .opacity(controller.isOpen ? 1 : 0)
                }
                .frame(minWidth: 64, minHeight: 44, alignment: .trailing)
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityLabel(controller.isOpen ? CookClockCopy.listeningLabel : "Listen")
            .accessibilityHint(controller
                .isOpen ? "Stops listening" : "Opens a listening window for next, back and timer")
            if let heard = controller.heard {
                Text(heard)
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.Workout.tess)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            } else if let refusal = controller.refusal {
                Text(refusal.line)
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.Workout.inkSecondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .tesseraAnimation(.easeOut(duration: 0.15), value: controller.heard)
        .tesseraFeedback(controller.cue)
        .onAppear {
            guard !calm else { return }
            withTesseraAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), reduceMotion: calm) {
                breathe = true
            }
        }
    }
}
