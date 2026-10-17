import Foundation

// swiftlint:disable function_parameter_count

/// The one on-phone check every Claude-written Home line passes before it shows (board 0t; docs/ai/home-lines-job.md
/// §5 and §2c, docs/ai/line-check-vectors.md, docs/research/ai5-home-lines-eval.md C1 to C14, and the C15 house-day
/// check). Pure and deterministic: no clock, no network, no store. A failed slot keeps its rules words; a refused
/// line is never cut to fit.
///
/// Codes: `C2`/`C3` caps, `C4` stop, `C5` marks, `C6` digits licensed (as values), `C7` digits survive (D2 lets a
/// done context drop its whole clock), `C8` number words, `C9` names, `C10` grading, `C11` praise, `C12` off limits,
/// `C13` US English, `C14` a fixed item, `C15` house day (a weekday or relative-day word the finish doesn't support,
/// and "usual", "usually", "after work", "before work" outright). Not C-numbered in the eval table, so named:
/// `HOUSE` ("record" for "best"), `GREET` (greeting or apology), `NOREPEAT` (context repeats the day label's
/// weekday, the title or the hero's state), `SECRET` (a secret word or a Claude key). C1 is a whole-reply check:
/// `replyProblems`.
public enum TessLineCheck {
    public enum Slot: Sendable {
        /// The time words above the hero: 6 words, 32 characters, no stop.
        case context
        /// SO FAR: one sentence, 14 words, 80 characters, with its stop.
        case detail
    }

    public enum Verdict: Equatable, Sendable {
        case pass
        /// Claude sent nothing for this slot. Not a failure; the rules line stays.
        case noLine
        case fail([String])

        public var passes: Bool {
            self == .pass
        }
    }

    /// The finish and the moment the line is read, which C15 judges weekday and relative-day words against in his
    /// days (4 am turnover). Without it a done line may use no weekday but the day label's and no relative-day
    /// word at all, unless the rules line already holds it.
    public struct HouseDay: Sendable {
        public var finish: Date
        public var now: Date
        public var calendar: Calendar

        public init(finish: Date, now: Date, calendar: Calendar = .current) {
            self.finish = finish
            self.now = now
            self.calendar = calendar
        }
    }

    /// C1, over a whole reply: every sent handle once, no unknown handle, no duplicate. A missing handle keeps its
    /// rules line and the others still swap, so it is reported but not fatal to the rest.
    public static func replyProblems(sent: [String], returned: [String]) -> [String] {
        var problems: [String] = []
        if Set(returned).count != returned.count {
            problems.append("duplicate id")
        }
        if returned.contains(where: { !sent.contains($0) }) {
            problems.append("unknown id")
        }
        if sent.contains(where: { !returned.contains($0) }) {
            problems.append("missing id")
        }
        return problems
    }

    /// One line for one slot of one item. `rulesLine` is the rules words of that same slot (the rules context for
    /// `.context`, the rules detail for `.detail`). `title` defaults to the first name. `kind` only matters for a
    /// cook, where "steps" is the cook's own word. The weekday and "usual" bans apply to a done item (the done job
    /// is the only Claude Home job; line-check-vectors L1, L2 and L52 keep "usual" and a weekday on planned items).
    public static func check(_ line: String?, slot: Slot, numbers: [Int], names: [String], rulesLine: String?,
                             isDone: Bool, dayLabel: String?, hero: String?, title: String? = nil,
                             kind: HomeFact.Kind? = nil, fixed: Bool = false, house: HouseDay? = nil) -> Verdict
    {
        guard let line, !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .noLine }
        if fixed {
            return .fail(["C14"])
        }
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = tokens(text)
        let padded = pad(words)
        let titleText = title ?? names.first ?? ""
        let titleWords = Set(tokens(titleText))
        var codes = shapeCodes(text, raw: line, slot: slot)
        codes += digitCodes(text, numbers: numbers, rulesLine: rulesLine, clockMayDrop: slot == .context && isDone)
        codes += wordCodes(text, words: words, padded: padded, names: names, titleWords: titleWords, kind: kind)
        if slot == .context,
           repeats(
               words,
               padded: padded,
               title: tokens(titleText),
               hero: hero,
               dayLabel: dayLabel,
               rulesLine: rulesLine
           )
        {
            codes.append("NOREPEAT")
        }
        if SecretWords.mentions(text) || looksLikeClaudeKey(text) {
            codes.append("SECRET")
        }
        // C15: the house day, on a done line.
        if isDone, !houseDayHolds(words, padded: padded, dayLabel: dayLabel, rulesLine: rulesLine, house: house) {
            codes.append("C15")
        }
        var seen = Set<String>()
        codes = codes.filter { seen.insert($0).inserted }
        return codes.isEmpty ? .pass : .fail(codes)
    }

    /// C2 to C5: the slot's caps, its stop, and its marks.
    private static func shapeCodes(_ text: String, raw: String, slot: Slot) -> [String] {
        var codes: [String] = []
        let spaced = text.split(whereSeparator: \.isWhitespace).count
        switch slot {
        case .context:
            if spaced > HomeLines.contextWords {
                codes.append("C2")
            }
            if text.count > HomeLines.contextCharacters {
                codes.append("C3")
            }
            if text.hasSuffix(".") || text.hasSuffix(":") || text.hasSuffix(";") {
                codes.append("C4")
            }
        case .detail:
            if spaced > HomeLines.detailWords {
                codes.append("C2")
            }
            if text.count > HomeLines.detailCharacters {
                codes.append("C3")
            }
            let body = String(text.dropLast())
            if !text.hasSuffix(".") || body.contains("?") || body.contains("!")
                || body.firstMatch(of: /[.?!]\s/) != nil
            {
                codes.append("C4")
            }
        }
        if text.contains("!") || text.contains("…") || text.contains(" · ") || raw.contains("\n")
            || text.unicodeScalars.contains(where: isEmoji)
        {
            codes.append("C5")
        }
        return codes
    }

    /// C6, C7: digits read as values ("8:05" gives 8 and 5; "05" is 5).
    private static func digitCodes(_ text: String, numbers: [Int], rulesLine: String?, clockMayDrop: Bool) -> [String] {
        var codes: [String] = []
        let groups = digitValues(text)
        let licensed = Set(numbers)
        if groups.contains(where: { !licensed.contains($0) }) {
            codes.append("C6")
        }
        if !digitsSurvive(groups, rules: rulesLine, clockMayDrop: clockMayDrop) {
            codes.append("C7")
        }
        return codes
    }

    /// C8 to C13, the house word, and greetings.
    private static func wordCodes(_ text: String, words: [String], padded: String, names: [String],
                                  titleWords: Set<String>, kind: HomeFact.Kind?) -> [String]
    {
        var codes: [String] = []
        let numberWord = words.enumerated().contains { index, word in
            numberWords.contains(word) || (word == "one" && index + 1 < words.count
                && countNouns.contains(words[index + 1]))
        }
        if numberWord {
            codes.append("C8")
        }
        if !namesAreKnown(text, names: names, titleWords: titleWords) {
            codes.append("C9")
        }
        if words.contains(where: grading.contains) || gradingPhrases.contains(where: { padded.contains(" \($0) ") }) {
            codes.append("C10")
        }
        if words.contains(where: praise.contains) {
            codes.append("C11")
        }
        if words.contains("record") || words.contains("records") {
            codes.append("HOUSE")
        }
        // C12: a word of the item's own title is allowed; "steps" is a cook's word on a cook.
        var off = offLimits.subtracting(titleWords)
        if kind == .cook {
            off.remove("steps")
        }
        if (words.contains("legs") && !titleWords.contains("legs")) || words.contains(where: off.contains)
            || moneyMarks.contains(where: text.contains) || placePhrases.contains(where: { padded.contains(" \($0) ") })
        {
            codes.append("C12")
        }
        if words.contains(where: british.contains) {
            codes.append("C13")
        }
        if let first = words.first, greetings.contains(first) {
            codes.append("GREET")
        } else if text.lowercased().hasPrefix("good morning") || words.contains(where: apologies.contains) {
            codes.append("GREET")
        }
        return codes
    }

    /// The same check read straight off a Home line: its rules words for the slot, numbers, names, hero and fact.
    public static func check(_ line: String?, slot: Slot, for item: HomeLine, dayLabel: String?,
                             house: HouseDay? = nil) -> Verdict
    {
        check(line, slot: slot, numbers: item.numbers, names: item.names,
              rulesLine: slot == .context ? item.context : item.detail, isDone: item.fact.state == .done,
              dayLabel: dayLabel, hero: item.hero, title: item.fact.title, kind: item.fact.kind, fixed: item.fixed,
              house: house)
    }

    // MARK: C6, C7

    /// Every run of digits as a value. A run too long for an Int can match nothing licensed.
    static func digitValues(_ text: String) -> [Int] {
        text.matches(of: /\d+/).map { Int($0.output) ?? Int.max }
    }

    /// C7: every number in the rules words appears in the line at least as often. D2: on a done context the line may
    /// drop its whole clock ("7:40 pm" gives 7 and 40); if it keeps any part of the clock, all of it must stay.
    static func digitsSurvive(_ groups: [Int], rules: String?, clockMayDrop: Bool) -> Bool {
        let need = counts(HomeLines.digits(in: rules))
        let have = counts(groups)
        if need.allSatisfy({ have[$0.key, default: 0] >= $0.value }) {
            return true
        }
        guard clockMayDrop, let rules, let clock = clockDigits(in: rules) else { return false }
        var rest = need
        for value in clock {
            rest[value, default: 0] -= 1
        }
        guard rest.allSatisfy({ $0.value <= 0 || have[$0.key, default: 0] >= $0.value }) else { return false }
        // Nothing of the clock may be kept alone: the line holds no more of a clock number than the rest needs.
        return Set(clock).allSatisfy { have[$0, default: 0] <= max(rest[$0, default: 0], 0) }
    }

    private static func counts(_ values: [Int]) -> [Int: Int] {
        values.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    /// The numbers of the first clock time in some words: "7:40 pm" gives [7, 40], "7 pm" gives [7].
    private static func clockDigits(in words: String) -> [Int]? {
        guard let match = words.firstMatch(of: /\b(\d{1,2})(?::(\d{2}))?\s?(?:am|pm)\b/) else { return nil }
        return [Int(match.output.1)].compactMap(\.self) + [match.output.2.flatMap { Int($0) }].compactMap(\.self)
    }

    // MARK: C9

    /// A capitalised word other than a sentence's first must be a weekday, a month or a word of the pack's names.
    private static func namesAreKnown(_ text: String, names: [String], titleWords: Set<String>) -> Bool {
        let allowed = Set(names.flatMap(tokens)).union(titleWords)
        for match in text.matches(of: /[A-Za-z][A-Za-z']*/) {
            guard match.output.first?.isUppercase == true else { continue }
            let before = text[..<match.range.lowerBound]
            if before.allSatisfy(\.isWhitespace) || before.hasSuffix(". ") || before.hasSuffix("? ") {
                continue
            }
            var word = match.output.lowercased()
            if word.hasSuffix("'s") {
                word.removeLast(2)
            }
            if weekdayNames.contains(word) || months.contains(word) || allowed.contains(word) {
                continue
            }
            return false
        }
        return true
    }

    // MARK: No repeat

    private static func repeats(_ words: [String], padded: String, title: [String], hero: String?, dayLabel: String?,
                                rulesLine: String?) -> Bool
    {
        let rulesWords = tokens(rulesLine ?? "")
        let rulesPadded = pad(rulesWords)
        if let weekday = tokens(dayLabel ?? "").first, weekdayNames.contains(weekday), words.contains(weekday),
           !rulesWords.contains(weekday)
        {
            return true
        }
        if !title.isEmpty, padded.contains(pad(title)), !rulesPadded.contains(pad(title)) {
            return true
        }
        let heroWords = Set(tokens(hero ?? ""))
        return words.contains { stateWords.contains($0) && heroWords.contains($0) && !rulesWords.contains($0) }
    }

    // MARK: C15

    /// Whether every banned word, weekday and relative-day word in a done line is one the facts support. A word the
    /// rules line itself uses is the phone's own and always allowed.
    private static func houseDayHolds(_ words: [String], padded: String, dayLabel: String?, rulesLine: String?,
                                      house: HouseDay?) -> Bool
    {
        let rulesWords = tokens(rulesLine ?? "")
        let rulesPadded = pad(rulesWords)
        if bannedOutright.contains(where: { padded.contains(" \($0) ") }) {
            return false
        }
        let supported = supportedWeekday(dayLabel: dayLabel, house: house)
        for word in words where weekdayNames.contains(word) && word != supported && !rulesWords.contains(word) {
            return false
        }
        for phrase in relativeDayWords where padded.contains(" \(phrase) ") && !rulesPadded.contains(" \(phrase) ") {
            guard let house, relativeDaySupported(phrase, house: house) else { return false }
        }
        return true
    }

    /// The weekday of the finish's house day ("thursday" for 12:30 am Friday), else the day label's own.
    private static func supportedWeekday(dayLabel: String?, house: HouseDay?) -> String? {
        if let house {
            let day = TesseraDay(calendar: house.calendar).day(of: house.finish)
            return HomeLines.weekdays[house.calendar.component(.weekday, from: day) - 1].lowercased()
        }
        return tokens(dayLabel ?? "").first.flatMap { weekdayNames.contains($0) ? $0 : nil }
    }

    private enum Part { case morning, afternoon, evening, night }

    private static func part(of hour: Int) -> Part {
        switch hour {
        case 4 ..< 12: .morning
        case 12 ..< 17: .afternoon
        case 17 ..< 21: .evening
        default: .night
        }
    }

    private static func relativeDaySupported(_ phrase: String, house: HouseDay) -> Bool {
        let day = TesseraDay(calendar: house.calendar)
        let finishDay = day.day(of: house.finish), nowDay = day.day(of: house.now)
        let apart = house.calendar.dateComponents([.day], from: finishDay, to: nowDay).day ?? 0
        let finishPart = part(of: house.calendar.component(.hour, from: house.finish))
        switch phrase {
        case "today": return apart == 0
        case "tonight": return apart == 0 && (finishPart == .evening || finishPart == .night)
        case "this morning": return apart == 0 && finishPart == .morning
        case "this afternoon": return apart == 0 && finishPart == .afternoon
        case "this evening": return apart == 0 && finishPart == .evening
        case "yesterday": return apart == 1
        case "last night": return apart == 1 && (finishPart == .evening || finishPart == .night)
        default: return false // tomorrow: a finished workout has no tomorrow in its facts
        }
    }

    // MARK: Words

    /// Lowercase whole-word tokens: "didn't" is one word, digits and punctuation are not words.
    static func tokens(_ text: String) -> [String] {
        text.lowercased().replacingOccurrences(of: "\u{2019}", with: "'").matches(of: /[a-z]+(?:'[a-z]+)?/)
            .map { String($0.output) }
    }

    private static func pad(_ words: [String]) -> String {
        " " + words.joined(separator: " ") + " "
    }

    private static func isEmoji(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        return value >= 0x1F000 || (0x2600 ... 0x27BF).contains(value) || (0x2B00 ... 0x2BFF).contains(value)
            || value == 0xFE0F
    }
}

// swiftlint:enable function_parameter_count

/// The word lists the checks read: whole lowercase tokens, never substrings.
extension TessLineCheck {
    static let weekdayNames = Set(HomeLines.weekdays.map { $0.lowercased() })
    static let months: Set<String> = ["january", "february", "march", "april", "may", "june", "july", "august",
                                      "september", "october", "november", "december"]
    static let relativeDayWords = ["last night", "this morning", "this afternoon", "this evening", "yesterday",
                                   "tomorrow", "tonight", "today"]
    static let bannedOutright = ["usual", "usually", "as usual", "after work", "before work"]
    static let stateWords: Set<String> = ["done", "paused", "finished", "cooked"]

    static let grading: Set<String> = ["missed", "behind", "overdue", "late", "again", "only", "still", "yet",
                                       "finally", "skipped", "streak", "should", "must", "failed", "slipped",
                                       "lazy", "backlog", "lighter"]
    static let gradingPhrases = [
        "catch up",
        "need to",
        "don't forget",
        "remember to",
        "go easy",
        "take it easy",
        "push through",
    ]
    static let praise: Set<String> = ["great", "awesome", "nice", "strong", "solid", "crushed", "proud",
                                      "amazing", "job", "well"]
    static let health: Set<String> = TessMemoryScreen.healthWords.union(
        ["steps", "body", "bpm", "bmi", "blood", "weight", "kg", "lb", "lbs"]
    )
    static let money = TessMemoryScreen.moneyWords.filter { !["$", "£", "€"].contains($0) }
    static let places = TessMemoryScreen.placeWords.filter { !$0.contains(" ") }
    static let offLimits: Set<String> = health.union(money).union(places).union(["money", "mom"])
    static let moneyMarks = ["$", "£", "€"]
    static let placePhrases = ["lives at", "live at", "whole foods"]
    static let british: Set<String> = ["mum", "apologise", "apologised", "colour", "favourite", "realise",
                                       "organise", "centre", "programme", "flavour", "honour", "behaviour"]
    static let greetings: Set<String> = ["hi", "hello", "hey"]
    static let apologies: Set<String> = ["sorry", "oops", "apologize", "apologise", "apologies"]
    static let numberWords: Set<String> = ["two", "three", "four", "five", "six", "seven", "eight", "nine",
                                           "ten", "eleven", "twelve", "couple", "dozen", "half", "twenty",
                                           "thirty", "forty", "fifty", "sixty", "hundred"]
    static let countNouns: Set<String> = ["exercise", "exercises", "set", "sets", "rep", "reps", "best",
                                          "bests", "day", "days", "week", "weeks", "step", "steps", "item",
                                          "items", "thing", "things", "hour", "hours", "min", "minute",
                                          "minutes", "time", "times", "ingredient", "ingredients", "left",
                                          "more", "new", "workout", "session", "cook", "meal", "task", "tasks",
                                          "to"]
}
