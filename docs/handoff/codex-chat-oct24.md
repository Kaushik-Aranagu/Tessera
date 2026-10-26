# Design chat with Codex, Oct 24 (2:45 to 8:35 AM PT)

Kaushik's weekly Claude limit ran out about 2:30 AM PT. He kept designing with Codex (ChatGPT) in one chat. That chat
is not in GitHub. This note is its digest, so an agent on another system or account can continue. Raw log on his Mac:
`~/.codex/sessions/2026/10/24/rollout-2026-10-24T02-39-49-01a16d47-e04d-78c3-a4a9-bd5d99cb5109.jsonl`.
Prototypes and screenshots: `~/.codex/visualizations/2026/10/24/01a16d47-e04d-78c3-a4a9-bd5d99cb5109/originals/`
(local viewer was `http://127.0.0.1:8769/`, on his Mac only). Codex workspace: `~/Documents/ChatGPT/Tessera 2`.
Other Codex sessions in the same folder are its engineering lanes (coordinator, core/AI, iOS design, QA/ops); they
shipped no design changes after 2:33 AM PT that reached GitHub.

How he works with it: he dictates by voice, corrects fast, and says "somewhere you're doing a very bad job" when a
result drifts from the Claude boards. Codex recovered the real boards by reading them from his signed-in Chrome and
copying them into editable local HTML ("the recovered boards"). Reproducing a Claude board from specs alone failed.

## 1. Notes door pages (sheet 247, working copy from the 3 AM v1)
Decisions, all from him:
- The band at the top is the Notes word wall; spacing was increased from 3 pt to 5 pt between words, then he said it
  was fine either way.
- The band is a FIXED block on every door page (the prototype used 354 x 124 pt). Words repack inside it. When a door
  has too few words, repeat words in other colors and sizes. Effects from the landing apply: flip, departure scramble,
  dissolve, replacing words. Sizes, colors and placement may vary but must always fit.
- Notes carry areas (tags). A note may touch several areas. This is a key Notes feature: tap an area to gather every
  related note across doors.
- The lower section: he wants it better than two columns, with scroll and page transitions, as good as the band.
  Folio won: the lower section turns like a page while the band stays fixed. Both directions turn: horizontal swipes
  curl the page to the left, vertical swipes fold it top to bottom. It must look like a real flexible sheet folding,
  not a rigid plane (backside visible, crease, soft contact shadow). Codex used Grabfold's WebGL page-curl
  (`github.com/javocsoft/grabfold`). Final feel: subtle shadow, shallow curl, firm bound edge, little corner lift,
  still fluid. In-app, build the real thing in SwiftUI/Metal with the same behavior.
- Instead of "Previous note / Next note" the buttons name the neighboring notes by title.
- The small heading above the preview (and a "Titles" word) opens a searchable overlay listing every note title.
- A small card per note in the lower section; opening a note shows its own full page without the band (voice memo:
  duration, areas, transcript).
- Open note order: title, updated date, then the content directly. Areas come after the content as a control. It opens
  a small pane sized to its contents. He asked for a glass look: translucent, thin, refractive, NO border and NO bright
  rim, background text faintly visible but not competing, tone between the last two prototypes. Selecting an area opens
  that area's list. This conflicts with the older "no lens or glass" ruling; his latest ask wins for this pane only.
  Reconcile with the Design lane before building.
- Remove diagonal arrow glyphs everywhere (next to Areas, on the pane, all other places).
- The Design lane has since updated 247 (v2, 4:30 PM PT): reconcile these Codex-era changes with that version.

## 2. Keystones for every app (3 rounds)
He named it: the "keystone" (Home mosaic, Notes word wall). He wants one for every app, in the same space as Home's
mosaic, expressive, alive, interactive, with a unique selling point.
- Round 1 (nine quiet studies: tension field, counterweights, movement traces for Training; Kitchen, Recipes, Pantry,
  Lists, Routines, Weather): "none as interesting as the mosaic or the word wall"; too basic.
- Round 2 (living systems: live metal for Training, edible sculpture, time garden, paper murmuration). Verdicts:
  live metal is okay but not a whole thing, maybe for live workout mode; the recipe drawing does not scale to many
  recipes but the "pull apart to reveal a breakdown (ingredients, a plan)" interaction is great and should be reused
  elsewhere; the time garden is the favorite. Takeaway: a SCENE that reacts to what he does, adds and completes, built
  from the app's data, that also helps him navigate.
- Round 3 (scene lab): Routines got the woodland (sheet 248). A Training scene (path with cairns for logged sets, flags
  for finished movements, a pool that is the live rest timer) was started but not developed. No scenes yet for
  Kitchen, Pantry, Recipes, Lists, Weather or Money.

## 3. Routines woodland
See `design-sheets/routines-woodland-248.md` and the board https://claude.ai/artifact/KZkqPY2U6VxDMBETRu3CML.

## 4. Rules he stated that apply everywhere
- Any effect or reaction lasts at most 3 to 5 seconds.
- Info density: as much information in as little space as possible without clutter. He rejected both long lists and
  everything-on-one-screen; use dials and swipes to move between dimensions.
- He does not want tabs, pills, filter rows or redundant buttons; the item itself is the control (tap opens, swipe or
  hold completes).
- Illustrations that scale badly (per-recipe drawings) are out; scenes must scale with the amount of data.
