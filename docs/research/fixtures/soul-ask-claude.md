# Fixture: soul events for every Claude ask (Product board item H)

**For:** Core (routing), Builder B (emitters), Builder A (the look), QA. **Owner:** Research lab. **Date:** Oct 16, 2026.
Read at origin/master, traced by hand, nothing run. Sources: `Features/Tess/SoulRouter.swift` (SR), `tess-motion.md`
§5, §13, §14 (TM), `tess-picks.md` 18a and 18c, `ai/soul-signals.md`, `ai/claude-client.md` §3 and §5 (CC),
`research/claude-requests-audit.md`, boards `core.md` and `ios-b.md`, `decisions.md` 9:58 AM.

**Contract.** A view or the client emits; `SoulRouter.handle` decides; no view sets a mode. Every ask is
`.askClaude(kind, touched:)`, then exactly one of `.claudeDone` or `.claudeFailed`. `askClaude` fires only after the
walls and `ledger.reserve` pass, just before the first request (CC §3 steps 1 to 4), so a refused ask is silent by
construction. `touched` stays on the phone and never enters a request body (CC §5, test 8). Today `SoulEvent` has a
bare `.askClaude` (SR:22) and the router maps it to thinking, not working (SR:121-124).

## 1. Asks that emit

| # | Trigger | kind | touched (in job order) | Sequence | Line while working, then after | Master today |
|---|---|---|---|---|---|---|
| A1 | Capture miss: Ask or Speak phrase the grammar and on-device model miss, switch on, key, under cap | `.capture` | `[]` (the phrase is not an object; no readers, the words have gone, TM §8 row "A Claude call out") | `.sent` (local thinking) → gather 220 ms → `askClaude` → `claudeDone` on ghosts, else `claudeFailed` | "Asking Claude." then Claude's line with UNDO, or "Claude didn't answer in time.", "Claude is busy right now.", "Didn't catch that." | Call live (`ClaudeTessModel.swift:49`); soul gets only `.sent` (`BottomChrome.swift:478`) then `.committed` or `.lineShown`. **No askClaude: not built** |
| A2 | Key check: paste or Test in Settings: Claude | `.keyCheck` | `[]` (CC §5) | `askClaude` → `claudeDone` on works or capReached, else `claudeFailed` | "Checking it with Claude." then the outcome line | **Built, bare event:** `ClaudeSection.swift:332`, `:338`; router shows thinking |
| A3 | Plan my day opened, switch on, key, under cap | `.plan` | rows the plan moves or names, in plan order (PlanPack block ids t1, e1, w1 mapped back to object ids) | rules plan draws at once → `askClaude` → `claudeDone` on a checked plan, else `claudeFailed` | "Planning your day." then "Plan ready. Push A at 12:15 pm." or "Claude didn't answer in time. Here's your usual plan." | `ClaudePlanWording.word` (`PlanWording.swift:432`) has no caller. **Not built** |
| A4 | Link read: a recipe link is fetched and parsed (L1 card, L2 text), no Claude | `.linkFetch` | `[]` until lines exist | `askClaude` → `claudeDone` on a found recipe; on L3 it continues as A5 with no second split (TM §14 rule 5) | "Reading the recipe." then the found line, or "You're offline. I'll read it when you're back." | `RecipeLinkReader` never built in App or Features (`RecipeLinkReader.swift:142`). **Not built** |
| A5 | Recipe reader L3: card and text both fail, not paywalled, switch on, key, under cap | `.recipeLink` | the parsed ingredient and step lines of the draft, in page order | joins A4's working → `claudeDone` / `claudeFailed` | "Reading the recipe." then "Claude read it. Check it, then save." or "Claude didn't answer in time. Paste the text instead." | `ClaudeRecipeReader.read` (`RecipeLinkReader.swift:347`), latent. Line on master is "No recipe card there. Asking Claude." (`:14`). **Not built** |
| A6 | Photo read in Show (Vision on the phone; the image never leaves) | `.photoRead` | the OCR lines in read order, then the ghost row they become | `askClaude` → `claudeDone` on a ghost, `claudeFailed` on "No text in that photo." | "Reading the photo." (proposed; TM lists photo reads under working) | No PageReader on master. **Not built** |
| A7 | Home lines: the trailing call after a Home fact change, Home on screen | `.homeLines` | packed `HomeFact.id`s in Home order, then memory ids (`home-lines-job.md` §7) | `askClaude` → `claudeDone` only if a slot redraws, else `claudeFailed` (silent, see ★) | No working line: the rules line stays; Failure lines never show on Home | No job, no ClaudeClient. **Not built** |
| A8 | Week story: Review shown on Monday after 04:00, facts changed | `.weekStory` | the objects behind each handle in line order (`week-story-job.md` §1.6) | `askClaude` → `claudeDone` / `claudeFailed` | "Reading your week." (proposed) | **Not built** |

## 2. Cases that emit nothing (or change only the look)

| # | Case | What happens | Event | Master today |
|---|---|---|---|---|
| N1 | Claude key shape in the phrase | "That looks like a Claude key. It goes in Review, under Claude." | none (the line only) | `TessModel.swift:69` returns before any route |
| N2 | Secret words (tacocat, a door code like 4417, "my password is hunter2") | grammar only, never Claude | none past `.sent` | `TessModel.swift:74`, `ClaudeTessModel.swift:54`; plan titles and recipe paste not yet walled (audit CA3, core.md order) |
| N3 | Money, body, health ("costco 212.37", "182.4 this morning", "took 2 advil") | on-device model or "Didn't catch that." | none past `.sent` | `PrivateFacts` at `TessModel.swift:78` and `ClaudeTessModel.swift:54`. Recipe L3 strips money spans and still asks (CC §3 step 2) |
| N4 | Switch off ("Tess asks Claude: no"), no key, or demo flags | rules or local path | none | `ClaudeTessModel.swift:50`, `PlanWording.swift:433`, `RecipeLinkReader.swift:351`; demo skips wiring at `AppModel.swift:128` |
| N5 | Cap reached ($50 a month), or a `.lines` job at 80% ($40) | "Claude paused until Nov 1." (capture, plan, recipe each add their own tail) | `lineShown` only, never `askClaude` | reserve fails before send: `ClaudeTessModel.swift:60-64`, `PlanWording.swift:447`, `RecipeLinkReader.swift:355`; 80% step-aside not built |
| N6 | Offline inbox | The failed send already ended with `claudeFailed` ("No connection. Saved it for Claude."); the save itself and the later drain emit nothing (nobody is waiting) | none | save `ClaudeTessModel.swift:113-116`; drain `TessInbox.swift:58` latent, no caller |
| N7 | Running workout | Live Ask stays on the `.live` router: `.liveAsk` then `.liveAnswered`; Home's router gets nothing, no readers on `.live`; Home lines, plan and week story never run in a workout | none on Home | `WorkoutModeView.swift:276`, `:280`; the A1 emitter must check for a live session (not built) |
| N8 | Siri and Shortcuts | Claude never writes for them | none | `ClaudeTessModel.swift:51` |
| N9 | Second ask while working | joins the running constellation; the later `claudeDone` ends it | no second split | TM §14 rule 5; not built |
| N10 | Done in flight | `askClaude` queues behind Done; `claudeFailed` clears the queue | queued | `SR:84-90`, `SR:122` |
| L1 | Reduce Motion | Events still fire. Working: 200 ms crossfade to the faded grade, mains loosened 1.5x, satellites 40%, no readers; Done its still frame. Mouth dip as a 150 ms crossfade | same events | TM §13; working look not built |
| L2 | Low Power | Events still fire. Six lights, no readers, 30 fps, colour back over 550 ms, Done as built; mouth as Reduce Motion | same events | TM §13; no Low Power path on master |
| L3 | Eyes off (the default) | No face, so `claudeFailed` has no dip: lights gather, colour returns, the line says what happened | same events | `tess-picks.md` rules; mouth not built |

**Mouth.** `curve` −0.35 for 1.2 s only on her own `claudeFailed` (timeout, busy, unreadable, nothing made), with eyes
on. Never for offline, a bad key or the cap: those are not her miss, and never at him.

## 3. Gaps

| # | Gap | Default proposed | Owner |
|---|---|---|---|
| G1 | No `onAsk` / `onDone` / `onFail` hook: Claude callers can't tell the app an ask started | `ClaudeClient` (or each caller until AI-2) calls `onAsk(kind, touched)` after reserve, before send; `onEnd(outcome)` once | Core |
| G2 | `touched` from pack builders (plan, recipe, Home lines, week story) | Each builder returns ids in job order; test that none reach the body | Core |
| G3 | `SoulEvent.askClaude` has no payload; router maps it to thinking (SR:121-124) | `.askClaude(kind:touched:)`, route to working(reading:); readers only with two or more touched words on screen | Builder A |
| G4 | `claudeFailed` can't say whose miss it was | `.claudeFailed(mine: Bool)`; the mouth dips only when `mine` | Builder A, Core sets it |
| G5 | Capture miss never emits `askClaude` (Ask shows thinking for the whole call) | `AppModel` forwards G1 to `soul.handle`, skipped while a workout is live (N7) | Builder B |
| G6 | `.missed` after a real send (Claude made nothing, `ClaudeTessModel.swift:126`) must end working | emit `claudeFailed(mine: true)` with "Didn't catch that." | Core, Builder B |
| G7 | Recipe line mismatch: master "No recipe card there. Asking Claude." vs sheet "Reading the recipe." | Working line "Reading the recipe."; keep master's line only if Design prefers it | Builder B, Design |
| G8 | Plan, link, recipe, photo and week story emitters | Emit A3 to A8 as each caller lands | Builder B |

★ **Product:** Home lines (A7) and week story (A8) run without him waiting. TM §5 says working is "for anything he
waits on", but `home-lines-job.md` §7 sends `askClaude(touched:)`. Should a background wording job split her into
working, or stay silent? Default proposed: week story shows working (he opened Review); Home lines emits nothing.
