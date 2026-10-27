import SwiftUI
import TesseraCore

/// The step rules of the departure board (sheet 200), kept apart from the view so they test without a screen.
enum DepartureSteps {
    /// The strip a changed letter clicks through.
    static let strip = Array(" abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:,.'")
    static let maxSteps = 9
    static let stepMS = 52
    static let flipMS = 70
    static let delayMS = 14

    /// The letters shown from `old` to `new`: forward along the strip, at most nine, skipping evenly. A character
    /// that is not on the strip lands at once.
    static func sequence(from old: Character, to new: Character) -> [Character] {
        guard old != new else { return [] }
        guard let b = strip.firstIndex(of: new) else { return [new] }
        let a = strip.firstIndex(of: old) ?? 0
        var remaining = (b - a + strip.count) % strip.count
        let skip = max(1, Int((Double(remaining) / Double(maxSteps)).rounded(.up)))
        var at = a
        var out: [Character] = []
        while remaining > 0 {
            let move = min(skip, remaining)
            at = (at + move) % strip.count
            remaining -= move
            out.append(strip[at])
        }
        return out
    }

    /// The line as letters: the runs joined by one space cell each (an app word never runs into the next word).
    static func flat(_ line: [DepartureSegment]) -> [Character] {
        Array(line.map(\.text).joined(separator: " "))
    }

    /// Where each run starts in `flat`.
    static func starts(_ line: [DepartureSegment]) -> [Int] {
        line.reduce(into: [0]) { $0.append($0[$0.count - 1] + $1.text.count + 1) }
    }

    /// Start delay of a letter: (line x 5 + index) x 14 ms.
    static func delay(line: Int, index: Int) -> Int {
        (line * 5 + index) * delayMS
    }
}

/// One run of a line: plain words, an app word (its accent) or a number (Outfit 300).
struct DepartureSegment: Equatable {
    enum Kind: Equatable {
        case plain, number
        case app(HomeApp)
        /// "Sunset": painted with the mosaic's sky, a link to its weather page (sheet 212).
        case sky
        /// The date (sheet 216): Figtree 500, no underline, a gradient of the hour's sky; it opens Today.
        case day
    }

    var text: String
    var kind: Kind
    /// A door (sheet 211): an app word, or a number that belongs to a clause with an app word, opens its thing.
    var opens = false
    /// Home 236 v2.4: the weather the word names, when it names one; the word then wears its effects.
    var weather: WeatherKind?
}

/// Turns a clause into segments, using the same word split as the day sentence.
enum DepartureLines {
    static func segments(of clause: HomeSentence.Clause) -> [DepartureSegment] {
        var out: [DepartureSegment] = []
        let words = DaySentence.words([clause])
        let hasDoor = words.contains { $0.app != nil }
        func add(_ text: String, _ kind: DepartureSegment.Kind, opens: Bool = false) {
            if let last = out.last, last.kind == kind {
                out[out.count - 1].text += " " + text
            } else {
                out.append(DepartureSegment(text: text, kind: kind, opens: opens))
            }
        }
        for word in words {
            if let app = word.app {
                add(word.text, .app(app), opens: true)
            } else if word.text.contains(where: \.isNumber) {
                add(word.text, .number, opens: hasDoor)
            } else {
                add(word.text, .plain)
            }
        }
        return out
    }
}

/// The three lines as a departure board: when a line changes, each changed letter steps through the strip to its new
/// character, hinged at the middle, left to right with a small stagger. Unchanged letters stay put. With Reduce Motion
/// the whole line crossfades in 150 ms and nothing flips. VoiceOver reads the final sentence once.
struct DepartureBoard: View {
    let lines: [[DepartureSegment]]
    /// A door was tapped: the line it is on, and the word's frame in window space (the doorway's wave starts there).
    let open: (Int, CGRect) -> Void

    static let size: CGFloat = 23
    static let lineGap: CGFloat = 3
    /// Each of the three lines has its own fixed row, so a flip or a longer line never moves the page (Kaushik, Oct
    /// 23).
    static let rowHeight: CGFloat = 30
    static let boardHeight: CGFloat = rowHeight * 3 + lineGap * 2

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var cells: [[Cell]] = []
    @State private var generation = 0
    @State private var landed = 0
    @State private var onScreen = false
    @State private var taps = 0
    /// What the cells were last heading for, so a newer change can snap them there before it starts.
    @State private var lastTarget: [[Cell]] = []
    /// Where each door word sits, kept outside the view state so a layout pass does not redraw the board.
    @State private var frames = DoorFrames()
    /// The hour's band, re-checked on a timer so the date's colour turns without a redraw.
    @State private var band = DateSky.band(at: AppClock.now)

    final class DoorFrames {
        var byKey: [String: CGRect] = [:]
    }

    struct Cell: Equatable {
        var shown: Character
        var squash: Bool = false
        /// The cell's own fixed width: the width of the letter it will end on, in its face. The letters that walk
        /// through
        /// it are drawn centred in it, so nothing on the row moves while they flip (sheet 216, r28).
        var width: CGFloat?
        /// The face and colour of the run the letter came from, so a dropped letter keeps them through the pass.
        var kind: DepartureSegment.Kind?
    }

    private var finalText: String {
        lines.map { $0.map(\.text).joined(separator: " ") }.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: Self.lineGap) {
            ForEach(Array(lines.enumerated()), id: \.offset) { li, line in
                lineView(li, line)
                    .frame(maxWidth: .infinity, minHeight: Self.rowHeight, maxHeight: typeSize.isAccessibilitySize
                        ? nil : Self.rowHeight, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        // One element for the whole board (its flap letters never surface one by one), with each door an action.
        .accessibilityRepresentation { Text(finalText) }
        .accessibilityActions {
            // Each door is a button: "Push day, opens Training".
            ForEach(Array(lines.enumerated()), id: \.offset) { li, line in
                let starts = DepartureSteps.starts(line)
                ForEach(Array(line.enumerated()), id: \.offset) { k, seg in
                    if seg.opens, case let .app(app) = seg.kind {
                        Button("\(seg.text), opens \(app.rawValue)") {
                            open(li, frames.byKey["\(li)-\(starts[k])"] ?? .zero)
                        }
                    }
                }
            }
        }
        .tesseraFeedback(.made, trigger: landed)
        .tesseraFeedback(.made, trigger: taps)
        .onAppear {
            onScreen = true
            band = DateSky.band(at: AppClock.now)
            if cells.isEmpty {
                cells = lines.map { Self.cells($0) }
                lastTarget = cells
            }
        }
        .onDisappear { onScreen = false }
        .task {
            // The hour's band is re-checked every 30 s; when it turns, the colour eases over (MotionPolicy) and the
            // date line flips once through itself.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                let now = DateSky.band(at: AppClock.now)
                if now != band {
                    withTesseraAnimation(.easeInOut(duration: 0.6), reduceMotion: reduceMotion) { band = now }
                    bandPass()
                }
            }
        }
        .onChange(of: lines) { old, new in transition(from: old, to: new) }
    }

    @ViewBuilder
    private func lineView(_ li: Int, _ line: [DepartureSegment]) -> some View {
        let lineCells = li < cells.count ? cells[li] : Self.cells(line)
        let starts = DepartureSteps.starts(line)
        let plain = TrailingWrap(spacing: 6, lineSpacing: 2.4) {
            ForEach(Array(line.enumerated()), id: \.offset) { _, seg in
                plainSegment(seg, li: li)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHidden(true)
        if reduceMotion {
            // Reduce Motion: a plain swap, no letters.
            plain
        } else if typeSize.isAccessibilitySize {
            // Accessibility sizes: plain wrapping words that snap.
            plain
        } else {
            // The letters always click forward (sheet 200), on one line in its own row: the words are chosen to fit,
            // never shrunk, wrapped or crossfaded.
            HStack(spacing: 0) {
                // The words, 6 pt apart; the letters going away sit after them with no gap, so the row's right edge
                // is the last word's (x 378 on Bridge).
                HStack(spacing: 6) {
                    ForEach(units(of: line, starts: starts)) { unit in
                        unitView(unit, cells: lineCells, li: li)
                            .fixedSize()
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityHidden(true)
                // Letters the new line no longer has go at once: the row's right edge stays at the last word (x 378),
                // and nothing draws past it (Kaushik, Oct 26).
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func droppedStyle(_ kind: DepartureSegment.Kind) -> AnyShapeStyle {
        switch kind {
        case let .app(app): AnyShapeStyle(app.accent)
        case .sky: AnyShapeStyle(LinearGradient(colors: [SkyWordStyle.first, SkyWordStyle.second],
                                                startPoint: .leading, endPoint: .trailing))
        case .day: AnyShapeStyle(DateSky.gradient(band: band))
        default: AnyShapeStyle(Theme.Colors.ink)
        }
    }

    /// The pieces a line wraps by: each plain or number word on its own, a door (an app word) whole.
    private struct Unit: Identifiable {
        let id: Int
        let seg: DepartureSegment
        let words: [(text: String, start: Int)]
    }

    private func units(of line: [DepartureSegment], starts: [Int]) -> [Unit] {
        var out: [Unit] = []
        for (k, seg) in line.enumerated() {
            var words: [(text: String, start: Int)] = []
            var offset = 0
            for word in seg.text.split(separator: " ", omittingEmptySubsequences: false) {
                words.append((String(word), starts[k] + offset))
                offset += word.count + 1
            }
            let whole: Bool = switch seg.kind {
            case .app, .sky: true
            default: seg.opens
            }
            if whole {
                out.append(Unit(id: out.count, seg: seg, words: words))
            } else {
                for word in words where !word.text.isEmpty {
                    out.append(Unit(id: out.count, seg: seg, words: [word]))
                }
            }
        }
        return out
    }

    @ViewBuilder
    private func unitView(_ unit: Unit, cells: [Cell], li: Int) -> some View {
        let seg = unit.seg
        // The flap letters are drawing only: the board is one accessibility element with the whole text and its doors
        // as actions, so no letter cell reads (or measures) over its neighbours.
        let content = HStack(spacing: 6) {
            ForEach(Array(unit.words.enumerated()), id: \.offset) { _, word in
                HStack(spacing: 0) {
                    ForEach(0 ..< word.text.count, id: \.self) { k in
                        let cell = word.start + k < cells.count ? cells[word.start + k] : Cell(shown: " ")
                        Text(String(cell.shown))
                            .font(font(for: seg.kind))
                            .fixedSize()
                            .frame(width: cell.width)
                            .scaleEffect(x: 1, y: cell.squash ? 0.08 : 1, anchor: .center)
                    }
                }
            }
        }
        let key = "\(li)-\(unit.words.first?.start ?? 0)"
        let door = content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames.byKey[key] = $0 }
        switch seg.kind {
        case let .app(app):
            Button {
                taps += 1
                open(li, frames.byKey[key] ?? .zero)
            } label: { door }
                .buttonStyle(MosaicWordStyle(accent: app.accent))
        case .sky:
            Button {
                taps += 1
                open(li, frames.byKey[key] ?? .zero)
            } label: {
                if let weather = seg.weather {
                    // Home 236 v2.4: a weather word wears its cloud's colour and its one effect.
                    door.weatherWord(weather, night: WeatherKind.isNight(at: AppClock.now))
                } else {
                    door
                }
            }
            .buttonStyle(SkyWordStyle(underline: seg.weather
                    .map { $0.colour(night: WeatherKind.isNight(at: AppClock.now)) }))
        case .day:
            Button {
                taps += 1
                open(li, frames.byKey[key] ?? .zero)
            } label: {
                door.foregroundStyle(DateSky.gradient(band: band))
            }
            .buttonStyle(.plain)
        case .number where seg.opens, .plain where seg.opens:
            Button {
                taps += 1
                open(li, frames.byKey[key] ?? .zero)
            } label: {
                door.foregroundStyle(Theme.Colors.ink)
                    .contentShape(.interaction, Rectangle().inset(by: -8))
            }
            .buttonStyle(.plain)
        default:
            content.foregroundStyle(Theme.Colors.ink)
        }
    }

    /// A segment as plain text (Reduce Motion and the accessibility sizes), with its door where it has one.
    @ViewBuilder
    private func plainSegment(_ seg: DepartureSegment, li: Int) -> some View {
        let text = Text(seg.text).font(font(for: seg.kind))
        switch seg.kind {
        case let .app(app):
            Button { taps += 1; open(li, .zero) } label: { text }.buttonStyle(MosaicWordStyle(accent: app.accent))
        case .sky:
            Button { taps += 1; open(li, .zero) } label: {
                text.foregroundStyle(seg.weather.map { $0.colour(night: WeatherKind.isNight(at: AppClock.now)) }
                    ?? Theme.Colors.ink)
            }
            .buttonStyle(SkyWordStyle(underline: seg.weather
                    .map { $0.colour(night: WeatherKind.isNight(at: AppClock.now)) }))
        case .day:
            Button { taps += 1; open(li, .zero) } label: { text.foregroundStyle(DateSky.gradient(band: band)) }
                .buttonStyle(.plain)
        default:
            if seg.opens {
                Button { taps += 1; open(li, .zero) } label: {
                    text.foregroundStyle(Theme.Colors.ink)
                }
                .buttonStyle(.plain)
            } else {
                text.foregroundStyle(Theme.Colors.ink)
            }
        }
    }

    private func font(for kind: DepartureSegment.Kind) -> Font {
        switch kind {
        case .number: Theme.numeral(Self.size, weight: .light)
        case .app, .sky: Theme.voice(size: Self.size * 1.12).weight(.bold)
        case .day: Theme.voice(size: Self.size).weight(.medium)
        case .plain: Theme.voice(size: Self.size)
        }
    }

    /// One cell per character of the line, in order, with a space between runs.
    @MainActor
    private static func cells(_ line: [DepartureSegment]) -> [Cell] {
        var out: [Cell] = []
        for (index, seg) in line.enumerated() {
            if index > 0 {
                out.append(Cell(shown: " "))
            }
            out += seg.text.map { Cell(shown: $0, width: CellMetrics.width(of: $0, kind: seg.kind), kind: seg.kind) }
        }
        return out
    }

    private func transition(from _: [[DepartureSegment]], to new: [[DepartureSegment]]) {
        generation += 1
        let gen = generation
        // A newer change cancels the older one: the cells snap to what that one was heading for first.
        if !lastTarget.isEmpty {
            cells = lastTarget
        }
        let target = new.map { Self.cells($0) }
        lastTarget = target
        if reduceMotion || typeSize.isAccessibilitySize || cells.isEmpty {
            cells = target
            return
        }
        var current = cells
        while current.count < target.count {
            current.append([])
        }
        var longest = 0
        var longestByLine: [Int: Int] = [:]
        for (li, want) in target.enumerated() {
            var old = current[li]
            // Added letters flip in from a space; kept ones now own their final widths; dropped ones keep theirs.
            while old.count < want.count {
                old.append(Cell(shown: " "))
            }
            for k in want.indices {
                old[k].width = want[k].width
                old[k].kind = want[k].kind
            }
            current[li] = old
            let span = max(old.count, want.count)
            for k in 0 ..< span {
                let was = old[k].shown
                let final = k < want.count ? want[k].shown : " "
                let steps = DepartureSteps.sequence(from: was, to: final)
                if steps.isEmpty {
                    continue
                }
                let finish = DepartureSteps.delay(line: li, index: k) + steps.count * DepartureSteps.stepMS
                longest = max(longest, finish)
                longestByLine[li] = max(longestByLine[li] ?? 0, finish)
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(DepartureSteps.delay(line: li, index: k)))
                    for step in steps {
                        guard gen == generation else { return }
                        set(li, k, shown: step, squash: true)
                        try? await Task.sleep(for: .milliseconds(16))
                        // The sheet's own flip curve: scaleY 0.08 to 1 over 70 ms on cubic-bezier(.3, .7, .4, 1).
                        withTesseraAnimation(
                            .timingCurve(0.3, 0.7, 0.4, 1, duration: Double(DepartureSteps.flipMS) / 1000),
                            reduceMotion: false
                        ) { set(li, k, shown: step, squash: false) }
                        try? await Task.sleep(for: .milliseconds(DepartureSteps.stepMS - 16))
                    }
                    guard gen == generation else { return }
                    set(li, k, shown: final, squash: false)
                }
            }
        }
        cells = current
        // Dropped letters collapse only after the whole pass, so the row never shifts while it runs.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(longest + DepartureSteps.flipMS + 20))
            guard gen == generation else { return }
            for (li, want) in target.enumerated() where li < cells.count && cells[li].count > want.count {
                cells[li] = Array(cells[li].prefix(want.count))
            }
        }
        // One soft tap when the last letter lands, only while Home is on screen.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(longest + DepartureSteps.flipMS))
            if gen == generation, scenePhase == .active, onScreen {
                landed += 1
            }
        }
    }

    /// The band changed: each letter of the date line squashes and settles again, left to right, on the flip curve.
    private func bandPass() {
        guard !reduceMotion, !typeSize.isAccessibilitySize, !cells.isEmpty else { return }
        let gen = generation
        for k in cells[0].indices where cells[0][k].shown != " " {
            let shown = cells[0][k].shown
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(DepartureSteps.delay(line: 0, index: k)))
                guard gen == generation, !cells.isEmpty, k < cells[0].count else { return }
                set(0, k, shown: shown, squash: true)
                try? await Task.sleep(for: .milliseconds(16))
                withTesseraAnimation(
                    .timingCurve(0.3, 0.7, 0.4, 1, duration: Double(DepartureSteps.flipMS) / 1000),
                    reduceMotion: false
                ) { set(0, k, shown: shown, squash: false) }
            }
        }
    }

    private func set(_ li: Int, _ k: Int, shown: Character, squash: Bool) {
        guard li < cells.count else { return }
        if k >= cells[li].count {
            cells[li] += Array(repeating: Cell(shown: " "), count: k - cells[li].count + 1)
        }
        cells[li][k] = Cell(shown: shown, squash: squash, width: cells[li][k].width, kind: cells[li][k].kind)
    }
}

/// The "Sunset" word: the mosaic's own sky as a two-stop text gradient (C9772E to B0466A by day, E8A06A to E07A9A at
/// night), with a 1 pt underline at 5 pt in the second stop.
struct SkyWordStyle: ButtonStyle {
    /// A weather word's underline takes its cloud's colour; nil keeps the sky's second stop.
    var underline: Color?

    static var first: Color {
        Theme.Colors.Accent.skyFrom
    }

    static var second: Color {
        Theme.Colors.Accent.skyTo
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(LinearGradient(
                colors: [Self.first, Self.second],
                startPoint: .leading,
                endPoint: .trailing
            ))
            // No decorative underline at rest (landing contract §10, QA on 283): a 1 pt line only while pressed.
            .overlay(alignment: .bottom) {
                Rectangle().fill(underline ?? Self.second).frame(height: 1).offset(y: 5)
                    .opacity(configuration.isPressed ? 1 : 0)
            }
            .contentShape(.interaction, Rectangle().inset(by: -8))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// The date's colour (sheet 216): a left-to-right gradient of the hour's sky, drawn like the Sunset word. Light values
/// on a light look, dark values on a dark one.
enum DateSky {
    enum Band: Int {
        case morning, day, evening, night
    }

    static func band(at date: Date, calendar: Calendar = .current) -> Band {
        switch calendar.component(.hour, from: date) {
        case 5 ..< 11: .morning
        case 11 ..< 17: .day
        case 17 ..< 20: .evening
        default: .night
        }
    }

    /// (light from, light to, dark from, dark to) for each band.
    static func stops(_ band: Band) -> (UInt32, UInt32, UInt32, UInt32) {
        switch band {
        case .morning: (0xA9621A, 0xC2507A, 0xE6A97E, 0xE07FA0)
        case .day: (0x2F6FD0, 0x237E92, 0x6FA4FF, 0x5CC6D2)
        case .evening: (0xBF6A22, 0xA33C62, 0xE8A06A, 0xF286A6)
        case .night: (0x4B3FA8, 0x2D3F7A, 0xA79CF0, 0x7E95D8)
        }
    }

    static func gradient(at date: Date) -> LinearGradient {
        gradient(band: band(at: date))
    }

    static func gradient(band: Band) -> LinearGradient {
        let s = stops(band)
        return LinearGradient(colors: [Color(light: s.0, dark: s.2), Color(light: s.1, dark: s.3)],
                              startPoint: .leading, endPoint: .trailing)
    }
}

/// The width a letter takes in its own face, so each cell can be fixed to the letter it will end on. A face that cannot
/// be
/// found leaves the cell at its natural width.
@MainActor
enum CellMetrics {
    private struct Key: Hashable {
        let character: Character
        let tag: UInt8
    }

    private static var cache: [Key: CGFloat] = [:]

    /// The measured width of a line as the board lays it out: each letter in its own face, one 6 pt gap between
    /// words. A face that cannot be found is estimated, so the rule holds in a test host too.
    static func lineWidth(_ line: [DepartureSegment]) -> CGFloat {
        var total: CGFloat = 0
        var words = 0
        for seg in line {
            for word in seg.text.split(separator: " ") {
                words += 1
                for ch in word {
                    total += width(of: ch, kind: seg.kind) ?? estimate(kind: seg.kind)
                }
            }
        }
        return total + CGFloat(max(words - 1, 0)) * 6
    }

    private static func estimate(kind: DepartureSegment.Kind) -> CGFloat {
        switch kind {
        case .app, .sky: DepartureBoard.size * 1.12 * 0.58
        default: DepartureBoard.size * 0.53
        }
    }

    static func width(of character: Character, kind: DepartureSegment.Kind) -> CGFloat? {
        guard character != " " else { return nil }
        let isNumber = if case .number = kind {
            true
        } else {
            false
        }
        // A plain value key: building a string from the kind (an enum with a payload) cast through String(describing:)
        // for every letter, which was slow enough on launch to trip the scene-create watchdog under load.
        let tag: UInt8 = switch kind {
        case .number: 0
        case .plain: 1
        case .app, .sky: 2
        case .day: 3
        }
        let key = Key(character: character, tag: tag)
        if let cached = cache[key] {
            return cached
        }
        let family = isNumber ? "Outfit" : "Figtree"
        guard !UIFont.fontNames(forFamilyName: family).isEmpty else {
            // The fit and the fixed cells depend on these faces: a build without them must say so, loudly (a unit-test
            // host does not load the app's fonts, so it estimates).
            assert(FeatureFlagStore.isTestHost, "\(family) metrics not found: the board cannot be measured")
            return nil
        }
        let (size, weight): (CGFloat, UIFont.Weight) = switch kind {
        case .number: (DepartureBoard.size, .light)
        case .app, .sky: (DepartureBoard.size * 1.12, .bold)
        case .day: (DepartureBoard.size, .medium)
        case .plain: (DepartureBoard.size, .regular)
        }
        let descriptor = UIFontDescriptor(fontAttributes: [.family: family])
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        let width = NSAttributedString(string: String(character), attributes: [.font: UIFont(descriptor: descriptor,
                                                                                             size: size)])
            .size().width.rounded(.up)
        cache[key] = width
        return width
    }
}
