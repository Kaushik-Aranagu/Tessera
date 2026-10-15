import Foundation
import TesseraCore

/// The rest countdown outlives the app: its end and length ride on the workout process's resume point (extras),
/// so a relaunch mid-rest picks the countdown back up instead of "Set 2 is up".
extension WorkoutSession {
    enum RestKey {
        static let endsAt = "restEndsAt"
        static let total = "restTotal"
    }

    /// The rest saved on a resume point, if it is still running at `now`. An elapsed rest is simply over.
    static func savedRest(in point: ResumePoint?, at now: Date) -> (endsAt: Date, total: TimeInterval)? {
        guard let extras = point?.extras, let end = extras[RestKey.endsAt].flatMap(TimeInterval.init),
              let total = extras[RestKey.total].flatMap(TimeInterval.init) else { return nil }
        let endsAt = Date(timeIntervalSinceReferenceDate: end)
        return endsAt > now ? (endsAt, total) : nil
    }

    /// The rest this workout's open process remembers (used when the session is recreated after a relaunch).
    static func savedRest(for workout: ObjectRecord, model: AppModel) -> (endsAt: Date, total: TimeInterval)? {
        savedRest(in: ProcessTable(engine: model.engine).process(for: workout)?.resumePoint, at: AppClock.now)
    }

    /// Saves the current rest (or its absence) on the process, over a fresh resume point for the next set.
    func persistRest() {
        guard let process = ProcessTable(engine: model.engine).process(for: workout) else { return }
        var point = WorkoutProgress(of: workout, store: model.store).resumePoint
        if let restEndsAt, restTotal > 0 {
            point.extras[RestKey.endsAt] = String(restEndsAt.timeIntervalSinceReferenceDate)
            point.extras[RestKey.total] = String(restTotal)
        } else if process.resumePoint?.extras[RestKey.endsAt] == nil {
            // Nothing saved and nothing to save: nothing to write.
            return
        }
        // Written on the store, not as an op: bookkeeping, like the engine's own resume-point writes, and the
        // latest op stays the set you logged (Undo, the trail).
        guard let data = try? JSONEncoder().encode(point), let text = String(data: data, encoding: .utf8)
        else { return }
        try? model.store.set("resumePoint", to: .text(text), on: process.object)
    }
}
