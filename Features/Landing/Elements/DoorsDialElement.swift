import CoreGraphics
import Foundation
import TesseraCore
import TesseraTess

/// The base case of the induction (sheet 288, section 4): the doors dial, a `ListElement`, the `dial` place. It is
/// the first element listed in `ElementRegistry.all`; every element after it is proven the same way.
struct DoorsDialElement: TesseraElement {
    /// The sample the suite draws: the Log's eight doors (sheet 292).
    var names: [(id: String, name: String)] = DoorForms.sampleNames

    var spec: ElementSpec {
        let names = names
        var answers: [TemplateEntry: TemplateAnswer] = [:]
        for entry in TemplateEntry.allCases {
            answers[entry] = .inherits
        }
        answers[.identity] = .says("Doors, a ListElement, the dial place")
        answers[.frame] = .says("218,640 160 x 120 on every landing; the Page takes it at level 1")
        answers[.shape] = .says("doors")
        answers[.forms] = .says("reel (designed), index (two columns of four past five doors), sentence (four names)")
        answers[.touch] = .says("reel turns and the focus opens; index and sentence tap a door")
        answers[.meaning] = .says("doors (kind door), focus is the reel's centre, call openDoor")
        answers[.moves] = .says("replace spins the reel or fades and rises; form travels 520 ms; value rolls digits")
        answers[.look] =
            .says("focus 26 pt 700 in the room colour, neighbours 20 pt ink 2; index 15 pt, 13 pt in columns")
        answers[.privacy] = .says("door names only; the Private door shows a count, never names")
        answers[.stage] = .says("the focus is always readable: never blurred, never under 20 pt in the reel")
        let level0 = LandingPlace.Doors.dial
        let others = [LandingPlace.Doors.summary, LandingPlace.widget.frame, LandingPlace.foot.frame,
                      LandingPlace.Foot.actionWord, LandingPlace.Foot.tess, LandingPlace.caption.frame,
                      LandingPlace.keystone.frame]
        return ElementSpec(
            name: "Doors",
            kind: .dial,
            place: .dial,
            shape: .doors,
            frames: [0: level0],
            neighbours: [0: others],
            forms: DoorForms.specs,
            moves: [ElementMove(name: "replace", milliseconds: 980), ElementMove(name: "form", milliseconds: 520),
                    ElementMove(name: "value", milliseconds: 400)],
            returnPlays: 1,
            answers: answers,
            render: { Self.draw($0, names: names) },
            meaning: { request in Self.meaning(request, names: names) },
            // A move to a form ends on the layout the form draws when still: one path draws both (sheet 288).
            landing: { Self.draw($0, names: names) },
            unseen: { _ in (frames: DoorsFormMove.frames(isShown: false), arrives: true) }
        )
    }

    /// What the dial means: doors, the focus, and `openDoor`. The same in every form.
    static func meaning(_: RenderRequest, names: [(id: String, name: String)]) -> ElementMeaning {
        ElementMeaning(
            place: .dial,
            items: names.map { ElementItem(kind: "door", name: $0.name) },
            focus: 0,
            calls: [ElementCall("openDoor", .shell, phrases: ["open"], inputs: [CallInput("door", from: .door)],
                                reaction: .navigate)]
        )
    }

    /// Draws one form of the dial at a variant, as runs and targets.
    static func draw(_ request: RenderRequest, names: [(id: String, name: String)]) -> ElementRender {
        let forms = DoorForms.specs
        let form = forms[request.variant.form]
        let size = form.sizeSteps[min(request.variant.size, form.sizeSteps.count - 1)]
        var render = ElementRender()
        let focus = 0
        switch form.name {
        case "index":
            let gap = Double(form.densitySteps[min(request.variant.density, form.densitySteps.count - 1)])
                .map { CGFloat($0) } ?? DoorForms.indexGaps[0]
            let layout = DoorForms.index(names: names, focus: focus, size: size, gap: gap, scale: request.typeScale)
            fill(&render, layout: layout, inline: false) { DoorForms.indexTarget($0) }
        case "sentence":
            let count = DoorForms.sentenceCounts[min(request.variant.facts, DoorForms.sentenceCounts.count - 1)]
            let layout = DoorForms.sentence(names: names, focus: focus, size: size, count: count,
                                            scale: request.typeScale)
            fill(&render, layout: layout, inline: true) { DoorForms.sentenceTarget($0) }
        default:
            drawReel(&render, names: names, focus: focus)
        }
        return render
    }

    private static func fill(_ render: inout ElementRender, layout: DoorFormLayout, inline: Bool,
                             target: (DoorPlacement) -> CGRect)
    {
        for placement in layout.placements {
            render.runs.append(ElementRun(text: placement.text, rect: placement.rect, size: placement.size,
                                          bold: placement.bold, ink: placement.ink,
                                          isTarget: !placement.isJoiner || placement.opensIndex))
            if !placement.isJoiner || placement.opensIndex {
                if inline {
                    render.inlineTargets.append(target(placement))
                } else {
                    render.targets.append(target(placement))
                }
            }
            if !placement.isJoiner {
                render.shown.append(placement.text)
            }
        }
        render.summarised = layout.summarised
        render.lost = layout.lost
        render.clipped = layout.clipped
    }

    /// The reel: the focus and one door above and below, 40 pt places, 26 and 20 pt, right-aligned.
    private static func drawReel(_ render: inout ElementRender, names: [(id: String, name: String)], focus: Int) {
        let frame = DoorForms.frame
        for place in -1 ... 1 {
            let index = (focus + place + names.count) % names.count
            let name = names[index].name
            let isFocus = place == 0
            let size: CGFloat = isFocus ? 26 : 20
            let width = DoorText.width(name, size: size, bold: true)
            let y = frame.minY + CGFloat(place + 1) * 40 + (40 - size * 1.25) / 2
            let rect = CGRect(x: frame.maxX - min(width, frame.width), y: y, width: min(width, frame.width),
                              height: size * 1.25)
            render.runs.append(ElementRun(text: name, rect: rect, size: size, bold: true,
                                          ink: isFocus ? .room : .ink2, isTarget: true))
            render.targets.append(CGRect(x: frame.minX, y: frame.minY + CGFloat(place + 1) * 40, width: frame.width,
                                         height: 40))
            if isFocus {
                render.shown.append(name)
            }
        }
        // The reel shows three places and the rest are one turn away, so they are summarised by the reel itself.
        render.summarised = names.count - 1
        render.lost = 0
    }
}

/// The dial's form move (sheet 288, Unseen): with the dial not shown, a change draws no frame and arrives at once.
enum DoorsFormMove {
    static let travel = 0.52
    static let fade = 0.26

    static func frames(isShown: Bool) -> Int {
        isShown ? 1 : 0
    }
}
