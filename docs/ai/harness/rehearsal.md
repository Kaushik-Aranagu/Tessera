# Tess tries it first: the hidden test path

Kaushik, Oct 26: "part of the job of Tess or the AI layer would be to think or process that request from user and
make the changes to the data layer, try to do some testings. And I think UI should also provide a way to do that
testing internally for the AI agents, AI layer, without showing it to the user ... whatever can be changed on-device
and can be processed ... the changes, testing part ... should be done on device."

This builds on the element and look contracts (`elements.md`, `element-looks.md`, Design sheet 286) and the
transition catalog Design is mapping, where input leads to control, control to data, and data to render. A
rehearsal sits between control and data: Tess runs the change where he can't see it, checks the result, and then
commits it for real or drops it.

## 1. The rule

- **Rehearse, check, then act.** A rehearsal never touches his store, his screen, his notifications, Health, his
  widgets or the network. When it passes, Tess makes the real change the usual way: pending, with a ghost row and a
  10 s Undo for data, or `setLook` for a look. She never copies the rehearsal back; she runs the change again on the
  real engine, so the op log is the real one.
- **On the phone.** The copy, the actions, the off-screen render and the checks all run on the phone. Only the
  model's reasoning may run elsewhere, and what it reads of a rehearsal passes the Door like any fragment (taint,
  lab and strict). Rebuilding code on the Mac or an edge server is later scope.
- **Never shown.** No ghost rows, haptics, Live Activity, notice or sound. The result goes to Tess and, in
  Developer mode, to the run trace.

## 2. When she rehearses

- **Bulk or structural writes:** more than 3 records from one ask ("move everything to tomorrow"), or anything that
  edits a plan, a routine's slots or a list's sections.
- **A look picked on an open ask:** "I don't like this dial" makes her try each candidate look off screen before she
  shows one.
- **A first try of something new:** a tool she hasn't run for him before, or a call the engine refused last time.
- **Never for a bound command:** "done", "as a column" and the like are deterministic and already have Undo.

Rehearsals have a budget: at most 3 per ask, each under 2 s on the phone. Past that she asks him instead of guessing.

**Wired (AI lane, `RehearseFlags`):** the picker reads his words, with no model. These asks are flagged:
- **Bulk:** a count over 3 of a counted thing ("my 5 tasks", "six sets"). Also "everything", or "all", "every",
  "each" or "rest" followed by my, the or of, or by a counted word.
- **Structural:** a reshape word (reorder, rearrange, restructure, regroup, reorganize, shuffle, merge). Also a shape
  word (plan, program, split, routine, slots, sections) said together with a change word (move, swap, add, remove...).

A flagged pick (`Pick.rehearse`, `Pick.count`) puts `rehearse` first in its tools. Its pack adds one line that holds
nothing of his: "This ask changes many things. Rehearse first: call rehearse with the calls you would make ...". The
line rides only when the phone has the tool. Look asks, bound commands and money asks are never flagged; money is the
phone's own rung with its one call.

## 3. Data: a copy of his store, in memory

**Engine (Core):**
- `ObjectStore.fork()` gives an in-memory copy of the graph: a GRDB backup of the database into a fresh in-memory
  queue, then a `TesseraContext` over it. The copy has no write-through, no observers, no autosave and no
  integrations. Health, the calendar and notifications hang off `ActionEngine.observe`, and the copy's engine has
  none.
- `Rehearsal(engine:)` holds one fork per run, so three tries cost one copy.
- `Rehearsal.try(_ calls: [ToolCall]) -> RehearsalResult` runs Tess's own tools (`TessTools.run`, not pending) on
  the copy and returns:
  - each call's receipt, or its refusal line;
  - the **diff**: objects made, changed and deleted, by shown name (a private thing is its label), with each field's
    old and new value; money and body values are tainted `deviceOnly`;
  - the **checks** that failed (below).

**Checks (engine, no model):**
- Every call applied, with no refusal.
- No link to a deleted object, and no object left without its parent.
- The count matches the ask when the ask says one ("move my 5 tasks", and the diff changed 5).
- Nothing outside the agent's scope changed (`MemoryScope.reads` on every changed object), so the Deck can't edit
  the Galley.
- No money action ran unless it came from the phone's own rung, the same wall as always.

**Tess's tool:** `rehearse(calls: [{name, arguments}])` returns the receipts, the diff and the failed checks as text.
It writes nothing, so it doesn't count against the ghost budget, but it does count as a round. Then she calls the
same tools for real, or says what went wrong and what she would do instead.

**How each rung reads it (AI lane, wired):**
- Core's `rehearse` tool is `deviceOnly`, because its full text can hold money, body and private values. `TessRun`
  runs it itself, with one `Rehearsal` per ask, so the ask's 3 tries are shared across rounds.
- **The phone's own model** reads `Result.text` whole: the receipts, the diff and the checks.
- **A Claude rung** reads `RehearseFlags.forClaude`: the result's fragments as the Door's policy allows, and never the
  receipts.
  - Under strict, a money, body or private line stays on the phone, and she hears how many were held back.
  - The last line is "All checks passed.", or "Checks failed: change nothing, and tell him why."
- A money call inside a rehearsal on a Claude rung still fails its check (`moneyOffPhone`). The rehearsal itself writes
  nothing, so it isn't a ghost and doesn't use the ghost budget.
- The spec Claude sees takes the tool's own input: `calls`, an array of `{name, arguments}` with the arguments as
  JSON text, and `expecting`, the count he named or null. Its description is `RehearseFlags.description`.

## 4. Looks: the quiet stage (sheet 287, section 5)

**UI (Builder A, with the shell):**
- `ShellStage.render(screen:looks:)` draws the screen he is on with the candidate look and today's content. It has no
  window and no clock, and draws only the end frame, plus the 50% frame for moves that travel.
- It is outside every `liveScope`, so nothing animates, nothing is shown, and the live gate (`live-visibility.md`)
  stays closed.
- Each item view can report a preference, `RenderedItem(id, visible, truncated, typeSize)`, which the stage gathers
  into its flags.

**Checks (on the phone, no model, no pixels sent anywhere), as a `StageReport` per place:**
- **fits:** no clipped text, lines within their count, every item in the place's `ElementMeaning` drawn.
- **floor:** no type under the room's floor at his Dynamic Type size.
- **contrast:** AA or better, in both looks.
- **rules:** at most 4 colours, the three biggest words never share one, nothing near Ember, money "about".
- **touch:** every target at least 44 pt.
- **calm:** the move ends within 1 s, and a Reduce Motion version exists.

**`tryLook` (AI lane):** on an open look ask the model gets `tryLook` before `setLook`.
- `tryLook` stages one form or trait value and returns only the flags: "Tried, not shown: the dial fails fits. Try
  another, or tell him why", or "... it passes every check. setLook shows it".
- It is not a shell call: nothing reaches the host, and nothing is kept.
- She gets at most 3 tries per ask (`TessRun.maxTries`); a fourth is refused with "That's 3 tries for this ask".
- A look that passed in this run goes straight to the shell when she sets it, so it isn't staged twice.

**Wired today (AI lane):** the host gives `TessRun.stage` a closure that stages one `LookChange`. When the model
picks a form or value with `setLook`, `TessRun` first checks the change against the place's own list. Then it stages
the change, and hands the intent to the shell only if every flag passes. Otherwise the model hears the failed checks,
for example "the dial fails fits, touch", and tries the next form or tells him why. His look stays. Only the flags
reach the model, never a picture or an item name. A bound change ("the doors as an index") is his own choice, like his
hand, so it isn't staged.

## 5. Order of work

1. **Core:** `ObjectStore.fork()`, `Rehearsal` with the diff and the engine checks, the `rehearse` tool, and its
   tests. A rehearsal must leave the real store byte for byte unchanged, and fire no observer.
2. **AI lane (this thread):** the stage gate on `setLook` is done (`TessRun.stage`, `StageReport`). Still to do:
   when she rehearses data (done: `RehearseFlags`), `tryLook` (done), and test-world cases scored on "rehearsed,
   then acted correctly" (done: `WorldKind.rehearse`; a case's `order` must come in that order). The `rehearse`
   spec and the Claude route through the Door are done too (`TessRun.rehearsed`).
3. **Builder A:** `ShellStage.render(screen:looks:) -> StageReport`, wired to `TessRun.stage`, and the
   `RenderedItem` preference on each place's item views, after the sheet 287 forms exist.
4. **Later:** a vision check of the rendered image on the phone's own model, and rebuilding code on the Mac or an
   edge server for changes bigger than a look.
