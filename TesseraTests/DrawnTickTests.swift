import SwiftUI
@testable import Tessera
import Testing

struct DrawnTickTests {
    /// Sheets 313 and 314: the first whole number in a count line is the one that rolls; the words stay.
    @Test func onlyTheFirstNumberRolls() throws {
        let parts = try #require(RollingLine.split("3 of 7"))
        #expect(parts.before == "" && parts.number == 3 && parts.after == " of 7")
        let left = try #require(RollingLine.split("5 steps, about 10 min left"))
        #expect(left.before == "" && left.number == 5 && left.after == " steps, about 10 min left")
        #expect(RollingLine.split("nothing on it yet") == nil)
        let later = try #require(RollingLine.split("Packing, 6 left"))
        #expect(later.before == "Packing, " && later.number == 6 && later.after == " left")
    }

    /// Sheet 300: the stroke runs from the short arm's start, through the elbow, to the long arm's end.
    @Test func theTickRunsFromTheShortArmToTheLongArm() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = TickShape().path(in: rect)
        #expect(path.boundingRect.minX >= 15 && path.boundingRect.maxX <= 87)
        #expect(TickShape.start.x < TickShape.elbow.x && TickShape.elbow.x < TickShape.end.x)
        #expect(TickShape.elbow.y > TickShape.start.y && TickShape.end.y < TickShape.elbow.y)
        #expect(TickShape.shortArmShare > 0.2 && TickShape.shortArmShare < 0.5)
        #expect(DrawnTick.drawSeconds == 0.16 && DrawnTick.faint == 0.18)
        #expect(DrawnTick.pressLength == 1.7 && DrawnTick.pressExtra == 0.7)
    }
}
