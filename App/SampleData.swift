import Foundation
import Observation
import SwiftUI
import TesseraCore

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
