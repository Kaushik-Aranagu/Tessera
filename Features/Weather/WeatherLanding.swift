import SwiftUI
import UIKit

/// Lookout, the Weather landing on the sheet 283 scaffold: the page is a drawn sky, the keystone is the skypiece
/// (glass raised by light and shadow), Hours, Week and Air on the dial, "Rain alert" at the foot. Never a city.
/// Entry: `-weatherLanding` on the simulator (there is no Weather room in the app yet).
struct WeatherLandingView: View {
    @State private var door: WeatherDoor?

    var body: some View {
        NavigationStack {
            WeatherLandingPage(openDoor: { door = $0 })
                .navigationDestination(item: $door) { WeatherDoorPage(door: $0) }
        }
    }
}

enum WeatherDoor: String, Hashable, Identifiable, CaseIterable {
    case hours, week, air

    var id: String {
        rawValue
    }

    var name: String {
        switch self {
        case .hours: "Hours"
        case .week: "Week"
        case .air: "Air"
        }
    }
}

enum WeatherAccent {
    static let room = Color(light: 0xC9772E, dark: 0xE8A06A)
    /// "Good" air in go green (241's done green).
    static let good = Color(light: 0x25803D, dark: 0x8FC9A0)
}

struct WeatherLandingPage: View {
    let openDoor: (WeatherDoor) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus = 0
    @State private var switcherIndex = 0
    @State private var switcherVerticalIndex = 0
    @State private var widgetIndex = 0
    @State private var alertOn = WeatherRainAlert.isOn()
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            let facts = LookoutRoomContent.Facts(snapshot: WeatherSample.snapshot(now: AppClock.now), alertOn: alertOn)
            let snapshot = facts.snapshot
            let plate = LookoutPlate.pick(kind: snapshot.kind, at: snapshot.now, dark: scheme == .dark)
            LandingScaffold(title: "Lookout", accent: WeatherAccent.room, navWord: "Bridge", onBack: { dismiss() },
                            switcher: WeatherWords.switcher, switcherIndex: $switcherIndex,
                            switcherVerticalIndex: $switcherVerticalIndex,
                            needs: facts.needs(switcherIndex),
                            keystone: { LookoutSkypiece(snapshot: snapshot) { openDoor(.hours) } },
                            caption: facts.caption,
                            widget: facts.widget, widgetIndex: $widgetIndex,
                            openWidget: { item in openDoor(facts.door(forItem: item.id)) },
                            glyph: { item in
                                LandingGlyph(item: item, color: item.bigColor ?? WeatherAccent.room, room: .lookout)
                            },
                            doors: facts.doors, focus: $focus,
                            openDoor: { door in openDoor(WeatherDoor(rawValue: door.id) ?? .hours) },
                            action: action(facts),
                            backdrop: AnyView(LookoutPlateView(plate: plate, fallback: AnyView(
                                LookoutSkyView(kind: snapshot.kind, now: snapshot.now)
                            ))),
                            summaryStyle: .fog)
                // The text colour comes from the plate (256): light ink on a dark plate, dark ink on a bright one.
                // The house inks follow the scheme, so the page wears the plate's scheme.
                .environment(\.colorScheme, plate.lightInk ? .dark : .light)
        }
        .overlay { LookoutDropHandover() }
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Verb over object (283 v3), from the shared steps: Alert (rain), then Hours and Walk across.
    private func action(_ facts: LookoutRoomContent.Facts) -> LandingFootAction {
        let steps = facts.steps
        return LandingFootAction(word: steps[0].verb, object: steps[0].object,
                                 hint: alertOn ? "Turns the rain alert off" : "Tells you before rain",
                                 alternates: [
                                     .init(verb: steps[1].verb, object: steps[1].object) { openDoor(.hours) },
                                     .init(verb: steps[2].verb, object: steps[2].object) {
                                         LookoutActions.walk(facts.snapshot)
                                     },
                                 ]) {
            LookoutActions.toggleAlert { on in
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { alertOn = on }
            }
        }
    }
}

/// The page's sky (256, drawn until the photo plates land): the hour's and the condition's two colours, settling by
/// 520 pt and holding below. It is the page itself, not a panel.
struct LookoutSkyView: View {
    let kind: WeatherKind
    let now: Date
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { proxy in
            let stops = LookoutSky.stops(kind: kind, hour: LookoutSky.hour(now), dark: scheme == .dark)
            let settle = min(1, LookoutSky.settle / max(proxy.size.height, 1))
            LinearGradient(stops: [.init(color: Color(hex: stops.top), location: 0),
                                   .init(color: Color(hex: stops.bottom), location: settle),
                                   .init(color: Color(hex: stops.bottom), location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
        .accessibilityHidden(true)
    }
}

/// The keystone, the skypiece (253/254, board r66): raised glass over the plate, made of light and shadow only (a
/// caught light top-left, two shadows bottom-right, a hairline; no material, no blur, no fill), so the sky shows
/// through untouched. Inside: the temperature, the condition with feels and high, and three live stats. The shadows
/// stop at the slot's foot, so none runs under the caption.
struct LookoutSkypiece: View {
    let snapshot: WeatherSnapshot
    let open: () -> Void

    @Environment(\.colorScheme) private var scheme

    static let radius: CGFloat = 26
    /// How far below the glass a shadow may reach: the caption starts 10 pt under the slot.
    static let shadowFoot: CGFloat = 6

    var body: some View {
        let size = LandingKeystone<EmptyView>.size
        let shape = RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
        Button(action: open) {
            content(size)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .background { LookoutGlass(shape: shape, onDark: scheme == .dark, foot: Self.shadowFoot) }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(WeatherWords.name(snapshot.kind, night: snapshot.night)), \(snapshot.temperature) degrees"
        )
        .accessibilityHint("Opens the hours")
        .accessibilityIdentifier("weather.condition")
    }

    private func content(_ size: CGSize) -> some View {
        let forms = WeatherWords.condition(snapshot.kind, night: snapshot.night)
        return ZStack(alignment: .topLeading) {
            (Text("\(snapshot.temperature)")
                .font(.custom("Outfit", fixedSize: 112).weight(.ultraLight))
                + Text("°").font(.custom("Outfit", fixedSize: 44).weight(.ultraLight))
                // Raised to the numeral's cap line, as on the board.
                .baselineOffset(46))
                .tracking(-0.03 * 112)
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize()
                .offset(x: 18, y: -4)
            VStack(alignment: .trailing, spacing: 4) {
                Text(Self.fitted(forms))
                    .font(.custom("Figtree", fixedSize: Self.wordSize).weight(.semibold))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                    .fixedSize()
                Text(Self.feels(snapshot))
                    .font(.custom("Outfit", fixedSize: 15).weight(.light))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(width: size.width - 24, alignment: .trailing)
            .offset(y: 28)
            HStack(alignment: .bottom) {
                ForEach(Array(Self.stats(snapshot).enumerated()), id: \.offset) { index, stat in
                    if index > 0 {
                        Spacer(minLength: 8)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stat.value)
                            .font(.custom("Outfit", fixedSize: 22).weight(.light))
                            .monospacedDigit()
                            .foregroundStyle(Theme.Colors.ink)
                        Text(stat.label.uppercased())
                            .font(.custom("Figtree", fixedSize: 10.5).weight(.medium))
                            .tracking(0.06 * 10.5)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                    .lineLimit(1)
                    .fixedSize()
                }
            }
            .frame(width: size.width - 48)
            .offset(x: 24, y: size.height - 18 - 40)
        }
    }

    static let wordSize: CGFloat = 22
    /// The room the condition has at the top right, beside the temperature.
    static let wordWidth: CGFloat = 170

    /// The longest condition form that fits its slot (never smaller type, never "...").
    static func fitted(_ forms: [String]) -> String {
        let font = UIFont(name: "Figtree-SemiBold", size: wordSize) ?? .boldSystemFont(ofSize: wordSize)
        return forms.first { ($0 as NSString).size(withAttributes: [.font: font]).width <= wordWidth }
            ?? forms.last ?? ""
    }

    /// "feels like 79°, high 81°" (board r66).
    static func feels(_ snapshot: WeatherSnapshot) -> String {
        "feels like \(WeatherWords.degrees(snapshot.feelsLike)), high \(WeatherWords.degrees(snapshot.high))"
    }

    /// The glass's three live stats: wind, when rain starts (else tonight's low) and the UV index.
    static func stats(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> [(value: String, label: String)] {
        let wind = (String(snapshot.wind), WeatherWords.windUnit(snapshot.fahrenheit))
        let middle: (String, String) = if let wet = snapshot.hours.first(where: { WeatherWords.isWet($0.kind) }) {
            (WeatherWords.hour(wet.date, calendar: calendar), "rain from")
        } else {
            (WeatherWords.degrees(snapshot.low), "low")
        }
        return [wind, middle, (String(snapshot.uvIndex), "uv index")]
    }
}

/// The glass's light and shadow, drawn outside the shape only: the inside is cut away so the sky stays untouched.
/// The shadows end `foot` points under the glass, fading out, so they never reach the caption.
struct LookoutGlass: View {
    let shape: RoundedRectangle
    let onDark: Bool
    let foot: CGFloat

    private static let reach: CGFloat = 30

    var body: some View {
        let reach = Self.reach
        let insets = EdgeInsets(top: reach, leading: reach, bottom: foot, trailing: reach)
        ZStack {
            shape.fill(.black).shadow(color: .white.opacity(onDark ? 0.22 : 0.38), radius: 7, x: -4, y: -4)
            shape.fill(.black).shadow(color: .black.opacity(onDark ? 0.36 : 0.24), radius: 10, x: 5, y: 4)
            shape.fill(.black).shadow(color: .black.opacity(onDark ? 0.16 : 0.09), radius: 17, x: 2, y: 6)
        }
        .padding(insets)
        .mask {
            VStack(spacing: 0) {
                Rectangle()
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: foot)
            }
            .overlay { shape.padding(insets).blendMode(.destinationOut) }
            .compositingGroup()
        }
        .padding(EdgeInsets(top: -reach, leading: -reach, bottom: -foot, trailing: -reach))
        .overlay {
            shape.strokeBorder(LinearGradient(stops: [
                .init(color: .white.opacity(onDark ? 0.18 : 0.3), location: 0),
                .init(color: .white.opacity(0), location: 0.5),
                .init(color: .black.opacity(onDark ? 0.14 : 0.08), location: 1),
            ], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The keystone hands the widget its item on arrival (283 v3): 26 drops fall from the skypiece glass onto the
/// widget, once, about 1.4 s. Reduce Motion: nothing falls. Never takes a touch.
struct LookoutDropHandover: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now
    @State private var done = false

    static let count = 26
    static let length: TimeInterval = 1.4

    var body: some View {
        if !reduceMotion, !done {
            GeometryReader { proxy in
                let scale = max(0.86, min(1.1, proxy.size.height / 874))
                TimelineView(.animation(minimumInterval: 1 / 60)) { context in
                    let elapsed = context.date.timeIntervalSince(start)
                    Canvas { canvas, size in
                        Self.draw(&canvas, width: size.width, scale: scale, elapsed: elapsed)
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                start = .now
                try? await Task.sleep(for: .seconds(Self.length + 0.4))
                done = true
            }
        }
    }

    /// Each drop leaves the glass's lower edge (y about 360) a little after the last, falls with gravity's ease-in
    /// and lands on the widget's top (y about 440), fading as it lands.
    static func draw(_ canvas: inout GraphicsContext, width: CGFloat, scale: CGFloat, elapsed: TimeInterval) {
        let left = (width - 354) / 2 + 12
        for index in 0 ..< count {
            let seed = Double((index * 37) % count) / Double(count)
            let delay = seed * 0.6
            let fall = (elapsed - delay) / 0.8
            guard fall > 0, fall < 1 else { continue }
            let x = left + CGFloat((Double(index) + 0.5) / Double(count)) * 330 + CGFloat(sin(Double(index) * 2.3)) * 4
            let y = (352 + CGFloat(fall * fall) * 96) * scale
            var drop = Path()
            drop.move(to: CGPoint(x: x, y: y))
            drop.addLine(to: CGPoint(x: x - 1.5, y: y + 7))
            canvas.stroke(drop, with: .color(Theme.Colors.Accent.rain.opacity(1 - fall * fall)),
                          style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
    }
}

/// A door's page: the title, then plain lines (the room's first cut; sheet 243's day page follows the room).
struct WeatherDoorPage: View {
    let door: WeatherDoor
    @Environment(\.dismiss) private var dismiss
    @State private var detail: LookoutDetail?

    var body: some View {
        let snapshot = WeatherSample.snapshot(now: AppClock.now)
        VStack(alignment: .leading, spacing: 12) {
            Button("Lookout") { dismiss() }
                .font(.custom("Figtree", size: 17, relativeTo: .body))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(minHeight: 44)
                .buttonStyle(.plain)
            Text(door.name)
                .font(.custom("Figtree", size: 34, relativeTo: .largeTitle).weight(.bold))
                .foregroundStyle(WeatherAccent.room)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(lines(snapshot).enumerated()), id: \.offset) { index, line in
                // A row opens what it names: the hour, the day or the air (the same detail as the shell's rows).
                Button {
                    detail = LookoutRoomContent.Facts(snapshot: snapshot).detail(forRow: "\(door.rawValue).\(index)")
                } label: {
                    FitLine(forms: FitLine.cuts(line), size: 17, color: Theme.Colors.ink)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens it")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { ThemedBackground() }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $detail) { LookoutDetailPage(detail: $0) }
    }

    private func lines(_ snapshot: WeatherSnapshot) -> [String] {
        LookoutRoomContent.Facts(snapshot: snapshot).lines(door)
    }
}
