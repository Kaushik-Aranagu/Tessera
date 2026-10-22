import SwiftUI
import TesseraCore

/// Home v2 (sheet 137, Kaushik's pick Oct 22): one page, no sideways pager. The date with Review as a door word, Now
/// while something runs, the day's line, Next, and the app edges along the bottom: six thin strokes in their apps'
/// resting colours, a tap opening the nearest app. Behind Settings › Review › "Home v2" (default Off: Home as today).
/// The fan (pull up the edges) and the swipe across apps are Builder A's motion and join later.
enum HomeV2 {
    static let choiceID = "homeV2"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

/// What the edges and the Review word open, each as its own full-screen page with Close.
enum HomeV2Door: Identifiable, Hashable {
    case review
    case app(HomeApp)

    var id: String {
        switch self {
        case .review: "review"
        case let .app(app): app.rawValue
        }
    }
}

struct HomeV2View: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var door: HomeV2Door?
    @State private var link: HomeLink?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                // Today's page as it is: the day word, Now, the day's line and Next (queue swipes, Undo and the
                // plan all kept). REVIEW is a door word on the day's line now; the day stroke lives on its page.
                NowPage()
                    .overlay(alignment: .topTrailing) {
                        Button("Review") { door = .review }
                            .buttonStyle(LandingWordStyle())
                            .accessibilityHint("Opens your day and week")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.Spacing.gutter)
                    .padding(.top, Theme.Spacing.s)
            }
            .scrollIndicators(.hidden)
            // At default sizes it fits one screen; it scrolls only when type needs it (137 §1).
            .scrollDisabled(!typeSize.isAccessibilitySize)

            AppEdges { door = .app($0) }
                .padding(.bottom, HomeSpatialView.dockClearance)
        }
        .environment(\.openHomeLink) { link = $0 }
        .fullScreenCover(item: $door) { door in
            HomeV2DoorPage(door: door)
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Close") { self.door = nil }
                            .buttonStyle(InkLabelWordStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.gutter - 8)
                }
        }
        .fullScreenCover(item: $link) { link in
            link.destination
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Close") { self.link = nil }
                            .buttonStyle(InkLabelWordStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.gutter - 8)
                }
        }
    }
}

/// The page a door opens: Review's page, or an app's landing (or its page where the landing isn't built yet).
private struct HomeV2DoorPage: View {
    let door: HomeV2Door
    @State private var link: HomeLink?

    var body: some View {
        Group {
            switch door {
            case .review:
                ScrollView { ReviewPage().padding(.horizontal, Theme.Spacing.gutter) }
            case .app(.training):
                ScrollView { TrainingPage().padding(.horizontal, Theme.Spacing.gutter) }
            case .app(.kitchen):
                ScrollView {
                    KitchenLandingPage()
                        .padding(.horizontal, Theme.Spacing.gutter)
                        .padding(.top, Theme.Spacing.m)
                }
            case .app(.money): MoneyLandingView()
            case .app(.notes): NotesView()
            case .app(.lists): ListsView()
            case .app(.routines):
                // Routines' landing is Builder A's (sheet 131 L4); until then its plans.
                ScrollView { TrainingPage().padding(.horizontal, Theme.Spacing.gutter) }
            }
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .environment(\.openHomeLink) { link = $0 }
        .fullScreenCover(item: $link) { link in
            link.destination
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Close") { self.link = nil }
                            .buttonStyle(InkLabelWordStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.gutter - 8)
                }
        }
    }
}

/// The app edges (137 §2): six 3 pt strokes, 3 pt apart, edge to edge, in app order, each in its app's resting
/// colour. One 44 pt hit area for the group; a tap opens the app whose stroke is nearest. Nothing about an app's
/// contents shows on its stroke. VoiceOver reads one element, "Apps", whose actions open each app.
struct AppEdges: View {
    let open: (HomeApp) -> Void

    static let order: [HomeApp] = [.training, .kitchen, .money, .notes, .lists, .routines]
    static let stroke: CGFloat = 3
    static let gap: CGFloat = 3

    private var height: CGFloat {
        CGFloat(Self.order.count) * Self.stroke + CGFloat(Self.order.count - 1) * Self.gap
    }

    var body: some View {
        VStack(spacing: Self.gap) {
            ForEach(Self.order, id: \.self) { app in
                Rectangle()
                    .fill(Theme.Colors.restTint(app.accent))
                    .frame(height: Self.stroke)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: max(44, height), alignment: .bottom)
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { point in
            open(Self.nearest(to: point.y, in: max(44, height), strokes: height))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Apps")
        .accessibilityAddTraits(.isButton)
        .accessibilityActions {
            ForEach(Self.order, id: \.self) { app in
                Button(app.rawValue) { open(app) }
            }
        }
    }

    /// The stroke nearest a touch at `y` in a hit area `area` tall whose strokes fill its bottom `strokes` points.
    static func nearest(to y: CGFloat, in area: CGFloat, strokes: CGFloat) -> HomeApp {
        let top = area - strokes
        let pitch = stroke + gap
        let index = Int(((y - top) / pitch).rounded(.down))
        return order[min(max(index, 0), order.count - 1)]
    }
}
