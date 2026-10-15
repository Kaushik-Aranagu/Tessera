import Foundation
import TesseraCore

/// The capture pipeline: the deterministic grammar first, then the on-device model, then an honest
/// "Didn't catch that." Everything is performed through the action engine as Tess, pending by default,
/// so the ghost row is real data that commits after the grace period or on tap, and undoes cleanly.
@MainActor
public final class TessCaptureEngine: TessCapturing {
    public let engine: ActionEngine
    public let grammar: TessGrammar
    /// The model step. Nil, or unavailable on this device, means grammar only.
    public var model: (any TessModelCapturing)?

    public init(engine: ActionEngine, model: (any TessModelCapturing)? = nil) {
        self.engine = engine
        grammar = TessGrammar(store: engine.store, classes: engine.classes)
        self.model = model
    }

    public func capture(_ phrase: String, context: TessContext) async -> TessCapture {
        if let parse = grammar.parse(phrase, context: context) {
            do {
                let (record, line) = try perform(parse, context: context)
                return TessCapture(records: [record], line: line, source: .grammar)
            } catch {
                return TessCapture(records: [], line: Self.line(for: error), source: .grammar)
            }
        }
        if let model, model.isAvailable {
            return await model.capture(phrase, context: context, engine: engine)
        }
        return TessCapture(records: [], line: "Didn't catch that. Try \u{201C}bench 80 x 8\u{201D}.", source: .none)
    }

    private func perform(_ parse: TessGrammar.Parse, context: TessContext) throws -> (OpRecord, String) {
        let pending = !context.commitImmediately
        switch parse {
        case let .lift(exercise, sets, reps, weight, unit):
            let record = try engine.perform(
                LogExercise(exercise: exercise.id, weight: weight, reps: reps, sets: sets, unit: unit),
                by: .tess, pending: pending
            ).record
            let name = Self.shortName(exercise.name)
            let scheme = sets > 1 ? "\(sets) x \(TessVoice.number(reps))" : "\(TessVoice.number(reps)) reps"
            let load = TessVoice.number(weight) + (unit == .kilograms ? "" : " \(unit.symbol)")
            return (record, "\(name) \(scheme) at \(load). Added to today.")
        case let .set(entry, kilograms, reps, kind, phrase, unit):
            // Logged in the unit it was said in, so the set keeps its entered unit.
            let said = unit.fromKilograms(kilograms, rounded: false)
            let record = try engine.perform(
                LogSet(entry: entry.id, weight: said, reps: reps, kind: kind, source: .tess,
                       unit: unit == .kilograms ? nil : unit),
                by: .tess, pending: pending
            ).record
            let number = entry.orderedChildren.count
            let weight = unit == .kilograms ? TessVoice.number(kilograms) : unit.format(kilograms: kilograms)
            let line = switch phrase {
            case .same: "Same again, logged."
            case .drop: "Drop set. \(weight) x \(TessVoice.number(reps))."
            case .repsOnly, .full: "Set \(number). \(weight) x \(TessVoice.number(reps))."
            }
            return (record, line)
        case let .task(title, startsAt):
            let record = try engine.perform(CreateTask(title: title, startsAt: startsAt), by: .tess, pending: pending)
                .record
            return (record, startsAt.map { "\(title), \(Self.when($0, context: context))." } ?? "\(title), in Later.")
        case let .note(body):
            let record = try engine.perform(CreateNote(body: body), by: .tess, pending: pending).record
            let links = record.ops.count {
                if case .setLinks = $0 {
                    true
                } else {
                    false
                }
            }
            return (record, links > 0 ? "Noted, linked." : "Noted.")
        }
    }

    /// "Bench Press" reads as "Bench" in Tess's one-liners; other names stay whole.
    static func shortName(_ name: String) -> String {
        name == "Bench Press" ? "Bench" : name
    }

    static func when(_ date: Date, context: TessContext) -> String {
        let calendar = context.calendar
        let day: String
        if calendar.isDate(date, inSameDayAs: context.now) {
            day = "today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: context.now),
                  calendar.isDate(date, inSameDayAs: tomorrow)
        {
            day = "tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEEE"
            day = formatter.string(from: date)
        }
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        let time = minute == 0 ? "\(twelve) \(hour < 12 ? "am" : "pm")"
            : String(format: "%d:%02d %@", twelve, minute, hour < 12 ? "am" : "pm")
        return "\(day) \(time)"
    }

    static func line(for error: any Error) -> String {
        if case let ActionError.invalidArguments(_, reason) = error {
            return "Didn't save that. \(reason.prefix(1).uppercased() + reason.dropFirst())."
        }
        return "Didn't save that. Tap to retry."
    }
}

/// The model step of capture, so it can be swapped (on-device model now; Private Cloud Compute or Claude later).
@MainActor
public protocol TessModelCapturing {
    var isAvailable: Bool { get }
    func capture(_ phrase: String, context: TessContext, engine: ActionEngine) async -> TessCapture
}
