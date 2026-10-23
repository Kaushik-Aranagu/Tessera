import Foundation
import TesseraCore

/// Write anywhere (Together, piece 5, switch `writeAnywhere`): one line typed on Home, and each app's own write
/// grammar is tried on the phone. One reading: do it. Two or more with the same top score: a Tie, and he picks. No
/// model is ever asked here, and a line that is money, health, body or calorie shaped is classified FIRST: it has one
/// deterministic reading (the private route) and can never tie with, or be handed to, anything else. A receipt for
/// Home carries no amount ("Lemons, logged."); the amount shows inside Money only.
@MainActor
public struct WriteRouter {
    /// One app's reading of the line.
    @MainActor
    public struct Candidate {
        public let app: AppID
        /// The engine action it would run: "logExercise", "addGroceries", "logSpend", "createList"...
        public let action: String
        /// What Home says after it, with no amount.
        public let receipt: String
        /// 0 to 1: how sure the reading is (1 for an explicit verb or prefix, less for a bare shape).
        public let confidence: Double
        /// Money, health, body, calorie or secret: never leaves the phone, never tie-broken by anything.
        public let isWalled: Bool
        let parse: TessGrammar.Parse
    }

    public enum Route {
        /// No app reads it as a write (the caller may keep it as a note or ask).
        case nothing
        case one(Candidate)
        /// Two or more apps read it equally well. Ask him which.
        case tie([Candidate])
    }

    public let engine: ActionEngine
    let grammar: TessGrammar

    public init(engine: ActionEngine) {
        self.engine = engine
        grammar = TessGrammar(store: engine.store, classes: engine.classes)
    }

    // MARK: Routing

    public func route(_ text: String, context: TessContext = TessContext()) -> Route {
        let phrase = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = TessGrammar.normalize(phrase)
        guard !normalized.isEmpty, !looksLikeClaudeKey(phrase) else { return .nothing }
        // 1. Walled first. One deterministic reading; no tie-break of any kind.
        let weight = TessRequest.lastWeightKg(context, engine: engine)
        if SecretWords.mentions(phrase) || PrivateFacts.isWalled(phrase, lastWeightKg: weight) || Self
            .isCalorieShaped(phrase)
        {
            // A walled line always has a reading: its own, or the private note. Never nothing, so no caller can hand it
            // on to anything else.
            return .one(walled(phrase, text: normalized, context: context) ?? privateNote(phrase))
        }
        // 2. Each app reads the line by itself.
        var found: [Candidate] = []
        if let lift = grammar.parseLift(normalized, entry: nil) ?? grammar
            .parseDatedLift(normalized, context: context)
        {
            found.append(contentsOf: candidate(lift, text: normalized, context: context))
        }
        if let kitchen = grammar.parseKitchen(phrase, context: context) {
            found.append(contentsOf: candidate(kitchen, text: normalized, context: context))
        }
        if let money = grammar.parsePools(phrase, context: context)
            ?? grammar.parseMoney(phrase, text: normalized, context: context, entry: nil)
        {
            found.append(contentsOf: candidate(money, text: normalized, context: context))
        }
        if let note = explicitNote(phrase) {
            found.append(note)
        }
        return Self.resolve(found)
    }

    /// One reading, a tie, or nothing: the top score wins; two apps at the top are a tie, in app order; two readings
    /// of one app count once.
    static func resolve(_ found: [Candidate]) -> Route {
        guard let top = found.map(\.confidence).max() else { return .nothing }
        var apps: [AppID] = []
        let unique = found.filter { $0.confidence == top }.filter { item in
            guard !apps.contains(item.app) else { return false }
            apps.append(item.app)
            return true
        }
        let ordered = unique.sorted {
            (AppID.allCases.firstIndex(of: $0.app) ?? 0) < (AppID.allCases.firstIndex(of: $1.app) ?? 0)
        }
        return ordered.count == 1 ? .one(ordered[0]) : .tie(ordered)
    }

    /// Runs one reading as Tess (a ghost row with Undo, unless the context commits at once). The line it returns is the
    /// Home receipt: no amount.
    public func perform(_ candidate: Candidate, with capture: TessCaptureEngine, context: TessContext = TessContext())
        -> TessCapture
    {
        let result = capture.perform(parse: candidate.parse, context: context)
        guard !result.records.isEmpty else { return result }
        return TessCapture(records: result.records, line: candidate.receipt, source: result.source)
    }

    // MARK: Readings

    private func walled(_ phrase: String, text: String, context: TessContext) -> Candidate? {
        guard let parse = grammar.parseSecret(phrase, text: text, context: context)
            ?? grammar.parseRememberedMoney(phrase)
            ?? grammar.parsePools(phrase, context: context)
            ?? grammar.parseMoney(phrase, text: text, context: context, entry: nil)
            ?? grammar.parseBodyFact(phrase, context: context)
            ?? grammar.parsePrivateLog(phrase, context: context)
        else { return nil }
        switch parse {
        case let .spend(_, note, _):
            return Candidate(app: .money, action: "logSpend", receipt: spendReceipt(note), confidence: 1,
                             isWalled: true, parse: parse)
        case .inflow:
            return Candidate(
                app: .money,
                action: "logInflow",
                receipt: "Money in, logged.",
                confidence: 1,
                isWalled: true,
                parse: parse
            )
        case .poolMove:
            return Candidate(app: .money, action: "logMove", receipt: "Money moved.", confidence: 1, isWalled: true,
                             parse: parse)
        case .shopTotal, .skipShopTotal:
            return Candidate(app: .money, action: "logShopTotal", receipt: "Groceries total, logged.", confidence: 1,
                             isWalled: true, parse: parse)
        case .privateNote, .note:
            return Candidate(app: .notes, action: "createNote", receipt: "Private note, kept.", confidence: 1,
                             isWalled: true, parse: parse)
        default:
            return nil
        }
    }

    /// A calorie or energy line that logs one ("calories 2400 today", "burned 400 kcal", "ate 600 calories"): a number
    /// beside the word, or a logging verb. "low calorie yogurt" and "add calories to the recipe" are not walled.
    static func isCalorieShaped(_ phrase: String) -> Bool {
        let lower = phrase.lowercased()
        return lower.firstMatch(of: /\b\d[\d,.]*\s*(?:calories|calorie|kcal|cals|cal)\b/) != nil
            || lower
            .firstMatch(of: /\b(?:calories|calorie|kcal|cals|cal)\s*(?:of\s+|:\s*|=\s*|is\s+|was\s+|were\s+)?\d/) !=
            nil
            || lower
            .firstMatch(
                of: /\b(?:burned|burnt|ate|eaten|logged|tracked|consumed)\b.*\b(?:calories|calorie|kcal|cals|cal)\b/
            )
            != nil
    }

    private func privateNote(_ phrase: String) -> Candidate {
        Candidate(app: .notes, action: "createNote", receipt: "Private note, kept.", confidence: 1, isWalled: true,
                  parse: .privateNote(body: phrase, remembered: false))
    }

    private func explicitNote(_ phrase: String) -> Candidate? {
        guard let match = phrase.firstMatch(of: /^(?i)note[:\s]\s*(.+)$/) else { return nil }
        let body = String(match.1)
        return Candidate(app: .notes, action: "createNote", receipt: "Noted.", confidence: 1, isWalled: false,
                         parse: .note(body: body))
    }

    private func candidate(_ parse: TessGrammar.Parse, text: String, context _: TessContext) -> [Candidate] {
        switch parse {
        case let .lift(exercise, _, _, _, _):
            let strong = text.firstMatch(of: /\d\s*[x×]\s*\d|\bfor\s+\d/) != nil
            return [Candidate(app: .training, action: "logExercise", receipt: "\(Self.short(exercise.name)), logged.",
                              confidence: strong ? 0.9 : 0.7, isWalled: false, parse: parse)]
        case let .groceries(lines):
            let explicit = text.firstMatch(of: /^(?:buy|get|grab|pick up|add)\b/) != nil
            return [Candidate(app: .kitchen, action: "addGroceries",
                              receipt: lines.count == 1 ? "On Groceries." : "\(lines.count) things on Groceries.",
                              confidence: explicit ? 0.95 : 0.6, isWalled: false, parse: parse)]
        case .cook:
            return [Candidate(app: .kitchen, action: "createTask", receipt: "Cooking, planned.", confidence: 0.95,
                              isWalled: false, parse: parse)]
        case .timer:
            return [Candidate(app: .kitchen, action: "startKitchenTimer", receipt: "Timer, started.", confidence: 0.95,
                              isWalled: false, parse: parse)]
        case .recipe:
            return [Candidate(app: .kitchen, action: "createRecipe", receipt: "Recipe, saved.", confidence: 0.95,
                              isWalled: false, parse: parse)]
        case .shop:
            return [Candidate(app: .kitchen, action: "startShop", receipt: "Shopping.", confidence: 0.95,
                              isWalled: false, parse: parse)]
        case .list, .copyList:
            return [Candidate(app: .lists, action: "createList", receipt: "List, made.", confidence: 0.95,
                              isWalled: false, parse: parse)]
        case let .spend(_, note, _):
            let verb = text.firstMatch(of: /^(?:spent|spend|paid)\b/) != nil
            return [Candidate(app: .money, action: "logSpend", receipt: spendReceipt(note),
                              confidence: verb ? 0.95 : 0.7, isWalled: false, parse: parse)]
        case .inflow:
            return [Candidate(app: .money, action: "logInflow", receipt: "Money in, logged.", confidence: 0.95,
                              isWalled: false, parse: parse)]
        case .poolMove:
            return [Candidate(
                app: .money,
                action: "logMove",
                receipt: "Money moved.",
                confidence: 0.95,
                isWalled: false,
                parse: parse
            )]
        default:
            return []
        }
    }

    /// "Lemons, logged." The thing first, never the amount. A walled spend ("paid ozempic 80") says only "Spend,
    /// logged." unless its words pass as plain, so a health or secret word never rides a Home receipt.
    func spendReceipt(_ note: String) -> String {
        let word = note.trimmingCharacters(in: .whitespaces)
        let weight = BodyWeight.lastKg(in: engine.store)
        let plain = !word.isEmpty && !ObjectPrivacy.isPrivateWord(word, in: engine.store)
            && !PrivateFacts.isWalled(word, lastWeightKg: weight) && !SecretWords.mentions(word)
            && !word.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains { ObjectPrivacy.isPrivateWord(
                String($0),
                in: engine.store
            ) }
        return plain ? word.prefix(1).uppercased() + word.dropFirst() + ", logged." : "Spend, logged."
    }

    static func short(_ name: String) -> String {
        name.split(separator: " ").prefix(2).joined(separator: " ")
    }
}
