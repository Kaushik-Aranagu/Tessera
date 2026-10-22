import SwiftUI
import TesseraCore

/// Kitchen's landing (Design 131 §2, v2, Kaushik's pick Oct 22): one sentence, then two large doors. Pantry, with a
/// level line per place and what is to get; Recipes, with this week as plain rows, today in full ink with its start,
/// open days faint. A running cook gets one line above both, "Go on" into its clock. The foot: Cook when a meal is
/// planned tonight, else Plan a meal. Behind Settings › Review › "Landing pages" (default Off).
struct KitchenLanding: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openHomeLink) private var open
    @Environment(\.colorScheme) private var scheme
    @State private var cookCover: KitchenCookCover?

    var body: some View {
        let _ = model.revision
        let front = KitchenFront(model: model, now: AppClock.now)
        let accent = KitchenFront.accent
        LandingPage(title: "Kitchen",
                    sentence: LandingSentence.build(front.sentence, accent: accent),
                    accent: accent,
                    running: front.cooking.map { cook in
                        [LandingLine(
                            text: cook.line,
                            link: (word: "Go on", action: { cookCover = .init(id: cook.id) })
                        )]
                    } ?? [],
                    lead: { KitchenDoors(front: front, open: open) },
                    doors: [LandingDoor(word: "Groceries") { open(.groceries) },
                            LandingDoor(word: "Lists") { open(.lists) },
                            LandingDoor(word: "Paste a recipe") { open(.pasteRecipe) }],
                    action: front.tonight.map { meal in
                        LandingAction(word: "Cook", hint: "Starts \(meal.title)") { cook(meal) }
                    },
                    secondary: LandingAction(word: "Plan a meal", hint: "Opens Recipes") { open(.recipes) },
                    standalone: false)
            .fullScreenCover(item: $cookCover) { CookClockPage(cookID: $0.id) }
            .accessibilityElement(children: .contain)
    }

    /// Cook: tonight's recipe starts at its size and its clock opens (the same as Cook on the recipe page).
    private func cook(_ meal: KitchenFront.Meal) {
        guard let recipe = meal.recipe else {
            open(.recipes)
            return
        }
        guard let cook = try? model.engine.perform(StartCooking(recipe: recipe, time: AppClock.now), by: .user).output
        else {
            TessVoice.shared.say("Didn't start that. Try again.")
            return
        }
        model.touch()
        cookCover = .init(id: cook.id)
    }
}

struct KitchenCookCover: Identifiable {
    let id: UUID
}

/// Pantry and Recipes, the two big doors, each with its summary under it.
private struct KitchenDoors: View {
    let front: KitchenFront
    let open: (HomeLink) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            door("Pantry", value: front.toGet > 0 ? "\(front.toGet) to get" : nil, link: .pantry) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(front.places, id: \.name) { place in
                        LevelLine(name: place.name, level: place.level)
                    }
                }
            }
            door("Recipes", value: front.saved > 0 ? "\(front.saved) saved" : nil, link: .recipes) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(front.week) { day in
                        WeekRow(day: day)
                    }
                }
            }
        }
    }

    private func door(_ word: String, value: String?, link: HomeLink,
                      @ViewBuilder summary: () -> some View) -> some View
    {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Button { open(link) } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(word)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                    Spacer(minLength: Theme.Spacing.m)
                    if let value {
                        Text(value)
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityLabel(value.map { "\(word), \($0)" } ?? word)
            .accessibilityHint("Opens \(word)")
            summary()
        }
    }
}

/// Kitchen's signature line: a place and how full it is of what it usually holds (things in, against things low or
/// out). An ink stroke on a faint track, no colour, no box.
private struct LevelLine: View {
    let name: String
    let level: Double

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            Text(name)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(width: 84, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colors.ink.opacity(0.12)).frame(height: 1.5)
                    Capsule().fill(Theme.Colors.ink).frame(width: proxy.size.width * level, height: 2.5)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 12)
            .tesseraAnimation(value: level)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(KitchenFront.levelWords(level))
    }
}

/// One day of the week: its short name, the meal, its time; an open day faint.
private struct WeekRow: View {
    let day: KitchenFront.Day

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Text(day.weekday)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(width: 44, alignment: .leading)
            Text(day.meal?.title ?? "Open")
                .textRole(day.isToday ? .bodyStrong : .body)
                .foregroundStyle(day.meal == nil ? Theme.Colors.ink.opacity(0.4) : Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.Spacing.s)
            if let when = day.when {
                Text(when)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
