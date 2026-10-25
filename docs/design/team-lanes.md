# Design team: three lanes (Oct 23, Kaushik 5:45 PM PDT)

Design is the whole design, not only the screens. All new ideas and corrections from Kaushik
come to Design first (via the coordinator); Design fixes the designs, then the builders build.
Coders implement. Builders (install and test) are shared.

## Lanes
1. UI and UX (lanes/ui-ux.md): screens, motion, copy, accents, the look rules in 127 and 131.
2. Data and architecture (lanes/data-architecture.md): how objects, classes, links, ops and
   the engine (TesseraCore, ObjectStore, ObjectPath, pools, ledger) are structured. A core
   principle, equal with UI.
3. AI (lanes/ai.md): Tess and Foundation Models, what the on-device AI does across every app,
   and the walls (what never reaches Claude). Third pillar.

## How a lane works
- Each lane owns a notes file: decisions made, mistakes not to repeat, research with sources,
  open questions. Read it before every round; add a line after every verdict or correction.
- A round has items from any lane; each sheet names its lane. Cross-lane items name both.
- Coders mirror the lanes (UI coders, core/data coders, AI coders), each with their own notes.
  The coordinator owns that split; Design only names the lane per item.
- Verdicts stay with Design leads and are pinned to head SHAs, as before.

## Running the lanes (coordinator, 5:46 PM)
- Each lane is an on-demand helper (Sonnet; Haiku for copies and board pages). It starts only
  when its pillar has something queued, reads its lanes/<lane>.md first, does the work, adds
  what it learned or got wrong to that file, and stops.
- Kaushik's corrections and new ideas come to Design through the coordinator. Design picks the
  pillar (or two) that fixes each one.
- Design direction and verdicts stay with the Design thread; the helpers draft and research.

## Coder routing (coordinator, 5:46 PM)
Each Mac lead runs three on-demand coder helpers: UI/UX, core and data, AI. Builders are shared;
gates, installs and cuts run on Haiku. Every sheet is addressed to its lane. UI/UX sheets go to
Builder A or B by app; data and AI sheets go to Core. Corrections arrive from the coordinator
with Kaushik's message id.
