import SwiftUI

/// A label inside a key that sizes itself to its one-line width (`fixedSize()`): when that line is wider than the
/// page's column, the label takes the column's width and wraps, so it never widens Now and clips the whole column at
/// both edges (AX5, Design on #1143's shot). Shorter than the column, it keeps its own width. The column is read from
/// the page's container (the pager or the AX scroll view), never from the stack the label could widen.
private struct WrapsWithinPage: ViewModifier {
    @State private var natural: CGFloat = 0
    @State private var page: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: WrapsWithinFit.width(natural: natural, column: page - 2 * Theme.Spacing.gutter),
                   alignment: .leading)
            .background(alignment: .leading) {
                content
                    .fixedSize()
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { natural = $0 }
            }
            .background {
                Color.clear
                    .containerRelativeFrame(.horizontal)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { page = $0 }
                    .hidden()
            }
    }
}

enum WrapsWithinFit {
    /// The column's width when the one-line label wouldn't fit in it; nil (its own width) otherwise.
    static func width(natural: CGFloat, column: CGFloat?) -> CGFloat? {
        guard let column, column > 0, natural > column else { return nil }
        return column
    }
}

extension View {
    func wrapsWithinPage() -> some View {
        modifier(WrapsWithinPage())
    }
}
