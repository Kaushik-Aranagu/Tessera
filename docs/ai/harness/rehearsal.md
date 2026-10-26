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

## 4. Looks: an off-screen render

**UI (Builder A, with the shell):**
- `LookRehearsal.render(place:look:screen:)` draws the place's `PlaceHost` in the candidate look, with today's
  content, through `ImageRenderer`, at the place's own frame size.
- It is outside the window and outside every `liveScope`, so nothing animates, nothing is shown, and the live gate
  (`live-visibility.md`) stays closed.
- Each item view reports a preference, `RenderedItem(id, visible, truncated, typeSize)`, and the renderer gathers
  them into a `LookCheck`.

**Checks (on the phone, no model, no pixels sent anywhere):**
- Every item in the place's `ElementMeaning` is drawn, and none is cut. Sheet 286's rule is that a look keeps the
  items, focus and calls.
- Nothing is smaller than the type floor at his Dynamic Type size.
- The look rules still hold: no more than 4 colours on the page, no filled dots, and money is "about".
- With Reduce Motion on, the look's entrance has a crossfade.

**Tess's tool:** `tryLook(place, look)` returns one line, for example "Column shows all 5 doors, none cut" or
"Sentence cuts 2 of 8 doors". She shows him only a look that passed, with `setLook` (the wash, the swap, the Undo
line). If none passes, she says so and keeps his look.

## 5. Order of work

1. **Core:** `ObjectStore.fork()`, `Rehearsal` with the diff and the engine checks, the `rehearse` tool, and its
   tests. A rehearsal must leave the real store byte for byte unchanged, and fire no observer.
2. **AI lane (this thread):** when she rehearses (the picker flags bulk and structural asks), the `rehearse` and
   `tryLook` specs, the diff as fragments with taint, and test-world cases scored on "rehearsed, then acted
   correctly".
3. **Builder A:** `LookRehearsal` and the `RenderedItem` preference on each place's item views, after the sheet 286
   looks exist.
4. **Later:** a vision check of the rendered image on the phone's own model, and rebuilding code on the Mac or an
   edge server for changes bigger than a look.
