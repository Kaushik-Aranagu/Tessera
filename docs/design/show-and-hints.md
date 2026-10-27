# Show, and the phrase hints (build sheet)

> **US shop (item 25):** aisle names, amounts, fractions, pack sizes and merging for a US kitchen are in `kitchen/us-shop.md`, which wins over this sheet's metric and UK examples.

Just enough to build. Tess's capture surface (`no-buttons.md`, shipped in #107) gets two additions:
- Its **Show** layer, for photos of receipts, recipes and pages.
- **Phrase hints**: S, G and H lines, from `research/tess-discoverability.md`.

Recording: `recordings/show-and-hints.mp4` (source `studies/show-and-hints.html`):
- A receipt picked from the recent-photos row is read and logged.
- In Write, a hint drops into the field, and a G line shows under the drying ghost.
- An H line beside the soul is swiped away.

Engine and routes come from `research/capture-modes.md`: `PageReader` (Vision OCR, on device), then the route scorer, then `ReceiptTotal.read`, `RecipeParser` or a note. Photos are held in memory only.

## Show

### Opening it
- Tap **Show** in the opened column. The cadmium dab rises to the top slot (Speak's, y 594), and the other two dabs turn cadmium as they settle into the slots below (420ms, settle spring, 40ms apart).
- The words cross over to **Photos · Camera · File**, in the same places (Title 34/500, right-aligned to x 314, entering from +24pt). Video waits until frames are read (`capture-modes.md` "Later").
- Tess's question swaps through a blur to "Show me something" (or "Show me the receipt" when a shop total is awaited).

### The recent-photos row
- It rises in the wash under the question at y 476 (up 16pt, 380ms): the latest photos and screenshots at 60×80, 8pt apart, running off the right edge and scrolling on x. A photo is content, so it keeps its rectangle with a 1pt soft shadow and no corners.
- Build it with `PhotosPicker` in `.photosPickerStyle(.compact)` with `.photosPickerAccessoryVisibility(.hidden)`, so no Photos permission is needed. Check that its tiles can sit without a card behind them. If they can't, **Photos** opens the full system picker; the system picker is exempt from the no-shapes rule, like **File**.
- **Camera** opens VisionKit's document camera (`capture-modes.md` slice 2). It's system UI and exempt.
- **File** opens `fileImporter` (later).

### Reading (the living moment)
1. **Tap a photo:** the row and the words fade (200ms). The picked photo grows out of its tile to a reading view, 240×300, centred at y 120 to 420 above the wash (460ms, house curve). The dabs gather back into the corner and pulse in turn, and Tess says "Reading the receipt…" beside the soul.
2. **The brush passes:** the cadmium band from the paste screen sweeps the photo top to bottom (800ms, multiply). It's the same "read, never replaced" language as paste and link fetch.
3. **What was used gets marked:** the total row (or the lines that became ingredients) gets a 3pt cadmium under-stroke, drawn left to right in 220ms.
4. **It settles as a ghost:**
   - The photo shrinks to a 36×48 thumbnail at x 22, y 548.
   - Beside it, the ghost line reads at Title 34 and 45%: "Tesco, **£38.20**?". The amount is a value word; tap it to open the amount dial (`money-dial.md`).
   - Under it at y 612 are the **route words** in labels: **TOTAL** · RECIPE · NOTE. The chosen one is in ink with a 3pt cadmium under-stroke; tap another to switch.
   - A 1.5pt cobalt drying line runs under the ghost for 2s, then it commits and everything closes into the soul. Tess says "Groceries, £38.20. Logged." with **UNDO**.
5. **Tap the thumbnail** before it dries to see the photo full-bleed with the used lines marked. Swipe down to come back.

**By route:**
- **Recipe:** the ghost reads "Shepherd's pie, 7 ingredients". Committing opens the paste paint-over (sheet 11) with the OCR text, and the brush pass runs again there.
- **Note:** "A note: Q4 plan". It commits like a written note. Lines under 0.5 confidence show at 45% in the ghost.
- **Receipt with low confidence:** no drying. The dial opens with the amount, and Tess asks "Is the total £18.75?".

**Failure lines** (beside the soul, cobalt):
- "No text in that photo."
- "Couldn't find a total. **Type it?**" The value word opens the dial.
- "Videos aren't read yet."

**Reduce Motion:** no growth and no band. The photo crossfades to the thumbnail and ghost, and the marks fade in together.

## Phrase hints
Three kinds, one at a time, and never more than three shows a day. The research brief sets the retire rules (used twice, ignored on three days, swiped; S and G lines end on day 15). The ledger is `TessHintLedger` in `UserDefaults`. Every line passes `TessVoice.violations`.

### S: in Write (placeholder and one phrase)
- **Placeholder:** a real phrase for the context on the writing line, at Title 34/500 and 28% ink. Examples: "bench 80x8, or ask" when idle, "same, 8, or 80x8" in a workout, "timer pasta 10" with a recipe open. Typing replaces it.
- **One more phrase** sits **between the question and the field** (y 468), at 21/400 and 55% ink, with no weight and no wash: "milk, eggs, 2 lemons". It sits above the field because the keyboard covers everything under it.
  - **Tap it:** it travels down into the field and inks (21 → 34, 55% → 100%, 360ms, house curve) with the caret at its end. It never sends. `.selection` fires.
  - It's set apart from the column's **fast paths**. Those are value words (21/600 full ink) that act on tap, and they leave when Write opens. A hint is a lighter phrase that only fills the field.
- The current build shows two phrases ("log bench 82.5×8 · bench best?"). Make it one.
- **Speak** gets its one line (#20) as Tess's resting line beside the soul, on the first days: "Hold me and say it: 80 for 8." That waits for Speak (V2).

### G: under the drying ghost
- After Return, while the ghost dries (2s), one line fades in under the drying line, 300ms after it starts (y 566 in Write, under the route words in Show). It's 21/400 in `inkSecondary`, with the phrase itself in 600 ink: "You can also say **buy milk and eggs**."
- It goes when the ghost commits or is swiped away, and never delays the commit.

### H: beside the soul, after something done by hand
- Once, in Tess's line slot beside the soul (right 78, bottom 43, width 262), cobalt 21 with the phrase in 600: "Next time, this works: **book physio fri 9am**." It stays 4s, the same as her other lines.
- **Tap the phrase** to open Write with it in the field (it never sends).
- **Swipe it right** to retire it: it follows the finger and fades (200ms). There's no confirm.
- Never shown while a ghost is drying or rest is running, and at most one a day.

### Never
Coach marks, tooltips, outlines, chips, capsules, dots, counts of hints left, red, or sound. A hint appears by opacity through `MotionPolicy`. Reduce Motion: no travel into the field, just a crossfade. VoiceOver reads the S line as the field's `accessibilityHint`, once.

## Owners
| Part | Where | Owner |
|---|---|---|
| Show layer: words, dab recolour, recent-photos row, reading view, ghost with thumbnail and route words | `Command/BottomChrome.swift` (TessCapture) | Builder B |
| `PageReader`, route scorer, `ReceiptTotal.read`, OCR to the paste screen | `TesseraCore`, `Features/Recipes` | Core |
| S, G and H lines, `TessHintLedger` | `Command/BottomChrome.swift`, `TesseraTess` | Builder B (lines), Core (ledger and parse table) |
