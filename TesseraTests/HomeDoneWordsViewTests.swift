import Foundation
import SwiftUI
@testable import Tessera
import TesseraTess
import Testing

/// home-lines-job.md §6: Claude's words redraw the context only when they differ from the rules line.
@MainActor
struct HomeDoneWordsViewTests {
    @Test func differentWordsTakeTheSlot() {
        let words = HomeDoneWords(context: "a new best on bench")
        #expect(LineHero<EmptyViewKey>.claudeContext(words, rules: "7:40 pm") == "a new best on bench")
    }

    @Test func identicalOrMissingWordsNeverRedraw() {
        #expect(LineHero<EmptyViewKey>.claudeContext(HomeDoneWords(context: "7:40 pm"), rules: "7:40 pm") == nil)
        #expect(LineHero<EmptyViewKey>.claudeContext(HomeDoneWords(), rules: "7:40 pm") == nil)
        #expect(LineHero<EmptyViewKey>.claudeContext(nil, rules: "7:40 pm") == nil)
    }
}

extension HomeDoneWordsViewTests {
    @Test func anotherObjectClearsHeldWordsAndTheSameKeepsThem() {
        let first = UUID(), second = UUID()
        #expect(LineHero<EmptyViewKey>.isStale(askedFor: first, current: second))
        #expect(!LineHero<EmptyViewKey>.isStale(askedFor: first, current: first))
        #expect(!LineHero<EmptyViewKey>.isStale(askedFor: nil, current: first))
    }
}

/// A key-less LineHero, to reach its static helper.
typealias EmptyViewKey = SwiftUI.EmptyView
