import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The class conformance suite (sheet 288, section 6): every system class answers the policy, the answers agree with
/// each
/// other, and the lists the walls read are the table's.
@MainActor
struct ClassPolicyTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]

    init() throws {
        classes = try store.prepareCatalog()
    }

    @Test func everyClassHasAnAnswerAndEveryClassExists() {
        for key in SystemCatalog.Key.allCases {
            #expect(classes[key] != nil, "\(key.rawValue) has no class")
            _ = ClassPolicy.of(key)
        }
    }

    @Test func theAnswersAgreeWithEachOther() {
        for key in SystemCatalog.Key.allCases {
            let entry = ClassPolicy.of(key)
            if entry.mirror {
                // Read nowhere, or at least under no strict slice (lab may read the calendar and Health).
                #expect((entry.neverRead || entry.strictNever) && entry.unnameable && entry.localOnly,
                        "mirror \(key.rawValue)")
            }
            if entry.localOnly {
                // Her bookkeeping and the mirrors are named to no one and in no strict slice.
                #expect(entry.unnameable && (entry.neverRead || entry.strictNever), "local only \(key.rawValue)")
            }
            if entry.neverRead, !entry.unnameable, key != .closedDay {
                // Only closed days are unread yet nameable (the Day log and Home read them by name).
                #expect(Bool(false), "\(key.rawValue) is never read but nameable")
            }
        }
    }

    @Test func theWallsReadTheTable() {
        #expect(PrivateWords.mirrorClassKeys == Set(ClassPolicy.mirrorKeys.map(\.systemKey)))
        #expect(PrivateWords.localOnlyClassKeys == Set(ClassPolicy.localOnlyKeys.map(\.systemKey)))
        #expect(MemoryScope.neverRead == ClassPolicy.neverReadKeys)
        for key in ClassPolicy.unnameableKeys {
            let object = ObjectRecord(title: "x", classDef: classes[key])
            store.context.insert(object)
            #expect(TessAskRouter.isUnnameable(object, classes: classes), "\(key.rawValue)")
        }
    }

    /// The table before it existed, so the PR can show exactly what moved.
    @Test func todaysListsAreTheOldOnesPlusTheTightenings() {
        let oldUnnameable: Set<SystemCatalog.Key> = [
            .pool,
            .spend,
            .inflow,
            .poolMove,
            .rateNote,
            .sleepNight,
            .stepsDay,
            .restingHeartRate,
            .meProfile,
            .event,
            .heldNotice,
            .tessTurn,
            .tessCall,
            .tessSent,
            .tessWaiting,
            .belief,
        ]
        let oldNeverRead: Set<SystemCatalog.Key> = [.tessTurn, .tessCall, .tessSent, .tessSentExact, .tessWaiting,
                                                    .tessMemory, .settings, .meProfile, .heldNotice, .closedDay,
                                                    .tessAgent, .notebookPage, .agentEpisode]
        // Tightened (Oct 27): these were nameable and are not now.
        let nowUnnameable: Set<SystemCatalog.Key> = [.tessAgent, .settings, .tessMemory, .notebookPage, .agentEpisode,
                                                     .tessSentExact]
        let names: (Set<SystemCatalog.Key>) -> [String] = { $0.map(\.rawValue).sorted() }
        #expect(names(ClassPolicy.unnameableKeys) == names(oldUnnameable.union(nowUnnameable)),
                "differs: \(names(ClassPolicy.unnameableKeys.symmetricDifference(oldUnnameable.union(nowUnnameable))))")
        // Nothing loosened; neverRead is exactly what it was (the mirrors stay readable under lab, held back under
        // strict by `strictNever`, which is the old list).
        #expect(names(ClassPolicy.neverReadKeys) == names(oldNeverRead))
        let oldStrictNever: Set<SystemCatalog.Key> = [.event, .sleepNight, .stepsDay, .restingHeartRate, .heldNotice]
        #expect(oldStrictNever.isSubset(of: ClassPolicy.strictNeverKeys))
        #expect(oldNeverRead.isSubset(of: ClassPolicy.strictNeverKeys))
    }

    /// A class marked labeled gives a private-looking object a label somewhere in the shown-label rule.
    @Test func everyLabeledClassHasALabelRule() throws {
        for key in SystemCatalog.Key.allCases where ClassPolicy.of(key).labeled {
            let object = try store.create(#require(classes[key]), title: "Lexapro refill dose")
            // Some classes need their private flag as well as the words.
            try? store.set("isPrivate", to: .bool(true), on: object)
            if key == .book {
                try? store.set("isPrivate", to: .bool(true), on: object)
            }
            #expect(ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) != nil, "\(key.rawValue)")
        }
    }

    @Test func aPlainClassNeverLabelsAnObjectOnItsOwn() throws {
        for key in SystemCatalog.Key.allCases where !ClassPolicy.of(key).labeled && !ClassPolicy.of(key).mirror {
            let object = try store.create(#require(classes[key]), title: "Tuesday")
            #expect(ObjectPrivacy.label(of: object, in: store, classes: classes) == nil, "\(key.rawValue)")
        }
    }
}
