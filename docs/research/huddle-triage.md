# Huddle triage: from Kaushik's remarks to board items

Research lab, 2026-10-15. For the first phone review (build cut 19:45 UTC, guide in `../product/review-session.md`). Copy this file per huddle, for example `huddle-2026-10-15.md`, and fill it in. Do not edit board files from here; each lead writes its own.

## 1. How to use it (5 steps)

1. **Paste.** The coordinator or Product pastes Kaushik's remarks into section 4, nearly verbatim, one remark per row. Keep his words; split a remark only when it touches two owners.
2. **Fill the row.** Pick the area and owner from section 2, then type, size and severity from section 3. Check `v1-gap-audit.md` and the owner's Next first: if the remark matches an existing item, write "matches <file> Next n" and add his quote to that item instead of a new line.
3. **Write the board line.** One line in the owner's format: what it is, the spec link if any, "Done when ...", then `(Kaushik, huddle HH:MM: "his words")`. The owner's lead pastes it into its own `board/<team>.md`.
4. **Place it.** Bugs on something already shipped go to the top of the owner's Next. Look-and-feel polish goes to Design first (Design takes review feedback ahead of its Next). Ideas go to Product to slot against the priority order in `../ops/board.md`.
5. **Batch the questions.** Any row with Decision = y goes into one list in section 7, sent once to Kaushik through the coordinator. Nobody asks him one by one.

## 2. Ownership map

| Area | Owner | Notes |
|---|---|---|
| Home (rail, Now, Today, What's running) | iOS Builder B | Design for look; Research `context-packing.md` for what shows |
| Workout and live mode (dial, drum, hold, finish) | iOS Builder A | Engine gaps (prefill, RemoveSlot, EditSet) go to Core |
| Rest Live Activity, Lock Screen, Dynamic Island | iOS Builder A | Watch Smart Stack layout is Core Next 2 |
| Exercise page | iOS Builder A | |
| Plans (week, month) | iOS Builder A | Rest days in the week come from Core |
| Routine editor | iOS Builder A | Remove-slot action is Core |
| Kitchen screens (recipe page, paste, cook mode, shelf) | Core engine | Kitchen lead accepts; Builder B wires them into Home |
| Groceries | Core engine | Kitchen lead accepts |
| Lists | Core (engine), Builder B (screens 9-12) | Kitchen lead accepts |
| Notes | Builder B (hookup to Home) | Note parsing is Core grammar |
| Review (week as counts) | Builder B (hookup to Home) | Counts come from Core |
| Tess capture (bar, ghost row, voice) | Builder B (surface), Core (grammar, model layer) | Design owns the soul and the capture surface sheet |
| Widgets and snippets | iOS Builder A | Design `widgets-and-snippets.md` |
| Design system (Theme, type, buttons, motion) | iOS Builder A builds; Design studio decides | Button sweep is Builder A Next 1 |
| Engine (TesseraCore, ledger, progression) | Core engine | |
| Data (safety, migration, Health, Claude key) | Core engine | QA reviews; Settings look is Design |
| Priorities, new areas, scope | Product lead | |

## 3. Size, type and severity

- **Size:** XS under 1 hour. S an afternoon. M one slice. L needs a spec first (Product or Research writes it before anyone builds).
- **Type:** bug (shipped thing does the wrong thing), polish (works, but feel, type, motion or copy falls short of the bar), idea (something new).
- **Severity:** blocks daily use (he would stop using it at the gym or in the shop), annoying (works around it), nice (would like it).
- **Bar check for polish rows:** no cards, no pills or rounded-rectangle buttons, Inter Tight, big type, motion through `MotionPolicy`, no guilt and no red. A fix that breaks one of these is not done.
- **Velocity:** an XS or S bug that blocks daily use ships before the next gym day, even if rough; polish follows.

## 4. Triage table

| # | Kaushik said (verbatim) | Area | Owner | Type | Size | Severity | Board line to add | Decision (y/n) |
|---|---|---|---|---|---|---|---|---|
| 1 | | | | | | | | |
| 2 | | | | | | | | |
| 3 | | | | | | | | |
| 4 | | | | | | | | |
| 5 | | | | | | | | |
| 6 | | | | | | | | |

Add rows as needed. Known gaps he was told not to report (progression not raising the weight, voice) still get logged if he raises them, as "matches core.md Next 1" or "matches ios-b.md Next 2".

## 5. Pre-filled rows: the 9 huddle questions

| Q | Question | Likely owner | If yes / answer A becomes | If no / answer B becomes | Decision |
|---|---|---|---|---|---|
| 1 | What did you reach for first, what didn't you find? | Builder B, Product | Missing thing: Builder B Next line "Rail or Home entry for X. Done when X is one swipe or tap from Home." | Found everything: no item; note "rail confirmed" in `../product/decisions.md` | n |
| 2 | Is one hold, dial and drum fast enough between sets? | Builder A | Fast enough: Product shifts next week toward new areas (Tess model layer, Lists) | In the way: top of Builder A Next "Gym friction fix: <what>. Done when a set logs in under N s on the phone, with a recording." | n |
| 3 | Does the look feel like yours? What first? | Design studio | Yes: no item; Design proceeds with no-buttons and capture surface | No: top of Design Next "Redirect <paint/type/seams/bloom>. Done when a revised sheet and recording replace the current values." | n |
| 4 | What should Tess do in week one? | Core (model layer), Product | His pick orders T2 tools: Core Now note "T2 tool order: <his list>." | Nothing chosen: keep Research's default order in `tess-model-layer.md` | y |
| 5 | Which area would you open daily after gym and kitchen? | Product | Product Next "Ship list order after M4: <area> first." | Unsure: keep M5 order Reading, Money, Upkeep, People | y |
| 6 | What's running: ledger or plate stack? | Builder B, Design | Plate stack: Builder B Next "What's running as plate stack per `docs/design/plate-stack.md`. Done when it replaces the ledger, with a recording." | Ledger (recommended): Design closes the concept; no Builder B item | y |
| 7 | Claude's monthly cap? | Core, Design (Settings) | $10 hard stop (recommended): Core T-layer line "Cap at $10/month, fall back to the phone and tell him once." | Other amount: same line with his number | y |
| 8 | Can Claude see sleep and energy? | Core | No (recommended): Core line "Model context sends only light day yes/no. Done when a test proves no Health values leave the phone." | Yes: Research writes the data scope first (L), then Core | y |
| 9 | Grammar misses go to Claude automatically? | Core, Design | Yes (recommended): Core line "Grammar miss routes to Claude as an undoable ghost row." Design line "Cloud mark on the bloom." Coordinator asks for the API key. | No: Core line "Grammar miss stays a note; Claude only on an explicit ask." | y |

## 6. Worked examples (made up)

| # | Kaushik said | Area | Owner | Type | Size | Severity | Board line to add | Decision |
|---|---|---|---|---|---|---|---|---|
| E1 | "the rest timer is too small on the lock screen" | Rest Live Activity | Builder A (Design for values) | polish | S | annoying | Builder A Next 2: "Lock Screen rest countdown readable at arm's length. Done when the countdown uses Design's large numeral size, Done stays one tap, and a phone photo is in the PR. (Kaushik, huddle 20:10: 'the rest timer is too small on the lock screen')" | n |
| E2 | "I want to log water" | New tracking | Product | idea | L | nice | Product Next: "Water logging as a small daily count, via Tess ('water 500') and the Day log. Done when it has a ship-list line slotted after M4 or into Day log. (Kaushik, huddle 20:14: 'I want to log water')" | y: daily habit or Day log entry? |
| E3 | "Home feels empty in the morning" | Home | Builder B, Research | polish | M | annoying | Builder B Next, after slice 8: "Morning Home shows the day's plan from context packing. Done when the 07:00 moment in `../research/context-packing.md` renders with the routine and first task, with a recording. (Kaushik, huddle 20:18: 'Home feels empty in the morning')" | n |

## 7. Follow-through checklist

- [ ] Every row has owner, type, size, severity and a board line, or a "matches" note.
- [ ] Bugs on shipped things are at the top of the owner's Next; look-and-feel rows sent to Design first.
- [ ] Each lead has posted its lines to its own `board/<team>.md`; Product updated `../ops/board.md` if order changed.
- [ ] Mac teams (Core, Builder A, Builder B) told via the coordinator, with their lines pasted in full.
- [ ] Batched questions sent once to Kaushik through the coordinator:
  1. 
  2. 
- [ ] His answers to Q4 to Q9 logged in `../product/decisions.md`.
- [ ] Recap line to Kaushik: "Got N remarks: X bugs fixed before your next gym day, Y polish with Design, Z ideas queued. N questions below."
