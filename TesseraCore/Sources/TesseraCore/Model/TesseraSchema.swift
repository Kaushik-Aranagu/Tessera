import SwiftData

public enum TesseraSchema {
    public static let models: [any PersistentModel.Type] = [
        ClassDef.self,
        FieldDef.self,
        ObjectRecord.self,
        ObjectLink.self,
        ViewDef.self,
        OpRecord.self,
    ]

    /// Local-only store for now. Switch `cloudKitDatabase` to `.private(...)`
    /// once the iCloud entitlement is added (needs a paid developer account).
    public static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: Schema(models),
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: Schema(models), configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
