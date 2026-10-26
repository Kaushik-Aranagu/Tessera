import SwiftUI
import CoreGraphics
import Testing
@testable import Tessera

/// Sheet 283 v4: every point belongs to a named place; empty places are kept and never filled by a neighbour.
@Suite struct LandingPlacesTests {
    private let screen = CGRect(x: 0, y: 0, width: 402, height: 874)

    @Test func everyPlaceIsOnTheScreen() {
        for place in LandingPlace.allCases {
            #expect(screen.contains(place.frame), "\(place) leaves the screen")
        }
    }

    @Test func placesNeverOverlap() {
        let places = LandingPlace.allCases
        for (index, first) in places.enumerated() {
            for second in places[(index + 1)...] {
                #expect(!first.frame.intersects(second.frame), "\(first) overlaps \(second)")
            }
        }
    }

    @Test func theScreenIsCoveredTopToBottom() {
        // The vertical bands tile 0 ... 874 with no gap: a breath is a place, never a hole.
        let bands = LandingPlace.allCases.sorted { $0.frame.minY < $1.frame.minY }
        var cursor: CGFloat = 0
        for band in bands {
            #expect(band.frame.minY == cursor, "a gap before \(band)")
            cursor = band.frame.maxY
        }
        #expect(cursor == 874)
    }

    @Test func theThreeBreathsAreTheEmptyPlaces() {
        let breaths = LandingPlace.allCases.filter(\.isBreath)
        #expect(breaths.count == 3)
        #expect(breaths.map(\.frame.minY) == [182, 612, 760])
    }

    @Test func theKitSlotsAreThePlaces() {
        #expect(LandingKeystone<EmptyView>.size == LandingPlace.keystone.frame.size)
        #expect(LandingKeystone<EmptyView>.top == LandingPlace.keystone.frame.minY)
        #expect(LandingWidget<EmptyView>.top == LandingPlace.widget.frame.minY)
    }

    @Test func childrenStayInsideTheirParent() {
        let masthead = LandingPlace.masthead.frame
        let children: [CGRect] = [LandingPlace.Masthead.title, LandingPlace.Masthead.navWord, LandingPlace.Masthead.switcher,
                                  LandingPlace.Masthead.needs, LandingPlace.Masthead.settingsWord,
                                  LandingPlace.Masthead.departureBoard]
        for child in children {
            #expect(masthead.contains(child))
        }
        #expect(LandingPlace.widget.frame.contains(LandingPlace.Widget.glyph))
        #expect(LandingPlace.doors.frame.contains(LandingPlace.Doors.dial))
        #expect(LandingPlace.doors.frame.contains(LandingPlace.Doors.summary))
        #expect(LandingPlace.foot.frame.contains(LandingPlace.Foot.actionWord))
        // Tess is 96 tall from the foot's top, so she reaches into the home bar's strip: she stays on the screen.
        #expect(screen.contains(LandingPlace.Foot.tess))
    }
}
