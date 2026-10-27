import Foundation
@testable import Tessera
import Testing

@Suite("Workout mode: the Done total counting up")
struct CountUpTests {
    @Test("It takes 900 ms and ends exactly on the final value")
    func ends() {
        #expect(CountUp.duration == 0.9)
        #expect(CountUp.value(at: 0, final: 9795) == 0)
        #expect(CountUp.value(at: 0.9, final: 9795) == 9795)
        #expect(CountUp.value(at: 3, final: 9795) == 9795)
    }

    @Test("Ease-out cubic: fast first, slow last")
    func easing() {
        #expect(CountUp.eased(0) == 0 && CountUp.eased(1) == 1)
        #expect(abs(CountUp.eased(0.5) - 0.875) < 1e-9)
        #expect(CountUp.eased(0.25) > 0.25)
        let early = CountUp.eased(0.1) - CountUp.eased(0)
        let late = CountUp.eased(1) - CountUp.eased(0.9)
        #expect(early > late)
    }

    @Test("It never goes backwards")
    func monotonic() {
        var last = -1.0
        for step in 0 ... 90 {
            let value = CountUp.value(at: Double(step) / 100, final: 9795)
            #expect(value >= last)
            last = value
        }
    }

    @Test("The number is grouped, whole, and the last frame reads the final text")
    func formatting() {
        #expect(CountUp.text(9795) == CountUp.text(CountUp.value(progress: 1, final: 9795)))
        #expect(CountUp.text(0) == "0")
        #expect(CountUp.text(41.4) == "41")
        #expect(CountUp.text(9795.2).contains("9") && CountUp.text(9795).count >= 4)
    }

    @Test("No frame is wider than the final: a slot sized to it never grows")
    func slot() {
        let final = CountUp.text(9795).count
        for step in 0 ... 100 {
            let text = CountUp.text(CountUp.value(progress: Double(step) / 100, final: 9795))
            #expect(text.count <= final)
        }
    }
}
