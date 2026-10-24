import SwiftUI
import TesseraCore

/// One row of the wheel: a recipe, or "New recipe" at the end of the loop.
private enum RecipeRow: Identifiable {
    case recipe(RecipesRoomBoard.Item)
    case new

    var id: String {
        switch self {
        case let .recipe(item): item.id.uuidString
        case .new: "new"
        }
    }
}

/// Recipes (sheet 233 v5): the place dial over four lenses (Ready now, One short, Planned, All), two brief lines, a
/// section line, and the wheel of recipes, quickest first with pinned ones on top and "New recipe" in the loop. The
/// focus row is large with two detail lines that clip in. A tap on the focused lens opens the full-page list; the
/// left edge closes it. The foot follows the focus: Cook now, Get it, Get 2 things, New recipe. Every change is a
/// receipt with the one Undo. Calories wait on Core's nutrition table. Behind the Kitchen rooms switch.
struct RecipesRoomPage: View {
    var open: (UUID) -> Void
    var paste: () -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var lens = 0
    @State private var top = 0
    @State private var full = false
    @State private var receipts = KitchenReceipts()
    @State private var cooking: CookingCover?

    private struct CookingCover: Identifiable {
        let id: UUID
    }

    var body: some View {
        let _ = model.revision
        let board = RecipesRoomBoard(store: model.store, classes: model.classes, now: AppClock.now)
        let lenses = RecipesRoomBoard.Lens.allCases
        let current = lenses[min(lens, lenses.count - 1)]
        let rows = wheelRows(board.items(in: current))
        let focused = rows.isEmpty ? nil : rows[min(top, rows.count - 1)]
        VStack(alignment: .leading, spacing: 0) {
            header(toGet: board.toGetCount)
            if !full {
                PlaceDial(places: lenses.map { .init(id: $0.rawValue, name: $0.rawValue, count: board.count($0)) },
                          focus: $lens, onTapFocus: { openFull() })
                    .padding(.horizontal, Theme.Spacing.gutter)
                    .onChange(of: lens) { top = 0 }
                brief(board)
            }
            sectionLine(current, count: board.count(current))
            wheel(rows)
                .padding(.horizontal, Theme.Spacing.gutter)
            Spacer(minLength: 0)
            ReceiptLine(receipts: receipts).padding(.horizontal, Theme.Spacing.gutter)
            foot(focused)
        }
        .background { ThemedBackground() }
        .background {
            if !full {
                EdgeSwipeBack()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 24, coordinateSpace: .global).onEnded { value in
                if full, value.startLocation.x < 28, value.translation.width > 80 {
                    withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { full = false }
                }
            }
        )
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $cooking) { CookClockPage(cookID: $0.id) }
        .accessibilityAction(.escape) {
            if full {
                full = false
            } else {
                dismiss()
            }
        }
    }

    // MARK: Parts

    private func header(toGet: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Recipes")
                .font(Theme.voice(size: 17).weight(.semibold))
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Text(PantryRoomCopy.toGetWord(toGet))
                .font(Theme.voice(size: 15))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .frame(minHeight: 44)
    }

    private func brief(_ board: RecipesRoomBoard) -> some View {
        let lines = RecipesRoomBoard.brief(board.items(in: .ready))
        return VStack(alignment: .leading, spacing: 0) {
            KitchenBriefLine(text: lines.first)
            KitchenBriefLine(text: lines.second)
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .accessibilityElement(children: .combine)
    }

    private func sectionLine(_ lens: RecipesRoomBoard.Lens, count: Int) -> some View {
        Text(RecipesRoomBoard.sectionLine(lens, count: count))
            .font(Theme.voice(size: 13))
            .foregroundStyle(Theme.Colors.inkSecondary)
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .trailing)
            .padding(.horizontal, Theme.Spacing.gutter)
    }

    private func wheelRows(_ items: [RecipesRoomBoard.Item]) -> [RecipeRow] {
        items.map(RecipeRow.recipe) + [.new]
    }

    private func wheel(_ rows: [RecipeRow]) -> some View {
        FocusWheel(items: rows, top: $top, others: full ? 9 : 4, onOpen: { row in
            if case let .recipe(item) = row {
                open(item.id)
            } else {
                paste()
            }
        }) { row, focus, distance in
            rowView(row, focus: focus, distance: distance)
        }
    }

    @ViewBuilder
    private func rowView(_ row: RecipeRow, focus: Double, distance: Int) -> some View {
        switch row {
        case let .recipe(item):
            let size = 15 + 13 * focus + (distance == 1 ? 2 * (1 - focus) : 0)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    Text(KitchenText.short(item.name, limit: 22))
                        .font(Theme.voice(size: size)
                            .weight(focus > 0.5 ? .semibold : (item.isPinned ? .semibold : .regular)))
                        .foregroundStyle(focus > 0.5 ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                        .lineLimit(1)
                    Spacer(minLength: Theme.Spacing.s)
                    if focus < 0.5, let minutes = item.minutes {
                        minutesWord(minutes, size: size)
                    }
                }
                // The two detail lines clip in as the row comes into focus.
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.detailOne).lineLimit(1)
                    Text(item.detailTwo).lineLimit(1)
                }
                .font(Theme.voice(size: 15))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(height: 22 * 2 * focus, alignment: .top)
                .clipped()
            }
        case .new:
            Text("New recipe")
                .font(Theme.voice(size: 15 + 13 * focus).weight(focus > 0.5 ? .semibold : .regular))
                .foregroundStyle(Theme.Colors.Accent.kitchenText)
                .lineLimit(1)
        }
    }

    /// "20 min" with "min" at 0.62 of the number.
    private func minutesWord(_ minutes: Int, size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(minutes)").font(Theme.numeral(size))
            Text("min").font(Theme.voice(size: size * 0.62))
        }
        .foregroundStyle(Theme.Colors.inkSecondary)
    }

    private func foot(_ focused: RecipeRow?) -> some View {
        Group {
            switch focused {
            case let .recipe(item)?:
                KitchenFoot(action: RecipesRoomBoard.footWord(shorts: item.shorts.count)) { footTapped(item) }
            case .new?:
                KitchenFoot(action: "New recipe", hint: "Tell Tess, type it, or paste a link.") { paste() }
            case nil:
                KitchenFoot(action: "New recipe", hint: "Tell Tess, type it, or paste a link.") { paste() }
            }
        }
        .padding(.bottom, HomeMosaic.tessRoom / 2)
    }

    // MARK: Actions

    private func openFull() {
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { full = true }
    }

    private func footTapped(_ item: RecipesRoomBoard.Item) {
        if item.shorts.isEmpty {
            cook(item)
        } else {
            getShorts(item)
        }
    }

    private func cook(_ item: RecipesRoomBoard.Item) {
        var started: UUID?
        let refusal = RecipeCopy.startCook {
            let result = try model.engine.perform(StartCooking(recipe: item.id, serves: nil), by: .user)
            started = result.output.id
            return result
        }
        if let refusal {
            receipts.say(refusal)
            return
        }
        model.touch()
        if let started {
            cooking = CookingCover(id: started)
        }
    }

    /// "Feta and mascarpone, on To get." with the one Undo.
    private func getShorts(_ item: RecipesRoomBoard.Item) {
        guard let result = try? model.engine.perform(AddGroceries(lines: item.shorts), by: .user) else {
            receipts.say("Didn't save that. Try again.")
            return
        }
        let record: OpRecord? = result.record
        model.touch()
        receipts.say(RecipesRoomBoard.getReceipt(item.shorts)) {
            if let record {
                _ = model.engine.undo(record)
            }
            model.touch()
        }
    }
}
