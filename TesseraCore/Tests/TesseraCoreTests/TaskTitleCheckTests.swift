import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// A task title is judged by the one shared title check (G105), like a routine or recipe title: title words and the
/// "Dr Name" rule count for a task too.
@MainActor
struct TaskTitleCheckTests {
    let store = ObjectStore.open(inMemory: true)

    @Test(arguments: ["Pay Dr Lin rent 1200", "Call Dr Lin", "Pay the therapist", "Take lexapro"])
    func aTaskTitleUsesTheOneSharedCheck(_ title: String) throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let task = try engine.perform(CreateTask(title: title), by: .user).output
        #expect(ObjectPrivacy.isPrivateTitle(title, lastWeightKg: nil))
        #expect(ObjectPrivacy.label(of: task, in: store, classes: engine.classes) == "Private task", "\(title)")
    }

    @Test func aPlainTaskTitleStaysPlain() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        for title in ["Buy lemons", "Call mom", "Dr Pepper run"] {
            let task = try engine.perform(CreateTask(title: title), by: .user).output
            #expect(ObjectPrivacy.label(of: task, in: store, classes: engine.classes) == nil, "\(title)")
        }
    }

    @Test func callTheDentistStaysPlainEverywhere() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        for title in ["Call the dentist", "Book the dentist", "dentist"] {
            let task = try engine.perform(CreateTask(title: title), by: .user).output
            #expect(ObjectPrivacy.label(of: task, in: store, classes: engine.classes) == nil, "\(title)")
            #expect(!ObjectPrivacy.isPrivateTitle(title, lastWeightKg: nil), "\(title)")
        }
        let json = try String(decoding: TesseraExport(context: store.context).encoded(), as: UTF8.self)
        #expect(json.contains("Call the dentist"))
    }

    @Test func tessDoesNotSayADoctorTaskBack() async throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let tess = TessCaptureEngine(engine: engine)
        let capture = await tess.capture("Call Dr Lin tomorrow", context: TessContext())
        #expect(!capture.records.isEmpty)
        #expect(!capture.line.lowercased().contains("lin"), "\(capture.line)")
    }

    @Test func bookPhysioStaysPlain() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        for title in ["Book physio", "physio", "PT"] {
            let task = try engine.perform(CreateTask(title: title), by: .user).output
            #expect(ObjectPrivacy.label(of: task, in: store, classes: engine.classes) == nil, "\(title)")
            #expect(!ObjectPrivacy.isPrivateTitle(title, lastWeightKg: nil), "\(title)")
        }
    }

    @Test func lowercaseDrNameIsPrivate() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        for title in ["call dr lin", "CALL DR LIN", "dr. lin tue", "see dr patel friday"] {
            #expect(ObjectPrivacy.isPrivateTitle(title, lastWeightKg: nil), "\(title)")
            let task = try engine.perform(CreateTask(title: title), by: .user).output
            #expect(ObjectPrivacy.label(of: task, in: store, classes: engine.classes) == "Private task", "\(title)")
        }
        for plain in ["Dr Pepper run", "dr pepper", "drive home", "dry cleaning", "call dr", "dentist"] {
            #expect(!ObjectPrivacy.isPrivateTitle(plain, lastWeightKg: nil), "\(plain)")
        }
    }
}
