import SwiftUI

/// Lookout (Weather) as content for the standing shell (sheet 283 v5): level 0 is the landing, the same content as
/// `WeatherLandingPage` (both read `Facts`, the one source); level 1 is a door page (Hours, Week, Air), the Door title
/// and a Page of its lines. The skypiece is a scene keystone ("lookout.sky") the host draws over the plate, so it is
/// untouched when a door opens. Never a city. Pure: no views.
struct LookoutRoomContent: RoomContent {
    static let room = "lookout"

    /// Everything Lookout says, from one snapshot; the scaffold landing and the shell both use it.
    struct Facts: Equatable {
        var snapshot: WeatherSnapshot
        var alertOn = false

        var cards: [LookoutCard] {
            WeatherWords.cards(snapshot, alertOn: alertOn)
        }

        var widget: [WidgetItem] {
            cards.map { card in
                WidgetItem(id: card.id, header: card.header, big: card.big, bigIsNumber: card.bigIsNumber,
                           unit: card.unit, middle: card.middle, small: card.small,
                           bigColor: card.wet ? Theme.Colors.Accent.rain : nil, strikeable: false)
            }
        }

        /// Which door a widget item opens.
        func door(forItem id: String) -> WeatherDoor {
            cards.first { $0.id == id }?.opens == .week ? .week : .hours
        }

        var doors: [DialDoor] {
            [
                // The fact line sits in the summary's label (a text count beside the dial's name hung the shell's
                // landing on the simulator, so Lookout's dial names stand alone).
                DialDoor(id: "hours", name: "Hours", count: nil,
                         color: snapshot.kind.colour(night: snapshot.night),
                         label: snapshot.hours.first
                             .map { _ in "Now \(WeatherWords.degrees(snapshot.temperature)), next hours" },
                         lines: WeatherWords.hourLines(snapshot)),
                DialDoor(id: "week", name: "Week", color: Theme.Colors.Accent.rain,
                         label: WeatherWords.weekLines(snapshot).isEmpty ? "A steady week" : "Days to note",
                         lines: WeatherWords.weekLines(snapshot)),
                DialDoor(id: "air", name: "Air",
                         color: snapshot.air == "good" ? WeatherAccent.good : Theme.Colors.ink,
                         label: "Air, sun and wind now", lines: WeatherWords.airLines(snapshot)),
            ]
        }

        var caption: [String] {
            WeatherWords.briefForms(snapshot).map { $0.lead + $0.rest }
        }

        func needs(_ switcher: Int) -> [String] {
            WeatherWords.needs(snapshot, switcher: switcher)
        }

        /// Verb over object (283 v3): Alert (rain), then Hours and Walk across.
        var steps: [ShellStep] {
            [
                ShellStep(id: "alert", verb: "Alert", object: WeatherWords.alertObject(on: alertOn)),
                ShellStep(id: "hours", verb: "Hours", object: "Next 12 hours"),
                ShellStep(id: "walk", verb: "Walk", object: "Best time today"),
            ]
        }

        /// A door page's lines: each hour, each notable day, the air.
        func lines(_ door: WeatherDoor, calendar: Calendar = .current) -> [String] {
            switch door {
            case .hours:
                snapshot.hours.map { hour in
                    let name = WeatherWords.name(hour.kind, night: false).lowercased()
                    return "\(WeatherWords.hour(hour.date, calendar: calendar)) \(WeatherWords.degrees(hour.temperature)) \(name)"
                }
            case .week:
                snapshot.week.dropFirst().map { day in
                    let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: day.date) - 1]
                    let name = WeatherWords.name(day.kind, night: false).lowercased()
                    return "\(weekday) \(name), high \(WeatherWords.degrees(day.high)), low \(WeatherWords.degrees(day.low))"
                }
            case .air:
                WeatherWords.airLines(snapshot)
            }
        }

        /// What a door page row opens: one hour, one day, or the air now (`ShellRow.id` is "door.index").
        func detail(forRow id: String, calendar: Calendar = .current) -> LookoutDetail? {
            let parts = id.split(separator: ".")
            guard parts.count == 2, let door = WeatherDoor(rawValue: String(parts[0])),
                  let index = Int(parts[1]) else { return nil }
            switch door {
            case .hours:
                guard snapshot.hours.indices.contains(index) else { return nil }
                let hour = snapshot.hours[index]
                let wet = WeatherWords.isWet(hour.kind)
                return LookoutDetail(id: id, title: WeatherWords.hour(hour.date, calendar: calendar), lines: [
                    "\(WeatherWords.degrees(hour.temperature)), \(WeatherWords.name(hour.kind, night: false).lowercased())",
                    wet ? "Wet. Take a coat" : "Dry.",
                    "Wind \(snapshot.wind) \(WeatherWords.windUnit(snapshot.fahrenheit))",
                ])
            case .week:
                let days = Array(snapshot.week.dropFirst())
                guard days.indices.contains(index) else { return nil }
                let day = days[index]
                let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: day.date) - 1]
                return LookoutDetail(id: id, title: weekday, lines: [
                    WeatherWords.name(day.kind, night: false),
                    "High \(WeatherWords.degrees(day.high)), low \(WeatherWords.degrees(day.low))",
                    WeatherWords.isWet(day.kind) ? "Wet. Plan for rain" : "Dry.",
                ])
            case .air:
                return LookoutDetail(id: id, title: "Air", lines: WeatherWords.airLines(snapshot))
            }
        }

        @MainActor
        static func load(now: Date = AppClock.now) -> Self {
            Self(snapshot: WeatherSample.snapshot(now: now), alertOn: WeatherRainAlert.isOn())
        }
    }

    let facts: Facts

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        route.level == 0 ? landing(state) : door(WeatherDoor(rawValue: route.door ?? "hours") ?? .hours)
    }

    private var accent: Color {
        WeatherAccent.room
    }

    // MARK: Level 0

    private func landing(_ state: RoomState) -> Screen {
        let widget = facts.widget
        let item = widget.indices.contains(state.widgetIndex) ? widget[state.widgetIndex] : widget.first
        let doors = facts.doors
        let focused = doors[((state.dialFocus % doors.count) + doors.count) % doors.count]
        let switcher = WeatherWords.switcher.indices.contains(state.switcherIndex) ? state.switcherIndex : 0
        return Screen(layout: .landing, slots: [
            .title: title,
            .navWord: SlotContent(id: "lookout.nav.bridge", kind: .text, payload: .navWord("Bridge")),
            .switcher: SlotContent(id: "lookout.switcher", kind: .switcher,
                                   payload: .switcher(across: WeatherWords.switcher, vertical: [])),
            .needs: SlotContent(id: ContentID("lookout.needs.\(switcher)"), kind: .text,
                                payload: .lines(facts.needs(switcher))),
            .keystone: keystone,
            .caption: caption,
            .widget: SlotContent(id: "lookout.widget", kind: .widget, payload: .widget(widget)),
            .glyph: item.map { SlotContent(id: ContentID("lookout.glyph.\($0.id)"), kind: .glyph,
                                           payload: .glyph($0, color: $0.bigColor ?? accent)) },
            .dial: SlotContent(id: "lookout.dial", kind: .dial, payload: .dial(doors)),
            .doorSummary: SlotContent(id: ContentID("lookout.summary.\(focused.id)"), kind: .summary,
                                      payload: .summary(focused)),
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Level 1

    private func door(_ door: WeatherDoor) -> Screen {
        let dial = facts.doors.first { $0.id == door.rawValue }
        let lines = facts.lines(door)
        let rows = lines.enumerated().map { ShellRow(id: "\(door.rawValue).\($0.offset)", title: $0.element) }
        let line = switch door {
        case .hours: "The next \(lines.count) hours"
        case .week: lines.isEmpty ? "A steady week" : "The days to note"
        case .air: "Air, sun and wind now"
        }
        return Screen(layout: .door, slots: [
            .title: title,
            .navWord: SlotContent(id: "lookout.nav.lookout", kind: .text, payload: .navWord("Lookout")),
            .doorTitle: SlotContent(id: ContentID("lookout.door.\(door.rawValue).title"), kind: .text,
                                    payload: .doorTitle(name: door.name, line: line, color: dial?.color ?? accent)),
            .keystone: keystone,
            .caption: caption,
            .page: SlotContent(id: ContentID("lookout.door.\(door.rawValue).page"), kind: .list, payload: .list(rows)),
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Shared by both levels (same ids: the skypiece, title, caption and foot are not touched)

    private var title: SlotContent {
        SlotContent(id: "lookout.title", kind: .text, payload: .title("Lookout", accent: accent))
    }

    private var keystone: SlotContent {
        SlotContent(id: "lookout.sky", kind: .scene, payload: .scene("lookout.sky", label: "The sky now"))
    }

    private var caption: SlotContent {
        SlotContent(id: "lookout.caption", kind: .text, payload: .lines(facts.caption))
    }

    private var action: SlotContent {
        SlotContent(id: "lookout.action", kind: .action, payload: .action(facts.steps, accent: accent))
    }
}

/// One hour, one day or the air, opened from a door page row: a title and up to three short lines. Never a city.
struct LookoutDetail: Identifiable, Equatable {
    let id: String
    let title: String
    let lines: [String]
}

/// The page a door page row opens (shell and scaffold alike): the hour, the day or the air, in the room's type.
struct LookoutDetailPage: View {
    let detail: LookoutDetail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Lookout") { dismiss() }
                .font(.custom("Figtree", size: 17, relativeTo: .body))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(minHeight: 44)
                .buttonStyle(.plain)
            Text(detail.title)
                .font(.custom("Figtree", size: 34, relativeTo: .largeTitle).weight(.bold))
                .foregroundStyle(WeatherAccent.room)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(detail.lines.enumerated()), id: \.offset) { index, line in
                FitLine(forms: FitLine.cuts(line), size: 20, color: Theme.Colors.ink,
                        weight: index == 0 ? .semibold : .regular)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { ThemedBackground() }
    }
}

/// Lookout's foot, shared by the scaffold landing and the shell host: the phone-only rain alert with a take-back,
/// and Tess's walk line (nothing written, no place named).
@MainActor
enum LookoutActions {
    static func toggleAlert(changed: @escaping (Bool) -> Void) {
        let was = WeatherRainAlert.isOn()
        WeatherRainAlert.set(!was)
        changed(!was)
        TessVoice.shared.say(WeatherRainAlert.receipt(on: !was), takeBack: {
            WeatherRainAlert.set(was)
            changed(was)
        })
    }

    static func walk(_ snapshot: WeatherSnapshot) {
        TessVoice.shared.say(WeatherWords.walkLine(snapshot))
    }
}

/// Lookout opened through the standing shell (`-shellRoom lookout` on the simulator): the sky plate is the page
/// (`shellBackdrop`), the skypiece the keystone, and the page wears the plate's ink. Drops fall from the glass on
/// arrival (none under Reduce Motion).
struct LookoutShellHost: View {
    @Environment(\.colorScheme) private var scheme
    @State private var navigator = ShellNavigator(root: .landing(LookoutRoomContent.room))
    @State private var alertOn = WeatherRainAlert.isOn()
    @State private var detail: LookoutDetail?

    var body: some View {
        let facts = LookoutRoomContent.Facts(snapshot: WeatherSample.snapshot(now: Self.minute(AppClock.now)),
                                             alertOn: alertOn)
        let snapshot = facts.snapshot
        let plate = LookoutPlate.pick(kind: snapshot.kind, at: snapshot.now, dark: scheme == .dark)
        ShellView(room: LookoutRoomContent(facts: facts), navigator: navigator, accent: WeatherAccent.room,
                  act: { handle($0, facts) })
            .environment(\.shellScene) { _ in
                AnyView(LookoutSkypiece(snapshot: snapshot) { navigator.push(.door(LookoutRoomContent.room, "hours")) })
            }
            .environment(\.shellBackdrop, AnyView(LookoutPlateView(plate: plate, fallback: AnyView(
                LookoutSkyView(kind: snapshot.kind, now: snapshot.now)
            ))))
            .environment(\.doorSummaryStyle, .fog)
            .environment(\.shellGlyphRoom, .lookout)
            // The text colour comes from the plate (256), so the page wears the plate's scheme.
            .environment(\.colorScheme, plate.lightInk ? .dark : .light)
            .overlay { LookoutDropHandover() }
            .sheet(item: $detail) { LookoutDetailPage(detail: $0) }
        #if DEBUG
            .task { await walkForStills() }
        #endif
    }

    /// The snapshot is read to the minute, so the screen holds still between minutes.
    static func minute(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }

    #if DEBUG
        /// `-shellDoor hours` (simulator only, LaunchFlags): opens that door 2 s after launch; `-shellBack` comes back.
        private func walkForStills() async {
            guard let door = LaunchFlags.value(after: "-shellDoor") else { return }
            try? await Task.sleep(for: .seconds(2))
            navigator.push(.door(LookoutRoomContent.room, door))
            guard LaunchFlags.has("-shellBack") else { return }
            try? await Task.sleep(for: .seconds(3))
            navigator.pop()
        }
    #endif

    private func handle(_ intent: ShellIntent, _ facts: LookoutRoomContent.Facts) {
        switch intent {
        case .done, .notNow:
            break
        case .back:
            navigator.pop()
        case let .openDoor(id):
            navigator.push(.door(LookoutRoomContent.room, id))
        case let .openItem(id):
            // A widget card opens its door; a page row opens the hour, the day or the air it names.
            if let opened = facts.detail(forRow: id) {
                detail = opened
            } else {
                navigator.push(.door(LookoutRoomContent.room, facts.door(forItem: id).rawValue))
            }
        case .action("hours"):
            navigator.push(.door(LookoutRoomContent.room, "hours"))
        case .action("walk"):
            LookoutActions.walk(facts.snapshot)
        case .action:
            LookoutActions.toggleAlert { alertOn = $0 }
        }
    }
}
