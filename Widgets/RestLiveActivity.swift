import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// MARK: Constants (spec: docs/design/live-activity.md, mockup docs/design/mockups/LiveFinal.dc.html)

/// The extension can't see the app's Theme, so the palette is pinned here.
private enum Palette {
    static let cream = Color(hex: 0xF6EFE4)
    static let vermilion = Color(hex: 0xE2603F)
    /// Under the system material, as in the mockup (rgba(18,14,26,.46)).
    static let materialTint = Color(hex: 0x120E1A).opacity(0.46)
    /// Go: the sky warms to cadmium and vermilion.
    static let goWash1 = Color(hex: 0xE8BD4C).opacity(0.75)
    static let goWash2 = Color(hex: 0xE2603F).opacity(0.6)
}

/// Colour moods. Kaushik hasn't picked yet; Cobalt sky is the default.
enum RestMood {
    case cobaltSky, dusk, sage, ink

    static let current: RestMood = .cobaltSky

    /// Top-left wash.
    var wash1: Color {
        switch self {
        case .cobaltSky: Color(hex: 0x3F7FC0).opacity(0.75)
        case .dusk: Color(hex: 0xE2603F).opacity(0.7)
        case .sage: Color(hex: 0x6E9E6A).opacity(0.75)
        case .ink: .clear
        }
    }

    /// Top-right wash.
    var wash2: Color {
        switch self {
        case .cobaltSky: Color(hex: 0x7A5CA0).opacity(0.45)
        case .dusk: Color(hex: 0x965096).opacity(0.55)
        case .sage: Color(hex: 0x2A7F86).opacity(0.6)
        case .ink: .clear
        }
    }

    var line: Color {
        switch self {
        case .cobaltSky, .ink: Palette.cream
        case .dusk: Color(hex: 0xFFB896)
        case .sage: Color(hex: 0xC8E6B4)
        }
    }

    var tick: Color {
        self == .dusk ? Color(hex: 0xFFE3D2) : Palette.vermilion
    }
}

/// Inter Tight, bundled in the extension (Widgets/Fonts, `UIAppFonts`). If the font file is missing, `.custom`
/// falls back to the system font, so the layout still holds.
private enum Typeface {
    static let family = "Inter Tight"

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(family, fixedSize: size).weight(weight)
    }

    /// The countdown: Light (wght 250 is between .ultraLight and .light; .light is the nearest named weight).
    static func numerals(_ size: CGFloat) -> Font {
        font(size, .light).monospacedDigit()
    }
}

private enum Metric {
    /// The right column (the Done button) starts here on the Lock Screen.
    static let rightColumn: CGFloat = 160
    static let lineWidth: CGFloat = 2.5
    static let guideWidth: CGFloat = 1.5
    static let lineHeight: CGFloat = 12
    /// Set false for a straight 2.5pt line if the curved mask doesn't render.
    static let curvedLine = true
}

private let workoutURL = URL(string: "tessera://workout")

// MARK: Widget

struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            RestLockScreenView(state: context.state, isGo: RestFace.isGoTime(context))
                .activityBackgroundTint(Palette.materialTint)
                .activitySystemActionForegroundColor(Palette.cream)
                .widgetURL(workoutURL)
        } dynamicIsland: { context in
            let state = context.state
            let isGo = RestFace.isGoTime(context)
            let mood = RestMood.current
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Countdown(state: state, isGo: isGo, size: 40)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    PlannedSetButton(state: state, isGo: isGo, nameSize: 16, setSize: 21)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HorizonLine(state: state, isGo: isGo, color: mood.line)
                        .padding(.horizontal, 8)
                        .padding(.top, 6)
                }
            } compactLeading: {
                Tick(color: mood.tick)
                    .frame(width: 18, height: 14)
            } compactTrailing: {
                Group {
                    if isGo {
                        Text("Go")
                    } else {
                        Text(timerInterval: state.restInterval, countsDown: true)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .font(Typeface.font(17).monospacedDigit())
                .foregroundStyle(Palette.cream)
                .frame(maxWidth: 48)
            } minimal: {
                Tick(color: mood.tick)
                    .frame(width: 16, height: 13)
            }
            .keylineTint(isGo ? Palette.vermilion : mood.wash1)
            .widgetURL(workoutURL)
        }
    }
}

// MARK: Lock Screen

private struct RestLockScreenView: View {
    let state: RestActivityAttributes.ContentState
    let isGo: Bool
    private let mood = RestMood.current

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Countdown(state: state, isGo: isGo, size: 48)
                    .padding(.leading, 22)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Rectangle()
                    .fill(Palette.cream.opacity(0.16))
                    .frame(width: 1, height: 60)
                PlannedSetButton(state: state, isGo: isGo, nameSize: 17, setSize: 24)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .frame(width: Metric.rightColumn)
            }
            .padding(.top, 14)
            HorizonLine(state: state, isGo: isGo, color: mood.line)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            HStack(spacing: 0) {
                Group {
                    if isGo {
                        Text("Rested \(Duration.seconds(state.restTotal).formatted(.time(pattern: .minuteSecond)))")
                    } else {
                        Text("Rest, then set \(state.setNumber)")
                    }
                }
                .font(Typeface.font(17))
                .foregroundStyle(Palette.cream.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.leading, 22)
                .frame(maxWidth: .infinity, alignment: .leading)
                BottomKeys(isGo: isGo)
                    .frame(width: Metric.rightColumn)
            }
            .frame(height: 34)
            .padding(.bottom, 8)
        }
        .frame(height: 150)
        .background { Washes(isGo: isGo, mood: mood) }
    }
}

/// Two soft blurred washes inside the system material, top left and top right. Go warms them.
private struct Washes: View {
    let isGo: Bool
    let mood: RestMood

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Ellipse()
                    .fill(RadialGradient(colors: [isGo ? Palette.goWash1 : mood.wash1, .clear], center: .center,
                                         startRadius: 0, endRadius: 135))
                    .frame(width: 270, height: 150)
                    .offset(x: -40, y: -60)
                    .blur(radius: 8)
                Ellipse()
                    .fill(RadialGradient(colors: [isGo ? Palette.goWash2 : mood.wash2, .clear], center: .center,
                                         startRadius: 0, endRadius: 110))
                    .frame(width: 220, height: 130)
                    .offset(x: proxy.size.width - 170, y: -40)
                    .blur(radius: 10)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: Pieces

private enum RestFace {
    /// The content goes stale at the rest end (`staleDate`), so the face turns to Go even if the app is suspended.
    static func isGoTime(_ context: ActivityViewContext<RestActivityAttributes>) -> Bool {
        context.state.phase == .ready || context.isStale
    }
}

/// The countdown (cream, Light, tabular), or "Go" pushing in from below. Always-On shows a still "Ready at 18:26".
private struct Countdown: View {
    let state: RestActivityAttributes.ContentState
    let isGo: Bool
    let size: CGFloat
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        Group {
            if isGo {
                Text("Go")
                    .font(Typeface.font(size, .light))
                    .transition(.push(from: .bottom))
            } else if isLuminanceReduced {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Ready at")
                        .font(Typeface.font(17))
                        .foregroundStyle(Palette.cream.opacity(0.62))
                    Text(state.restEndsAt, format: .dateTime.hour().minute())
                        .font(Typeface.numerals(size * 0.75))
                }
            } else {
                Text(timerInterval: state.restInterval, countsDown: true)
                    .font(Typeface.numerals(size))
                    .contentTransition(.numericText(countsDown: true))
                    // Timer text claims all the width it can; pin it to the width of "m:ss".
                    .frame(width: size * 2.4, alignment: .leading)
            }
        }
        .tracking(-size * 0.02)
        .foregroundStyle(Palette.cream)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .id(isGo)
    }
}

/// The planned set is the Done button: tapping it logs the set, like hold to log.
private struct PlannedSetButton: View {
    let state: RestActivityAttributes.ContentState
    let isGo: Bool
    let nameSize: CGFloat
    let setSize: CGFloat

    var body: some View {
        Button(intent: LogPlannedSetIntent()) {
            VStack(alignment: .leading, spacing: 3) {
                Text(state.exercise)
                    .font(Typeface.font(nameSize))
                    .foregroundStyle(Palette.cream.opacity(0.62))
                    .padding(.trailing, 26)
                Text(state.plannedSet)
                    .font(Typeface.font(setSize).monospacedDigit())
                    .tracking(-setSize * 0.01)
                    .foregroundStyle(Palette.cream)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                ZStack {
                    if isGo {
                        // "Tap the set": a soft vermilion glow behind the tick.
                        Ellipse()
                            .fill(RadialGradient(colors: [Palette.vermilion.opacity(0.55), .clear], center: .center,
                                                 startRadius: 0, endRadius: 22))
                            .frame(width: 44, height: 40)
                    }
                    Tick(color: RestMood.current.tick, lineWidth: isGo ? 3 : 2.6)
                        .frame(width: 22, height: 18)
                }
                .offset(y: 4)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log \(state.exercise), \(state.plannedSet)")
    }
}

/// "+15" | "Skip", split by a hairline. Once rest is over +15 dims and Skip skips the set.
private struct BottomKeys: View {
    let isGo: Bool

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if isGo {
                    Text("+15").opacity(0.25)
                } else {
                    Button(intent: ExtendRestIntent()) { label("+15") }
                }
            }
            .frame(maxWidth: .infinity)
            Rectangle()
                .fill(Palette.cream.opacity(0.16))
                .frame(width: 1, height: 18)
            Group {
                if isGo {
                    Button(intent: SkipSetIntent()) { label("Skip") }
                } else {
                    Button(intent: SkipRestIntent()) { label("Skip") }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .font(Typeface.font(18, .medium))
        .foregroundStyle(Palette.cream)
        .buttonStyle(.plain)
    }

    private func label(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
    }
}

/// The horizon line: a cream stroke over a full-width 1.5pt guide that drains toward the left as rest runs out.
/// The system animates `ProgressView(timerInterval:)`, so it drains even while the app is suspended.
private struct HorizonLine: View {
    let state: RestActivityAttributes.ContentState
    let isGo: Bool
    let color: Color

    var body: some View {
        ZStack {
            guide
            if !isGo {
                drain
            }
        }
        .frame(height: Metric.lineHeight)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var guide: some View {
        if Metric.curvedLine {
            HorizonCurve()
                .stroke(Palette.cream.opacity(0.14), style: StrokeStyle(lineWidth: Metric.guideWidth, lineCap: .round))
        } else {
            Rectangle().fill(Palette.cream.opacity(0.14)).frame(height: Metric.guideWidth)
        }
    }

    @ViewBuilder
    private var drain: some View {
        let bar = ProgressView(timerInterval: state.restInterval, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(color)
        // Stretch the system bar over the curve's height so only the masked stroke shows.
        .scaleEffect(x: 1, y: 4)
        .frame(height: Metric.lineHeight)
        if Metric.curvedLine {
            bar.mask {
                HorizonCurve().stroke(style: StrokeStyle(lineWidth: Metric.lineWidth, lineCap: .round))
            }
        } else {
            bar.mask { Rectangle().frame(height: Metric.lineWidth) }
        }
    }
}

/// The mockup's horizon: M2 6 C 90 3, 200 9, 332 5 in a 334 × 12 box.
private struct HorizonCurve: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 334, scaleY = rect.height / 12
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }
        var path = Path()
        path.move(to: point(2, 6))
        path.addCurve(to: point(332, 5), control1: point(90, 3), control2: point(200, 9))
        return path
    }
}

/// The red brush tick: M2 11 C 6 13, 8 16, 10 18 C 14 10, 19 5, 24 2 in a 26 × 20 box.
private struct Tick: View {
    let color: Color
    var lineWidth: CGFloat = 2.6

    var body: some View {
        TickShape()
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .accessibilityHidden(true)
    }
}

private struct TickShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 26, scaleY = rect.height / 20
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }
        var path = Path()
        path.move(to: point(2, 11))
        path.addCurve(to: point(10, 18), control1: point(6, 13), control2: point(8, 16))
        path.addCurve(to: point(24, 2), control1: point(14, 10), control2: point(19, 5))
        return path
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

#Preview("Lock Screen", as: .content, using: RestActivityAttributes(workoutTitle: "Push A")) {
    RestLiveActivity()
} contentStates: {
    RestActivityAttributes.ContentState(exercise: "Bench", setNumber: 4, weight: 82.5, reps: 8,
                                        restEndsAt: .now.addingTimeInterval(95), restTotal: 150, phase: .resting)
    RestActivityAttributes.ContentState(exercise: "Bench", setNumber: 4, weight: 82.5, reps: 8,
                                        restEndsAt: .distantPast, restTotal: 150, phase: .ready)
}

#Preview("Island", as: .dynamicIsland(.expanded), using: RestActivityAttributes(workoutTitle: "Push A")) {
    RestLiveActivity()
} contentStates: {
    RestActivityAttributes.ContentState(exercise: "Bench", setNumber: 4, weight: 82.5, reps: 8,
                                        restEndsAt: .now.addingTimeInterval(95), restTotal: 150, phase: .resting)
}
