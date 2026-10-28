import ActivityKit
import SwiftUI
import WidgetKit

// Surfaces v2 (Design 142): the Live Activities in each app's signature. Training's face is the rest face with set
// marks
// (it replaces the old Lock Screen face only when the app sets `setsTotal`, which it does only while the Review switch
// is
// On). Cook and Routine are new activities the app starts only while the switch is On.

private let ink = Color(red: 0xF6 / 255, green: 0xEF / 255, blue: 0xE4 / 255)

// MARK: Training: set marks with the rest countdown

struct TrainingMarksFace: View {
    @Environment(\.restPalette) private var palette
    let state: RestActivityAttributes.ContentState
    let isGo: Bool

    var body: some View {
        let accent = SurfaceStyle.accentOnDark("training")
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(state.showsSet ? state.exercise : "Private workout")
                        .font(SurfaceType.words(18, .medium, relativeTo: .headline))
                        .foregroundStyle(palette.cream)
                    if state.showsSet, let total = state.setsTotal {
                        SetMarksRow(done: state.setsDone ?? 0, total: total, accent: accent, inkColor: palette.cream)
                        Text(isGo ? "Set \(state.setNumber) is next" : "Rest, then set \(state.setNumber)")
                            .font(SurfaceType.words(14, .regular, relativeTo: .subheadline))
                            .foregroundStyle(palette.cream.opacity(0.62))
                    } else {
                        Text(isGo ? "Rest is over" : "Rest")
                            .font(SurfaceType.words(14, .regular, relativeTo: .subheadline))
                            .foregroundStyle(palette.cream.opacity(0.62))
                    }
                }
                Spacer(minLength: 0)
                Group {
                    if isGo {
                        Text("Go").font(SurfaceType.words(44, .light, relativeTo: .largeTitle))
                    } else {
                        Text(timerInterval: state.restInterval, countsDown: true)
                            .font(SurfaceType.numerals(48, relativeTo: .largeTitle))
                            .frame(width: 48 * 2.4, alignment: .trailing)
                    }
                }
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            BottomKeys(isGo: isGo)
                .frame(height: 34)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityElement(children: .contain)
    }
}

/// One mark per planned set: done filled, the next one ringed, the rest faint.
struct SetMarksRow: View {
    let done: Int
    let total: Int
    let accent: Color
    let inkColor: Color

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Array(SurfaceMarks.marks(done: done, total: total).enumerated()), id: \.offset) { _, mark in
                switch mark {
                case .done: Circle().fill(accent).frame(width: 12, height: 12)
                case .current: Circle().strokeBorder(accent, lineWidth: 2).frame(width: 12, height: 12)
                case .todo: Circle().strokeBorder(inkColor.opacity(0.28), lineWidth: 1.5).frame(width: 12, height: 12)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(min(done, total)) of \(total) sets done")
    }
}

// MARK: Cook: the soonest timer, "+2", the next step

struct CookLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookActivityAttributes.self) { context in
            Group {
                if context.state.isReady {
                    CookReadyLockScreen(state: context.state)
                } else {
                    CookLockScreen(recipe: context.attributes.recipeName, state: context.state)
                }
            }
            .activityBackgroundTint(Color(red: 0x12 / 255, green: 0x0E / 255, blue: 0x1A / 255).opacity(0.9))
            .activitySystemActionForegroundColor(ink)
            .widgetURL(context.state.link ?? URL(string: "tessera://cook"))
        } dynamicIsland: { context in
            let accent = SurfaceStyle.accentOnDark("kitchen")
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if let food = state.readyFood {
                        // A timer hit zero: "Chicken ready" in wine mixed toward white, swelling once.
                        CookReadyWord(text: CookFace.readyWord(food: food), trigger: food)
                            .padding(.leading, 8)
                    } else {
                        Text(timerInterval: state.interval, countsDown: true)
                            .font(SurfaceType.numerals(40, relativeTo: .largeTitle))
                            .foregroundStyle(accent)
                            .frame(width: 100, alignment: .leading)
                            .padding(.leading, 8)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if state.isReady, let end = state.nextInterval {
                        Text(timerInterval: end, countsDown: true)
                            .font(SurfaceType.numerals(24, .regular, relativeTo: .title2))
                            .foregroundStyle(accent)
                            .frame(maxWidth: 80, alignment: .trailing)
                            .padding(.trailing, 8)
                    } else if let plus = state.plusWord {
                        Text(plus)
                            .font(SurfaceType.numerals(24, .regular, relativeTo: .title2))
                            .foregroundStyle(accent)
                            .padding(.trailing, 8)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.timerLabel)
                            .font(SurfaceType.words(15, .medium, relativeTo: .subheadline))
                        if let step = state.nextStep {
                            Text(step)
                                .font(SurfaceType.words(14, .regular, relativeTo: .footnote))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                if let plus = state.plusWord {
                    Text(plus).font(SurfaceType.numerals(15, .regular, relativeTo: .footnote)).foregroundStyle(accent)
                } else {
                    Image(systemName: "timer").foregroundStyle(accent)
                }
            } compactTrailing: {
                if state.isReady {
                    Text("Ready").font(SurfaceType.words(14, .medium, relativeTo: .footnote)).foregroundStyle(CookReady.wine)
                } else {
                    Text(timerInterval: state.interval, countsDown: true)
                        .font(SurfaceType.numerals(15, .regular, relativeTo: .footnote))
                        .foregroundStyle(accent)
                        .frame(maxWidth: 48)
                }
            } minimal: {
                Image(systemName: "timer").foregroundStyle(state.isReady ? CookReady.wine : accent)
            }
            .keylineTint(accent)
        }
    }
}

/// Sheet 344's ready colour: wine mixed 45% toward white.
private enum CookReady {
    static let wine: Color = {
        let mixed = CookFace.readyWine
        return Color(red: Double(mixed.red) / 255, green: Double(mixed.green) / 255, blue: Double(mixed.blue) / 255)
    }()
}

/// "Chicken ready", which swells once (1.08 across by 1.14 up, 520 ms) each time the food changes. Reduce Motion: it
/// just appears.
private struct CookReadyWord: View {
    let text: String
    let trigger: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let word = Text(text)
            .font(SurfaceType.words(22, .medium, relativeTo: .title3))
            .foregroundStyle(CookReady.wine)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        if CookFace.swells(reduceMotion: reduceMotion) {
            word.phaseAnimator([0.0, 1.0, 0.0], trigger: trigger) { content, phase in
                content.scaleEffect(x: 1 + (CookFace.swell.x - 1) * phase, y: 1 + (CookFace.swell.y - 1) * phase)
            } animation: { _ in
                .easeInOut(duration: CookFace.swell.duration / 2)
            }
        } else {
            word
        }
    }
}

/// "READY, OFF THE HEAT", the food big, and the next timer on the right ("5:58, onions to go").
private struct CookReadyLockScreen: View {
    let state: CookActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(CookFace.readyLine)
                .font(SurfaceType.words(14, .medium, relativeTo: .caption))
                .tracking(1.2)
                .foregroundStyle(CookReady.wine)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(state.readyFood ?? "")
                    .font(SurfaceType.words(44, .medium, relativeTo: .largeTitle))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: 8)
                if let end = state.nextInterval {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(timerInterval: end, countsDown: true)
                            .font(SurfaceType.numerals(24, .regular, relativeTo: .title2))
                            .frame(maxWidth: 70, alignment: .trailing)
                        if let label = state.nextLabel {
                            Text(", \(label)").font(SurfaceType.words(15, .regular, relativeTo: .subheadline))
                        }
                    }
                    .foregroundStyle(ink.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .accessibilityElement(children: .combine)
    }
}

private struct CookLockScreen: View {
    let recipe: String
    let state: CookActivityAttributes.ContentState

    var body: some View {
        let accent = SurfaceStyle.accentOnDark("kitchen")
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(timerInterval: state.interval, countsDown: true)
                    .font(SurfaceType.numerals(52, relativeTo: .largeTitle))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 52 * 2.4, alignment: .leading)
                if let plus = state.plusWord {
                    Text(plus)
                        .font(SurfaceType.numerals(26, .regular, relativeTo: .title2))
                        .foregroundStyle(accent)
                        .accessibilityLabel("\(state.others) other timers")
                }
                Spacer(minLength: 0)
            }
            Text("\(state.timerLabel), \(recipe)")
                .font(SurfaceType.words(15, .medium, relativeTo: .subheadline))
                .foregroundStyle(ink.opacity(0.7))
            if let step = state.nextStep {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next")
                        .font(SurfaceType.words(12, .medium, relativeTo: .caption))
                        .foregroundStyle(ink.opacity(0.55))
                    Text(step)
                        .font(SurfaceType.words(17, .regular, relativeTo: .body))
                        .foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
}

// MARK: Routine: the step with the Thread

struct RoutineLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoutineActivityAttributes.self) { context in
            RoutineLockScreen(name: context.attributes.routineName, state: context.state)
                .activityBackgroundTint(Color(red: 0x12 / 255, green: 0x0E / 255, blue: 0x1A / 255).opacity(0.9))
                .activitySystemActionForegroundColor(ink)
                .widgetURL(URL(string: "tessera://routine"))
        } dynamicIsland: { context in
            let accent = SurfaceStyle.accentOnDark("routines")
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(state.step)
                        .font(SurfaceType.words(20, .medium, relativeTo: .title3))
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(state.position) of \(state.count)")
                        .font(SurfaceType.numerals(17, .regular, relativeTo: .body))
                        .foregroundStyle(accent)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ThreadRow(position: state.position, count: state.count, accent: accent, inkColor: ink)
                        .padding(.horizontal, 8)
                }
            } compactLeading: {
                Text("\(state.position)")
                    .font(SurfaceType.numerals(15, .regular, relativeTo: .footnote))
                    .foregroundStyle(accent)
            } compactTrailing: {
                Text(timerInterval: state.startedAt ... .distantFuture, countsDown: false)
                    .font(SurfaceType.numerals(15, .regular, relativeTo: .footnote))
                    .frame(maxWidth: 48)
            } minimal: {
                Text("\(state.position)")
                    .font(SurfaceType.numerals(15, .regular, relativeTo: .footnote))
                    .foregroundStyle(accent)
            }
            .keylineTint(accent)
        }
    }
}

private struct RoutineLockScreen: View {
    let name: String
    let state: RoutineActivityAttributes.ContentState

    var body: some View {
        let accent = SurfaceStyle.accentOnDark("routines")
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(SurfaceType.words(14, .medium, relativeTo: .subheadline))
                .foregroundStyle(accent)
            Text(state.step)
                .font(SurfaceType.words(26, .medium, relativeTo: .title2))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
            ThreadRow(position: state.position, count: state.count, accent: accent, inkColor: ink)
            Text("Step \(state.position) of \(state.count)")
                .font(SurfaceType.numerals(15, .regular, relativeTo: .subheadline))
                .foregroundStyle(ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
}

/// The Thread: one bead per step on a rose line; the steps behind him are filled, the one he is on is larger.
struct ThreadRow: View {
    let position: Int
    let count: Int
    let accent: Color
    let inkColor: Color

    var body: some View {
        let beads = min(max(count, 1), 12)
        let on = min(max(position, 1), beads)
        ZStack(alignment: .leading) {
            Rectangle().fill(accent.opacity(0.5)).frame(height: 1.5)
            HStack(spacing: 0) {
                ForEach(1 ... beads, id: \.self) { index in
                    Circle()
                        .fill(index <= on ? accent : inkColor.opacity(0.25))
                        .frame(width: index == on ? 14 : 8, height: index == on ? 14 : 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }
}
