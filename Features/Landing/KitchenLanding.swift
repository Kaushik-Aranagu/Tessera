import SwiftUI
import TesseraCore

/// Kitchen's landing (Design 131 §2, v2, Kaushik's pick Oct 22): one sentence, then two large doors. Pantry, with a
/// level line per place and what is to get; Recipes, with this week as plain rows, today in full ink with its start,
/// open days faint. A running cook gets one line above both, "Go on" into its clock. The foot: Cook when a meal is
/// planned tonight, else Plan a meal. Behind Settings › Review › "Landing pages" (default Off).
struct KitchenLandingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openHomeLink) private var open
    @Environment(\.colorScheme) private var scheme
    @State private var cookCover: KitchenCookCover?

    var body: some View {
        let _ = model.revision
        let front = KitchenFront(model: model, now: AppClock.now)
        let accent = KitchenFront.accent
        LandingPage(title: "Kitchen",
                    sentence: LandingText.build(front.sentence, accent: accent),
                    accent: accent,
                    running: front.cooking.map { cook in
                        [LandingLine(
                            text: cook.line,
                            link: (word: "Go on", action: { cookCover = .init(id: cook.id) })
                        )]
                    } ?? [],
                    lead: { KitchenDoors(front: front, open: open) },
                    // Groceries lives in Pantry as To get (Design on #1224). Lists stays: Kitchen is its only door
                    // until
                    // the Lists landing has its own place in Home.
                    doors: [LandingDoor(word: "Lists") { open(.lists) },
                            LandingDoor(word: "Paste a recipe") { open(.pasteRecipe) }],
                    // Cook when a meal is planned tonight, else Plan a meal takes the one underline.
                    action: front.tonight.map { meal in
                        LandingAction(word: "Cook", hint: "Starts \(meal.title)") { cook(meal) }
                    } ?? LandingAction(word: "Plan a meal", hint: "Opens Recipes") { open(.recipes) },
                    secondary: front.tonight == nil ? nil
                        : LandingAction(word: "Plan a meal", hint: "Opens Recipes") { open(.recipes) },
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
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            door("Pantry", value: front.pantryValue, link: .pantry) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(front.places, id: \.name) { place in
                        LevelLine(name: place.name, level: place.level)
                    }
                }
            }
            door("Recipes", value: nil, link: .recipes) {
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
                // At accessibility sizes the value goes under the word, so the word never breaks.
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
                    : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
                layout {
                    Text(word)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if !typeSize.isAccessibilitySize {
                        Spacer(minLength: Theme.Spacing.m)
                    }
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

/// Kitchen's signature line: a place and how full it is (KitchenFront.level). An ink stroke on a faint track, no
/// colour, no box; no line at all when nothing in the place is known. At accessibility sizes the line sits under the
/// word only as wide as its fill, so it never reads as a row separator (Design, release 42).
private struct LevelLine: View {
    let name: String
    let level: Double?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Theme.Spacing.m))
        layout {
            Text(name)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(width: typeSize.isAccessibilitySize ? nil : 84, alignment: .leading)
            if let level {
                if typeSize.isAccessibilitySize {
                    // The fill alone, under the word: a share of the word's own width.
                    Capsule().fill(Theme.Colors.ink)
                        .frame(width: max(120 * level, level > 0 ? 6 : 0), height: 2.5)
                        .tesseraAnimation(value: level)
                } else {
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
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(level.map(KitchenFront.levelWords) ?? "nothing known yet")
    }
}

/// One day of the week: its short name, the meal, its time; an open day faint.
private struct WeekRow: View {
    let day: KitchenFront.Day
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
        layout {
            Text(day.weekday)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(width: typeSize.isAccessibilitySize ? nil : 44, alignment: .leading)
            Text(day.meal?.title ?? "Open")
                .textRole(day.isToday ? .bodyStrong : .body)
                .foregroundStyle(day.meal == nil ? Theme.Colors.ink.opacity(0.4) : Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !typeSize.isAccessibilitySize {
                Spacer(minLength: Theme.Spacing.s)
            }
            if let when = day.when {
                Text(when)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
