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
                DialDoor(id: "week", name: "This week", color: Theme.Colors.Accent.rain,
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

        /// The Door title's second line.
        func line(_ door: WeatherDoor) -> String {
            switch door {
            case .hours: "The next \(snapshot.hours.count) hours"
            case .week: WeatherWords.weekLines(snapshot).isEmpty ? "A steady week" : "The days to note"
            case .air: "Air, sun and wind now"
            }
        }

        /// A door page's ranked rows, only what the snapshot can answer: each hour (its word and temperature), each
        /// day from tomorrow (its word and high), the air (wind, air word, UV). Row ids are "door.index".
        func rows(_ door: WeatherDoor, calendar: Calendar = .current) -> [LevelRow] {
            switch door {
            case .hours:
                snapshot.hours.enumerated().map { index, hour in
                    LevelRow(id: "hours.\(index)", title: WeatherWords.hour(hour.date, calendar: calendar).uppercased(),
                             value: "\(hour.temperature)", unit: "\u{00B0}",
                             sub: WeatherWords.name(hour.kind, night: false))
                }
            case .week:
                snapshot.week.dropFirst().enumerated().map { index, day in
                    let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: day.date) - 1]
                    return LevelRow(id: "week.\(index)", title: weekday, value: "\(day.high)", unit: "\u{00B0}",
                                    sub: WeatherWords.name(day.kind, night: false))
                }
            case .air:
                [
                    LevelRow(id: "air.0", title: "Wind", value: "\(snapshot.wind)",
                             unit: WeatherWords.windUnit(snapshot.fahrenheit)),
                    LevelRow(
                        id: "air.1",
                        title: "Air",
                        sub: snapshot.air.prefix(1).uppercased() + snapshot.air.dropFirst()
                    ),
                    LevelRow(id: "air.2", title: "UV", value: "\(snapshot.uvIndex)"),
                ]
            }
        }

        /// An item page: an hour opens the `hours` body (the hour before to two after, one advice line); any other
        /// row draws its siblings until its own page is drawn.
        func item(door: WeatherDoor, rowID: String, calendar: Calendar = .current) -> LookoutItem {
            let all = rows(door, calendar: calendar)
            let parts = rowID.split(separator: ".")
            let index = parts.count == 2 ? Int(parts[1]) : nil
            guard let index, all.indices.contains(index) else {
                return LookoutItem(
                    title: "Nothing here",
                    line: "",
                    facts: [],
                    body: .siblings(SiblingsBody.make(rows: all,
                                                      current: rowID))
                )
            }
            let row = all[index]
            guard door == .hours else {
                let facts = DeckRoomContent.plainFacts(row, index: index, count: all.count, door: door.name,
                                                       doorID: door.rawValue)
                return LookoutItem(title: row.title, line: row.sub, facts: facts,
                                   body: .siblings(SiblingsBody.make(rows: all, current: rowID)))
            }
            let hour = snapshot.hours[index]
            let wet = WeatherWords.isWet(hour.kind)
            // The hour before, the hour and the two after; slid to keep four where the day's ends allow.
            let first = min(max(index - 1, 0), max(snapshot.hours.count - 4, 0))
            let window = snapshot.hours.indices.filter { $0 >= first && $0 < first + 4 }
            let lines = window.map { at in
                HoursLine(id: "hours.\(at)", time: all[at].title, word: all[at].sub, temp: all[at].value,
                          unit: all[at].unit, isOpen: at == index)
            }
            let word = WeatherWords.name(hour.kind, night: false)
            return LookoutItem(
                title: row.title, line: "\(word), \(hour.temperature) degrees",
                facts: [ItemFact(number: "\(hour.temperature)", unit: "\u{00B0}", label: "Temp"),
                        ItemFact(number: "\(snapshot.wind)", unit: WeatherWords.windUnit(snapshot.fahrenheit),
                                 label: "Wind"),
                        ItemFact(number: "\(snapshot.uvIndex)", label: "UV")],
                body: .hours(HoursBody(lines: lines, advice: wet ? "Wet, take a coat" : "Dry")),
                isHour: true
            )
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
                    wet ? "Wet, take a coat" : "Dry",
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
                    WeatherWords.isWet(day.kind) ? "Wet, plan for rain" : "Dry",
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
        let door = WeatherDoor(rawValue: route.door ?? "hours") ?? .hours
        return switch route.level {
        case 0: landing(state)
        case 1: self.door(door)
        default: item(door: door, id: route.item ?? "")
        }
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
        let all = WeatherDoor.allCases
        let at = all.firstIndex(of: door) ?? 0
        let previous = (at + all.count - 1) % all.count
        let next = (at + 1) % all.count
        let title = PageTitle(
            name: door.name, line: facts.line(door),
            previous: .door(Self.room, all[previous].rawValue), next: .door(Self.room, all[next].rawValue),
            previousFocus: previous, nextFocus: next
        )
        return Screen(layout: .door, slots: [
            .title: self.title,
            .navWord: SlotContent(id: "lookout.nav.doors", kind: .text, payload: .navWord("Doors")),
            .doorTitle: SlotContent(id: ContentID("lookout.door.\(door.rawValue).title"), kind: .text,
                                    payload: .pageTitle(title)),
            .keystone: keystone,
            .caption: caption,
            .page: SlotContent(id: ContentID("lookout.door.\(door.rawValue).page"), kind: .rows,
                               payload: .ranked(RankedPageData(rows: facts.rows(door), accent: accent))),
            .actionWord: doorFoot(door),
            .tess: nil,
        ])
    }

    // MARK: Level 2

    private func item(door: WeatherDoor, id: String) -> Screen {
        let rows = facts.rows(door)
        let place = rows.firstIndex { $0.id == id }
        let previous = place.flatMap { rows.count > 1 ? ($0 + rows.count - 1) % rows.count : nil }
        let next = place.flatMap { rows.count > 1 ? ($0 + 1) % rows.count : nil }
        let page = facts.item(door: door, rowID: id)
        let title = PageTitle(
            name: page.title, line: page.line,
            previous: previous.map { .item(Self.room, door.rawValue, rows[$0].id) },
            next: next.map { .item(Self.room, door.rawValue, rows[$0].id) }, isItem: true
        )
        return Screen(layout: .door, slots: [
            .title: self.title,
            .navWord: SlotContent(id: ContentID("lookout.nav.door.\(door.rawValue)"), kind: .text,
                                  payload: .navWord(door.name)),
            .doorTitle: SlotContent(id: ContentID("lookout.item.\(door.rawValue).\(id).title"), kind: .text,
                                    payload: .pageTitle(title)),
            .keystone: keystone,
            .caption: caption,
            .page: SlotContent(id: ContentID("lookout.item.\(door.rawValue).\(id).page"), kind: .rows,
                               payload: .item(ItemPageData(facts: page.facts, body: page.body, accent: accent))),
            .actionWord: itemFoot(page),
            .tess: nil,
        ])
    }

    /// The foot at level 1: Alert before rain, Ask Tess about the door. (The Lookout has nothing to add to.)
    private func doorFoot(_ door: WeatherDoor) -> SlotContent {
        SlotContent(id: "lookout.action.door", kind: .action, payload: .action([
            ShellStep(id: "alert", verb: "Alert", object: "before rain"),
            ShellStep(id: "ask", verb: "Ask", object: "Tess about \(door.name)"),
        ], accent: accent))
    }

    /// The foot at level 2: an hour has its own verbs; any other row opens or asks.
    private func itemFoot(_ page: LookoutItem) -> SlotContent {
        if page.isHour {
            return SlotContent(id: "lookout.action.hour", kind: .action, payload: .action([
                ShellStep(id: "alert", verb: "Alert", object: "30 min before"),
                ShellStep(id: "walk", verb: "Walk", object: "Best time today"),
            ], accent: accent))
        }
        return SlotContent(id: "lookout.action.row", kind: .action, payload: .action([
            ShellStep(id: "open", verb: "Open", object: page.title),
            ShellStep(id: "ask", verb: "Ask", object: "Tess about \(page.title)"),
        ], accent: accent))
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

/// An item page of the Lookout (level 2): its title and line, its facts and its body.
struct LookoutItem: Equatable {
    var title: String
    var line: String
    var facts: [ItemFact]
    var body: ItemBody
    var isHour = false
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

    /// Ask has no page of its own yet: Tess says how to reach her.
    static func ask(_ door: String?) {
        let name = door.flatMap(WeatherDoor.init(rawValue:))?.name ?? "the weather"
        TessVoice.shared.say("Hold me and ask about \(name.lowercased())")
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
            LookoutRouting.open(id, navigator: navigator, facts: facts)
        case .action("hours"):
            navigator.push(.door(LookoutRoomContent.room, "hours"))
        case .action("walk"):
            LookoutActions.walk(facts.snapshot)
        case .action("ask"):
            LookoutActions.ask(navigator.route.door)
        case .action("open"):
            break
        case .action:
            LookoutActions.toggleAlert { alertOn = $0 }
        }
    }
}

/// What a tap on a card or row does in the Lookout: a widget card opens its door; a door page row opens its item page
/// (level 2); an item page's sibling replaces it.
@MainActor
enum LookoutRouting {
    static func open(_ id: String, navigator: ShellNavigator, facts: LookoutRoomContent.Facts) {
        let route = navigator.route
        switch route.level {
        case 0: navigator.push(.door(route.room, facts.door(forItem: id).rawValue))
        case 1: navigator.push(.item(route.room, route.door ?? "hours", id))
        default: navigator.replace(.item(route.room, route.door ?? "hours", id))
        }
    }
}
