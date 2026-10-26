import Foundation
@testable import Tessera
import Testing

struct TessWordsTests {
    @Test func wordsArriveSixtyTwoMillisecondsApartAndFortyMoreAfterPunctuation() {
        let arrivals = TessWords.arrivals("Done, Stretch is at 9 pm.")
        #expect(arrivals.map(\.word) == ["Done,", "Stretch", "is", "at", "9", "pm."])
        #expect(arrivals[0].delay == 0)
        #expect(abs(arrivals[1].delay - (0.062 + 0.040)) < 1e-9)
        #expect(abs(arrivals[2].delay - (0.062 + 0.040 + 0.062)) < 1e-9)
        #expect(abs(TessWords.total("Hi there.") - (0.062 + 0.180)) < 1e-9)
    }

    @Test func eachWordRisesThreePointsOverOneEightyAndNeverFades() {
        #expect(TessWords.offset(elapsed: 0, delay: 0) == 3)
        #expect(TessWords.offset(elapsed: 0.18, delay: 0) == 0)
        #expect(TessWords.offset(elapsed: 0.09, delay: 0) > 0 && TessWords.offset(elapsed: 0.09, delay: 0) < 3)
        #expect(!TessWords.isShown(elapsed: 0.05, delay: 0.1) && TessWords.isShown(elapsed: 0.1, delay: 0.1))
    }

    @Test func aTimeMarkerAppearsOnlyAfterAGapOfTwentyMinutesOrMore() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let locale = Locale(identifier: "en_US")
        let base = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 23,
            hour: 12,
            minute: 0
        )))
        let times = [
            base,
            base.addingTimeInterval(5 * 60),
            base.addingTimeInterval(31 * 60),
            base.addingTimeInterval(51 * 60),
        ]
        let markers = TessTimeMarker.markers(for: times, calendar: calendar, locale: locale)
        #expect(markers == [nil, nil, "12:31 pm", "12:51 pm"])
        let opening = TessTimeMarker.openingMarker(
            last: times[3],
            now: times[3].addingTimeInterval(40 * 60),
            calendar: calendar,
            locale: locale
        )
        #expect(opening == "Now, 1:31 pm")
        #expect(TessTimeMarker.openingMarker(
            last: times[3],
            now: times[3].addingTimeInterval(5 * 60),
            calendar: calendar,
            locale: locale
        ) == nil)
    }

    @Test func theEchoFindsTheLatestEarlierMentionByShownLabel() {
        let earlier = ["Tonight is Push day at 6, then Stretch at 8.", "Added limes to Groceries.", "Push day moved."]
        let found = TessEcho.earlierMention(of: ["Stretch", "Push day"], in: earlier)
        #expect(found?.line == 2 && found?.name == "Push day")
        #expect(TessEcho.earlierMention(of: ["Tacos"], in: earlier) == nil)
        #expect(!TessEcho.mentions("Push", in: "Pushed"), "whole words only")
    }
}
