// swiftlint:disable identifier_name
import CoreGraphics
import Foundation
import TesseraTess

// Sheet 288, section 5: the conformance suite. On a failure, fix first (the element's own steps, in order), then
// block (must) or warn (should). `scripts/test.sh` fails only on `.block`, and lists `.fixed` and `.warn`.

enum CheckTier: String, Sendable {
    case must, should
}

enum CheckOutcome: Equatable, Sendable {
    case pass
    case fixed(by: [ElementFix], detail: String)
    case warn(String)
    case block(String)

    var isBlock: Bool {
        if case .block = self {
            true
        } else {
            false
        }
    }
}

/// The checks of section 5, by name.
enum ElementCheckName: String, CaseIterable, Sendable {
    case renders = "Renders", lands = "Lands", meaning = "Meaning", unseen = "Unseen", walls = "Walls"
    case floor = "Floor", touch = "Touch", contrast = "Contrast", registered = "Registered", bounds = "Bounds"
    case layers = "Layers", timing = "Timing", returning = "Return", colours = "Colours"
    case reduceMotion = "Reduce Motion", template = "Template"

    var tier: CheckTier {
        switch self {
        case .timing, .returning, .colours, .reduceMotion, .template: .should
        default: .must
        }
    }

    /// Which fixes may help this check (the Fixable column).
    var fixes: [ElementFix] {
        switch self {
        case .renders, .bounds: [.size, .density, .facts, .nextForm, .designedForm]
        case .floor: [.size, .nextForm, .designedForm]
        case .touch: [.density, .nextForm, .designedForm]
        case .contrast, .colours: [.designedForm]
        case .timing, .returning: []
        default: []
        }
    }

    /// Checks of the whole element rather than of one form in one look.
    var isWholeElement: Bool {
        switch self {
        case .meaning, .registered, .layers, .template, .reduceMotion, .timing, .returning, .unseen: true
        default: false
        }
    }
}

struct ConformanceResult: Equatable, Sendable {
    var check: ElementCheckName
    var element: String
    /// The form (nil for whole-element checks), the look and the Dynamic Type scale it ran in.
    var form: String?
    var look: ElementLook?
    var scale: CGFloat?
    var outcome: CheckOutcome
}

enum ElementConformance {
    /// The looks, scales and Reduce Motion states every form is checked in.
    static let scales: [CGFloat] = [1, 1.3]

    static let unitFloor: CGFloat = 10
    static let lineFloor: CGFloat = 13
    /// Targets are 44 pt on their long side; the short side is the line pitch (at least 24 pt) where targets tile a
    /// column or a sentence, because the dial's frame is 120 pt high.
    static let targetLong: CGFloat = 44
    static let targetShort: CGFloat = 24
    static let aa: CGFloat = 4.5
    static let aaLarge: CGFloat = 3

    static func run(spec: ElementSpec) -> [ConformanceResult] {
        var results: [ConformanceResult] = []
        func add(_ check: ElementCheckName, _ form: String? = nil, _ look: ElementLook? = nil, _ scale: CGFloat? = nil,
                 _ outcome: CheckOutcome)
        {
            results.append(ConformanceResult(check: check, element: spec.name, form: form, look: look, scale: scale,
                                             outcome: outcome))
        }
        for (check, outcome) in wholeElement(spec) {
            add(check, nil, nil, nil, outcome)
        }
        for (index, form) in spec.forms.enumerated() {
            for level in spec.levels {
                for look in ElementLook.allCases {
                    for scale in scales {
                        for reduce in [false, true] {
                            let request = RenderRequest(variant: ElementVariant(form: index), look: look,
                                                        typeScale: scale, reduceMotion: reduce, level: level)
                            for check in [ElementCheckName.renders, .lands, .walls, .floor, .touch, .contrast,
                                          .bounds, .colours]
                            {
                                // The look and scale matter; Reduce Motion only changes moves, so one pass is enough.
                                if reduce, check != .lands {
                                    continue
                                }
                                let name = spec.levels.count > 1 ? "\(form.name) L\(level)" : form.name
                                add(check, name, look, scale, resolve(check, spec: spec, request: request))
                            }
                        }
                    }
                }
            }
        }
        return results
    }

    // MARK: Whole-element checks

    private static func wholeElement(_ spec: ElementSpec) -> [(ElementCheckName, CheckOutcome)] {
        var out: [(ElementCheckName, CheckOutcome)] = []
        out.append((.registered, ElementRegistry.contains(spec.name) ? .pass
                : .block("\(spec.name) is not listed in ElementRegistry.all")))
        out.append((.layers, layers(spec)))
        out.append((.meaning, meaning(spec)))
        out.append((.unseen, unseen(spec)))
        let slow = spec.moves.filter { $0.milliseconds > 1000 }
        out.append((.timing, slow.isEmpty ? .pass
                :
                .warn(
                    "\(slow.map(\.name).joined(separator: ", ")) runs past 1 s; use Reduce Motion's 150 ms crossfade"
                )))
        out.append((.returning, spec.returnPlays <= 6 ? .pass
                : .warn("coming back plays \(spec.returnPlays) differences; show now instead")))
        let inherits = spec.answer(.reduceMotion) == .inherits
        out.append((.reduceMotion, spec.hasReduceMotion || inherits ? .pass : .warn("no Reduce Motion version")))
        let missing = TemplateEntry.allCases.filter { spec.answer($0) == nil }
        out.append((.template, missing.isEmpty ? .pass
                : .warn("unanswered: \(missing.map(\.rawValue).joined(separator: ", "))")))
        return out
    }

    private static func layers(_ spec: ElementSpec) -> CheckOutcome {
        // A place never covers another element, so its text never has other text under it; layers from 6 up bring a
        // ground. Frames on the same level must not overlap another element (the 4 pt seam is theirs).
        for form in spec.forms.indices {
            let render = spec.render(RenderRequest(variant: ElementVariant(form: form)))
            if render.overlapsOtherText {
                return .block("text of \(spec.name) is over other text")
            }
            if spec.layer.needsGround, !render.ownsGround {
                return .block("layer \(spec.layer.rawValue) carries text without its ground")
            }
        }
        for (level, frame) in spec.frames {
            if spec.layer == .places, (spec.neighbours[level] ?? []).contains(where: { $0.intersects(frame) }) {
                return .block("frame at level \(level) overlaps another place")
            }
        }
        return .pass
    }

    private static func meaning(_ spec: ElementSpec) -> CheckOutcome {
        let meanings = spec.forms.indices.map { spec.meaning(RenderRequest(variant: ElementVariant(form: $0))) }
        guard let first = meanings.first else { return .block("no forms") }
        return meanings.allSatisfy { $0 == first } ? .pass : .block("the forms mean different things for one screen")
    }

    private static func unseen(_ spec: ElementSpec) -> CheckOutcome {
        for form in spec.forms.indices {
            let result = spec.unseen(RenderRequest(variant: ElementVariant(form: form)))
            if result.frames != 0 || !result.arrives {
                return .block("an unseen change drew \(result.frames) frames or missed its end state")
            }
        }
        return .pass
    }

    // MARK: Per-form checks with the fix loop

    /// Evaluates one check; on a failure tries the allowed fixes in order, then the tier decides.
    static func resolve(_ check: ElementCheckName, spec: ElementSpec, request: RenderRequest) -> CheckOutcome {
        guard let first = failure(check, spec: spec, request: request) else { return .pass }
        var variant = request.variant
        var applied: [ElementFix] = []
        for fix in check.fixes {
            var guardCount = 0
            while let next = apply(fix, to: variant, spec: spec), guardCount < 12 {
                guardCount += 1
                variant = next
                applied.append(fix)
                var trial = request
                trial.variant = variant
                if failure(check, spec: spec, request: trial) == nil {
                    return .fixed(by: applied, detail: "\(spec.forms[request.variant.form].name): \(first); "
                        + applied.map(\.description).joined(separator: ", ") + " now passes")
                }
                if fix == .nextForm || fix == .designedForm {
                    break
                }
            }
        }
        return check.tier == .must ? .block(first) : .warn(first)
    }

    /// One step of a fix, or nil when the element has no such step left.
    static func apply(_ fix: ElementFix, to variant: ElementVariant, spec: ElementSpec) -> ElementVariant? {
        let form = spec.forms[variant.form]
        var next = variant
        switch fix {
        case .size:
            guard variant.size + 1 < form.sizeSteps.count, form.sizeSteps[variant.size + 1] >= form.sizeFloor
            else { return nil }
            next.size += 1
        case .density:
            guard variant.density + 1 < form.densitySteps.count else { return nil }
            next.density += 1
        case .facts:
            guard variant.facts + 1 < form.factsSteps else { return nil }
            next.facts += 1
        case .nextForm:
            guard variant.form + 1 < spec.forms.count else { return nil }
            next = ElementVariant(form: variant.form + 1)
        case .designedForm:
            guard variant.form != 0 || variant != ElementVariant() else { return nil }
            next = ElementVariant()
        }
        return next
    }

    /// Why a check fails for this request, or nil.
    static func failure(_ check: ElementCheckName, spec: ElementSpec, request: RenderRequest) -> String? {
        let render = spec.render(request)
        let frame = spec.frames[request.level] ?? .zero
        switch check {
        case .renders:
            if render.lost > 0 {
                return "\(render.lost) items are lost"
            }
            if render.clipped {
                return "text was clipped or wrapped"
            }
            return render.runs
                .contains { !frame.insetBy(dx: -0.5, dy: -0.5).contains($0.rect) } ? "a run is outside its frame" : nil
        case .lands:
            let landed = spec.landing(request)
            return landed == render ? nil : "the move's end frame differs from a still render"
        case .walls:
            let broken = ElementWalls.violations(of: render, forms: spec.forms)
            if !broken.isEmpty {
                return "look rules broken: \(broken.map(\.rawValue).joined(separator: ", "))"
            }
            if render.facts.contains(where: { $0.taint == .deviceOnly }) {
                return "a deviceOnly fact is on a frame"
            }
            return ElementWalls.moneyIsAbout(render) ? nil : "money without \"about\""
        case .floor:
            let low = render.runs.first { $0.size < ($0.isUnit ? unitFloor : lineFloor) }
            return low.map { "\"\($0.text)\" is \($0.size) pt, under its floor" }
        case .touch:
            let small = render.targets
                .first { max($0.width, $0.height) < targetLong || min($0.width, $0.height) < targetShort }
                ?? render.inlineTargets.first { min($0.width, $0.height) < targetShort }
            return small.map { "a target is \(Int($0.width)) x \(Int($0.height)) pt" }
        case .contrast:
            return contrast(render, look: request.look)
        case .bounds:
            return bounds(render, spec: spec, request: request, frame: frame)
        case .colours:
            return colours(render)
        default:
            return nil
        }
    }

    private static func bounds(_ render: ElementRender, spec: ElementSpec, request: RenderRequest,
                               frame: CGRect) -> String?
    {
        let others = spec.neighbours[request.level] ?? []
        for run in render.runs {
            if let hit = others.first(where: { $0.intersects(run.rect) }) {
                return "\"\(run.text)\" crosses another element's frame at \(Int(hit.minX)),\(Int(hit.minY))"
            }
            if !frame.insetBy(dx: -0.5, dy: -0.5).contains(run.rect) {
                return "\"\(run.text)\" leaves its frame"
            }
        }
        for (index, run) in render.runs.enumerated() {
            for other in render.runs[(index + 1)...] where run.rect.intersects(other.rect) {
                return "\"\(run.text)\" crosses \"\(other.text)\""
            }
        }
        return nil
    }

    private static func colours(_ render: ElementRender) -> String? {
        let inks = Set(render.runs.map(\.ink))
        // Three roles at most here; the page's four-colour budget is the room's.
        if inks.count > 3 {
            return "more than 4 colours"
        }
        let biggest = render.runs.sorted { $0.size > $1.size }.prefix(3)
        if biggest.count == 3, Set(biggest.map(\.ink)).count == 1,
           Set(render.runs.map(\.size)).count > 1
        {
            return "the three biggest words share a colour"
        }
        return nil
    }

    // MARK: Contrast

    private static func contrast(_ render: ElementRender, look: ElementLook) -> String? {
        let theme = look.look
        let ground = theme.ground
        for run in render.runs {
            let ink = rgb(for: run.ink, look: theme)
            let ratio = contrastRatio(ink.color, ground, alpha: ink.alpha)
            let large = run.size >= 24 || (run.size >= 18.66 && run.bold)
            if ratio < (large ? aaLarge : aa) {
                return "\"\(run.text)\" is \(String(format: "%.1f", ratio)):1 in \(look.rawValue)"
            }
        }
        return nil
    }

    static func rgb(for ink: ElementInk, look: Look) -> (color: UInt32, alpha: CGFloat) {
        switch ink {
        case .ink: (look.ink, 1)
        case .ink2: look.ink2.map { ($0, 1) } ?? (look.ink, look.isDark ? 0.72 : 0.66)
        case .room: (look.accents?.notes ?? look.context, 1)
        case .done: look.isDark ? (0x8FC9A0, 1) : (0x25803D, 1)
        case .late: look.isDark ? (0xEE8E9C, 1) : (0x9A2541, 1)
        case .best: look.isDark ? (0xD9C27A, 1) : (0x7E6A1E, 1)
        case .planned: look.isDark ? (0xA7BCD6, 1) : (0x34506F, 1)
        }
    }

    static func luminance(_ hex: UInt32) -> CGFloat {
        func channel(_ value: UInt32) -> CGFloat {
            let c = CGFloat(value) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel((hex >> 16) & 0xFF) + 0.7152 * channel((hex >> 8) & 0xFF) + 0.0722 * channel(hex & 0xFF)
    }

    static func contrastRatio(_ text: UInt32, _ ground: UInt32, alpha: CGFloat = 1) -> CGFloat {
        func blend(_ shift: UInt32) -> UInt32 {
            let t = CGFloat((text >> shift) & 0xFF), g = CGFloat((ground >> shift) & 0xFF)
            return UInt32((t * alpha + g * (1 - alpha)).rounded())
        }
        let mixed = (blend(16) << 16) | (blend(8) << 8) | blend(0)
        let a = luminance(mixed), b = luminance(ground)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    // MARK: Report

    static func blocks(_ results: [ConformanceResult]) -> [ConformanceResult] {
        results.filter(\.outcome.isBlock)
    }

    /// The lines `scripts/test.sh` lists: every `.fixed` and `.warn`, and every `.block`.
    static func report(_ results: [ConformanceResult]) -> [String] {
        results.compactMap { result in
            let where_ = [result.form, result.look?.rawValue, result.scale.map { "x\($0)" }].compactMap(\.self)
                .joined(separator: " ")
            switch result.outcome {
            case .pass: return nil
            case let .fixed(_, detail): return "FIXED \(result.element) \(result.check.rawValue) [\(where_)] \(detail)"
            case let .warn(reason): return "WARN \(result.element) \(result.check.rawValue) [\(where_)] \(reason)"
            case let .block(reason): return "BLOCK \(result.element) \(result.check.rawValue) [\(where_)] \(reason)"
            }
        }
    }
}
