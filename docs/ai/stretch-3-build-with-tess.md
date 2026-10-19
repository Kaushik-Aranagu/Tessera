# Stretch 3: Build with Tess from a sentence (huddle batch 9)

For: Product, then Core (validator, tools, route) and Builder B (the ghost class page, the Review row). From: AI architecture. Docs only: no Claude calls, no key use, nothing built. This page does **not** redo `docs/research/app-from-a-sentence.md` (the flow, the 15 sentences, the validator table and the A1 to A5 slices stay there); it fixes the batch 9 questions: what "block catalog only" means, the pack, the budget against the $50 cap, the switch, and what is built on master. Tags: **[code]**, **[docs]**, **[unbuilt]**, **[proposed]**, **[unverified]**. Prices from `model-effort-cost-table.md`: Sonnet 5.5 2,000 n$ in / 10,000 n$ out per token.

## 0. The one-paragraph answer

"I want to track my plants" becomes **one** strict tool call (`proposeClass`, `proposeFields`, `proposeList`, `useExisting` or `clarify`). The phone validates it against the block catalog, applies it as one pending op group, and shows a **ghost of the class's own page**; one tap accepts, undo removes it all. Claude never writes code, formulas or screens, and never sees a single object of his. Sonnet 5.5 low, about **$0.012 a call**. Typical month **$0.06**; capped worst **$0.72** (1.4% of $50). Off by default behind **Build with Tess**.

## 1. What master has today (verified in code)

- `Op.createClass` and `Op.deleteClass` exist (`TesseraCore/Sources/TesseraCore/Actions/Op.swift:32,33`) with inverses, written by the class page's "New subclass" [code]. **No** `addField` or `createView` op yet [code: grep]. So a class with fields and a view cannot yet be one undoable op group: A1 in the research page is still the first slice [unbuilt].
- `TessUse` has seven cases (`capture, question, paste, recipeLink, plan, keyCheck, lines`); `buildClass` is not one [code `TessModel.swift:5`].
- No `ClassProposalValidator` or `proposeClass` in Swift [code: grep]. The research page's schema and 40-row validator table are specs only.

## 2. "Block catalog only" (the rule that keeps this safe)

The roadmap line is "a usable app spec from one sentence, using only the block catalog" (`product/roadmap.md`, M4). Defined here so it can be tested [proposed]:

| Block | What Claude may use |
|---|---|
| Parent classes | Any non-composition class in the catalog (Thing, Activity, Note, and system classes). Not Set, Exercise Entry, Recipe Line, Recipe Step, Slot, List Item, Process |
| Field kinds | text, number, bool, date, duration, mass, choice, ref, refList. **Not** computed, classRef, richText, and no `expression` anywhere |
| Traits | schedulable, timed, trackable, measurable (with the compatibility rules in the validator) |
| Views | list, board, calendar, gallery, with a sort and a group naming one of the class's own fields |
| Objects of system classes | List (through `proposeList`), Habit and Chore (once those classes exist), reusing the existing actions |
| Not blocks (refused) | Code, formulas, automations ("when X, do Y" is Stretch 5), new screens, Home tiles (Design's remix editor, batch 9 row 7), integrations, notifications |

Anything outside the table is a `clarify` ("That is a few apps. Start with the people you keep in touch with?") or a refusal line; the validator is the gate whatever the model returns, so a hostile or confused answer cannot make anything beyond a class, up to 8 fields and a view.

## 3. The job

```swift
// new [unbuilt]. Static like every TessJob.
TessJob(name: "buildClass", model: "claude-sonnet-5-5", maxTokens: 900, effort: "low", timeout: 20,
        instructions: TessVoice.house + BuildClassRules.text, output: BuildTools.oneOf5,
        writeTools: ["proposeClass", "proposeFields", "proposeList"], memory: [], priority: .recipe, toolChoice: .auto)
```

Sonnet runs on auto, as Sonnet refuses a forced tool (`claude-client.md` section 2); a reply with no tool call is `.noLine` and the phone says "I couldn't make that into something. Try it shorter?". **The write tools are pending**: they run as a ghost (`pending: true`), nothing commits without his tap and there is **no 2 s auto-commit** for schema.

## 4. The pack: what leaves the phone

| Leaves | Never |
|---|---|
| The sentence as he typed or said it (600 characters at most, the capture cap) | Any object: titles, values, notes, list names, list items, sets, health, memory lines |
| The catalog: class names with parent, traits, own field names, kinds, units, choice options; the alias table (about 2,000 tokens) | Counts, dates, the op log, the handle map |
| Tool schemas and stable instructions (cached prefix) | The key, in any form |

Order on the phone before any call: key and key-shaped text refused (as `TessRouter`, first); **local pre-match** (research rules 1 and 2: an existing class or alias opens with no call; list names are matched on the phone and never sent). **Money, body and secret words in the sentence** (for example "track my expenses", "track my blood pressure"): the capture-miss ruling that lets a whole phrase go ("all but the key", Oct 17) is about capture misses, not this job. Default [proposed, needs Product]: such a sentence **stays on the phone** and opens the offline shapes (Tracker, List, Log) with the name filled in, with no call. The class catalog itself can hold his own class names (for example "Therapy notes" if he made one): classes marked private never enter the pack (the same `ObjectPrivacy.isPrivateTitle` check as everywhere).

## 5. Validation and the ghost (summary; the table is in the research page section 4)

`ClassProposalValidator` is pure engine code, runs inside `apply`, and returns one plain reason line for every rejection (name unique, reserved names, name shape, kinds valid, no formula injection, field limit 8, parent exists and not a composition part, refs resolve, traits compatible, units and options, view valid, size caps). A rejection goes back to Claude as the tool error for **one** retry; a second shows the reason to him. The ghost is the class's own future page, faint, with preview-only samples that are never written (real names from the sentence become real objects in the same group). Accept is one tap; dismiss discards everything; undo is one tap after.

## 6. Budget against the $50 cap

Per call: 2,500 in (catalog 2,000 + sentence + instructions) / 700 out (A) = 5,000,000 + 7,000,000 = 12,000,000 n$ = **$0.012**. A retry or a `clarify` round adds the same again.

| Case | Calls | Cost |
|---|---|---|
| Typical: 4 builds a month, 1.3 calls each | 5 | **$0.06** (0.1%) |
| Capped worst: 20 build attempts a month, 3 calls each | 60 | **$0.72** (1.4%) |
| Runaway without caps: a bug looping one retry per tick | unbounded | $0.012 each; 4,000 calls is the $50 cap |

Caps [proposed, in code]: **10 sentences a day, 20 a month**, at most 2 calls per sentence (one retry), at most 2 pending schema records at once (research table). Build is user-initiated, so a runaway needs a bug, not a habit; the caps make that bug cost at most $0.72 a month. Step-aside at $40: **does not apply** (a build is something he asked for; it runs to $50, like capture, plan, recipe and questions).

**Model.** The roadmap and `research/ai-and-tess.md` item 10 say Opus 5.5 for "build me an app"; the research page chose Sonnet 5.5 at about $0.01. I recommend Sonnet 5.5 low. Opus has **no price row** in the ledger, and an unknown model string prices as 0 so the cap cannot see it (`model-effort-cost-table.md`, risks): if Opus is wanted, a price row is added first, with a test that every job's model is a key of `prices`.

## 7. Review switch (off by default)

Name: **Build with Tess** under the Review group "Tess asks Claude". Off (default, today's behavior): "Tess won't turn a sentence into a new kind of thing; Start from a shape still works." On: "Say what you want to track; she shows it as a draft you accept." Needs the master switch and a key; falls back to Start from a shape offline, capped or off. Row keeps its value through master Off and Remove key. The **sentence-and-catalog pack is visible** in "What was sent" like any job.

## 8. Tests (none needs a key)

`buildPackHoldsCatalogAndSentenceAndNoObject`; `privateClassNeverEntersThePack`; `moneyBodyOrSecretSentenceStaysOnThePhone`; `exactClassOrAliasOpensWithNoCall`; `listNamesAreMatchedOnThePhone`; `proposalWithFormulaIsRejectedWithItsReasonLine`; `ninthFieldIsRejected`; `ghostNeverAutoCommits`; `dismissLeavesNoTrace`; `undoAfterAcceptRemovesClassFieldsViewAndRealObjects`; `undoWithForeignObjectReturnsConflict`; `buildStopsAtTwoCallsPerSentenceAndTwentyAMonth`; `switchOffMakesNoRequestAndOpensShapes`; `everyJobModelHasAPriceRow`.

## 9. Order and dependencies

A1 first (schema ops with retire inverses), then A2 (validator and tools), A3 (route and the 15 sentences in the free eval harness; the **live** run of the 15 plus 25 waits for Kaushik's ask), A4 (ghost class page, Builder B with Design), A5 (evolve and delete). Home tiles and the remix editor are outside this page.

## 10. Rulings I need

1. Sonnet 5.5 low (my recommendation), not Opus 5.5?
2. Sentences with money, body or secret words stay on the phone and open Start from a shape?
3. Caps of 10 a day and 20 a month?
