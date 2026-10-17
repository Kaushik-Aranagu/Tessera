import Foundation

/// Money and body facts stay on the phone (Product 999df84, Research 129 MU2 and 138 MW1/MW7; docs/ai/architecture.md
/// §7). One check for every Claude caller: the router skips Claude's route for a walled phrase before any
/// `isAvailable`, Claude's own route refuses it again, and the inbox never keeps one. The grammar and the phone's own
/// model may still read it. A money or body word with no number passes (W4): "pay rent fri" is a task. In the past
/// tense the past-tense log wins over W4: "paid rent fri" and "bought milk sat" are ordinary dated notes, not tasks
/// and not private (Product, 12:21 PM PT Oct 16).
public enum PrivateFacts {
    /// Whether a title must stay off surfaces he doesn't unlock (Siri read-backs, the Live Activity, Spotlight): a
    /// secret word, money or a body fact (Product P14, decisions 12:26 PM PT Oct 16).
    /// `lastWeightKg` is his last logged body weight, or nil with none logged or with a set in focus (a number is then
    /// the bar). No default: every caller says which (board 0ai, Product 4:46 PM PT).
    public static func isPrivateTitle(_ title: String, lastWeightKg: Double?) -> Bool {
        title == SecretWords.title || SecretWords.mentions(title) || isWalled(title, lastWeightKg: lastWeightKg)
    }

    /// Whether a phrase must never reach Claude: money-shaped or body-shaped (secret words have their own wall).
    public static func isWalled(_ phrase: String, lastWeightKg: Double?) -> Bool {
        isMoneyShaped(phrase) || isBodyShaped(phrase, lastWeightKg: lastWeightKg)
    }

    // MARK: Money (W1)

    /// Currency words, spend and pay words, accounts, and the memory screen's money words (one list for both walls).
    static let moneyWords: Set<String> = TessMemoryScreen.moneyWords.union([
        "usd", "dollar", "dollars", "bucks", "buck", "gbp", "pound", "pounds", "quid", "tenner", "fiver", "eur", "euro",
        "euros", "inr", "rs", "rupee", "rupees", "cad", "aud", "chf", "jpy", "yen", "spend", "paid", "pay",
        "cost", "costs", "refund", "refunded", "tip", "tipped", "venmo", "venmoed", "zelle", "zelled", "paypal", "owe",
        "owes", "balance", "checking", "savings", "salary", "paycheck", "copay", "rent",
    ])

    /// Whether a phrase is money-shaped: a currency sign, a money word with an amount, or an amount with exactly two
    /// decimals ("costco 212.37", "coffee 6.25 today"). Training notation ("82.50 x 8", "80 for 8", "5 reps") and
    /// clock times ("3pm") are never money.
    public static func isMoneyShaped(_ phrase: String) -> Bool {
        let lower = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lower.isEmpty else { return false }
        // "paid" or "spent" with an amount is always money, even shaped like a set: "paid 20 for 2 tickets" (L3).
        // "bought a tv for 800" is a spend too; "bought 2 lemons" is not (QA F2 on #534).
        let spent = (lower.firstMatch(of: /\b(?:paid|spent|spend)\b/) != nil
            || lower.firstMatch(of: /\bbought\b.*\bfor\s+\d/) != nil) && hasAmount(lower)
        guard spent || !isTraining(lower) else { return false }
        if spent || lower.contains(where: { "$£€₹¥".contains($0) }) {
            return true
        }
        let words = words(withoutTimes(lower))
        if words.contains(where: isAmount), words.contains(where: moneyWords.contains) {
            return true
        }
        return words.contains { $0.wholeMatch(of: /\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2}|\d+,\d{2}/) != nil }
    }

    // MARK: Body (W2, W3)

    /// Research private-health-words CR1: "sick of rice", "that set was sick", "sick beat".
    nonisolated(unsafe) static let sickSlang: [Regex<Substring>] = [
        /\bsick\s+of\b/,
        /\b(?:set|lift|pr|workout|session|pump|song|view|beat|car|shot|play|trick)\s+(?:was|is|looks|looked)?\s*sick\b/,
        /\bsick\s+(?:set|lift|pr|workout|session|pump|song|view|beat|car|shot|play|trick)\b/,
    ]

    /// "log my weight 82.4" is his weight (Research, Siri BX): Siri would speak the number back.
    static let weighWords: Set<String> = ["weigh", "weighs", "weighed", "weighing", "weigh-in", "weight", "bw",
                                          "scale"]
    static let bodyUnits: Set<String> = ["lb", "lbs", "kg", "kgs", "pounds", "kilos"]
    static let dayWords: Set<String> = ["this", "morning", "today", "tonight", "evening", "night", "am", "pm", "at",
                                        "yesterday", "now", "in", "me", "i", "my", "was", "is"]
    /// Words that make a bare number his body weight (Product 4:46 PM PT): "my weight is 82.4, good?".
    static let bodyWords: Set<String> = ["weight", "weigh", "weighed", "kg", "lb", "lbs", "bmi"]
    /// A number with one of these after it is something else: a duration, a distance, food, a share or a set
    /// (Product 4:55 PM PT): "80 min walk", "75 g oats", "85% done".
    static let otherUnits: Set<String> = ["min", "mins", "minute", "minutes", "h", "hr", "hrs", "hour", "hours", "km",
                                          "mi", "mile", "miles", "g", "gram", "grams", "%", "cal", "cals", "kcal",
                                          "rep", "reps", "set", "sets", "x", "×", "oz", "ml", "cup", "cups"]
    static let vitals: Set<String> = ["bp", "hr", "hrv", "spo2", "pulse", "resting", "temp", "temperature", "glucose",
                                      "bpm", "systolic", "diastolic"]
    public static let medicines: Set<String> = ["advil", "tylenol", "ibuprofen", "acetaminophen", "aspirin", "aleve",
                                                "lexapro", "zoloft", "sertraline", "prozac", "adderall", "xanax",
                                                "melatonin",
                                                "benadryl", "claritin", "zyrtec", "pill", "pills", "tablet", "tablets",
                                                "capsule", "capsules", "dose", "meds", "medication"]
    /// Symptoms and hurts: walled with no number (Product on QA L1): "knee hurts", "headache", "slept badly".
    static let symptoms: Set<String> = ["migraine", "nausea", "nauseous", "fever", "rash", "headache", "vomiting",
                                        "vomited", "dizzy", "diarrhea", "cramps", "insomnia", "symptoms", "hurts",
                                        "hurt", "hurting", "aches", "ache", "aching", "sore", "injured", "sprained",
                                        "slept", "cramping", "sick", "unwell"]
    /// Kitchen units: "weigh the flour 500 g" is the kitchen, not his body (MB34).
    static let kitchenUnits: Set<String> = ["g", "gram", "grams", "oz", "ml", "cup", "cups", "tbsp", "tsp"]

    /// Whether a phrase is a fact about his body: his weight, a vital, sleep as a fact, a medicine or a symptom. A lift
    /// weight is the bar, not his body (MB31, MB32); food amounts and distances pass (MB33, MB40).
    public static func isBodyShaped(_ phrase: String, lastWeightKg: Double?) -> Bool {
        let lower = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lower.isEmpty, !isTraining(lower) else { return false }
        if isBareWeight(lower, lastWeightKg: lastWeightKg) {
            return true
        }
        let words = words(lower)
        let hasNumber = words.contains { $0.first?.isNumber == true }
        // "Feeling sick" is a body fact (HW19, health slice 1); slang and "sick of" are not (Research CR1).
        let sickOf = Self.sickSlang.contains { lower.firstMatch(of: $0) != nil }
        if words.contains(where: { symptoms.contains($0) && !($0 == "sick" && sickOf) }) || lower
            .firstMatch(of: /\d\s*(?:mg|mcg)\b/) != nil
            || lower.firstMatch(of: /\bbody\s?fat\b|\bbf\s*\d/) != nil
        {
            return true
        }
        guard hasNumber else { return false }
        if words.contains(where: medicines.contains) || words.contains("slept") || words
            .contains(where: vitals.contains)
            || lower.contains("blood pressure") || lower.contains("heart rate")
        {
            return true
        }
        if words.contains(where: weighWords.contains) {
            return !words.contains(where: kitchenUnits.contains) && !words.contains { $0.wholeMatch(of: /\d+g/) != nil }
        }
        // A lone number with a body unit, or a bare decimal, and only day words: "182.4 this morning".
        let rest = words.filter { $0.first?.isNumber != true && !bodyUnits.contains($0) }
        let unitOrDecimal = words.contains(where: bodyUnits.contains) || words.contains { $0.contains(".") }
            || words.contains { $0.wholeMatch(of: /\d+(?:\.\d+)?(?:lbs?|kgs?)/) != nil }
        return unitOrDecimal && rest.allSatisfy(dayWords.contains)
    }

    /// Words before a number that make it a name, not an amount ("room 82", "bus 76").
    static let namingWords = ["room", "rm", "gate", "bus", "route", "line", "flat", "apt", "apartment", "unit", "suite",
                              "platform", "table", "seat", "row", "floor", "level", "page", "chapter", "exit", "highway",
                              "hwy", "no", "number", "order", "ticket", "flight"]
    nonisolated(unsafe) static let namedNumber = try! Regex( // swiftlint:disable:this force_try
        #"\b(?:"# + namingWords.joined(separator: "|") + #")\s*#?\s*\d+\b|#\s*\d+\b"#
    )

    /// A bare number that is his weight (Product 2:56 and 4:46 PM PT): within 10% of his last logged weight, with or
    /// without a day word ("is 82.4 good?", "how's 76 looking?"); with none logged, a decimal beside a body word
    /// ("my weight is 82.4"). A number with another unit after it stays plain, read on the raw phrase ("85% done").
    static func isBareWeight(_ lower: String, lastWeightKg: Double?) -> Bool {
        // A price is never his weight, per pound or not ("chicken $1.29/lb"; Research US3), and nor is a number that
        // names something ("room 82", "bus 76", "#80"; QA low on 0ai).
        let text = withoutTimes(lower).replacing(/[$£€₹¥]\s?\d[\d,]*(?:\.\d+)?(?:\s*\/\s*[a-z]+)?/, with: " ")
            .replacing(namedNumber, with: " ")
        let numbers = text.matches(of: /(\d+(?:[.,]\d+)?)\s*(%|×|[a-z]+)?/).compactMap { match -> Double? in
            let unit = match.output.2.map(String.init)
            guard unit.map({ !otherUnits.contains($0) }) ?? true,
                  var value = Double(match.output.1.replacingOccurrences(of: ",", with: ".")) else { return nil }
            if let unit, ["lb", "lbs", "pounds"].contains(unit) {
                value *= 0.453_592
            }
            return value
        }
        guard !numbers.isEmpty else { return false }
        if let last = lastWeightKg, last > 0, numbers.contains(where: { abs($0 - last) <= last * 0.1 }) {
            return true
        }
        let bodyWord = words(text).contains(where: bodyWords.contains) || text.contains("body fat")
        return bodyWord && text.firstMatch(of: /\d[.,]\d/) != nil
    }

    // MARK: Shared

    /// The words of a phrase: letters and digits, with "." and "," kept inside numbers.
    static func words(_ lower: String) -> [String] {
        lower.split { !$0.isLetter && !$0.isNumber && $0 != "." && $0 != "," && $0 != "-" }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".,-")) }
            .filter { !$0.isEmpty }
    }

    /// Whether a phrase holds an amount: a number that is not a clock time.
    public static func hasAmount(_ phrase: String) -> Bool {
        words(withoutTimes(phrase.lowercased())).contains(where: isAmount)
    }

    /// The phrase with clock times taken out ("7:30", "3pm", "11 am"), so a time is never an amount.
    static func withoutTimes(_ lower: String) -> String {
        lower.replacing(/\b\d{1,2}:\d{2}\s*(?:am|pm)?|\b\d{1,2}\s*(?:am|pm)\b/, with: " ")
    }

    /// A number that is an amount, not a clock time ("3pm", "7:30" are times).
    static func isAmount(_ word: String) -> Bool {
        word.first?.isNumber == true && word.wholeMatch(of: /\d{1,2}(?:am|pm)/) == nil
    }

    /// Set notation: a weight by reps is the bar, never money or his body.
    static func isTraining(_ lower: String) -> Bool {
        lower.firstMatch(of: /\d\s*(?:x|×|for|by)\s*\d/) != nil || lower.firstMatch(of: /\d\s*reps?\b/) != nil
    }
}
