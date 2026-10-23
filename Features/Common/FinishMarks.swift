import Observation
import SwiftUI
import TesseraCore

// Design 139, finishing: each app ends a piece of work with its own small flourish and one line. The drawing lives
// here; the words are `FinishWords`. Everything is behind the Review switch "Finishing marks" (`FinishWords.isOn`),
// and nothing here runs with it Off.

// MARK: - The moment

/// What just finished, handed from the place that finished it to the screen that shows the flourish. One value for
/// the whole app: the workout's finish records it, the Training week row and the Routines Thread read it once.
@MainActor @Observable
final class FinishMoment {
    static let shared = FinishMoment()

    struct Finished: Equatable, Identifiable {
        let id = UUID()
        let at: Date
        /// Logged sets in the session (one brush circle each).
        let setCount: Int
        let minutes: Int
        /// Tess's Training line, already worded (private names masked).
        let trainingLine: String
        /// The routine the workout was made from, when there is one.
        let routineID: UUID?
    }

    /// How long a finish stays worth showing when its screen opens after it.
    nonisolated static let freshFor: TimeInterval = 300

    private(set) var finished: Finished?
    /// The ids each flourish has already played, so none plays twice.
    private var played: Set<String> = []

    /// Records a finished session (call only with the switch On).
    func record(name: String, privateLabel: String?, setCount: Int, duration: TimeInterval, routineID: UUID?) {
        let minutes = FinishWords.minutes(of: duration)
        finished = Finished(
            at: Date(), setCount: setCount, minutes: minutes,
            trainingLine: FinishWords.trainingLine(name: name, privateLabel: privateLabel, minutes: minutes),
            routineID: routineID
        )
    }

    /// The finish, while it is still fresh.
    var current: Finished? {
        guard let finished, Date().timeIntervalSince(finished.at) < Self.freshFor else { return nil }
        return finished
    }

    /// True once per (finish, flourish): the first caller plays, later ones see it already drawn.
    func claim(_ flourish: String) -> Finished? {
        guard let current, played.insert("\(current.id)-\(flourish)").inserted else { return nil }
        return current
    }

    func hasPlayed(_ flourish: String) -> Bool {
        guard let current else { return false }
        return played.contains("\(current.id)-\(flourish)")
    }
}

// MARK: - Training: the sets gather into today

/// Today's mark in the week row (24 pt). When a session has just finished, its set marks (small brush circles, one
/// per logged set) gather into the open wet ring, which closes into a finished ring, wet at first and then drying
/// to ink, with one rigid haptic as it closes. Reduce Motion: no gather; the ring crossfades closed.
struct FinishingTodayMark: View {
    let side: CGFloat
    let open: SetMarkSpec
    let closed: SetMarkSpec

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0 open and wet, 1 closed and wet, 2 closed and dried.
    @State private var stage = 0
    @State private var gathered = false
    @State private var playing = false
    @State private var rigid = 0

    private static let flourish = "training"
    private static let maxShown = 14

    var body: some View {
        ZStack {
            ring(open, age: 0, visible: stage == 0)
            ring(closed, age: 0, visible: stage == 1)
            ring(closed, age: 99, visible: stage == 2)
            if playing, !reduceMotion {
                ForEach(0 ..< Self.shown(setCount), id: \.self) { index in
                    SetMarkCircle(spec: closed, side: 14, age: 99)
                        .offset(gathered ? .zero : Self.start(index, of: Self.shown(setCount)))
                        .scaleEffect(gathered ? 0.3 : 1)
                        .opacity(gathered ? 0 : 0.9)
                        .tesseraAnimation(.timingCurve(0.5, 0, 0.2, 1, duration: 0.75).delay(Double(index) * 0.02),
                                          value: gathered)
                }
            }
        }
        .frame(width: side, height: side)
        .tesseraFeedback(trigger: rigid) { _, new in new > 0 ? .setLogged : nil }
        .task { await play() }
    }

    private var setCount: Int {
        FinishMoment.shared.current?.setCount ?? 0
    }

    private static func shown(_ count: Int) -> Int {
        min(max(count, 1), maxShown)
    }

    private func ring(_ spec: SetMarkSpec, age: Double, visible: Bool) -> some View {
        SetMarkCircle(spec: spec, side: side, age: age)
            .opacity(visible ? 1 : 0)
            .tesseraAnimation(Theme.Motion.house, value: visible)
    }

    /// Where a gathering mark starts: spread on an arc below the row, reading left to right in the order logged.
    static func start(_ index: Int, of total: Int) -> CGSize {
        let spread = Double(index) / Double(max(total - 1, 1))
        let angle = (0.15 + 0.7 * spread) * .pi
        return CGSize(width: -cos(angle) * 78, height: sin(angle) * 64 + 18)
    }

    private func play() async {
        guard FinishWords.isOn else {
            stage = FinishMoment.shared.hasPlayed(Self.flourish) ? 2 : 0
            return
        }
        guard FinishMoment.shared.claim(Self.flourish) != nil else {
            stage = FinishMoment.shared.hasPlayed(Self.flourish) ? 2 : 0
            return
        }
        playing = true
        if !reduceMotion {
            try? await Task.sleep(for: .milliseconds(250))
            withTesseraAnimation(reduceMotion: reduceMotion) { gathered = true }
            try? await Task.sleep(for: .milliseconds(900))
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { stage = 1 }
        rigid += 1
        try? await Task.sleep(for: .milliseconds(500))
        withTesseraAnimation(Theme.Motion.dry(reduceMotion: reduceMotion) ?? .easeOut(duration: 0.15),
                             reduceMotion: reduceMotion) { stage = 2 }
        playing = false
    }
}

// MARK: - Routines: the Thread ties a loop

/// A 14 pt loop in rose that draws itself and dries to the Thread's ink.
struct FinishLoop: View {
    static let side: CGFloat = 14

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn: CGFloat = 0
    @State private var dried = false

    var body: some View {
        LoopShape()
            .trim(from: 0, to: reduceMotion ? 1 : drawn)
            .stroke(dried ? Theme.Colors.ink.opacity(0.6) : Theme.Colors.Accent.routines,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .frame(width: Self.side, height: Self.side)
            .opacity(reduceMotion && drawn == 0 ? 0 : 1)
            .accessibilityHidden(true)
            .task {
                withTesseraAnimation(.easeOut(duration: 0.45), reduceMotion: reduceMotion) { drawn = 1 }
                try? await Task.sleep(for: .milliseconds(450))
                withTesseraAnimation(Theme.Motion.dry(reduceMotion: reduceMotion) ?? .easeOut(duration: 0.15),
                                     reduceMotion: reduceMotion) { dried = true }
            }
    }
}

/// One turn and a little over, ending where a knot would tie: the tail crosses its own start.
private struct LoopShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 1
        path.addArc(center: centre, radius: radius, startAngle: .degrees(-100), endAngle: .degrees(270),
                    clockwise: false)
        return path
    }
}

/// Wraps a Routines Thread line: when that routine has just finished, the Thread ties a loop at its stitch and two
/// short lines hang under it ("Morning, 22 min." and "Tomorrow, usually 6:40 am."). Hook:
/// `.modifier(FinishRoutineLines(routineID:name:isPrivate:usualStartMinuteOfDay:))`.
struct FinishRoutineLines: ViewModifier {
    let routineID: UUID
    /// The name as the room may see it (already "Private routine" when walled).
    let name: String
    let isPrivate: Bool
    /// Core's usual start for the routine; nil before seven runs, so the second line is left out.
    let usualStartMinuteOfDay: Int?

    @State private var finished: FinishMoment.Finished?

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            content
                .overlay(alignment: .topLeading) {
                    if finished != nil {
                        FinishLoop()
                            .offset(x: -ThreadMetrics.inset + 0.75 - FinishLoop.side / 2, y: 5)
                    }
                }
            if let finished {
                VStack(alignment: .leading, spacing: 2) {
                    Text(FinishWords.routineLine(name: name, privateLabel: isPrivate ? name : nil,
                                                 minutes: finished.minutes))
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.ink)
                    if let tomorrow = FinishWords.tomorrowLine(usualStartMinuteOfDay: usualStartMinuteOfDay) {
                        Text(tomorrow)
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)
                .accessibilityElement(children: .combine)
            }
        }
        .tesseraAnimation(Theme.Motion.house, value: finished)
        .task {
            guard FinishWords.isOn, let current = FinishMoment.shared.current, current.routineID == routineID,
                  FinishMoment.shared.claim("routine-\(routineID)") != nil else { return }
            finished = current
        }
    }
}

// MARK: - Kitchen: the spine draws into the serve rule

/// The end of a cook: the cook spine (a vertical line down the left) draws down and turns into the serve rule, then
/// "Served at 7:02 pm." writes in ochre and dries to ink. Hook, one line, where the cook ends:
/// `CookServeRule(servedAt: AppClock.now)` (not wired in: the cook page leaves the moment it finishes).
struct CookServeRule: View {
    let servedAt: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn: CGFloat = 0
    @State private var worded = false
    @State private var dried = false

    private static let height: CGFloat = 44

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpineIntoRule()
                .trim(from: 0, to: reduceMotion ? 1 : drawn)
                .stroke(Theme.Colors.ink.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .opacity(reduceMotion && drawn == 0 ? 0 : 1)
                .accessibilityHidden(true)
            Text(FinishWords.servedLine(at: servedAt))
                .textRole(.body)
                .foregroundStyle(dried ? Theme.Colors.ink : Theme.Colors.Accent.kitchen)
                .opacity(worded ? 1 : 0)
                .padding(.leading, Theme.Spacing.m)
                .padding(.top, Self.height + Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(FinishWords.servedLine(at: servedAt))
        .task {
            withTesseraAnimation(.easeOut(duration: 0.45), reduceMotion: reduceMotion) { drawn = 1 }
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 450))
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { worded = true }
            withTesseraAnimation(Theme.Motion.dry(reduceMotion: reduceMotion) ?? .easeOut(duration: 0.15),
                                 reduceMotion: reduceMotion) { dried = true }
        }
    }
}

/// Down the left, then a turn along the bottom: the spine becomes the rule.
private struct SpineIntoRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.75, y: 0))
        path.addLine(to: CGPoint(x: 0.75, y: 44))
        path.addLine(to: CGPoint(x: rect.maxX, y: 44))
        return path
    }
}
