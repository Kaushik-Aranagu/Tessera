import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Batch 5 "Make it mine": the class inspector's listing (sheet 113), the class package and its import preview, and
/// Tess's receipt lines.
@MainActor
struct ClassInspectorTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func inspect(_ classDef: ClassDef) -> ClassInspection {
        ClassInspection.make(classDef, store: model.store, prototypeID: model.prototype(of: classDef)?.id)
    }

    @Test func aSetListsItsFieldsWithTypesAndTheFormulaAsWritten() throws {
        let set = try #require(model.classDef(.set))
        let inspection = inspect(set)
        #expect(inspection.isBuiltIn)
        #expect(inspection.originLine.hasPrefix("Built in, "))
        let weight = try #require(inspection.fields.first { $0.name == "Weight" })
        #expect(weight.type == "weight")
        #expect(weight.formula == nil)
        let computed = try #require(inspection.fields.first { $0.formula != nil })
        #expect(computed.type == "formula")
        #expect(computed.formula?.contains("weight") == true)
        #expect(computed.voiceOver.contains("formula: "))
    }

    @Test func linksReadOutAndIn() throws {
        let entry = try #require(model.classDef(.exerciseEntry))
        let exercise = try #require(model.classDef(.exercise))
        let out = inspect(entry).links.filter { $0.direction == .out }
        #expect(out.contains { $0.classID == exercise.id && $0.line == "\(exercise.name) out" })
        let incoming = inspect(exercise).links.filter { $0.direction == .in }
        #expect(incoming.contains { $0.classID == entry.id })
    }

    @Test func aNewClassIsYoursAndCountsItsObjectsWithoutTheirTitles() throws {
        let thing = try #require(model.classDef(.thing))
        let films = model.store.createClass(name: "Films", parent: thing)
        #expect(inspect(films).originLine == "Yours, 0 objects")
        model.store.create(films, title: "Heat")
        let inspection = inspect(films)
        #expect(inspection.originLine == "Yours, 1 object")
        #expect(inspection.links.isEmpty)
        #expect(inspection.views.isEmpty)
        #expect(!String(describing: inspection).contains("Heat"), "never an object's title")
    }

    @Test func typeWordsArePlain() {
        #expect(ClassInspection.typeWord(.bool, target: nil) == "yes or no")
        #expect(ClassInspection.typeWord(.ref, target: "Exercise") == "link to Exercise")
        #expect(ClassInspection.typeWord(.refList, target: "Muscle") == "links to Muscle")
        #expect(ClassInspection.typeWord(.richText, target: nil) == "long text")
    }

    @Test func theSwitchIsOffUntilItReadsOn() {
        #expect(!ClassInspectorSwitch.isOn(nil))
        #expect(!ClassInspectorSwitch.isOn("Off"))
        #expect(ClassInspectorSwitch.isOn("On"))
    }

    @Test func theAreaBlocksShowOnlyForAll() {
        #expect(!NowBlocks.showsAreas(nil))
        #expect(!NowBlocks.showsAreas("Today's"))
        #expect(NowBlocks.showsAreas("All"))
    }
}

@MainActor
struct ClassPackageTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private var sample: ClassPackageFile {
        ClassPackageFile(
            name: "Films", parent: "Media",
            fields: [
                .init(key: "rating", name: "Rating", kind: .number),
                .init(key: "seen", name: "Seen", kind: .date),
                .init(key: "director", name: "Director", kind: .ref, target: "Person"),
            ],
            objects: [.init(title: "Heat", values: ["rating": .number(5)]), .init(title: "Ran")]
        )
    }

    @Test func previewSaysWhatItAddsBeforeAnythingIsWritten() {
        let preview = ClassPackagePreview.make(sample, classNames: ["Thing", "Films"])
        #expect(preview.name == "Films 2")
        #expect(preview.existingName == "Films")
        #expect(preview.parentName == "Thing")
        #expect(preview.missingParent == "Media")
        #expect(preview.fields == ["Rating", "Seen"])
        #expect(preview.leftOutFields == ["Director"])
        #expect(preview.objectCount == 2)
        #expect(preview.lines == [
            "Films 2, a new class beside your Films.",
            "Media isn't on this phone, so it goes under Thing.",
            "Fields: Rating and Seen.",
            "Left out: Director. Their classes aren't here.",
            "2 objects.",
        ])
    }

    @Test func previewKeepsALinkWhoseClassIsHere() {
        let preview = ClassPackagePreview.make(sample, classNames: ["Thing", "Media", "Person"])
        #expect(preview.name == "Films")
        #expect(preview.parentName == "Media")
        #expect(preview.missingParent == nil)
        #expect(preview.leftOutFields.isEmpty)
        #expect(preview.lines.first == "Films, a new class.")
        #expect(preview.lines[1] == "Under Media.")
    }

    @Test func aFileRoundTripsAndOtherJSONIsRefused() throws {
        let data = try ClassPackageFile.encode(sample)
        #expect(ClassPackageFile.decode(data) == sample)
        #expect(ClassPackageFile.decode(Data("{\"name\":\"x\"}".utf8)) == nil)
        var future = sample
        future.version = ClassPackageFile.currentVersion + 1
        #expect(try ClassPackageFile.decode(ClassPackageFile.encode(future)) == nil)
    }

    @Test func importAddsTheClassFieldsAndObjectsAndUndoTakesTheObjectsBack() throws {
        let result = try model.engine.perform(ImportClassPackage(file: sample), by: .user)
        let films = result.output.classDef
        #expect(films.name == "Films")
        #expect(films.parent?.id == model.classDef(.thing)?.id)
        let keys = ClassResolver.effectiveFields(of: films).map(\.key)
        #expect(keys.contains("rating") && keys.contains("seen") && !keys.contains("director"))
        let objects = model.store.objects(of: films).filter { !$0.isDeleted }
        #expect(Set(objects.map(\.title)) == ["Heat", "Ran"])
        let heat = try #require(objects.first { $0.title == "Heat" })
        #expect(model.store.number("rating", of: heat) == 5)
        #expect(result.record.receipt == "Films, added with 2 objects.")

        model.engine.undo(result.record)
        #expect(model.store.objects(of: films).allSatisfy(\.isDeleted))
    }

    @Test func exportCarriesTheClassAndItsObjects() throws {
        let thing = try #require(model.classDef(.thing))
        let films = model.store.createClass(name: "Films", parent: thing)
        model.store.create(films, title: "Heat")
        let file = ClassPackageFile.make(films, model: model)
        #expect(file.name == "Films")
        #expect(file.parent == thing.name)
        #expect(file.objects.map(\.title) == ["Heat"])
    }

    @Test func copy() {
        #expect(ClassPackageCopy.added("Films", objects: 0) == "Films, added.")
        #expect(ClassPackageCopy.added("Films", objects: 1) == "Films, added with 1 object.")
        #expect(ClassPackageCopy.list(["A", "B", "C"]) == "A, B and C")
    }
}

struct BodyWeightTrendTests {
    let calendar = Calendar(identifier: .gregorian)

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: Date(timeIntervalSince1970: 1_790_000_000))!
    }

    /// The research note's worked example: 80.0, 80.6, 79.6, a missing day, 79.8.
    @Test func workedExample() {
        let points = BodyWeightTrend.series([
            .init(day: day(0), kg: 80.0), .init(day: day(1), kg: 80.6), .init(day: day(2), kg: 79.6),
            .init(day: day(4), kg: 79.8),
        ], calendar: calendar)
        let trends = points.map { ($0.trend * 100).rounded() / 100 }
        #expect(trends == [80.0, 80.06, 80.01, 79.97])
        #expect(BodyWeightTrend.format(points[3].trend) == "80.0")
    }

    @Test func aBigStepIsCappedAndALongGapStartsAgain() {
        let capped = BodyWeightTrend.series([.init(day: day(0), kg: 80), .init(day: day(1), kg: 90)],
                                            calendar: calendar)
        #expect(abs(capped[1].trend - 80.2) < 0.0001)
        let reseeded = BodyWeightTrend.series([.init(day: day(0), kg: 80), .init(day: day(40), kg: 75)],
                                              calendar: calendar)
        #expect(reseeded[1].trend == 75)
    }

    @Test func theLastWeighInOfADayWins() {
        let morning = day(0)
        let evening = morning.addingTimeInterval(10 * 3600)
        let daily = BodyWeightTrend.daily([(at: evening, kg: 81), (at: morning, kg: 80)]) { _ in morning }
        #expect(daily == [.init(day: morning, kg: 81)])
    }

    @Test func theWeeklyRateWaitsForAWeekAndReadsPlainly() {
        let short = BodyWeightTrend.series((0 ..< 5).map { .init(day: day($0), kg: 80) }, calendar: calendar)
        #expect(BodyWeightTrend.weeklyRate(short, calendar: calendar) == nil)
        let falling = BodyWeightTrend.series((0 ... 14).map { .init(day: day($0), kg: 80 - Double($0) * 0.2) },
                                             calendar: calendar)
        let rate = BodyWeightTrend.weeklyRate(falling, calendar: calendar)
        #expect(rate.map { $0 < 0 } == true)
        #expect(BodyWeightTrend.rateLine(rate)?.hasSuffix("kg less than last week") == true)
        #expect(BodyWeightTrend.rateLine(0.04) == "About the same as last week")
        #expect(BodyWeightTrend.rateLine(0.3) == "0.3 kg more than last week")
        #expect(BodyWeightTrend.rateLine(nil) == nil)
    }

    @Test func onlyABareWeighInReadsAsHisWeight() {
        #expect(WeighInNotes.kilograms(in: "82 kg") == 82)
        #expect(WeighInNotes.kilograms(in: "weighed 81.8 this morning") == 81.8)
        #expect(WeighInNotes.kilograms(in: "bw 80,5") == 80.5)
        #expect(abs((WeighInNotes.kilograms(in: "181 lb") ?? 0) - 82.1) < 0.1)
        #expect(WeighInNotes.kilograms(in: "squat 140 kg") == nil)
        #expect(WeighInNotes.kilograms(in: "ibuprofen 200 mg") == nil)
        #expect(WeighInNotes.kilograms(in: "82") == nil, "a bare number needs a weigh word or a unit")
    }

    @Test func voiceOverReadsTheTrendFirst() {
        #expect(BodyWeightCopy.voiceOver(trend: 80.04, today: 80.6, rate: "About the same as last week")
            == "Body weight trend 80.0 kilograms, today 80.6, About the same as last week")
    }

    @Test func habitWeekCountsDaysLeftToSunday() throws {
        // 2026-10-19 is a Monday.
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 19)))
        #expect(HabitLine.daysLeft(in: monday, calendar: calendar) == 6)
        let sunday = try #require(calendar.date(byAdding: .day, value: 6, to: monday))
        #expect(HabitLine.daysLeft(in: sunday, calendar: calendar) == 0)
    }
}

struct TessReceiptTests {
    let first = UUID()
    let second = UUID()
    let third = UUID()

    @Test func oneChangePerThingInTheOrderTouched() {
        let field = UUID()
        let changes = TessReceipt.changes([
            .setValue(object: first, field: field, old: nil, new: .number(1)),
            .create(object: second, classID: UUID(), parent: nil, title: "Milk"),
            .setTitle(object: second, old: "Milk", new: "Oat milk"),
            .setTitle(object: first, old: "x", new: "y"),
            .softDelete(object: third),
        ])
        #expect(changes == [
            .init(id: first, verb: .renamed),
            .init(id: second, verb: .added),
            .init(id: third, verb: .removed),
        ])
    }

    @Test func theLineNamesTwoThingsAndCountsTheRest() {
        let names = [first: "Dentist", second: "Milk"]
        let two = TessReceipt.line([.init(id: first, verb: .changed), .init(id: second, verb: .added)]) { names[$0] }
        #expect(two == "Dentist, changed. Milk, added.")
        let more = TessReceipt.line([.init(id: first, verb: .changed), .init(id: second, verb: .added),
                                     .init(id: third, verb: .added)]) { names[$0] }
        #expect(more == "Dentist, changed. Milk, added. 1 more thing.")
        let unnamed = TessReceipt.line([.init(id: third, verb: .added), .init(id: UUID(), verb: .added)]) { _ in nil }
        #expect(unnamed == "2 things changed.")
    }

    @Test func undoSaysWhatItTookBack() {
        #expect(TessReceipt.undone("Dentist, changed.", partial: false) == "Dentist, taken back.")
        #expect(TessReceipt.undone("Dentist, changed.", partial: true) == "Some of it changed since. The rest is back.")
    }
}
