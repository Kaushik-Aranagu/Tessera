import SwiftUI

// MARK: - Text roles

/// The four sizes of the active concept (plus numbers set at those sizes in the mono face).
enum TextRole {
    case hero, heroNumber, title, titleNumber, body, bodyStrong, label, labelStrong
    /// Label size and face, case preserved: times, numbers, units, class lines, paths in code.
    case data
}

private struct TextRoleModifier: ViewModifier {
    let role: TextRole

    func body(content: Content) -> some View {
        let scale = Theme.concept.scale
        let spec: ThemeConcept.TypeSpec = switch role {
        case .hero, .heroNumber: scale.hero
        case .title, .titleNumber: scale.title
        case .body, .bodyStrong: scale.body
        case .label, .labelStrong, .data: scale.label
        }
        let font: Font = switch role {
        case .heroNumber: Theme.Typography.number(spec, weight: scale.heroNumberWeight)
        case .titleNumber: Theme.Typography.number(spec, weight: .regular)
        case .bodyStrong: Theme.Typography.font(spec, weight: .medium)
        case .labelStrong: Theme.Typography.font(spec, weight: .bold)
        default: Theme.Typography.font(spec)
        }
        let isNumber = role == .heroNumber || role == .titleNumber || role == .data
        return content
            .font(font)
            .tracking(spec.tracking * spec.size)
            .lineHeight(.multiple(factor: spec.lineHeight))
            .textCase(spec.uppercase && !isNumber ? .uppercase : nil)
            // The hero is capped around 80 pt.
            .dynamicTypeSize(role == .hero ? ...DynamicTypeSize.xxxLarge : ...DynamicTypeSize.accessibility5)
    }
}

extension View {
    func textRole(_ role: TextRole) -> some View {
        modifier(TextRoleModifier(role: role))
    }
}

// MARK: - Entrance

extension EnvironmentValues {
    /// True on a page's first visit this session; revisits and back-navigation appear instantly.
    @Entry var animateEntrance = false
}

/// First visit only: the first few elements enter in reading order — 25 ms stagger, ~14 pt rise,
/// `.smooth(0.28)`, blur 4 → 0 on the hero only. Never blocks taps. Reduce Motion: opacity only.
private struct EntranceModifier: ViewModifier {
    let order: Int
    let hero: Bool
    @Environment(\.animateEntrance) private var animate
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        let active = animate && order < 6
        let hidden = active && !shown
        content
            .opacity(hidden ? 0 : 1)
            .blur(radius: hidden && hero && !reduceMotion ? 4 : 0)
            .offset(y: hidden && !reduceMotion ? 14 : 0)
            .task {
                guard active else { return }
                // Start after the first frame is on screen, so a busy first frame can't swallow the animation.
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(reduceMotion ? .easeOut(duration: 0.15)
                    : .smooth(duration: 0.28).delay(Double(order) * Theme.Motion.stagger)) { shown = true }
            }
    }
}

extension View {
    func entrance(_ order: Int, hero: Bool = false) -> some View {
        modifier(EntranceModifier(order: order, hero: hero))
    }
}

// MARK: - Vertical margin labels

/// Sets a label rotated 90° in the left margin beside its content — the editorial attention device.
struct MarginSection<Content: View>: View {
    let label: String
    var color: Color = Theme.Colors.inkSecondary
    @ViewBuilder var content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                // One symmetric column; the label turns horizontal.
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Eyebrow(text: label, color: color).accessibilityAddTraits(.isHeader)
                    content
                }
            } else {
                HStack(alignment: .top, spacing: Theme.Spacing.m) {
                    VerticalLabel(text: label, color: color)
                    content.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct VerticalLabel: View {
    let text: String
    var color: Color = Theme.Colors.inkSecondary

    var body: some View {
        Rotated90 {
            Text(text.uppercased())
                .textRole(.label)
                .tracking(2)
                .foregroundStyle(color)
                .fixedSize()
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// Lays out its child rotated −90° (reads bottom-to-top), swapping width and height, top-aligned.
private struct Rotated90<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        RotatedLayout { content.rotationEffect(.degrees(-90)) }
    }
}

private struct RotatedLayout: Layout {
    func sizeThatFits(proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        guard let size = subviews.first?.sizeThatFits(.unspecified) else { return .zero }
        return CGSize(width: size.height, height: size.width)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        guard let subview = subviews.first else { return }
        let size = subview.sizeThatFits(.unspecified)
        subview.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: ProposedViewSize(size))
    }
}

// MARK: - Hero text

/// The screen's one hero: the object's NAME only. Long names step down in width (100 → 85 → 75%) at the same
/// size, then demote to the Title style (never an in-between size); last resort is tail truncation, with the
/// full name kept in the accessibility label.
///
/// The fit is decided from the measured width and the words themselves — not from layout proposals, which are
/// unreliable mid-transition (a `ViewThatFits` here picked the wrong candidate while rows were animating).
struct HeroText<Rendered: View>: View {
    let text: String
    /// Applies per-glyph effects to the chosen candidate.
    var render: (Text) -> Rendered
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize = Theme.concept.scale.hero.size
    @State private var width: CGFloat = 0

    private enum Fit: Equatable { case hero(Font.Width), title }

    var body: some View {
        Group {
            switch fit {
            case let .hero(fontWidth):
                render(Text(text))
                    .textRole(.hero)
                    .fontWidth(fontWidth)
                    .allowsTightening(true)
                    .lineLimit(3)
            case .title:
                render(Text(text))
                    .textRole(.title)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .accessibilityLabel(text)
    }

    /// Estimates lines per candidate from an average advance of ~0.56 em (display faces at this weight).
    private var fit: Fit {
        guard width > 0 else { return .hero(.standard) }
        let words = text.split(separator: " ").map(\.count)
        let longest = words.max() ?? 0
        for (fontWidth, factor) in [(Font.Width.standard, 1.0), (.condensed, 0.85), (.compressed, 0.75)] {
            let perLine = Int(width / (heroSize * 0.56 * factor))
            guard longest <= perLine else { continue }
            var lines = 1, used = 0
            for word in words {
                let needed = used == 0 ? word : used + 1 + word
                if needed > perLine {
                    lines += 1; used = word
                } else {
                    used = needed
                }
            }
            if lines <= 3 {
                return .hero(fontWidth)
            }
        }
        return .title
    }
}
