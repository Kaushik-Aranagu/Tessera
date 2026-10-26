import SwiftUI

/// Layout mode (sheet 283 v7): places only, no content, read-only. Every screen as soft bubbles, one per place of
/// the v4 map, in the room's colour (11% fill, 18 pt radius, a 1 pt inner line); empty places dashed and labelled
/// "empty"; the breaths drawn as empty strips. Bubbles never leave the screen: across walks the rooms (each bubble
/// takes the next room's colour and changes its label the way its place does), up opens the room's door page (the
/// merges of v5), down splits them back. Tap a bubble to read it; tap the ground for where you are. Leave by the Nav
/// word twice or the left-edge pull.
struct LayoutModeView: View {
    var leave: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var room = LayoutRoom.bridge
    @State private var level = LayoutKind.landing
    @State private var previous: LayoutRoom?
    @State private var selected: LayoutBubble?
    @State private var showWhere = false
    @State private var bump = false
    @State private var navTaps: [Date] = []
    @State private var dialTaps: [Date] = []
    @FocusState private var focused: Bool

    var body: some View {
        GeometryReader { proxy in
            let scale = max(0.86, min(1.1, proxy.size.height / 874))
            let dx = (proxy.size.width - 402) / 2
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { tappedGround() }
                    .accessibilityHidden(true)
                ForEach(LayoutBubble.all, id: \.self) { bubble in
                    let rect = bubble.frame(room: room, level: level)
                    bubbleView(bubble)
                        .frame(width: rect.width, height: rect.height)
                        .opacity(bubble.isShown(room: room, level: level) ? 1 : 0)
                        .offset(x: rect.minX + dx, y: rect.minY * scale)
                        .allowsHitTesting(bubble.isShown(room: room, level: level))
                        .accessibilityHidden(!bubble.isShown(room: room, level: level))
                }
                panel
                    .offset(x: LandingPlace.keystone.frame.minX + dx, y: LandingPlace.keystone.frame.minY * scale)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .background { ThemedBackground() }
        .contentShape(Rectangle())
        .gesture(walk)
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(.rightArrow) { step(1); return .handled }
        .onKeyPress(.leftArrow) { step(-1); return .handled }
        .onKeyPress(.upArrow) { deeper(); return .handled }
        .onKeyPress(.downArrow) { upward(); return .handled }
        .onAppear { focused = true }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Layout mode, \(whereLine)")
        .accessibilityAction(named: "Next room") { step(1) }
        .accessibilityAction(named: "Previous room") { step(-1) }
        .accessibilityAction(named: room.hasDoors && level == .landing ? "Door page" : "Back up") {
            if level == .landing {
                deeper()
            } else {
                upward()
            }
        }
    }

    // MARK: Bubbles

    private func bubbleView(_ bubble: LayoutBubble) -> some View {
        let holds = bubble.holds(room: room, level: level)
        let empty = holds == nil
        let color = room.color
        let radius: CGFloat = bubble.isBreath ? 6 : (bump ? 26 : 18)
        return ZStack(alignment: .topLeading) {
            if empty {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(color.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            } else {
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(color.opacity(0.11))
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(color.opacity(0.32), lineWidth: 1)
                    .padding(1)
            }
            if !bubble.isBreath, bubble != .place(.keystone) || (selected == nil && !showWhere) {
                label(bubble, empty: empty)
            }
            if bubble == .place(.dial) {
                reel
            }
        }
        .tesseraAnimation(.easeOut(duration: 0.2), value: room)
        .contentShape(Rectangle())
        .onTapGesture { tapped(bubble) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bubble.isBreath ? "Breath, empty" : "\(bubble.name(room: room)), \(holds ?? "empty")")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(bubble
            .isShown(room: room, level: level) ? "layout.\(bubble.key)" : "layout.merged.\(bubble.key)")
    }

    /// The bubble's label: the room's name on the Title, else the place's name, with "empty" under an empty place.
    /// It changes with the room the way the place changes its content on the phone.
    private func label(_ bubble: LayoutBubble, empty: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FitLine(forms: FitLine.cuts(bubble.name(room: room)), size: bubble == .place(.title) ? 17 : 13,
                    color: room.color, weight: .semibold)
            if empty {
                Text("empty")
                    .font(.custom("Figtree", size: 11, relativeTo: .caption2))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .id("\(bubble.key)-\(room.rawValue)-\(level == .door ? 1 : 0)")
        .transition(labelTransition(bubble))
    }

    private func labelTransition(_ bubble: LayoutBubble) -> AnyTransition {
        guard let place = bubble.place, !reduceMotion else { return .opacity.animation(MotionPolicy.reducedMotionFade) }
        if place == .dial {
            // The reel runs over the dial; its name settles in as the reel stops.
            return .asymmetric(insertion: .opacity.animation(MotionPolicy.resolve(
                .easeOut(duration: 0.14).delay(ShellTiming.reel - 0.14), reduceMotion: false
            )),
            removal: .opacity.animation(
                MotionPolicy.resolve(.easeOut(duration: 0.1), reduceMotion: false)
            ))
        }
        return PlaceTransition.make(place, PlaceStyle(move: .move, context: .route), reduceMotion: false)
    }

    /// The dial's reel when the room changes (0.98 s): the old room's dial, mixed names, then the new one.
    @ViewBuilder
    private var reel: some View {
        if let previous, previous != room, !reduceMotion {
            DialReel(from: [previous.dialLabel, previous.name], to: [room.dialLabel, room.name], color: room.color)
                .id("reel-\(previous.rawValue)-\(room.rawValue)")
        }
    }

    // MARK: The reading panel (inside the Keystone bubble)

    @ViewBuilder
    private var panel: some View {
        let rect = LandingPlace.keystone.frame
        if let selected {
            let frame = selected.frame(room: room, level: level)
            VStack(alignment: .leading, spacing: 2) {
                FitLine(forms: [selected.name(room: room)], size: 17, color: room.color, weight: .semibold)
                Text("\(Int(frame.minX)), \(Int(frame.minY)), \(Int(frame.width)) by \(Int(frame.height))")
                    .font(.custom("Outfit", size: 13, relativeTo: .caption))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                panelLine("Holds", selected.holds(room: room, level: level) ?? "Nothing here: kept, empty")
                panelLine("Touch", selected.touch)
                panelLine("Next room", selected.nextRoom)
                panelLine(level == .landing ? "Door page" : "Back up", selected.depth(level: level, room: room))
            }
            .padding(12)
            .frame(width: rect.width, height: rect.height, alignment: .topLeading)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("layout.panel")
            .transition(.opacity)
        } else if showWhere {
            VStack(alignment: .leading, spacing: 4) {
                FitLine(forms: [whereLine], size: 17, color: room.color, weight: .semibold)
                panelLine("Across", "The next room; every bubble stays")
                panelLine("Up", room.hasDoors ? "The door page; places merge" : "Bridge has one level")
                panelLine("Down", "Back up; the merged places split")
                panelLine("Leave", "The Nav word twice, or pull from the left edge")
            }
            .padding(12)
            .frame(width: rect.width, height: rect.height, alignment: .topLeading)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("layout.where")
            .transition(.opacity)
        }
    }

    private func panelLine(_ head: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(head)
                .font(.custom("Figtree", size: 13, relativeTo: .caption).weight(.semibold))
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize()
            FitLine(forms: FitLine.cuts(text), size: 13, color: Theme.Colors.inkSecondary)
        }
    }

    /// "Galley, the landing, 5 of 7".
    private var whereLine: String {
        "\(room.name), \(level == .landing ? "the landing" : "the door page"), \(room.rawValue + 1) of \(LayoutRoom.allCases.count)"
    }

    // MARK: Gestures

    private var walk: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let width = value.translation.width
                let height = value.translation.height
                if value.startLocation.x < 24, width > 80, abs(height) < 120 {
                    exit()
                } else if abs(width) > abs(height), abs(width) > 60 {
                    step(width < 0 ? 1 : -1)
                } else if abs(height) > 60 {
                    if height < 0 {
                        deeper()
                    } else {
                        upward()
                    }
                }
            }
    }

    private func step(_ delta: Int) {
        let count = LayoutRoom.allCases.count
        let next = LayoutRoom(rawValue: (room.rawValue + delta + count) % count) ?? .bridge
        previous = room
        withTesseraAnimation(.easeOut(duration: 0.2), reduceMotion: reduceMotion) {
            selected = nil
            showWhere = false
            room = next
            // Switching rooms on a door page keeps the door level; Bridge has one level.
            if !next.hasDoors {
                level = .landing
            }
        }
    }

    private func deeper() {
        guard room.hasDoors, level == .landing else { return }
        glide(to: .door)
    }

    private func upward() {
        guard level == .door else { return }
        glide(to: .landing)
    }

    /// Places in both glide to their new frame (0.56 s), the radius bumping mid-way; merges and splits flow. Reduce
    /// Motion: the bubbles jump.
    private func glide(to next: LayoutKind) {
        previous = room
        if reduceMotion {
            selected = nil
            level = next
            return
        }
        withAnimation(MotionPolicy.resolve(.timingCurve(0.3, 0.7, 0.2, 1, duration: 0.56), reduceMotion: false)) {
            selected = nil
            level = next
        }
        withAnimation(MotionPolicy.resolve(.easeOut(duration: 0.28), reduceMotion: false)) { bump = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.28))
            withAnimation(MotionPolicy.resolve(.easeIn(duration: 0.28), reduceMotion: false)) { bump = false }
        }
    }

    private func tapped(_ bubble: LayoutBubble) {
        let now = Date()
        if bubble == .place(.navWord) {
            navTaps = navTaps.filter { now.timeIntervalSince($0) < 1.2 } + [now]
            if navTaps.count >= 2 {
                exit()
                return
            }
        }
        if bubble == .place(.dial), room == .bridge {
            // Bridge has one level: its dial tapped twice walks into Log.
            dialTaps = dialTaps.filter { now.timeIntervalSince($0) < 1.2 } + [now]
            if dialTaps.count >= 2 {
                dialTaps = []
                step(1)
                return
            }
        }
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
            showWhere = false
            selected = selected == bubble ? nil : bubble
        }
    }

    private func tappedGround() {
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
            selected = nil
            showWhere.toggle()
        }
    }

    private func exit() {
        leave()
        dismiss()
    }
}

// MARK: - The rooms

/// The seven screens Layout mode walks, in order, looping.
enum LayoutRoom: Int, CaseIterable {
    case bridge, log, lookout, deck, galley, watch, purse

    var name: String {
        ["Bridge", "Log", "Lookout", "Deck", "Galley", "Watch", "Purse"][rawValue]
    }

    var color: Color {
        switch self {
        case .bridge: Theme.Colors.ink
        case .log: LandingAccent.notes
        case .lookout: Theme.Colors.Accent.rain
        case .deck: Theme.Colors.Accent.training
        case .galley: LandingAccent.kitchen
        case .watch: Theme.Colors.Accent.routines
        case .purse: LandingAccent.money
        }
    }

    /// Bridge has one level.
    var hasDoors: Bool {
        self != .bridge
    }

    var dialLabel: String {
        self == .bridge ? "The apps" : "Doors"
    }

    fileprivate var switcher: String {
        switch self {
        case .bridge: "Departure board"
        case .log: "Newest, Due, Pinned, From Tess"
        case .lookout: "Now, Tonight, Tomorrow, This week"
        case .deck: "Today, This week, This month"
        case .galley: "Tonight, Tomorrow, This week"
        case .watch: "Evening, Night, Morning"
        case .purse: "October, This year, Since May"
        }
    }

    fileprivate var keystone: String {
        switch self {
        case .bridge: "The mosaic"
        case .log: "The word wall"
        case .lookout: "The sky glass"
        case .deck: "The chalk board"
        case .galley: "The ticket rail"
        case .watch: "The woods"
        case .purse: "The index"
        }
    }

    fileprivate var widget: String {
        switch self {
        case .bridge: "The one thing"
        case .log: "The newest notes"
        case .lookout: "Rain from 7 pm, tonight 54°"
        case .deck: "Tonight 6:30 pm, this week 3 of 6"
        case .galley: "Tacos, rice, 3 things on the way"
        case .watch: "Walk, journal, 3 of 7"
        case .purse: "Still yours, next drop, today"
        }
    }

    fileprivate var glyph: String {
        switch self {
        case .bridge: "The thing's sign in mosaic tiles"
        case .log: "Spark, bulb, book or checklist"
        case .lookout: "Rain, moon or sun"
        case .deck: "Steps, ticks or barbell"
        case .galley: "Plates, bowl, ticket or basket"
        case .watch: "Watering can, grove, bird and flower"
        case .purse: "Calendar, coins or index line"
        }
    }

    fileprivate var action: String? {
        switch self {
        case .bridge: nil
        case .log: "Write, Speak, List"
        case .lookout: "Alert, Hours, Walk"
        case .deck: "Start, Log, Rest"
        case .galley: "Cook, Get, Wash"
        case .watch: "Plant, Water, Pause"
        case .purse: "Log, Look, Plan"
        }
    }
}

// MARK: - The bubbles

/// One bubble: a shell place, or one of the three breaths.
enum LayoutBubble: Hashable {
    case place(Place)
    case breath(LandingPlace)

    static let all: [LayoutBubble] = [
        .breath(.breathAboveKeystone),
        .breath(.breathBelowWidget),
        .breath(.breathAboveFoot),
    ]
        + Place.allCases.map { .place($0) }

    var key: String {
        switch self {
        case let .place(place): place.rawValue
        case let .breath(breath): breath.rawValue
        }
    }

    var place: Place? {
        if case let .place(place) = self {
            place
        } else {
            nil
        }
    }

    var isBreath: Bool {
        if case .breath = self {
            true
        } else {
            false
        }
    }

    /// Where the bubble sits. Bridge holds the Settings word and the Departure board in its masthead; a merged-away
    /// place waits in its target's rect (so a split spreads out of it).
    func frame(room: LayoutRoom, level: LayoutKind) -> CGRect {
        switch self {
        case let .breath(breath):
            return level == .door && breath != .breathAboveKeystone ? ShellLayout.mergedFrame(.page) : breath.frame
        case let .place(place):
            if room == .bridge {
                switch place {
                case .title: return LandingPlace.Masthead.settingsWord
                case .switcher, .needs: return LandingPlace.Masthead.departureBoard
                default: break
                }
            }
            return ShellLayout.frame(place, in: level)
        }
    }

    func isShown(room: LayoutRoom, level: LayoutKind) -> Bool {
        switch self {
        case let .breath(breath):
            return level == .landing || breath == .breathAboveKeystone
        case let .place(place):
            // Bridge's Departure board is one bubble: Needs folds into it.
            if room == .bridge, place == .needs {
                return false
            }
            return ShellLayout.exists(place, in: level)
        }
    }

    func name(room: LayoutRoom) -> String {
        guard case let .place(place) = self else { return "Breath" }
        switch place {
        case .title: return room == .bridge ? "Settings word" : room.name
        case .navWord: return "Nav word"
        case .switcher: return room == .bridge ? "Departure board" : "Switcher"
        case .needs: return "Needs"
        case .doorTitle: return "Door title"
        case .keystone: return "Keystone"
        case .caption: return "Caption"
        case .widget: return "Widget"
        case .glyph: return "Glyph"
        case .dial: return "Dial"
        case .doorSummary: return "Door summary"
        case .page: return "Page"
        case .actionWord: return "Action word"
        case .tess: return "Tess"
        }
    }

    /// What the place holds in this room, or nil when it is kept empty.
    func holds(room: LayoutRoom, level: LayoutKind) -> String? {
        guard case let .place(place) = self else { return nil }
        let bridge = room == .bridge
        switch place {
        case .title: return bridge ? "Settings, and the way to it" : "The room's name, \(room.name)"
        case .navWord: return bridge ? nil : (level == .door ? room.name : "Bridge")
        case .switcher: return room.switcher
        case .needs: return bridge ? nil : "Two lines on what the room needs"
        case .doorTitle: return "The door's name and one line"
        case .keystone: return room.keystone
        case .caption: return bridge ? nil : "One line on how to touch the keystone"
        case .widget: return room.widget
        case .glyph: return room.glyph
        case .dial: return bridge ? "The apps" : "The room's doors"
        case .doorSummary: return bridge ? "One fact line" : "The focused door's lines"
        case .page: return "The door's list, newest first"
        case .actionWord: return room.action
        case .tess: return "Tess, in the room's colour"
        }
    }

    var touch: String {
        guard case let .place(place) = self else { return "None: always empty" }
        switch place {
        case .title: return "Opens the index"
        case .navWord: return "Goes back; twice here leaves Layout mode"
        case .switcher: return "Across or up and down past 40 pt; tap for the next"
        case .needs: return "None; they change with the switcher"
        case .doorTitle: return "None"
        case .keystone: return "Its own gestures; a drag that starts on it stays"
        case .caption: return "None"
        case .widget: return "Swipe for the next item; hold to strike; tap opens"
        case .glyph: return "None"
        case .dial: return "Up and down; tap the focus to open"
        case .doorSummary: return "None; it changes with the dial"
        case .page: return "Scroll; tap a row to open it"
        case .actionWord: return "Tap does it; swipe across for the next action"
        case .tess: return "Tap to talk to Tess"
        }
    }

    /// How the place changes going to the next room (sheet 283 v4, shell-contract-283.md).
    var nextRoom: String {
        guard case let .place(place) = self else { return "Stays empty" }
        switch place {
        case .title, .navWord, .switcher, .needs, .doorTitle: return "Flaps like the board, row by row"
        case .keystone: return "Turns: the flip, and back the reveal"
        case .caption: return "Rolls up into the keystone and unrolls"
        case .widget: return "The old item up and out; the new one rises"
        case .glyph: return "Collapses to a point and forms again"
        case .dial: return "The reel spins through both lists and slows"
        case .doorSummary: return "Off to the right; the new one in from the right"
        case .page: return "Leaves softly; new rows settle top down"
        case .actionWord: return "Out left with a lean; new letters stream in"
        case .tess: return "Stays; only her colour changes"
        }
    }

    /// The door-page rule (or, on a door page, the way back up).
    func depth(level: LayoutKind, room: LayoutRoom) -> String {
        guard room.hasDoors else { return "Bridge has one level; the dial twice walks into Log" }
        switch self {
        case .breath(.breathAboveKeystone): return "Stays"
        case .breath: return level == .landing ? "Merges into the Page" : "Splits out of the Page"
        case let .place(place):
            if let target = ShellLayout.target(of: place) {
                let name = target == .page ? "Page" : "Door title"
                return level == .landing ? "Merges into the \(name)" : "Splits out of the \(name)"
            }
            switch place {
            case .doorTitle: return level == .door ? "Splits into the Switcher and Needs" : "Forms from the Switcher and Needs"
            case .page: return level == .door ? "Splits into the Widget, Glyph, Dial and Summary"
                : "Forms from the Widget, Glyph, Dial and Summary"
            case .keystone: return "Stays, untouched"
            default: return "Stays; glides to its frame"
            }
        }
    }
}

/// `-layoutMode` on the simulator: Layout mode first; leaving it shows Bridge (the app as usual).
struct LayoutModeFlagHost: View {
    @State private var open = true

    var body: some View {
        if open {
            LayoutModeView { open = false }
        } else {
            RootView()
        }
    }
}

/// The simulator's way into the sheet 283 screens: `-shell` opens the Log through the standing shell, `-layoutMode`
/// opens Layout mode. LaunchFlags is simulator-only, so neither ever reaches the phone.
struct ShellFlagRoot: View {
    static var isAsked: Bool {
        LaunchFlags.has("-shell") || LaunchFlags.has("-layoutMode")
    }

    var body: some View {
        if LaunchFlags.has("-layoutMode") {
            LayoutModeFlagHost()
        } else {
            NotesShellHost()
        }
    }
}
