import Foundation
import FoundationModels
import TesseraCore
import TesseraTess

/// "Tess names training days" (Core's #1160; Kaushik, Oct 19, 7:12 PM). After a change settles, every routine Tess
/// may still name gets a short name from its exercises: the phone's own model first, Claude only when "Tess asks
/// Claude" is on, else the rule name. A private routine is never named, and his own name stops it for good
/// (`DayNames.mayAutoName`). The Review row `trainingAutoName` (default On) turns it off.
extension AppModel {
    var dayNamer: DayNamer {
        if let namer = dayNamerStore {
            return namer
        }
        let namer = DayNamer(keys: SystemKeychain(), ledger: TessUsageLedger(store: store, classes: classes),
                             allowed: { [weak self] in (self?.asksClaude ?? false) && !PowerState.isLowPower },
                             enabled: { DayNamingSwitch.isOn(ReviewChoices.shared.value(of: DayNames.reviewKey)) })
        namer.now = { AppClock.now }
        // On-device first (his 7:12 PM rule): with the phone's own model present, Claude is never asked; until Builder
        // A's closure plugs in, such a phone takes the rule name.
        namer.onDeviceAvailable = { DayNamingSwitch.onDeviceModelReady() }
        dayNamerStore = namer
        return namer
    }

    /// Names waiting routines a moment after the last change, so a routine being built is named once it settles.
    func nameTrainingDaysSoon(after delay: Duration = .seconds(2)) {
        guard DayNamingSwitch.isOn(ReviewChoices.shared.value(of: DayNames.reviewKey)) else { return }
        dayNaming?.cancel()
        dayNaming = Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await self?.nameTrainingDays()
        }
    }

    /// Every routine that needs a name, named one at a time. Returns the names applied.
    @discardableResult
    func nameTrainingDays() async -> [String] {
        guard let routineClass = classes[.routine] else { return [] }
        let waiting = store.objects(of: routineClass).filter {
            !$0.isDeleted && DayNames.needsName($0, store: store)
        }
        var named: [String] = []
        for routine in waiting {
            if let name = await dayNamer.autoName(routine, engine: engine) {
                named.append(name)
            }
        }
        if !named.isEmpty {
            // Saves and redraws; the pass it schedules finds nothing waiting, so this never loops.
            touch()
        }
        return named
    }
}

/// The Review switch read for day naming: On unless he turned it Off.
enum DayNamingSwitch {
    static func isOn(_ value: String?) -> Bool {
        value != "Off"
    }

    /// The phone's own model can run now.
    static func onDeviceModelReady() -> Bool {
        SystemLanguageModel.default.isAvailable
    }
}
