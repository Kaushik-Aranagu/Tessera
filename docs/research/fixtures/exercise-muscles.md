# Exercise to muscles fixtures (sheet 88)

Research, for Design's imagery sheet 88 (MUSCLES page and Routine mini map), Builder A (`MuscleFigure`) and Core. Board: research 8:37 IMAGERY DATA. Decision: decisions 8:37 pm (sheet 88 adopted; "muscle table is the phone's"). Public anatomy facts only; no personal data. Read against origin/master at commit 626e31f.

## Status (what exists on master)
- The table already exists. `ExerciseLibrary.swift` (TesseraCore/Catalog) seeds 72 built-in exercises, each with `primary` and `secondary` muscles, written in our own words. `ExerciseLibraryInstaller` links them to the class profile as `primaryMuscles` and `secondaryMuscles` refList fields. This file records that table as test-ready rows; it does not invent a second one.
- The muscle list exists: `MuscleSeed`, 18 muscles, installed by `MuscleLibrary` as Muscle objects with a `group` field.
- The credit rule exists: `TrainingLedger.weeklySets(weekContaining:)` counts 1 per set for each primary muscle and 0.5 per set for each secondary muscle. Warm-ups are not working sets.
- Inheritance exists: `ObjectStore.linkedObjects(_:ofClass:)` walks up the class chain to the nearest class profile, so a child class with no muscles of its own reads its parent's.
- Gaps found:
  1. `ReviewPage` `MuscleVolume` counts primary muscles only (whole sets), while `weeklySets` counts secondary at half. The same week can show two different numbers.
  2. `MuscleVolume.muscles(of:)` stops at the first profile with primary muscles and ignores secondary.
  3. No muscle-to-figure-region map exists yet (sheet 88 needs one; proposed below).
  4. The sheet says "Front shoulders"; the app name is "Front Delts". Design and Builder A must pick one label (settled, Rulings D1).
  5. The brief says "the 30 exercises he uses". Which 30 is not in public data or on the board, so the fixtures cover all 72 catalog exercises. Settled, Rulings P3: Design's mock list uses the 72.

## The muscle list (fixed, 18)
Chest, Front Delts, Side Delts, Rear Delts, Triceps, Biceps, Forearms, Lats, Upper Back, Lower Back, Abs, Obliques, Glutes, Quads, Hamstrings, Adductors, Abductors, Calves.

Existing groups (the `group` field, used to roll up and for the Routine context line): Chest = Chest; Shoulders = Front, Side and Rear Delts; Arms = Triceps, Biceps, Forearms; Back = Lats, Upper Back, Lower Back; Core = Abs, Obliques; Legs = Glutes, Quads, Hamstrings, Adductors, Abductors, Calves.

### Figure regions (for Builder A; Rulings D2 and D3 applied)
Sheet 88's figure draws front: traps, delts, chest, arms, forearms, abs, obliques, hips, quads, calves; back: traps, rear delts, lats, triceps, forearms, low back, glutes, hamstrings, calves. Proposed map from the 18 muscles to regions:

| Muscle | Front region | Back region |
|---|---|---|
| Chest | chest | none |
| Front Delts | delts | none |
| Side Delts | delts | delts |
| Rear Delts | none | rear delts |
| Triceps | none | triceps |
| Biceps | arms | none |
| Forearms | forearms | forearms |
| Lats | none | lats |
| Upper Back | none | traps (shared, Rulings D2) |
| Lower Back | none | low back |
| Abs | abs | none |
| Obliques | obliques | none |
| Glutes | none | glutes |
| Quads | quads | none |
| Hamstrings | none | hamstrings |
| Adductors | none until Design draws the inner-thigh strip (Rulings D3) | none |
| Abductors | hips | glutes (outer edge) |
| Calves | calves | calves |

Anatomy notes: the lats sit on the back, not the front; the upper back (rhomboids, mid and lower traps) shares the traps region on the figure because the sheet draws no separate mid-back shape. A muscle with no region on a side leaves that side unlit.

## Credit rule (status: exists on master; the numbers below are not new)
- A working set credits each primary muscle 1 and each secondary muscle 0.5. A warm-up credits nothing.
- A compound lift with two primaries credits both in full (a set of Back Squat is 1 for Quads and 1 for Glutes). The sum can exceed the set count; that is intended and is how the table reads.
- A muscle listed as both primary and secondary: not present in the catalog; PROPOSAL: primary wins, never 1.5.
- Figure intensity (sheet 88): primary 72% train color, secondary 36%, which is the same 1 to 0.5 ratio. Row text: primary reads "primary", secondary reads "half a set each".
- Routine union map (sheet 88): a muscle is lit as primary if any slot lists it primary, else as secondary if any slot lists it secondary. PROPOSAL.
- Settled (Rulings P1): `MuscleVolume` (Review) calls `weeklySets`, so both pages show the same number.

## Edge cases (PROPOSALS unless marked)
1. Custom exercise with no muscles and no parent: no muscles, MUSCLES page reads "Nothing known yet." (sheet 88), no figure, no credit, no error. Routine union skips it. Any offer to fill it is gated (Rulings P2).
2. Custom exercise whose parent class is a catalog lift (exists on master via `linkedObjects(ofClass:)`): reads the parent's muscles. A name alone ("Paused Bench Press") is not matched by guessing.
3. Own muscles on a custom exercise: his pick overrides, and parent muscles are not merged.
4. Variants such as "Incline bench": a name match goes through the catalog name and aliases only, case-insensitive, hyphen and space equal ("Close Grip Bench" = "Close-Grip Bench"). "Incline bench" and "Incline BB Press" resolve to Incline Bench Press (Chest and Front Delts primary). "Incline" alone is ambiguous (Bench vs Dumbbell vs Curl): no match.
5. Unknown name ("Zottman curl" not in catalog): no match, then edge case 1. Never fuzzy-match to the nearest name.
6. Equipment prefixes: "DB Bench" and "BB Bench" are listed aliases. A prefix that is not a listed alias ("Smith Bench") is not matched.
7. Bodyweight lifts (Pull-Up, Dip, Push-Up): credited like any lift; load type does not change credit.
8. Claude-filled rows keep "From Claude, Oct 16" (every-side.md) and the figure reads the same table. Muscles outside the 18 are dropped, not added. PROPOSAL.
9. Private exercises or notes: no figure change; this table is app content, not a private fact.
10. Isolation lifts with no secondary (Pec Deck, Leg Extension) show primary only, and "half a set each" does not appear.

## Fixture rows: catalog (72)
Columns: id, exercise (catalog name), expected primary, expected secondary, test name (Swift Testing, in `TesseraCoreTests`), owner. Check: the exercise's profile `primaryMuscles` and `secondaryMuscles` equal the lists, as sets; one working set credits primary 1 and secondary 0.5.

| id | exercise | expected primary | expected secondary | test name | owner |
|---|---|---|---|---|---|
| EM-001 | Bench Press | Chest | Triceps, Front Delts | `muscles_benchPress` | Core |
| EM-002 | Incline Bench Press | Chest, Front Delts | Triceps | `muscles_inclineBenchPress` | Core |
| EM-003 | Close-Grip Bench Press | Triceps, Chest | Front Delts | `muscles_closeGripBench` | Core |
| EM-004 | Dumbbell Bench Press | Chest | Triceps, Front Delts | `muscles_dbBenchPress` | Core |
| EM-005 | Incline Dumbbell Press | Chest, Front Delts | Triceps | `muscles_inclineDbPress` | Core |
| EM-006 | Machine Chest Press | Chest | Triceps, Front Delts | `muscles_machineChestPress` | Core |
| EM-007 | Push-Up | Chest | Triceps, Front Delts, Abs | `muscles_pushUp` | Core |
| EM-008 | Dip | Chest, Triceps | Front Delts | `muscles_dip` | Core |
| EM-009 | Cable Fly | Chest | Front Delts | `muscles_cableFly` | Core |
| EM-010 | Pec Deck | Chest | none | `muscles_pecDeck` | Core |
| EM-011 | Overhead Press | Front Delts | Triceps, Side Delts | `muscles_overheadPress` | Core |
| EM-012 | Seated Dumbbell Shoulder Press | Front Delts | Triceps, Side Delts | `muscles_seatedDbShoulderPress` | Core |
| EM-013 | Machine Shoulder Press | Front Delts | Triceps | `muscles_machineShoulderPress` | Core |
| EM-014 | Dumbbell Lateral Raise | Side Delts | none | `muscles_dbLateralRaise` | Core |
| EM-015 | Cable Lateral Raise | Side Delts | none | `muscles_cableLateralRaise` | Core |
| EM-016 | Barbell Row | Upper Back, Lats | Biceps, Rear Delts, Lower Back | `muscles_barbellRow` | Core |
| EM-017 | One-Arm Dumbbell Row | Lats, Upper Back | Biceps, Rear Delts | `muscles_oneArmDbRow` | Core |
| EM-018 | Seated Cable Row | Upper Back, Lats | Biceps, Rear Delts | `muscles_seatedCableRow` | Core |
| EM-019 | Chest-Supported Row | Upper Back | Lats, Rear Delts, Biceps | `muscles_chestSupportedRow` | Core |
| EM-020 | T-Bar Row | Upper Back, Lats | Biceps, Lower Back | `muscles_tBarRow` | Core |
| EM-021 | Face Pull | Rear Delts | Upper Back | `muscles_facePull` | Core |
| EM-022 | Reverse Pec Deck | Rear Delts | Upper Back | `muscles_reversePecDeck` | Core |
| EM-023 | Pull-Up | Lats | Biceps, Upper Back | `muscles_pullUp` | Core |
| EM-024 | Chin-Up | Lats, Biceps | Upper Back | `muscles_chinUp` | Core |
| EM-025 | Assisted Pull-Up | Lats | Biceps | `muscles_assistedPullUp` | Core |
| EM-026 | Lat Pulldown | Lats | Biceps, Upper Back | `muscles_latPulldown` | Core |
| EM-027 | Close-Grip Pulldown | Lats | Biceps | `muscles_closeGripPulldown` | Core |
| EM-028 | Straight-Arm Pulldown | Lats | none | `muscles_straightArmPulldown` | Core |
| EM-029 | Back Squat | Quads, Glutes | Adductors, Lower Back | `muscles_backSquat` | Core |
| EM-030 | Front Squat | Quads | Glutes, Upper Back | `muscles_frontSquat` | Core |
| EM-031 | Goblet Squat | Quads | Glutes | `muscles_gobletSquat` | Core |
| EM-032 | Hack Squat | Quads | Glutes | `muscles_hackSquat` | Core |
| EM-033 | Leg Press | Quads, Glutes | Adductors | `muscles_legPress` | Core |
| EM-034 | Smith Machine Squat | Quads | Glutes | `muscles_smithSquat` | Core |
| EM-035 | Bulgarian Split Squat | Quads, Glutes | Adductors | `muscles_bulgarianSplitSquat` | Core |
| EM-036 | Walking Lunge | Quads, Glutes | Adductors | `muscles_walkingLunge` | Core |
| EM-037 | Reverse Lunge | Glutes, Quads | none | `muscles_reverseLunge` | Core |
| EM-038 | Step-Up | Quads, Glutes | none | `muscles_stepUp` | Core |
| EM-039 | Deadlift | Glutes, Hamstrings, Lower Back | Quads, Upper Back, Forearms | `muscles_deadlift` | Core |
| EM-040 | Sumo Deadlift | Glutes, Quads, Adductors | Hamstrings, Lower Back | `muscles_sumoDeadlift` | Core |
| EM-041 | Romanian Deadlift | Hamstrings, Glutes | Lower Back | `muscles_romanianDeadlift` | Core |
| EM-042 | Dumbbell Romanian Deadlift | Hamstrings, Glutes | Lower Back | `muscles_dbRomanianDeadlift` | Core |
| EM-043 | Good Morning | Hamstrings, Lower Back | Glutes | `muscles_goodMorning` | Core |
| EM-044 | Kettlebell Swing | Glutes, Hamstrings | Lower Back | `muscles_kbSwing` | Core |
| EM-045 | Hip Thrust | Glutes | Hamstrings | `muscles_hipThrust` | Core |
| EM-046 | Back Extension | Lower Back, Glutes | Hamstrings | `muscles_backExtension` | Core |
| EM-047 | Cable Pull-Through | Glutes | Hamstrings | `muscles_cablePullThrough` | Core |
| EM-048 | Leg Extension | Quads | none | `muscles_legExtension` | Core |
| EM-049 | Lying Leg Curl | Hamstrings | none | `muscles_lyingLegCurl` | Core |
| EM-050 | Seated Leg Curl | Hamstrings | none | `muscles_seatedLegCurl` | Core |
| EM-051 | Hip Adduction | Adductors | none | `muscles_hipAdduction` | Core |
| EM-052 | Hip Abduction | Abductors, Glutes | none | `muscles_hipAbduction` | Core |
| EM-053 | Standing Calf Raise | Calves | none | `muscles_standingCalfRaise` | Core |
| EM-054 | Seated Calf Raise | Calves | none | `muscles_seatedCalfRaise` | Core |
| EM-055 | Barbell Curl | Biceps | Forearms | `muscles_barbellCurl` | Core |
| EM-056 | Dumbbell Curl | Biceps | Forearms | `muscles_dbCurl` | Core |
| EM-057 | Hammer Curl | Biceps, Forearms | none | `muscles_hammerCurl` | Core |
| EM-058 | Incline Dumbbell Curl | Biceps | none | `muscles_inclineDbCurl` | Core |
| EM-059 | Preacher Curl | Biceps | none | `muscles_preacherCurl` | Core |
| EM-060 | Cable Curl | Biceps | Forearms | `muscles_cableCurl` | Core |
| EM-061 | Rope Pushdown | Triceps | none | `muscles_ropePushdown` | Core |
| EM-062 | Overhead Cable Extension | Triceps | none | `muscles_overheadCableExtension` | Core |
| EM-063 | Skull Crusher | Triceps | none | `muscles_skullCrusher` | Core |
| EM-064 | Dumbbell Overhead Extension | Triceps | none | `muscles_dbOverheadExtension` | Core |
| EM-065 | Barbell Shrug | Upper Back | Forearms | `muscles_barbellShrug` | Core |
| EM-066 | Dumbbell Shrug | Upper Back | Forearms | `muscles_dbShrug` | Core |
| EM-067 | Plank | Abs | Obliques | `muscles_plank` | Core |
| EM-068 | Ab Wheel Rollout | Abs | Lats | `muscles_abWheelRollout` | Core |
| EM-069 | Hanging Leg Raise | Abs | Forearms | `muscles_hangingLegRaise` | Core |
| EM-070 | Cable Crunch | Abs | none | `muscles_cableCrunch` | Core |
| EM-071 | Pallof Press | Obliques | Abs | `muscles_pallofPress` | Core |
| EM-072 | Farmer's Carry | Forearms, Upper Back | Abs, Obliques | `muscles_farmersCarry` | Core |

## Fixture rows: edge cases
| id | input | expected primary | expected secondary | test name | owner |
|---|---|---|---|---|---|
| EC-01 | custom "Zottman Curl", no parent | none | none | `muscles_customNoParentIsEmpty` | Core |
| EC-02 | custom "Paused Bench Press", parent Bench Press | Chest | Triceps, Front Delts | `muscles_childReadsParent` | Core |
| EC-03 | custom with own Biceps, parent Bench Press | Biceps | none | `muscles_ownOverridesParent` | Core |
| EC-04 | name "incline bench" | Chest, Front Delts | Triceps | `muscles_aliasInclineBench` | Core |
| EC-05 | name "Close Grip Bench" | Triceps, Chest | Front Delts | `muscles_hyphenSpaceEqual` | Core |
| EC-06 | name "incline" | no match | no match | `muscles_ambiguousNameNoMatch` | Core |
| EC-07 | name "Smith Bench" | no match | no match | `muscles_unlistedPrefixNoMatch` | Core |
| EC-08 | 3 working sets Back Squat | Quads 3, Glutes 3 | Adductors 1.5, Lower Back 1.5 | `credit_squatThreeSets` | Core |
| EC-09 | 2 working sets + 1 warm-up Bench Press | Chest 2 | Triceps 1, Front Delts 1 | `credit_warmupIgnored` | Core |
| EC-10 | muscle in both lists | primary only, credit 1 | none for that muscle | `credit_primaryWinsOverSecondary` | Core |
| EC-11 | Review week total vs `weeklySets` for the same sets (Rulings P1) | equal | equal | `review_matchesLedgerCredit` | Builder B |
| EC-12 | Routine of Bench Press, Overhead Press, Rope Pushdown | Chest, Front Delts, Triceps | Side Delts | `routine_unionMap` | Builder A |
| EC-13 | Claude row names "Teres major" | dropped | dropped | `muscles_claudeRowOutsideListDropped` | Core |
| EC-14 | exercise with no muscles on MUSCLES page | no figure, "Nothing known yet." | none | `musclesPage_emptyState` | Builder A |
| EC-15 | Bench Press figure | Chest region at 72% | Triceps and Front Delts at 36% | `figure_benchPressRegions` | Builder A |
| EC-16 | Hip Adduction, figure only (Adductors has no front region yet, Rulings D3) | Adductors 1 (credit), no figure fill | none | `figure_adductorsNoRegionNoFill` | Builder A |
| EC-17 | custom "Rehab press for my knee surgery", no parent (walled: private content, must not be sent) | none (name not sent) | none (name not sent) | `muscles_walledNameNotSent` | Core |

## Rulings
Settled on the board. Each ruling replaces the matching proposal above.

Design (sheet 88)
- D1. The page says "Front shoulders". The stored name stays "Front Delts". One label map in the view turns the stored name into the page label.
- D2. Upper Back shares the traps region on the back figure. It has no front region.
- D3. Adductors has no region until Design draws a thin inner-thigh strip on the front figure. Until then Adductors gets no fill on the figure and no invented region. It still gets its row: primary 1 set, secondary half a set. The credit row is EM-051 and the no-fill check is EC-16. Design will tell Research when the strip is added, and the front region is set then.

Product (decisions 8:39 pm)
- P1. Review uses the ledger credit rule: primary 1, secondary 0.5, warm-ups 0. Builder B owns the change to `MuscleVolume`, so Review and the ledger show one number for the same week (row EC-11).
- P2. Tess may offer to fill muscles for a custom exercise that has none. This is opt-in only and gated: the same gate as fillFacts (asksClaude, and BD4 with his yes). Only public anatomy is sent, and only for a name that is clean, meaning it holds no private content. A name with private content is never sent (row EC-17).
- P3. Design's mock list uses the 72 seeded exercises. The fixtures cover the same 72.

## Open questions
None. Every earlier question is settled under Rulings (D1, D2, D3, P1, P2, P3).
