import Foundation
import TesseraCore

extension WorkoutSession {
    /// Lands on a process's resume point: the exercise in focus, with the dial and drum preset.
    func apply(_ point: ResumePoint) {
        if let focus = point.focus, let index = entries.firstIndex(where: { $0.id == focus }) {
            select(entryAt: index)
        }
        if let weight = point.weight {
            self.weight = weight
        }
        if let reps = point.reps {
            self.reps = reps
        }
        touch()
    }
}
