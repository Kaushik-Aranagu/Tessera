import SwiftUI
import TesseraCore

// The energy check-in (Design 112): a 1 to 5 level on the rep drum, asked at most once a day on the morning plan
// line, paired with last night's sleep. Behind the Review switch `energyCheckIn` (Off: nothing shows). Never sent to
// Claude, never red.

// MARK: - The level, kept on this phone

/// Today's level, one per day. Core has no class for it yet, so it is kept on this iPhone (UserDefaults, keyed by the
/// day) until Core adds one; nothing goes in the op log, backups, packs or Claude. Under a demo flag nothing is
/// written: a level lasts until the app quits.
@MainActor
@Observable
final class EnergyLog {
    static let shared = EnergyLog()
    nonisolated static let levels = 1 ... 5
    nonisolated static let fallback = 3

    private let defaults: UserDefaults
    private let writes: Bool
    private var held: [String: Int] = [:]
    private var lastHeld: Int?

    init(defaults: UserDefaults = .standard, writes: Bool = !AppModel.isDemo) {
        self.defaults = defaults
        self.writes = writes
    }

    static func key(day: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "energy.%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static let lastKey = "energy.last"

    /// The level set on the day containing `now` (his day, from 04:00), or nil.
    func level(at now: Date, calendar: Calendar) -> Int? {
        let key = Self.key(day: TesseraDay(calendar: calendar).day(of: now), calendar: calendar)
        if let level = held[key] {
            return level
        }
        guard writes, defaults.object(forKey: key) != nil else { return nil }
        let level = defaults.integer(forKey: key)
        return Self.levels.contains(level) ? level : nil
    }

    /// Where the drum starts: the last answer, or 3.
    var startingLevel: Int {
        if let lastHeld {
            return lastHeld
        }
        let last = writes ? defaults.integer(forKey: Self.lastKey) : 0
        return Self.levels.contains(last) ? last : Self.fallback
    }

    func set(_ level: Int, at now: Date, calendar: Calendar) {
        guard Self.levels.contains(level) else { return }
        let key = Self.key(day: TesseraDay(calendar: calendar).day(of: now), calendar: calendar)
        held[key] = level
        lastHeld = level
        guard writes else { return }
        defaults.set(level, forKey: key)
        defaults.set(level, forKey: Self.lastKey)
    }

    /// Whether the morning plan line asks: the switch is on, it is morning, and no level is set today.
    func asks(switchOn: Bool, at now: Date, calendar: Calendar) -> Bool {
        switchOn && MyDayWindow.energyIsOpen(at: now, calendar: calendar) && level(at: now, calendar: calendar) == nil
    }
}

// MARK: - Words

enum EnergyCopy {
    static let ask = "Energy today?"
    static let word = "Energy"

    /// The drum's VoiceOver value: "3 of 5".
    static func spoken(_ level: Int) -> String {
        "\(level) of \(EnergyLog.levels.upperBound)"
    }

    /// The plan line's sleep: "slept 6h40".
    static func slept(_ minutes: Int) -> String {
        "slept \(LastNightSleep.short(minutes))"
    }

    /// The Day log's one quiet line: "Energy 4, slept 7 h", "Energy 4" with no sleep, nothing with no level.
    static func dayLog(level: Int?, asleepMinutes: Int?) -> String? {
        guard let level else { return nil }
        return asleepMinutes.map { "Energy \(level), slept \(LastNightSleep.rounded($0))" } ?? "Energy \(level)"
    }
}

// MARK: - The morning plan line

/// Under the plan hero in the morning: last night's sleep on the left, the energy ask and its drum on the right.
/// Once a level is set the drum settles into "Energy 4" in ink. Shows only with the switch on.
struct EnergyPlanLine: View {
    let now: Date
    let calendar: Calendar

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let log = EnergyLog.shared

    var body: some View {
        let level = log.level(at: now, calendar: calendar)
        let asleep = LastNightSleep.asleepMinutes(store: model.store, classes: model.classes, now: now,
                                                  calendar: calendar)
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            if let asleep {
                Text(EnergyCopy.slept(asleep))
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            Spacer(minLength: Theme.Spacing.s)
            if let level {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    Text(EnergyCopy.word)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                    Text("\(level)")
                        .textRole(.titleNumber)
                        .foregroundStyle(Theme.Colors.ink)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Energy, \(EnergyCopy.spoken(level))")
                .transition(.opacity)
            } else {
                Text(EnergyCopy.ask)
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.tess)
                    .accessibilityHidden(true)
                EnergyDrum(start: log.startingLevel) { picked in
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                        log.set(picked, at: AppClock.now, calendar: calendar)
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The rep drum's sibling for 1 to 5: numbers in a vertical snap scroll, no box, no words; the centre one large in
/// ink. Touching it sets the level: a scroll that settles on a number, or a tap on the centre one.
struct EnergyDrum: View {
    let start: Int
    let set: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scrolled: Int?
    @State private var settled = false
    @State private var picks = 0

    @ScaledMetric(relativeTo: .title) private var width: CGFloat = 56
    @ScaledMetric(relativeTo: .title) private var pitch: CGFloat = 44
    private let rows: CGFloat = 3

    var body: some View {
        let current = scrolled ?? start
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(EnergyLog.levels), id: \.self) { value in
                    let isCurrent = value == current
                    Text("\(value)")
                        .textRole(isCurrent ? .titleNumber : .body)
                        .foregroundStyle(isCurrent ? Theme.Colors.ink : Theme.Colors.inkTertiary)
                        .frame(width: width, height: pitch)
                        .contentShape(Rectangle())
                        .onTapGesture { pick(value) }
                        .tesseraAnimation(Theme.Motion.snappy, value: isCurrent)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
        .scrollPosition(id: $scrolled, anchor: .center)
        .contentMargins(.vertical, pitch * (rows - 1) / 2, for: .scrollContent)
        .frame(width: width, height: pitch * rows)
        .mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 0), .init(color: .black, location: 0.3),
                .init(color: .black, location: 0.7), .init(color: .clear, location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
        .onAppear { scrolled = start }
        .onScrollPhaseChange { _, phase in
            // A scroll he made that comes to rest sets the level; the drum's own first placement does not.
            if phase == .idle, settled, let scrolled {
                pick(scrolled)
            }
            if phase == .interacting {
                settled = true
            }
        }
        // One soft haptic when the level is set (Design 112), through the house haptics.
        .tesseraFeedback(.selection, trigger: picks)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(EnergyCopy.word)
        .accessibilityValue(EnergyCopy.spoken(current))
        .accessibilityHint("Sets today's energy")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: pick(min(EnergyLog.levels.upperBound, current + 1))
            case .decrement: pick(max(EnergyLog.levels.lowerBound, current - 1))
            @unknown default: break
            }
        }
    }

    private func pick(_ value: Int) {
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { scrolled = value }
        picks += 1
        set(value)
    }
}
