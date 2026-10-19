import SwiftUI
import TesseraCore

/// Design's original vector muscle figure (sheet 88/91, board 84): front and back, crisp, never blurred or soft.
/// Worked parts take the area colour (primary full, secondary 70%); a part that is not worked is a bare outline.
/// It is information, not decoration: hidden from VoiceOver (the rows say the same), no glow, no stagger.
enum MuscleRole: Equatable, Sendable {
    case primary, secondary

    var strength: Double {
        self == .primary ? 1 : 0.7
    }
}

/// SVG path data of the absolute commands the figure uses: M, L, C and Z.
enum FigurePath {
    /// Command letters and numbers, whether or not a space separates them ("M92 66" and "M 92 66" read the same).
    static func tokens(_ data: String) -> [String] {
        var result: [String] = []
        var number = ""
        func flush() {
            if !number.isEmpty {
                result.append(number)
            }
            number = ""
        }
        for character in data {
            if character.isLetter {
                flush()
                result.append(String(character))
            } else if character == " " || character == "," {
                flush()
            } else if character == "-", !number.isEmpty {
                flush()
                number = "-"
            } else {
                number.append(character)
            }
        }
        flush()
        return result
    }

    static func path(_ data: String) -> Path {
        var path = Path()
        let tokens = Self.tokens(data)
        var index = 0
        func number() -> CGFloat? {
            guard index < tokens.count, let value = Double(tokens[index]) else { return nil }
            index += 1
            return CGFloat(value)
        }
        func point() -> CGPoint? {
            guard let x = number(), let y = number() else { return nil }
            return CGPoint(x: x, y: y)
        }
        var command = ""
        while index < tokens.count {
            if Double(tokens[index]) == nil {
                command = tokens[index]
                index += 1
            }
            switch command {
            case "M":
                guard let to = point() else { return path }
                path.move(to: to)
            case "L":
                guard let to = point() else { return path }
                path.addLine(to: to)
            case "C":
                guard let first = point(), let second = point(), let to = point() else { return path }
                path.addCurve(to: to, control1: first, control2: second)
            case "Z":
                path.closeSubpath()
            default:
                return path
            }
        }
        return path
    }
}

/// The phone stores 18 muscle names; the rows, the figure's VoiceOver line and the Routine line show plain US words
/// (imagery-88.md, "Muscle label map"). The stored name never changes; only what is shown does.
enum MuscleWords {
    static func shown(_ stored: String) -> String {
        switch stored.lowercased() {
        case "front delts": "Front shoulders"
        case "side delts": "Side shoulders"
        case "rear delts": "Rear shoulders"
        case "upper back": "Upper back"
        case "lower back": "Lower back"
        case "adductors": "Inner thighs"
        case "abductors": "Outer hips"
        default: stored
        }
    }

    /// "Works chest, shoulders and triceps": the three shoulder names fold into "shoulders", in the shown words.
    static func works(_ stored: [String]) -> String {
        var words: [String] = []
        for name in stored {
            let shown = shown(name)
            let word = shown.hasSuffix("shoulders") ? "shoulders" : shown.lowercased()
            if !words.contains(word) {
                words.append(word)
            }
        }
        // Design's wording has no Oxford comma ("chest, shoulders and triceps"), whatever the locale's list style.
        guard let last = words.last else { return "" }
        let head = words.dropLast().joined(separator: ", ")
        return head.isEmpty ? "Works \(last)" : "Works \(head) and \(last)"
    }
}

/// Region ids are the stored muscle names without spaces; Side Delts has no region of its own and rides the delt
/// that shows on that side.
enum MuscleFigureMap {
    static func regionID(for muscle: MuscleSeed, back: Bool) -> String? {
        switch muscle {
        case .sideDelts: back ? "RearDelts" : "FrontDelts"
        default: muscle.name.replacingOccurrences(of: " ", with: "")
        }
    }

    /// Whether a stored muscle title is the one a region stands for (Side Delts rides the delt on that side).
    static func matches(_ title: String, regionID: String) -> Bool {
        guard let seed = MuscleSeed.allCases.first(where: { $0.name.lowercased() == title.lowercased() }) else {
            return false
        }
        return regionID == Self.regionID(for: seed, back: false) || regionID == Self.regionID(for: seed, back: true)
    }

    /// The role of each region id on one side, for stored muscle titles.
    static func roles(_ muscles: [(name: String, role: MuscleRole)], back: Bool) -> [String: MuscleRole] {
        var result: [String: MuscleRole] = [:]
        for muscle in muscles {
            guard let seed = MuscleSeed.allCases.first(where: { $0.name.lowercased() == muscle.name.lowercased() }),
                  let id = regionID(for: seed, back: back) else { continue }
            if result[id] != .primary {
                result[id] = muscle.role
            }
        }
        return result
    }
}

/// Which side of the body to show for an exercise (Design brief 1, sheet 107): count the primary muscles that have a
/// region on the front and on the back (Side Delts ride the front delts on the front and the rear delts on the back;
/// Calves and Forearms are ignored when counting the back). More on the back than the front is the back figure;
/// otherwise, and on a tie, the front.
enum MuscleSide {
    static func showsBack(_ muscles: [(name: String, role: MuscleRole)]) -> Bool {
        let front = Set(MuscleFigureArt.frontRegions.map(\.id))
        let back = Set(MuscleFigureArt.backRegions.map(\.id))
        var onFront = 0, onBack = 0
        for muscle in muscles where muscle.role == .primary {
            guard let seed = MuscleSeed.allCases.first(where: { $0.name.lowercased() == muscle.name.lowercased() })
            else { continue }
            if let id = MuscleFigureMap.regionID(for: seed, back: false), front.contains(id) {
                onFront += 1
            }
            if seed != .calves, seed != .forearms, let id = MuscleFigureMap.regionID(for: seed, back: true),
               back.contains(id)
            {
                onBack += 1
            }
        }
        return onBack > onFront
    }
}

/// The colour a routine's figures wear: Push vermilion, Pull cobalt, Legs cadmium; anything mixed or unknown is the
/// Training colour. It follows the routine's own kind (Core's `RoutineKind`); a routine with none falls back to what
/// its day's primary muscles say.
enum MuscleTint {
    static func colour(kind: RoutineKind?) -> Color {
        switch kind {
        case .push: Theme.Colors.live
        case .pull: Theme.Colors.tess
        case .legs: Theme.Colors.now
        case nil: Theme.Colors.training
        }
    }

    /// The kind a set of muscles points to: chest, shoulders and triceps are push; back and biceps pull; quads, glutes
    /// and hamstrings legs. Mixed (or only core) muscles point to none.
    static func kind(ofPrimaries muscles: [(name: String, role: MuscleRole)]) -> RoutineKind? {
        var kinds: Set<RoutineKind> = []
        for muscle in muscles where muscle.role == .primary {
            switch muscle.name.lowercased() {
            case "chest", "front delts", "side delts", "triceps": kinds.insert(.push)
            case "lats", "upper back", "lower back", "rear delts", "biceps", "forearms": kinds.insert(.pull)
            case "quads", "glutes", "hamstrings", "calves", "adductors", "abductors": kinds.insert(.legs)
            default: break
            }
        }
        return kinds.count == 1 ? kinds.first : nil
    }

    /// The routine's kind, else the muscles' kind, else the Training colour.
    static func colour(kind: RoutineKind?, muscles: [(name: String, role: MuscleRole)]) -> Color {
        colour(kind: kind ?? Self.kind(ofPrimaries: muscles))
    }
}

/// One side of the figure. The drawing is a 200 x 440 box with the left half drawn and mirrored about x = 100.
struct MuscleFigure: View {
    let back: Bool
    let roles: [String: MuscleRole]
    var tint: Color = Theme.Colors.training
    /// Tapping a worked part opens that muscle (the same open as its row); nil when nothing handles taps.
    var onTap: ((String) -> Void)?
    /// The one VoiceOver line for the whole figure ("Works chest, shoulders and triceps"); empty hides it.
    var spoken = ""
    /// The outline's ink: 22% by default; Design's small figures (under 70 pt) use 40 to 50% so the line stays visible.
    var lineOpacity = 0.22
    /// The outline's colour: ink unless a page paints on something else (live mode draws in its cream).
    var lineColor: Color?
    /// The outline's width in viewBox units (2.2 to 2.6 under 70 pt tall, 1.4 from 110 pt); nil keeps the 1 pt line.
    var lineWidth: CGFloat?

    private var outline: [String] {
        back ? MuscleFigureArt.backOutline : MuscleFigureArt.frontOutline
    }

    private var regions: [(id: String, path: String)] {
        back ? MuscleFigureArt.backRegions : MuscleFigureArt.frontRegions
    }

    private var lines: [String] {
        back ? MuscleFigureArt.backLines : MuscleFigureArt.frontLines
    }

    var body: some View {
        GeometryReader { proxy in
            figure
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { tap in
                    guard let onTap, let id = Self.hit(tap.location, in: proxy.size, regions: regions, roles: roles)
                    else { return }
                    onTap(id)
                })
        }
        .aspectRatio(200.0 / 440.0, contentMode: .fit)
        .tesseraAnimation(.easeOut(duration: 0.26), value: roles.map { "\($0.key)\($0.value)" }.sorted())
        .modifier(FigureAccessibility(spoken: spoken))
    }

    private var figure: some View {
        Canvas { context, size in
            let place = Self.placement(in: size)
            let ink = (lineColor ?? Theme.Colors.ink).opacity(lineOpacity)
            let width = lineWidth.map { $0 * min(size.width / 200, size.height / 440) } ?? 1
            for half in [CGAffineTransform.identity, Self.mirror] {
                let transform = half.concatenating(place)
                for (id, data) in regions {
                    guard let role = roles[id] else { continue }
                    context.fill(FigurePath.path(data).applying(transform),
                                 with: .color(tint.opacity(role.strength)))
                }
                for data in outline + lines {
                    context.stroke(FigurePath.path(data).applying(transform), with: .color(ink),
                                   style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }

    /// Mirror about x = 100: x becomes 200 - x.
    static let mirror = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 200, ty: 0)

    /// The 200 x 440 box fitted and centred in `size`.
    static func placement(in size: CGSize) -> CGAffineTransform {
        let scale = min(size.width / 200, size.height / 440)
        return CGAffineTransform(translationX: (size.width - 200 * scale) / 2, y: (size.height - 440 * scale) / 2)
            .scaledBy(x: scale, y: scale)
    }

    /// The worked region a tap belongs to: the nearest within a 44 pt target centred on each part (nil if none).
    static func hit(_ location: CGPoint, in size: CGSize, regions: [(id: String, path: String)],
                    roles: [String: MuscleRole]) -> String?
    {
        let scale = min(size.width / 200, size.height / 440)
        guard scale > 0 else { return nil }
        let place = placement(in: size)
        let drawn = location.applying(place.inverted())
        // The drawn half is the left one; fold a tap on the right half onto it.
        let point = CGPoint(x: drawn.x > 100 ? 200 - drawn.x : drawn.x, y: drawn.y)
        let pad = 22 / scale
        var best: (id: String, distance: CGFloat)?
        for (id, data) in regions where roles[id] != nil {
            let box = FigurePath.path(data).boundingRect
            let target = CGRect(x: box.midX - max(box.width / 2, pad), y: box.midY - max(box.height / 2, pad),
                                width: max(box.width, 2 * pad), height: max(box.height, 2 * pad))
            guard target.contains(point) else { continue }
            let distance = hypot(point.x - box.midX, point.y - box.midY)
            if best == nil || distance < best!.distance {
                best = (id, distance)
            }
        }
        return best?.id
    }
}

/// VoiceOver reads the figure as one element (regions are not separate stops); no line means hidden.
private struct FigureAccessibility: ViewModifier {
    let spoken: String

    func body(content: Content) -> some View {
        if spoken.isEmpty {
            content.accessibilityHidden(true)
        } else {
            content.accessibilityElement(children: .ignore).accessibilityLabel(spoken)
        }
    }
}
