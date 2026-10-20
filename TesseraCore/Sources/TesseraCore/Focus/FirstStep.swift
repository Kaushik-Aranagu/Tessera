import Foundation

/// The first-step splitter (M4 slice 9): a task untouched for 3 days gets one offered 2-minute first step, never a
/// lecture. Rules only, no model. At most one offer a day (the M4 default: one Tess suggestion a day).
public struct FirstStepOffer: Equatable, Sendable {
    public let task: UUID
    public let title: String
    /// "Write one sentence of the report." Two minutes of it.
    public let step: String
}

@MainActor
public struct FirstStep {
    public static let untouchedDays = 3

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]
    public let calendar: Calendar

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], calendar: Calendar = .current) {
        self.store = store
        self.classes = classes
        self.calendar = calendar
    }

    /// The step for a title: the verb it starts with decides, and anything else is two minutes on it.
    public static func step(for title: String) -> String {
        let words = title.trimmingCharacters(in: .whitespaces).split(separator: " ").map(String.init)
        guard let first = words.first?.lowercased() else { return "Spend 2 minutes on it." }
        let rest = words.dropFirst().joined(separator: " ")
        switch first {
        case "write", "draft": return "Write one sentence\(rest.isEmpty ? "" : " of \(rest)")."
        case "call", "phone": return "Find the number\(rest.isEmpty ? "" : " for \(rest)")."
        case "email", "reply", "message", "text": return "Open the thread\(rest.isEmpty ? "" : " for \(rest)")."
        case "clean", "tidy": return "Set a 2-minute timer and start\(rest.isEmpty ? "" : " on \(rest)")."
        case "buy", "order": return "Put it on your list\(rest.isEmpty ? "" : ": \(rest)")."
        case "book", "schedule": return "Open the calendar\(rest.isEmpty ? "" : " for \(rest)")."
        case "read": return "Read one page\(rest.isEmpty ? "" : " of \(rest)")."
        default: return "Spend 2 minutes on \(title)."
        }
    }

    /// The oldest open task untouched for 3 days or more, once a day; private titles never get an offer (the step
    /// would say the words).
    public func offer(now: Date, lastOfferedOn: Date? = nil) -> FirstStepOffer? {
        let day = TesseraDay(calendar: calendar)
        if let lastOfferedOn, day.isSameDay(lastOfferedOn, now) {
            return nil
        }
        guard let taskClass = classes[.task],
              let cutoff = calendar.date(byAdding: .day, value: -Self.untouchedDays, to: now) else { return nil }
        let candidates = store.objects(of: taskClass).filter { task in
            !task.isDeleted && store.value("isDone", of: task) != .bool(true) && task.updatedAt <= cutoff
                && ObjectPrivacy.label(of: task, in: store, classes: classes) == nil
                && store.value("firstStepOf", of: task) == nil
        }
        guard let oldest = candidates.min(by: { $0.updatedAt < $1.updatedAt }) else { return nil }
        return FirstStepOffer(task: oldest.id, title: oldest.title, step: Self.step(for: oldest.title))
    }
}

/// Takes the offered step: a 2-minute task about the task.
public struct AcceptFirstStep: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "acceptFirstStep", summary: "Add a 2-minute first step",
        parameters: [.init("task", .object, "The task")], isOfferedToModel: false
    )

    public var task: UUID
    public var time: Date?

    public init(task: UUID, time: Date? = nil) {
        self.task = task
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let parent = try transaction.object(task, is: .task)
        let step = FirstStep.step(for: parent.title)
        return try CreateTask(title: step, startsAt: time ?? .now, minutes: 2, about: [parent.id]).apply(&transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        "First step for \(store.object(id: task)?.title ?? "it")"
    }
}
