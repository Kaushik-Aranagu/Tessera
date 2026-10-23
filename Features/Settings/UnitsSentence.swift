import SwiftUI
import TesseraCore

/// "Weights in kg, distances in km, lengths in cm, temperatures in °C." Each unit is a value word: a tap moves it
/// to the kind's other unit, the same pick a swipe on any unit word makes (Design sheet 115). Display only: stored
/// values never change. In a demo nothing is written; the pick lasts until the app quits.
struct UnitsSentence: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Picks made in a demo, which never writes his settings.
    @State private var demoPicks: [MeasureKind: String] = [:]

    var body: some View {
        let _ = model.revision
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(UnitsCopy.kinds.enumerated()), id: \.element) { index, kind in
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(UnitsCopy.lead(kind, first: index == 0))
                    Button(unit(kind)) { step(kind) }
                        .buttonStyle(.valueWash)
                        .fontWeight(.semibold)
                        .foregroundStyle(SettingsV2.valueInk)
                        .contentTransition(.opacity)
                        .accessibilityLabel(UnitsCopy.name(kind))
                        .accessibilityValue(MeasureParts.spokenUnit(unit(kind)))
                        .accessibilityHint("Changes the unit everywhere this shows")
                    Text(index == UnitsCopy.kinds.count - 1 ? "." : ",")
                }
                .frame(minHeight: 44, alignment: .leading)
            }
        }
        .textRole(.body)
        .foregroundStyle(Theme.Colors.ink)
    }

    private func unit(_ kind: MeasureKind) -> String {
        demoPicks[kind] ?? model.displayUnits.unit(for: kind) ?? UnitsCopy.standard(kind)
    }

    private func step(_ kind: MeasureKind) {
        let next = UnitsCopy.next(after: unit(kind), in: kind)
        withTesseraAnimation(.easeOut(duration: 0.15), reduceMotion: reduceMotion) {
            if AppModel.isDemo {
                demoPicks[kind] = next
            } else {
                model.chooseUnit(next, for: kind)
            }
        }
    }
}

/// The Units sentence's words, pure so they are tested without a view.
enum UnitsCopy {
    /// The kinds he can pick a unit for here; time reads in minutes and hours on its own, money swipes on its amount.
    static let kinds: [MeasureKind] = [.weight, .distance, .length, .temperature]

    static func lead(_ kind: MeasureKind, first: Bool) -> String {
        let word = switch kind {
        case .weight: "weights"
        case .distance: "distances"
        case .length: "lengths"
        case .temperature: "temperatures"
        default: kind.rawValue
        }
        return (first ? word.prefix(1).uppercased() + word.dropFirst() : " " + word) + " in "
    }

    static func name(_ kind: MeasureKind) -> String {
        switch kind {
        case .weight: "Weight unit"
        case .distance: "Distance unit"
        case .length: "Length unit"
        case .temperature: "Temperature unit"
        default: "Unit"
        }
    }

    /// The unit a kind reads in before he picks one.
    static func standard(_ kind: MeasureKind) -> String {
        kind.units.first ?? ""
    }

    /// The kind's next unit, wrapping.
    static func next(after unit: String, in kind: MeasureKind) -> String {
        MeasureParts.cycle(kind.units, from: unit)
    }
}
