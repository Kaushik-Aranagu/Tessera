import Foundation
import os
import TesseraCore

// Plan my day through Claude (docs/research/plan-my-day-prompt.md, fixtures/plan-my-day-claude.md, board 95): the
// rules plan shows at once; Claude may word it and lightly reorder inside a run; any failure keeps the rules plan.

/// What leaves the phone for the plan: compact JSON with short handles, never ids, notes, health or history.
public struct PlanPack: Sendable, Equatable {
    /// The exact wire line (sorted keys).
    public let json: String
    /// The same plan at any minute of the day: what the wording is remembered by.
    public let cacheKey: String
    /// Handle ("t1", "e2", "w1", "k1") to the plan block's index.
    public let handles: [String: Int]
    /// Handles of the run blocks (Tess's plan lines), by run.
    public let runs: [[String]]
    public let cap: Int
    let window: (from: Int, to: Int)
    let now: Int
    /// Minutes of day per handle: (start, end, min), and whether it's fixed.
    let blocks: [String: (start: Int, end: Int, min: Int, fixed: Bool, kind: DayPlan.Kind)]
    let dues: [Int]
    /// Every title word, for the number and health checks.
    let titleWords: Set<String>
    /// Names he has that this plan doesn't hold (V13).
    let otherNames: Set<String>
    let hasWorkout: Bool
    let isRestDay: Bool

    public static func == (lhs: PlanPack, rhs: PlanPack) -> Bool {
        lhs.json == rhs.json
    }

    /// Nil when there's nothing to word: no window, or no plan lines (d14).
    /// `otherNames`: what he has that isn't in this plan (tasks left out, Later, routines, skipped events), for V13.
    /// `includesEventTitles` false (his call on Oct 22): events go as "busy", with their kind and times only.
    public init?(plan: DayPlan, now: Date, calendar: Calendar, calendarKnown: Bool, restDay: Bool,
                 otherNames: [String] = [], includesEventTitles: Bool = true)
    {
        guard let window = plan.window, !plan.ghosts.isEmpty else { return nil }
        let day = TesseraDay(calendar: calendar).day(of: now)
        // Wall-clock minutes (plus a day after midnight), never elapsed time: DST days keep their hours (QA P1).
        func minutes(_ date: Date) -> Int {
            let parts = calendar.dateComponents([.hour, .minute], from: date)
            let wall = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            return calendar.startOfDay(for: date) > day ? wall + 24 * 60 : wall
        }
        func clock(_ minutes: Int) -> String {
            String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
        }
        var counters: [DayPlan.Kind: Int] = [:]
        var handles: [String: Int] = [:]
        var rows: [[String: Any]] = []
        var blocks: [String: (start: Int, end: Int, min: Int, fixed: Bool, kind: DayPlan.Kind)] = [:]
        var runOf: [Int: Int] = [:]
        for (number, run) in plan.runs.enumerated() {
            for block in run {
                if let index = plan.blocks.firstIndex(of: block) {
                    runOf[index] = number + 1
                }
            }
        }
        var runs: [[String]] = Array(repeating: [], count: plan.runs.count)
        var dues: [Int] = []
        for (index, block) in plan.blocks.enumerated() {
            let prefix = switch block.kind {
            case .task: "t"
            case .event: "e"
            case .timedTask: "k"
            case .workout: "w"
            }
            counters[block.kind, default: 0] += 1
            let handle = "\(prefix)\(counters[block.kind] ?? 1)"
            handles[handle] = index
            let start = minutes(block.start), end = minutes(block.end)
            let title = block.kind == .event && !includesEventTitles ? "busy" : block.title
            var row: [String: Any] = ["id": handle, "kind": block.kind.rawValue, "title": title,
                                      "start": clock(start), "end": clock(end), "min": block.minutes]
            if let run = runOf[index] {
                row["run"] = run
                runs[run - 1].append(handle)
            } else {
                row["fixed"] = true
            }
            if let due = block.due {
                row["due"] = clock(minutes(due))
                dues.append(minutes(due))
            }
            if let moved = block.movedFrom {
                row["movedFrom"] = clock(minutes(moved))
            }
            if block.running {
                row["running"] = true
            }
            rows.append(row)
            blocks[handle] = (start, end, block.minutes, runOf[index] == nil, block.kind)
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        var top: [String: Any] = [
            "allDay": includesEventTitles ? plan.allDay : [], "blocks": rows, "cap": plan.cap, "light": plan.light,
            "now": clock(minutes(now)),
            "weekday": formatter.string(from: TesseraDay(calendar: calendar).day(of: now).addingTimeInterval(43200)),
            "window": [clock(minutes(window.start)), clock(minutes(window.end))],
        ]
        if !calendarKnown {
            top["cal"] = false
        }
        if restDay {
            top["rest"] = true
        }
        // The same plan, whatever minute it is: run blocks without their times, no "now" or window (QA S2).
        var stable = top
        stable["now"] = nil
        stable["window"] = nil
        stable["blocks"] = rows.map { row in
            var row = row
            if row["run"] != nil {
                row["start"] = nil
                row["end"] = nil
            }
            return row
        }
        cacheKey = (try? JSONSerialization.data(withJSONObject: stable, options: [.sortedKeys]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        guard let data = try? JSONSerialization.data(
            withJSONObject: top,
            options: [.sortedKeys, .withoutEscapingSlashes]
        ),
            let json = String(data: data, encoding: .utf8) else { return nil }
        self.json = json
        self.handles = handles
        self.runs = runs
        cap = plan.cap
        self.window = (minutes(window.start), minutes(window.end))
        self.now = minutes(now)
        self.blocks = blocks
        self.dues = dues
        // Compared as words, the way V13 reads a line ("Mum's birthday" is "mum's birthday").
        func phrase(_ text: String) -> String {
            text.lowercased().split { !$0.isLetter && !$0.isNumber && $0 != "'" }.joined(separator: " ")
        }
        // Multi-word names only ("Lunch" would catch "before lunch"), and never one that overlaps a title in the plan
        // or its all-day items ("landlord" in "Reply to landlord") (QA S1 on #303).
        let inPack = (plan.blocks.map(\.title) + plan.allDay).map(phrase)
        self.otherNames = Set(otherNames.map(phrase).filter { name in
            // As words, not letters: "pasta" doesn't overlap "pastry bake" (QA on #306).
            let padded = " \(name) "
            return name.contains(" ") && !inPack.contains { padded.contains(" \($0) ") || " \($0) ".contains(padded) }
        })
        hasWorkout = plan.blocks.contains { $0.kind == .workout }
        isRestDay = restDay
        func words(_ text: String) -> [String] {
            text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        }
        let titles: [String] = plan.blocks.filter { includesEventTitles || $0.kind != .event }.map(\.title)
            + (includesEventTitles ? plan.allDay : [])
        titleWords = Set(titles.flatMap(words))
    }
}

/// Claude's reply: `proposePlan`.
public struct ProposePlan: Decodable, Sendable, Equatable {
    public struct Block: Decodable, Sendable, Equatable {
        public let id: String
        public let start: String
        public let end: String?
        public let lineText: String
    }

    public struct Line: Decodable, Sendable, Equatable {
        public let id: String
        public let line: String
    }

    public let blocks: [Block]
    public let startWith: Line?
    public let ghostLines: [Line]
    public let note: String?
}

/// V1 to V12 (plan-my-day-prompt.md section 4). Any code means the rules plan shows as is.
public enum PlanProposalValidator {
    static let planBanned = ["missed", "failed", "behind", "overdue", "late", "again", "only", "finally", "skipped",
                             "slipped", "lazy", "backlog", "lighter"]
    static let planBannedPhrases = ["catch up", "need to", "don't forget", "remember to", "go easy", "take it easy",
                                    "push through"]
    static let healthWords = ["sleep", "slept", "sleepy", "tired", "exhausted", "fatigue", "energy", "rested",
                              "recovery", "recover", "heart", "hrv", "steps", "sore", "sick", "unwell", "drained",
                              "burnout"]
    static let numberWords = ["two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
                              "twelve", "twenty", "thirty", "forty", "fifty", "sixty", "hundred"]

    public static func violations(_ proposal: ProposePlan, against pack: PlanPack) -> [String] {
        var codes: [String] = []
        func minutes(_ text: String?) -> Int? {
            guard let text, let match = text.firstMatch(of: /^(\d{2}):(\d{2})$/), let hour = Int(match.1),
                  let minute = Int(match.2) else { return nil }
            return hour * 60 + minute
        }
        // V1, V2: shape and the same objects.
        let ids = proposal.blocks.map(\.id)
        if Set(ids).count != ids.count || Set(proposal.ghostLines.map(\.id)).count != proposal.ghostLines.count {
            codes.append("V1")
        }
        if Set(ids) != Set(pack.blocks.keys) {
            codes.append("V2")
            return codes
        }
        var placed: [String: (start: Int, end: Int)] = [:]
        for block in proposal.blocks {
            guard let start = minutes(block.start), let input = pack.blocks[block.id] else {
                codes.append("V1")
                return codes
            }
            placed[block.id] = (start, minutes(block.end) ?? start + input.min)
        }
        // V3: fixed blocks don't move.
        for (id, input) in pack.blocks where input.fixed {
            if placed[id]?.start != input.start || placed[id]?.end != input.end {
                codes.append("V3")
                break
            }
        }
        // V4: each run back to back from its first start, its own lengths.
        for run in pack.runs {
            let first = run.compactMap { pack.blocks[$0]?.start }.min() ?? 0
            var cursor = first
            for (id, at) in run.compactMap({ id in placed[id].map { (id, $0) } })
                .sorted(by: { $0.1.start < $1.1.start })
            {
                guard at.start == cursor, at.end - at.start == pack.blocks[id]?.min else {
                    codes.append("V4")
                    break
                }
                cursor = at.end
            }
            // V5: inside the window.
            if run
                .contains(where: { placed[$0].map { $0.start < pack.window.from || $0.end > pack.window.to } ?? true
                })
            {
                codes.append("V5")
            }
        }
        // V6: no overlap.
        let ordered = placed.values.sorted { $0.start < $1.start }
        if zip(ordered, ordered.dropFirst()).contains(where: { $0.end > $1.start }) {
            codes.append("V6")
        }
        // V7: ghost lines.
        let runIDs = Set(pack.runs.flatMap(\.self))
        if Set(proposal.ghostLines.map(\.id)) != runIDs || proposal.ghostLines.count > min(3, pack.cap)
            || proposal.ghostLines.contains(where: { $0.line.trimmingCharacters(in: .whitespaces).isEmpty })
        {
            codes.append("V7")
        }
        // V8: start with the earliest block that isn't an event.
        let earliest = placed.filter { pack.blocks[$0.key]?.kind != .event }.min { $0.value.start < $1.value.start }?
            .key
        if proposal.startWith?.id != earliest || proposal.startWith.map(\.line.isEmpty) == true {
            codes.append("V8")
        }
        // V9 to V12: every line.
        let lines = proposal.blocks.map(\.lineText).filter { !$0.isEmpty } + proposal.ghostLines.map(\.line)
            + [proposal.startWith?.line, proposal.note].compactMap(\.self)
        if proposal.blocks.contains(where: { runIDs.contains($0.id) && !$0.lineText.isEmpty }) {
            codes.append("V9")
        }
        let times = Set(pack.blocks.values.flatMap { [$0.start, $0.end] } + placed.values.flatMap { [$0.start, $0.end] }
            + pack.dues + [pack.window.from, pack.window.to, pack.now])
        let lengths = Set(pack.blocks.values.map(\.min))
        for line in lines {
            if !TessVoice.violations(in: line).isEmpty {
                codes.append("V9")
            }
            let lower = line.lowercased()
            let tokens = lower.split { !$0.isLetter && !$0.isNumber && $0 != "'" }.map(String.init)
            if tokens.contains(where: planBanned.contains) || planBannedPhrases.contains(where: lower.contains) {
                codes.append("V10")
            }
            if !numbersAreLicensed(lower, tokens: tokens, times: times, lengths: lengths, titles: pack.titleWords) {
                codes.append("V11")
            }
            if tokens.contains(where: { healthWords.contains($0) && !pack.titleWords.contains($0) }) {
                codes.append("V12")
            }
            // V13 (Product, 10:24 PM PT): naming a task, event or exercise that isn't in the plan, or training on a
            // day with no workout block ("Rest day." alone on a rest day).
            let padded = " " + tokens.joined(separator: " ") + " "
            let training = ["workout", "gym", "training"]
            if pack.otherNames.contains(where: { padded.contains(" \($0) ") })
                || !pack.hasWorkout && tokens
                .contains(where: { training.contains($0) && !pack.titleWords.contains($0) })
                || !pack.hasWorkout && padded.contains(" rest day ") && !(pack.isRestDay && line == "Rest day.")
            {
                codes.append("V13")
            }
        }
        return Array(Set(codes)).sorted()
    }

    /// V11: times only as "7:30 am" / "5 pm" and only ones in the plan; durations only a block's minutes; any other
    /// number only as it appears in a title.
    static func numbersAreLicensed(_ line: String, tokens _: [String], times: Set<Int>, lengths: Set<Int>,
                                   titles: Set<String>) -> Bool
    {
        var rest = line
        for match in line.matches(of: /(\d{1,2})(?::(\d{2}))?\s?(am|pm)\b/) {
            guard let hour = Int(match.1), (1 ... 12).contains(hour) else { return false }
            let minute = match.2.flatMap { Int($0) } ?? 0
            let value = (hour % 12 + (match.3 == "pm" ? 12 : 0)) * 60 + minute
            guard times.contains(value) || times.contains(value + 24 * 60) else { return false }
            rest = rest.replacingOccurrences(of: String(match.0), with: " ")
        }
        if rest.firstMatch(of: /\d{1,2}:\d{2}/) != nil {
            return false // "17:00" or "9:30" with no am/pm
        }
        for match in rest.matches(of: /(\d+(?:\.\d+)?)\s?(min|mins|minutes|hour|hours|h)\b/) {
            guard let value = Double(match.1) else { return false }
            let asMinutes = match.2.hasPrefix("h") ? Int(value * 60) : Int(value)
            guard lengths.contains(asMinutes) else { return false }
            rest = rest.replacingOccurrences(of: String(match.0), with: " ")
        }
        let leftover = rest.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        for token in leftover where token.contains(where: \.isNumber) || numberWords.contains(token) {
            if !titles.contains(token) {
                return false
            }
        }
        return true
    }
}

/// The rules plan with Claude's wording swapped in.
public struct WordedPlan: Sendable, Equatable {
    /// The plan with the run reordered (same blocks, new times inside their runs).
    public let plan: DayPlan
    /// A line per block, by index in `plan.blocks` (plan lines and any fixed-block line).
    public let lines: [Int: String]
    public let startLine: String?
    public let note: String?
}

public extension DayPlan {
    /// Applies a valid proposal: same blocks, run order and times from the reply, lines attached.
    func applying(_ proposal: ProposePlan, pack: PlanPack, calendar: Calendar, now: Date) -> WordedPlan {
        let day = TesseraDay(calendar: calendar).day(of: now)
        var blocks = blocks
        var lineByHandle: [String: String] = [:]
        for block in proposal.blocks {
            guard let index = pack.handles[block.id], let input = pack.blocks[block.id], !input.fixed,
                  let match = block.start.firstMatch(of: /^(\d{2}):(\d{2})$/), let hour = Int(match.1),
                  let minute = Int(match.2) else { continue }
            let base = calendar.date(byAdding: .day, value: hour / 24, to: day) ?? day
            let start = calendar.date(bySettingHour: hour % 24, minute: minute, second: 0, of: base) ?? base
            blocks[index].start = start
            blocks[index].end = start.addingTimeInterval(TimeInterval(input.min * 60))
        }
        for block in proposal.blocks where !block.lineText.isEmpty {
            lineByHandle[block.id] = block.lineText
        }
        for line in proposal.ghostLines {
            lineByHandle[line.id] = line.line
        }
        // Keep each line with its block through the re-sort.
        let handleAt = Dictionary(uniqueKeysWithValues: pack.handles.map { ($0.value, $0.key) })
        var tagged = blocks.enumerated().map { (block: $0.element, handle: handleAt[$0.offset]) }
        tagged.sort { $0.block.start < $1.block.start }
        var lines: [Int: String] = [:]
        for (index, entry) in tagged.enumerated() {
            if let handle = entry.handle, let line = lineByHandle[handle] {
                lines[index] = line
            }
        }
        let plan = DayPlan(
            window: window,
            blocks: tagged.map(\.block),
            cap: cap,
            light: light,
            lightReason: lightReason,
            allDay: allDay,
            notPlanned: notPlanned
        )
        return WordedPlan(plan: plan, lines: lines, startLine: proposal.startWith?.line, note: proposal.note)
    }
}

/// What Plan my day shows: Claude's wording, or the rules plan with at most one quiet line.
public enum PlanWordingResult: Sendable, Equatable {
    case worded(WordedPlan)
    /// The rules plan as is; `line` is "Claude didn't answer in time. Here's your usual plan." and the like, or nil.
    case rules(line: String?)
}

/// Asks Claude (Sonnet 5.5) to word today's rules plan: one `proposePlan` reply, no tools that write, 20 s, the cap
/// held before the call, every call on the ledger. Never writes; accepting a line is his `MoveTask`.
@MainActor
public final class ClaudePlanWording {
    public static let model = "claude-sonnet-5-5"
    static let maxTokens = 1024

    public let keys: any TessKeychain
    public let ledger: TessUsageLedger
    public let session: URLSession
    public var timeout: TimeInterval = 20
    /// "Tess asks Claude" (`SettingsStore.read().sendsMissesToClaude`): one switch for misses and plans (Product).
    public var allowed: () -> Bool = { true }
    public var now: () -> Date = { .now }
    public var calendar: Calendar = .current
    /// The same pack today reuses its wording (no second call).
    /// The last result per pack, failures and rejections included, so reopening never pays again (merge check).
    private var worded: (key: String, proposal: ProposePlan, pack: PlanPack)?
    /// A failed or rejected call is remembered for his day: reopening never pays again today (QA S2).
    private var failed: (day: Date, result: PlanWordingResult)?
    private static let log = Logger(subsystem: "com.kaushikaranagu.tessera", category: "tess.plan")

    public init(keys: any TessKeychain, ledger: TessUsageLedger,
                session: URLSession = URLSession(configuration: .ephemeral))
    {
        self.keys = keys
        self.ledger = ledger
        self.session = session
    }

    /// `stale` is asked once the reply is back: true when he touched the plan or 20 s passed, so a late reply is
    /// dropped (its cost still counted).
    public func word(_ plan: DayPlan, pack: PlanPack?, stale: () -> Bool = { false }) async -> PlanWordingResult {
        guard let pack, allowed(), let key = keys.read() else { return .rules(line: nil) }
        let today = TesseraDay(calendar: calendar).day(of: now())
        if let worded, worded.key == pack.cacheKey,
           let proposal = Self.repacked(worded.proposal, from: worded.pack, to: pack),
           PlanProposalValidator.violations(proposal, against: pack).isEmpty
        {
            return .worded(plan.applying(proposal, pack: pack, calendar: calendar, now: now()))
        }
        if let failed, failed.day == today {
            return failed.result
        }
        let input = (try? JSONSerialization.jsonObject(with: Data(pack.json.utf8))).map { "\($0)" } ?? pack.json
        let estimate = TessUsageLedger.estimate(text: Self.instructions + Self.schemaText + input,
                                                maxTokens: Self.maxTokens, model: Self.model)
        guard let reservation = ledger.reserve(estimate, now: now(), calendar: calendar) else {
            let reset = (calendar.dateInterval(of: .month, for: now())?.end ?? now())
                .formatted(.dateTime.month(.abbreviated).day())
            return .rules(line: "Claude paused until \(reset). Here's your usual plan.")
        }
        defer { ledger.settle(reservation) }
        let started = Date()
        var outcome = "works"
        var usage = (input: 0, output: 0)
        var requestID: String?
        defer {
            ledger.record(use: .plan, model: Self.model, input: usage.input, output: usage.output,
                          costNano: TessUsageLedger.cost(model: Self.model, input: usage.input, output: usage.output),
                          latency: Date().timeIntervalSince(started), outcome: outcome, requestID: requestID,
                          at: now())
        }
        // A call that reached Claude is remembered for today; offline, cancelled and a bad key (a new key may come)
        // never are.
        func done(_ result: PlanWordingResult) -> PlanWordingResult {
            // Busy passes in minutes, so it's never remembered for the day (QA on #306).
            if !["offline", "cancelled", "badKey", "busy"].contains(outcome) {
                failed = (today, result)
            }
            return result
        }
        let reply: (proposal: ProposePlan?, usage: (Int, Int), requestID: String?, stop: String?)
        do {
            reply = try await withDeadline(timeout) { try await self.send(pack.json, key: key) }
        } catch let failure as ClaudeTessModel.Failure {
            outcome = failure.outcome
            // Product 10:24 PM PT: one line, then the usual plan; a rejected or late reply stays silent.
            let line: String? = switch failure.outcome {
            case "timeout": "Claude didn't answer in time. Here's your usual plan."
            case "badKey": "That key didn't work. Paste it again? Here's your usual plan."
            case "offline", "busy": "Here's your usual plan."
            default: nil
            }
            return done(.rules(line: line))
        } catch is CancellationError {
            outcome = "cancelled" // the view went away: not a call to remember (merge check)
            return .rules(line: nil)
        } catch {
            outcome = Task.isCancelled ? "cancelled" : "other"
            return done(.rules(line: nil))
        }
        usage = reply.usage
        requestID = reply.requestID
        guard !stale() else {
            outcome = "late"
            return done(.rules(line: nil))
        }
        // Cut off or refused: the rules plan, with its row (merge check).
        if let stop = reply.stop, ["max_tokens", "refusal"].contains(stop) {
            outcome = stop
            return done(.rules(line: nil))
        }
        guard let proposal = reply.proposal else {
            outcome = "rejected V1"
            return done(.rules(line: nil))
        }
        let codes = PlanProposalValidator.violations(proposal, against: pack)
        guard codes.isEmpty else {
            outcome = "rejected " + codes.joined(separator: ",")
            Self.log.debug("plan rejected: \(codes.joined(separator: ","), privacy: .public)")
            return done(.rules(line: nil))
        }
        worded = (pack.cacheKey, proposal, pack)
        return .worded(plan.applying(proposal, pack: pack, calendar: calendar, now: now()))
    }

    /// The remembered reply for the same plan at a later minute: the same run order and lines, repacked from each
    /// run's new start, fixed blocks at their new times.
    static func repacked(_ proposal: ProposePlan, from _: PlanPack, to new: PlanPack) -> ProposePlan? {
        func clock(_ minutes: Int) -> String {
            String(format: "%02d:%02d", minutes / 60, minutes % 60)
        }
        let oldStart = Dictionary(uniqueKeysWithValues: proposal.blocks.compactMap { block in
            block.start.firstMatch(of: /^(\d{2}):(\d{2})$/).flatMap { match in
                Int(match.1).flatMap { hour in Int(match.2).map { (block.id, hour * 60 + $0) } }
            }
        })
        var starts: [String: Int] = [:]
        for run in new.runs {
            var cursor = run.compactMap { new.blocks[$0]?.start }.min() ?? 0
            for id in run.sorted(by: { (oldStart[$0] ?? 0) < (oldStart[$1] ?? 0) }) {
                starts[id] = cursor
                cursor += new.blocks[id]?.min ?? 0
            }
        }
        let blocks = proposal.blocks.compactMap { block -> ProposePlan.Block? in
            guard let input = new.blocks[block.id] else { return nil }
            let start = starts[block.id] ?? input.start
            return ProposePlan.Block(id: block.id, start: clock(start), end: clock(start + input.min),
                                     lineText: block.lineText)
        }
        guard blocks.count == proposal.blocks.count else { return nil }
        return ProposePlan(blocks: blocks, startWith: proposal.startWith, ghostLines: proposal.ghostLines,
                           note: proposal.note)
    }

    /// A hard deadline: URLRequest's timeout only counts idle time, so the call races a sleep (merge check).
    private func withDeadline<T: Sendable>(_ seconds: TimeInterval,
                                           _ work: @escaping @MainActor () async throws -> T) async throws -> T
    {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await work() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw ClaudeTessModel.Failure.timeout
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else { throw ClaudeTessModel.Failure.timeout }
            return first
        }
    }

    func send(_ pack: String, key: String) async throws
        -> (proposal: ProposePlan?, usage: (Int, Int), requestID: String?, stop: String?)
    {
        var http = URLRequest(url: ClaudeKeyCheck.base, timeoutInterval: timeout)
        http.httpMethod = "POST"
        http.setValue(key, forHTTPHeaderField: "x-api-key")
        http.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        http.setValue("application/json", forHTTPHeaderField: "content-type")
        guard let schema = try? JSONSerialization.jsonObject(with: Data(Self.schemaText.utf8)),
              let body = try? JSONSerialization.data(withJSONObject: [
                  "model": Self.model, "max_tokens": Self.maxTokens, "system": Self.instructions,
                  "tools": [[
                      "name": "proposePlan",
                      "description": "Tess's wording and light reorder of today's rules plan.",
                      "strict": true,
                      "input_schema": schema,
                  ]],
                  "tool_choice": ["type": "auto"], "messages": [["role": "user", "content": pack]],
                  "output_config": ["effort": "low"],
              ] as [String: Any]) else { throw ClaudeTessModel.Failure.other }
        http.httpBody = body
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: http)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError() // the view went away: never remembered (QA on #306)
        } catch let error as URLError {
            throw error.code == .timedOut ? ClaudeTessModel.Failure.timeout : ClaudeTessModel.Failure.offline
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ClaudeTessModel.Failure.other
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200: break
        case 401, 403: throw ClaudeTessModel.Failure.badKey
        case 504: throw ClaudeTessModel.Failure.timeout
        case 429, 500 ... 599: throw ClaudeTessModel.Failure.busy
        default: throw ClaudeTessModel.Failure.other
        }
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw ClaudeTessModel.Failure.other
        }
        let used = object["usage"] as? [String: Any] ?? [:]
        let usage = (used["input_tokens"] as? Int ?? 0, used["output_tokens"] as? Int ?? 0)
        let requestID = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "request-id")
        let content = object["content"] as? [[String: Any]] ?? []
        let input = content
            .first { $0["type"] as? String == "tool_use" && $0["name"] as? String == "proposePlan" }?["input"]
        let proposal = input.flatMap { try? JSONSerialization.data(withJSONObject: $0) }
            .flatMap { try? JSONDecoder().decode(ProposePlan.self, from: $0) }
        return (proposal, usage, requestID, object["stop_reason"] as? String)
    }

    /// plan-my-day-prompt.md section 1, word for word (stable bytes, so it caches).
    static let instructions = """
    You are Tess, the voice of Tessera, a personal planning app for one person.

    The app's rules have already built today's plan. It is correct. You word it, and you may lightly reorder tasks. \
    Reply only with proposePlan.

    Plan rules
    - Return every input block once, with its exact id. Never add, drop, merge or split a block. Titles are shown by \
    the app; you never change them.
    - Blocks marked "fixed" (events, the workout, timed tasks) keep their exact start and end.
    - Other blocks have a "run": tasks back to back in one gap. You may change their order inside their run only, \
    then pack them back to back from the run's first start, each keeping its "min". Never move a task to another run. \
    Keeping the input order is always fine.
    - ghostLines: one line per run block, same ids, never more than 3.
    - startWith: the earliest block that is not an event, with one line. Null if there is none.
    - lineText: "" for run blocks. For fixed blocks usually "", or a short line tying it to a task.
    - note: one line about the whole day, or null. Usually null.

    Voice
    - Every line 11 words or fewer. Plain, warm, a little dry. Point first.
    - Say what the title doesn't: length, timing, or what it sits next to. Invent nothing.
    - Offer, never instruct. No "should", "need to" or "don't forget".
    - No greetings, praise, apologies, emoji or exclamation marks.
    - Nothing that grades the day or the person: never missed, failed, behind, overdue, late, again, only, streak.
    - Numbers: write times as 7:30 am or 5 pm, only times from the input or your blocks. Durations as the given \
    minutes. No counts of anything.
    - cal false means the calendar is unknown. Never call the day clear, open or free.
    - rest true means a planned rest day. The note may be exactly "Rest day."; say nothing else about rest or training.
    - A workout with running true is under way. It is startWith; word it as under way, never as something to start.
    - Never mention why the plan is short, the night, or anything not in the input.
    - Never mention sleep, energy, tiredness or health. When "light" is true, keep the wording gentle, leave the \
    workout's lineText empty, and if the workout is startWith, its line is just its title and time.
    - Never advise on training. Mention people, places and things only as they appear in titles.
    """

    /// The strict `proposePlan` input schema (section 3).
    static let schemaText = #"""
    {"type":"object","additionalProperties":false,"required":["blocks","startWith","ghostLines","note"],
    "properties":{
    "blocks":{"type":"array","description":"Every input block once, same id, in time order.","items":{"type":"object",
    "additionalProperties":false,"required":["id","start","end","lineText"],"properties":{
    "id":{"type":"string","description":"An input id, copied exactly."},
    "start":{"type":"string","description":"HH:mm, 24-hour."},
    "end":{"type":["string","null"],"description":"HH:mm, or null for start plus min."},
    "lineText":{"type":"string","description":"11 words or fewer. \"\" for run blocks."}}}},
    "startWith":{"anyOf":[{"type":"object","additionalProperties":false,"required":["id","line"],
    "properties":{"id":{"type":"string"},"line":{"type":"string"}}},{"type":"null"}]},
    "ghostLines":{"type":"array","description":"One accept-or-skip line per run block. At most 3.","items":{
    "type":"object","additionalProperties":false,"required":["id","line"],
    "properties":{"id":{"type":"string"},"line":{"type":"string"}}}},
    "note":{"type":["string","null"],"description":"One line about the day, usually null."}}}
    """#
}
