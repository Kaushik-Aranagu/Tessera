import Foundation
import Observation
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

    @ObservationIgnored private var container: TesseraContainer?
    @ObservationIgnored private var sample: AppModel?

    /// The model the screens draw: the sample while the switch is on, else his own.
    func model(over real: AppModel) -> AppModel {
        guard Self.isOn else { return real }
        if let sample {
            return sample
        }
        let container = TesseraSchema.makeContainer(inMemory: true)
        // Its own defaults too, so a first-launch receipt or a remembered page never touches his.
        let defaults = UserDefaults(suiteName: "com.kaushikaranagu.tessera.sample") ?? .standard
        defaults.removePersistentDomain(forName: "com.kaushikaranagu.tessera.sample")
        let model = AppModel(context: container.mainContext, launchDefaults: defaults, seedsStarterLists: true)
        // Not his settings: no Claude, no timer alerts, no settings writes reach anything of his.
        model.settingsAreReal = false
        DemoData.prepareSample(model)
        self.container = container
        sample = model
        return model
    }

    /// Off: the sample is let go, so the next time it is on it starts fresh.
    func release() {
        sample = nil
        container = nil
    }
}
