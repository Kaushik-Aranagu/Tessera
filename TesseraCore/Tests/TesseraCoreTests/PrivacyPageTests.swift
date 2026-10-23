import Foundation
@testable import TesseraCore
import Testing

/// Together round 12, 179 walledPageV2 and round 10, 169 backupsV2: sentences from the store, counts only.
@MainActor
struct PrivacyPageTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func make(_ key: SystemCatalog.Key, _ title: String) throws -> ObjectRecord {
        try store.create(#require(engine.classes[key]), title: title)
    }

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @Test func nothingPrivateSaysSo() {
        let facts = PrivacyPage.facts(engine: engine)
        #expect(facts.total == 0)
        #expect(PrivacyPage.countsLine(facts) == "No private things yet. Anything private shows as Private everywhere.")
    }

    @Test func countsPerKindAndNeverAName() throws {
        _ = try make(.routine, "Knee rehab day")
        _ = try make(.routine, "Therapy block")
        _ = try make(.workout, "Knee rehab day")
        _ = try make(.note, "Lexapro dose")
        _ = try make(.note, "Shopping ideas")
        _ = try make(.routine, "Push A")
        let facts = PrivacyPage.facts(engine: engine)
        let line = PrivacyPage.countsLine(facts)
        #expect(line == "4 private things. 2 routines, 1 workout, 1 note. They show as Private everywhere.")
        for word in ["Knee", "Therapy", "Lexapro", "Shopping", "Push"] {
            #expect(!line.contains(word))
        }
    }

    @Test func aDeletedPrivateThingIsNotCountedAndPoolsAreAlwaysPrivate() throws {
        let gone = try make(.note, "Lexapro dose")
        store.softDelete(gone)
        try engine.perform(CreatePool(name: "US checking", opening: "100"), by: .user)
        #expect(PrivacyPage.countsLine(PrivacyPage.facts(engine: engine))
            == "1 private thing. 1 pool. They show as Private everywhere.")
    }

    @Test func thePageNeverOffersToTurnAWallOff() {
        let lines = PrivacyPage.lines(engine: engine, claudeOn: false, backupLine: "No backup yet.")
        #expect(lines.count == 4)
        #expect(lines[1] == "Never leaves this phone: health, calendar, body, calories, money amounts.")
        #expect(lines[2] == "Tess asks Claude: Off.")
        #expect(PrivacyPage.askClaudeLine(on: true) == "Tess asks Claude: On.")
        #expect(!lines.joined().lowercased().contains("turn off"))
    }

    // MARK: Backups

    @Test func theLastBackupReadsInHouseWords() {
        let now = at(23, 10)
        #expect(BackupWords.lastLine(createdAt: at(23, 21, 14), things: 4210, now: at(23, 22), calendar: calendar)
            == "Last backup tonight, 9:14 pm. 4,210 things.")
        #expect(BackupWords.lastLine(createdAt: at(23, 7, 40), things: 1, now: now, calendar: calendar)
            == "Last backup this morning, 7:40 am. 1 thing.")
        #expect(BackupWords.lastLine(createdAt: at(22, 21, 14), things: nil, now: now, calendar: calendar)
            == "Last backup yesterday, 9:14 pm.")
        #expect(BackupWords.lastLine(createdAt: at(19, 9), things: 10, now: now, calendar: calendar)
            == "Last backup Monday, 9 am. 10 things.")
        #expect(BackupWords.lastLine(createdAt: at(1, 9), things: 10, now: now, calendar: calendar)
            == "Last backup Oct 1, 9 am. 10 things.")
        #expect(BackupWords.lastLine(createdAt: nil, things: nil, now: now) == "No backup yet.")
    }

    @Test func restoreListsSevenDatesAndPreviewsInCountsOnly() {
        let dates = (1 ... 9).map { at($0, 21) }
        let list = BackupWords.restoreDates(dates, calendar: calendar)
        #expect(list.count == 7 && list.first == "Friday, Oct 9" && list.last == "Saturday, Oct 3")
        let preview = BackupWords.restorePreview(copyThings: 4100, nowThings: 4210)
        #expect(preview == "That copy has 4,100 things, fewer than the 4,210 you have now. "
            + "Today's copy stays in Backups, and you can undo this for 10 minutes.")
    }

    @Test func thingCountsReadTheStoreWithoutOpeningAnyName() throws {
        let before = try #require(BackupWords.thingCount(in: store.context))
        _ = try make(.note, "Lexapro dose")
        let after = try #require(BackupWords.thingCount(in: store.context))
        #expect(after == before + 1)
    }

    @Test func copiesSayOnlyWhatTheyLeaveOut() {
        #expect(BackupWords.notIncluded(leavingOutPrivate: false) == "Not included: health and calendar.")
        #expect(BackupWords.notIncluded(leavingOutPrivate: true)
            == "Not included: health, calendar, body and private things.")
    }

    @Test func moneyCookingAndPlacesAreCountedByKindNeverByName() throws {
        let checking = try engine.perform(CreatePool(name: "US checking", opening: "100"), by: .user).output
        try engine.perform(LogInflow(amount: "50", pool: checking.id), by: .user)
        try engine.perform(LogSpend(amount: 12, typed: "12", pool: checking.id), by: .user)
        _ = try make(.place, "Dr Lin clinic")
        let facts = PrivacyPage.facts(engine: engine)
        let nouns = Set(facts.counts.map(\.noun))
        #expect(nouns.contains("pool") && nouns.contains("deposit") && nouns.contains("place"))
        #expect(facts.total == facts.counts.reduce(0) { $0 + $1.count })
        #expect(!PrivacyPage.countsLine(facts).contains("Lin"))
    }
}
