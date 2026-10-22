import SwiftUI

extension Theme.Typography {
    /// The kicker's type spec (Design item 115): the UI face at 14, semibold, +0.12 em, uppercase. One token, so a new
    /// face swaps here and nowhere else.
    static var kickerSpec: ThemeConcept.TypeSpec {
        var spec = Theme.concept.scale.label
        spec.family = .ui
        spec.size = 14
        spec.weight = .semibold
        spec.tracking = 0.12
        spec.condensed = false
        spec.uppercase = true
        return spec
    }
}

/// The small row above a page's title: ink secondary, no stage colour.
private struct KickerStyle: ViewModifier {
    func body(content: Content) -> some View {
        let spec = Theme.Typography.kickerSpec
        content
            .font(Theme.Typography.font(spec))
            .tracking(spec.tracking * spec.size)
            .textCase(.uppercase)
            .foregroundStyle(Theme.Colors.inkSecondary)
    }
}

extension View {
    func kicker() -> some View {
        modifier(KickerStyle())
    }
}

/// A kicker row with two ends: a word at the left, a phrase at the right. When both don't fit on one line the right
/// drops under the left and wraps; nothing is cut and nothing ends in "…". At accessibility sizes it is always the
/// stacked pair, the left first.
struct KickerRow: View {
    let left: String
    var right: String?

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if let right, !right.isEmpty {
            if typeSize.isAccessibilitySize {
                stacked(right)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                        Text(left).kicker().fixedSize()
                        Spacer(minLength: Theme.Spacing.s)
                        Text(right).kicker().fixedSize()
                    }
                    stacked(right)
                }
            }
        } else {
            Text(left).kicker().fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stacked(_ right: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(left).kicker()
            Text(right).kicker()
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
