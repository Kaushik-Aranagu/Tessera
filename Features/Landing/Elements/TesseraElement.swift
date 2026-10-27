import CoreGraphics
import Foundation
import TesseraCore
import TesseraTess

// Sheet 288, the element template. Every element answers the same short template as data (`ElementSpec`), and the
// conformance suite (`ElementConformance`) proves it keeps the rules. The walls (look rules, privacy taints, his
// finger wins, every move ends within 1 s) are helpers in the protocol extension, never requirements, so no
// conformer can override them.

/// Sheet 291, section 5b: the only surfaces that may sit over the places, bottom up.
enum SurfaceLayer: Int, CaseIterable, Comparable, Sendable {
    /// Nothing is under it.
    case ground = 0
    /// Type, lists, widget, glyph, keystone: flat, and never over another element.
    case places
    /// Shape mode outlines: on the seams, no fill.
    case shapeOutlines
    /// The glass lens: only under a finger; never holds text.
    case lens
    /// Tess's wash: 600 ms, never under his finger.
    case wash
    /// Tess's soul: a fixed 96 pt square, a boundary rather than a cover.
    case soul
    /// Tess's words and receipts: a frosted band (blur 16, 88% ground).
    case words
    /// Sheets: an opaque ground; one at a time.
    case sheets
    /// iOS's own alerts and keyboard.
    case system

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Layers 6 and up carry text over other text, so they bring a ground of their own (frosted for 6, opaque for 7).
    var needsGround: Bool {
        self >= .words
    }
}

enum ElementKind: String, Sendable {
    case place, type, list, dial, keystone, glyph, body, overlay
}

/// The entries of the template (section 3).
enum TemplateEntry: String, CaseIterable, Sendable {
    case identity, frame, shape, forms, touch, meaning, moves, control, pending, `return`, live, reduceMotion, look
    case privacy, layer, stage
}

/// An entry is either answered or says "inherits".
enum TemplateAnswer: Equatable, Sendable {
    case inherits
    case says(String)
}

/// The two looks every check runs in.
enum ElementLook: String, CaseIterable, Sendable {
    case paper, black

    var look: Look {
        self == .paper ? .white : .black
    }
}

/// What colour a run is set in, by role: a leaf never names a colour of its own (there is no colour trait).
enum ElementInk: Equatable, Sendable {
    case ink, ink2, room
}

/// One run of text as an element draws it, in the shell's frame (402 x 874), rect included.
struct ElementRun: Equatable, Sendable {
    var text: String
    var rect: CGRect
    var size: CGFloat
    var bold = false
    var ink: ElementInk = .ink
    /// A unit (a count, a time) may go to 10 pt; a line floor is 13 pt.
    var isUnit = false
    /// The run is tappable.
    var isTarget = false
}

/// A way a render can break the look rules (cards, pills, bars, rings, middle dots, filled dots, underlines).
enum LookViolation: String, Sendable {
    case card, pill, bar, ring, middleDot, filledDot, underline, colourTrait
}

/// What a form draws for one sample at one variant: runs, targets, what it showed, and what it dropped.
struct ElementRender: Equatable, Sendable {
    var runs: [ElementRun] = []
    /// Touch rects (a run's tap area, widened to its cell).
    var targets: [CGRect] = []
    /// Targets that tile a line of text (a sentence's names): both sides at least 24 pt, because their neighbours
    /// are the gaps between them.
    var inlineTargets: [CGRect] = []
    /// Names it drew in full.
    var shown: [String] = []
    /// Items it did not draw by name but folded into a tappable "and N more".
    var summarised = 0
    /// Items lost: neither shown nor summarised.
    var lost = 0
    /// A run that did not fit, was cut, wrapped or hidden.
    var clipped = false
    /// Facts the frame carries (name taint matters under Walls).
    var facts: [ElementFact] = []
    var violations: [LookViolation] = []
    var overlapsOtherText = false
    var ownsGround = false
}

/// How the element is asked to draw: which form and fixes, which look, which Dynamic Type scale.
struct ElementVariant: Equatable, Sendable {
    var form = 0
    var size = 0
    var density = 0
    var facts = 0
}

struct RenderRequest: Equatable, Sendable {
    var variant = ElementVariant()
    var look: ElementLook = .paper
    var typeScale: CGFloat = 1
    var reduceMotion = false
    var level = 0
}

/// The fixes an element tries, in this order (section 5).
enum ElementFix: Int, CaseIterable, Comparable, Sendable, CustomStringConvertible {
    case size, density, facts, nextForm, designedForm

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var description: String {
        switch self {
        case .size: "size step down"
        case .density: "density step down"
        case .facts: "fewer facts"
        case .nextForm: "next form"
        case .designedForm: "designed form"
        }
    }
}

/// One form an element can take. Steps are ordered designed first; a ladder of one cannot step.
struct ElementFormSpec: Sendable {
    var name: String
    var sizeSteps: [CGFloat]
    var densitySteps: [String] = ["designed"]
    var factsSteps: Int = 1
    /// The size trait's floor: a fix never goes below it.
    var sizeFloor: CGFloat = 13
    /// The names of this form's traits (a colour trait is a wall violation).
    var traits: [String] = []
}

/// A move an element plays and how long it takes.
struct ElementMove: Sendable {
    var name: String
    var milliseconds: Int
}

/// The filled template as data, so the stage, Tess and the tests can read it.
struct ElementSpec: Sendable {
    var name: String
    var kind: ElementKind
    var place: ElementPlace
    var shape: ContentShape
    /// Its frame per level (0 the landing, 1 a door page); nil where it is merged away.
    var frames: [Int: CGRect]
    /// Every other element's frame per level, for Bounds.
    var neighbours: [Int: [CGRect]] = [:]
    var forms: [ElementFormSpec]
    var layer: SurfaceLayer = .places
    var moves: [ElementMove] = []
    var hasReduceMotion = true
    /// Coming back into view plays only the differences: how many it plays.
    var returnPlays = 1
    var answers: [TemplateEntry: TemplateAnswer] = [:]
    var render: @Sendable (RenderRequest) -> ElementRender
    /// What the same screen means in a form (#1449): the meaning must not depend on the form.
    var meaning: @Sendable (RenderRequest) -> ElementMeaning
    /// The end frame a move to this form lands on, which must equal a still render.
    var landing: @Sendable (RenderRequest) -> ElementRender
    /// With `isShown` false, how many frames a change draws (zero), and whether it arrives at its end state.
    var unseen: @Sendable (RenderRequest) -> (frames: Int, arrives: Bool)

    /// An empty template entry says "inherits": a new element only writes what differs.
    func answer(_ entry: TemplateEntry) -> TemplateAnswer? {
        answers[entry]
    }
}

/// The base: a default for every entry, so an element writes only what differs (section 3).
protocol TesseraElement: Sendable {
    var spec: ElementSpec { get }
}

extension TesseraElement {
    /// The walls forward to `ElementWalls`; they are helpers, never requirements.
    static func violations(of render: ElementRender, forms: [ElementFormSpec]) -> [LookViolation] {
        ElementWalls.violations(of: render, forms: forms)
    }

    static func moneyIsAbout(_ render: ElementRender) -> Bool {
        ElementWalls.moneyIsAbout(render)
    }
}

/// The walls themselves (look rules, money, colour trait): `final` by being a namespace nobody inherits from.
enum ElementWalls {
    static func violations(of render: ElementRender, forms: [ElementFormSpec]) -> [LookViolation] {
        var found = render.violations
        if forms.contains(where: { $0.traits.contains { ["colour", "color", "hue"].contains($0.lowercased()) } }) {
            found.append(.colourTrait)
        }
        return found
    }

    /// Money is always "about" and never coloured by sign (the look rules).
    static func moneyIsAbout(_ render: ElementRender) -> Bool {
        render.runs.allSatisfy { run in
            guard run.text.contains("$") || run.text.contains("£") || run.text.contains("€") else { return true }
            return run.text.lowercased().hasPrefix("about")
        }
    }
}

/// `ElementRegistry.all` lists every element. A new element that is not listed fails Registered.
enum ElementRegistry {
    static let all: [any TesseraElement] = [
        DoorsDialElement(),
    ]

    static func contains(_ name: String) -> Bool {
        all.contains { $0.spec.name == name }
    }
}
