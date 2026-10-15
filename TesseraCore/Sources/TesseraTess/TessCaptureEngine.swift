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

    /// Runs the routes in order (grammar, then the on-device model) through `TessRouter`.
    public func capture(_ phrase: String, context: TessContext) async -> TessCapture {
        var context = context
        if context.process == nil {
            context.process = ProcessTable(engine: engine).running()?.subject?.id
        }
        return await router.run(TessRequest(text: phrase, context: context, use: .capture))
    }

    /// The router for this engine: grammar first, then the model step if there is one.
    public var router: TessRouter {
        var models: [any TessModel] = [GrammarTessModel(capture: self)]
        if let model {
            models.append(OnDeviceTessModel(model))
        }
        return TessRouter(engine: engine, models: models)
    }

    /// Several sets from one phrase, all or nothing: if one can't log, the ones already logged are taken back.
    func performSets(_ parts: [TessGrammar.Parse], context: TessContext) -> TessCapture {
        var records: [OpRecord] = []
        var lines: [String] = []
        for part in parts {
            do {
                let (record, line) = try perform(part, context: context)
                records.append(record)
                lines.append(line)
            } catch {
                for record in records.reversed() {
                    if record.state == .pending {
                        _ = try? engine.discard(record)
                    } else {
                        engine.undo(record)
                    }
                }
                return TessCapture(records: [], line: Self.line(for: error), source: .grammar)
            }
        }
        let line = lines.count > 1 ? "\(lines.count) sets logged." : lines.first ?? ""
        return TessCapture(records: records, line: line, source: .grammar)
    }

    /// The grammar route: a capture when the grammar reads the phrase, else nil.
    func grammarCapture(_ phrase: String, context: TessContext) -> TessCapture? {
        if let parse = grammar.parse(phrase, context: context) {
            do {
                if case let .sets(parts) = parse {
                    return performSets(parts, context: context)
                }
                let (record, line) = try perform(parse, context: context)
                return TessCapture(records: [record], line: line, source: .grammar)
            } catch {
                return TessCapture(records: [], line: Self.line(for: error), source: .grammar)
            }
        }
        return nil
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
        default:
            return try performKitchen(parse, pending: pending, context: context)
        }
    }

    private func performKitchen(_ parse: TessGrammar.Parse, pending: Bool,
                                context: TessContext) throws -> (OpRecord, String)
    {
        switch parse {
        case let .groceries(lines):
            let record = try engine.perform(AddGroceries(lines: lines), by: .tess, pending: pending).record
            return (record, lines.count == 1 ? "\(lines[0].prefix(1).uppercased() + lines[0].dropFirst()), on the list."
                : "\(lines.count) things on the list.")
        case let .cook(recipe, date?):
            let record = try engine.perform(
                CreateTask(title: "Cook \(recipe.title.lowercased())", startsAt: date, about: [recipe.id]),
                by: .tess, pending: pending
            ).record
            return (record, "\(recipe.title), \(Self.when(date, context: context)).")
        case let .cook(recipe, nil):
            let record = try engine.perform(StartCooking(recipe: recipe.id), by: .tess, pending: pending).record
            return (record, "Cooking \(recipe.title.lowercased()).")
        case let .timer(label, minutes):
            let cook = ProcessTable(engine: engine).running()?.subject
            let cookID = cook.flatMap { $0.classDef?.id == engine.classes[.cook]?.id ? $0.id : nil }
            let record = try engine.perform(StartKitchenTimer(label: label, minutes: minutes, cook: cookID),
                                            by: .tess, pending: pending).record
            return (record, "\(label), \(TessVoice.number(minutes)) min.")
        case let .list(name):
            let record = try engine.perform(CreateList(name: name), by: .tess, pending: pending).record
            return (record, "New list: \(name).")
        case .shop:
            let record = try engine.perform(StartShop(), by: .tess, pending: pending).record
            let line = Groceries(store: engine.store, classes: engine.classes).shoppingLine()
            return (record, "\(line).")
        case let .reschedule(task, date):
            let record = try engine.perform(MoveTask(task: task.id, to: date), by: .tess, pending: pending).record
            return (record, "\(task.title), \(Self.when(date, context: context)).")
        case let .cookStep(cook, next):
            if next {
                let index = (ProcessTable(engine: engine).running()?.resumePoint?.index ?? 0) + 1
                let record = try engine.perform(GoToCookStep(cook: cook.id, step: index, time: context.now), by: .tess,
                                                pending: pending).record
                return (record, "Step \(index + 1).")
            }
            let record = try engine.perform(FinishCooking(cook: cook.id, time: context.now), by: .tess,
                                            pending: pending).record
            return (record, "\(cook.title), done.")
        case .ignoredInWorkout:
            throw ActionError.invalidArguments(action: "capture", reason: "the rest timer lives on the workout screen")
        case let .recipe(text):
            let record = try engine.perform(CreateRecipe(text: text), by: .tess, pending: pending).record
            let parsed = RecipeParser.parse(text)
            let timers = parsed?.steps.flatMap(\.timers).count ?? 0
            let parts = [
                "\(parsed?.ingredients.count ?? 0) ingredients", "\(parsed?.steps.count ?? 0) steps",
            ] + (timers > 0 ? ["\(timers) \(timers == 1 ? "timer" : "timers")"] : [])
            return (record, parts.joined(separator: ", ") + ".")
        default:
            throw ActionError.invalidArguments(action: "capture", reason: "not a kitchen phrase")
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
