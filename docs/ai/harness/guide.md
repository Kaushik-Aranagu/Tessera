# Tess's guide: she knows the app and herself

Kaushik's ask (Oct 27): Tess should know the app itself (its rooms, screens, calls, knobs and tools), keep her context
sensible by loading the right facts when an ask needs them, and later carry this knowledge in small trained models.
The full plan is the "Tess knows herself: plan" doc. This page is the first slice, plus the build order for engineers.

## The first slice (built)

`TessGuide` (TesseraTess/Harness/Guide/TessGuide.swift) is a book of short pages, built from the same catalogs that
the screens and tools are built from. Tess reads it with one tool, `guide(path)`:

- A path reads a page (`/calls/pauseRoutine`). Words search the pages (`how do I pause`) and return their paths.
- Every answer is at most 1,200 characters. Each page ends with the paths it leads to (progressive disclosure).
- The guide holds what the app is, never his data. Every page is claude-safe under strict, on every rung.

| Shelf | What a page says | Built from |
|---|---|---|
| `/you` | Who she is: rungs, the Door, Undo, caps per ask, memory tools | Written; caps from code |
| `/rules` | His house rules: weeks start Monday, Undo 10 s, swipes, money colors, no full stops | Written |
| `/rooms/<room>` | The calls each place offers in the room | `ElementCatalog` |
| `/places/<place>` | What the place is, where it offers calls, its forms | `ElementPlace`, `LookCatalog` |
| `/calls/<call>` | What it does, inputs, words, reaction, reach, where | `ElementCatalog`, `TessTools` |
| `/looks/forms/<f>`, `/looks/traits/<t>` | Each form and trait, values, designed | `ElementForms`, `LookCatalog` |
| `/tools/<tool>` | Every tool she may be offered, with its inputs | `TessRun.toolSpecs`, shell specs, `TessTools.all` |

Wiring:

- `ToolPicker.pick` offers `guide` on asks about the app or her ("how do I", "what does", "where is", "why did
  you", `TessGuide.isAbout`). It goes right after the calls he named, so the 12-tool limit never cuts it.
- When the pick offers the guide, the pack carries `TessGuide.contentsLine`: one line saying what each shelf holds
  (tier 1).
- `TessRun` runs `guide` like `open`: read only, with nothing written. A run interrupted before it ran reads as
  interrupted, not "nothing was changed".

`TessGuideTests` fails if any of these lacks a page: a room, place, call, form, trait or tool. It also fails if a page
names a path that isn't one, or if a page is clipped. A new call can't ship without a page.

## Next slices (in order)

1. Test-world questions about the app ("how do I pause the Watch"), scored against the guide's pages. Add these
   after the rehearsal PR lands, because it changes `EvalWorldKey`.
2. Later shelves:
   - `/classes`: classes and fields, from `SystemCatalog`.
   - `/settings`: every knob and what it changes.
   - `/screens`: from the builders' shell code.
   - `/code`: a map of which file owns what, generated on the Mac.
3. The context ledger. Each run records which fragments and pages were loaded and which were used, by path only and
   never the text. The night pass computes hit rates per ask kind. `BudgetTuner` preloads a page that is fetched on 8
   of 10 asks of a kind and drops a fragment that is never used.
4. Checks go live. The answer check gets one retry once false fails are under 2% on the test world. Next come a
   belief check (a reply that contradicts a kept belief gets one retry) and open loops ("I'll check tomorrow" becomes
   an object).
5. The curriculum generator, on the Mac:
   - It writes asks for every call, place and room.
   - Claude solves them on synthetic test-world data only, never his data.
   - The engine's checks keep only the right answers.
6. Small models, one job at a time, starting with call routing. Each job runs through four stages:
   - fine-tuning: LoRA in MLX on the Mac;
   - reinforcement learning: GRPO, with rewards from `CallConformance`, rehearsal, `AnswerCheck` and the world key;
   - a gate: the model must beat the current rung on that job's cases and pass every privacy-wall case;
   - a shipping choice: an Apple adapter needs the paid account's entitlement, and Gemma in the app adds size. That
     choice is his.
