import Foundation
import TesseraCore

/// Edit and undo any set (ship list slice 8): tap a logged stroke and the dial and drum hold that set's numbers;
/// Save writes Core's EditSet and Remove Core's DeleteObject (both in the op log, undoable); Cancel puts the
/// next set's numbers back.
extension WorkoutSession {
    /// Only while the edited set still exists in the current exercise (an undo or swap can take it away).
    var isEditing: Bool {
        editingRow != nil
    }

    /// The set being edited, as a row (number, weight, reps).
    var editingRow: SetRow? {
        guard let id = editingSetID, let entry = currentEntry else { return nil }
        return setRows(of: entry).first { $0.id == id }
    }

    /// Loads a logged set of the current exercise onto the dial and drum.
    func beginEditing(setID: UUID) {
        guard finishedAt == nil, let entry = currentEntry,
              let row = setRows(of: entry).first(where: { $0.id == setID }) else { return }
        if editStash == nil {
            editStash = (weight, reps, rpe)
        }
        editingSetID = setID
        weight = row.weight
        reps = row.reps
        rpe = row.rpe
        isEffortShown = row.rpe != nil
        touch()
    }

    /// Writes the dialled numbers to the set through the engine.
    func saveEdit() {
        guard let row = editingRow else { return endEditing() }
        let changed = abs(row.weight - weight) > 0.001 || row.reps != reps || row.rpe != rpe
        if changed, let result = try? model.engine.perform(
            EditSet(set: row.id, weight: weight, reps: reps, rpe: rpe), by: .user
        ) {
            lastEdit = (result.record, row.number)
            editNote = "Set \(row.number) is \(Format.kilograms(weight)) × \(Int(reps)) now."
            refreshAfterExternalWrite()
            model.touch()
        }
        endEditing()
    }

    /// Removes the set being edited through Core's DeleteObject (in the op log, so Undo brings it back).
    func removeEditing() {
        guard let row = editingRow else { return endEditing() }
        if let result = try? model.engine.perform(DeleteObject(object: row.id), by: .user) {
            lastEdit = (result.record, row.number)
            editNote = "Set \(row.number) removed."
            if undoable?.setID == row.id {
                undoable = nil
            }
            if lastSeated?.setID == row.id {
                lastSeated = nil
            }
            bests.removeAll { $0.setID == row.id }
            refreshAfterExternalWrite()
            persistRest()
            model.touch()
        }
        endEditing()
    }

    func endEditing() {
        editingSetID = nil
        if let stash = editStash {
            weight = stash.weight
            reps = stash.reps
            rpe = stash.rpe
        }
        editStash = nil
        isEffortShown = false
    }

    /// Undo in the Tess bar: the latest action first, an edit, else the last logged set.
    var canUndoLast: Bool {
        guard finishedAt == nil else { return false }
        if let lastEdit, lastEdit.record.state != .undone {
            return true
        }
        return canUndo
    }

    func undoLast() {
        if let edit = lastEdit, edit.record.state != .undone {
            model.engine.undo(edit.record)
            lastEdit = nil
            editNote = "Set \(edit.number) is back as it was."
            refreshAfterExternalWrite()
            model.touch()
        } else {
            editNote = nil
            undoLastSet()
        }
    }
}
