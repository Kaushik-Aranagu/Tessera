// swiftlint:disable identifier_name
import CoreGraphics
import SwiftUI
@testable import Tessera
import TesseraTess
import Testing

/// Sheet 288: the conformance suite runs for every registered element. `scripts/test.sh` fails only on `.block`; the
/// `.fixed` and `.warn` lines are printed so the run lists them.
@MainActor
struct ElementConformanceTests {
    @Test func everyRegisteredElementPassesWithNoBlock() {
        #expect(!ElementRegistry.all.isEmpty)
        for element in ElementRegistry.all {
            let results = ElementConformance.run(spec: element.spec)
            for line in ElementConformance.report(results) {
                print("ELEMENT \(line)")
            }
            let blocks = ElementConformance.blocks(results)
            #expect(blocks.isEmpty, "\(element.spec.name): \(blocks.map { "\($0.check.rawValue) \($0.outcome)" })")
        }
    }

    @Test func theDoorsDialIsTheFirstRegisteredElement() {
        #expect(ElementRegistry.all.first?.spec.name == "Doors")
        #expect(ElementRegistry.contains("Doors"))
    }

    @Test func anUnregisteredElementFailsRegistered() {
        var spec = DoorsDialElement().spec
        spec.name = "Stray"
        let results = ElementConformance.run(spec: spec)
        let registered = results.first { $0.check == .registered }
        #expect(registered?.outcome.isBlock == true)
        #expect(!ElementConformance.blocks(results).isEmpty)
    }

    @Test func everyCheckOfTheSheetRuns() {
        let results = ElementConformance.run(spec: DoorsDialElement().spec)
        let ran = Set(results.map(\.check))
        #expect(ran == Set(ElementCheckName.allCases))
        #expect(ElementCheckName.allCases.filter { $0.tier == .should }.count == 5)
        #expect(ElementCheckName.allCases.filter { $0.tier == .must }.count == 11)
    }

    @Test func formsAndLooksAreAllChecked() {
        let results = ElementConformance.run(spec: DoorsDialElement().spec)
        let forms = Set(results.compactMap(\.form))
        #expect(forms == ["reel", "index", "sentence"])
        #expect(Set(results.compactMap(\.look)) == [.paper, .black])
    }

    @Test func aFailingMustCheckIsFixedBySteppingDown() {
        // Eight doors at 15 pt in two columns with a 14 pt gap do not fit 160 pt; the size steps down, then the gap.
        let spec = DoorsDialElement(names: DoorForms.sampleNames.map { ($0.id, $0.name + " and more") }).spec
        let request = RenderRequest(variant: ElementVariant(form: 1))
        let outcome = ElementConformance.resolve(.bounds, spec: spec, request: request)
        switch outcome {
        case let .fixed(by, _): #expect(by.first == .size)
        case .block: break // nothing fits: the suite blocks rather than ship it
        default: Issue.record("expected fixed or block, got \(outcome)")
        }
    }

    @Test func aShouldCheckWarnsAndNeverBlocks() {
        var spec = DoorsDialElement().spec
        spec.moves = [ElementMove(name: "slow", milliseconds: 1500)]
        spec.returnPlays = 9
        let results = ElementConformance.run(spec: spec)
        let timing = results.first { $0.check == .timing }
        let back = results.first { $0.check == .returning }
        if case .warn = timing?.outcome {} else {
            Issue.record("timing should warn")
        }
        if case .warn = back?.outcome {} else {
            Issue.record("return should warn")
        }
        #expect(!ElementConformance.blocks(results).contains { $0.check == .timing || $0.check == .returning })
    }

    @Test func aMissingTemplateEntryWarns() {
        var spec = DoorsDialElement().spec
        spec.answers[.privacy] = nil
        let template = ElementConformance.run(spec: spec).first { $0.check == .template }
        if case let .warn(reason)? = template?.outcome {
            #expect(reason.contains("privacy"))
        } else {
            Issue.record("template should warn")
        }
    }

    @Test func aColourTraitBreaksTheWalls() {
        var spec = DoorsDialElement().spec
        spec.forms[0].traits = ["colour"]
        let walls = ElementConformance.run(spec: spec).filter { $0.check == .walls }
        #expect(walls.contains { $0.outcome.isBlock })
    }

    @Test func aDeviceOnlyFactOnAFrameBlocks() {
        var spec = DoorsDialElement().spec
        let base = spec.render
        spec.render = { request in
            var render = base(request)
            render.facts = [ElementFact("Rent 1400", taint: .deviceOnly)]
            return render
        }
        #expect(ElementConformance.run(spec: spec).contains { $0.check == .walls && $0.outcome.isBlock })
    }

    @Test func textOverAnotherElementsFrameBlocksBounds() {
        var spec = DoorsDialElement().spec
        spec.neighbours[0] = [CGRect(x: 300, y: 640, width: 78, height: 120)]
        #expect(ElementConformance.run(spec: spec).contains { $0.check == .bounds && $0.outcome.isBlock })
    }

    @Test func aLayerAboveThePlacesNeedsItsGround() {
        var spec = DoorsDialElement().spec
        spec.layer = .words
        #expect(ElementConformance.run(spec: spec).contains { $0.check == .layers && $0.outcome.isBlock })
        #expect(SurfaceLayer.allCases.count == 9)
        #expect(DoorsDialElement().spec.layer == .places)
    }

    @Test func contrastMathIsWCAG() {
        #expect(abs(ElementConformance.contrastRatio(0x000000, 0xFFFFFF) - 21) < 0.01)
        #expect(ElementConformance.contrastRatio(0x777777, 0xFFFFFF) < 4.6)
    }

    @Test func theMeaningDoesNotDependOnTheForm() {
        let spec = DoorsDialElement().spec
        let meanings = (0 ..< spec.forms.count).map { spec.meaning(RenderRequest(variant: ElementVariant(form: $0))) }
        #expect(Set(meanings.map(\.items.count)) == [8])
        #expect(meanings.allSatisfy { $0 == meanings[0] })
        #expect(meanings[0].calls.first?.name == "openDoor")
    }
}
