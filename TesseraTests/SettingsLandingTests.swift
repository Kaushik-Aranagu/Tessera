import Foundation
import SwiftUI
@testable import Tessera
import Testing
import UIKit

/// The Settings landing (landing contract §12): its six doors, the state line forms and their fit, the wall weighted by
/// what he opened, and nothing private or key-shaped in its words.
struct SettingsLandingTests {
    private static let colors = SettingsLandingWords.Colors(ink: .black, slate: .gray, green: .green)

    private static func facts(remembers: String = "12 things", claude: Bool = false,
                              backup: String? = "Last backup tonight, 9:14 pm. 4,210 things.") -> SettingsLandingFacts
    {
        SettingsLandingFacts(remembers: remembers, asksClaude: claude, units: ["kg", "km", "cm", "°C"],
                             backupLine: backup, build: "abc1234",
                             privacyLines: ["3 private notes stay on this phone.", "Health never leaves it."])
    }

    @Test func theDialCarriesTheSixDoorsInOrder() {
        let doors = SettingsLandingWords.doors(Self.facts(), colors: Self.colors)
        #expect(doors.map(\.name) == ["Tess", "Privacy", "Units", "Claude", "Backups", "About"])
        #expect(doors.allSatisfy { $0.lines.count <= 3 })
        #expect(doors[0].count == "12")
        #expect(doors[2].lines == ["kg, km", "cm, °C"])
        #expect(doors[4].lines.first == "Last backup tonight, 9:14 pm.")
    }

    @Test func everyDoorOpensAnExistingArea() {
        for door in SettingsLandingWords.doors(Self.facts(), colors: Self.colors) {
            #expect(SettingsArea(rawValue: door.id) != nil)
        }
    }

    @Test func claudeReadsOnOrOffOnlyNeverAKey() {
        for claude in [true, false] {
            let facts = Self.facts(claude: claude)
            let words = SettingsLandingWords.doors(facts, colors: Self.colors).flatMap { [$0.name] + $0.lines }
                + SettingsLandingWords.stateLine(facts)
                + SettingsLandingWords.wall(opened: [:]).map(\.text)
            #expect(!words.contains { $0.contains("sk-") || $0.lowercased().contains("key:") })
        }
        let claudeOn = SettingsLandingWords.doors(Self.facts(claude: true), colors: Self.colors)[3]
        #expect(claudeOn.lines.first == "On")
    }

    @Test func stateLineGoesLongestFirstWithNoCounters() {
        for facts in [Self.facts(), Self.facts(remembers: "Nothing yet"), Self.facts(claude: true)] {
            let forms = SettingsLandingWords.stateLine(facts)
            #expect(forms.count >= 2)
            #expect(zip(forms, forms.dropFirst()).allSatisfy { $0.count >= $1.count })
            #expect(!forms.contains { $0.contains(" of ") && $0.first?.isNumber == true })
        }
        #expect(SettingsLandingWords.stateLine(Self.facts()).first == "Tess remembers 12 things, all on this phone.")
        #expect(SettingsLandingWords.stateLine(Self.facts(remembers: "Nothing yet")).last == "Nothing kept.")
        #expect(SettingsLandingWords.stateLine(Self.facts()).last == "Tess keeps 12.")
    }

    @Test func theSecondFormFitsAtDefaultAndTheLastAtAX5() throws {
        let width: CGFloat = 354
        for facts in [Self.facts(), Self.facts(claude: true), Self.facts(remembers: "Nothing yet")] {
            let forms = SettingsLandingWords.stateLine(facts)
            // Figtree 16 at the default size; at AX5 about 3.1x, and the last form may step down to 0.8x (FitLine).
            for (size, form) in try [(CGFloat(16), #require(forms.dropFirst().first)),
                                     (CGFloat(16 * 3.1 * 0.8), #require(forms.last))]
            {
                let font = UIFont(name: "Figtree-Regular", size: size) ?? .systemFont(ofSize: size)
                let measured = (form as NSString).size(withAttributes: [.font: font]).width
                #expect(measured <= width, "\(form) at \(size) pt is \(measured) pt")
            }
        }
    }

    @Test func theWallHoldsEveryAreaAndLeansToWhatWasOpened() {
        let plain = SettingsLandingWords.wall(opened: [:])
        #expect(plain.count == SettingsArea.allCases.count)
        #expect(plain.allSatisfy { (0 ... 1).contains($0.weight) })
        let now = Date()
        let leaned = SettingsLandingWords.wall(opened: ["about": now])
        let about = try? #require(leaned.first { $0.id == "about" })
        let tess = try? #require(leaned.first { $0.id == "tess" })
        #expect((about?.weight ?? 0) > (tess?.weight ?? 1))
    }

    @Test func openedAreasStayOnThisPhone() throws {
        let defaults = try #require(UserDefaults(suiteName: "SettingsLandingTests-\(UUID().uuidString)"))
        let when = Date(timeIntervalSince1970: 1_000_000)
        SettingsAreaSeen.mark(.units, at: when, defaults: defaults)
        #expect(SettingsAreaSeen.all(defaults: defaults)["units"] == when)
    }

    @Test func briefBoldsTheLeadAndKeepsOneSentence() {
        let brief = SettingsLandingWords.brief("Last backup tonight, 9:14 pm. 4,210 things.")
        #expect(brief.lead == "Last backup")
        #expect(brief.rest == " tonight, 9:14 pm.")
        #expect(SettingsLandingWords.brief(nil).lead == nil)
        #expect(SettingsLandingWords.briefWhen(" this afternoon, 1:11 pm.") == "this afternoon")
        #expect(SettingsLandingWords.briefWhen(" Saturday, 3:03 am.") == "Saturday")
    }

    @Test func wholeWordCutsNeverEllipsize() {
        // The dial's own cut moved into the kit (FitLine.cuts) when the lead's dial replaced the lane's.
        let forms = FitLine.cuts("Across the lake and back")
        #expect(forms.first == "Across the lake and back")
        #expect(forms.last == "Across")
        #expect(!forms.contains { $0.contains("...") || $0.contains("…") })
        #expect(FitLine.cuts("Today") == ["Today"])
    }
}
