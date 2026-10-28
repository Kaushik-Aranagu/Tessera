import CoreGraphics
import Foundation
import TesseraCore
import TesseraTess

// Sheet 288, the induction's next steps: the door Page (level 1) and the item page (level 2) as elements. Both fill the
// template and pass the same conformance suite; the kit's other body kinds inherit the item page.

/// The Page's block at levels 1 and 2 (24,412 354 x 364) and the places around it.
enum PageFrames {
    static let block = LandingPlace.widget.frame.union(LandingPlace.breathBelowWidget.frame)
        .union(LandingPlace.Doors.dial).union(LandingPlace.breathAboveFoot.frame)

    /// Every other place at levels 1 and 2 (the Door title or Item title is 24,106 354 x 70).
    static var neighbours: [CGRect] {
        [LandingPlace.Masthead.title, ShellLayout.mergedFrame(.doorTitle), LandingPlace.keystone.frame,
         LandingPlace.caption.frame, LandingPlace.Foot.actionWord, LandingPlace.Foot.tess]
    }
}

private func unchanged(_: RenderRequest) -> (frames: Int, arrives: Bool) {
    (frames: 0, arrives: true)
}

private func inheritedAnswers() -> [TemplateEntry: TemplateAnswer] {
    var answers: [TemplateEntry: TemplateAnswer] = [:]
    for entry in TemplateEntry.allCases {
        answers[entry] = .inherits
    }
    return answers
}

// MARK: - The Page (level 1)

/// The door's rows: a `ListElement` in the `page` place. Rows split the block by rank weights.
struct RankedPageElement: TesseraElement {
    /// The sample the suite draws: the Deck's Library, seven lifts with their bests.
    static let sample: [LevelRow] = [
        LevelRow(id: "a", title: "Bench Press", value: "100", unit: "kg", sub: "Best, Oct 12", state: .best),
        LevelRow(id: "b", title: "Back Squat", value: "140", unit: "kg", sub: "Last, Oct 20"),
        LevelRow(id: "c", title: "Deadlift", value: "170", unit: "kg", sub: "Last, Oct 17"),
        LevelRow(id: "d", title: "Overhead Press", value: "62.5", unit: "kg", sub: "Last, Oct 12"),
        LevelRow(id: "e", title: "Barbell Row", value: "85", unit: "kg"),
        LevelRow(id: "f", title: "Pull-up", value: "12", unit: "reps"),
        LevelRow(id: "g", title: "Dip", value: "15", unit: "reps", state: .planned),
    ]

    static let sizeSteps: [CGFloat] = [36, 32, 28]

    var rows: [LevelRow] = Self.sample

    var spec: ElementSpec {
        var answers = inheritedAnswers()
        answers[.identity] = .says("Page, a ListElement, the page place at level 1")
        answers[.frame] = .says("24,412 354 x 364; rows split it by weights 1.7, 1.3, 1.08, 1, 0.94, 0.88, 0.84")
        answers[.shape] = .says("many: up to seven ranked rows, the last may stand for the rest")
        answers[.touch] = .says("tap a row opens its item page; across on the Door title goes to the next door")
        answers[.meaning] = .says("items are the rows (kind row), focus the first, call openItem")
        answers[.moves] = .says("replace: rows leave softly and settle from the top, 0.38 s, 45 ms apart")
        answers[.look] = .says("title 0.36 x row height, 17 to 34 pt; first row bold in the room colour mixed 58% with "
            +
            "ink; value Outfit Light at 0.82 of the title, unit at half size; sub line 13 pt only when taller than 40")
        answers[.privacy] = .says("a private row is only its label (Private workout), never a value or sub line")
        answers[.stage] = .says("sub lines are the first thing a larger size drops; a value never wraps")
        let rows = rows
        return ElementSpec(
            name: "Page",
            kind: .list,
            place: .page,
            shape: .many,
            frames: [1: PageFrames.block],
            levels: [1],
            neighbours: [1: PageFrames.neighbours],
            forms: [ElementFormSpec(
                name: "ranked",
                sizeSteps: Self.sizeSteps,
                densitySteps: ["designed", "no sub lines"],
                sizeFloor: 24
            )],
            moves: [ElementMove(name: "replace", milliseconds: 850)],
            answers: answers,
            render: { Self.draw($0, rows: rows) },
            meaning: { _ in Self.meaning(rows) },
            landing: { Self.draw($0, rows: rows) },
            unseen: unchanged
        )
    }

    static func meaning(_ rows: [LevelRow]) -> ElementMeaning {
        ElementMeaning(
            place: .page,
            items: rows.map { ElementItem(kind: "row", name: $0.title, isPrivate: $0.isPrivate) },
            focus: 0,
            calls: [ElementCall("openItem", .shell, phrases: ["open"], inputs: [CallInput("item", from: .referent)],
                                reaction: .navigate)]
        )
    }

    static func ink(_ row: LevelRow, index: Int) -> ElementInk {
        switch row.state {
        case .done: .done
        case .late: .late
        case .best: .best
        case .planned: .planned
        case .none: index == 0 ? .room : .ink
        }
    }

    static func draw(_ request: RenderRequest, rows: [LevelRow]) -> ElementRender {
        var render = ElementRender()
        let step = Self.sizeSteps[min(request.variant.size, Self.sizeSteps.count - 1)] / 100
        let shown = RankedLayout.shown(rows, moreID: "more")
        let layouts = RankedLayout.rows(count: shown.count, in: PageFrames.block, scale: request.typeScale, ratio: step,
                                        dropSubs: request.variant.density > 0)
        render.lost = rows.count - shown.count
        for (index, row) in shown.enumerated() {
            let layout = layouts[index]
            let ink = ink(row, index: index)
            let unitWidth = row.unit.isEmpty ? 0 : DoorText.width(row.unit, size: layout.unitSize, bold: false) + 3
            let valueWidth = row.value.isEmpty ? 0
                : DoorText.width(row.value, size: layout.valueSize, bold: false) + unitWidth
            let room = layout.rect.width - valueWidth - (valueWidth > 0 ? RankedLayout.gap : 0)
            let titleWidth = DoorText.width(row.title, size: layout.titleSize, bold: index == 0)
            let titleHeight = layout.titleSize * 1.25
            let subHeight = layout.showsSub && !row.sub.isEmpty ? layout.subSize * 1.3 : 0
            let top = layout.rect.minY + (layout.rect.height - titleHeight - subHeight) / 2
            render.runs.append(ElementRun(text: row.title,
                                          rect: CGRect(x: layout.rect.minX, y: top, width: min(titleWidth, room),
                                                       height: titleHeight),
                                          size: layout.titleSize, bold: index == 0, ink: ink, isTarget: true))
            if titleWidth > room {
                render.clipped = true
            }
            if subHeight > 0 {
                render.runs.append(ElementRun(text: row.sub,
                                              rect: CGRect(x: layout.rect.minX, y: top + titleHeight,
                                                           width: min(DoorText.width(row.sub, size: layout.subSize,
                                                                                     bold: false), room),
                                                           height: subHeight),
                                              size: layout.subSize, ink: .ink2))
            }
            if valueWidth > 0 {
                let valueTop = layout.rect.minY + (layout.rect.height - layout.valueSize * 1.25) / 2
                let valueOnly = valueWidth - unitWidth
                render.runs.append(ElementRun(text: row.value,
                                              rect: CGRect(x: layout.rect.maxX - valueWidth, y: valueTop,
                                                           width: valueOnly, height: layout.valueSize * 1.25),
                                              size: layout.valueSize, ink: .ink))
                if unitWidth > 0 {
                    render.runs.append(ElementRun(text: row.unit,
                                                  rect: CGRect(x: layout.rect.maxX - unitWidth + 3, y: valueTop,
                                                               width: unitWidth - 3, height: layout.valueSize * 1.25),
                                                  size: layout.unitSize, ink: .ink, isUnit: true))
                }
            }
            render.targets.append(layout.rect)
            render.shown.append(row.title)
        }
        return render
    }
}

// MARK: - The item page (level 2)

/// The item page: Facts over a Body drawn by the item's kind. One element per kind, so the suite proves each.
struct ItemPageElement: TesseraElement {
    enum Sample {
        case sets, siblings, hours
    }

    var sample: Sample

    static var sets: Self {
        Self(sample: .sets)
    }

    static var siblings: Self {
        Self(sample: .siblings)
    }

    static var hours: Self {
        Self(sample: .hours)
    }

    static let hoursBody = HoursBody(
        lines: [
            HoursLine(id: "h6", time: "6 PM", word: "Cloudy", temp: "62", unit: "\u{00B0}"),
            HoursLine(id: "h7", time: "7 PM", word: "Rain starts", temp: "60", unit: "\u{00B0}", isOpen: true),
            HoursLine(id: "h8", time: "8 PM", word: "Rain", temp: "58", unit: "\u{00B0}"),
            HoursLine(id: "h9", time: "9 PM", word: "Easing", temp: "57", unit: "\u{00B0}"),
        ],
        advice: "Wet, take a coat"
    )

    static let setsBody = SetsBody(
        lines: [
            SetLine(id: "w1", label: "Warm-up", weight: "40", unit: "kg", reps: "8", state: .done),
            SetLine(id: "w2", label: "Warm-up", weight: "60", unit: "kg", reps: "5", state: .done),
            SetLine(id: "s1", label: "Set 1", weight: "80", unit: "kg", reps: "5", state: .done),
            SetLine(id: "s2", label: "Set 2", weight: "80", unit: "kg", reps: "5", state: .next),
            SetLine(id: "s3", label: "Set 3", weight: "80", unit: "kg", reps: "5", state: .todo),
            SetLine(id: "s4", label: "Set 4", weight: "80", unit: "kg", reps: "5", state: .todo),
        ],
        lastTime: "80 kg \u{00D7} 5, 5, 5, 4"
    )

    static let siblingsBody = SiblingsBody(rows: Array(RankedPageElement.sample.prefix(7)), current: "c")

    static let facts = [
        ItemFact(number: "80", unit: "kg", label: "Today"),
        ItemFact(number: "100", unit: "kg", label: "Best"),
        ItemFact(number: "112", unit: "kg", label: "Est. 1 rep"),
    ]

    var body: ItemBody {
        switch sample {
        case .sets: .sets(Self.setsBody)
        case .siblings: .siblings(Self.siblingsBody)
        case .hours: .hours(Self.hoursBody)
        }
    }

    var spec: ElementSpec {
        var answers = inheritedAnswers()
        let itemBody = body
        let kind = itemBody.name
        answers[.identity] = .says("Item page (\(kind)), a BodyElement at level 2: Facts over Body")
        answers[.frame] = .says("Facts 24,412 354 x 64 (columns 1.2 : 1 : 1), Body 24,484 354 x 292")
        answers[.shape] = .says("few: three facts over the kind's body")
        answers[.touch] = .says(kind == "siblings" ? "tap a row opens it; across on the Item title goes to the next item"
            : "none of its own; across on the Item title goes to the next item")
        answers[.moves] = .says("replace: facts and body leave softly and settle from the top, 0.38 s")
        answers[.look] = .says("number Outfit Light 28 pt, the first in the room colour, unit at half size; label 10.5 pt "
            + "tracked caps in slate; \(kind) body in its own block")
        answers[.privacy] = .says("a private item is only its label; no value reaches Facts or Body")
        return ElementSpec(
            name: "Item page (\(kind))",
            kind: .body,
            place: .page,
            shape: .few,
            frames: [2: PageFrames.block],
            levels: [2],
            neighbours: [2: PageFrames.neighbours],
            forms: [ElementFormSpec(name: kind, sizeSteps: [1], sizeFloor: 1)],
            moves: [ElementMove(name: "replace", milliseconds: 600)],
            answers: answers,
            render: { Self.draw($0, body: itemBody) },
            meaning: { _ in Self.meaning(itemBody) },
            landing: { Self.draw($0, body: itemBody) },
            unseen: unchanged
        )
    }

    static func meaning(_ body: ItemBody) -> ElementMeaning {
        ElementMeaning(
            place: .page,
            items: facts.map { ElementItem(kind: "fact", name: $0.label) },
            focus: 0,
            calls: body.name == "siblings"
                ? [ElementCall("openItem", .shell, phrases: ["open"], inputs: [CallInput("item", from: .referent)],
                               reaction: .navigate)]
                : []
        )
    }

    static func draw(_ request: RenderRequest, body: ItemBody) -> ElementRender {
        var render = ElementRender()
        let block = PageFrames.block
        let factsFrame = ItemPageLayout.factsFrame(in: block)
        for (index, column) in ItemPageLayout.columns(in: factsFrame).enumerated() {
            let fact = facts[index]
            let number = ItemPageLayout.numberSize * request.typeScale
            let numberWidth = DoorText.width(fact.number, size: number, bold: false)
            let unitSize = max(10, number / 2)
            let unitWidth = fact.unit.isEmpty ? 0 : DoorText.width(fact.unit, size: unitSize, bold: false) + 3
            let numberRect = ItemPageLayout.numberRect(in: column, scale: request.typeScale)
            if numberWidth + unitWidth > numberRect.width {
                render.clipped = true
            }
            render.runs.append(ElementRun(text: fact.number,
                                          rect: CGRect(x: numberRect.minX, y: numberRect.minY, width: numberWidth,
                                                       height: numberRect.height),
                                          size: number, ink: index == 0 ? .room : .ink))
            if unitWidth > 0 {
                render.runs.append(ElementRun(text: fact.unit,
                                              rect: CGRect(x: numberRect.minX + numberWidth + 3, y: numberRect.minY,
                                                           width: unitWidth - 3, height: numberRect.height),
                                              size: unitSize, ink: .ink, isUnit: true))
            }
            render.runs.append(ElementRun(text: fact.label.uppercased(),
                                          rect: ItemPageLayout.labelRect(in: column, scale: request.typeScale),
                                          size: ItemPageLayout.labelSize, ink: .planned, isUnit: true))
            render.shown.append(fact.label)
        }
        let bodyRender = body.render(in: ItemPageLayout.bodyFrame(in: block), scale: request.typeScale)
        render.runs += bodyRender.runs
        render.targets += bodyRender.targets
        render.shown += bodyRender.shown
        render.lost += bodyRender.lost
        render.clipped = render.clipped || bodyRender.clipped
        return render
    }
}
