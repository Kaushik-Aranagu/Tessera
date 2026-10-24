import SwiftUI
import TesseraCore

/// Settings, overhauled (sheet 203; Kaushik, Oct 23): one sentence line per preference, a value on the right, its
/// choices opening in place as words. Where two features do the same job they are one choice. Every change speaks one
/// line with the one Undo. Developer mode (hold the build line) only turns things off. The Claude key keeps its own
/// page and is never shown here; no money values or health data appear on this page.
struct SettingsHub: View {
    var cameFrom = "Home"
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var developerOpen = false
    @State private var holds = 0

    private let choices = ReviewChoices.shared

    var body: some View {
        let _ = model.revision
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isPresented {
                    Button { dismiss() } label: {
                        Text("‹ \(cameFrom)")
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Back to \(cameFrom)")
                }
                Text("Settings")
                    .textRole(.hero)
                    .wordFit("Settings")
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)

                group("You") {
                    weightLine
                    SettingsPageLine(sentence: "About me", hint: "Weight, height, age") { MePage() }
                    SettingsPageLine(sentence: "Rest day", hint: "Which day you rest") {
                        HubPage(title: "Rest day") { RestDaySentence() }
                    }
                    SettingsPageLine(sentence: "Colours by day and night") {
                        HubPage(title: "Colours") { LookSentence() }
                    }
                }
                group("Time") {
                    if Tier1b.quietIsOn {
                        quietLine
                    }
                    dayTurnsLine
                }
                group("Home") {
                    flagLine("homeAppsList", "Apps list under Next")
                    conflictLine("homeIs")
                }
                group("Tess") {
                    SettingsPageLine(sentence: "Tess asks Claude", value: model.asksClaude ? "On" : "Off",
                                     valueColor: Theme.Colors.tess,
                                     hint: "Only with your key, and never your health, calendar, body, money or private words")
                    {
                        HubPage(title: "Tess asks Claude") { ClaudeSection() }
                    }
                    valueLine("tessFace", "Tess has eyes", names: ["Off": "Off", "Eyes": "On"])
                    flagLine("trainingAutoName", "Tess names training days")
                }
                group("Training") {
                    flagLine("restTimer", "Rest timer")
                    valueLine("swapExercise", "Swap an exercise with")
                    flagLine("finishNudge", "Nudge if I forget Finish")
                }
                group("Kitchen") {
                    flagLine("cookTimerVoice", "The cook timer speaks")
                    flagLine("handsFreeCook", "Hands-free while cooking")
                }
                group("Privacy") {
                    SettingsPageLine(sentence: "Words that stay private", hint: "What stays on this phone") {
                        PrivacyWordsPage()
                    }
                }
                group("Look") {
                    conflictLine("pagesTurnBy")
                    valueLine("font", "Font")
                }
                group("Safe keeping") {
                    SettingsPageLine(sentence: "Backups", hint: "Where your history is kept") { BackupView() }
                    SettingsPageLine(sentence: "Undo, everything you did", hint: "Recent changes") {
                        RecentChangesPage()
                    }
                }
                group("About") {
                    SettingsPageLine(sentence: "Credits", hint: "Who made what") { AboutPage() }
                    buildLine
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .navigationBarBackButtonHidden()
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $developerOpen) { DeveloperMode() }
        .tesseraFeedback(.selection, trigger: holds)
    }

    // MARK: Lines

    private func group(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .padding(.top, Theme.Spacing.xl)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func choice(_ id: String) -> ReviewChoices.Choice? {
        ReviewChoices.all.first { $0.id == id }
    }

    /// An On/Off flag as a line.
    @ViewBuilder
    private func flagLine(_ id: String, _ sentence: String, why: String? = nil) -> some View {
        if let row = choice(id) {
            SettingsLine(sentence: sentence, options: [.init(id: "On", name: "On"), .init(id: "Off", name: "Off")],
                         selected: choices.value(of: row), why: why)
            { option in
                set(row, to: option.id, said: "\(sentence), \(option.id.lowercased()).")
            }
        }
    }

    /// A multi-value switch as a line; `names` shows a value under another name ("Eyes" reads "On").
    @ViewBuilder
    private func valueLine(_ id: String, _ sentence: String, names: [String: String] = [:]) -> some View {
        if let row = choice(id) {
            SettingsLine(sentence: sentence,
                         options: row.values.map { .init(id: $0, name: names[$0] ?? $0) },
                         selected: choices.value(of: row))
            { option in
                set(row, to: option.id, said: "\(sentence), \((names[option.id] ?? option.id).lowercased()).")
            }
        }
    }

    /// Two features that do the same job: one choice, the other turns off.
    @ViewBuilder
    private func conflictLine(_ id: String) -> some View {
        if let conflict = FeatureChoices.choice(id) {
            SettingsLine(sentence: conflict.sentence,
                         options: conflict.options.map { .init(id: $0.id, name: $0.name) },
                         selected: HubChoices.selected(id)?.id ?? conflict.defaultOption)
            { option in
                let undo = HubChoices.choose(option.id, in: id)
                model.touch()
                TessVoice.shared.say("\(conflict.sentence) \(option.name.lowercased()).", takeBack: {
                    HubChoices.restore(undo)
                    model.touch()
                })
            }
        }
    }

    private var weightLine: some View {
        let kind = MeasureKind.weight
        let current = model.displayUnits.unit(for: kind) ?? UnitsCopy.standard(kind)
        return SettingsLine(sentence: "Weights in", options: kind.units.map { .init(id: $0, name: $0) },
                            selected: current)
        { option in
            let previous = current
            model.chooseUnit(option.id, for: kind)
            TessVoice.shared.say("Weights in \(option.name).", takeBack: {
                model.chooseUnit(previous, for: kind)
            })
        }
    }

    private var quietLine: some View {
        let hours = model.settingsAreReal ? SettingsStore(engine: model.engine).read().quietHours : QuietHours.standard
        return SettingsPageLine(sentence: "Quiet hours", value: hours.words,
                                hint: "When notices wait. Timers always come through.")
        {
            QuietHoursPage()
        }
    }

    /// "The day turns over at 4 am": when late-night things stop belonging to yesterday.
    private var dayTurnsLine: some View {
        let current = model.settingsAreReal ? SettingsStore(engine: model.engine).read().dayTurnsAtHour : 4
        let options = (0 ... 8).map { SettingsLine.Option(id: "\($0)", name: HouseTime.clock(minuteOfDay: $0 * 60)) }
        return SettingsLine(sentence: "The day turns over at", options: options, selected: "\(current)",
                            why: TesseraSettings.dayTurnsAtWhy)
        { option in
            guard let hour = Int(option.id) else { return }
            let previous = current
            model.updateSettings { $0.dayStartHour = hour }
            TessVoice.shared.say("The day turns over at \(option.name).", takeBack: {
                model.updateSettings { $0.dayStartHour = previous }
            })
        }
    }

    private func set(_ row: ReviewChoices.Choice, to value: String, said: String) {
        let previous = choices.value(of: row)
        choices.set(row, to: value)
        model.touch()
        TessVoice.shared.say(said, takeBack: {
            choices.set(row, to: previous)
            model.touch()
        })
    }

    /// "Tessera, build N. Hold for Developer mode." Holding it 700 ms opens Developer mode; Enter does with
    /// VoiceOver or a keyboard.
    private var buildLine: some View {
        Text("Tessera, build \(BuildStamp.short). Hold for Developer mode.")
            .textRole(.data)
            .foregroundStyle(Theme.Colors.inkSecondary)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.top, Theme.Spacing.l)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.7) {
                holds += 1
                developerOpen = true
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tessera, build \(BuildStamp.short)")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Opens Developer mode")
            .accessibilityAction { developerOpen = true }
    }
}

/// A page under Settings that holds a sentence component: the back word, the title, then the component.
struct HubPage<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Button { dismiss() } label: {
                    Text("‹ Settings")
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityLabel("Back to Settings")
                Text(title)
                    .textRole(.hero)
                    .wordFit(title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                content()
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .navigationBarBackButtonHidden()
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

/// Developer mode (sheet 203): every feature flag the main page does not carry, by app, all On. One tap turns a flag
/// Off and another brings it back. It never adds a feature. Tools: Sample data (simulator only), Class inspector,
/// Recent changes.
struct DeveloperMode: View {
    @Environment(AppModel.self) private var model
    private let choices = ReviewChoices.shared

    var body: some View {
        let _ = model.revision
        HubPage(title: "Developer mode") {
            VStack(alignment: .leading, spacing: 0) {
                Text("Only for turning things off. A flag that is Off comes back with one more tap.")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(groups, id: \.group) { entry in
                    Text(entry.group.rawValue)
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .padding(.top, Theme.Spacing.xl)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(entry.flags, id: \.flag.id) { item in
                        flagRow(item.flag, isOn: item.isOn)
                    }
                }
                Text("Tools")
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .padding(.top, Theme.Spacing.xl)
                    .accessibilityAddTraits(.isHeader)
                if LaunchFlags.allowed {
                    toolRow("sampleData", "Sample data")
                }
                toolRow("classInspector", "Class inspector")
                SettingsPageLine(sentence: "Recent changes") { RecentChangesPage() }
            }
        }
    }

    private var groups: [(group: FeatureGroup, flags: [(flag: FeatureFlag, isOn: Bool)])] {
        FeatureFlags.developerGroups(off: HubChoices.state().off).compactMap { entry in
            let rest = entry.flags.filter { !HubChoices.onMainPage.contains($0.flag.id) }
            return rest.isEmpty ? nil : (group: entry.group, flags: rest)
        }
    }

    private func flagRow(_ flag: FeatureFlag, isOn: Bool) -> some View {
        Button {
            guard let row = ReviewChoices.all.first(where: { $0.id == flag.id }) else { return }
            let next = isOn ? "Off" : "On"
            choices.set(row, to: next)
            model.touch()
            TessVoice.shared.say("\(flag.name), \(next.lowercased()).", takeBack: {
                choices.set(row, to: isOn ? "On" : "Off")
                model.touch()
            })
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Text(flag.name).foregroundStyle(Theme.Colors.ink)
                Spacer(minLength: Theme.Spacing.s)
                Text(isOn ? (flag.needsClaude && !model.asksClaude ? "On, held" : "On") : "Off")
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            .textRole(.body)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(flag.name)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(isOn ? "Turns it off" : "Turns it back on")
    }

    @ViewBuilder
    private func toolRow(_ id: String, _ name: String) -> some View {
        if let row = ReviewChoices.all.first(where: { $0.id == id }) {
            SettingsLine(sentence: name,
                         options: [.init(id: "On", name: "On"), .init(id: "Off", name: "Off")],
                         selected: choices.value(of: row))
            { option in
                choices.set(row, to: option.id)
                model.touch()
            }
        }
    }
}
