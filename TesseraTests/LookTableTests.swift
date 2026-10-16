@testable import Tessera
import Testing

/// QA T5: the five looks pinned against docs/design/themes.md (sheet plus both addenda), and Plein's light half
/// against the colours the app had before looks existed, except the listed changes.
struct LookTableTests {
    @Test func everyLookMatchesTheSheet() {
        let sheet: [String: [UInt32]] = [
            // ground, raised, ink, context, muted, tess, live, liveInk, now, health, training, neutral, sky
            "Porcelain": [0xFFFFFF, 0xF5F4F8, 0x17141F, 0x6A4C9C, 0xB9B3C3, 0x2450D8, 0xE2432A, 0xC23A22, 0xF0A500,
                          0x12936A, 0xCC3F68, 0x9C95A8, 0x7FB6E0],
            "Obsidian": [0x000000, 0x0F0E12, 0xF5F2EC, 0xB7A6E0, 0x5C5765, 0x86B4FF, 0xFF5B3A, 0xFF7A5C, 0xFFC23D,
                         0x3FD49A, 0xFF6B92, 0x8E879A, 0x7CC4F0],
            "Plein": [0xF2ECE3, 0xFAF6EF, 0x2B2440, 0x7A5C8E, 0xA39AAE, 0x2A64A0, 0xC8452F, 0xB83C28, 0xE0B341,
                      0x6E9E6A, 0x6E9E6A, 0xA39AAE, 0x9EC3D6],
            "Lacquer": [0x140F1B, 0x221A2D, 0xF1E7D6, 0xC3A6DE, 0x6C6078, 0x8DB2FF, 0xF06A4C, 0xFF8466, 0xE8B54A,
                        0x8FCB9E, 0xF07FA0, 0x9A8FA6, 0x9DBCD6],
            "Celadon": [0xE7EEE9, 0xFFFFFF, 0x0F231D, 0x456680, 0x97ABA2, 0x2C59BE, 0xD8462C, 0xB8361E, 0xD99A1C,
                        0x23866A, 0xC24766, 0x7E918A, 0x8DBBD6],
        ]
        let workout: [String: [UInt32]] = [
            // ground, raised, ink, signal, rest, tess, health
            "Porcelain": [0x14111A, 0x221D2C, 0xF5F2EC, 0xFF5B3A, 0xF0A500, 0x8FB0FF, 0x3FC58F],
            "Obsidian": [0x000000, 0x141217, 0xF5F2EC, 0xFF5B3A, 0xFFC23D, 0x86B4FF, 0x3FD49A],
            "Plein": [0x1C1828, 0x3B2D57, 0xF3ECE0, 0xD9563F, 0xE8BD4C, 0x9DBFE6, 0x7FB07A],
            "Lacquer": [0x0C0812, 0x1C1426, 0xF1E7D6, 0xF06A4C, 0xE8B54A, 0x8DB2FF, 0x8FCB9E],
            "Celadon": [0x0E1C17, 0x18302A, 0xEEF3EF, 0xEE7056, 0xE2A93A, 0x9DBBEA, 0x5DBE98],
        ]
        #expect(Look.all.map(\.name) == ["Porcelain", "Obsidian", "Plein", "Lacquer", "Celadon"])
        for look in Look.all {
            let tokens = [look.ground, look.raised, look.ink, look.context, look.muted, look.tess, look.live,
                          look.liveInk, look.now, look.health, look.training, look.neutral, look.sky]
            #expect(tokens == sheet[look.name], "\(look.name)")
            let kit = look.workout
            #expect([kit.ground, kit.raised, kit.ink, kit.signal, kit.rest, kit.tess, kit.health] == workout[look.name],
                    "\(look.name) workout")
        }
        let lightModes = Look.light.map(\.isDark)
        let darkModes = Look.dark.map(\.isDark)
        #expect(lightModes == [false, false, false])
        #expect(darkModes == [true, true])
    }

    /// Plein is the look he had; only tess (#2E6DA4 → #2A64A0, contrast) changed from before.
    @Test func pleinKeepsTodaysLightHalf() {
        let before = ThemeConcept.plein.palette
        let plein = Look.plein
        #expect(plein.ground == before.ground.0)
        #expect(plein.ink == before.ink.0)
        #expect(plein.live == before.live.0)
        #expect(plein.training == before.training.0)
        #expect(plein.context == before.context.0)
        #expect(plein.now == before.now.0)
        #expect(plein.health == before.health.0)
        #expect(plein.muted == before.muted.0)
        #expect(plein.tess == 0x2A64A0 && before.tess.0 == 0x2E6DA4)
        #expect(plein.workout.signal == ThemeConcept.plein.workout.signal)
        #expect(plein.workout.rest == ThemeConcept.plein.workout.rest)
    }
}
