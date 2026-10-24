import Foundation

/// The bulk of the bank: the same kinds over every exercise, recipe, month and room, so a run asks about 200
/// questions and a miss shows a pattern ("counts across months fail on Haiku") rather than one bad answer. Every
/// answer is computed from the world's rows. Counts of zero are left out: "none" is a right answer the exact scorer
/// can't read.
extension EvalWorldKey {
    static let exercises = ["Bench Press", "Overhead Press", "Incline Bench Press", "Deadlift", "Barbell Row",
                            "Lat Pulldown", "Back Squat", "Romanian Deadlift"]

    func monthText(_ year: Int, _ month: Int) -> String {
        let date = EvalWorld.at(year, month, 15)
        return MemoryEval.formatter("MMMM yyyy", calendar: calendar).string(from: date)
    }

    /// The last 12 whole months before now: Oct 2025 through Sep 2026 for the small world.
    var months: [(year: Int, month: Int)] {
        let list = (1 ... 12).compactMap { back -> (year: Int, month: Int)? in
            guard let date = calendar.date(byAdding: .month, value: -back, to: world.now) else { return nil }
            let parts = calendar.dateComponents([.year, .month], from: date)
            guard let year = parts.year, let month = parts.month else { return nil }
            return (year: year, month: month)
        }
        return Array(list.reversed())
    }

    func bank() -> [WorldQuestion] {
        bests() + monthlyWorkouts() + recipeCounts() + firstCooks() + bodyQuestions() + moneyByMonth()
            + homeQuestions() + moreFollowUps() + moreAcrossRooms() + morePrivate()
    }

    func bests() -> [WorldQuestion] {
        Self.exercises.compactMap { exercise in
            guard let best = best(exercise) else { return nil }
            return WorldQuestion(id: "bank/best/\(exercise)", kind: .lookUp,
                                 turns: ["What's the heaviest I've done on \(exercise)?"],
                                 expected: .number(best.set.weight, unit: "kg"), tools: ["query"])
        }
    }

    func monthlyWorkouts() -> [WorldQuestion] {
        months.compactMap { year, month -> WorldQuestion? in
            let count = workouts.filter { inMonth($0.start, year, month) }.count
            guard count > 0 else { return nil }
            return WorldQuestion(id: "bank/workouts/\(year)-\(month)", kind: .count,
                                 turns: ["How many workouts did I do in \(monthText(year, month))?"],
                                 expected: .number(Double(count), unit: nil), tools: ["query"])
        }
    }

    /// Each recipe in September and October, where it was cooked at all.
    func recipeCounts() -> [WorldQuestion] {
        world.recipes.flatMap { recipe in
            [(2026, 9), (2026, 10)].compactMap { pair -> WorldQuestion? in
                let (year, month) = pair
                let count = cooks(recipe, year: year, month: month)
                guard count > 0 else { return nil }
                return WorldQuestion(id: "bank/cooks/\(recipe)/\(year)-\(month)", kind: .count,
                                     turns: ["How many times did I cook \(recipe) in \(monthText(year, month))?"],
                                     expected: .number(Double(count), unit: nil), tools: ["query"])
            }
        }
    }

    func firstCooks() -> [WorldQuestion] {
        world.recipes.compactMap { recipe in
            guard let first = world.cooks.filter({ $0.recipe == recipe }).map(\.day).min() else { return nil }
            return WorldQuestion(id: "bank/firstCook/\(recipe)", kind: .when,
                                 turns: ["When did I first cook \(recipe)?"], expected: .day(first), tools: ["query"])
        }
    }

    /// Weigh-ins and nights on eight spread-out days, and the change in weight over the year.
    func bodyQuestions() -> [WorldQuestion] {
        var out: [WorldQuestion] = []
        let weighStep = max(1, world.weighIns.count / 8)
        for weighIn in stride(from: 0, to: world.weighIns.count, by: weighStep).prefix(8).map({ world.weighIns[$0] }) {
            out.append(.init(id: "bank/weight/\(MemoryEval.stamp(weighIn.at, calendar: calendar))", kind: .lookUp,
                             turns: ["What did I weigh on \(dayText(weighIn.at))?"],
                             expected: .number(weighIn.kg, unit: "kg"), tools: ["query"]))
        }
        let nightStep = max(1, world.nights.count / 8)
        for night in stride(from: 0, to: world.nights.count, by: nightStep).prefix(8).map({ world.nights[$0] }) {
            out.append(.init(id: "bank/sleep/\(MemoryEval.stamp(night.day, calendar: calendar))", kind: .lookUp,
                             turns: ["How many hours did I sleep the night before \(dayText(night.day))?"],
                             expected: .number(night.hours, unit: "hours"), tools: ["query"]))
        }
        if let first = world.weighIns.first, let last = world.weighIns.last {
            out.append(.init(id: "bank/weight/change", kind: .math,
                             turns: ["How much weight have I lost since \(dayText(first.at))?"],
                             expected: .number(((first.kg - last.kg) * 10).rounded() / 10, unit: "kg"),
                             tools: ["query"]))
        }
        return out
    }

    func moneyByMonth() -> [WorldQuestion] {
        var out: [WorldQuestion] = []
        for (year, month) in months {
            let coffee = spent("coffee", year: year, month: month)
            if coffee > 0 {
                out.append(.init(id: "bank/coffee/\(year)-\(month)", kind: .math,
                                 turns: ["How much did I spend on coffee in \(monthText(year, month))?"],
                                 expected: .number(coffee, unit: nil), tools: ["query"]))
            }
            let eatingOut = spent("eating out", year: year, month: month)
            if eatingOut > 0, month % 2 == 0 {
                out.append(.init(id: "bank/eatingOut/\(year)-\(month)", kind: .math,
                                 turns: ["How much did I spend eating out in \(monthText(year, month))?"],
                                 expected: .number(eatingOut, unit: nil), tools: ["query"]))
            }
        }
        out.append(.init(id: "dontKnow/car-insurance", kind: .dontKnow,
                         turns: ["How much do I pay for car insurance?"], expected: .dontKnow))
        return out
    }

    /// Chores, habits and the calendar.
    func homeQuestions() -> [WorldQuestion] {
        var out: [WorldQuestion] = []
        if let plants = world.chores.first(where: { $0.title == "Water the plants" })?.done.max() {
            out.append(.init(id: "bank/chore/plants-last", kind: .when,
                             turns: ["When did I last water the plants?"], expected: .day(plants), tools: ["query"]))
        }
        if let trash = world.chores.first(where: { $0.title == "Take out the trash" }) {
            let count = trash.done.filter { inMonth($0, 2026, 9) }.count
            out.append(.init(id: "bank/chore/trash-sep", kind: .count,
                             turns: ["How many times did I take out the trash in September?"],
                             expected: .number(Double(count), unit: nil), tools: ["query"]))
        }
        if let reading = world.habits.first(where: { $0.name == "Read 20 minutes" }) {
            let august = reading.done.filter { inMonth($0, 2026, 8) }.count
            out.append(.init(id: "bank/habit/reading-aug", kind: .count,
                             turns: ["How many days did I read in August?"],
                             expected: .number(Double(august), unit: nil), tools: ["query"]))
            out.append(.init(id: "bank/habit/longest-reading", kind: .math,
                             turns: ["What's my longest reading streak, in days?"],
                             expected: .number(Double(longestRun(reading.done)), unit: nil), tools: ["query"]))
        }
        if let moving = world.events.first(where: { $0.title == "Moving day" }) {
            out.append(.init(id: "bank/event/moving", kind: .when, turns: ["When was moving day?"],
                             expected: .day(moving.start), tools: ["query"]))
        }
        let meetings = world.events.filter { $0.title == "Team meeting" && inMonth($0.start, 2026, 9) }.count
        out.append(.init(id: "bank/event/meetings-sep", kind: .count,
                         turns: ["How many team meetings did I have in September?"],
                         expected: .number(Double(meetings), unit: nil), tools: ["query"]))
        return out
    }

    func longestRun(_ days: [Date]) -> Int {
        var longest = 0, run = 0
        var previous: Date?
        for done in days.sorted() {
            let day = calendar.startOfDay(for: done)
            if let previous, calendar.dateComponents([.day], from: previous, to: day).day == 1 {
                run += 1
            } else if previous.map({ !calendar.isDate($0, inSameDayAs: day) }) ?? true {
                run = 1
            }
            longest = max(longest, run)
            previous = day
        }
        return longest
    }

    /// A count, then "and the month before?", for the five recipes cooked most in October.
    func moreFollowUps() -> [WorldQuestion] {
        let october = Dictionary(grouping: world.cooks.filter { inMonth($0.day, 2026, 10) }, by: { $0.recipe })
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0 < $1.0 }
            .prefix(5)
        return october.compactMap { recipe, _ in
            let september = cooks(recipe, year: 2026, month: 9)
            guard september > 0 else { return nil }
            return WorldQuestion(id: "bank/followUp/\(recipe)", kind: .followUp,
                                 turns: ["How many times did I cook \(recipe) in October?",
                                         "And the month before?"],
                                 expected: .number(Double(september), unit: nil), tools: ["query"])
        }
    }

    func moreAcrossRooms() -> [WorldQuestion] {
        guard let squat = best("Back Squat"),
              let week = calendar.dateInterval(of: .weekOfYear, for: squat.day) else { return [] }
        var out: [WorldQuestion] = []
        if let weighIn = world.weighIns.first(where: { week.contains($0.at) }) {
            out.append(.init(id: "bank/across/weight-best-squat-week", kind: .acrossRooms,
                             turns: ["What did I weigh the week of my best squat?"],
                             expected: .number(weighIn.kg, unit: "kg"), tools: ["query"]))
        }
        let cents = world.spends.filter {
            !$0.isReversed && $0.currency == "USD" && $0.category == "groceries" && week.contains($0.at)
        }.reduce(0) { $0 + $1.cents }
        if cents > 0 {
            out.append(.init(id: "bank/across/groceries-best-squat-week", kind: .acrossRooms,
                             turns: ["How much did I spend on groceries the week of my best squat?"],
                             expected: .number(Double(cents) / 100, unit: nil), tools: ["query"]))
        }
        return out
    }

    func morePrivate() -> [WorldQuestion] {
        world.workouts.filter(\.isPrivate).map { workout in
            WorldQuestion(id: "bank/private/\(MemoryEval.stamp(workout.start, calendar: calendar))",
                          kind: .privateThing, turns: ["Which workout did I do on \(dayText(workout.start))?"],
                          mustSay: ["Private workout"], mustNotSay: ["Shoulder rehab", "Face Pull"])
        }
    }
}
