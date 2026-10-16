import SwiftUI

/// DEBUG gallery (`-soulGallery`): every soul mode side by side on light and dark grounds, a soul that walks through
/// the modes to show the blends, and the borrowed motifs. Used for recordings and for tuning against the board.
struct SoulGallery: View {
    private static let modes: [(String, TessSoul.Mode)] = [
        ("1 · Idle", .idle), ("2 · Listening", .listening), ("3 · Thinking", .thinking), ("4 · Needs you", .needsYou),
        ("5 · Done", .done), ("6 · Hand-off", .handOff(target: CGPoint(x: 60, y: -30))), ("7 · Resting", .resting),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("Tess's soul").textRole(.title).foregroundStyle(Theme.Colors.ink)
                grid
                Text("On a dark ground").textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                grid
                    .background(Theme.Colors.Workout.ground, in: .rect(cornerRadius: 18))
                    .environment(\.colorScheme, .dark)
                Text("Blending, every 2.5 s").textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                ModeWalk(modes: Self.modes)
                motifs
            }
            .padding(Theme.Spacing.gutter)
        }
        .background { ThemedBackground() }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)], spacing: 0) {
            ForEach(Self.modes, id: \.0) { name, mode in
                VStack(alignment: .leading, spacing: 0) {
                    Text(name).textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                    TessSoul(mode: mode, loopsOneShots: true)
                        .frame(maxWidth: .infinity)
                        .frame(height: 130)
                }
                .padding(Theme.Spacing.m)
                .overlay(alignment: .top) { Hairline() }
            }
        }
    }

    private var motifs: some View {
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
}

/// One soul stepping through the modes, so the 0.4 s blends between them can be checked by eye.
private struct ModeWalk: View {
    let modes: [(String, TessSoul.Mode)]
    @State private var index = 0

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            TessSoul(mode: modes[index].1)
                .frame(width: 130, height: 130)
            Text(modes[index].0).textRole(.label).foregroundStyle(Theme.Colors.ink)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.5))
                index = (index + 1) % modes.count
            }
        }
    }
}
