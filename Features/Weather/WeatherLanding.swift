import SwiftUI

/// The Weather landing on the shared kit (243, landing contract): the condition word with its weather effect in the
/// keystone slot, Hours, Week and Air on the dial, one line at 612, "Rain alert" at the foot. Never a city.
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
    @State private var alertOn = WeatherRainAlert.isOn()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            let snapshot = WeatherSample.snapshot(now: AppClock.now)
            LandingFrame(title: "Weather", accent: WeatherAccent.room, stateLine: WeatherWords.stateLine(snapshot),
                         keystone: {
                             LandingKeystone(label: "The sky now") {
                                 WeatherKeystone(snapshot: snapshot) { openDoor(.hours) }
                             }
                         },
                         doors: doors(snapshot), focus: $focus,
                         openDoor: { door in openDoor(WeatherDoor(rawValue: door.id) ?? .hours) },
                         brief: { brief(snapshot) },
                         action: action,
                         onBack: { dismiss() })
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func doors(_ snapshot: WeatherSnapshot) -> [DialDoor] {
        let next = snapshot.hours.first
        let wet = Theme.Colors.Accent.rain
        return [
            DialDoor(id: "hours", name: "Hours", count: nil,
                     color: snapshot.kind.colour(night: snapshot.night),
                     label: next.map { "From \(WeatherWords.hour($0.date))" },
                     lines: WeatherWords.hourLines(snapshot)),
            DialDoor(id: "week", name: "Week", color: wet, label: "Days to note",
                     lines: WeatherWords.weekLines(snapshot)),
            DialDoor(id: "air", name: "Air", color: snapshot.air == "good" ? WeatherAccent.good : Theme.Colors.ink,
                     label: "Now", lines: WeatherWords.airLines(snapshot)),
        ]
    }

    private func brief(_ snapshot: WeatherSnapshot) -> some View {
        let line = WeatherWords.brief(snapshot)
        return (Text(line.lead).fontWeight(.semibold).foregroundStyle(Theme.Colors.ink) + Text(line.rest))
            .font(.custom("Figtree", size: 15, relativeTo: .callout))
            .foregroundStyle(Theme.Colors.inkSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityLabel(line.lead + line.rest)
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

/// The keystone: the temperature in Outfit and the condition word in its sky's colour, wearing its weather (236
/// v2.4-2.8). Reduce Motion: the word keeps its colour and nothing moves. A tap opens the hours.
struct WeatherKeystone: View {
    let snapshot: WeatherSnapshot
    let open: () -> Void

    var body: some View {
        let forms = WeatherWords.condition(snapshot.kind, night: snapshot.night)
        Button(action: open) {
            VStack(alignment: .leading, spacing: 0) {
                (Text("\(snapshot.temperature)")
                    .font(.custom("Outfit", fixedSize: 96).weight(.ultraLight))
                    + Text("°").font(.custom("Outfit", fixedSize: 48).weight(.ultraLight)))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(height: 96, alignment: .leading)
                ViewThatFits(in: .horizontal) {
                    ForEach(forms, id: \.self) { form in word(form).fixedSize() }
                    word(forms.last ?? "").lineLimit(1).minimumScaleFactor(0.75)
                }
                .weatherWord(snapshot.kind, night: snapshot.night)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(forms[0]), \(snapshot.temperature) degrees")
        .accessibilityHint("Opens the hours")
        .accessibilityIdentifier("weather.condition")
    }

    private func word(_ text: String) -> some View {
        Text(text)
            .font(.custom("Figtree", fixedSize: 64).weight(.bold))
            .tracking(-0.01 * 64)
    }
}

/// A door's page: the title, then plain lines (the room's first cut; sheet 243's day page follows the room).
struct WeatherDoorPage: View {
    let door: WeatherDoor
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let snapshot = WeatherSample.snapshot(now: AppClock.now)
        VStack(alignment: .leading, spacing: 12) {
            Button("Weather") { dismiss() }
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
