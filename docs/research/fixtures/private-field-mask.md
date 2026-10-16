# The private-field mask: fixture rows PM1 to PM20 (Core 0ai rider, Research BH)

*Research, Fri Oct 16, 2026. For Core 0ai (the one engine wall), Builder B (the page), QA (the riders gate). Read by hand on origin/master 64ffb93 (Merge #558). Nothing was built or run. Every value is made up: hunter2, tacocat and 4417 are placeholders.*

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

## 4. Open for Product

- **Q1. The newest row (PL3 vs 2:45 pm).** The 2:44 pm decision adopted screens-inventory-check PL3: "Private objects count but are never the newest or the most used." The 2:45 pm rider says the newest row shows the private label. Ruled in the 2:45 amendment (2:55 pm): 2:45 wins, so the newest slot shows the private label. PM18 and PM19 hold. The title never shows.
- **Q2. The task flag.** Master's Task has no `isPrivate`, and the riders pin can't add one (Catalog v9). Until Core 0ac slice 2 walls bare medicine names, "Take Advil" with no number is not private by title. PM7 is pending on that, not on 0ai. Ruled 2:55 pm: 0ai uses a computed check with no new field, so v9 holds.
- **Q3. R8's Builder B half.** R8 (PN-MENTION) has "the object page never shows a private note's body" (`InstanceBody`). 0ai's mask closes it for every class, so MN1's second half and PM5 are one fix, checked twice. Ruled 2:55 pm: the heading, InstanceBody and Linked from are all masked on Core 0ai with PF1/R18.

## 5. QA riders gate: run list

Run on the riders pin, Simulator, iPhone 17, after `scripts/test.sh` ends "All green". One launch: `-demo -demoTime 18:10 -resetDemo -wallsSeedPrivate`.

1. `WallsUITests/testObjectPageMask` (rows PM1 to PM20 from `walls-ui-phrases.json`, surface `objectPage`). Paste the summary line and the run time.
2. By hand, VoiceOver on: Review, tap Push A, Linked from. Swipe through. Expect "Private memory" and "You like to train in the evening", nothing else from the memories (PM3, PM10, PM20).
3. By hand: Notes, open "Gym bag in the car", add "gate code 4417", back to Review, tap the note (PM11). Expect "Private note" and no second line anywhere.
4. Home queue: tap "Pick up dry cleaning" (fields show, PM9). If 0ac slice 2 is in, tap the Advil task (PM7) and expect "Private task" only.
5. Breadcrumb up to Memory and Note (PM4); if 0ak is in, check the newest rows (PM18, PM19).
6. Pass: every row without `pending` passes, every pending row reports its expected failure, and no screen in steps 2 to 5 shows 4417, hunter2, Advil, "door" or "shoulder".
