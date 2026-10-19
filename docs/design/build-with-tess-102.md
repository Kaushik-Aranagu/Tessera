# 102. Build with Tess: one sentence in, a ghost app out

**Ask (Product, huddle batch 9, Oct 19):** "Build me an app from one sentence, using only the block catalog, shown as a ghost you accept." Switch: **Build with Tess**, off by default, behind Tess asks Claude and inside the $50 a month cap. Extends `ghost-class.md` (A4, the ghost class page, already drawn) and `product/ship-list-build.md` (slices A1 to A4, `proposeClass`, `proposeFields`, `proposeList`, `useExisting`, `clarify`). A4 draws one class. This sheet draws the whole app that comes out of a sentence and every state around it. Spec only; not yet okayed by Kaushik.

## The idea in one line
He says what he wants to track. Tess draws the app it would be, as a faint cobalt page he can change in place. One tap makes it real, one word skips it. Nothing is written until he says so.

## A. What "an app" means here
Built only from the block catalog already on the phone (classes, fields, a starter view, a List, a Chore or Habit by reuse rule 3). No code runs, nothing downloads, no new kinds. An app = **one ghost page, up to four blocks**: the class (name and fields), its starter view, any routed object (a Chore, a Habit, a List), and a Home line for it. Reuse comes first: an exact match opens what exists (`useExisting`, "You already have Plants.", no ghost).

## B. The flow, screen by screen
1. **Ask.** The Build with Tess switch is on. In the ask slot he says or types "I want to track my plants". The grammar marks `TessUse.buildClass`; the phone pre-matches first (reuse rules 1 to 3) and only an unmatched request leaves the phone (see E).
2. **Working.** Her line: "Drawing what a plant has." (A4 ends this line with an ellipsis; it changes to a full stop). Tess's dabs pulse in turn. The ask slot shows the sentence he said at 21 `inkSecondary` above her. Cancel is an ink word, "Stop", that ends the call and leaves nothing.
3. **Ghost.** The page assembles top-down in cobalt at 62%, as `ghost-class.md`, with four blocks in this order: breadcrumb and hero name (56); WHAT A PLANT HAS (field rows, 21, kind words tappable); HOW IT SHOWS (starter view, one row); AND ALONGSIDE (the routed Chore, Habit or List as one sentence, and "On Home as one line" as a toggle word, default off). Samples are 2 or 3 faint lines under SAMPLES, NOT SAVED and are never written.
4. **Change it.** Everything on the ghost is editable in place by the A4 and sheet 101 rules (tap kind word, swipe a field away, tap the hero to rename, hold a row to move). Saying more to Tess re-proposes; new rows paint in where they belong. At most one re-proposal call is added to the cost line.
5. **Accept.** **Make Plants** is one ink-word tap; no hold, no auto-commit after any delay (schema is a bigger write). The page dries from cobalt to ink top-down (520 ms a line, 60 ms stagger); Tess says "Made Plants." with Undo for the whole op group. No success haptic: the page drying is the result (A4 rule).
6. **Skip.** **Not now** is a 16 ink word on the right. It discards the whole proposal, the ghost fades in 220 ms, and Tess says "Skipped." Nothing is stored; the sentence is not remembered; asking again costs a new call.
7. **Undo** after accept removes class, fields, view, routed object and Home line in one step, for as long as the usual Undo window allows; later it is a normal Remix (101).

## C. States
| State | Look and words |
|---|---|
| Switch off | The sentence is handled as a normal capture; Tess says one plain line, "Build with Tess is off. Turn it on in Settings, Review." with the Settings row as an ink word |
| Needs Claude | If Tess asks Claude is off: "Build with Tess needs Tess asks Claude." The word goes to that row. Nothing is sent |
| Empty (just opened, nothing said) | The ask slot with one faint line: "Say what you want to track." |
| Working | As B2; time shown as nothing (no estimate); a slow call changes her line once to "Still drawing." |
| Ghost | As B3; hero 56, rows 21, labels 16; three sizes |
| Reused | No ghost: the existing class page opens; "You already have Plants." |
| Clarify | One question in Tess's line, answered by voice or one of two options as ink words ("Plants, or your Garden list?"); no dialog |
| Accepted | As B5; the empty class page shows "No plants yet. Say monstera, kitchen." |
| Skipped | As B6 |
| Rejected twice | The kernel rejected the proposal twice: Tess says the reason in plain words ("It asked for 11 fields. The limit is 8.") and offers "Try again" as an ink word; nothing is written |
| Failed write | One soft `.warning` haptic and "That did not save." The ghost stays so he can Keep again |
| Offline | "I can not draw it with no network." The sentence stays in the slot; nothing queues silently |
| Private / masked | A proposal whose class or field names would be a Private word is not drawn; Tess says "That one stays private. I can make it on the phone, with no Claude." and offers a plain on-phone class with the name he typed shown as "Private class" at 100% ink |
| Reduce Motion / Low Power | 150 ms crossfades; no breath, no paint-in, dabs still |
| AX1+ | Rows stack name above kind; Make and Not now stack, Make first; ghost page one column |
| VoiceOver | Prefix "Proposed class Plants, not saved yet"; each field "Spot, text"; Make and Not now are actions; after accept focus lands on the hero |
| Obsidian | Ghost in Tess cobalt, made page in ink |

## D. The one-line spend note
Under Make, a 16 `inkSecondary` line, shown only when the call cost something: "About 1 cent." (the A1 table puts a call near $0.01). It matches the Settings spend line. No total, no meter on this screen.

## E. What Tess may send to Claude (walls from sheet 80 apply)
- **Sent:** his one sentence (up to 600 characters; longer is refused), the class catalog pack (class names, field names and kinds, no objects), and the proposal that comes back for one retry.
- **Never sent:** any object's title or values, notes, places, health, money, body numbers, anything on a Private page, the Claude key or anything key-shaped, or the sentence itself when it is a Private word (the SecretWords refusal comes first; a phrase the on-phone grammar can answer or wall stays on the phone).
- **Receipt:** the sentence is shown masked in the sent log (sheet 80) as "Build with Tess" with a count, never the words. The call counts toward the monthly cap; at the cap Tess says so and the phone still offers the on-phone class.
- **Off means off:** with Tess asks Claude off, nothing leaves the phone and Build with Tess shows Needs Claude.

## Side (sheet 75)
The ghost's side is **WHY THESE**: for each field, where it came from in plain words ("Rating is the same shape as in Books", "Location is new"), one 21 line each, row name first. It is the answer to "why did she add that", and it never shows any object's words.

## Never
A form or a list of checkboxes; a confirmation dialog; an auto-accept after any time; samples written as real objects; the proposal remembered after Not now; a score or "AI built" badge; a pill or card; ellipsis in copy; italics; a faded or diffused Tess; sending anything the walls name.

## For Core and Builder B
- Core: needs A1 to A3 (schema ops, `proposeClass`, local matcher); the Home line and routed object ride in the same op group; Skip leaves no op. Rejected twice, Offline and Private/masked are states of the same router result, not new calls.
- Builder B: the ghost is the A4 ghost class page with two extra blocks (HOW IT SHOWS, AND ALONGSIDE) and a side; the Settings row lives in sheet 100 (Review) and is added there by Product (value Off, On; default Off; shows Needs Claude when Tess asks Claude is off).
- Open question for Product: should "On Home as one line" default to off (my recommendation: off, he chooses) or on?
