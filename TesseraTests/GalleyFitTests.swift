@testable import Tessera
import Testing

struct GalleyFitTests {
    /// Sheet 298: a line that fits is left as it is; one that does not loses its tracking first, then steps down, and
    /// never goes under 9 pt.
    @Test func wordsFitThePaper() {
        let face = "IBMPlexSansCond-Bold"
        let easy = GalleyFit.fit("TONIGHT", face: face, size: 13, tracking: 1.04, width: 200)
        #expect(easy == GalleyFit.Fit(size: 13, tracking: 1.04))
        let wide = GalleyFit.measure("TOMORROW,", face: face, size: 13, tracking: 1.04)
        let tight = GalleyFit.measure("TOMORROW,", face: face, size: 13, tracking: 0)
        #expect(tight < wide)
        // Room for the word without its tracking: only the tracking goes.
        let notracking = GalleyFit.fit("TOMORROW,", face: face, size: 13, tracking: 1.04, width: (wide + tight) / 2)
        #expect(notracking == GalleyFit.Fit(size: 13, tracking: 0))
        // Less room again: the size steps down and the word fits.
        let small = GalleyFit.fit("TOMORROW,", face: face, size: 13, tracking: 1.04, width: tight * 0.8)
        #expect(small.size < 13 && small.size >= GalleyFit.floor && small.tracking == 0)
        #expect(GalleyFit.measure("TOMORROW,", face: face, size: small.size, tracking: 0) <= tight * 0.8)
        // No room at all: the floor holds.
        #expect(GalleyFit.fit("TOMORROW,", face: face, size: 13, tracking: 1.04, width: 5).size == GalleyFit.floor)
    }
}
