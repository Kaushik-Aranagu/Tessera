import SwiftUI
import TesseraCore

// MARK: - The pass (sheet 259, landing contract v2 §2: the Galley keystone)

/// One paper ticket on the pass. Its pages are what a flip shows; a big ticket takes 2.4 shares of the rail.
struct GalleyTicket: Identifiable, Equatable {
    enum Opens: Equatable {
        case recipe(UUID)
        case recipes
        case groceries
        case pantry
    }

    enum Ink: Equatable {
        case dinner, toGet, runsOut, ask
    }

    let id: String
    let title: String
    let sub: String?
    /// Every line, before paging.
    let lines: [String]
    let big: Bool
    let ink: Ink
    let opens: Opens

    /// Lines a page holds in the 182 pt slot (259 v2): about six on a big ticket, three on a small one.
    var perPage: Int {
        big ? 6 : 3
    }

    /// The ticket's pages; always at least one (an empty ticket still has its title).
    var pages: [[String]] {
        guard !lines.isEmpty else { return [[]] }
        return stride(from: 0, to: lines.count, by: perPage).map { Array(lines[$0 ..< min($0 + perPage, lines.count)]) }
    }

    var share: CGFloat {
        big ? 2.4 : 1
    }
}

/// The landing's tickets as data, so the pass has tests: tonight's dinner, To get, what runs out. Walled recipes and
/// items never reach a ticket; they are counted.
struct GalleyPass: Equatable {
    struct Dinner: Equatable {
        let recipe: UUID?
        /// Already "Private recipe" when walled.
        let title: String
        let isPrivate: Bool
        let start: String?
        let ingredients: [String]
    }

    struct Stock: Equatable {
        let name: String
        let state: PantryLedger.State
        let isPrivate: Bool
    }

    var tickets: [GalleyTicket] = []
    var stateLine: [String] = []
    var hidden = 0
    var low: [String] = []
    var toGet: [String] = []
    var cookable: [String] = []

    static let maxTickets = 4

    static func build(dinner: Dinner?, toGet: [String], stock: [Stock], cookable: [String],
                      cooking: String?) -> GalleyPass
    {
        var pass = GalleyPass()
        let openToGet = toGet.filter { $0 != "Private item" }
        let openStock = stock.filter { !$0.isPrivate }
        pass.low = openStock.filter { $0.state == .out || $0.state == .low }.sorted { $0.state < $1.state }.map(\.name)
        pass.toGet = openToGet
        pass.cookable = cookable
        pass.hidden = toGet.count - openToGet.count + stock.count - openStock.count
        if let dinner {
            // A walled dinner keeps its ticket as "Private recipe" and shows nothing of what is in it.
            pass.tickets.append(GalleyTicket(id: "dinner", title: dinner.title, sub: dinner.start.map { "start \($0)" },
                                             lines: dinner.isPrivate ? [] : dinner.ingredients, big: true,
                                             ink: .dinner,
                                             opens: dinner.recipe.map { GalleyTicket.Opens.recipe($0) } ?? .recipes))
        } else {
            pass.tickets.append(GalleyTicket(id: "dinner", title: "Tonight?", sub: "nothing planned yet",
                                             lines: cookable.isEmpty ? [] : ["you could make"] + cookable,
                                             big: !cookable.isEmpty, ink: .ask, opens: .recipes))
        }
        if !openToGet.isEmpty {
            pass.tickets.append(GalleyTicket(id: "toget", title: "To get", sub: "\(openToGet.count) on the list",
                                             lines: openToGet, big: false, ink: .toGet, opens: .groceries))
        }
        if !pass.low.isEmpty {
            pass.tickets.append(GalleyTicket(id: "runsout", title: "Runs out", sub: "first to go", lines: pass.low,
                                             big: false, ink: .runsOut, opens: .pantry))
        }
        pass.tickets = Array(pass.tickets.prefix(maxTickets))
        pass.stateLine = stateLine(dinner: dinner, cooking: cooking, cookable: cookable.count)
        return pass
    }

    /// A cook running: its own line first. Planned: "Tacos tonight, start at 6:05." then shorter. Nothing planned:
    /// "Tonight? Nothing planned yet." (contract §12 empty state).
    static func stateLine(dinner: Dinner?, cooking: String?, cookable: Int) -> [String] {
        var forms: [String] = []
        if let cooking {
            forms.append(cooking)
        }
        if let dinner {
            if let start = dinner.start {
                forms.append("\(dinner.title) tonight, start at \(start)")
            }
            forms.append("\(dinner.title) tonight")
            return forms
        }
        if cookable > 0 {
            forms.append("Tonight? Nothing planned yet, you could make \(cookable)")
        }
        forms.append("Tonight? Nothing planned yet")
        return forms
    }

    /// The update row: "Eggs and milk run out first." / "Eggs runs out first." Nothing low: nil.
    var lowLine: [LandingBrief.Form]? {
        guard let first = low.first else { return nil }
        if low.count >= 2 {
            let pair = "\(low[0]) and \(low[1])"
            return [LandingBrief.Form(text: "\(pair) run out first", key: pair),
                    LandingBrief.Form(text: "\(first) runs out first", key: first)]
        }
        return [LandingBrief.Form(text: "\(first) runs out first", key: first)]
    }
}

/// The rail: a 1 pt line across the top of the slot, the tickets hung from it in shares (big 2.4, others 1). Swipe up
/// on a ticket flips it over its clip to the next page, down flips back; a tap opens its thing.
struct GalleyRail: View {
    let tickets: [GalleyTicket]
    var open: (GalleyTicket.Opens) -> Void

    static let gap: CGFloat = 8
    static let railY: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let shares = tickets.reduce(0) { $0 + $1.share }
            let room = proxy.size.width - Self.gap * CGFloat(max(tickets.count - 1, 0))
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Theme.Colors.inkSecondary.opacity(0.6))
                    .frame(height: 1)
                    .offset(y: Self.railY)
                    .accessibilityHidden(true)
                HStack(alignment: .top, spacing: Self.gap) {
                    ForEach(tickets) { ticket in
                        GalleyTicketView(ticket: ticket, open: open)
                            .frame(width: room * ticket.share / max(shares, 1), height: proxy.size.height - Self.railY)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .top)))
                    }
                }
                .offset(y: Self.railY - 3)
            }
            .tesseraAnimation(Theme.Motion.house, value: tickets.map(\.id))
        }
    }
}

/// One ticket: a clip at the top, paper with a torn foot, the title in the thing's colour in the kitchen hand, a sub
/// line, the page's lines, and "over" when there is a next page. Swipe up flips to the next page, down flips back.
struct GalleyTicketView: View {
    let ticket: GalleyTicket
    var open: (GalleyTicket.Opens) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var page = 0
    @State private var turn: Double = 0
    @State private var cue = HapticCue()

    private var dark: Bool {
        scheme == .dark
    }

    private var paper: Color {
        dark ? Color(hex: 0x2B2722) : Color(hex: 0xF6EFDF)
    }

    private var titleColor: Color {
        switch ticket.ink {
        case .dinner: dark ? Color(hex: 0xE2A07F) : Color(hex: 0x9C4B2C)
        case .toGet: dark ? Color(hex: 0xB5BE7A) : Color(hex: 0x5E6B1F)
        case .runsOut: dark ? Color(hex: 0xEE8E9C) : Color(hex: 0x9A2541)
        case .ask: LandingAccent.kitchen
        }
    }

    var body: some View {
        let pages = ticket.pages
        let shown = pages[min(page, pages.count - 1)]
        VStack(alignment: .leading, spacing: 0) {
            Text(ticket.title.uppercased())
                .font(.custom("IBMPlexSansCond-Bold", fixedSize: 13))
                .tracking(13 * 0.08)
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let sub = ticket.sub {
                Text(sub.uppercased())
                    .font(.custom("IBMPlexSansCond-Medium", fixedSize: 10.5))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            ForEach(Array(shown.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.custom("IBMPlexSansCond-Regular", fixedSize: 12.5))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            if pages.count > 1 {
                Text(page < pages.count - 1 ? "over" : "back")
                    .font(.custom("IBMPlexSansCond-Regular", fixedSize: 12.5))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { TornPaper().fill(paper) }
        .overlay(alignment: .top) { clip }
        .rotation3DEffect(.degrees(turn), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.4)
        .contentShape(Rectangle())
        .onTapGesture { open(ticket.opens) }
        .gesture(DragGesture(minimumDistance: 10).onEnded { value in
            guard abs(value.translation.height) > abs(value.translation.width), abs(value.translation.height) > 40
            else { return }
            flip(value.translation.height < 0 ? 1 : -1)
        })
        .tesseraFeedback(cue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(([ticket.title, ticket.sub].compactMap(\.self) + shown).joined(separator: ", "))
        .accessibilityHint("Opens it")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open(ticket.opens) }
        .accessibilityAdjustableAction { direction in flip(direction == .increment ? 1 : -1) }
        .onChange(of: ticket.lines) { _, _ in page = min(page, max(ticket.pages.count - 1, 0)) }
    }

    /// The clip the ticket hangs from: a short ink stroke over the rail.
    private var clip: some View {
        Rectangle()
            .fill(Theme.Colors.inkSecondary)
            .frame(width: 18, height: 6)
            .offset(y: -3)
            .accessibilityHidden(true)
    }

    /// Over the clip to the next page (rotate to edge-on, swap the page, come back round), or back. At either end the
    /// ticket only nods. Reduce Motion swaps the page in place.
    private func flip(_ step: Int) {
        let pages = ticket.pages.count
        let next = page + step
        guard next >= 0, next < pages else {
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { turn = step > 0 ? -8 : 8 }
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { turn = 0 }
            return
        }
        cue.play(.selection)
        if reduceMotion {
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: true) { page = next }
            return
        }
        Task { @MainActor in
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { turn = step > 0 ? -90 : 90 }
            try? await Task.sleep(for: .milliseconds(220))
            page = next
            turn = step > 0 ? 90 : -90
            withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { turn = 0 }
        }
    }
}

/// Paper with a torn foot: straight sides and top, a small irregular zigzag along the bottom.
struct TornPaper: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
        let teeth = max(Int(rect.width / 9), 4)
        let step = rect.width / CGFloat(teeth)
        let depths: [CGFloat] = [4, 1, 3, 0, 4, 2, 1, 3]
        for index in (0 ..< teeth).reversed() {
            let x = rect.minX + step * CGFloat(index)
            path.addLine(to: CGPoint(x: x + step / 2, y: rect.maxY - depths[index % depths.count]))
            path.addLine(to: CGPoint(x: x, y: rect.maxY - 4))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - The page

/// The Galley's landing (landing contract v2: hub 282, sheet 259): the sentence at 106, the pass in the keystone slot,
/// its caption at 390, one update row at 424, the doors at 540, "Cook" (or "Plan tonight") at the foot.
struct KitchenLandingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openHomeLink) private var open
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var cookCover: KitchenCookCover?
    @State private var recipe: KitchenCookCover?
    @State private var focus = 0
    @State private var switcherIndex = 0
    @State private var switcherVerticalIndex = 0
    @State private var widgetIndex = 0

    static let switcher = GalleyRoomContent.switcher

    var body: some View {
        let _ = model.revision
        let front = KitchenFront(model: model, now: AppClock.now)
        // One source with the standing shell: the facts and words come from GalleyRoomContent.
        let facts = GalleyRoomContent.Facts.load(model: model, scheme: scheme, front: front)
        let pass = facts.pass
        LandingScaffold(title: "Galley", accent: LandingAccent.kitchen, navWord: "Bridge", onBack: { dismiss() },
                        switcher: Self.switcher, switcherIndex: $switcherIndex,
                        switcherVerticalIndex: $switcherVerticalIndex,
                        needs: facts.needs.indices.contains(switcherIndex) ? facts.needs[switcherIndex] : [],
                        keystone: {
                            LandingKeystone(label: "The pass") {
                                GalleyRail(tickets: pass.tickets) { opens in go(opens) }
                            }
                        },
                        caption: facts.caption.map { [$0] } ?? [],
                        widget: facts.widget, widgetIndex: $widgetIndex,
                        openWidget: { item in
                            switch item.id {
                            case "cooking": cookCover = front.cooking.map { KitchenCookCover(id: $0.id) }
                            case "dinner": go(front.tonight?.recipe.map { GalleyTicket.Opens.recipe($0) } ?? .recipes)
                            case "toget": open(.groceries)
                            case "runsout": open(.pantry)
                            default: open(.recipes)
                            }
                        },
                        glyph: { item in LandingGlyph(
                            item: item,
                            color: item.bigColor ?? LandingAccent.kitchen,
                            room: .galley
                        ) },
                        doors: facts.doors, focus: $focus,
                        openDoor: { door in
                            switch door.id {
                            case "tonight": go(front.tonight?.recipe.map { GalleyTicket.Opens.recipe($0) } ?? .recipes)
                            case "pantry", "leftovers": open(.pantry)
                            case "groceries": open(.groceries)
                            default: open(.recipes)
                            }
                        },
                        action: action(front, facts))
            .environment(\.doorSummaryStyle, .ticket)
            .overlay { KeystoneHandover(kind: .galleyTicket, from: Self.firstTicketCentre(pass.tickets)) }
            .toolbar(.hidden, for: .navigationBar)
            // A cover hides the landing: its live drawing waits (sheet 286, live only when seen).
            .liveScope(cookCover == nil && recipe == nil)
            .fullScreenCover(item: $cookCover) { CookClockPage(cookID: $0.id) }
            .fullScreenCover(item: $recipe) { RecipeView(recipeID: $0.id) }
    }

    /// Where the first ticket (tonight's) hangs, in design points, so the handover tears that one off.
    static func firstTicketCentre(_ tickets: [GalleyTicket]) -> CGPoint {
        let shares = tickets.reduce(0) { $0 + $1.share }
        let room = 354 - GalleyRail.gap * CGFloat(max(tickets.count - 1, 0))
        let width = room * (tickets.first?.share ?? 1) / max(shares, 1)
        return CGPoint(x: 24 + width / 2, y: 196 + 70)
    }

    private func go(_ opens: GalleyTicket.Opens) {
        switch opens {
        case let .recipe(id): recipe = .init(id: id)
        case .recipes: open(.recipes)
        case .groceries: open(.groceries)
        case .pantry: open(.pantry)
        }
    }

    /// Each door's meaning colour (241); the rule lives with the room's content.
    typealias DoorTone = GalleyRoomContent.DoorTone

    static func tone(door id: String, lowEmpty: Bool) -> DoorTone {
        GalleyRoomContent.tone(door: id, lowEmpty: lowEmpty)
    }

    /// The foot (283 v3): a verb over its object. Cook (tonight's dish), swipe across for Get (To get). There is no
    /// Dishes model yet, so no Wash. With nothing planned, Cook opens Recipes to pick tonight's dish.
    private func action(_ front: KitchenFront, _ facts: GalleyRoomContent.Facts) -> LandingFootAction {
        let get = LandingFootAction.Step(verb: "Get", object: "To get") { open(.groceries) }
        return LandingFootAction(word: "Cook", object: facts.cookObject, hint: facts.cookHint, alternates: [get]) {
            if let meal = front.tonight {
                cook(meal)
            } else {
                open(.recipes)
            }
        }
    }

    /// Cook: tonight's recipe starts at its size and its clock opens (the same as Cook on the recipe page).
    private func cook(_ meal: KitchenFront.Meal) {
        guard let recipe = meal.recipe else {
            open(.recipes)
            return
        }
        guard let cook = try? model.engine.perform(StartCooking(recipe: recipe, time: AppClock.now), by: .user).output
        else {
            TessVoice.shared.say("Didn't start that. Try again")
            return
        }
        model.touch()
        cookCover = .init(id: cook.id)
    }
}

struct KitchenCookCover: Identifiable {
    let id: UUID
}

#if DEBUG
    /// `-kitchen`: the Galley landing on its own, with its doors opening as Home would open them.
    struct KitchenLandingHost: View {
        @State private var link: HomeLink?

        var body: some View {
            KitchenLandingPage()
                .environment(\.openHomeLink) { link = $0 }
                .liveScope(link == nil)
                .fullScreenCover(item: $link) { $0.destination }
        }
    }
#endif
