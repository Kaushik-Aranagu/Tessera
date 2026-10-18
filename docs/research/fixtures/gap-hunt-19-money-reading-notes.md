# Gap hunt 19: Money, Reading, Notes and body weight under Low Power and VoiceOver (static read, origin/master 8427b08d, Sun Oct 18 PT)

For: Builder A (Money, Reading, body weight, shared PaintKey and haptics), Builder B (Notes, the shared Tess line), Core (engine, privacy), Design (specs), QA. Docs only; nothing was built or run (no Swift toolchain), so "shown" means what the code draws and "inferred" marks a reading I did not see executed. Method and row format follow `gap-hunt-home-settings.md` (merged, #947) and `gap-hunt-17-groceries-lists.md` (branch `claude/research-gh17`, **not on master**; every row that points at a GL id rests on that unmerged file).

**Gap ids.** The highest id found by grep over `docs` on master and over `/mnt/project-files/tessera` is **G606** (gap hunt 18, `gap-hunt-home-settings.md`); gap hunt 17's hunt ids stop at G266 and its rows use GL01 to GL62. New gaps here are **G607 onward**; every row also has an id **MN01 onward** (Money), **RD01 onward** (Reading), **NT01 onward** (Notes), **BW01 onward** (body weight) for test names. If another open PR has taken G607 or above, renumber at merge (open question 8).

Status words: **traced** means I read the line and it does what the row says; **inferred** means the row follows from a ruling or from code I did not read in full; **gap** means master has nothing for it or contradicts the ruling. **not built** is a gap whose screen does not exist: rows resting on the approved ship lists (`docs/product/ship-list-m5-money.md`, `ship-list-m5-reading.md`) are specs to test when the screen lands. **(unmerged)** marks a row resting on a PR or file that is not on master: GL rows (gh17 file), #890 (Core's one private-text function), and the G229 named-action-only key (Builder A).

Rulings used (decisions.md in the project mirror; stamps from 1:41 PM Oct 17 ran 1 to 2 hours ahead of PT and are read through the CLOCK CORRECTION entry, line 937): D4 and D6 (Reduce Motion keeps Tess at full opacity and pigment); D5 and 8:20 PM A (Low Power = Reduce Motion, 150 ms crossfade, soul keeps her own Low Power form); G223 and 9:18 PM items 2 and 3 (Low Power keeps his haptics and `timeUp`; Tess-initiated landings follow quiet hours 23:00 to 07:00); 8:18 PM (drum ticks capped at 25 per second, the landing tick always plays); G229 and G258 (finish and clear keys named-action-only for VoiceOver); G250 (one shared Tess line with UNDO announced to VoiceOver); G257 (bare words never mask; money only with an amount or sign); G102 and the 4:25 PM follow-up (no tap-to-reveal anywhere); 7:39 PM (private rows, Private note included, draw at 100% ink, no tell); 4:50 PM Oct 17 and 5:58 PM (a note is "Private note" only when flagged or holding secret, money or body words, with no per-titleWord check); clocks read "8:30 pm".

## 1. State of master for these areas

| Area | What master has today | Evidence |
|---|---|---|
| Money | **No screen and no engine.** No `Features/Money`, no `TesseraCore/.../Money`, no `Spend` class. What exists is the wall: `PrivateFacts.isMoneyShaped` (a sign, a money word plus an amount, or a two-decimal amount) and `moneyWords`. | `ls Features`; `TesseraCore/.../Tess/PrivateFacts.swift:25-52` |
| Reading | **No screen and no engine.** No `Features/Reading`, no `Book` class. Only the approved ship list. | `ls Features`; `docs/product/ship-list-m5-reading.md` |
| Notes | `NotesView` (index, writing line, rows) and `NoteEditor`; reached from Home's "Notes" entry word. `CreateNote` and `EditNote` in the engine. | `Features/Notes/NotesView.swift`, `NoteEditor.swift`; `HomeSpatialView.swift:346, 360`; `TesseraCore/.../Notes/Notes.swift:84-199` |
| Body weight | Engine-only: a weigh-in is a private note read by `BodyWeight.kilograms`; no entry screen, no Review line. | `TesseraCore/.../Tess/BodyWeight.swift:6-83`; grep `weight` in `Features/Home/Review*.swift` finds only `fontWeight` |
| Motion and haptics | Notes uses `withTesseraAnimation` and `.tesseraAnimation` throughout (good), so the Low Power fix is the shared one (HS03). No haptics call in Notes at all. | `NotesView.swift:84, 86, 122, 142, 168, 208`; `NoteEditor.swift:113, 139, 145, 175`; grep haptics in `Features/Notes`: none |
| VoiceOver in Notes | Labels on both fields, header on the title, combined row with a hint, hidden decoration. No live announcement and no named actions. | `NotesView.swift:74, 158, 216-217, 229`; `NoteEditor.swift:60, 72, 103` |

## 2. Top 10 gaps, ranked

Ranked by harm to him first (a leak or a lost thing), then by how many surfaces the fix touches.

| Rank | Gap id (row) | Gap | file:line | Owner |
|---|---|---|---|---|
| 1 | G607 (NT01) | `EditNote` only checks secret words. A plain note edited to "paid 40 for the visit" or "82 kg this morning" is never flagged private, so it keeps its raw title in the list and on Home and links its @ mentions; `CreateNote` flags the same text. Also makes a weigh-in typed into an old note invisible to `BodyWeight`. | `Notes.swift:116` vs `:172` | Core |
| 2 | G608 (NT02) | A note written in the writing line, edited in the editor or deleted gives no Tess line, no UNDO and no VoiceOver announcement; the engine call is made directly. | `NotesView.swift:118-127`; `NoteEditor.swift:162-183` | Builder B |
| 3 | G609 (NT03) | "Delete note" is one tap with no hold, no confirm and no UNDO, then dismisses; a mis-tap on the last control on the page loses a note. | `NoteEditor.swift:95-103, 178-183` | Builder B |
| 4 | G610 (NT04) | Pasting several lines into the writing line turns the newlines into spaces and files one flat line; the first-line/rest shape is lost and the note is cut at 60 characters for its title. | `NotesView.swift:152-156` | Builder B |
| 5 | G611 (NT05) | The row's visible "3 h", "12 min", "now" is what VoiceOver reads (the row is `.combine`); the spoken form exists (`when(spoken:)`) and is used only by the context line. | `NotesView.swift:204, 216` | Builder B |
| 6 | G612 (NT06) | Row title is `lineLimit(1)` with a `fixedSize()` time beside it; at accessibility sizes the title truncates to a few letters and the preview is lost. | `NotesView.swift:193, 209` | Builder B |
| 7 | G613 (BW01) | No body weight entry or Review line is built (ruled 1:23 PM Oct 16 and 8:07 PM Oct 17: "weight down 0.4 kg", Siri "Body weight logged."); the only way in is a private note. | `BodyWeight.swift:3-5`; `Intents.swift:166-169` | Builder A |
| 8 | G614 (MN01) | Money has no screen; its wall is built. The first screen needs the private, VoiceOver, drum-haptic and Low Power rules below in its definition of done, not as follow-ups. | `ship-list-m5-money.md` | Builder A + Core |
| 9 | G615 (RD01) | Reading has no screen. Its finish and drop keys are finishing keys: they must be named-action-only from day one (G229), and book titles pass through the one private-text function. | `ship-list-m5-reading.md` | Builder A + Core |
| 10 | G616 (NT07) | The Notes zoom transition ignores Low Power and Reduce Motion (ruled: 150 ms crossfade). Same fix as HS04; this row is the Notes test. | `NotesView.swift:18` | Builder B |

## 3. Rows

Columns: id, finding (file:line), expected outcome, status, owner, Swift Testing name. Existing rows are referenced, not repeated: HS02 to HS05 and GL12 (shared PaintKey named-action-only key, Low Power as Reduce Motion, zoom crossfade, haptic gate and quiet hours), HS15 and GL19 to GL25 (the shared Tess line announced to VoiceOver), HS06 (soul keeps full opacity), GL07 (no tap-to-reveal).

### 3a. Notes: privacy and masking

| Id | Finding (file:line) | Expected outcome | Status | Owner | Swift Testing name |
|---|---|---|---|---|---|
| NT01 | G607. `CreateNote` uses `isPrivateText` (secret words, money, body facts) at `Notes.swift:116, 132-134`; `EditNote` tests `SecretWords.mentions` only (`:172`). | Editing a plain note so it holds money (an amount or sign) or a body fact flags it private, sets the title to "Private note", clears its @ links and keeps the words in the body; the same string gives the same answer through `CreateNote` and `EditNote`. Bare "rent" or "dentist" never flags (G257, 4:50 PM). | gap | Core | `editNoteFlagsMoneyAndBodyTextPrivate`, `editNoteLeavesBareWordsPlain` |
| NT02 | `CreateNote.summary` returns "Private note" for a walled body (`Notes.swift:142`); the list and Home then show the stored title. | A walled note reads "Private note" in the index row, the Home line, the receipt and UNDO; one function (G105, #890 unmerged). | traced for the list; Home receipt rests on #890 (unmerged) | Core | `walledNoteReadsPrivateNoteEverywhere` |
| NT03 | Private row has no preview line (`NotesCopy.preview` returns "", `NotesView.swift:186, 195, 289-292`); a plain row has two lines. | Ruling 7:39 PM: a private row has no tell. Either the row keeps one height for both or Product accepts the height as the cost of hiding the preview (open question 1). Ink is already 100% (no dimming code in the row). | traced for ink; gap for height | Design + Builder B | `privateNoteRowDrawsAtFullInk`, `privateNoteRowHeightMatchesNeighbours` |
| NT04 | No tap-to-reveal in Notes: the index never shows a private body; the editor shows it only after the row is opened (`NoteEditor.swift:119-127`). | Opening a private note is opening it, not a reveal (the title stays "Private note", the editor holds his words); no "Show" control exists anywhere in `Features/Notes`. | traced; ruling reading in open question 2 | Builder B | `notesHaveNoRevealControl` |
| NT05 | A private note is never an @ mention's target (`Notes.swift:42-46`). | "@Private note" links nothing and a private note stores no links. | traced | Core | `privateNoteIsNeverMentionTarget` |
| NT06 | Two equal-title plain notes (two "Groceries to remember") are indistinguishable by row title alone. | Not a masking issue; rows differ by preview and time. Noted only so VoiceOver label (NT10) carries the time. | inferred | Builder B | `rowLabelIncludesTimeAsWords` |

### 3b. Notes: VoiceOver, actions, announcements

| Id | Finding (file:line) | Expected outcome | Status | Owner | Swift Testing name |
|---|---|---|---|---|---|
| NT07 | G616. `.navigationTransition(.zoom)` with no reduced branch. `NotesView.swift:18` | Reduce Motion or Low Power: 150 ms crossfade (HS04). | gap | Builder B | `notesZoomIsCrossfadeWhenReduced` |
| NT08 | G608. `write()` calls `model.engine.perform(CreateNote…)` and `model.touch()` only. `NotesView.swift:118-127` | A written note says one shared Tess line ("Noted." or "Private note.") with UNDO 10 s, announced to VoiceOver once (G250, HS15, GL25); UNDO removes the note and puts the text back in the writing line. | gap | Builder B | `writingANoteSaysItWithUndo`, `writingANoteAnnouncesOnceToVoiceOver` |
| NT09 | G609. `delete()` runs `DeleteObject` and `dismiss()`. `NoteEditor.swift:95-103, 178-183` | Delete is hold-to-finish like the other finishing keys with the named action "Delete note" only (G229, HS02); a Tess line "Note deleted." with UNDO 10 s (GL17 pattern); VoiceOver gets the announcement, focus returns to the index row above. Named-action-only for delete is not yet ruled: decisions.md ~line 1011 covers finish and clear keys only (open question 5). | gap (named-action-only part open) | Builder B (screen) + Builder A (key) | `deleteNoteIsNamedActionOnly`, `deleteNoteOffersUndoForTenSeconds` |
| NT10 | G611. Row is `.combine` of title, preview and the short `when` ("3 h", "now", "Tue", "14 Oct"). `NotesView.swift:204, 216` | Label reads title, then the spoken form ("3 hours ago", "just now", "Tuesday", "14 October"); a private row reads "Private note, 3 hours ago" and nothing of the body. | gap | Builder B | `noteRowLabelUsesSpokenWhen`, `privateNoteRowSpeaksNothingOfBody` |
| NT11 | The row hint "Opens the note" is set. `NotesView.swift:217` | Keep. A private row reads the same hint (no tell). | traced | Builder B | `noteRowHintIsSameForPrivate` |
| NT12 | The hero "Notes" has `.isHeader`; the context line has none (fine) and reads "2 notes, the latest 12 minutes ago". `NotesView.swift:65-74` | Traced. The context line is announced on arrival only if it changes (Home caps do not apply to Notes). | traced | Builder B | `notesHeaderIsHeaderTrait` |
| NT13 | A refused Claude key is shown in the context line only (`NotesView.swift:65, 82-87`; `NoteEditor.swift:37, 134-141`). | The refusal is also announced to VoiceOver once ("That looks like a Claude key. It goes in Settings." wording per `claudeKeyLine`); no key text is ever read back. | gap | Builder B | `refusedKeyIsAnnouncedNotRead` |
| NT14 | Editor fields: "First line" and "Note text" labels, no value or hint. `NoteEditor.swift:60, 72` | Traced. Add a hint to "Note text": "Return in the first line moves here" is not needed; keep labels only. | traced | Builder B | `noteEditorFieldsAreLabelled` |
| NT15 | The decorative `PaintDab` is hidden (`Paint.swift:169`); the writing line's hairline fill has no element. | Nothing unlabelled is focusable in the index; swipe through the page lands on: context, hero, "New note" field, rows. | traced for the dab; inferred for the order | Builder B | `notesIndexFocusOrderIsContextHeroFieldRows` |
| NT16 | Links in the editor are static `HStack` text, not buttons (`NoteEditor.swift:79-88`). | Decided later; today a link row is read as text, which is correct while nothing opens. If links open objects, they become buttons with a label "Linked to Bench Press". | traced | Builder B | `noteLinkRowsAreReadAsText` |

### 3c. Notes: Low Power, Reduce Motion, haptics, Dynamic Type, clocks

| Id | Finding (file:line) | Expected outcome | Status | Owner | Swift Testing name |
|---|---|---|---|---|---|
| NT17 | Every Notes animation goes through the policy, none raw (`NotesView.swift:84, 86, 122, 142, 168, 208`; `NoteEditor.swift:113, 139, 145, 175`). `.entrance` is shared (`Editorial.swift:84`). | Low Power takes the reduced branch once HS03 lands; no Notes-local change. The row insertion `.push(from: .top)` transition (`NotesView.swift:100`) is also reduced to opacity. | traced for the policy; gap for the push transition under Reduce Motion | Builder B | `noteInsertTransitionIsOpacityWhenReduced` |
| NT18 | The new-note time arrives cobalt and dries over `Motion.dry`. `NotesView.swift:207-208` | Under Reduce Motion or Low Power the time is inkSecondary at once (no wash). | inferred (depends on `Motion.dry(reduceMotion:)` returning nil) | Builder B | `newNoteTimeDriesInstantlyWhenReduced` |
| NT19 | No haptics in Notes: no tick on write, none on delete. | A write plays his landing tick (his touch, so Low Power keeps it); an autosave or a Tess-initiated change plays none (quiet hours, HS05). Nothing else buzzes. | gap | Builder B | `writeNotePlaysLandingTickInLowPower` |
| NT20 | Autosave 800 ms after typing stops, plus on leave. `NoteEditor.swift:152-160` | Traced; no timer-driven animation, nothing to reduce. | traced | Builder B | `autosaveHasNoAnimationCost` |
| NT21 | G612. `lineLimit(1)` on title and preview, `fixedSize()` on the time. `NotesView.swift:193, 199, 209` | At accessibility sizes the row stacks (time under the title), the title wraps to three lines and the preview to two; Dynamic Type never hides a title. | gap | Builder B | `noteRowStacksAtAccessibilitySizes` |
| NT22 | `Theme.voice(size: 18)` is `relativeTo: .body` (`Machined.swift:225-227`), so it scales. | Traced. | traced | Builder B | `noteRowPreviewScalesWithDynamicType` |
| NT23 | The editor's body has `minHeight: 180` and a fixed `-5` inset (`NoteEditor.swift:69, 71`). | Inset scaling with type is a polish item; the field must not clip at AX5. | inferred | Builder B | `noteEditorDoesNotClipAtAX5` |
| NT24 | `NotesCopy.when` uses his 04:00 day (`NotesView.swift:264-270`). | Traced: a 23:30 note is "2 h" at 01:30. Clock times, where shown, read "8:30 pm", and the Day log keeps "07:10" (7:34 PM ruling); Notes shows no clock. | traced | Builder B | `noteWhenUsesHisDay` |
| NT25 | G610. Writing line replaces every newline with a space and submits (`NotesView.swift:152-156`); `CreateNote.firstLine` cuts at 60 characters (`Notes.swift:136-139`). | A multi-line paste keeps its lines: the first line becomes the title and the rest the body; Return still submits a one-line note. | gap | Builder B | `pastedLinesKeepTheirShape` |
| NT26 | The writing line `TextField` has `.submitLabel(.done)` and a label "New note". `NotesView.swift:148, 158` | Traced. | traced | Builder B | `writingLineHasLabelAndDone` |

### 3d. Body weight (engine only)

| Id | Finding (file:line) | Expected outcome | Status | Owner | Swift Testing name |
|---|---|---|---|---|---|
| BW01 | G613. No weight entry; weigh-ins are private notes. `BodyWeight.swift:3-5, 18-32` | Entry, a Review line ("weight down 0.4 kg", never coloured) and "Body weight logged." for Siri/Tess; the number is never spoken in a Tess line, a receipt or UNDO. | not built | Builder A | `bodyWeightLogsWithoutSayingTheNumber` |
| BW02 | A weigh-in must be a private note to count (`BodyWeight.swift:23`). With NT01 open, a weigh-in typed in a plain note, or an edit that adds the number to one, is never read. | After NT01, every note holding a weigh-in is private, so every weigh-in is read; test both create and edit. | gap (rests on NT01) | Core | `editedNoteWithWeighInIsReadByBodyWeight` |
| BW03 | Weigh-ins sort by `createdAt` (`BodyWeight.swift:24`). | Ruled 1:23 PM Oct 16: the first weigh-in after 4 am counts when Health has two; for notes, a backdated "on" note (`CreateNote.on` sets `createdAt`, `Notes.swift:125-127`) must not beat a newer one. | inferred | Core | `backdatedWeighInDoesNotBeatNewest` |
| BW04 | Cache is keyed on `context.revision` (`BodyWeight.swift:10-14`). | Traced: an edit or delete of the newest weigh-in changes the answer on the next read. | traced | Core | `bodyWeightCacheFollowsRevision` |
| BW05 | Siri says "Private note, kept." for "weighed 82.2" (`Intents.swift:166-169`); R2 ("Body weight logged.") ruled open at 4:50 PM Oct 16. | Wording changes with the entry (BW01); until then a spoken number never comes back. | traced for the wall; gap for wording | Builder A | `siriWeighInNeverSaysNumber` |
| BW06 | A lift note ("squat 140 kg") is never a weight (`BodyWeight.swift:35-37, 62-66`). | Traced; keep the exercise-name check. | traced | Core | `liftNoteIsNotAWeighIn` |

### 3e. Money (not built; the rules to test when the screen lands)

| Id | Finding (file:line) | Expected outcome | Status | Owner | Swift Testing name |
|---|---|---|---|---|---|
| MN01 | G614. No `Spend` class or screen (`ship-list-m5-money.md` slices 1 to 8). | The first screen ships with the rows below as its definition of done. | not built | Builder A + Core | (suite `MoneyScreenAcceptance`) |
| MN02 | Money mask: a sign, or a money word with an amount, or an exact two-decimal amount (`PrivateFacts.swift:36-52`). | A spend line is money by definition; the question is whether the Money screen masks its own rows (open question 3). Elsewhere (Home, Notes, Groceries, lists, export) "Spent 12.40, lunch" reads "Private ..." per G105. | inferred | Core + Design | `spendReceiptMaskedOutsideMoneyScreen` |
| MN03 | Bare words never mask (G257): "rent", "tip", "pay", "balance" alone. `PrivateFacts.swift:26-31` lists them in `moneyWords`, masking needs an amount (`:48`). | A category word or a book/note/list title of "Rent" stays raw; "Rent 1850" and "rent $1,850" mask. | traced for `isMoneyShaped` | Core | `bareMoneyWordsStayRaw` |
| MN04 | Amounts are stored as typed and never summed across currencies (`ship-list-m5-money.md`). | VoiceOver reads each amount with its currency word ("12 pounds 40", "8 euros"), not the symbol or the raw digits; a typed-only amount reads as typed. | not built | Builder A | `amountSpeaksWithCurrencyWord` |
| MN05 | The month line is "October, logged: 41 spends · groceries 312.40 · lunch 86.10"; the word is "logged", never "you spent". | Exposed as one element with a spoken form ("41 spends logged in October. Groceries 312.40, lunch 86.10"); no chart, no red, no colour on direction. | not built | Builder A | `monthLineSpeaksAsSentence` |
| MN06 | Money dial / amount drum: ticks capped at 25 per second, landing tick always plays (8:18 PM). | Under Low Power the drum keeps his ticks (his touch); the cap and landing tick hold; under VoiceOver the drum is adjustable (swipe up/down by the step, label "Amount", value "12.40"). | not built | Builder A | `amountDrumIsAdjustableWithValue`, `drumTicksCappedAt25PerSecond` |
| MN07 | Logging a spend by hold or by Return. | A key that logs is not a finishing key (double tap works); a delete of a spend is named-action-only with UNDO 10 s (G229, GL17 pattern). | not built | Builder A | `deleteSpendIsNamedActionOnly` |
| MN08 | Receipts and UNDO: "Spent 12.40, lunch" (op summary). | One shared Tess line with UNDO announced to VoiceOver (HS15, GL25); at 23:00 to 07:00 a Tess-initiated receipt is silent in haptics (HS05). | not built | Builder A + Builder B | `spendReceiptUsesSharedLine` |
| MN09 | Amount fields at AX sizes; numbers do not wrap mid-figure. | Row stacks (amount above word); `Decimal` formatting is locale-correct, no fixed `.2f`. | not built | Builder A | `spendRowStacksAtAccessibilitySizes` |
| MN10 | Spend rows draw at 100% ink; no dimming of "private" spends; no tap-to-reveal anywhere (G102). | No reveal control; masked spends read "Private spend" the same weight as neighbours. | not built | Design + Builder A | `privateSpendRowDrawsAtFullInk` |
| MN11 | Capture: "spent 12.40 lunch" goes to the ghost row on the phone, never to Claude (`docs/research/fixtures/money-body-wall.md`, MU2). | Traced upstream by Core's capture tests; the screen adds no Claude call. | inferred | Core | `moneyCaptureNeverReachesClaude` |

### 3f. Reading (not built; rules to test when the screen lands)

| Id | Finding (file:line) | Expected outcome | Status | Owner | Swift Testing name |
|---|---|---|---|---|---|
| RD01 | G615. No `Book` class or screen (`ship-list-m5-reading.md` slices 1 to 5). | The first screen ships with the rows below as its definition of done. | not built | Builder A + Core | (suite `ReadingScreenAcceptance`) |
| RD02 | A "Finished" key and a "Set aside" key end a process. | Named-action-only for VoiceOver (G229, HS02); double tap speaks the hold hint; UNDO 10 s. "Start reading" and "Resume" keep double tap (GL14). | not built (rests on the G229 key, unmerged) | Builder A | `finishBookIsNamedActionOnly` |
| RD03 | Resume point is the page; next step reads "Dune, p 142". | VoiceOver reads "Dune, page 142"; the page control is adjustable (label "Page", value "142"), step by 1, by 10 on a rotor-style fast swipe if Design agrees. | not built | Builder A | `pageControlIsAdjustableWithValue` |
| RD04 | A book title goes through the one private-text function (G105, #890 unmerged). A sign alone masks money: "$100M Offers" would read "Private book". | Product decides whether a leading sign inside a title masks (open question 4); "Atomic Habits", "The Body Keeps the Score" and "Dr. Seuss" stay raw (G257). | inferred (unmerged #890) | Core | `bookTitleUsesOnePrivateTextFunction`, `bareBodyAndDoctorWordsInTitlesStayRaw` |
| RD05 | A book opens suspended and sits in What's running; it never takes Now. | Starting one announces "Dune, suspended" or the ruled wording once; no Tess-initiated haptic; quiet hours silence any Tess nudge (23:00 to 07:00). | not built | Builder A | `startingBookDoesNotTakeNow`, `readingNudgeSilentInQuietHours` |
| RD06 | Finishing a book shows its review line; no counts, goals or streaks. | No count is spoken or drawn ("12 books"); the review line is read as static text. | not built | Design | `readingShowsNoCounts` |
| RD07 | Reading screen motion. | Everything through `MotionPolicy`; zoom from the Home door is a 150 ms crossfade under Low Power (HS03, HS04); the page turn follows the page-turn fixtures. | not built | Builder A | `readingMotionFollowsPolicy` |
| RD08 | Dynamic Type at AX sizes; long titles. | Title wraps to three lines; page and author stack beneath it; no fixed row height. | not built | Builder A | `bookRowStacksAtAccessibilitySizes` |
| RD09 | Private book rows draw at 100% ink; no reveal (G102). | Same as MN10. | not built | Design | `privateBookRowDrawsAtFullInk` |

## 4. Counts

Gap ids G607 to G616 are the ten ranked rows. Row counts by status (mixed-status rows counted under their first word): traced 18, inferred 7, gap 10, not built 17, total 52. Rows resting on unmerged work: NT02 (Home receipt, #890), RD02 (G229 key), RD04 (#890), and the GL12, GL14, GL17, GL25 references.

## 5. Open questions for Product

1. A private note row has no preview line, so it is one line shorter than its neighbours. The 7:39 PM ruling says no tell. Should every Notes row keep a fixed two-line height (a blank second line for private ones), or is the shorter row accepted? Proposed default: fixed height.
2. Opening a private note in the editor shows its words with no further tap. Read with G102 this is not a reveal (the title stays "Private note" in the list and on Home). Confirm, or does Product want the editor to ask for Face ID?
3. Does the Money screen mask its own spend rows? The default read here is no: the Money screen is his own ledger and shows amounts; every other surface (Home, receipts, export, Notes, lists) masks per G105. Confirm.
4. Does a currency sign inside a book or recipe title ("$100M Offers") mask? `isMoneyShaped` says yes because any sign masks. Proposed: accept, and test the rule once.
5. A deleted note (NT09, and the same question for MN07): hold key plus UNDO (default here) or tap plus UNDO only? The finishing-key family is hold, but a note is cheap to undo. Also still open: whether delete is named-action-only for VoiceOver at all, because the G229 ruling (decisions.md ~line 1011) covers only finish and clear keys, and Design's amendment limits it to hold keys. Until Product rules, NT09 and MN07 keep named-action-only as the proposal, not a ruling.
6. Pasting several lines into the writing line: keep the lines (default here) or keep today's single flat line?
7. Notes make no haptic at all today. Is a landing tick on write wanted (default here), or does Notes stay silent?
8. Gap ids: I found no id above G606 on master or in the project mirror, but gap hunt 17's unmerged branch and any open research PR may also have taken G607 onward. Renumber at merge if so. GL and HS rows referenced here are unchanged either way.
