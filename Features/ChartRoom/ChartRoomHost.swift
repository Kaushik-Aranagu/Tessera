import SwiftUI
import TesseraCore

// The Chart room in the standing shell (R1 spec section 6), behind the `chartRoom` feature flag (Everywhere, ships
// On). The room is experimental: everything stays behind the flag, and Builder B's pages are untouched.

enum ChartRoomFlag {
    static let id = "chartRoom"

    /// On unless he turned it Off in Developer mode; a unit-test host and a demo keep it On (the room is the same).
    static var isOn: Bool {
        guard FeatureFlagStore.usesFlags else { return true }
        return FeatureFlagStore.isOn(id) ?? true
    }
}

extension ChartRoomModel {
    /// The one live model: kept on this iPhone (`chartRoom.document`), and `-resetChart` on the simulator starts blank.
    static func live() -> ChartRoomModel {
        let defaults = UserDefaults.standard
        if LaunchFlags.has("-resetChart") {
            defaults.removeObject(forKey: defaultsKey)
            defaults.removeObject(forKey: cursorKey)
        }
        return ChartRoomModel(defaults: defaults)
    }
}

/// The Chart room as the root shell holds it beside Bridge.
@MainActor
@Observable
final class ChartRoomDriver: ShellRoomDriver {
    let room = DocumentRoom.room
    let tessRoom: AppID? = nil
    let flip = KeystoneFlip.rows
    let glyphRoom: GlyphKind.Room? = nil
    var accent: Color {
        Theme.Colors.Accent.chart
    }

    /// Made on first use, so the drivers the shell builds and drops never reset a built room.
    @ObservationIgnored private(set) lazy var chart = ChartRoomModel.live()

    func content(model: AppModel, scheme _: ColorScheme) -> any RoomContent {
        chart.attach(model.engine)
        return DocumentRoom(nodes: chart.nodes, ghost: chart.ghostPlaces, accent: accent)
    }

    func handle(_ intent: ShellIntent, navigator _: ShellNavigator) -> Bool {
        switch intent {
        case .back: return false
        case let .action(id): run(id, chart)
        default: break
        }
        return true
    }

    func overlay(navigator _: ShellNavigator) -> AnyView {
        AnyView(ChartRoomLayer(model: chart))
    }
}

/// What the action word's steps do.
@MainActor
func run(_ step: String, _ chart: ChartRoomModel) {
    if step == "say" {
        chart.saySomething()
    } else if step.hasPrefix("does:") {
        chart.does(String(step.dropFirst(5)))
    }
}

/// The Chart room opened on its own (`-shellRoom chart` on the simulator): the same shell and layer as the root's.
struct ChartShellHost: View {
    @Environment(AppModel.self) private var app
    @State private var navigator = ShellNavigator(root: .landing(DocumentRoom.room))
    @State private var chart = ChartRoomModel.live()

    var body: some View {
        let _ = app.revision
        let _ = chart.attach(app.engine)
        ShellView(room: DocumentRoom(nodes: chart.nodes, ghost: chart.ghostPlaces), navigator: navigator,
                  accent: Theme.Colors.Accent.chart)
        { intent in
            switch intent {
            case .back: navigator.pop()
            case let .action(id): run(id, chart)
            default: break
            }
        }
        .overlay { ChartRoomLayer(model: chart) }
    }
}
