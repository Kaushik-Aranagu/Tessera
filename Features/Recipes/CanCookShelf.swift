import SwiftUI
import TesseraCore

/// The CAN COOK shelf at the top of the Recipes front (sheet 104 section 2), behind the Review switch Can cook shelf.
/// The section word in the area lean; one 21 line per recipe, the name leading in ink and its count word at the right
/// ("Ready", "1 short"). Six a page: the page word turns it, the rows crossfade. Below the judged rows, under a
/// hairline, the recipes the pantry knows too little of wait at 55% ink as "2 to check". A row opens its recipe, where
/// Pantry state shows what is short.
struct CanCookShelf: View {
    let shelf: CanCook
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var page = 0

    var body: some View {
        let pages = max(1, Int((Double(shelf.judged.count) / Double(CanCook.pageSize)).rounded(.up)))
        let current = min(page, pages - 1)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Can cook")
                    .textRole(.labelStrong)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Colors.areaLean(.kitchen))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Theme.Spacing.m)
                if pages > 1 {
                    Button {
                        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                            page = (current + 1) % pages
                        }
                    } label: {
                        Text("\(current + 1) of \(pages)")
                            .textRole(.label)
                            .monospacedDigit()
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Page \(current + 1) of \(pages)")
                    .accessibilityHint("Turns to the next page")
                }
            }
            .padding(.bottom, Theme.Spacing.s)
            if shelf.judged.isEmpty {
                Text(CanCook.empty)
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(minHeight: 44, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(shelf.judged.dropFirst(current * CanCook.pageSize).prefix(CanCook.pageSize))) { row in
                        line(row, faint: false)
                    }
                }
                .id(current)
                .transition(.opacity)
            }
            if !shelf.toCheck.isEmpty {
                Hairline()
                    .padding(.vertical, Theme.Spacing.m)
                    .accessibilityHidden(true)
                Text(CanCook.toCheckHeading(shelf.toCheck.count))
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, Theme.Spacing.xs)
                ForEach(shelf.toCheck.prefix(CanCook.pageSize)) { row in
                    line(row, faint: true)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func line(_ row: CanCook.Row, faint: Bool) -> some View {
        NavigationLink(value: row.id) {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
            layout {
                Text(row.name)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if !typeSize.isAccessibilitySize {
                    Spacer(minLength: Theme.Spacing.m)
                }
                if let word = row.word {
                    Text(word)
                        .textRole(.label)
                        .fontWeight(word == "Ready" ? .semibold : .regular)
                        .foregroundStyle(Theme.Colors.ink)
                }
            }
            .opacity(faint ? 0.55 : 1)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.word.map { "\(row.name), \($0)" } ?? "\(row.name), to check")
        .accessibilityHint("Opens the recipe")
    }
}
