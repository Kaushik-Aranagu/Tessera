import Foundation
@testable import TesseraCore
import Testing

/// G105: one check for a title or a word he typed. Receipts, UNDO, Tess lines, screens and the export all agree.
@MainActor
struct PrivacyParityTests {
    let store = ObjectStore.open(inMemory: true)

    nonisolated static let walled: [String] = [
        "Dentist cake", "dentist", "therapy ideas", "lexapro", "rent 2100", "take melatonin", "wifi password zebra99",
        "paid 40 for gas",
        "dentists", "Dr Patel", "Dr. Smith", "dr. lee",
    ]
    nonisolated static let plain: [String] = [
        "Weeknight dal", "milk", "socks", "Push A", "blood orange", "hearts of palm", "energy drink", "sleep tea",
        "Dr Pepper", "Rent car", "flour 5 kg", "ground beef 2 lb", "pain au chocolat", "recovery shake",
        "Weight Watchers chili", "drained tuna", "sleepy time tea", "dentist-appt", "5 kg flour", "1 pound butter",
        "2.5 kg rice", "2.25 kg rice", "2 pounds ground beef", "1 pound cake",
    ]

    @Test(arguments: PrivacyParityTests.walled)
    func everySurfaceMasksIt(_ title: String) {
        let last: Double? = nil
        #expect(ObjectPrivacy.isPrivateTitle(title, lastWeightKg: last), "\(title)")
        #expect(ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg: last))
        #expect(ObjectPrivacy.isPrivateWord(title, in: store))
        #expect(PrivateWords.isPrivateTitle(title, lastWeightKg: last))
        #expect(AddListItem.shownTitle(title, store: store) == "Private item")
    }

    @Test(arguments: PrivacyParityTests.plain)
    func aPlainTitleIsPlainEverywhere(_ title: String) {
        #expect(!ObjectPrivacy.isPrivateTitle(title, lastWeightKg: nil), "\(title)")
        #expect(!ObjectPrivacy.isPrivateWord(title, in: store))
        #expect(!PrivateWords.isPrivateTitle(title, lastWeightKg: nil))
        #expect(AddListItem.shownTitle(title, store: store) == title)
    }

    @Test func aRecipeCalledDentistCakeIsPrivateOnTheScreenAndInTheExport() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let cake = try engine.perform(
            CreateRecipe(text: "Dentist cake\nIngredients\n1 cup flour\nMethod\n1. Bake it."), by: .user
        ).output
        #expect(ObjectPrivacy.label(of: cake, in: store, classes: classes) == "Private recipe")
        #expect(PrivateWords.labels(in: store.context)[cake.id] != nil)
        let line = try engine.perform(AddRecipeToGroceries(recipe: cake.id), by: .user).record.summary
        #expect(!line.lowercased().contains("dentist"), "\(line)")
    }

    @Test(arguments: ["weighed 82.4 kg", "82.4 kg this morning", "my weight is 82.4", "weigh in 183 lb"])
    func aRealWeighInIsStillCaught(_ phrase: String) {
        #expect(ObjectPrivacy.isPrivateTitle(phrase, lastWeightKg: 82), "\(phrase)")
    }

    @Test func theDoctorPhraseRuleKeepsDrPepperRaw() {
        for walled in ["Dr Patel", "Dr. Smith", "dr. lee", "dentists", "Dentist appt"] {
            #expect(ObjectPrivacy.isPrivateTitle(walled, lastWeightKg: nil), "\(walled)")
        }
        for plain in ["Dr Pepper", "dr pepper", "Dr. Pepper", "dr. pepper", "drive home", "dentist-appt"] {
            #expect(!ObjectPrivacy.isPrivateTitle(plain, lastWeightKg: nil), "\(plain)")
        }
    }

    @Test func anIngredientLabelFollowsTheOneCheck() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let recipe = try engine.perform(
            CreateRecipe(text: "Dal\nIngredients\n1 cup lentils\n1 tsp lexapro\nMethod\n1. Cook."), by: .user
        ).output
        let ingredients = RecipeBook(store: store, classes: classes).lines(of: recipe).compactMap(\.ingredient)
        let medicine = try #require(ingredients.first { $0.title.lowercased().contains("lexapro") })
        let lentils = try #require(ingredients.first { $0.title.lowercased().contains("lentil") })
        #expect(ObjectPrivacy.label(of: medicine, in: store, classes: classes) == "Private item")
        #expect(ObjectPrivacy.label(of: lentils, in: store, classes: classes) == nil)
    }

    @Test(arguments: [
        "180 pounds today",
        "82 kilos this morning",
        "82 kilos",
        "weighed 180 pounds",
        "180 lb this morning",
    ])
    func aBodyWeightWithAPoundOrKiloUnitStaysPrivate(_ phrase: String) {
        #expect(ObjectPrivacy.isPrivateTitle(phrase, lastWeightKg: 82), "\(phrase)")
    }

    @Test(arguments: ["weighed 82.4 kg this morning", "paid 120.50 for shoes", "wifi password is hunter2zebra"])
    func anEditThatAddsAPrivateFactMakesTheNotePrivate(_ words: String) throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let note = try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user).output
        #expect(note.title == "Bench felt heavy")
        try engine.perform(EditNote(note: note.id, body: words), by: .user)
        #expect(note.title == SecretWords.title && store.value("isPrivate", of: note) == .bool(true), "\(words)")
        #expect(ObjectPrivacy.label(of: note, in: store, classes: classes) == "Private note")
        // A title edited to a private fact does the same.
        let other = try engine.perform(CreateNote(body: "Plain thing"), by: .user).output
        try engine.perform(EditNote(note: other.id, title: words), by: .user)
        #expect(other.title == SecretWords.title, "\(words)")
        // A plain edit stays plain.
        let plain = try engine.perform(CreateNote(body: "Leg day"), by: .user).output
        try engine.perform(EditNote(note: plain.id, body: "Leg day went well"), by: .user)
        #expect(plain.title == "Leg day" && store.value("isPrivate", of: plain) != .bool(true))
    }

    @Test(arguments: [
        "weighed 82 kg and felt great", "paid $4,000 deposit and 2 kg rice", "5 kg flour and weighed 82 kg",
        "2 kg rice paid 120.50 at costco",
    ])
    func anAmountInTheMiddleOrBeforeABodyFactStillMasks(_ phrase: String) {
        #expect(ObjectPrivacy.isPrivateTitle(phrase, lastWeightKg: 82), "\(phrase)")
        #expect(ObjectPrivacy.isPrivateTitle(phrase, lastWeightKg: nil), "\(phrase)")
    }

    @Test(arguments: [
        "82 kg and felt great",
        "82 kg then bench",
        "82 kg but tired",
        "180 pounds and sore",
        "82 kg with a cold"
    ])
    func aWeightFollowedByASentenceStaysPrivate(_ phrase: String) {
        // With his last weight known, as in real use; the connectors are not foods, so the amount rule never exempts
        // it.
        #expect(ObjectPrivacy.isPrivateTitle(phrase, lastWeightKg: 82), "\(phrase)")
    }

    @Test(arguments: ["2 kg of rice", "1 lb of butter", "2 kg rice and beans", "500 g flour"])
    func aGroceryAmountStillReadsPlain(_ phrase: String) {
        #expect(!ObjectPrivacy.isPrivateTitle(phrase, lastWeightKg: 82), "\(phrase)")
    }
}
