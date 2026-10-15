import SwiftUI

/// DEBUG gallery (`-soulGallery`): every soul mode side by side, plus the borrowed motifs. Used for recordings
/// and for tuning the choreography against the reference board.
struct SoulGallery: View {
    private let modes: [(String, TessSoul.Mode)] = [
        ("1 · Idle", .idle), ("2 · Listening", .listening), ("3 · Thinking", .thinking), ("4 · Working", .working),
        ("5 · Done", .done), ("6 · Needs you", .needsYou), ("7 · Hand-off", .handOff(target: CGPoint(x: 70, y: -40))),
        ("8 · Resting", .resting),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("Tess's soul").textRole(.title).foregroundStyle(Theme.Colors.ink)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)], spacing: 0) {
                    ForEach(modes, id: \.0) { name, mode in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(name).textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                            TessSoul(mode: mode, loopsOneShots: true)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                        }
                        .padding(Theme.Spacing.m)
                        .overlay(alignment: .top) { Hairline() }
                    }
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    Text("Glint").textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                    Text("Bench 85 kg, a new best").textRole(.title).foregroundStyle(Theme.Colors.ink).glint()
                    Text("Round robin").textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                    RoundRobin()
                    Text("Tick").textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Tick(seconds: 180 - context.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 180))
                            .foregroundStyle(Theme.Colors.ink)
                    }
                }
            }
            .padding(Theme.Spacing.gutter)
        }
        .background { ThemedBackground() }
    }
}
