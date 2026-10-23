import Foundation
import Observation
import SwiftUI
import TesseraCore
import TesseraTess

/// Kaushik, Oct 21: "fill in model data so I can understand how things would look". The Review switch "Sample data"
/// swaps the whole app onto a second store, in memory only, filled with example content (US words, dollars, his
/// phone's time zone, no city). His own store is never written while it is on, never mixed with the sample, and
/// comes back untouched when it is off. The sample is never backed up (backups read his store, not this one), sends
/// nothing to Claude, schedules no notifications and exports nothing to Health.
@MainActor
@Observable
final class SampleData {
    static let shared = SampleData()

    /// The Review switch's id.
    nonisolated static let choiceID = "sampleData"

    /// Whether the switch is on now.
    static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }

    /// The "Sample data" word on Today was tapped: Review opens Settings at the switch, on the Shown page.
    var jumpsToSwitch = false

    @ObservationIgnored private var container: TesseraContainer?
    @ObservationIgnored private var sample: AppModel?

    /// The model the screens draw: the sample while the switch is on, else his own.
    func model(over real: AppModel, on: Bool = SampleData.isOn) -> AppModel {
        guard on else { return real }
        if let sample {
            return sample
        }
        let container = TesseraSchema.makeContainer(inMemory: true)
        // Its own defaults too, so a first-launch receipt or a remembered page never touches his.
        let defaults = UserDefaults(suiteName: "com.kaushikaranagu.tessera.sample") ?? .standard
        defaults.removePersistentDomain(forName: "com.kaushikaranagu.tessera.sample")
        // Not his settings: no Claude, no timer alerts, no settings writes reach anything of his.
        let model = AppModel(context: container.mainContext, launchDefaults: defaults, seedsStarterLists: true,
                             isSample: true)
        DemoData.prepareSample(model)
        self.container = container
        sample = model
        return model
    }

    /// Whether this context is the sample's: a backup or a copy refuses it (QA on #1199).
    func holds(_ context: TesseraContext) -> Bool {
        container.map { $0.mainContext === context } ?? false
    }

    /// Off: the sample is let go, so the next time it is on it starts fresh.
    func release() {
        sample = nil
        container = nil
    }
}

extension EnvironmentValues {
    /// His own model, even while the screens draw the sample: Backups reads and writes only this (QA on #1199).
    @Entry var realModel: AppModel?
}

extension AppModel {
    /// Where Tess's forget log lives; none for the sample, so a sample "Forget" never reaches his log (QA on #1199).
    var forgetLogURL: URL? {
        isSample ? nil : TessMemoryStore.defaultForgetLogURL
    }
}

extension AppModel {
    /// What Tess reads with a phrase: the clock, the set being logged, and the Money pools switch (Core #1233), which
    /// lets "got 3200 paycheck" land in a pool. Off by default; Off reads every phrase as before.
    func captureContext() -> TessContext {
        TessContext(now: AppClock.now, entry: session?.currentEntry?.id,
                    moneyPools: ReviewChoices.shared.value(of: "moneyPools") == "On")
    }
}

extension AppModel {
    /// A cook is the running process.
    var isCooking: Bool {
        guard let subject = processes.running()?.subject, let cookClass = classDef(.cook),
              let classDef = subject.classDef else { return false }
        return ClassResolver.isSubclass(classDef, of: cookClass)
    }
}

/// Write anywhere (sheet 135 part 5): the line goes through Core's WriteRouter to the app that reads it. A tie keeps
/// both readings and asks "Money or Kitchen?"; the next line naming one of them settles it.
@MainActor
enum WriteTie {
    static var waiting: [WriteRouter.Candidate] = []
}

extension AppModel {
    /// The routed write, or nil to let Tess read the line as before: the switch Off, no app reads it, or Tess is in
    /// the middle of something (a live workout, a set-count or dated-lift ask, a running cook), where "80 x 5" is a
    /// set, not a new lift (QA on #1245).
    func routedWrite(_ phrase: String,
                     enabled: Bool = ReviewChoices.shared.value(of: "writeAnywhere") == "On") -> String?
    {
        guard enabled, session == nil, pendingSetAsk == nil, pendingDatedLift == nil, !isCooking,
              let capture = runtime.tess as? TessCaptureEngine else { return nil }
        let context = captureContext()
        // The answer to "Money or Kitchen?": an app's word picks its reading.
        if !WriteTie.waiting.isEmpty {
            let asked = WriteTie.waiting
            WriteTie.waiting = []
            let word = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let pick = asked.first(where: { $0.app.name.lowercased() == word }) {
                return land(WriteRouter(engine: engine).perform(pick, with: capture, context: context))
            }
        }
        switch WriteRouter(engine: engine).route(phrase, context: context) {
        case .nothing:
            return nil
        case let .one(candidate):
            return land(WriteRouter(engine: engine).perform(candidate, with: capture, context: context))
        case let .tie(candidates):
            WriteTie.waiting = candidates
            let names = candidates.prefix(2).map(\.app.name)
            return names.count == 2 ? "\(names[0]) or \(names[1])?" : nil
        }
    }
}

extension AppModel {
    /// The open dated-lift ask ("Bench 80 × 8 for Monday?"), if the last phrase raised one.
    var pendingDatedLift: TessDatedLiftAsk? {
        (runtime.tess as? TessCaptureEngine)?.pendingDatedLift
    }
}
