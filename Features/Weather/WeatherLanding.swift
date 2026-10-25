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
                                LookoutCloudGlyph(wet: cards.first { $0.id == item.id }?.wet ?? false)
                            },
                            doors: doors(snapshot), focus: $focus,
                            openDoor: { door in openDoor(WeatherDoor(rawValue: door.id) ?? .hours) },
                            action: action,
                            backdrop: AnyView(LookoutSkyView(kind: snapshot.kind, now: snapshot.now)))
        }
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

    private var action: LandingFootAction {
        LandingFootAction(word: "Rain alert", hint: alertOn ? "Turns the rain alert off" : "Tells you before rain") {
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

/// The widget glyph (283): a cloud drifting with rain falling under it. It moves once on arrival and every 7 s for
/// 1.6 s; at rest it holds one calm pose. Reduce Motion: the pose only.
struct LookoutCloudGlyph: View {
    let wet: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var burst = Date.distantPast

    private static let length: TimeInterval = 1.6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            let elapsed = context.date.timeIntervalSince(burst)
            let progress = elapsed >= 0 && elapsed < Self.length ? elapsed / Self.length : 0
            Canvas { canvas, size in draw(&canvas, size: size, progress: progress) }
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                burst = .now
                try? await Task.sleep(for: .seconds(7))
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(_ canvas: inout GraphicsContext, size: CGSize, progress: Double) {
        // The drift eases out and back (a sine over the burst), never linear.
        let drift = CGFloat(sin(progress * .pi)) * 6
        let cloud = Path { path in
            let x = size.width * 0.18 + drift
            let y = size.height * 0.22
            path.addEllipse(in: CGRect(x: x, y: y + 10, width: 30, height: 22))
            path.addEllipse(in: CGRect(x: x + 14, y: y, width: 30, height: 30))
            path.addEllipse(in: CGRect(x: x + 30, y: y + 8, width: 26, height: 24))
            path.addRoundedRect(
                in: CGRect(x: x + 6, y: y + 18, width: 46, height: 14),
                cornerSize: CGSize(width: 7, height: 7)
            )
        }
        canvas.fill(cloud, with: .color(Theme.Colors.inkSecondary.opacity(0.55)))
        guard wet else { return }
        for index in 0 ..< 5 {
            let column = size.width * 0.26 + CGFloat(index) * 8 + drift * 0.6
            let fall = (progress * 2 + Double(index) * 0.21).truncatingRemainder(dividingBy: 1)
            let y = size.height * 0.62 + CGFloat(fall) * 18
            var drop = Path()
            drop.move(to: CGPoint(x: column, y: y))
            drop.addLine(to: CGPoint(x: column - 2, y: y + 8))
            canvas.stroke(
                drop,
                with: .color(Theme.Colors.Accent.rain),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
            )
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
