import SwiftUI
import TesseraCore

extension EnvironmentValues {
    /// Namespace shared by zoom sources (rows, handles) and zoom destinations (object pages, workout mode).
    @Entry var zoomNamespace: Namespace.ID?
}

/// An inline name that is also a door (dotted underline). Use `ObjectRow` for whole rows.
struct ObjectHandle: View {
    let title: String
    let route: Route
    var relation: AppModel.Relation = .deeper
    var role: TextRole = .body
    var color: Color = Theme.Colors.ink
    var underline: Color = Theme.Colors.inkTertiary

    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        Button {
            model.open(route, relation)
        } label: {
            Text(title)
                .textRole(role)
                .foregroundStyle(color)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) { DottedRule(color: underline) }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .modifier(ZoomSource(id: route, namespace: relation == .deeper ? namespace : nil))
        // The hint never repeats the name VoiceOver just read (OL19).
        .accessibilityHint("Opens the page")
    }
}

/// A whole-row door (≥ 44 pt): dotted-underlined name on the left, right-aligned mono metadata and a "→".
/// The page zooms out of this row.
struct ObjectRow<Trailing: View>: View {
    let title: String
    let route: Route
    var role: TextRole = .body
    var color: Color = Theme.Colors.ink
    var underline: Color = Theme.Colors.inkTertiary
    var showsArrow = true
    @ViewBuilder var trailing: Trailing

    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        Button {
            model.open(route, .deeper)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Text(title)
                    .textRole(role)
                    .foregroundStyle(color)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 4)
                    .overlay(alignment: .bottom) { DottedRule(color: underline) }
                Spacer(minLength: Theme.Spacing.s)
                trailing
                if showsArrow {
                    // The arrow is drawing, not words: VoiceOver skips it (OL21).
                    Text("→").textRole(.label).foregroundStyle(Theme.Colors.inkTertiary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, Theme.Spacing.m)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .modifier(ZoomSource(id: route, namespace: namespace))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the page")
    }
}

extension ObjectRow where Trailing == EmptyView {
    init(title: String, route: Route, role: TextRole = .body, color: Color = Theme.Colors.ink) {
        self.init(title: title, route: route, role: role, color: color) { EmptyView() }
    }

    /// A row for an object takes the object, so its name is always the one shown title (OL20).
    @MainActor
    init(object: ObjectRecord, in model: AppModel) {
        self.init(title: ObjectTitle.shown(object, in: model.store, classes: model.classes), route: .object(object.id))
    }
}

extension ObjectRow {
    /// A row for an object, with trailing metadata (OL20).
    @MainActor
    init(object: ObjectRecord, in model: AppModel, @ViewBuilder trailing: () -> Trailing) {
        self.init(title: ObjectTitle.shown(object, in: model.store, classes: model.classes), route: .object(object.id),
                  trailing: trailing)
    }
}

extension ObjectHandle {
    /// An inline handle for an object takes the object, so its name is always the one shown title (OL20).
    @MainActor
    init(object: ObjectRecord, in model: AppModel) {
        self.init(title: ObjectTitle.shown(object, in: model.store, classes: model.classes), route: .object(object.id))
    }
}

struct DottedRule: View {
    let color: Color
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: 0, y: proxy.size.height / 2))
                path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [0.1, 4]))
        }
        .frame(height: 2)
    }
}

struct HandleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .animation(Theme.Motion.snappy, value: configuration.isPressed)
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.Motion.snappy, value: configuration.isPressed)
    }
}

struct ZoomSource<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

/// Picks how a page arrives at runtime: zoom out of its source row, or an iOS 27 cross-fade.
/// Reduce Motion always cross-fades.
struct ArrivalTransition<ID: Hashable>: ViewModifier {
    let id: ID
    let arrival: AppModel.Arrival
    let namespace: Namespace.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.navigationTransition(transition)
    }

    private var transition: AnyNavigationTransition {
        if arrival == .zoom, !reduceMotion, let namespace {
            AnyNavigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            AnyNavigationTransition(.crossFade)
        }
    }
}
