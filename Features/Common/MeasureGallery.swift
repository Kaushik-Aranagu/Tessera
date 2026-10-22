import SwiftUI
import TesseraCore

/// Simulator only (`-measureGallery`, LaunchFlags): every kind of measure the wheel draws, for a clip or a still.
struct MeasureGallery: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Text("Measures").textRole(.title)
            row("Weight", Measure(82.5, "kg"))
            row("Distance", Measure(5, "km"))
            row("Time", Measure(95, "min"))
            row("Length", Measure(180, "cm"))
            row("Temperature", Measure(180, "°C"))
            // Typed in euros: swipe the unit and it reads as an estimate ("about 29.02 USD").
            row("Money", Measure.money(24.8, currency: "EUR"))
            Spacer()
        }
        .padding(Theme.Spacing.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { ThemedBackground() }
        .task {
            model.ratesTable = CurrencyRates(rates: ["USD": 1.17, "GBP": 0.87],
                                             date: Date(timeIntervalSince1970: 1_792_000_000))
        }
    }

    private func row(_ name: String, _ measure: Measure) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(name).textRole(.body).foregroundStyle(Theme.Colors.inkSecondary)
            Spacer()
            MeasureView(measure: measure, size: 28)
        }
    }
}
