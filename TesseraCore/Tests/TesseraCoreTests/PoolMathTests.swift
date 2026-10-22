import Foundation
@testable import TesseraCore
import Testing

/// Money pools, PR 1: classes, seed, exact Decimal math and formatting (Part B, B2/B7).
@MainActor
struct PoolMathTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let book: PoolBook

    init() throws {
        classes = try store.prepareCatalog()
        book = PoolBook(store: store, classes: classes)
    }

    func pool(_ name: String, _ currency: String, opening: String = "0.00") throws -> ObjectRecord {
        let object = try store.create(#require(classes[.pool]), title: name)
        try store.set("currency", to: .text(currency), on: object)
        try store.set("openingTyped", to: .text(opening), on: object)
        return object
    }

    @discardableResult
    func inflow(_ pool: ObjectRecord, _ typed: String) throws -> ObjectRecord {
        let object = try store.create(#require(classes[.inflow]), title: "Inflow")
        try store.setLinks("pool", on: object, to: [pool])
        try store.set("amountTyped", to: .text(typed), on: object)
        return object
    }

    @discardableResult
    func spend(_ pool: ObjectRecord, _ typed: String) throws -> ObjectRecord {
        let object = try store.create(#require(classes[.spend]), title: "Spend")
        try store.set("typed", to: .text(typed), on: object)
        try store.setLinks("pool", on: object, to: [pool])
        return object
    }

    @discardableResult
    func move(from: ObjectRecord, into: ObjectRecord, sent: String, fee: String,
              arrived: String) throws -> ObjectRecord
    {
        let object = try store.create(#require(classes[.poolMove]), title: "Move")
        try store.setLinks("fromPool", on: object, to: [from])
        try store.setLinks("toPool", on: object, to: [into])
        try store.set("sentTyped", to: .text(sent), on: object)
        try store.set("feeTyped", to: .text(fee), on: object)
        try store.set("arrivedTyped", to: .text(arrived), on: object)
        return object
    }

    @Test func theNewClassesSeedAndASpendCarriesAPool() throws {
        for key in [SystemCatalog.Key.pool, .inflow, .poolMove, .rateNote] {
            #expect(classes[key] != nil, "\(key)")
        }
        let spendFields = try ClassResolver.effectiveFields(of: #require(classes[.spend])).map(\.key)
        #expect(spendFields.contains("pool"))
    }

    @Test func moveRateIsDerived() throws {
        let checking = try pool("US checking", "USD")
        let india = try pool("India account", "INR")
        let object = try move(from: checking, into: india, sent: "1000.00", fee: "5.00", arrived: "82650.00")
        let figures = book.figures(of: object)
        #expect(figures.leaves == Decimal(string: "1005.00"))
        #expect(try PoolFormat.rate(#require(figures.effectiveRate)) == "82.24")
        #expect(figures.effectiveRate == Decimal(string: "82.23880597"))
        #expect(figures.costBasis == Decimal(string: "0.01215971"))
        #expect(book.balance(of: checking) == Decimal(string: "-1005"))
        #expect(book.balance(of: india) == Decimal(string: "82650"))
    }

    @Test func balancesAreExactPerPool() throws {
        let checking = try pool("US checking", "USD")
        let india = try pool("India account", "INR")
        try inflow(checking, "4200.00")
        try spend(checking, "1850.00")
        try move(from: checking, into: india, sent: "1000.00", fee: "5.00", arrived: "82650.00")
        #expect(book.balance(of: checking) == Decimal(string: "1345.00"))
        // Another pool's spends never touch it.
        try spend(india, "450")
        #expect(book.balance(of: checking) == Decimal(string: "1345.00"))
        #expect(book.balance(of: india) == Decimal(string: "82200"))
    }

    @Test func exactDecimalSums() throws {
        let cash = try pool("Cash", "USD", opening: "0.00")
        try inflow(cash, "0.10")
        try inflow(cash, "0.20")
        #expect(book.balance(of: cash) == Decimal(string: "0.30"))
        try spend(cash, "0.30")
        #expect(book.balance(of: cash) == 0)
        // Opening digits and thousands commas read exactly.
        let saved = try pool("Saving", "USD", opening: "1,234.56")
        #expect(book.balance(of: saved) == Decimal(string: "1234.56"))
    }

    @Test func corruptDigitsCountZeroAndNeverCrash() throws {
        let odd = try pool("Odd", "USD", opening: "ten")
        try inflow(odd, "12..3")
        try inflow(odd, "")
        try inflow(odd, "5.00")
        #expect(book.balance(of: odd) == 5)
        let other = try pool("Other", "INR")
        let object = try move(from: odd, into: other, sent: "x", fee: "", arrived: "0")
        #expect(book.figures(of: object).effectiveRate == nil && book.figures(of: object).costBasis == nil)
        #expect(PoolBook.decimal(nil) == 0)
    }

    @Test func deletedRowsDropOutAndMovesNeedBothSides() throws {
        let checking = try pool("US checking", "USD")
        let row = try inflow(checking, "100.00")
        #expect(book.balance(of: checking) == 100)
        store.softDelete(row)
        #expect(book.balance(of: checking) == 0)
    }

    @Test func formattingIsDollarsFirstAndCodedInText() throws {
        #expect(PoolFormat.amount(1850, currency: "USD") == "$1,850.00")
        #expect(try PoolFormat.amount(#require(Decimal(string: "-120")), currency: "USD") == "-$120.00")
        #expect(PoolFormat.amount(82650, currency: "INR", text: true) == "INR 82,650.00")
        #expect(PoolFormat.amount(82650, currency: "INR") == "₹82,650.00")
        #expect(PoolFormat.amount(12, currency: "CHF") == "CHF 12.00")
        #expect(try PoolFormat.digits(#require(Decimal(string: "0.5"))) == "0.50" && PoolFormat.digits(7) == "7.00")
        #expect(try PoolFormat.digits(#require(Decimal(string: "1.005"))) == "1.01")
    }

    @Test func lakhGroupingIsOffUnlessAsked() {
        #expect(PoolFormat.amount(826_500, currency: "INR", text: true) == "INR 826,500.00")
        #expect(PoolFormat.amount(826_500, currency: "INR", lakh: true, text: true) == "INR 8,26,500.00")
        #expect(PoolFormat.amount(12_345_678, currency: "INR", lakh: true, text: true) == "INR 1,23,45,678.00")
        #expect(PoolFormat.amount(999, currency: "INR", lakh: true, text: true) == "INR 999.00")
        #expect(PoolFormat.amount(1000, currency: "INR", lakh: true, text: true) == "INR 1,000.00")
    }
}

/// Pools are private wherever a label is shown: the shared export, Tess lists and the one label function.
@MainActor
struct PoolPrivacyTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]

    init() throws {
        classes = try store.prepareCatalog()
    }

    /// Every string value, key and number in the JSON, so a leak is found as a value and not as a run of characters
    /// inside a timestamp or an id.
    func values(in data: Data) throws -> (strings: [String], numbers: [Double]) {
        var strings: [String] = []
        var numbers: [Double] = []
        func walk(_ node: Any) {
            if let map = node as? [String: Any] {
                for (key, value) in map {
                    strings.append(key)
                    walk(value)
                }
            } else if let list = node as? [Any] {
                list.forEach(walk)
            } else if let text = node as? String {
                strings.append(text)
            } else if let number = node as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() {
                numbers.append(number.doubleValue)
            }
        }
        try walk(JSONSerialization.jsonObject(with: data))
        return (strings, numbers)
    }

    @Test func eachPoolClassReadsPrivateAndTheSharedExportHoldsNoWord() throws {
        let checking = try store.create(#require(classes[.pool]), title: "US checking")
        let india = try store.create(#require(classes[.pool]), title: "India account")
        try store.set("currency", to: .text("INR"), on: india)
        try store.set("source", to: .text("Acme payroll"), on: checking)
        let inflow = try store.create(#require(classes[.inflow]), title: "Inflow paycheck Acme")
        try store.setLinks("pool", on: inflow, to: [checking])
        try store.set("amountTyped", to: .text("4200.00"), on: inflow)
        let move = try store.create(#require(classes[.poolMove]), title: "Move to India")
        try store.set("sentTyped", to: .text("1000.00"), on: move)
        try store.set("arrivedTyped", to: .text("82650.00"), on: move)
        let rate = try store.create(#require(classes[.rateNote]), title: "USD/INR 83.10")
        try store.set("valueTyped", to: .text("83.10"), on: rate)

        #expect(ObjectPrivacy.label(of: checking, in: store, classes: classes) == "Private pool")
        #expect(ObjectPrivacy.label(of: inflow, in: store, classes: classes) == "Private inflow")
        #expect(ObjectPrivacy.label(of: move, in: store, classes: classes) == "Private move")
        #expect(ObjectPrivacy.label(of: rate, in: store, classes: classes) == "Private rate")
        #expect(ObjectPrivacy.shownLabel(of: india, in: store, classes: classes) == "Private pool")

        let shared = try values(in: TesseraExport(context: store.context).encoded())
        for needle in ["US checking", "India account", "Acme", "4200.00", "82650.00", "1000.00", "83.10", "INR"] {
            #expect(!shared.strings.contains { $0.contains(needle) }, "\(needle)")
        }
        #expect(shared.strings.contains("Private pool"))
        // The unmasked export, which only tests ask for, does hold them: the check can fail.
        let full = try values(in: TesseraExport(context: store.context, maskingPrivate: false).encoded())
        #expect(full.strings.contains { $0.contains("India account") })
    }
}
