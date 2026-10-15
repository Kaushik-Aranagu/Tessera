import Foundation
import SwiftData

/// A saved presentation of a class's objects (list, board, calendar…).
@Model
public final class ViewDef {
    public enum Layout: String, Codable, CaseIterable, Sendable {
        case list, board, calendar, gallery
    }

    public var id: UUID = UUID()
    public var name: String = ""
    public var layoutRaw: String = Layout.list.rawValue
    public var sortIndex: Int = 0
    public var filterData: Data?
    public var classDef: ClassDef?

    public init(name: String = "", layout: Layout = .list) {
        id = .v7()
        self.name = name
        layoutRaw = layout.rawValue
    }

    public var layout: Layout {
        get { Layout(rawValue: layoutRaw) ?? .list }
        set { layoutRaw = newValue.rawValue }
    }
}
