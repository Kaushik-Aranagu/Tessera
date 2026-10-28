import CoreGraphics
import Foundation
import TesseraCore
import TesseraTess

/// The kit as one element (sheet 288): the `SlotKind.parts` keystone, a `KeystoneElement` drawing a ranked row of
/// numerals over names. The other parts inherit it (they draw through the same `PartLayout`), so the suite proves the
/// rule for the whole kit.
struct PartsKeystoneElement: TesseraElement {
    static let sample: [RankedItem] = [("Orchid", "6"), ("Monstera", "4"), ("Fern", "2"), ("Basil", "1")]
        .map { RankedItem(id: $0.0, big: $0.1, small: $0.0, isTop: $0.0 == "Orchid") }

    var spec: ElementSpec {
        var answers: [TemplateEntry: TemplateAnswer] = [:]
        for entry in TemplateEntry.allCases {
            answers[entry] = .inherits
        }
        answers[.identity] = .says("Parts, a KeystoneElement, the keystone place (kit parts inherit it)")
        answers[.frame] = .says("24,196 354 x 182 on the landing")
        answers[.shape] = .says("few: up to four ranked numerals over names")
        answers[.touch] = .says("none of its own; the shell's gestures pass through")
        answers[.look] = .says("Outfit 64 light numerals, 15 pt 600 names; the top one in wine, breathing")
        answers[.privacy] = .says("a private item's name reads Private; money and body classes are never bound")
        let frame = LandingPlace.keystone.frame
        let others = [LandingPlace.Masthead.title, LandingPlace.Masthead.switcher, LandingPlace.caption.frame,
                      LandingPlace.widget.frame, LandingPlace.Foot.actionWord, LandingPlace.Foot.tess]
        let items = Self.sample
        return ElementSpec(
            name: "Parts",
            kind: .keystone,
            place: .keystone,
            shape: .few,
            frames: [0: frame],
            neighbours: [0: others],
            forms: [ElementFormSpec(name: "row", sizeSteps: [1, 0.9], sizeFloor: 0.8)],
            moves: [ElementMove(name: "replace", milliseconds: 420)],
            answers: answers,
            render: { Self.draw($0, items: items) },
            meaning: { _ in Self.meaning(items) },
            landing: { Self.draw($0, items: items) },
            unseen: { _ in (frames: 0, arrives: true) }
        )
    }

    static func meaning(_ items: [RankedItem]) -> ElementMeaning {
        ElementMeaning(place: .keystone, items: items.map { ElementItem(kind: "part", name: $0.small) }, focus: 0)
    }

    static func draw(_: RenderRequest, items: [RankedItem]) -> ElementRender {
        var render = ElementRender()
        let pieces = PartLayout.place(.row(id: "row", items: items), in: LandingPlace.keystone.frame, scale: 1)
        for piece in pieces {
            render.runs.append(ElementRun(text: piece.text, rect: piece.rect, size: piece.size, bold: piece.bold,
                                          ink: .ink, isUnit: false, isTarget: false))
            if piece.id.hasSuffix(".name") {
                render.shown.append(piece.text)
                // A name wider than its cell would be cut: that is a clipped run.
                if DoorText.width(piece.text, size: piece.size, bold: true) > piece.rect.width {
                    render.clipped = true
                }
            }
        }
        return render
    }
}
