# The private-field mask: fixture rows PM1 to PM36 (Core 0ai rider, Research BH and BR)

*Research, Fri Oct 16, 2026. For Core 0ai (the one engine wall), Builder B (the page), QA (the riders gate). Read by hand on origin/master 64ffb93 (Merge #558). Nothing was built or run. Every value is made up: hunter2, tacocat and 4417 are placeholders. Rows PM21 to PM36 (workout notes, decisions 5:07 pm) added Oct 17 by Research BR, read on origin/master b41695d (section 3b).*

**The ruling (Product, 2:45 pm, decisions.md line 7).** The generic object page prints every field (`ObjectPage.swift:342-360`, `PropertyList`), so a private Tess memory's words show in plain text. Core 0ai adds a private-field mask: any object flagged private shows its class's private label ("Private note", "Private task", "Private memory") with its fields hidden. It covers the generic page, `PropertyList` and the class page's "newest" row. Research writes these rows; QA runs them in the riders gate.

## 1. What master does today, per route

All paths are `Features/Objects/ObjectPage.swift` unless named.

| Route | How you get there on master | What it prints | Leak? |
|---|---|---|---|
| **G. Generic page** (`InstanceBody`, :216-275) | Any `.object(id)` that isn't an exercise, plan or routine (:10-29) | Hero `object.title` (:227), class line `object <title as identifier> : <Class>` (:228), the `notes` field as body text (:232-234), then `PropertyList` (:237), Contents (:240-252), Linked from (:254-267) | **Yes** for a private memory or task: the title is the content. A private note's title is already "Private note" (`Notes.swift:117`), but its Body still prints (row P). |
| **P. PropertyList** (:342-422) | Under the hero on every generic page and class page | Every effective field except `notes` (:348): name (:367), then the value as text (:397-399, :412-420), a ref's target title (:387) or a class name (:392). Nothing checks `isPrivate` | **Yes**: a note's Body row prints the body; a memory's Rule row prints the rule; "Private yes" and "Stays on this phone yes" print as rows (:417) |
| **L. Linked from** (:254-267) | A workout's generic page, for a memory whose `evidence` links that workout (`TessMemory.swift:256-259`, `:675`) | One `ObjectRow` per source, titled `source.title` (:261); VoiceOver hint "Opens <title>" (`ObjectHandle.swift:77`) | **Yes**: a private memory's line is the row title |
| **C. Class tree** (`ClassBody`, :62-147) | The breadcrumb on any object page (:312-326) up to "Memory", "Note" or "Task", or Thing then Subclasses (:105-118) | The class name, its class line, the prototype's `PropertyList` (:89; prototype is the object titled with the class name, `AppModel.swift:483-485`), History and Used in for exercises only | **No** today: there is no list of objects and **no "newest" row** on master. The newest row arrives with the SideHost glance (Core 0ak, screens-inventory-check PL3) |
| **S. Search** | None on master: no `searchable` and no Spotlight index in `App/` or `Features/` | | n/a |

Where each test object's generic page is reached on master:

- **Note:** Review, tap today, tap the note's line: `ReviewWeek.swift:358-362` opens `.object(id)` from the Day log line (`DayStory.swift:302`, `:344-349`). The note's own page in Notes is `NoteEditor`, not the generic page, and stays as it is.
- **Task:** a Home queue row (`HomeQueue.swift:263`) or the Now hero (`NowPage.swift:217-220`).
- **Memory:** no Memory screen exists in `Features/` on master. Its only way in is row L on a workout's page (a workout opens from Review, `ReviewPage.swift:269`).

How private is stored on master:

| Class | Field | Set by |
|---|---|---|
| Note | `isPrivate` "Private", bool (`SystemCatalog.swift:220`) | `CreateNote` when asked or when `SecretWords.mentions(text)` (`Notes.swift:115-121`); `EditNote` keeps it and turns a plain note private when a secret word is added (`Notes.swift:163-177`). Siri's walled phrases save private notes (`Intents.swift:168`). |
| Memory | `isPrivate` "Stays on this phone", bool, default false (`SystemCatalog.swift:264`) | `RememberFact` for a body word or a health word (`TessMemory.swift:206-208`, `:229`, `:255`); forgotten-line hash entries (`TessMemory.swift:558-560`). Noticed lines are written public (`:671`). A told line with a secret word is refused (`TessMemory.swift:142-143`), so the PM1 memory is seeded through the store (it stands for a restored or older entry). |
| Task | **none**: the Task class has no private field (`SystemCatalog.swift:201-212`) | Privacy is read from the title only: `PrivateFacts.isPrivateTitle` (`PrivateFacts.swift:12-14`), used by Tess's receipt (`TessCaptureEngine.swift:300-301`) and Siri (`Intents.swift:174`). A bare medicine name with no number ("Take Advil") is not walled until Core 0ac slice 2 (decisions 2:40 pm, item 2). The 2:22 pm ruling (item 2) titles a medicine reminder "Private task"; that is not on master. |

**One check for 0ai (Research's suggestion, Core decides).** The mask reads one helper, for example `ObjectPrivacy.isPrivate(object)`: true when the object's `isPrivate` value is true, or its title is "Private note" or "Private task", or `SecretWords.mentions` holds for its title or a note's body (an old note from before #422, PM16), or, for a task, `PrivateFacts.isPrivateTitle(title)`. Adding an `isPrivate` field to Task would change the catalog, and the riders pin stays Catalog v9 (`next-build-v9r.md` section 3, V0), so a stored task flag is not for this pin.

**What "masked" means in every row below.** The page shows the breadcrumb (class names only), the hero as the class's private label, and a class line built from the label (`object privateMemory : Memory`, as a private note's reads today). There is no notes line, no "Properties" heading, no field names, no field values, no Contents, no Linked from, no Actions, and no count that hints at what is inside (no "8 fields", no "from 14 workouts"). VoiceOver reads the same: the label, the class line, nothing else. A masked object named on another page (row L, the newest row, a ref handle) reads its label, and its hint is "Opens Private memory".

## 2. The objects

Seeded on the Simulator over `-demo -demoTime 18:10 -resetDemo` (see `walls-ui-test-spec.md` section 11 for the seed flag). Times are the demo day.

| Object | Class | Stored | Private? |
|---|---|---|---|
| **O1** door code memory | Memory | title "Your door code is 4417", `rule` "door code is 4417", `kind` told, `area` about, `isPrivate` true, `evidence` today's Push A workout | yes (flag) |
| **O2** shoulder memory | Memory | title "Your left shoulder gets sore after presses", through `RememberFact` (body word, so private, `TessMemory.swift:206-208`); no rule, no evidence | yes (flag) |
| **O3** wifi note | Note | typed on the Notes line: "wifi password is hunter2"; no private ask, so `SecretWords` forces it (`Notes.swift:115-121`) | yes (forced) |
| **O4** Advil note | Note | Siri Add a Task "took advil 400mg" (private note, `TessTests.swift:241`); no secret word in it | yes (flag only) |
| **O5** Advil task | Task | Tess "take advil 8 am": title "Take Advil", `startsAt` 8 am today | yes (by title, after 0ac slice 2 or the 2:22 title) |
| **O6** gym bag note | Note | "Gym bag in the car" | no (control) |
| **O7** dry cleaning task | Task | "Pick up dry cleaning", 5 pm today | no (control) |
| **O8** evening memory | Memory | noticed: title "You like to train in the evening", `rule` "training.hours", `isPrivate` false, `evidence` 3 workouts | no (control) |

## 3. The rows

"Today" is master 64ffb93. "After" is what must show once 0ai (and, for the newest row, 0ak) is in.

| Row | Object | Route | Master today (file:line) | Leak today | After 0ai | Pass check |
|---|---|---|---|---|---|---|
| **PM1** | O1 | G: Review, tap Push A, Linked from, tap the memory | Hero "Your door code is 4417" (:227); class line "object yourDoorCodeIs4417 : Memory" (:228) | yes | Hero "Private memory"; class line `object privateMemory : Memory` | No label on the page contains "4417", "door" or "code" (`CONTAINS[c]`); one static text equals "Private memory" |
| **PM2** | O1 | P: same page, Properties | Rows Kind told, Rule "door code is 4417", Area about, From "Push A", Pinned no, Stays on this phone yes (:348-360, :397-399, :417, :387) | yes | No Properties section at all | No static text "Properties", "Rule", "Stays on this phone", "From" or "Push A" on the page |
| **PM3** | O1 | L: Push A's page, Linked from | Row titled "Your door code is 4417" (:261); hint "Opens Your door code is 4417" (`ObjectHandle.swift:77`) | yes | Row reads "Private memory"; hint "Opens Private memory" | The row's label equals "Private memory"; no element's label or hint contains "4417" |
| **PM4** | O1 | C: breadcrumb "Memory" on PM1's page | Memory class page: class line, prototype `PropertyList` with defaults only (:89); no object list, no newest row (:62-147) | no | Unchanged; when 0ak's glance lands, see PM18 | No label contains "4417" or "door"; no row names O1 |
| **PM5** | O3 | G: Review, tap today, tap "Private note" | Hero "Private note" (:227, title set by `Notes.swift:117`); Body row "wifi password is hunter2" (:348, :397-399, :419); "Private yes" (:417) | yes | Hero "Private note" only; no Body or Private row | No label contains "hunter2" or "wifi"; no static text "Body" |
| **PM6** | O4 | G: as PM5 | Hero "Private note"; Body row "took advil 400mg"; "Private yes" | yes | As PM5 | No label contains "advil" or "400"; the mask fires on the flag alone, with no secret word in the body |
| **PM7** | O5 | G: Home queue row "Take Advil" (`HomeQueue.swift:263`) or the Now hero (`NowPage.swift:220`) | Hero "Take Advil" (:227); class line "object takeAdvil : Task" (:228); Starts (the day and 8:00 am), Done no (:397-399, :417-418) | yes | Hero "Private task"; class line `object privateTask : Task`; no Starts, Length, Due or Done rows | No label on the page contains "advil"; one static text equals "Private task". (The queue row's own title is F7, not this rider.) |
| **PM8** | O6 | G and P: Review, tap today, tap "Note: Gym bag in the car" | Hero "Gym bag in the car"; Body row the same | no | Unchanged: the mask must not fire | The Body row shows "Gym bag in the car"; no "Private note" text appears |
| **PM9** | O7 | G and P: Home queue row | Hero "Pick up dry cleaning"; Starts (the day and 5:00 pm) | no | Unchanged | Hero and Starts row show; no "Private task" text appears |
| **PM10** | O8 | G, P and L: Push A's Linked from, tap the row | Row and hero "You like to train in the evening"; Rule "training.hours"; Stays on this phone no | no | Unchanged | Row, hero and Rule row show as today; no "Private memory" text appears |
| **PM11** | O6, then edit | Edge, made private after creation: open O6's page (PM8), go to Notes, add a second line "gate code 4417", come back | Master: `EditNote` makes it private and retitles it (`Notes.swift:163-177`), so the hero turns "Private note", but the Body row prints both lines, 4417 included | yes | Masked as PM5 on the next revision (`ObjectPage.swift:11` reads `model.revision`); no stale field stays on screen | After the edit, no label contains "4417" or "gym"; hero "Private note" |
| **PM12** | O8, flipped | Edge, a memory made private after creation (seeded `isPrivate` false to true; master has no toggle) | All fields print, as PM10 | yes | Masked as PM1, labelled "Private memory", the Linked from row too | No label contains "evening" or "training.hours" |
| **PM13** | O8, flipped back | Edge, private again to public (seeded true to false) | All fields print | no | Fields show again: the mask follows the stored value, never a cache | Rule row "training.hours" shows; no "Private memory" text appears |
| **PM14** | O3 | Edge, a SecretWords-forced note: typed on the Notes line with no private ask | Same as PM5 | yes | As PM5 | As PM5. Also: the hero never reads the first line (`Notes.swift:117` sets "Private note"; the mask must not undo it on a generic rename, decisions 2:22 pm) |
| **PM15** | O2 | Edge, the title is the memory's only stored content (no rule, no evidence) | Hero "Your left shoulder gets sore after presses"; class line its identifier; Properties shows defaults only (Kind told, Area about, Stays on this phone yes) | yes | Hero "Private memory"; no Properties heading; no empty-state text | No label contains "shoulder" or "sore"; no "Properties" text; no "0" or "1 field" anywhere |
| **PM16** | pre-#422 note | Edge: a note from before #422 ("wifi password is hunter2", no `isPrivate`, title the first line), as R6/N15 seeds it | Hero "wifi password is hunter2"; class line `object wifiPasswordIsHunter2 : Note`; Body row | yes | "Private note" whether or not R6's launch pass has run: the check also reads `SecretWords.mentions` on the title and body | No label contains "hunter2"; hero "Private note" |
| **PM17** | forgotten hash | Edge: a forgotten line's entry (`TessMemory.swift:558-560`: title is a hash of the words, `kind` forgotten, `isPrivate` true), opened with the seed flag's direct route | Hero is the hash; Kind forgotten | yes | "Private memory"; the hash never shows (a short code's hash can be guessed) | No static text matches `[0-9a-f]{16,}`; hero "Private memory" |
| **PM18** | O1 newest | C, newest row: Memory class page when the newest memory is private (needs 0ak) | No newest row on master (:62-147) | no (no row) | Reads "Private memory", never its title; opens the masked page | The row's label equals "Private memory"; no label contains "4417". |
| **PM19** | O3 newest | C, newest row: Note class page when the newest note is private (needs 0ak); then add O6 after it | No newest row on master | no (no row) | "Private note", never its first line; once O6 is newer, "Gym bag in the car" | First the row equals "Private note" and nothing holds "hunter2"; after O6, the row equals "Gym bag in the car" |
| **PM20** | O1, O3, O5 | VoiceOver on PM1, PM3, PM5, PM7 and PM18 | Rotor reads "Your door code is 4417, heading", the class line, every Properties row, "Opens Your door code is 4417" (`ObjectHandle.swift:35`, `:77`) | yes | Each page reads only the label (heading), the class line and the breadcrumb class names; each row reads the label and "Opens Private memory" | Every `label` and `hint` on screen, read with `CONTAINS[c]`, holds none of "4417", "door", "hunter2", "wifi", "advil", "shoulder", "Rule", "Body", "Stays on this phone" |

**Count.** 20 rows: 13 leak on master today (PM1 to PM3, PM5 to PM7, PM11, PM12, PM14 to PM17, PM20), 7 don't (the controls PM8 to PM10 and PM13, the class page PM4, and the newest rows PM18 and PM19, which don't exist yet). Every row needs 0ai. PM7 also needs the task check (0ac slice 2 or the 2:22 "Private task" title); PM16 also covers R6; PM18 and PM19 need 0ak's glance.

## 3b. Workout notes: rows PM21 to PM36 (decisions 5:07 pm, item 4)

*Added by Research BR, Sat Oct 17, 2026, read by hand on origin/master b41695d (Merge #573). Nothing was built or run.*

**The ruling (Product, 5:07 pm, item 4).** The generic workout front prints the workout's notes (`ObjectPage.swift:232-234`), so "left knee sore" shows on the front. Workout notes count as a body fact, so the 0ai rider masks them on the front, the same as other private fields. The 2:45 mask covered private objects only; this one masks one field on an object that is not private.

**Where a workout's notes live and show on master.** `notes` is a rich-text field on Thing (`SystemCatalog.swift:56-58`), so Workout inherits it (Workout's own fields are Scheduled, Started, Ended and Routine, `SystemCatalog.swift:127-133`). Nothing in the app writes a workout's notes on master: no screen edits it, no action sets it (`git grep '"notes"'` finds only `ObjectPage.swift:81`, `:232`, `:348` and the exercise library cue at `ExerciseLibraryInstaller.swift:87-88`). A workout gets notes from the old SwiftData store (`TesseraLegacyStore` copies every value), a restored backup (`TesseraExport.swift:130` keeps every value), or the seed flag. So the rows seed them through `ObjectStore`, as PM1 does.

| Surface | File:line on master | Reads a workout's notes? |
|---|---|---|
| Generic front, `InstanceBody` | `Features/Objects/ObjectPage.swift:232-234` | **Yes**: `Text(notes)` in body type under the hero, read by VoiceOver as plain text |
| `PropertyList` | `ObjectPage.swift:348` | No: `notes` is filtered out of the field rows |
| Class page (`ClassBody`) | `ObjectPage.swift:81-87` | Only the prototype's notes (the object titled "Workout"), never a session's |
| Contents (`ChildRow`) | `ObjectPage.swift:277-300` | No: exercise name and "N logged" or the target |
| Linked from, and a ref to the workout on another page | `ObjectPage.swift:254-267`, `:387` | No: the workout's title only |
| Class page History | `ObjectPage.swift:196-208` | No: date and sets |
| Day log line (Review, the day) | `TesseraCore/.../DayLog/DayStory.swift:217-238` | No: "title, N min. top set, best." Tapping it opens the front (`ReviewWeek.swift:353`) |
| Review (week) | `Features/Home/ReviewPage.swift:269` opens the front; `DayLog/WeekFacts.swift:3-5` | No: counts, titles and short exercise names only |
| Workout summary, finish screen, Now's done line | `Training/WorkoutSummary.swift:30-36`; `Features/Workout/WorkoutFinishView.swift:36-71`; `Features/Home/NowPage.swift:254-256`, `Home/HomeLines.swift:479-488` | No: counts, minutes, volume, best names |
| Now's planned line | `NowPage.swift:78-81` | No: title and time; it opens the front |
| Exercise HISTORY | `Features/Exercise/ExerciseDigest.swift:13-19`, `ExerciseViews.swift:98-150` | No: date, set count, top set |
| Training page | `Features/Home/TrainingPage.swift` | No: plan, lanes and targets |
| Live workout | `Features/Workout/WorkoutModeView.swift:450-482`, `WorkoutParts.swift:223-255` | No: the "notes" there are rest and edit notes the session writes, not the field |
| Live Activity, widgets | `Shared/RestActivityAttributes.swift:6-30`, `Widgets/RestLiveActivity.swift`; the bundle holds only `RestLiveActivity` (`Widgets/TesseraWidgetsBundle.swift:5-8`) | No: workout title, exercise, set, weight, reps, rest. No Home Screen widget on master |
| Claude capture pack | `TesseraTess/ClaudeTessModel.swift:151-155`, `TessModelCapture.swift:70-83` | No: "current exercise" and the last set |
| Plan my day pack | `TesseraTess/PlanWording.swift:8` | No: titles and handles only |
| answerQuery | `TesseraTess/TessTools.swift:236-266` | No: counts over a span |
| Health export, App Intents | `App/Health/HealthExporter.swift:59-63`; `TesseraIntents/Entities.swift:63-71` | No: sync id, version, brand; an entity's title |
| Backup file | `Export/TesseraExport.swift:130` | Yes, by design: his own file, kept on the phone (exempt, decisions 4:46 pm (2)). No row |

So the front is the one leak today. The other rows pin that each surface stays clean once the mask lands, and the drawn sides (Core 0ak: THE SETS, the exercise side's HISTORY page) carry their own rows (SA-SETS-8, SA-EX-12, DP22).

**Research's pick: mask every workout note, whatever it says.** The 5:07 ruling names the field, not the words, so "felt strong" is masked like "left knee sore". Screening by word list (SecretWords, PrivateFacts) would let "felt strong" through and then has to decide line by line for "felt strong, left knee sore". One rule for the field is simpler to build and to test, and a note about how a session felt is about his body anyway. PM23 is the trap: a builder who screens by words fails it.

**What shows instead.** On the generic front, one muted line "Note kept private" in the notes slot, no words, no count of lines or characters, and the same line whatever the note says. Everywhere else, nothing, as today. Research picks the marker over a blank because nothing else on master shows the note, so a blank would make it look lost; the marker says it is kept without saying what it is. Product can pick a blank instead (Q4); then `expectLine` becomes null and the checks become "no notes slot". The marker is not "Private note" (the Note class's label, which PM8 and PM19 look for), and the workout itself is not masked: hero, class line, Properties, Contents, Linked from and Start workout all show as today (PM27).

**Objects.** Added to `-wallsSeedPrivate` after `-resetDemo`, written through `ObjectStore` with fixed ids. The demo seeds a Push / Pull / Legs plan with legs yesterday (`Features/Demo/DemoData.swift:4`, `:70`).

| Object | What | Notes stored |
|---|---|---|
| **W1** | Today's Push A (the workout PM1 reaches; O1 and O8 link it) | "left knee sore" |
| **W2** | Yesterday's legs workout | "weighed 82.4 before" |
| **W3** | The latest pull workout | "felt strong" |
| **W4** | A push workout from last week | none (control) |
| **W5** | A workout scheduled today at 7:00 pm, not started, two exercises (Bench Press first) | "left knee sore" |
| **W6** | A pull workout from last week | three lines: "felt strong", "left knee sore", "locker 4417" |
| **W7** | A legs workout from last week | two spaces only (an empty note) |

**The rows.** "Today" is master b41695d. "After" is once 0ai is in.

| Row | Object | Route | Master today (file:line) | Leak today | After 0ai | Pass check |
|---|---|---|---|---|---|---|
| **PM21** | W1 | G: Review, today, tap the Push A line (`ReviewWeek.swift:353`) | "left knee sore" under the hero (`ObjectPage.swift:232-234`) | yes | "Note kept private" in the notes slot; no words | No label contains "knee" or "sore"; one static text equals "Note kept private" |
| **PM22** | W2 | G: Review, yesterday, the legs line | "weighed 82.4 before" under the hero | yes | As PM21 | No label contains "82.4" or "weighed"; one "Note kept private" |
| **PM23** | W3 | G: Review, the pull day, the pull line | "felt strong" under the hero | yes | As PM21: a plain note is masked too (the trap) | No label contains "felt" or "strong"; one "Note kept private" |
| **PM24** | W6 | G: `-openObject W6` | All three lines, "locker 4417" included | yes | One "Note kept private", no line count | No label contains "felt", "knee" or "4417"; no static text contains "lines" or "3"; exactly one "Note kept private" |
| **PM25** | W4 | G: `-openObject W4` | No notes line | no | Unchanged: no marker | No static text "Note kept private" |
| **PM26** | W7 | G: `-openObject W7` | An invisible two-space text (:233) | no | No marker: a note with no words is no note | No static text "Note kept private" |
| **PM27** | W1 | G and P: as PM21 | Hero "Push A", class line, Started, Ended, Routine, Contents, Linked from | no | Unchanged: the field is masked, not the workout | Hero "Push A" shows; a "Started" row shows; no "Private note", "Private task" or "Private memory" names W1; no static text "Notes" |
| **PM28** | W1 | L: W1's Linked from, then O8's page (its From row, `ObjectPage.swift:387`) | Rows name the memories and "Push A" | no | Unchanged (O1's row is "Private memory", PM3) | No label on either page contains "knee" or "sore" |
| **PM29** | W1, W2, W3 | Day log and Review: Review, today, yesterday and the pull day, then the week | "Push A, N min. ..." (`DayStory.swift:224-229`); week bands (`WeekFacts.swift:3-5`) | no | Unchanged | No label contains "knee", "sore", "82.4", "weighed", "felt" or "strong" |
| **PM30** | W1 | Summary: Home's Now done line (`NowPage.swift:256`), then the finish screen on W5 (PM33) | "Push A, done"; counts, minutes, kg moved (`WorkoutFinishView.swift:36-71`, `HomeLines.swift:479-488`) | no | Unchanged | No label contains "knee" or "sore" |
| **PM31** | W1, W2 | Exercise HISTORY: Bench Press, then Back Squat (`ExerciseViews.swift:98-150`); the class page History (`ObjectPage.swift:196-208`) | Dates, set counts, top sets | no | Unchanged; after 0ak the side's HISTORY page and THE SETS also show no note words (SA-SETS-8, SA-EX-12) | No label contains "knee", "sore", "82.4" or "weighed" |
| **PM32** | W1 to W3 | Training page and Home (`TrainingPage.swift`, `NowPage.swift`) | Plan, lanes, lines | no | Unchanged | No label contains any of the three notes' words |
| **PM33** | W5 | G, live, Live Activity: Now's planned line (`NowPage.swift:78-81`) opens W5's front; tap Start workout (`ObjectPage.swift:269-274`); log a set; lock the phone during rest | Front prints "left knee sore"; live screen, Lock Screen and Dynamic Island don't (`RestActivityAttributes.swift:6-30`) | yes (front) | Front shows "Note kept private" and Start workout; live and Live Activity unchanged | No label on the front or live screen contains "knee" or "sore"; by hand, nothing on the Lock Screen or Dynamic Island does |
| **PM34** | W1, W2, W3, W6, W5 | VoiceOver on PM21 to PM24 and PM33's front | Reads the note as body text | yes | Reads "Note kept private" and nothing of the note | Every label and hint, read with `CONTAINS[c]`, holds none of "knee", "sore", "82.4", "weighed", "felt", "strong", "4417" |
| **PM35** | W5 | Never packed for Claude, Plan my day: package test, `PlanPack(...)` with W5's block | Titles and handles only (`PlanWording.swift:8`) | no | Unchanged | The pack's JSON holds none of "knee", "sore" |
| **PM36** | W5 | Never packed for Claude, the live ask: W5 live with Bench Press in focus, ask "how did that set go?" under `-wallsSpy` | Capture pack: "current exercise" and the last set (`TessModelCapture.swift:70-83`, `ClaudeTessModel.swift:151-155`) | no | Unchanged | No Claude request body or pack holds "knee" or "sore"; nor does any on-device model prompt |

**Count.** 16 rows: 6 leak on master today (PM21 to PM24, PM33, PM34), 10 don't (the controls PM25 to PM27, and PM28 to PM32, PM35 and PM36, which pin surfaces that are clean today). Every leaking row needs Core 0ai. The rows need no new field and no catalog change (Catalog v9 holds): 0ai reads `notes` on any object whose class is Workout or a subclass (`ClassResolver.isSubclass`, as `ObjectPage.swift:269-270` does).

**All rows.** 36: 19 leak on master today (13 in PM1 to PM20, 6 in PM21 to PM36), 17 don't.

## 4. Open for Product

- **Q1. The newest row (PL3 vs 2:45 pm).** The 2:44 pm decision adopted screens-inventory-check PL3: "Private objects count but are never the newest or the most used." The 2:45 pm rider says the newest row shows the private label. Ruled in the 2:45 amendment (2:55 pm): 2:45 wins, so the newest slot shows the private label. PM18 and PM19 hold. The title never shows.
- **Q2. The task flag.** Master's Task has no `isPrivate`, and the riders pin can't add one (Catalog v9). Until Core 0ac slice 2 walls bare medicine names, "Take Advil" with no number is not private by title. PM7 is pending on that, not on 0ai. Ruled 2:55 pm: 0ai uses a computed check with no new field, so v9 holds.
- **Q3. R8's Builder B half.** R8 (PN-MENTION) has "the object page never shows a private note's body" (`InstanceBody`). 0ai's mask closes it for every class, so MN1's second half and PM5 are one fix, checked twice. Ruled 2:55 pm: the heading, InstanceBody and Linked from are all masked on Core 0ai with PF1/R18.
- **Q4. Marker or blank (workout notes, 5:07 pm).** Research picks one muted "Note kept private" line in the front's notes slot (section 3b), so the note doesn't look lost, since nothing else on master shows it. If Product wants a blank, PM21 to PM24, PM33 and PM34 drop `expectLine` and check that no notes slot shows. Either way no note words and no line count show, and "felt strong" is masked like the rest.

## 5. QA riders gate: run list

Run on the riders pin, Simulator, iPhone 17, after `scripts/test.sh` ends "All green". One launch: `-demo -demoTime 18:10 -resetDemo -wallsSeedPrivate` (the seed now also writes W1 to W7, section 3b).

1. `WallsUITests/testObjectPageMask` (rows PM1 to PM34 from `walls-ui-phrases.json`, surface `objectPage`), then the package rows PM35 (`planMyDay`) and PM36 (`liveWorkoutAsk`, under `-wallsSpy`). Paste the summary lines and the run time.
2. By hand, VoiceOver on: Review, tap Push A, Linked from. Swipe through. Expect "Private memory" and "You like to train in the evening", nothing else from the memories (PM3, PM10, PM20).
3. By hand: Notes, open "Gym bag in the car", add "gate code 4417", back to Review, tap the note (PM11). Expect "Private note" and no second line anywhere.
4. Home queue: tap "Pick up dry cleaning" (fields show, PM9). If 0ac slice 2 is in, tap the Advil task (PM7) and expect "Private task" only.
5. Breadcrumb up to Memory and Note (PM4); if 0ak is in, check the newest rows (PM18, PM19).
6. Workout notes by hand, VoiceOver on: Review, today, Push A (PM21, PM34). Expect "Note kept private" under the hero and the workout's fields, Contents and Linked from as before (PM27). Then Review, yesterday, the legs line (PM22) and the pull day (PM23, the plain-note trap). Expect the same marker and no note words.
7. Home: tap the 7:00 pm planned line (W5), check the marker, tap Start workout, log a set, lock the phone during rest (PM33). Expect no note words on the front, the live screen, the Lock Screen or the Dynamic Island.
8. Pass: every row without `pending` passes, every pending row reports its expected failure, and no screen in steps 2 to 7 shows 4417, hunter2, Advil, "door", "shoulder", "knee", "sore", "82.4", "weighed" or "felt strong".
