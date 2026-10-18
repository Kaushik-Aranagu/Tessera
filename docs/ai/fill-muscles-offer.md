# Tess's offer to fill muscles for a custom exercise (board R1)

For: Product, then Core (pack, tool, writes) and Builder B (the offer line). From: AI architecture. Docs only: no Claude calls, no key use, no key content. Ruling: decisions 8:39 PM Oct 17 (Research exercise-muscles.md): Tess may offer to fill muscles for a custom exercise that has none; opt-in only; public anatomy facts for the walled-clean exercise name only; behind `asksClaude` and the BD4 eval with his yes in the running thread; **nothing runs before that**. This page is the spec; it builds on `side-jobs.md` section 3 and the storage contract in `gap-lane-oct17.md` (c) and part 2 section 5. **[code]** = read in Swift; **[docs]**; **[unbuilt]** = nothing on master yet (`fillFacts` is not a `TessUse` case today).

## 1. When the offer appears (all must hold)

1. The exercise is custom (not one of the seeded exercises) and its `primaryMuscles` is empty [code: the field is a ref list to the 18 Muscle objects, `SystemCatalog.swift:84-85`].
2. `factsAsked` is empty (the field and `factsSource` are [unbuilt]; they come with the next catalog number, `gap-lane-oct17.md` (c)): any earlier answer, including a decline, ends the offer for good (asked once, ever).
3. A key is saved, "Tess asks Claude" is On, the Exercise class opt-in is On (per class, decisions.md:93), the month is under the cap, not demo.
4. The name passes the one `isPrivateText` test (G105). A walled name never shows the offer.
5. The eval gate has passed **and** Kaushik has said yes in the running thread. Until then the offer does not exist, whatever the switches say.

## 2. What the offer says and does

One plain line on the exercise's MUSCLES page, two label words: **ASK** and **NOT NOW**. Proposed copy (under 12 words, first person): "I can look up the muscles for {name}." NOT NOW stores `factsAsked` so it is not offered again. ASK sends one call (section 3). The offer is never a notification and never appears on Home.

## 3. The pack (what leaves and what never does)

- **Sent:** `{"kind": "exercise", "name": "<public name>"}` and the fixed instruction. Nothing else.
- **Never sent:** a handle or id, history, weights, reps, dates, notes, routine names, the user's body weight or anything measured, any other exercise, or an image. The body stays under 1,200 bytes.
- **Model:** Sonnet 5.5, low effort, one strict tool `fillFacts`, tool choice auto, 8 s timeout, no retry. Priority: background word job, so it **steps aside at $40** (ruled 8:24 PM).
- **Order of checks:** key-shape refusal, then the one private-text test on the name, then reserve against the cap, then send.

## 4. The answer and what is written

- The tool returns muscle names. The phone matches each against the 18 `MuscleSeed` names; a name that matches none is dropped. At most 3 primary and 4 secondary (proposal; matches the ledger credit of primary 1, secondary 0.5 used by Review's MuscleVolume).
- A name that is not an exercise (nothing to match) is a decline: nothing is stored except `factsAsked`.
- The result shows as a pending ghost row with **KEEP** and **NOT NOW**; only KEEP writes, through `ObjectStore`, into the existing `primaryMuscles` and `secondaryMuscles` links. `factsSource` reads "From Claude, {house date}", written by the phone, never by Claude. A seeded table row that arrives later replaces the fill and clears `factsSource`.
- Until KEEP, the fill changes nothing: Review's weekly volume and the muscle map read only kept links.

## 5. Cost and failure

- **Per call:** about 700 tokens in and 45 out, $0.0019 typical, $0.0026 worst. Once per new custom exercise, so typical 10 a month ($0.02), worst 100 a month ($0.26).
- **Offline, busy, timeout, cap, off, no key:** no line and no retry. The offer stays (ASK still works later). A refusal or a decline sets `factsAsked`; a transport failure does not.
- **Receipt:** a ledger row, job `fillFacts`, listed on What was sent as "Facts" with the exercise's public name only if it passed the wall.

## 6. Tests (none needs a key or a live call)

- F1. Offer hidden: no key, switch Off, class opt-in Off, demo, over cap, `factsAsked` set, a seeded exercise, a walled name, eval gate not passed.
- F2. The pack body is exactly the kind and the name; no id, handle, set, weight or date; under 1,200 bytes.
- F3. A walled name ("Dentist stretch", "Therapy ball") never shows the offer and builds no payload.
- F4. Reply names are matched to the 18 seeds; an unknown name writes nothing; limits 3 and 4 hold.
- F5. NOT NOW and a decline set `factsAsked`; a timeout does not.
- F6. KEEP writes the existing links and `factsSource`; before KEEP nothing is written and Review volume is unchanged.
- F7. A key-shaped name is refused before everything else.
- F8. Steps aside at $40 and is refused at $50 with no row.

## 7. Open for Product

None. The one proposal worth a glance is the 3 and 4 muscle limits (section 4).
