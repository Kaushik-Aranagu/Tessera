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
    }

    var text: String
    var kind: Kind
    /// A door (sheet 211): an app word, or a number that belongs to a clause with an app word, opens its thing.
    var opens = false
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var cells: [[Cell]] = []
    @State private var generation = 0
    @State private var landed = 0
    @State private var onScreen = false
    @State private var taps = 0
    /// Where each door word sits, kept outside the view state so a layout pass does not redraw the board.
    @State private var frames = DoorFrames()

    final class DoorFrames {
        var byKey: [String: CGRect] = [:]
    }

    struct Cell: Equatable {
        var shown: Character
        var squash: Bool = false
    }

    private var finalText: String {
        lines.map { $0.map(\.text).joined(separator: " ") }.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: Self.lineGap) {
            ForEach(Array(lines.enumerated()), id: \.offset) { li, line in
                lineView(li, line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(finalText)
        .accessibilityActions {
            // Each door is a button: "Push day, opens Training".
            ForEach(Array(lines.enumerated()), id: \.offset) { li, line in
                ForEach(Array(line.enumerated()), id: \.offset) { _, seg in
                    if seg.opens, case let .app(app) = seg.kind {
                        Button("\(seg.text), opens \(app.rawValue)") { open(li, .zero) }
                    }
                }
            }
        }
        .tesseraFeedback(.made, trigger: landed)
        .tesseraFeedback(.made, trigger: taps)
        .onAppear {
            onScreen = true
            if cells.isEmpty {
                cells = lines.map { Self.cells($0) }
            }
        }
        .onDisappear { onScreen = false }
        .onChange(of: lines) { old, new in transition(from: old, to: new) }
    }

    @ViewBuilder
    private func lineView(_ li: Int, _ line: [DepartureSegment]) -> some View {
        let lineCells = li < cells.count ? cells[li] : Self.cells(line)
        let starts = DepartureSteps.starts(line)
        let plain = TrailingWrap(spacing: 6, lineSpacing: 2.4) {
            ForEach(Array(line.enumerated()), id: \.offset) { _, seg in
                segmentView(seg, cells: nil, from: 0, li: li)
            }
        }
        if reduceMotion {
            // Reduce Motion: the whole line crossfades (150 ms) and nothing flips.
            plain
                .id(line.map(\.text).joined(separator: "|"))
                .transition(.opacity)
                .tesseraAnimation(.easeInOut(duration: 0.15), value: line)
        } else if typeSize.isAccessibilitySize {
            // Accessibility sizes: plain wrapping words that snap.
            plain
        } else {
            // Letters in one row while the line fits; a long line wraps as plain words instead.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    ForEach(Array(line.enumerated()), id: \.offset) { k, seg in
                        segmentView(seg, cells: lineCells, from: starts[k], li: li)
                        if k < line.count - 1 {
                            let at = starts[k] + seg.text.count
                            Text(String(at < lineCells.count ? lineCells[at].shown : " "))
                                .font(Theme.voice(size: Self.size))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                plain
            }
        }
    }

    @ViewBuilder
    private func segmentView(_ seg: DepartureSegment, cells: [Cell]?, from: Int, li: Int) -> some View {
        let content = HStack(spacing: 0) {
            if let cells {
                ForEach(0 ..< seg.text.count, id: \.self) { k in
                    let cell = from + k < cells.count ? cells[from + k] : Cell(shown: " ")
                    Text(String(cell.shown))
                        .font(font(for: seg.kind))
                        .scaleEffect(x: 1, y: cell.squash ? 0.08 : 1, anchor: .center)
                }
            } else {
                Text(seg.text).font(font(for: seg.kind))
            }
        }
        let key = "\(li)-\(from)"
        let door = content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames.byKey[key] = $0 }
        switch seg.kind {
        case let .app(app):
            Button {
                taps += 1
                open(li, frames.byKey[key] ?? .zero)
            } label: { door }
                .buttonStyle(MosaicWordStyle(accent: app.accent))
        case .number where seg.opens:
            Button {
                taps += 1
                open(li, frames.byKey[key] ?? .zero)
            } label: { door.foregroundStyle(Theme.Colors.ink) }
                .buttonStyle(.plain)
        case .number:
            content.foregroundStyle(Theme.Colors.ink)
        case .plain:
            content.foregroundStyle(Theme.Colors.ink)
        }
    }

    private func font(for kind: DepartureSegment.Kind) -> Font {
        switch kind {
        case .number: Theme.numeral(Self.size, weight: .light)
        case .app: Theme.voice(size: Self.size * 1.12).weight(.semibold)
        case .plain: Theme.voice(size: Self.size)
        }
    }

    /// One cell per character of the line, in order, with a space between runs.
    private static func cells(_ line: [DepartureSegment]) -> [Cell] {
        DepartureSteps.flat(line).map { Cell(shown: $0) }
    }

    private func transition(from _: [[DepartureSegment]], to new: [[DepartureSegment]]) {
        generation += 1
        let gen = generation
        let target = new.map { Self.cells($0) }
        if reduceMotion || typeSize.isAccessibilitySize || cells.isEmpty {
            cells = target
            return
        }
        var current = cells
        while current.count < target.count {
            current.append([])
        }
        cells = current
        var longest = 0
        for (li, line) in target.enumerated() {
            let before = li < current.count ? current[li] : []
            for (k, cell) in line.enumerated() {
                let was = k < before.count ? before[k].shown : " "
                let steps = DepartureSteps.sequence(from: was, to: cell.shown)
                if steps.isEmpty {
                    continue
                }
                longest = max(longest, DepartureSteps.delay(line: li, index: k) + steps.count * DepartureSteps.stepMS)
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(DepartureSteps.delay(line: li, index: k)))
                    for step in steps {
                        guard gen == generation else { return }
                        set(li, k, shown: step, squash: true)
                        try? await Task.sleep(for: .milliseconds(16))
                        withTesseraAnimation(.linear(duration: Double(DepartureSteps.flipMS) / 1000),
                                             reduceMotion: false) { set(li, k, shown: step, squash: false) }
                        try? await Task.sleep(for: .milliseconds(DepartureSteps.stepMS))
                    }
                    guard gen == generation else { return }
                    set(li, k, shown: cell.shown, squash: false)
                }
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

    private func set(_ li: Int, _ k: Int, shown: Character, squash: Bool) {
        guard li < cells.count else { return }
        if k >= cells[li].count {
            cells[li] += Array(repeating: Cell(shown: " "), count: k - cells[li].count + 1)
        }
        cells[li][k] = Cell(shown: shown, squash: squash)
    }
}
