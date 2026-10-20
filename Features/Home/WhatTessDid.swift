import SwiftUI
import TesseraCore

/// "What Tess did" (ship list M3 item 9): today's changes Tess made from his phrases, read from the op log, each one
/// line, thing first, with its own UNDO. The line is the receipt Tess said when she has it; an older record (its
/// spoken receipt isn't stored) is told from its ops.
enum TessReceipt {
    enum Verb: String, Equatable {
        case added, removed, renamed, changed, back
    }

    struct Change: Equatable {
        let id: UUID
        let verb: Verb
    }

    /// One change per thing touched, in the order first touched. A thing made here reads "added" whatever else
    /// happened to it; a removal wins over an edit.
    static func changes(_ ops: [Op]) -> [Change] {
        var order: [UUID] = []
        var verbs: [UUID: Verb] = [:]
        func rank(_ verb: Verb) -> Int {
            switch verb {
            case .added: 4
            case .removed: 3
            case .back: 2
            case .renamed: 1
            case .changed: 0
            }
        }
        for op in ops {
            let verb: Verb = switch op {
            case .create, .createClass: .added
            case .softDelete, .deleteClass: .removed
            case .restore: .back
            case .setTitle: .renamed
            case .setValue, .setLinks, .setSortIndex: .changed
            }
            let id = op.objectID
            if verbs[id] == nil {
                order.append(id)
            }
            if rank(verb) >= rank(verbs[id] ?? .changed) {
                verbs[id] = verb
            }
        }
        return order.compactMap { id in verbs[id].map { Change(id: id, verb: $0) } }
    }

    /// "Dentist, changed.", "Milk, added. Eggs, added.", "Push A, changed. 3 more things.". Things with no name
    /// (a set inside a workout) are counted, never named.
    static func line(_ changes: [Change], name: (UUID) -> String?) -> String {
        let named = changes.compactMap { change in name(change.id).map { "\($0), \(change.verb.rawValue)." } }
        let shown = named.prefix(2)
        let rest = changes.count - shown.count
        let more = rest == 0 ? "" : rest == 1 ? "1 more thing." : "\(rest) more things."
        guard !shown.isEmpty else {
            switch changes.count {
            case 0: return "Nothing changed."
            case 1: return "1 thing changed."
            default: return "\(changes.count) things changed."
            }
        }
        return [shown.joined(separator: " "), more].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// The line UNDO leaves: thing first, or plain when some of it changed since and was left alone.
    static func undone(_ line: String, partial: Bool) -> String {
        partial ? "Some of it changed since. The rest is back." : UndoCopy.takenBack(after: line)
    }

    @MainActor
    static func line(for record: OpRecord, model: AppModel) -> String {
        if let receipt = record.receipt, !receipt.isEmpty {
            return receipt
        }
        return line(changes(record.ops)) { id in
            if let object = model.store.object(id: id) {
                return ObjectTitle.shown(object, in: model.store, classes: model.classes)
            }
            return model.store.classDef(id: id)?.name
        }
    }

    /// Tess's committed records today, newest first.
    @MainActor
    static func today(_ model: AppModel, now: Date, calendar: Calendar = .current) -> [OpRecord] {
        let start = TesseraDay(calendar: calendar).start(of: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        return model.engine.history(from: start, to: end).filter { $0.actor == .tess && $0.state == .committed }
    }
}

/// The receipt block. On Now (one screen tall) it shows the newest change and "All N", which opens the day's list.
struct WhatTessDid: View {
    /// Now's form: the newest line only.
    var compact = true
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var undoneLine: String?
    @State private var undos = 0
    @State private var showsAll = false

    var body: some View {
        let _ = model.revision
        let records = TessReceipt.today(model, now: AppClock.now)
        if !records.isEmpty || undoneLine != nil {
            MarginSection(label: "Tess did") {
                VStack(alignment: .leading, spacing: 0) {
                    let shown = compact ? Array(records.prefix(1)) : records
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, record in
                        row(record)
                        if index < shown.count - 1 {
                            RowSeparator()
                        }
                    }
                    if let undoneLine {
                        Text(undoneLine)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .padding(.vertical, Theme.Spacing.s)
                            .transition(.opacity)
                    }
                    if compact, records.count > 1 {
                        Button("All \(records.count)") { showsAll = true }
                            .buttonStyle(.labelWord)
                            .accessibilityLabel("All \(records.count) changes Tess made today")
                    }
                }
            }
            .tesseraFeedback(.undo, trigger: undos)
            .sheet(isPresented: $showsAll) {
                ScrollView {
                    WhatTessDid(compact: false)
                        .padding(Theme.Spacing.gutter)
                }
                .scrollIndicators(.hidden)
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func row(_ record: OpRecord) -> some View {
        let line = TessReceipt.line(for: record, model: model)
        return HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(Format.clock(record.createdAt))
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                Text(line)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Theme.Spacing.s)
            Button("Undo") { undo(record, line: line) }
                .buttonStyle(.labelWord(Theme.Colors.inkSecondary, silent: true))
                .accessibilityLabel("Undo \(line)")
        }
        .padding(.vertical, Theme.Spacing.s)
        .accessibilityElement(children: .contain)
    }

    private func undo(_ record: OpRecord, line: String) {
        let outcome = model.engine.undo(record)
        var partial = false
        if case .partial = outcome {
            partial = true
        }
        model.session?.refreshAfterExternalWrite()
        model.touch()
        undos += 1
        withTesseraAnimation(reduceMotion: reduceMotion) {
            undoneLine = TessReceipt.undone(line, partial: partial)
        }
    }
}
