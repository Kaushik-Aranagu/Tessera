import SwiftUI
import TesseraCore

/// Home as a mosaic (sheet 199, Builder B's part): the date and a Settings word, three right-aligned lines about the
/// day, the mosaic with its caption, then Next. Nothing else: no write line, mic, widgets, ring or bars. Used in
/// place of Home when Settings › Review › "Mosaic" is On.
///
/// Bridge's state and behaviour live in `BridgeStage`; its parts are `BridgeBoard`, `BridgeMosaicCore`,
/// `BridgeOneThing`, `BridgeApps`, `BridgeSettingsWord`, the `BridgeField` behind them and `BridgeTess` above, so
/// the standing shell (sheet 283 v5) can draw the same Bridge place by place. This page draws them as it always did.
struct HomeMosaicPage: View {
    /// The page's own coordinate space, so a finished row's frame can be handed to the mosaic. The standing shell
    /// names its root the same, so the mosaic's shields and core read the same points there.
    static let space = "homeMosaicPage"

    @Environment(AppModel.self) private var model
    @State private var stage = BridgeStage()

    var body: some View {
        // Sheet 283 v4 places: Bridge is laid out at the sheet's fixed coordinates, no ScrollView. The departure board
        // in the masthead, the mosaic in the keystone band, the one-thing box in the widget place (24, 412, 354 x 200),
        // the dial in the doors place (24, 640, 160 x 120) with its fact at x 186; Tess has the foot.
        GeometryReader { proxy in
            let rise = max(0.86, min(1.1, proxy.size.height / 874))
            ZStack(alignment: .topLeading) {
                BridgeBoard(stage: stage)
                    .padding(.leading, BridgePlace.board.minX)
                    .padding(.top, BridgePlace.board.minY * rise)
                BridgeMosaicCore(stage: stage)
                    .padding(.leading, BridgePlace.keystone.minX)
                    .padding(.top, BridgePlace.keystone.minY * rise)
                BridgeOneThing(stage: stage)
                    .padding(.leading, BridgePlace.widget.minX)
                    .padding(.top, BridgePlace.widget.minY * rise)
                BridgeApps(stage: stage)
                    .padding(.leading, BridgePlace.doors.minX)
                    .padding(.top, BridgePlace.doors.minY * rise)
            }
            // Bridge's sections are fixed places: their type stops growing at AX2 and every line cuts on whole words.
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .coordinateSpace(.named(Self.space))
        }
        .overlay(alignment: .topLeading) {
            BridgeSettingsWord(stage: stage)
                .padding(.leading, BridgePlace.settings.minX)
                .padding(.top, BridgePlace.settings.minY)
        }
        .ignoresSafeArea(.container, edges: .vertical)
        // Sheet 202: the mosaic is the page's own pixels, edge to edge, behind everything; every touch leans it.
        .background { BridgeField(stage: stage) }
        .modifier(BridgeLife(stage: stage))
        // Sheet 209 and 215: Tess on her own layer above all of Home; touches pass through except on her.
        .overlay { BridgeTess(stage: stage) }
        .modifier(BridgeDoors(stage: stage))
    }

    /// Settings sits on row 1's baseline (the date): the date row is 30 pt at Figtree 23 under a 16 pt top pad, and the
    /// word is Figtree 16 centred in a 44 pt target, so the offset is the difference of the two baselines.
    static let settingsTop: CGFloat = {
        func face(_ size: CGFloat) -> UIFont {
            UIFont(descriptor: UIFontDescriptor(fontAttributes: [.family: "Figtree"]), size: size)
        }
        let big = face(DepartureBoard.size), small = face(16)
        let row = 16 + (DepartureBoard.rowHeight - big.lineHeight) / 2 + big.ascender
        let word = (44 - small.lineHeight) / 2 + small.ascender
        return max(row - word, 0)
    }()
}

/// The scroll offset, in an object so only the views that read `value` redraw when it changes.
@MainActor
@Observable
final class HomeScrollOffset {
    var value: CGFloat = 0
}

/// A's layer with the shields moved by the scroll: the words move with the page, so their rectangles do too. Reading
/// the offset here keeps the page itself from redrawing on every scroll frame.
struct HomeLayerHost: View {
    let scroll: HomeScrollOffset
    let scrollMinY: CGFloat
    let facts: MosaicFacts
    @Binding var scene: MosaicScene
    let controller: MosaicScreenController
    let coreTop: CGFloat
    let shield: [CGRect]
    let mood: MosaicMood
    let moment: MosaicMomentEvent?
    @Binding var caption: String
    var page: MosaicPage = .mood
    var pageDirection = 1
    var signSpec: MosaicSignSpec?
    var scenery: MosaicScenery?
    var dusk = false
    var faceModel: MosaicFaceModel?

    var body: some View {
        MosaicHomeLayer(
            facts: facts,
            scene: $scene,
            controller: controller,
            coreTop: coreTop,
            // Content origin is the scroll view's top less its offset.
            shield: shield.map { $0.offsetBy(dx: 0, dy: scrollMinY - scroll.value) },
            mood: mood,
            moment: moment,
            caption: $caption,
            page: page,
            pageDirection: pageDirection,
            signSpec: signSpec,
            scenery: scenery,
            dusk: dusk,
            faceModel: faceModel
        )
    }
}

/// Bridge's places from sheet 283 v4 (`LandingPlace`), as frames.
enum BridgePlace {
    static let board = LandingPlace.Masthead.departureBoard
    static let settings = LandingPlace.Masthead.settingsWord
    static let keystone = LandingPlace.keystone.frame
    static let widget = LandingPlace.widget.frame
    static let doors = LandingPlace.doors.frame
    /// The 160 pt mosaic core centred in the 182 pt keystone band.
    static let coreTop = keystone.minY + (keystone.height - HomeMosaic.moodsMosaicSize.height) / 2
}
