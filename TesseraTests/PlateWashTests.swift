import Foundation
@testable import Tessera
import Testing

/// Sheet 88's plate rules: Kitchen green at the end of the chain, three pigments at most, pale foods shaded.
@MainActor
struct PlateWashTests {
    @Test func noColoursIsKitchenGreen() {
        #expect(PlateWash.pigments([]) == [0x12936A])
    }

    @Test func theFirstThreeWithoutRepeats() {
        #expect(PlateWash.pigments([0xC0392B, 0xC0392B, 0xE67E22, 0xF1C40F, 0x2ECC71]) == [
            0xC0392B,
            0xE67E22,
            0xF1C40F,
        ])
    }

    @Test func paleFoodsShadeTowardInk() {
        #expect(PlateWash.isPale(0xFFFFFF) && !PlateWash.isPale(0x12936A))
        // 12% of the way from white to ink (#17141F).
        #expect(PlateWash.pigments([0xFFFFFF]) == [0xE3E3E4])
    }

    @Test func theSameObjectDrawsTheSamePlate() {
        #expect(PlateWash.blobs(seed: 42, pigments: 3) == PlateWash.blobs(seed: 42, pigments: 3))
        let count = PlateWash.blobs(seed: 42, pigments: 3).count
        #expect((3 ... 5).contains(count))
    }

    @Test func theSeedComesFromTheObjectID() {
        let id = UUID()
        #expect(PlateWash.seed(id) == PlateWash.seed(id))
        #expect(PlateWash.seed(id) != PlateWash.seed(UUID()))
    }

    @Test func aPrivatePlateHasNoPigmentAndAMaskedLabel() {
        var looked = false
        let plate = ObjectPlate(objectID: UUID(), isPrivate: true, pigments: {
            looked = true
            return [0xC0392B]
        }())
        #expect(plate.pigments.isEmpty && !looked, "a private plate never looks up pigments")
        #expect(ObjectPlate.photoLabel(title: "Rent 1200 stew", isPrivate: true, site: "example.com")
            == "Photo of Private recipe, from example.com")
        #expect(ObjectPlate.photoLabel(title: "Tacos", isPrivate: false, site: nil) == "Photo of Tacos")
    }
}
