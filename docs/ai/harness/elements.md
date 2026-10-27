# Tess AI-first: every element says what it is and what it can do

Kaushik, Oct 25, 7:46 PM PT: "since we have the UI and its reactivity being defined, we should build stuff from the
basics to be AI first calls and expectations in the design and architecture of the elements and how they react and
what inputs and what context it would need, so that Tess would be able to figure out from the context which calls
to call."

This builds on the standing shell (`docs/design/shell-contract-283.md`, sheet 283) and the harness (the Door, lab
and strict, `AgentSpec`, `TessRun`). Code: `TesseraTess/Harness/Elements/` (`ElementContract.swift`,
`TessFrame.swift`, `ToolPicker.swift`, `ElementCatalog.swift`), tests in `ElementsTests.swift`.

## The idea in one paragraph

The shell already asks each room one question: what goes in each place. AI-first adds a second answer, given in
the same breath from the same facts: **what that place means**. That covers what it shows (by shown name, with
object ids), which item is in focus, and which calls it offers (each with its inputs, where each input comes from
when he doesn't say it, how the place reacts when the call lands, and who may run it). When he opens Tess, the
navigator gathers the meanings into a **frame** (where he is). Tess reads the frame instead of a loose "on
screen" line. The **tool picker** then sends her only the calls that fit, screen first. A short command about the
thing in focus ("done", "open this", "got it") is **bound** from the frame and runs with no model at all. When a call
lands, the place that offered it plays its own move, and Tess's soul hands off to that place.

## 1. The contract (data, no views)

| Type | What it holds |
|---|---|
| `ElementPlace` | The shell's places, the app's `Place` raw values: title, navWord, switcher, needs, doorTitle, keystone, caption, widget, glyph, dial, doorSummary, page, actionWord, tess. |
| `ElementItem` | One shown thing: object `id` (when it is one), `kind` ("task", "list item", "routine", "recipe", "spend", "door"), `name` (always the shown name: a private thing is its label), `isPrivate`, the name's `taint`, and short `facts` ("due Thu", "tonight 6:30 pm"), each with its own taint. |
| `ElementCall` | One thing the place lets Tess do. It has a `name` (a Tess tool, `open`, or a shell call), a `kind` (`.tool` writes typed actions pending, as a ghost row with Undo; `.shell` only changes what is shown), the `phrases` that name it, its `inputs`, its `reaction`, its `reach`, and the item `kinds` it applies to. |
| `CallInput` | An argument and where it comes from when his words leave it out: `asked` (his words only), `referent` ("this"), `window` (the switcher's word), `door` (the dial's focus), `now`. |
| `Reaction` | How the place answers. `strike` (the Big line is struck, Undo 10 s). `next` (the item leaves, the next rises). `keystoneTakes` (the keystone takes it its own way: a word sets, a ticket hangs, chalk is written). `reform` (the glyph re-forms). `navigate`. `lines` (needs or door summary change). `tessLine` (only her line says it). |
| `CallReach` | `anyRung`, or `deviceOnly`: rules and the phone's own model only. Every money call is `deviceOnly`, because money actions are never offered to Claude. |
| `ElementMeaning` | One place's meaning: its items, its focus index, its calls. |
| `TessFrame` | Where he is: room, level, door, the switcher's word, every place's meaning, his last touch, and now. |

**Builders (A and B).** `SlotContent` gains `meaning: ElementMeaning?`. Each `RoomContent` fills it next to the
payload, from the same facts, so the screen and Tess can never disagree. A place's calls come from
`ElementCatalog.calls(room:place:)`. The room fills the items and the focus. The navigator keeps the last touch:
place, item and time, set on every tap or swipe that lands on an item. When Tess opens, it builds the `TessFrame`
from the current `Screen` and `RoomState`.

## 2. What "this" means

`TessFrame.referent()` resolves it, in order:

1. What he touched in the last 30 s, whatever place it was on.
2. The widget's shown item.
3. The page's focused row (door pages).
4. The keystone's focused part (the word he tapped once, the tree named in the caption).
5. The dial's focused door.

"This", "it", "that", "these", "those", "them" and "here" point at the referent. Without a pointing word, a call
acts on the focused item **of the place that offers it**. So "done" on Bridge strikes the widget's one thing, even
if he last tapped a door. The item's `kind` picks between calls with the same words: "done" on a list item is
`checkListItem`, on a task `completeTask`, on a Watch tree `tendRoutine`. The kind decides, never a guess.

## 3. Picking the calls (`ToolPicker.pick`)

1. **Bound, no model.** The ask is 6 words or fewer and names exactly one call the screen offers that can act on
   its target, and the frame fills every required input. "Open this" names `openItem` and `openDoor`, but only
   one of them takes a thing. The call runs at once as Tess, pending, with a ghost row and Undo, and the place
   reacts. Examples: "done", "got it", "open this", "go back", "start" (Deck, on Push A in the widget).
2. **Money named.** A `deviceOnly` call matched ("I spent 12 on lunch" in the Purse). Only the phone's own model
   gets it, with that one tool forced. Claude never sees a money call.
3. **Everything else.** Tools in this order, at most 12:
   1. The calls his words named.
   2. Every call the screen offers, with the touched place's calls first.
   3. The room agent's tools (`AgentSpec.tools`).
   4. `query` and `open`.

   `deviceOnly` calls are never in this list. The rung:
   - A named call is a small action, so `RungPlan.plain` (Haiku, then Sonnet), unless the ask is open.
   - No call named: `RungPlan.pick` (open asks go to Sonnet, Opus second).

Why: fewer, fitting tools are the accuracy rule. A model with 20 tools picks wrong more often than one with 6, and
the frame already knows the room.

## 4. Context Tess gets (`TessFrame.fragments()`)

- `Where: Deck, the landing, This week.` (always safe).
- `This: routine Push A, tonight 6:30 pm (widget)`. The referent, with its facts.
- Up to 5 items per place, by shown name, with their facts.
- Each fragment keeps its taint, so the Door drops money, body and calendar under strict as it always has.
  `aboutIDs` (referent first) become the run's object handles, so the model can name `[o1]` and the call still
  points at the right object when its name is a label.

## 5. How elements react when Tess acts

The place that offered the call plays its own move from sheet 283, the same as for his touch, so a change by Tess
reads as the screen's own life, not an overlay:

| Reaction | What the place does |
|---|---|
| strike | The widget's Big line is struck (180 ms, then 600 ms), Undo 10 s. Lookout and Purse have none. |
| next | The item rises out and the next one rises in (the widget move). |
| keystoneTakes | The keystone's own arrival: a Log word sets in the wall, a Galley ticket hangs, Deck chalk is written, a Watch tree is planted. |
| reform | The glyph collapses to a point and forms again. |
| navigate | Places change content in place (v5): a door page opens, or an item. |
| lines | The needs or door summary change in the room's own way (types on, chalks on, prints down). |
| tessLine | Nothing moves; her line says it ("Rain alert set for 7 pm."). |
| reshape | The place takes its new look: what both forms show travels to where it goes (matched by id, 520 ms) and the rest fades; it collapses to a point only when the forms share nothing; a trait eases in place (`element-looks.md`). |

Tess's soul does `handOff(target:)` to the reacting place's frame first (tess-soul.md), then the place plays. A
bound call that the engine refuses moves nothing: her line says why.

The look of a change Tess makes is sheet 285 (`docs/design/tess-hand-285.md`, board v12 "Tess acts"):
- The place's own move plays, starting at 0.5 of the carry track.
- What she changed stays in her blue for the 10 s Undo window, then dries into the room's ink. The blue shows only
  in keystone materials and strikes, never in widget, needs or row type.
- The wash goes behind the place on keystones with gaps (Galley rail, Log wall, Watch woods). On full-bleed
  keystones (Deck, Lookout, Purse) it lies over the keystone in screen blend.
- On a refusal, the dab stops short and goes home.

## 6. Walls (by construction)

- **Claude sees everything but the key (Kaushik, Oct 27 11:59 AM PT).** Nothing sent to Claude is filtered or masked
  for privacy: money, health, body, calories, calendar, secret words and private things go as they are. One switch
  holds it, `ClaudeSees.everything` (On); under lab the pack, `open` and recall give a private thing by its own words,
  tainted `deviceOnly` so strict still drops it. The walls below are what strict keeps, and what the phone's own
  screens, widgets, backups and logs keep.
- Frame items still carry a private thing's label (the app builds them); under lab they should carry its own name,
  a follow-up. Calls carry its `id`, so "done" on a "Private item" still checks the right row.
- Money: every Purse call is `deviceOnly`. Purse names and amounts carry `deviceOnly` taint, so under strict they
  never reach Claude. Under lab they may be read, and still never acted on by Claude.
- Body, sleep and calendar facts carry `deviceOnly` taint, the same as the day digest.
- Shell calls write nothing. Tool calls are always pending (a ghost row, Undo 10 s), as `TessTools` already does.
- **A model runs only a call it was offered.** `TessRun.runTool` refuses any tool name that is not in this turn's
  pack (plus `open` and the offered shell calls), and refuses a `deviceOnly` tool on a Claude rung even if it were
  offered. So `logSpend` runs in exactly two ways: bound from the frame by the phone with no model (never today: its
  amount is asked, so it does not bind), or called by the phone's own model. Claude can neither see nor call it; a
  test scripts Claude returning `logSpend` and finds no op and an error result. A shell call's object must be a handle
  of this pack.

## 7. Room by room

On every screen: the switcher offers `showWindow`, the dial `openDoor`, the nav word `goBack`, the keystone
`openItem`, and Tess `query`. Level 1 is the landing; level 2 is a door page (Door title plus Page). The keystone
stays live on both. "Proposed" marks a tool Core still has to add over an engine action that exists
(`ElementCatalog.proposed`).

| Room | Place | Shows (kind) | Calls (inputs) | Context Tess needs | Reaction |
|---|---|---|---|---|---|
| Bridge | widget | the one thing (task) | `completeTask` (referent), `rescheduleTask` (referent, asked time), `openItem` | due time, room | strike, next |
| Bridge | keystone | mosaic faces (Now, Gallery, Weather, Workout) | `openItem` | the face's one line | navigate |
| Bridge | dial | the rooms (door) | `openDoor` | each room's one fact line | navigate |
| Log | keystone | wall words (note, list) | `openItem`, `addToList` (referent list, asked items) | titles, due items | keystoneTakes |
| Log | widget, page | items (task, list item, note) | `checkListItem` (proposed), `completeTask`, `rescheduleTask`, `pinNote` (proposed), `openItem` | due date, list name | strike, next, keystoneTakes |
| Log | action word | Write, Speak, List | `createNote`, `createList`, `createTask` (window for the time) | the switcher window | keystoneTakes |
| Lookout | widget | weather lines | `openItem` | rain hour, temps (safe: no place name) | navigate |
| Lookout | action word | Alert, Hours, Walk | `rainAlert` (proposed, window), `createTask` for a walk (window) | the rain hours | tessLine |
| Deck | widget | tonight's session (routine), this week | `startWorkout` (proposed, referent), `restDay` (proposed), `openItem` | time, sessions this week | keystoneTakes, reform |
| Deck | keystone | the board: lifts and numbers | `openItem`, `logSet` (asked) | bests, last sets | keystoneTakes (chalk) |
| Deck | action word | Start, Log, Rest | `startWorkout`, `logSet`, `restDay` | the routine up next | keystoneTakes |
| Galley | keystone | tickets (recipe, to get, dishes) | `openItem`, `startCooking` (proposed), `addGroceries` (asked) | dish, serve time, what's on the way | keystoneTakes |
| Galley | widget | tonight, tomorrow (recipe) | `startCooking`, `setServeTime` (asked), `completeTask` (dishes), `openItem` | serve time | keystoneTakes, lines, strike |
| Galley | action word | Cook, Get, Wash | `startCooking`, `cookTogether`, `addGroceries`, `startShop`, `completeTask`, `createRecipe` | pantry and groceries counts | keystoneTakes |
| Watch | keystone, widget, page | trees (routine) | `tendRoutine`, `pauseRoutine` (proposed, referent), `openItem` | today's steps, streak words (no counter) | strike (water), reform |
| Watch | action word | Plant, Water, Pause | `plantRoutine` (proposed, asked), `tendRoutine`, `pauseRoutine` | the grove | keystoneTakes |
| Purse | widget, page | amounts (spend, pool) | `openItem` | amounts as `deviceOnly` | navigate |
| Purse | action word | Log, Look, Plan | `logSpend` (proposed, `deviceOnly`, asked amount and note) | none sent to Claude | keystoneTakes |

Door pages (level 2) take the widget's calls on their rows (`page`), so "done" and "not now" work on a focused
row as they do on the widget.

## 8. Who does what next

- **Core:**
  - `TessRun.ask(_:frame:)`. Use `ToolPicker.pick` for the tool specs and the rung, `frame.fragments()` in place
    of the "On screen" line, and `frame.aboutIDs` as the handles.
  - Run a `bound` call straight through `TessTools.run` with the object id, then emit `.ghost` and the reaction.
  - Add the proposed tools over their existing actions, then drop them from `proposed`. `logSpend` is registered
    for the on-device rungs only.
  - Add tool specs for the shell calls; `TessRun` hands them to the host as a `ShellIntent`.
- **Builders A and B:**
  - Add `SlotContent.meaning` and fill it in each `RoomContent`.
  - Have the navigator keep the last touch and build the `TessFrame` when Tess opens.
  - When a ghost row lands, the shell plays the call's `Reaction` on the offering place. Tess's soul hands off to
    that place's frame first.
- **Design studio:** done in sheet 285 (section 5).
- **AI lane (this thread):** the test world gets frame questions ("done" on each room's widget, "open this", "move
  it to tomorrow" with the switcher on Tomorrow), so the runner scores the picker as well as the answers.
