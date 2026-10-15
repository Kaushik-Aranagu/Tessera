import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// MARK: Constants (spec: docs/design/live-activity.md, mockup docs/design/mockups/LiveRest.dc.html)

/// The extension can't see the app's Theme, so the painterly palette is pinned here.
private enum Palette {
    static let ground = Color(hex: 0x1C1828)
    /// Violet wash from the top left.
    static let violet = Color(hex: 0x3B2D57)
    /// Teal wash from the bottom right.
    static let teal = Color(hex: 0x1E3D4A)
    static let cream = Color(hex: 0xF3ECE0)
    static let secondary = Color(hex: 0xA79FB5)
    /// Rest: cadmium.
    static let cadmium = Color(hex: 0xE8BD4C)
    /// Live / ready: vermilion.
    static let vermilion = Color(hex: 0xD9563F)
    static let glint = Color(hex: 0xFFE2A8)
}

/// Fraunces and Hanken Grotesk aren't bundled yet: same fallback as the app (system serif / system sans). Swap here.
private enum Typeface {
    /// Fraunces, tabular figures.
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif).monospacedDigit()
    }

    /// Fraunces italic.
    static func italic(_ size: CGFloat) -> Font {
        .system(size: size, design: .serif).italic()
    }

    /// Hanken Grotesk.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

private enum Metric {
    static let doneKey = CGSize(width: 112, height: 52)
    static let doneKeyIsland = CGSize(width: 104, height: 50)
    static let doneRadius: CGFloat = 14
    static let ghostKey = CGSize(width: 64, height: 40)
    static let ghostRadius: CGFloat = 12
    static let strokeHeight: CGFloat = 7
    /// Set false to fall back to a plain rounded-rect drain if the brush mask doesn't render.
    static let brushMask = true
}

private let workoutURL = URL(string: "tessera://workout")

// MARK: Widget

struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            RestLockScreenView(context: context)
                .activityBackgroundTint(Palette.ground.opacity(0.92))
                .activitySystemActionForegroundColor(Palette.cream)
                .widgetURL(workoutURL)
        } dynamicIsland: { context in
            let state = context.state
            let ready = RestFace.isReady(context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RestFace.headline(state, ready: ready, size: 44)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    DoneKey(ready: ready, size: Metric.doneKeyIsland)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !ready {
                            DryingStroke(state: state)
                        }
                        HStack(alignment: .center) {
                            RestFace.nextSet(state)
                            Spacer(minLength: 8)
                            if !ready {
                                GhostKey(title: "Skip", intent: SkipRestIntent())
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                PaintDab(ready: ready)
            } compactTrailing: {
                if ready {
                    Text("Set \(state.setNumber)")
                        .font(Typeface.display(18))
                        .foregroundStyle(Palette.vermilion)
                } else {
                    RestFace.countdown(state)
                        .font(Typeface.display(18))
                        .frame(maxWidth: 52)
                }
            } minimal: {
                PaintDab(ready: ready)
            }
            .keylineTint(ready ? Palette.vermilion : Palette.cadmium)
            .widgetURL(workoutURL)
        }
    }
}

// MARK: Lock Screen

private struct RestLockScreenView: View {
    let context: ActivityViewContext<RestActivityAttributes>

    var body: some View {
        let state = context.state
        let ready = RestFace.isReady(context)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                RestFace.headline(state, ready: ready, size: 52)
                    .padding(.top, 4)
                Spacer(minLength: 8)
                DoneKey(ready: ready, size: Metric.doneKey)
            }
            Spacer(minLength: 0)
            if ready {
                VStack(alignment: .leading, spacing: 2) {
                    RestFace.nextSet(state)
                    Text("rested \(Duration.seconds(state.restTotal).formatted(.time(pattern: .minuteSecond)))")
                        .font(Typeface.italic(18))
                        .foregroundStyle(Palette.secondary)
                }
            } else {
                DryingStroke(state: state)
                Spacer(minLength: 0)
                HStack(alignment: .center, spacing: 8) {
                    RestFace.nextSet(state)
                    Spacer(minLength: 8)
                    GhostKey(title: "+15s", intent: ExtendRestIntent())
                    GhostKey(title: "Skip", intent: SkipRestIntent())
                }
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 14)
        .padding(.vertical, 14)
        .frame(height: 156)
        .background { PainterlyGround() }
    }
}

/// The workout's painterly ground, machined only at the edge, with the lit process seam on top.
private struct PainterlyGround: View {
    var body: some View {
        ZStack(alignment: .top) {
            Palette.ground.opacity(0.92)
            RadialGradient(colors: [Palette.violet.opacity(0.95), .clear], center: .topLeading, startRadius: 0,
                           endRadius: 280)
            RadialGradient(colors: [Palette.teal.opacity(0.95), .clear], center: .bottomTrailing, startRadius: 0,
                           endRadius: 260)
            // Inner top chamfer.
            Rectangle().fill(.white.opacity(0.14)).frame(height: 1).padding(.top, 2)
            // The lit 2pt vermilion process seam, with its glint.
            Rectangle()
                .fill(LinearGradient(stops: [
                    .init(color: Palette.vermilion, location: 0.4),
                    .init(color: Palette.glint, location: 0.5),
                    .init(color: Palette.vermilion, location: 0.6),
                ], startPoint: .leading, endPoint: .trailing))
                .frame(height: 2)
                .shadow(color: Palette.vermilion.opacity(0.6), radius: 6)
        }
        .overlay { ContainerRelativeShape().strokeBorder(.black.opacity(0.6), lineWidth: 0.5) }
    }
}

// MARK: Pieces

private enum RestFace {
    /// The content goes stale when the rest runs out, so the face flips to ready even if the app is suspended.
    static func isReady(_ context: ActivityViewContext<RestActivityAttributes>) -> Bool {
        context.state.phase == .ready || context.isStale
    }

    /// Resting: "2:30 rest". Ready: "Set 4 is up".
    @ViewBuilder
    static func headline(_ state: RestActivityAttributes.ContentState, ready: Bool, size: CGFloat) -> some View {
        if ready {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Set \(state.setNumber)")
                    .font(Typeface.display(size))
                    .foregroundStyle(Palette.cream)
                Text("is up")
                    .font(Typeface.italic(18))
                    .foregroundStyle(Palette.cadmium)
            }
            .lineLimit(1)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                countdown(state)
                    .font(Typeface.display(size))
                    // Timer text claims all the width it can; pin it to the width of "m:ss".
                    .frame(width: size * 2.2, alignment: .leading)
                Text("rest")
                    .font(Typeface.italic(18))
                    .foregroundStyle(Palette.secondary)
            }
            .lineLimit(1)
        }
    }

    static func countdown(_ state: RestActivityAttributes.ContentState) -> some View {
        Text(timerInterval: state.restInterval, countsDown: true)
            .monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .foregroundStyle(Palette.cadmium)
            .minimumScaleFactor(0.7)
    }

    /// "Bench, 82.5 × 8".
    static func nextSet(_ state: RestActivityAttributes.ContentState) -> some View {
        Text("\(state.exercise), \(state.plannedSet)")
            .font(Typeface.italic(21))
            .foregroundStyle(Palette.cream)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

/// The drying stroke: a 7pt cadmium brushstroke that shortens from the right as rest runs out, over a 2pt guide at
/// the full length. The system animates `ProgressView(timerInterval:)`, so it dries even while the app is suspended.
private struct DryingStroke: View {
    let state: RestActivityAttributes.ContentState

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Palette.cream.opacity(0.14))
                .frame(height: 2)
            drain
        }
        .frame(height: Metric.strokeHeight)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var drain: some View {
        let bar = ProgressView(timerInterval: state.restInterval, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(Palette.cadmium)
        // Stretch the system bar past the stroke's height and ends, so only its fill shows through the shape.
        .scaleEffect(x: 1, y: 3)
        .padding(.horizontal, -6)
        .frame(height: Metric.strokeHeight)
        if Metric.brushMask {
            bar.mask { BrushStroke() }
        } else {
            bar.clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }
}

/// A dry-brush stroke: slightly uneven edges with a blunt loaded start and a feathered tail.
private struct BrushStroke: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width, height = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 1, y: rect.minY + height * 0.18))
        path.addCurve(to: CGPoint(x: rect.minX + width * 0.5, y: rect.minY + height * 0.05),
                      control1: CGPoint(x: width * 0.18, y: rect.minY - height * 0.05),
                      control2: CGPoint(x: width * 0.34, y: rect.minY + height * 0.16))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + height * 0.3),
                      control1: CGPoint(x: width * 0.7, y: rect.minY - height * 0.06),
                      control2: CGPoint(x: width * 0.92, y: rect.minY + height * 0.1))
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.maxY - height * 0.25))
        path.addCurve(to: CGPoint(x: rect.minX + width * 0.45, y: rect.maxY - height * 0.04),
                      control1: CGPoint(x: width * 0.8, y: rect.maxY + height * 0.02),
                      control2: CGPoint(x: width * 0.62, y: rect.maxY - height * 0.14))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.maxY - height * 0.12),
                      control1: CGPoint(x: width * 0.26, y: rect.maxY + height * 0.06),
                      control2: CGPoint(x: width * 0.08, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The cadmium paint dab (compact leading and minimal); vermilion once the set is up.
private struct PaintDab: View {
    let ready: Bool

    var body: some View {
        let color = ready ? Palette.vermilion : Palette.cadmium
        Ellipse()
            .fill(RadialGradient(colors: [color, color.opacity(0.3)], center: .center, startRadius: 0,
                                 endRadius: 9))
            .frame(width: 18, height: 16)
            .rotationEffect(.degrees(-12))
            .blur(radius: 1.4)
            .accessibilityLabel(ready ? "Set is up" : "Resting")
    }
}

/// Done: cream key; glows vermilion once the set is up.
private struct DoneKey: View {
    let ready: Bool
    let size: CGSize

    var body: some View {
        Button(intent: LogPlannedSetIntent()) {
            Text("Done")
        }
        .buttonStyle(KeyStyle(radius: Metric.doneRadius, size: size, fill: Palette.cream, ink: Palette.ground,
                              font: Typeface.body(21, weight: .semibold), outline: nil))
        .shadow(color: ready ? Palette.vermilion.opacity(0.55) : .clear, radius: 11)
    }
}

/// A hairline key (+15s, Skip).
private struct GhostKey<Intent: AppIntent>: View {
    let title: LocalizedStringKey
    let intent: Intent

    var body: some View {
        Button(intent: intent) {
            Text(title)
        }
        .buttonStyle(KeyStyle(radius: Metric.ghostRadius, size: Metric.ghostKey, fill: .clear, ink: Palette.cream,
                              font: Typeface.body(18, weight: .medium), outline: Palette.cream.opacity(0.32)))
    }
}

/// A small-radius slab, never a capsule: inner top highlight on filled keys, 0.5pt black hairline, or a 1pt outline.
private struct KeyStyle: ButtonStyle {
    let radius: CGFloat
    let size: CGSize
    let fill: Color
    let ink: Color
    let font: Font
    let outline: Color?

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        configuration.label
            .font(font)
            .foregroundStyle(ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(width: size.width, height: size.height)
            .background(fill, in: shape)
            .overlay {
                if let outline {
                    shape.strokeBorder(outline, lineWidth: 1)
                } else {
                    shape.strokeBorder(.black.opacity(0.6), lineWidth: 0.5)
                    Rectangle().fill(.white.opacity(0.7)).frame(height: 1).padding(.horizontal, radius)
                        .frame(maxHeight: .infinity, alignment: .top).padding(.top, 0.5)
                }
            }
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.75 : 1)
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
