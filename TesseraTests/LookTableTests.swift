@testable import Tessera
import Testing

/// QA T5: the five looks pinned against docs/design/looks-recut.md (Design 43; Obsidian as themes.md had it).
struct LookTableTests {
    @Test func everyLookMatchesTheSheet() {
        let sheet: [String: [UInt32]] = [
            // ground, raised, ink, context, muted, tess, live, liveInk, now, health, training, neutral, sky
            "Porcelain": [0xFFFFFF, 0xF6F5F9, 0x121016, 0x5A3DAF, 0xB9B3C3, 0x2450D8, 0xE2432A, 0xC23A22, 0xF0A500,
                          0x12936A, 0xCC3F68, 0x9C95A8, 0x7FB6E0],
            "Obsidian": [0x000000, 0x0F0E12, 0xF5F2EC, 0xB7A6E0, 0x5C5765, 0x86B4FF, 0xFF5B3A, 0xFF7A5C, 0xFFC23D,
                         0x3FD49A, 0xFF6B92, 0x8E879A, 0x7CC4F0],
            "Plein": [0xF3EDE2, 0xFBF7F0, 0x26201E, 0x7D4E6E, 0xBDB2A4, 0x2A4FA8, 0xB9452B, 0xA33A22, 0xC98E1B,
                      0x5E8F5A, 0xB04A5E, 0xA89C90, 0x8DB4C8],
            "Lacquer": [0x130A0D, 0x221317, 0xF3E8D6, 0xD9A6B8, 0x6E5C62, 0x8FB5FF, 0xF0583A, 0xFF7C5E, 0xE9B64A,
                        0x86C9A0, 0xF48BA6, 0x9E8F93, 0xA6BCD6],
            "Celadon": [0xE0EAE2, 0xFFFFFF, 0x0C1E19, 0x3A6584, 0x97ABA2, 0x2C59BE, 0xD94B2E, 0xB23A1F, 0xCF9418,
                        0x1F8B6A, 0xBF4664, 0x7E918A, 0x86B8D4],
        ]
        #expect(Look.all.map(\.name) == ["Porcelain", "Obsidian", "Plein", "Lacquer", "Celadon"])
        for look in Look.all {
            let tokens = [look.ground, look.raised, look.ink, look.context, look.muted, look.tess, look.live,
                          look.liveInk, look.now, look.health, look.training, look.neutral, look.sky]
            #expect(tokens == sheet[look.name], "\(look.name)")
        }
        let lightModes = Look.light.map(\.isDark)
        let darkModes = Look.dark.map(\.isDark)
        #expect(lightModes == [false, false, false])
        #expect(darkModes == [true, true])
    }

    /// Design 43 recut Plein: flat (no washes or grain), earth pigments, its own training colour apart from health.
    @Test func pleinIsFlatWithEarthPigments() {
        let plein = Look.plein
        #expect(plein.field == .pigmentBloom)
        #expect(plein.training != plein.health)
        #expect(plein.sheen == 0xE0B341 && !plein.sheenOnLetters)
    }
}
