import Foundation

/// What Tess does when she is dragged onto an object, or asked "Ask Tess about this" (sheet 215). The answer is made on
/// the phone first. Claude is only ever offered one thing, the object's shown text, and only when `asksClaude` is on
/// and
/// the object's class is on the allowed list. Walled, private, money, health, body, calorie and calendar objects are
/// answered on the phone every time, even when masked, and are never packed for Claude. No money action is ever
/// offered.
public struct TessAsk: Equatable, Sendable {
    /// The line she says now, from the phone.
    public let phoneAnswer: String
    /// The only words that may go to Claude for this object (its shown text); nil unless allowed and asksClaude is on.
    public let claudeText: String?
    /// What she may offer to do about it. Empty for anything money.
    public let actions: [Action]

    public enum Action: Equatable, Sendable {
        /// Mark a task done (it undoes through the op log).
        case markTaskDone(UUID)
    }
}

@MainActor
public enum TessAskRouter {
    /// "That stays on this phone." and nothing else, for money, health, body, calories and the calendar.
    public static let staysHere = "That stays on this phone."

    /// Classes whose shown text may go to Claude, when the object is plain and asksClaude is on.
    static let claudeClasses: [SystemCatalog.Key] = [.task, .list, .listItem, .recipe, .routine]

    public static func route(_ object: ObjectRecord, engine: ActionEngine, asksClaude: Bool,
                             calendar: Calendar = .current) -> TessAsk
    {
        let store = engine.store, classes = engine.classes
        // Money, health, body, calorie and calendar things: one answer, no text for Claude, no actions.
        if isUnnameable(object, classes: classes) {
            return TessAsk(phoneAnswer: staysHere, claudeText: nil, actions: [])
        }
        // A private or walled thing is answered by its label, on the phone, always.
        if let label = ObjectPrivacy.shownLabel(of: object, in: store, classes: classes)
            ?? (Describe.isPrivate(object, in: store, classes: classes) ? classLabel(of: object) : nil)
        {
            return TessAsk(phoneAnswer: "\(label).", claudeText: nil, actions: [])
        }
        let shown = Describe.sentence(object, in: store, classes: classes, calendar: calendar)
            ?? (object.title.isEmpty ? nil : object.title)
        // The words are walled themselves (a title with a money or body fact): the phone answers and nothing leaves.
        let weight = BodyWeight.lastKg(in: store)
        let walled = shown.map {
            SecretWords.mentions($0) || ObjectPrivacy.containsPrivateWord($0, in: store)
                || PrivateFacts.isWalled($0, lastWeightKg: weight) || PrivateFacts.isCalorieShaped($0)
        } ?? false
        if walled {
            return TessAsk(phoneAnswer: staysHere, claudeText: nil, actions: [])
        }
        let answer = shown ?? "I don't have much on that one."
        var actions: [TessAsk.Action] = []
        if let taskClass = classes[.task], let classDef = object.classDef,
           ClassResolver.isSubclass(classDef, of: taskClass), store.value("isDone", of: object) != .bool(true)
        {
            actions.append(.markTaskDone(object.id))
        }
        let allowed = claudeClasses.contains { key in
            object.classDef.map { classDef in classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false }
                ?? false
        }
        return TessAsk(phoneAnswer: answer, claudeText: asksClaude && allowed ? shown : nil, actions: actions)
    }

    /// The class's own plain word ("Task", "Note"), for a private thing that has no shown label.
    static func classLabel(of object: ObjectRecord) -> String {
        let name = object.classDef?.name ?? ""
        return name.isEmpty ? "Private" : "Private \(name.lowercased())"
    }

    /// Money, health, body and calendar objects (the classes that are never named or sent).
    public static func isUnnameable(_ object: ObjectRecord, classes: [SystemCatalog.Key: ClassDef]) -> Bool {
        guard let classDef = object.classDef else { return false }
        if ClassResolver.app(for: classDef) == .money {
            return true
        }
        let blocked: [SystemCatalog.Key] = [.pool, .spend, .inflow, .poolMove, .rateNote, .sleepNight, .stepsDay,
                                            .restingHeartRate, .meProfile, .event, .heldNotice, .tessTurn, .tessCall,
                                            .tessSent, .tessWaiting]
        return blocked.contains { key in classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false }
    }
}

/// Today's actions in the room log: each with its time and its op-log Undo, titles masked, money worded "Reversed".
public struct RoomLogEntry: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let time: Date
    public let sentence: String
    /// "Undo", or "Reversed" for a money change.
    public let undoWord: String
    public let isMoney: Bool
}

@MainActor
public enum TessRoomLog {
    /// Today's changes by him or Tess (his day, the 4 am edge), newest first.
    public static func today(engine: ActionEngine, now: Date, calendar: Calendar = .current) -> [RoomLogEntry] {
        let day = TesseraDay(calendar: calendar)
        return UndoLog.recent(engine: engine, now: now, limit: 200).filter { day.isSameDay($0.at, now) }.map {
            RoomLogEntry(id: $0.id, time: $0.at, sentence: $0.sentence, undoWord: $0.isMoney ? "Reversed" : "Undo",
                         isMoney: $0.isMoney)
        }
    }

    /// Takes one back through the op log. The line is "Reversed." for money and "Put back." for the rest.
    @discardableResult
    public static func undo(_ entry: RoomLogEntry, engine: ActionEngine) -> UndoOutcome {
        let outcome = UndoLog.undo(entry.id, engine: engine)
        if case .putBack = outcome, entry.isMoney {
            return .putBack(line: "Reversed.")
        }
        return outcome
    }
}
