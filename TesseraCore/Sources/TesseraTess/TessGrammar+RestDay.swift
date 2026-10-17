import Foundation
import TesseraCore

extension TessGrammar {
    private static let weekdayNames: [String: Int] = [
        "sunday": 1, "sun": 1, "monday": 2, "mon": 2, "tuesday": 3, "tue": 3, "tues": 3,
        "wednesday": 4, "wed": 4, "thursday": 5, "thu": 5, "thur": 5, "thurs": 5,
        "friday": 6, "fri": 6, "saturday": 7, "sat": 7,
    ]

    /// RG3 (Research 146): "rest day Sunday", "make Sunday my rest day", "my rest day is Sunday", "Sunday is my rest
    /// day" set the rest weekday; never a task called "Rest day". Only a bare weekday: "rest day today" and "rest
    /// day Sunday morning" are not this rule.
    func parseSetRestWeekday(text: String) -> Parse? {
        let day = "(sunday|sun|monday|mon|tuesday|tues|tue|wednesday|wed|thursday|thurs|thur|thu|friday|fri|saturday|sat)"
        let shapes = [
            "^(?:set |make |change )?(?:my )?(?:weekly )?rest day(?: to| on| is| =)? \(day)$",
            "^(?:set |make |change )?\(day)(?: as| to be)? my(?: weekly)? rest day$",
            "^\(day) is(?: going to be)? my(?: weekly)? rest day$",
            "^\(day) rest day$",
        ]
        for shape in shapes {
            if let regex = try? Regex(shape), let match = text.firstMatch(of: regex),
               match.output.count > 1, let word = match.output[1].substring,
               let weekday = Self.weekdayNames[String(word)]
            {
                return .setRestWeekday(weekday: weekday)
            }
        }
        return nil
    }
}
