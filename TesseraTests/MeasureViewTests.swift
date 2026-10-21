import Foundation
@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// Design sheet 115: a number and its unit drawn apart, the unit wheel, and the services behind it.
@MainActor
struct MeasureViewTests {
    // MARK: Parts

    @Test func aWeightIsTwoPartsAndTheUnitIsAlwaysThere() {
        #expect(MeasureParts.parts(of: Measure(82.5, "kg")) == [.init(number: "82.5", unit: "kg")])
        #expect(MeasureParts.parts(of: Measure(100, "kg")) == [.init(number: "100", unit: "kg")])
        #expect(MeasureParts.parts(of: Measure(5, "km")) == [.init(number: "5", unit: "km")])
    }

    @Test func timePastAnHourReadsHoursAndMinutes() {
        #expect(MeasureParts.parts(of: Measure(95, "min")) == [.init(number: "1", unit: "hr"),
                                                               .init(number: "35", unit: "min")])
        #expect(MeasureParts.parts(of: Measure(120, "min")) == [.init(number: "2", unit: "hr"),
                                                                .init(number: "0", unit: "min")])
        #expect(MeasureParts.parts(of: Measure(45, "min")) == [.init(number: "45", unit: "min")])
        #expect(MeasureParts.parts(of: Measure(1.5, "hr")) == [.init(number: "1.5", unit: "hr")], "hr stays decimal")
    }

    @Test func moneyIsDrawnAsTypedOrAsAnEstimate() {
        #expect(MeasureParts.parts(of: Measure.money(12.4, currency: "EUR")) == [.init(number: "€12.40", unit: "EUR")])
        let rates = CurrencyRates(rates: ["USD": 1.1], date: .now)
        let converted = Measure.money(10, currency: "EUR").converted(to: "USD", rates: rates)
        #expect(converted.map(MeasureParts.parts(of:)) == [.init(number: "11.00", unit: "USD")])
        #expect(converted?.isEstimate == true, "the view puts 'about' before an estimate")
    }

    // MARK: The wheel

    @Test func theWheelHasUnitsOnlyWhereTheKindHasMoreThanOne() {
        #expect(MeasureParts.wheel(for: Measure(82.5, "kg"), rates: nil) == ["kg", "lb"])
        #expect(MeasureParts.wheel(for: Measure(5, "km"), rates: nil) == ["km", "mi"])
        #expect(MeasureParts.wheel(for: Measure.money(10, currency: "EUR"), rates: nil).isEmpty, "no rates, no wheel")
        let rates = CurrencyRates(rates: ["USD": 1.1, "GBP": 0.85], date: .now)
        #expect(MeasureParts.wheel(for: Measure.money(10, currency: "EUR"), rates: rates) == ["EUR", "GBP", "USD"])
    }

    @Test func swipingStepsOneUnitAtATimeAndStopsAtTheEnds() {
        let wheel = ["kg", "lb"]
        #expect(MeasureParts.step(wheel, from: "kg", by: 1) == "lb")
        #expect(MeasureParts.step(wheel, from: "kg", by: 5) == "lb", "no wrap")
        #expect(MeasureParts.step(wheel, from: "kg", by: -1) == "kg")
        #expect(MeasureParts.cycle(wheel, from: "lb") == "kg", "a tap under Reduce Motion wraps")
    }

    @Test func theNumberConvertsAndTheStoredValueDoesNot() throws {
        let stored = Measure(82.5, "kg")
        let pounds = try #require(stored.converted(to: "lb"))
        #expect(MeasureParts.parts(of: pounds) == [.init(number: "181.9", unit: "lb")])
        #expect(stored.value == 82.5 && stored.unit == "kg")
    }

    // MARK: Words

    @Test func voiceOverSaysTheValueInTheUnitShown() throws {
        let pounds = try #require(Measure(82.5, "kg").converted(to: "lb"))
        #expect(MeasureParts.spoken(pounds) == "181.9 pounds")
        #expect(MeasureParts.spoken(Measure(1, "kg")) == "1 kilogram")
        #expect(MeasureParts.spoken(Measure(95, "min")) == "1 hour 35 minutes")
    }

    // MARK: His pick

    @Test func hisPickIsRememberedPerKindAndNothingStoredChanges() {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        model.settingsAreReal = true
        #expect(model.displayUnits.unit(for: .weight) == nil)
        model.chooseUnit("lb", for: .weight)
        #expect(model.displayUnits.unit(for: .weight) == "lb")
        #expect(model.displayUnits.unit(for: .distance) == nil, "another kind is untouched")
        #expect(model.displayUnits.shown(Measure(82.5, "kg")).unit == "lb")
    }

    // MARK: The build line

    @Test func theBuildLineIsAShortShaOrDev() {
        #expect(BuildStamp.normalised("c420a0cb16694d9d316c417c64a198df08b9ed1d") == "c420a0c")
        #expect(BuildStamp.normalised("C420A0C") == "c420a0c")
        #expect(BuildStamp.normalised("$(TESSERA_BUILD_SHA)") == "dev")
        #expect(BuildStamp.normalised("dev") == "dev")
        #expect(BuildStamp.normalised(nil) == "dev")
    }

    // MARK: The rates call site

    @Test func theRatesAreFetchedOnceAnHourNoMatterHowManyPagesOpen() async {
        RatesStub.requests = 0
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RatesStub.self]
        let url = FileManager.default.temporaryDirectory.appending(path: "rates-\(UUID().uuidString).json")
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        #expect(model.currencyFetch === model.currencyFetch, "one instance, so the hourly cap holds app-wide")
        model.currencyFetchStore = CurrencyRatesFetch(cache: RatesCache(url: url),
                                                      session: URLSession(configuration: configuration))
        let first = await model.refreshRates()
        let second = await model.refreshRates()
        let third = await model.refreshRates()
        #expect(RatesStub.requests == 1, "three pages opened, one request")
        #expect(first?.rates["USD"] == 1.17 && second == first && third == first)
        #expect(model.ratesTable == first)
    }
}

/// A canned ECB file, and a count of how often it was asked for.
final class RatesStub: URLProtocol {
    nonisolated(unsafe) static var requests = 0

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requests += 1
        let xml = """
        <Cube><Cube time='2026-10-20'><Cube currency='USD' rate='1.1700'/><Cube currency='GBP' rate='0.8700'/></Cube></Cube>
        """
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(xml.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
