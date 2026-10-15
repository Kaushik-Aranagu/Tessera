import Foundation
@testable import Pilot
import SwiftData
import Testing

@MainActor
struct ModelTests {
    @Test func insertAppTypeWithFieldsAndRecords() throws {
        let container = PilotSchema.makeContainer(inMemory: true)
        let context = container.mainContext

        let type = AppType(name: "Workout", symbolName: "figure.run")
        context.insert(type)
        type.fields?.append(FieldDef(name: "Minutes", kind: .number))
        type.records?.append(Record(title: "Morning run"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<AppType>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.fields?.first?.kind == .number)
        #expect(fetched.first?.records?.first?.title == "Morning run")
    }

    @Test func unknownRawValuesFallBackToDefaults() {
        let field = FieldDef(name: "x")
        field.kindRaw = "bogus"
        #expect(field.kind == .text)

        let view = ViewDef(name: "v")
        view.layoutRaw = "bogus"
        #expect(view.layout == .list)
    }
}
