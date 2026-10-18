import SwiftUI
@testable import Tessera
import TesseraCore
import Testing

/// Design's muscle figure (sheet 88/91, board 84): the drawing, its muscle map and its taps.
@MainActor
struct MuscleFigureTests {
    @Test func theSvgPathDataBecomesAPath() {
        let box = FigurePath.path("M10 20 L30 20 C30 40 10 40 10 20 Z").boundingRect
        #expect(box.minX == 10 && box.maxX == 30 && box.minY == 20)
        #expect(FigurePath.path("").isEmpty)
        #expect(FigurePath.path("Q 1 2").isEmpty, "an unknown command draws nothing rather than guessing")
    }

    @Test func everyRegionOfBothSidesParses() {
        for (_, data) in MuscleFigureArt.frontRegions + MuscleFigureArt.backRegions {
            #expect(!FigurePath.path(data).boundingRect.isEmpty, "\(data)")
        }
        for data in MuscleFigureArt.frontOutline + MuscleFigureArt.backOutline {
            #expect(!FigurePath.path(data).isEmpty)
        }
    }

    @Test func storedMusclesLandOnTheirRegionsAndSideDeltsRidesTheDelt() {
        let muscles: [(name: String, role: MuscleRole)] = [
            (name: "Chest", role: .primary), (name: "Side Delts", role: .secondary),
            (name: "Lats", role: .secondary), (name: "Chest", role: .secondary),
        ]
        let front = MuscleFigureMap.roles(muscles, back: false)
        #expect(front["Chest"] == .primary, "the stronger role wins")
        #expect(front["FrontDelts"] == .secondary)
        let back = MuscleFigureMap.roles(muscles, back: true)
        #expect(back["RearDelts"] == .secondary && back["Lats"] == .secondary)
        #expect(MuscleFigureMap.matches("Side Delts", regionID: "FrontDelts"))
        #expect(!MuscleFigureMap.matches("Chest", regionID: "Lats"))
    }

    @Test func aTapLandsInTheNearestWorkedPartOnEitherHalf() {
        let size = CGSize(width: 166, height: 365)
        let roles: [String: MuscleRole] = ["Chest": .primary]
        let place = MuscleFigure.placement(in: size)
        // The chest's centre, drawn at about (81, 120) on the left half and mirrored on the right.
        let left = CGPoint(x: 81, y: 120).applying(place)
        let right = CGPoint(x: 119, y: 120).applying(place)
        #expect(MuscleFigure.hit(left, in: size, regions: MuscleFigureArt.frontRegions, roles: roles) == "Chest")
        #expect(MuscleFigure.hit(right, in: size, regions: MuscleFigureArt.frontRegions, roles: roles) == "Chest")
        let off = CGPoint(x: 5, y: 430).applying(place)
        #expect(MuscleFigure.hit(off, in: size, regions: MuscleFigureArt.frontRegions, roles: roles) == nil)
        #expect(MuscleFigure.hit(left, in: size, regions: MuscleFigureArt.frontRegions, roles: [:]) == nil)
    }
}
