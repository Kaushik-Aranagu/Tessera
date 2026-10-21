import Foundation
import TesseraCore
import TesseraTess

/// The unit wheel's two services (Design sheet 115): his unit pick per kind, and the exchange rates the money wheel
/// uses. Both are display only: a stored value never changes when a unit does.
extension AppModel {
    /// The unit he last picked for each kind (nothing picked yet: each measure keeps its own unit).
    var displayUnits: DisplayUnits {
        _ = revision
        return settingsAreReal ? SettingsStore(engine: engine).read().displayUnits : DisplayUnits()
    }

    /// He swiped a unit: remember it for the whole kind, so every weight (or length, or time...) changes with it.
    func chooseUnit(_ unit: String, for kind: MeasureKind) {
        guard settingsAreReal else { return }
        _ = try? SettingsStore(engine: engine).update { $0.displayUnits.choose(unit, for: kind) }
        touch()
    }

    /// The only fetch instance in the app. Its once-an-hour cap is per instance, so it must stay one.
    var currencyFetch: CurrencyRatesFetch {
        if let fetch = currencyFetchStore {
            return fetch
        }
        let fetch = CurrencyRatesFetch()
        currencyFetchStore = fetch
        return fetch
    }

    /// THE call site of the rates fetch. A page that shows money calls this once when it opens (`.refreshesRates()`
    /// below, applied to the page, never to a row or a view that redraws); `refreshIfNeeded()` itself answers with the
    /// saved table at once unless one is due (nothing saved, or the last try was over an hour ago), so a second page
    /// opening inside the hour makes no request. Only the public ECB file is asked for; nothing of his goes with it.
    @discardableResult
    func refreshRates() async -> CurrencyRates? {
        let table = await currencyFetch.refreshIfNeeded()
        if table != ratesTable {
            ratesTable = table
        }
        return table
    }
}
