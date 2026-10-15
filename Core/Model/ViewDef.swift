import Foundation
import SwiftData

/// A saved presentation of a class's objects (list, board, calendar…).
@Model
final class ViewDef {
    enum Layout: String, Codable, CaseIterable {
        case list, board, calendar, gallery
    }

    var id: UUID = UUID()
    var name: String = ""
    var layoutRaw: String = Layout.list.rawValue
    var sortIndex: Int = 0
    var filterData: Data?
    var classDef: ClassDef?

    init(name: String = "", layout: Layout = .list) {
        self.name = name
        layoutRaw = layout.rawValue
    }

    var layout: Layout {
        get { Layout(rawValue: layoutRaw) ?? .list }
        set { layoutRaw = newValue.rawValue }
    }
}
