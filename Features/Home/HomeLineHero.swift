import SwiftUI
import TesseraCore

/// Home says one plain line per thing (home-first-review.md 41): the time words above, the thing and its state as
/// the hero, and at most one key under it. The words come from Core's HomeLines lens; nothing else about the thing
/// sits on Home, and nothing is ever cut.
struct LineHero<Key: View>: View {
    let line: HomeLine
    /// What a tap on the hero opens.
    var opens: Route?
    /// Words for the context line in place of Core's (nil keeps Core's).
    var context: String??
    @ViewBuilder var key: () -> Key

    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if let context = context ?? line.context {
                // The words shorten when the full line doesn't fit; the type never does.
                ViewThatFits(in: .horizontal) {
                    Text(context).lineLimit(1).fixedSize()
                    Text(line.contextShort ?? context).lineLimit(1).fixedSize()
                    // At large type even the short words wrap rather than cut (QA F2 on #366).
                    Text(line.contextShort ?? context).fixedSize(horizontal: false, vertical: true)
                }
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .contentTransition(.opacity)
                .entrance(1)
            }
            Group {
                if let opens {
                    Button {
                        model.open(opens)
                    } label: {
                        HomeHeroText(text: line.hero)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HandleButtonStyle())
                    .modifier(ZoomSource(id: opens, namespace: namespace))
                    .accessibilityHint("Opens \(line.fact.title)")
                } else {
                    HomeHeroText(text: line.hero)
                }
            }
            .siblingParallax()
            .entrance(2, hero: true)
            key()
                .entrance(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The hero in the first of three forms that fits its width: Hero 56 on one line, Title 44 on one line, Title 44
/// wrapped. Never "…". The fit is read from the measured width and the words (as `HeroText` does), not from layout
/// proposals, which misfire mid-transition.
struct HomeHeroText: View {
    let text: String
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize = Theme.concept.scale.hero.size
    @ScaledMetric(relativeTo: .title) private var titleSize = Theme.concept.scale.title.size
    @State private var width: CGFloat = 0

    private enum Form { case hero, title, wrapped }

    var body: some View {
        Group {
            switch form {
            case .hero:
                Text(text).textRole(.hero).lineLimit(1)
            case .title:
                Text(text).textRole(.title).lineLimit(1)
            case .wrapped:
                Text(text).textRole(.title)
            }
        }
        .foregroundStyle(Theme.Colors.ink)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .accessibilityLabel(text)
    }

    /// An average advance of about 0.56 em for the display face at this weight.
    private var form: Form {
        guard width > 0 else { return .hero }
        if CGFloat(text.count) <= width / (heroSize * 0.56) {
            return .hero
        }
        return CGFloat(text.count) <= width / (titleSize * 0.56) ? .title : .wrapped
    }
}

/// "Thursday night": the only day word on Home, where the painted stroke used to be.
struct DayLabel: View {
    let now: Date

    var body: some View {
        Text(DayLane(offset: 0, date: now, items: []).phrase(now: now))
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            .accessibilityAddTraits(.isHeader)
    }
}
