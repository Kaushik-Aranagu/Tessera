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

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            let snapshot = WeatherSample.snapshot(now: AppClock.now)
            let cards = WeatherWords.cards(snapshot, alertOn: alertOn)
            LandingScaffold(title: "Lookout", accent: WeatherAccent.room, navWord: "Bridge", onBack: { dismiss() },
                            switcher: WeatherWords.switcher, switcherIndex: $switcherIndex,
                            switcherVerticalIndex: $switcherVerticalIndex,
                            needs: WeatherWords.needs(snapshot, switcher: switcherIndex),
                            keystone: { LookoutSkypiece(snapshot: snapshot) { openDoor(.hours) } },
                            caption: WeatherWords.briefForms(snapshot).map { $0.lead + $0.rest },
                            widget: cards.map(item), widgetIndex: $widgetIndex,
                            openWidget: { item in
                                let card = cards.first { $0.id == item.id }
                                openDoor(card?.opens == .week ? .week : .hours)
                            },
                            glyph: { item in
                                LandingGlyph(item: item, color: item.bigColor ?? WeatherAccent.room, room: .lookout)
                            },
                            doors: doors(snapshot), focus: $focus,
                            openDoor: { door in openDoor(WeatherDoor(rawValue: door.id) ?? .hours) },
                            action: action(snapshot),
                            backdrop: AnyView(LookoutSkyView(kind: snapshot.kind, now: snapshot.now)),
                            summaryStyle: .fog)
        }
        .overlay { LookoutDropHandover() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func item(_ card: LookoutCard) -> WidgetItem {
        WidgetItem(id: card.id, header: card.header, big: card.big, bigIsNumber: card.bigIsNumber, unit: card.unit,
                   middle: card.middle, small: card.small,
                   bigColor: card.wet ? Theme.Colors.Accent.rain : nil, strikeable: false)
    }

    private func doors(_ snapshot: WeatherSnapshot) -> [DialDoor] {
        let next = snapshot.hours.first
        let wet = Theme.Colors.Accent.rain
        return [
            DialDoor(id: "hours", name: "Hours", count: nil,
                     color: snapshot.kind.colour(night: snapshot.night),
                     label: next.map { _ in "Next hours" },
                     lines: WeatherWords.hourLines(snapshot)),
            DialDoor(id: "week", name: "Week", color: wet, label: "Days to note",
                     lines: WeatherWords.weekLines(snapshot)),
            DialDoor(id: "air", name: "Air", color: snapshot.air == "good" ? WeatherAccent.good : Theme.Colors.ink,
                     label: "Now", lines: WeatherWords.airLines(snapshot)),
        ]
    }

    /// Verb over object (283 v3): Alert (rain), then Hours and Walk across. Never "Rain alert" as one word.
    private func action(_ snapshot: WeatherSnapshot) -> LandingFootAction {
        LandingFootAction(word: "Alert", object: WeatherWords.alertObject(on: alertOn),
                          hint: alertOn ? "Turns the rain alert off" : "Tells you before rain",
                          alternates: [
                              .init(verb: "Hours", object: "Next 12 hours") { openDoor(.hours) },
                              .init(verb: "Walk", object: "Best time today") {
                                  TessVoice.shared.say(WeatherWords.walkLine(snapshot))
                              },
                          ]) {
            toggle()
        }
    }

    private func toggle() {
        let was = alertOn
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { alertOn = !was }
        WeatherRainAlert.set(!was)
        TessVoice.shared.say(WeatherRainAlert.receipt(on: !was), takeBack: {
            WeatherRainAlert.set(was)
            alertOn = was
        })
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

/// The keystone, the skypiece (253/254): the sky continues through a slab raised by light and shadow only (a caught
/// hairline top-left, a shade hairline bottom-right, a short and a soft shadow; no material, no blur, no tint). It
/// holds the temperature and the condition word in its sky's colour. Nothing in it moves.
struct LookoutSkypiece: View {
    let snapshot: WeatherSnapshot
    let open: () -> Void

    @Environment(\.colorScheme) private var scheme

    static let radius: CGFloat = 26
    /// The slot's top on the 402 x 874 frame (contract v3).
    static let top: CGFloat = 196

    var body: some View {
        let size = LandingKeystone<EmptyView>.size
        let dark = scheme == .dark
        let stops = LookoutSky.stops(kind: snapshot.kind, hour: LookoutSky.hour(snapshot.now), dark: dark)
        let shape = RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
        // The slab's fill is the page sky at the same place, so only the edge light and the shadows raise it.
        let start = UnitPoint(x: 0.5, y: -Self.top / size.height)
        let end = UnitPoint(x: 0.5, y: (LookoutSky.settle - Self.top) / size.height)
        Button(action: open) {
            content
                .padding(.horizontal, 24)
                .frame(width: size.width, height: size.height, alignment: .leading)
                .background {
                    shape
                        .fill(LinearGradient(colors: [Color(hex: stops.top), Color(hex: stops.bottom)],
                                             startPoint: start, endPoint: end))
                        .shadow(color: .black.opacity(dark ? 0.55 : 0.14), radius: 16, x: 0, y: 8)
                        .shadow(color: .black.opacity(dark ? 0.45 : 0.10), radius: 1.5, x: 1, y: 2)
                }
                .overlay {
                    shape
                        .strokeBorder(LinearGradient(stops: [
                            .init(color: .white.opacity(dark ? 0.32 : 0.85), location: 0),
                            .init(color: .white.opacity(0), location: 0.45),
                            .init(color: .black.opacity(0), location: 0.6),
                            .init(color: .black.opacity(dark ? 0.6 : 0.16), location: 1),
                        ], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2)
                }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(WeatherWords.name(snapshot.kind, night: snapshot.night)), \(snapshot.temperature) degrees"
        )
        .accessibilityHint("Opens the hours")
        .accessibilityIdentifier("weather.condition")
    }

    private var content: some View {
        let forms = WeatherWords.condition(snapshot.kind, night: snapshot.night)
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                (Text("\(snapshot.temperature)")
                    .font(.custom("Outfit", fixedSize: 88).weight(.ultraLight))
                    + Text("°").font(.custom("Outfit", fixedSize: 44).weight(.ultraLight)))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(height: 92, alignment: .leading)
                // The word wears its sky's colour only: the 236 word effects draw clipped layers that show as
                // boxes on the glass, so they stay off the skypiece until they are cut to the letters.
                word(Self.fitted(forms))
                    .fixedSize()
                    .foregroundStyle(snapshot.kind.colour(night: snapshot.night))
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                side("Feels", WeatherWords.degrees(snapshot.feelsLike))
                side("High", WeatherWords.degrees(snapshot.high))
                side("Low", WeatherWords.degrees(snapshot.low))
            }
        }
    }

    static let wordSize: CGFloat = 34
    /// The room the word has beside the Feels, High and Low column.
    static let wordWidth: CGFloat = 196

    /// The longest condition form that fits its slot at 34 pt (never smaller type, never "...").
    static func fitted(_ forms: [String]) -> String {
        let font = UIFont(name: "Figtree-Bold", size: wordSize) ?? .boldSystemFont(ofSize: wordSize)
        return forms.first { ($0 as NSString).size(withAttributes: [.font: font]).width <= wordWidth }
            ?? forms.last ?? ""
    }

    private func word(_ text: String) -> some View {
        Text(text)
            .font(.custom("Figtree", fixedSize: Self.wordSize).weight(.bold))
            .tracking(-0.01 * Self.wordSize)
            .lineLimit(1)
    }

    private func side(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(label)
                .font(.custom("Figtree", fixedSize: 13).weight(.semibold))
                .foregroundStyle(Theme.Colors.inkSecondary)
            Text(value)
                .font(.custom("Outfit", fixedSize: 20).weight(.light))
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.ink)
        }
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
            ForEach(Array(lines(snapshot).enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.custom("Figtree", size: 17, relativeTo: .body))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { ThemedBackground() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func lines(_ snapshot: WeatherSnapshot) -> [String] {
        switch door {
        case .hours:
            snapshot.hours.map { hour in
                let name = WeatherWords.name(hour.kind, night: false).lowercased()
                return "\(WeatherWords.hour(hour.date)) \(WeatherWords.degrees(hour.temperature)) \(name)"
            }
        case .week:
            snapshot.week.dropFirst().map { day in
                let calendar = Calendar.current
                let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: day.date) - 1]
                let name = WeatherWords.name(day.kind, night: false).lowercased()
                return "\(weekday) \(name), high \(WeatherWords.degrees(day.high)), low \(WeatherWords.degrees(day.low))"
            }
        case .air:
            WeatherWords.airLines(snapshot)
        }
    }
}
