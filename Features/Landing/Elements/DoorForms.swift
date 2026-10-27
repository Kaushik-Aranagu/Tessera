import CoreGraphics
import SwiftUI
import UIKit

// Sheet 292, many doors (drawn on the Log's eight). Pure layout in the dial's own 160 x 120 frame, so the
// conformance suite, the stage and the view all place the same words.

/// The dial's three forms.
enum DoorsForm: String, CaseIterable, Sendable {
    case reel, index, sentence
}

extension EnvironmentValues {
    /// The form the landing dial takes. The shell (or Tess's reshape) sets it; the default is the designed reel.
    @Entry var doorsForm: DoorsForm = .reel
}

/// Measures a display line the way the dial sets it (Figtree where registered, the system face otherwise), with 3%
/// air so a run never measures narrower than it draws.
enum DoorText {
    static func width(_ text: String, size: CGFloat, bold: Bool) -> CGFloat {
        let base = UIFont(name: "Figtree-Variable", size: size) ?? UIFont.systemFont(ofSize: size)
        let font = bold ? UIFont.systemFont(ofSize: size, weight: .semibold) : base
        let raw = (text as NSString).size(withAttributes: [.font: font]).width
        return ceil(raw * 1.03)
    }
}

/// One door word placed in the dial frame (absolute, in the shell's 402 x 874 space).
struct DoorPlacement: Equatable, Sendable {
    var id: String
    var text: String
    var rect: CGRect
    var size: CGFloat
    var bold: Bool
    var ink: ElementInk
    /// Part of a joiner ("and 4 more") rather than a door's own name.
    var isJoiner = false
    /// A tap on the joiner turns the place into the index form.
    var opensIndex = false
}

struct DoorFormLayout: Equatable, Sendable {
    var form: DoorsForm
    var placements: [DoorPlacement]
    /// Doors folded into "and N more".
    var summarised: Int
    /// Doors neither placed nor folded.
    var lost: Int
    var clipped: Bool
}

enum DoorForms {
    /// The dial's frame on every landing (218, 640, 160 x 120).
    static let frame = LandingPlace.Doors.dial
    static let indexSizes: [CGFloat] = [15, 13]
    static let indexGaps: [CGFloat] = [14, 8]
    static let sentenceSizes: [CGFloat] = [19, 17, 15]
    static let sentenceCounts = [4, 3, 2]
    /// Four rows in 120 pt.
    static let indexPitch: CGFloat = 30
    static let linePitch: CGFloat = 24
    static let maxLines = 5

    /// The form specs as the element template reads them (sizes designed first; floor 13).
    static let specs: [ElementFormSpec] = [
        ElementFormSpec(name: "reel", sizeSteps: [26]),
        ElementFormSpec(name: "index", sizeSteps: indexSizes, densitySteps: ["14", "8"], factsSteps: 1),
        ElementFormSpec(name: "sentence", sizeSteps: sentenceSizes, factsSteps: sentenceCounts.count),
    ]

    // MARK: Index

    /// Two columns of four when more than five doors, else one column. Each column is right-aligned and as wide as
    /// its longest name; the pair sits on the frame's right edge. `size` and `gap` come from the fix ladder.
    static func index(names: [(id: String, name: String)], focus: Int, size: CGFloat, gap: CGFloat, scale: CGFloat = 1)
        -> DoorFormLayout
    {
        let columns = names.count > 5 ? 2 : 1
        let perColumn = columns == 2 ? 4 : max(names.count, 1)
        let pitch = columns == 2 ? indexPitch : min(indexPitch, frame.height / CGFloat(perColumn))
        let scaled = size * scale
        var placements: [DoorPlacement] = []
        var widths: [CGFloat] = []
        for column in 0 ..< columns {
            let slice = names.enumerated().filter { $0.offset / perColumn == column }
            widths
                .append(slice.map { DoorText.width($0.element.name, size: scaled, bold: $0.offset == focus) }
                    .max() ?? 0)
        }
        // The right column ends on the frame's right edge; the left one sits a gap before it.
        var right = frame.maxX
        var rights = Array(repeating: CGFloat(0), count: columns)
        for column in stride(from: columns - 1, through: 0, by: -1) {
            rights[column] = right
            right -= widths[column] + gap
        }
        for (offset, door) in names.enumerated() {
            let column = offset / perColumn
            guard column < columns else { continue }
            let row = offset % perColumn
            let isFocus = offset == focus
            let width = DoorText.width(door.name, size: scaled, bold: isFocus)
            let x = rights[column] - width
            let y = frame.minY + CGFloat(row) * pitch + (pitch - scaled * 1.25) / 2
            placements.append(DoorPlacement(id: door.id, text: door.name,
                                            rect: CGRect(x: x, y: y, width: width, height: scaled * 1.25),
                                            size: scaled, bold: isFocus, ink: isFocus ? .room : .ink))
        }
        let placed = placements.count
        let outside = placements.contains { !frame.contains($0.rect) }
        return DoorFormLayout(form: .index, placements: placements, summarised: 0,
                              lost: names.count - placed, clipped: outside)
    }

    /// The tap area of an index door: its column cell, wide enough to tap and as tall as the row pitch.
    static func indexTarget(_ placement: DoorPlacement, pitch: CGFloat = indexPitch) -> CGRect {
        let width = max(placement.rect.width, ElementConformance.targetLong)
        let x = min(placement.rect.maxX, frame.maxX) - width
        return CGRect(x: max(x, frame.minX), y: placement.rect.midY - pitch / 2, width: width, height: pitch)
    }

    // MARK: Sentence

    /// "Notes, Lists, Today, Plan and 4 more": at most `count` names then "and N more" in ink 2, no full stop,
    /// wrapped right-aligned in 160 pt, in at most five 24 pt lines.
    static func sentence(names: [(id: String, name: String)], focus: Int, size: CGFloat, count: Int, scale: CGFloat = 1)
        -> DoorFormLayout
    {
        let scaled = size * scale
        let pitch = max(linePitch, ceil(scaled * 1.25))
        let shown = Array(names.prefix(count))
        let more = names.count - shown.count
        // Tokens, each unbreakable: a name (with its comma) or a joiner in ink 2.
        struct Token {
            var id: String; var text: String; var ink: ElementInk; var bold: Bool; var joiner: Bool; var more: Bool
        }
        var tokens: [Token] = []
        for (index, door) in shown.enumerated() {
            let last = index == shown.count - 1
            let comma = last || (more == 0 && index == shown.count - 2) ? "" : ","
            tokens.append(Token(id: door.id, text: door.name + comma, ink: index == focus ? .room : .ink,
                                bold: index == focus, joiner: false, more: false))
            if more == 0, index == shown.count - 2 {
                tokens.append(Token(id: "and", text: "and", ink: .ink2, bold: false, joiner: true, more: false))
            }
        }
        if more > 0 {
            tokens.append(Token(
                id: "more",
                text: "and \(more) more",
                ink: .ink2,
                bold: false,
                joiner: true,
                more: true
            ))
        }
        let space = DoorText.width(" ", size: scaled, bold: false)
        var lines: [[(token: Token, width: CGFloat)]] = [[]]
        var used: CGFloat = 0
        for token in tokens {
            let width = DoorText.width(token.text, size: scaled, bold: token.bold)
            let need = used == 0 ? width : used + space + width
            if need > frame.width, used > 0 {
                lines.append([(token, width)])
                used = width
            } else {
                lines[lines.count - 1].append((token, width))
                used = need
            }
        }
        var placements: [DoorPlacement] = []
        var clipped = lines.count > maxLines || lines.count * Int(pitch) > Int(frame.height)
        for (row, line) in lines.enumerated() {
            let total = line.reduce(0) { $0 + $1.width } + space * CGFloat(max(line.count - 1, 0))
            var x = frame.maxX - total
            for entry in line {
                let y = frame.minY + CGFloat(row) * pitch + (pitch - scaled * 1.25) / 2
                let rect = CGRect(x: x, y: y, width: entry.width, height: scaled * 1.25)
                if rect.minX < frame.minX - 0.5 {
                    clipped = true
                }
                placements.append(DoorPlacement(id: entry.token.id, text: entry.token.text, rect: rect, size: scaled,
                                                bold: entry.token.bold, ink: entry.token.ink,
                                                isJoiner: entry.token.joiner,
                                                opensIndex: entry.token.more))
                x += entry.width + space
            }
        }
        return DoorFormLayout(form: .sentence, placements: placements, summarised: more, lost: 0, clipped: clipped)
    }

    /// A sentence target: the run and a little air either side, one line pitch tall. Names tile the line.
    static func sentenceTarget(_ placement: DoorPlacement) -> CGRect {
        let pitch = max(linePitch, ceil(placement.size * 1.25))
        return CGRect(x: placement.rect.minX - 2, y: placement.rect.midY - pitch / 2,
                      width: placement.rect.width + 4, height: pitch)
    }

    // MARK: The fix ladder, used by the view and the suite alike

    /// The best layout for these doors in this form: the designed size, then the size steps down (never below the
    /// floor), then density (the gap), then fewer names; nil when nothing fits (the view then keeps the reel).
    static func fit(_ form: DoorsForm, names: [(id: String, name: String)], focus: Int, scale: CGFloat)
        -> DoorFormLayout?
    {
        func ok(_ layout: DoorFormLayout) -> Bool {
            guard layout.lost == 0, !layout.clipped else { return false }
            let rects = layout.placements.map(\.rect)
            for (index, rect) in rects.enumerated()
                where rects[(index + 1)...].contains(where: { $0.intersects(rect) })
            {
                return false
            }
            return true
        }
        switch form {
        case .reel:
            return nil
        case .index:
            // Size steps down first, then the gap narrows (sheet 292).
            let steps: [(CGFloat, CGFloat)] = [(indexSizes[0], indexGaps[0]), (indexSizes[1], indexGaps[0]),
                                               (indexSizes[1], indexGaps[1])]
            for (size, gap) in steps {
                let layout = index(names: names, focus: focus, size: size, gap: gap, scale: scale)
                if ok(layout) {
                    return layout
                }
            }
            return nil
        case .sentence:
            // Type steps down from 19 to 15, then fewer names before "and N more".
            let last = sentenceSizes[sentenceSizes.count - 1]
            let steps: [(CGFloat, Int)] = sentenceSizes.map { ($0, sentenceCounts[0]) }
                + sentenceCounts.dropFirst().map { (last, $0) }
            for (size, count) in steps {
                let layout = sentence(names: names, focus: focus, size: size, count: count, scale: scale)
                if ok(layout) {
                    return layout
                }
            }
            return nil
        }
    }

    /// The Log's eight (sheet 292), used by the board and the tests.
    static let sampleNames: [(id: String, name: String)] = [
        ("all", "All notes"), ("loose", "Loose"), ("private", "Private"), ("today", "Today"),
        ("week", "This week"), ("projects", "Projects"), ("reading", "Reading"), ("ideas", "Ideas"),
    ]
}
