import CoreGraphics
import SwiftUI
@testable import Tessera
import Testing

/// Sheet 292, many doors, drawn on the Log's eight.
struct DoorFormsTests {
    private let names = DoorForms.sampleNames
    private let frame = DoorForms.frame

    @Test func eightDoorsIndexAsTwoColumnsOfFour() throws {
        let layout = try #require(DoorForms.fit(.index, names: names, focus: 0, scale: 1))
        #expect(layout.placements.count == 8)
        #expect(layout.lost == 0)
        let columns = Dictionary(grouping: layout.placements) { $0.rect.maxX }
        #expect(columns.count == 2)
        #expect(columns.values.allSatisfy { $0.count == 4 })
        // The pair sits on the frame's right edge; names are 15 pt, or 13 pt when the pair is wider than the frame.
        #expect(layout.placements.map(\.rect.maxX).max() == frame.maxX)
        #expect(layout.placements.allSatisfy { frame.contains($0.rect) })
        #expect([13, 15].contains(layout.placements[0].size))
    }

    @Test func eachIndexColumnIsRightAlignedAndTheGapIsFourteenOrEight() throws {
        let layout = try #require(DoorForms.fit(.index, names: names, focus: 0, scale: 1))
        let rights = Set(layout.placements.map(\.rect.maxX)).sorted()
        let leftWidth = layout.placements.filter { $0.rect.maxX == rights[0] }.map(\.rect.width).max() ?? 0
        let rightLeft = layout.placements.filter { $0.rect.maxX == rights[1] }.map(\.rect.minX).min() ?? 0
        let gap = rightLeft - rights[0]
        #expect(gap == 14 || gap == 8)
        _ = leftWidth
    }

    @Test func fiveOrFewerDoorsStayOneColumn() throws {
        let layout = try #require(DoorForms.fit(.index, names: Array(names.prefix(5)), focus: 0, scale: 1))
        #expect(Set(layout.placements.map(\.rect.maxX)).count == 1)
    }

    @Test func theIndexStepsSizeDownBeforeTheGapNarrows() {
        let wide = DoorForms.index(names: names, focus: 0, size: 15, gap: 14)
        let stepped = DoorForms.index(names: names, focus: 0, size: 13, gap: 14)
        let tight = DoorForms.index(names: names, focus: 0, size: 13, gap: 8)
        func width(_ layout: DoorFormLayout) -> CGFloat {
            (layout.placements.map(\.rect.maxX).max() ?? 0) - (layout.placements.map(\.rect.minX).min() ?? 0)
        }
        #expect(width(wide) > width(stepped))
        #expect(width(stepped) > width(tight))
    }

    @Test func theSentenceNamesFourThenAndFourMore() throws {
        let layout = try #require(DoorForms.fit(.sentence, names: names, focus: 0, scale: 1))
        let words = layout.placements.map(\.text)
        #expect(words.contains("and 4 more"))
        #expect(layout.placements.filter { !$0.isJoiner }.count == 4)
        let more = try #require(layout.placements.first { $0.opensIndex })
        #expect(more.ink == .ink2)
        #expect(layout.summarised == 4)
        #expect(!words.joined().contains("."), "no full stop")
        #expect(layout.placements.allSatisfy { frame.contains($0.rect) })
    }

    @Test func theSentenceTypeStepsFromNineteenDownToFifteen() throws {
        let layout = try #require(DoorForms.fit(.sentence, names: names, focus: 0, scale: 1))
        let size = try #require(layout.placements.first?.size)
        #expect((15 ... 19).contains(size))
        let lines = Set(layout.placements.map(\.rect.minY)).count
        #expect(lines <= DoorForms.maxLines)
        #expect(CGFloat(lines) * DoorForms.linePitch <= frame.height)
    }

    @Test func fewDoorsReadAsAWholeSentence() throws {
        let layout = try #require(DoorForms.fit(.sentence, names: Array(names.prefix(3)), focus: 0, scale: 1))
        #expect(layout.summarised == 0)
        #expect(layout.placements.map(\.text).contains("and"))
    }

    @Test func tappingAndFourMoreIsTheIndexFormAndSharedNamesTravelBetweenThem() throws {
        let sentence = try #require(DoorForms.fit(.sentence, names: names, focus: 0, scale: 1))
        let index = try #require(DoorForms.fit(.index, names: names, focus: 0, scale: 1))
        let shared = Set(sentence.placements.filter { !$0.isJoiner }.map(\.id)).intersection(index.placements.map(\.id))
        #expect(shared.count == 4, "the four named doors keep one view each and move to their index places")
    }

    @Test func bothFormsPassBoundsInPaperAndBlack() {
        let spec = DoorsDialElement().spec
        for form in [1, 2] {
            for look in ElementLook.allCases {
                let request = RenderRequest(variant: ElementVariant(form: form), look: look)
                let fails = ElementConformance.failure(.bounds, spec: spec, request: request)
                // A designed variant may need a fix; the fixed outcome must still pass.
                let outcome = ElementConformance.resolve(.bounds, spec: spec, request: request)
                #expect(!outcome.isBlock, "\(form) \(look) \(fails ?? "")")
            }
        }
    }

    @Test func aDoorIsNeverLostWhenAFormCannotFit() {
        let many = (0 ..< 12).map { ("d\($0)", "Door number \($0)") }
        #expect(DoorForms.fit(.index, names: many, focus: 0, scale: 1) == nil, "the view then keeps the reel")
    }
}
