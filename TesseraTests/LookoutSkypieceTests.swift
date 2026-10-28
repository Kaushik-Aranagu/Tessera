import Foundation
import SwiftUI
@testable import Tessera
import Testing
import UIKit

/// Kaushik on the installed Lookout (Oct 26): the skypiece read as a grey card. The keystone is the screen's glass
/// raised by light and shadow only (sheet 254 v9), its shadows end before the caption, and Now's needs lines are care
/// nudges that never repeat what the glass already says.
@MainActor
struct LookoutSkypieceTests {
    private static let calendar = Calendar(identifier: .gregorian)

    private static func snapshot(hour: Int) -> WeatherSnapshot {
        let now = calendar.date(bySettingHour: hour, minute: 10, second: 0, of: Date()) ?? Date()
        return WeatherSample.make(now: now, fahrenheit: true)
    }

    @Test func theShadowsMeltBeforeTheCaption() {
        // The caption sits 10 pt under the slot; the glass's shadows are gone before it.
        #expect(LookoutSkypiece.shadowFoot < 10)
        // Light and shadow fall off the sides inside the 24 pt gutters.
        #expect(LookoutSkypiece.shadowReach <= 24)
    }

    @Test func nowsNeedsNeverRepeatTheGlass() {
        for hour in [0, 7, 13, 18, 22] {
            let snapshot = Self.snapshot(hour: hour)
            let needs = WeatherWords.needs(snapshot, switcher: 0, calendar: Self.calendar)
            let condition = WeatherWords.name(snapshot.kind, night: snapshot.night).lowercased()
            #expect(needs.count == 2)
            for line in needs {
                #expect(!line.contains("\(snapshot.temperature)°"), "\(line)")
                #expect(!line.lowercased().contains(condition), "\(line)")
                #expect(!line.lowercased().contains("feels like"), "\(line)")
                #expect(!line.hasSuffix("."), "\(line)")
            }
        }
    }

    @Test func careNudgesFitTheNeedsSlotWhole() {
        let font = UIFont(name: "Figtree-SemiBold", size: 15) ?? .systemFont(ofSize: 15, weight: .semibold)
        for hour in [0, 7, 13, 18, 22] {
            for line in WeatherWords.careNudges(Self.snapshot(hour: hour), calendar: Self.calendar) {
                let width = (line as NSString).size(withAttributes: [.font: font]).width
                #expect(width <= 150, "\(line) is \(width) pt")
            }
        }
    }

    @Test func aKeystoneBleedTakesTheLargestAsk() {
        var value = EdgeInsets(top: 4, leading: 22, bottom: 0, trailing: 0)
        KeystoneBleedKey.reduce(value: &value) { EdgeInsets(top: 22, leading: 0, bottom: 9, trailing: 24) }
        #expect(value == EdgeInsets(top: 22, leading: 22, bottom: 9, trailing: 24))
        let clip = KeystoneClip(insets: value).path(in: CGRect(x: 0, y: 0, width: 354, height: 182)).boundingRect
        #expect(clip == CGRect(x: -22, y: -22, width: 400, height: 213))
    }
}
