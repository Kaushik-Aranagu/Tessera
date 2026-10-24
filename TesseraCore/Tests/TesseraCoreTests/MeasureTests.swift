import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Design sheet 115: the number and the unit as two planes. Conversion is display only.
@MainActor
struct MeasureTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func eightyTwoPointFiveKilogramsReadsAsPounds() {
        let weight = Measure(82.5, "kg")
        #expect(weight.converted(to: "lb")?.formatted == "181.9 lb")
        #expect(weight.formatted == "82.5 kg" && Measure(80, "kg").formatted == "80 kg")
    }

    @Test(arguments: [("kg", "lb", 82.5), ("km", "mi", 5.0), ("min", "hr", 95.0), ("cm", "in", 182.0),
                      ("°C", "°F", 37.0), ("°C", "°F", -40.0)])
    func everyConversionRoundTrips(_ from: String, _ to: String, _ value: Double) throws {
        let there = try #require(UnitConverter.convert(value, from: from, to: to))
        let back = try #require(UnitConverter.convert(there, from: to, to: from))
        #expect(abs(back - value) < 1e-9, "\(from) \(to) \(value)")
    }

    @Test func knownValues() {
        #expect(UnitConverter.convert(100, from: "°C", to: "°F") == 212)
        #expect(Measure(37, "°C").converted(to: "°F")?.formatted == "98.6°F")
        #expect(Measure(5, "km").converted(to: "mi")?.formatted == "3.11 mi")
        #expect(Measure(90, "min").converted(to: "hr")?.formatted == "1 hr 30 min")
        #expect(Measure(95, "min").converted(to: "hr")?.formatted == "1 hr 35 min")
        #expect(Measure(120, "min").converted(to: "hr")?.formatted == "2 hr")
        #expect(Measure(35, "min").converted(to: "hr")?.formatted == "35 min")
        #expect(Measure(2.54, "cm").converted(to: "in")?.formatted == "1 in")
        #expect(UnitConverter.convert(1, from: "kg", to: "km") == nil)
        #expect(Measure(1, "kg").converted(to: "km") == nil)
    }

    @Test func eachKindHasItsOptionsAndMoneyHasNoOfflineWheel() {
        #expect(MeasureKind.weight.units == ["kg", "lb"] && MeasureKind.temperature.units == ["°C", "°F"])
        #expect(MeasureKind.money.units.isEmpty && !MeasureKind.money.convertsOffline)
        #expect(MeasureKind.allCases.filter { $0 != .money }.allSatisfy { $0.convertsOffline && $0.base != nil })
    }

    @Test func theChoiceIsPerKindAndRoundTripsThroughSettings() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        var units = DisplayUnits()
        units.choose("lb", for: .weight)
        units.choose("mi", for: .distance)
        units.choose("stone", for: .weight)
        #expect(units.unit(for: .weight) == "lb" && units.unit(for: .distance) == "mi" && units.unit(for: .time) == nil)
        #expect(DisplayUnits(encoded: units.encoded) == units)
        try SettingsStore(engine: engine).update { $0.displayUnits = units }
        #expect(SettingsStore(engine: engine).read().displayUnits.unit(for: .weight) == "lb")
        try SettingsStore(engine: engine).update { $0.displayUnits.choose(nil, for: .weight) }
        #expect(SettingsStore(engine: engine).read().displayUnits.unit(for: .weight) == nil)
        #expect(SettingsStore(engine: engine).read().displayUnits.unit(for: .distance) == "mi")
    }

    @Test func storedValuesNeverChangeWhenTheUnitDoes() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let exercise = try #require(store.allClasses().first { $0.name == "Bench Press" } ?? engine.classes[.exercise])
        let made = try engine.perform(LogExercise(exercise: exercise.id, weight: 82.5, reps: 8, sets: 1), by: .user)
        _ = made
        let setClass = try #require(engine.classes[.set])
        let set = try #require(store.objects(of: setClass).first)
        let before = store.number("weight", of: set)
        #expect(before == 82.5)
        let workoutClass = try #require(engine.classes[.workout])
        let workout = try #require(store.objects(of: workoutClass).first)
        func top() -> String? {
            StoreDayLookup(store: store, classes: engine.classes, records: []).topSet(inWorkout: workout.id)?.text
        }
        #expect(top()?.hasSuffix("82.5 × 8") == true, "\(top() ?? "nil")")
        try SettingsStore(engine: engine).update { $0.displayUnits.choose("lb", for: .weight) }
        #expect(top()?.hasSuffix("181.9 lb × 8") == true, "\(top() ?? "nil")")
        #expect(store.number("weight", of: set) == 82.5)
        try SettingsStore(engine: engine).update { $0.displayUnits.choose("kg", for: .weight) }
        #expect(store.number("weight", of: set) == 82.5)
        #expect(top()?.hasSuffix("82.5 × 8") == true)
    }

    @Test func moneyNeverConvertsWithoutRatesAndNeverTouchesTheStoredAmount() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let spend = try engine.perform(LogSpend(amount: 12.4, typed: "€12.40", currency: "EUR", note: "lunch"),
                                       by: .user).output
        try SettingsStore(engine: engine).update { $0.displayUnits.choose("lb", for: .weight) }
        #expect(store.value("typed", of: spend)?.stringValue == "€12.40" && store.number("amount", of: spend) == 12.4)
        let money = Measure.money(12.4, currency: "EUR")
        #expect(money.formatted == "€12.40" && Measure.money(12.4, currency: nil).formatted == "12.40")
        #expect(money.converted(to: "GBP") == nil)
        // The weight choice does not touch an amount, and money has no unit wheel without rates.
        #expect(DisplayUnits(chosen: ["weight": "lb"]).shown(money) == money)
        #expect(DisplayUnits(chosen: ["money": "GBP"]).shown(money) == money)
    }

    @Test func moneyConvertsWithRatesAsAnEstimateWithItsDate() throws {
        let date = Date(timeIntervalSince1970: 1_792_000_000)
        let rates = CurrencyRates(rates: ["USD": 1.25, "GBP": 0.8, "INR": 100], date: date)
        let money = Measure.money(10, currency: "USD")
        let pounds = try #require(money.converted(to: "GBP", rates: rates))
        #expect(pounds.formatted == "about 6.40 GBP" && pounds.isEstimate && pounds.rateDate == date)
        #expect(money.formatted == "$10.00" && money.value == 10)
        #expect(rates.currencies == ["EUR", "GBP", "INR", "USD"])
        #expect(money.converted(to: "XXX", rates: rates) == nil)
        #expect(money.converted(to: "USD", rates: rates) == money)
    }

    @Test func noClaudeFileMentionsTheUnitChoice() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess")
        let names = try FileManager.default.contentsOfDirectory(atPath: sources.path(percentEncoded: false))
        var checked = 0
        for name in names where name.hasSuffix(".swift") && ["ClaudeTessModel", "PlanWording", "HomeDoneWording",
                                                             "RecipeLinkReader", "TessTools", "TessSentLog",
                                                             "DayNamer"].contains(where: name.hasPrefix)
        {
            let text = try String(contentsOf: sources.appending(path: name), encoding: .utf8)
            #expect(!text.contains("displayUnits") && !text.contains("DisplayUnits"), "\(name)")
            checked += 1
        }
        #expect(checked >= 5)
    }
}

/// The rates file and the one fetch.
@MainActor
@Suite(.serialized)
struct CurrencyRatesTests {
    static let xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <gesmes:Envelope><Cube><Cube time='2026-10-20'>
    <Cube currency='USD' rate='1.1670'/><Cube currency='GBP' rate='0.8650'/><Cube currency='INR' rate='96.1000'/>
    </Cube></Cube></gesmes:Envelope>
    """

    final class Stub: URLProtocol, @unchecked Sendable {
        nonisolated(unsafe) static var requests: [URLRequest] = []
        nonisolated(unsafe) static var reply: Data?
        override class func canInit(with _: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            Self.requests.append(request)
            if let reply = Self.reply {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: reply)
                client?.urlProtocolDidFinishLoading(self)
            } else {
                client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            }
        }

        override func stopLoading() {}
    }

    static func setReply(_ data: Data?) {
        Stub.reply = data
    }

    func fetcher(_ moment: Date, cache: RatesCache) -> CurrencyRatesFetch {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Stub.self]
        let fetch = CurrencyRatesFetch(cache: cache, session: URLSession(configuration: configuration))
        fetch.now = { moment }
        return fetch
    }

    func cache() -> RatesCache {
        RatesCache(url: FileManager.default.temporaryDirectory.appending(path: "rates-\(UUID().uuidString).json"))
    }

    @Test func theEcbFileParses() throws {
        let table = try #require(CurrencyRatesFetch.parse(Data(Self.xml.utf8)))
        #expect(table.rates["USD"] == 1.167 && table.rates["INR"] == 96.1 && table.rates["EUR"] == 1)
        #expect(try abs(#require(table.convert(10, from: "USD", to: "GBP")) - 7.4122) < 0.001)
        #expect(CurrencyRatesFetch.parse(Data("<nope/>".utf8)) == nil)
    }

    @Test func theRequestCarriesNothingOfHisAndHourlyAtMost() async throws {
        Stub.requests = []
        Stub.reply = Data(Self.xml.utf8)
        let store = cache()
        let start = Date(timeIntervalSince1970: 1_792_000_000)
        let first = try #require(await fetcher(start, cache: store).refreshIfNeeded())
        #expect(first.rates["GBP"] == 0.865 && Stub.requests.count == 1)
        let request = try #require(Stub.requests.first)
        #expect(request.httpMethod == "GET" && request.httpBody == nil && request.httpBodyStream == nil)
        #expect(request.url?.host() == "www.ecb.europa.eu" && request.url?.query == nil)
        #expect(request.allHTTPHeaderFields?.keys.contains { $0.lowercased() == "x-api-key" } != true)
        // Inside the hour: the saved table, no second call.
        _ = await fetcher(start.addingTimeInterval(1800), cache: store).refreshIfNeeded()
        #expect(Stub.requests.count == 1)
        // After the hour: one more.
        _ = await fetcher(start.addingTimeInterval(3700), cache: store).refreshIfNeeded()
        #expect(Stub.requests.count == 2)
    }

    @Test func offlineKeepsTheLastSavedTableWithItsDateAndNothingSavedStopsTheWheel() async throws {
        let store = cache()
        Stub.reply = nil
        let start = Date(timeIntervalSince1970: 1_792_000_000)
        #expect(await fetcher(start.addingTimeInterval(-7200), cache: store).refreshIfNeeded() == nil)
        Stub.reply = Data(Self.xml.utf8)
        _ = await fetcher(start, cache: store).refreshIfNeeded()
        Stub.reply = nil
        let kept = try #require(await fetcher(start.addingTimeInterval(7200), cache: store).refreshIfNeeded())
        #expect(kept.rates["USD"] == 1.167 && kept.date == CurrencyRatesFetch.parse(Data(Self.xml.utf8))?.date)
    }
}

/// The lows from #1176.
@MainActor
struct MeasureLowsTests {
    @Test func theRatesFilesAreExcludedFromBackup() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "rates-\(UUID().uuidString).json")
        let cache = RatesCache(url: url)
        cache.write(CurrencyRates(rates: ["USD": 1.2], date: .now), fetchedAt: .now)
        cache.noteAttempt(at: .now)
        for file in try [url, #require(cache.attemptURL)] {
            let values = try file.resourceValues(forKeys: [.isExcludedFromBackupKey])
            #expect(values.isExcludedFromBackup == true, "\(file.lastPathComponent)")
        }
    }

    @Test func aFailedTryIsNotRetriedWithinTheHourEvenByANewFetcher() async {
        let url = FileManager.default.temporaryDirectory.appending(path: "rates-\(UUID().uuidString).json")
        CurrencyRatesTests.Stub.requests = []
        CurrencyRatesTests.Stub.reply = nil
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CurrencyRatesTests.Stub.self]
        let start = Date(timeIntervalSince1970: 1_792_000_000)
        func fetcher(_ moment: Date) -> CurrencyRatesFetch {
            let fetch = CurrencyRatesFetch(cache: RatesCache(url: url),
                                           session: URLSession(configuration: configuration))
            fetch.now = { moment }
            return fetch
        }
        #expect(await fetcher(start).refreshIfNeeded() == nil)
        #expect(await fetcher(start.addingTimeInterval(600)).refreshIfNeeded() == nil)
        #expect(CurrencyRatesTests.Stub.requests.count == 1)
        _ = await fetcher(start.addingTimeInterval(3700)).refreshIfNeeded()
        #expect(CurrencyRatesTests.Stub.requests.count == 2)
    }

    @Test func addedLoadOnABodyweightLiftFollowsTheChosenUnit() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: classes)
        let engine = ActionEngine(store: store, classes: classes)
        let pullUp = try #require(store.allClasses().first { $0.name == "Pull-Up" })
        try engine.perform(LogExercise(exercise: pullUp.id, weight: 10, reps: 5, sets: 1), by: .user)
        let entryClass = try #require(classes[.exerciseEntry])
        let entry = try #require(store.objects(of: entryClass).first)
        let tess = TessCaptureEngine(engine: engine)
        #expect(tess.load(10, unit: .kilograms, entry: entry) == "+10")
        try SettingsStore(engine: engine).update { $0.displayUnits.choose("lb", for: .weight) }
        #expect(tess.load(10, unit: .kilograms, entry: entry) == "+22 lb")
        #expect(tess.load(0, unit: .kilograms, entry: entry) == "bodyweight")
    }

    @Test func anAttemptTimeInTheFutureDoesNotBlockTheFetch() {
        let url = FileManager.default.temporaryDirectory.appending(path: "rates-\(UUID().uuidString).json")
        let cache = RatesCache(url: url)
        let now = Date(timeIntervalSince1970: 1_792_000_000)
        cache.noteAttempt(at: now.addingTimeInterval(86400))
        #expect(cache.isFetchDue(now: now))
        cache.noteAttempt(at: now.addingTimeInterval(-600))
        #expect(!cache.isFetchDue(now: now))
    }
}
