# People ship list: fourth slice for M5 (engine-first), DRAFT for Product

**DRAFT for Product to review.** Research lab, 2026-10-15. Not approved; nothing here is a decision until Product signs it. Comes after Upkeep (`ship-list-m5-upkeep-draft.md`), as Kaushik ordered. Same rules as `../product/ship-list-lists.md` and `../product/ship-list-kitchen.md`: small end-to-end slices, velocity over perfection, engine first so Core can start now. **Engine** = logic and tests only; **Feature screen** = a self-contained screen in its own `Features/People/` folder that meets the UI bar (no cards, pills, capsules or stock lists). Source: the People part of `people-and-upkeep.md` (smallest version only), with Kaushik's yes to both People questions: no Contacts access, and any @mention counts as "mentioned" while only a contact phrase counts as "talked". Owners: **Core** builds engine slices, **Builder B** builds screens. Checked against `origin/master` at `5956550`: there is no `person` key in `SystemCatalog.Key` and no People code. Notes link @mentions today (`NoteList.mentions`, `Transaction.linkMentions` into the note's `about`), but tasks do not: `CreateTask` sets `about` only from ids it is given, and an unknown `@Name` links nothing. `NoteList.resolve` matches a class name first, then the oldest object of any class with that exact title.

**The idea in one line.** A person is an object you mention: "call @Mum" or "dinner with Sam fri" links Mum or Sam, and the person reads "talked 2 days ago", worked out from notes and tasks, never typed. The only new class is `Person`. It reuses notes, tasks, `about` links and backlinks, `ObjectStore`, the op log and undo, the ghost row and `TessCaptureEngine`, `RollForwardTasks` and `NowPicker` as they are. No keep-in-touch intervals, no overdue list, no scores, no Contacts prompt.

**Birthdays are dated tasks.** A birthday is a day and month on the person and one dated task "Sam's birthday" on its next occurrence. On the day it is an untimed task, so `NowPicker` already puts it on Now with no new rule.

**Progressive disclosure rule.** A person opens as their name and one line ("talked Tue · birthday 12 Mar"). Mentions, aliases and the birthday are one gesture away. The People page shows names, not counts; nothing about who you have not talked to.

## Slices

| # | Slice | Done when | Type | Owner |
|---|---|---|---|---|
| 1 | **Person class and actions** | `SystemCatalog.Key.person` (parent `thing`): name (title), aliases (`.text`, comma separated: "Mum, Mom, Amma"), birthMonth and birthDay (`.number`, optional), birthYear (`.number`, optional, stored only, no ages shown), contactID (`.text`, empty in v1, kept for a later Contacts link), birthdayTask (`.ref` to `task`). `AddPerson(name, aliases?)`, `EditPerson`, `SetBirthday(person, month, day, year?)`, `ClearBirthday` and `DeleteObject`, all undoable through the op log. `person(named:)` (in `TesseraCore/People/`) tries exact name or alias, case-insensitive; then the same with a possessive "'s" or a trailing "s" dropped ("mums" finds Mum); then a first word that only one person has ("sam" finds Sam Patel). Two matches return `.ambiguous`, never the first. No substring match. `AddPerson` with an existing name returns that person. Op summaries read "Added Sam", "Sam's birthday, 12 Mar" | Engine | Core |
| 2 | **Mentions in tasks, and people on first use** | `CreateTask` and `RenameObject` on a task run `linkMentions` on the title, as notes do, so "call @Mum" links Mum. An unknown one-word `@Name` (or any `@[Long Name]`) creates a Person in the same transaction, so one undo removes both. When an exact title is shared (Person "Rosemary" and the ingredient Rosemary), `resolve` prefers the Person; class names still win first, as now. Tests: "@Sam" in a task links Sam; unknown "@Priya" in a note makes Priya and undo removes her; "@Bench Press felt heavy" and "@Mac & Cheese was great" still link as today; "@Rosemary" links the person | Engine | Core |
| 3 | **Last talked, last mentioned** | `PeopleLedger` (in `TesseraCore/People/`, shaped like `ListContents`) returns per person, all derived from backlinks and never stored: `lastMentioned` (newest note or task that links them, by createdAt), `lastTalked` (newest note that links them and holds a contact phrase, by createdAt, or done task that links them and holds one, by doneAt), `talkLine` ("talked today", "talked Tue", "talked 3 weeks ago"; else "mentioned 5 days ago"; else nothing), and `nextBirthday`. The contact phrase list is fixed and shared with slice 5: talked to, spoke to, called, rang, texted, messaged, facetimed, met, saw, visited, caught up with, coffee / lunch / dinner / drinks / call with, and the task forms call, ring, text, see, meet, visit. "return @Sam's drill" is mentioned only. A dated task "Dinner with Sam" counts as talked only when done. Tests: day boundary at 04:00 (the roll-forward day), undo of the note moves the line back, a deleted note drops out, two people in one note | Engine | Core |
| 4 | **Birthdays as dated tasks** | `SetBirthday` creates or moves one task "Sam's birthday" (about [Sam], no time) on the next occurrence and stores it as `birthdayTask`; 29 Feb falls on 28 Feb in other years. `RollForwardTasks` skips birthday tasks. In the same action, a past undone birthday task is closed quietly (done at its own day, so it never shows in today) and next year's task is created and linked; one undo reverts both. Done early in the day stays done. `ClearBirthday` deletes the open task. Tests: 15 Oct sets 12 Mar → Fri 12 Mar 2027; setting 15 Oct on 15 Oct → today; a skipped birthday never rolls or counts as carried over; 29 Feb in 2027 and 2028 | Engine | Core |
| 5 | **People phrases and tools** | `TessGrammar+People.swift`, a `.person` parse case (birthday, talk, contact task), checked after notes, pasted recipes and relative sets, before comma sets, lifts, kitchen and tasks (and after reading, money and upkeep once they land). It binds only when its argument resolves (collision rule 1): a birthday shape, or a contact phrase plus a person from `person(named:)`. The split rule (collision rule 3) does not split inside a contact phrase. All phrases in the table below map as written, with their feedback line. `LogTalk(people: [name], text, at?)` and `SetBirthday` are in `ActionRegistry` with name-only parameters, so the on-device model and Claude can call them. All 15 eval rows pass, and every phrase in `../product/kitchen-phrases.md`, the existing grammar tests and the `grammar-collisions.md` guard rows still parse the same | Engine | Core |
| 6 | **Person page** | Object page for one person, see design steer | Feature screen `Features/People/` | Builder B |
| 7 | **People page** | The People front page: everyone, most recently talked first, see design steer | Feature screen `Features/People/` | Builder B |
| 8 | **@ in the editors** | Typing @ in the note editor and the task title offers people first, then other objects, and shows "New person" for an unknown name, see design steer | Feature screen `Features/People/` (shared view) | Builder B |

Build order: 1 → 2 → 3 → 4 → 5; screen 8 after 2, 6 after 3, 7 after 3.

## Capture phrases (slice 5)

| Phrase | Maps to | Feedback line |
|---|---|---|
| `call mum`, `text sam`, `ring mum` (person exists) | task "Call mum", Later, about [Mum] | "Call Mum, in Later." |
| `call mum thu`, `see sam at 7` | task dated as the task grammar does (`decisions.md`: a weekday that is today means today), about the person | "Call Mum, Thu." |
| `dinner with Sam fri`, `coffee with sam and ben sat` | task dated, about every named person | "Dinner with Sam, Fri." |
| `met Sam`, `talked to sam`, `saw mum yesterday` | `LogTalk`: a note "Met @Sam" dated as said (a day cue means the most recent past day) | "Met Sam. Noted." |
| `met Priya` (no such person) | ambiguous ghost row: "New person Priya, met today" or "Note: met Priya"; waits for a tap | "New person: Priya?" |
| `Sam's birthday 12 March`, `sam birthday 12/3`, `sam bday march 12`, `birthday sam 12 mar` | `SetBirthday` (and `AddPerson` if new) plus the birthday task | "Sam's birthday, 12 Mar. On your list for Fri 12 Mar." |
| `Sam's birthday 12 March 1990` | as above, year stored only | as above |

Rules:
- Phrases are ghost rows like everything else: pending, commit after 2 s or on tap, undo.
- A bare name links only after a contact phrase or in a birthday phrase, and only to an existing person. Only `@Name`, a birthday phrase and a tapped "New person" create a person; "call priya" with no Priya goes on unchanged (no date: the model; with a date: a plain task).
- A birthday needs a day and a month. "mum's birthday present fri" and "buy present for mums birthday on the twentieth" are tasks (the second linked to Mum), never a birthday change.
- An unknown name after a past contact verb must look like a name: 1 to 3 words, no article, pronoun, date word or number, and not the exact title of another object. "met the deadline" and "saw Dune" never make a person.
- Kitchen keeps its words without a contact phrase: "buy rosemary" is groceries even when Rosemary is a person. A contact phrase decides the other way: "dinner with Rosemary fri" is a task about Rosemary, never a cook or a grocery line.
- A person's name never reaches the lift resolver once a contact phrase has bound: "drinks with Ben 7pm" is never Bench Press.
- `note` wins, as now. A note's @mentions link as in slice 2, and a contact phrase in it counts as talked.
- `<list name>:` (collision rule 1) still binds only to a list's exact name, so a list called "Sam" takes "sam: chalk bag"; people phrases never use a colon.
- Questions ("when did i last talk to sam") go to the question path (collision rule 2) and are answered from `PeopleLedger` on the phone.
- Two people match (two Sams): the ghost row shows both, waits for a tap, and the next "sam" prefers the last pick.

## Eval phrases (15)

Clock: Thu 15 Oct 2026, 18:00 Europe/London, the `grammar-collisions.md` fixtures, plus people Mum (aliases Mom, Amma), Sam (last talked Tue 13 Oct), Ben and Rosemary, the ingredient Rosemary, and no Priya. A context is idle unless stated. "Model" means the grammar returns nil.

| # | Phrase | Context | Expected |
|---|---|---|---|
| 1 | `call mum` | idle | task "Call mum", Later, about [Mum]; Mum's talk line unchanged until done |
| 2 | `dinner with Sam fri` | idle | task "Dinner with Sam", Fri 16 Oct, about [Sam]; counts as talked only when done |
| 3 | `Sam's birthday 12 March` | idle | person.birthday Sam 12 Mar + task "Sam's birthday" Fri 12 Mar 2027, about [Sam] |
| 4 | `met Priya` | idle | ambiguous: new person Priya with note "Met @Priya" \| note; no write before a tap |
| 5 | `met sam yesterday` | idle | note "Met @Sam" dated 14 Oct; Sam "talked yesterday" |
| 6 | `met the deadline` | idle | trap: no person (model) |
| 7 | `drinks with Ben 7pm` | idle | trap: task "Drinks with Ben" today 19:00, about [Ben]; never Bench Press |
| 8 | `dinner with Rosemary fri` | idle | trap: task Fri 16 Oct about Person Rosemary; not groceries, not a cook task |
| 9 | `buy rosemary` | idle | trap: groceries [rosemary], no person link (guard) |
| 10 | `note coffee with @Sam, he's moving in may` | idle | note about [Sam], Sam talked 15 Oct; "may" is not a date |
| 11 | `buy present for mums birthday on the twentieth` | idle | trap: task Tue 20 Oct about [Mum]; Mum's birthday unchanged |
| 12 | `call mum thu` | idle | task "Call mum" Thu 15 Oct (`decisions.md`), about [Mum] |
| 13 | `talked to sam and mum` | idle | trap: one note "Talked to @Sam and @Mum", both talked today; not split, no grocery "mum" |
| 14 | `when did i last talk to sam` | idle | trap: question, no write ("Tue, 2 days ago.") |
| 15 | `caught sam on the phone, he got the job` | idle, Claude on | model: ghost row note about [Sam] via `LogTalk`, "via Claude"; with no model, "Didn't catch that. Try: talked to Sam." |

As Swift Testing rows, beside `collisionRows`: `.init("call mum", .idle, "task Call mum later about Mum")`, `.init("met Priya", .idle, "ambiguous person.new|note")`, `.init("buy rosemary", .idle, "groceries [rosemary]")`, and so on. The people fixtures are added to the shared eval store.

## Privacy with Claude

People are the most personal data in the app. With Claude switched on (`tess-model-layer.md`), the grammar handles the common phrases on the phone, so Claude sees a person only when a phrase misses.
- Sent: the typed phrase (which holds whatever name was typed) and today's date, in the existing capture pack.
- Never sent: the list of people, aliases, birthdays, note bodies, talk history, or any other person's name. People are not added to the capture pack's object names, unlike lists and recipes.
- Tools take names and resolve them on the phone. A miss returns "no person called X" with no closest names, so a wrong guess never reveals who else is in the app.
- Questions about people run locally; only the question text leaves the phone.
- Slice 5 adds a `TessContextPack` snapshot test: a capture with five people in the store sends none of their names except the one typed.

## Design steers (one per screen)

Shared: light ground, the house paper and washes; Design picks the People lean in its build sheet. Vermilion only for something running (people never run), cobalt only for Tess. No avatars in circles, no red, no "overdue", no counts of who you have not seen. Times are words in tabular figures.

**6. Person page.** The hero is the name. One context line in Body: "talked Tue · birthday 12 Mar". Below, the mentions as a single margin timeline: day numerals on the left, the note or task line on the right with the person's name set in weight, contact lines in full ink and plain mentions a step lighter. The birthday is a **day and month drum**, the day drum's sibling; release writes `SetBirthday`. Aliases and delete are one level deeper. Empty state: "Mention @Sam in a note or task and it shows here."

**7. People page.** Not a contact list. The names are set as running text, one paragraph, ordered by last talked, recent first, separated by thin spaces; each name taps through to its page. A birthday within 14 days hangs in the right margin beside its name ("Sam, Fri"). People never mentioned sit at the end in a lighter weight; nobody fades for being quiet. New person is the ghost row ("@Priya"). Empty state is one cobalt line from Tess: "Tell me who you talked to. Try: met Sam."

**8. @ in the editors.** Typing @ lifts a single line of names above the keyboard, people first then other objects by recent use, filtered as you type, no sheet. An unknown name shows "New person" in the same line. A committed mention sets in weight inline (cobalt stays for Tess); long-press shows which object it is, which settles ties like Rosemary.

## Depends on

- From master: `ObjectStore`, `SystemCatalog`, the op log and undo, `DeleteObject`, `RenameObject`, `CreateTask`, `NoteList` and `linkMentions`, backlinks, the ghost row and `TessCaptureEngine`, `ActionRegistry`, `RollForwardTasks`, `NowPicker`, `TaskList`.
- `grammar-collisions.md` rules 1, 2, 3, 5, 7 and 9: the question guard for eval row 14 (until it lands, row 14 falls back to the model, never to a task), the split rule exemption for row 13, the ordinal fix for row 11, and ambiguous ghost rows for row 4.
- `tess-model-layer.md` T2 (name-resolving tools) and T4 (context packs) for eval row 15 and the privacy test. Without them, row 15 is "Didn't catch that."
- Nothing from Reading, Money or Upkeep is required. The people check sits after them in `TessGrammar.parse`; Upkeep's verb list shares no word with the contact phrases.
- M4 slice 5 (Day log) is not on master. Op summaries ("Met Sam", "Talked to Sam and Mum") are written now for "Talked to Sam, Mum" there.

## Later

Beyond the smallest version, not in this list:
- Contacts access through the limited picker (`contactAccessPicker`, `ContactAccessButton`) to read birthdays; `contactID` is stored for it.
- Gift ideas as a list linked to the person (`gift Sam: chalk bag`), and the birthday Now slot showing it.
- A heads-up a week before a birthday, notifications, widgets, Shortcuts and Siri "log a talk".
- Relationships between people (Sam's partner), groups and households, photos.
- A spend or a book linked to a person, once Money and Reading land.
- The Day log line, once M4 slice 5 lands.
- Never: keep-in-touch intervals, overdue lists, scores, auto-enrichment from mail or social accounts.

## Open questions for Product (each with a default)

1. **Contacts access?** Default: none (Kaushik's default). Birthdays are typed once; no prompt, no usage string.
2. **What counts as "talked"?** Default: a note or done task that links the person and holds a contact phrase from the fixed list. Any other link is "mentioned" (Kaushik's yes in `people-and-upkeep.md` question 2).
3. **Does an unknown @Name create a person?** Default: yes, one word or the bracket form, in the same transaction, undoable.
4. **Do bare names (no @) in phrases link or create people?** Default: link an existing person only after a contact phrase or in a birthday phrase; create only from a birthday phrase or a tapped "New person".
5. **When does a dated contact task count as talked?** Default: when it is done, at doneAt.
6. **A birthday heads-up a week ahead?** Default: no extra task; the birthday task shows in Upcoming and is on Now on the day.
7. **People names and Claude?** Default: only the typed phrase leaves the phone; no list of people, birthdays or notes is ever sent.
8. **A person and another object share a title (Rosemary)?** Default: @ mentions prefer the Person; grammar without a contact phrase keeps the kitchen meaning.
9. **People app or Home only?** Default: its own small app, `Features/People/`, beside Reading, Money and Upkeep on the sibling rail.
