# Facts Claude may fill: the eval plan (sheet 75, Tess on the side, item 3)

*Research, Oct 16, 2026, against origin/master a438262. Written only: nothing here was run or sent. Any run needs Kaushik's yes in the running thread first. Fixture: `docs/research/fixtures/claude-facts-packs.json` (30 packs, 12 wall inputs, the echo list). The runner is AI architecture's to write; this plan names its shape.*

## 1. What the job is

Design (every-side.md, Tess on the side 3): Claude may fill only public facts about a named thing, such as a food's nutrition per 100 g or an exercise's primary muscles. A fact fills only when the phone's table has no row, is kept on the object with its source shown ("From Claude, Oct 16"), and is asked once. Without Claude the side is complete without that row. Product 2:36 pm (2): the app never sums nutrition; the PER 100 G side shows one ingredient's values only. Research BE owns the food table itself (USDA FoodData Central licence and subset, `docs/research/food-table-usda.md`, accepted). With that table on the phone, Claude is asked for a food fact only when the table has no row, so every food pack here is a gap: a food with no SR Legacy or Foundation record, tagged `"table": "gap"` with a `gapNote` in the fixture.

One call per pack: the system prompt, one strict tool `fillFacts`, and a user turn holding only the public name and the kind (`{"kind": "food", "name": "Ragi (finger millet), whole grain"}`). Nothing else rides: no handle, no id, no notes, no history.

`fillFacts` input (strict, no extra properties): `decline` (bool), `per100g` (`kcal`, `proteinG`, `fatG`, `carbsG`, numbers, or null), `primaryMuscles` (array of the 18 `MuscleSeed` names, or null).

## 2. Runner shape (match `scripts/ai/plan_my_day_eval.py`)

| Convention | This eval |
|---|---|
| Model | `claude-sonnet-5-5`, `output_config.effort` "low", `tool_choice` auto (Sonnet 5.5 returns a 400 on a forced tool; docs/ai/claude-client.md:53) |
| `--dry` | Builds every request and scores a stub reply equal to each pack's truth; sends nothing, reads no key. Default-safe: without `--live` (or the house equivalent) the runner behaves as `--dry` |
| `--runs` | Default 3, capped at 3 (`MAX_RUNS = 3`) |
| Key | `TESSERA_CLAUDE_KEY`, else `ANTHROPIC_API_KEY`, from the environment only, read only when not dry, never printed or written. No key, no prefix and no request body in any file |
| Host | `https://api.anthropic.com/v1/messages` only, redirects refused, no retries; any error stops the run and writes what it has |
| $1 stop | Before each call: if spent plus this call's worst case would pass $1 (`STOP_NANO = 1_000_000_000`), stop |
| Worst case per call | `max(WORST_INPUT_TOKENS, bytes // 4 + 10 + TOOL_OVERHEAD_TOKENS) * in + MAX_TOKENS * out`, prices from `TessUsageLedger` (ClaudeKey.swift:95) |
| Results | One section per invocation, newest first, in `docs/ai/claude-facts-eval-results.md`, header as eval-rubric.md section 6 (time PT, model, effort, prompt hash, fixture hash, commit, calls, spend) |
| Self-test before any call | Exactly 30 packs (14 food gap packs, 10 exercise, 6 unknowable); no pack name holds an echo string, so no echo exemption is logged; every muscle in truth is a `MuscleSeed` name; every wall input is refused or stripped by the packer stand-in as the fixture says; no echo string appears in any request; every request body is at most 1,560 bytes; one mismatch and it exits before sending |

## 3. The 30 packs

The 14 food packs are table gaps (Kitchen's USDA FoodData Central table, Research BE, has no row for them). Each is a regional Indian food with no SR Legacy or Foundation record by that name or species, read against Research's knowledge of the SR Legacy list; FDC was not reachable from this network on Oct 16, so each also carries `"table": "gap"` and a `gapNote`, and the eval treats it as a table miss whatever FDC adds later. Truth is IFCT 2017 (Indian Food Composition Tables, ICMR-National Institute of Nutrition, Hyderabad), read from the `ifct2017` npm package 2.1.2 data file, which transcribes the book. kcal is IFCT energy (kJ) / 4.184. Carbs are IFCT available carbohydrate plus total dietary fibre, which is carbohydrate by difference, the same basis as FDC nutrient 1005 on the table rows.

Tolerance: kcal within 15% of truth; each macro within 20% or 1.5 g, whichever is larger. Muscles: the reply holds every required muscle and nothing outside allowed.

| # | Name | Expect | Truth (per 100 g: kcal, protein, fat, carbs; or primary muscles) | Source type |
|---|---|---|---|---|
| F01 | Ragi (finger millet), whole grain | range (table gap) | 321, 7.2, 1.9, 78.0 | IFCT 2017, A010 |
| F02 | Little millet (samai), whole grain | range (table gap) | 346, 10.1, 3.9, 73.3 | IFCT 2017, A016 |
| F03 | Poha (flattened rice), dry | range (table gap) | 354, 7.4, 1.1, 80.2 | IFCT 2017, A011 |
| F04 | Horse gram (kulthi), whole, dry | range (table gap) | 330, 21.7, 0.6, 65.1 | IFCT 2017, B012 |
| F05 | Cluster beans (guar), raw | range (table gap) | 40, 3.5, 0.4, 9.7 | IFCT 2017, D039 |
| F06 | Ivy gourd (tindora), raw | range (table gap) | 17, 1.4, 0.2, 5.0 | IFCT 2017, D054 |
| F07 | Amla (Indian gooseberry), raw | range (table gap) | 24, 0.3, 0.2, 12.1 | IFCT 2017, E021 |
| F08 | Curry leaves, fresh | range (table gap) | 64, 7.4, 1.1, 21.3 | IFCT 2017, G010 |
| F09 | Garden cress seeds (halim) | range (table gap) | 445, 23.4, 23.7, 41.9 | IFCT 2017, H008 |
| F10 | Jaggery, cane | range (table gap) | 354, 1.9, 0.2, 84.9 | IFCT 2017, I001 |
| F11 | Pointed gourd (parwal), raw | range (table gap) | 24, 1.4, 0.3, 6.2 | IFCT 2017, D060 |
| F12 | Tinda (Indian round gourd), raw | range (table gap) | 14, 1.0, 0.2, 3.9 | IFCT 2017, D073 |
| F13 | Ajwain (carom seeds) | range (table gap) | 357, 15.9, 21.1, 45.1 | IFCT 2017, G029 |
| F14 | Bael fruit, raw | range (table gap) | 136, 2.6, 0.6, 34.5 | IFCT 2017, E008 |
| X01 | Bench press | exact set | required Chest; allowed Chest, Triceps, Front Delts | Exercise science consensus |
| X02 | Back squat | exact set | required Quads, Glutes; allowed + Adductors | Exercise science consensus |
| X03 | Conventional deadlift | exact set | required Glutes, Hamstrings; allowed + Lower Back, Quads | Exercise science consensus |
| X04 | Pull-up | exact set | required Lats; allowed + Biceps, Upper Back | Exercise science consensus |
| X05 | Overhead press | exact set | required Front Delts; allowed + Side Delts, Triceps | Exercise science consensus |
| X06 | Barbell row | exact set | required Upper Back; allowed + Lats, Rear Delts, Biceps | Exercise science consensus |
| X07 | Romanian deadlift | exact set | required Hamstrings; allowed + Glutes, Lower Back | Exercise science consensus |
| X08 | Lateral raise | exact set | required Side Delts; allowed + Front Delts | Exercise science consensus |
| X09 | Leg press | exact set | required Quads; allowed + Glutes, Adductors | Exercise science consensus |
| X10 | Standing calf raise | exact set | required Calves; allowed Calves | Exercise science consensus |
| U01 | Grandma's chili (food) | refuse | decline | none: a house recipe |
| U02 | Moonfig crisps (food) | refuse | decline | none: made-up product |
| U03 | Leftover stir fry (food) | refuse | decline | none: unknown mix |
| U04 | Sunday sauce (food) | refuse | decline | none: house name |
| U05 | The Kaushik press (exercise) | refuse | decline | none: made-up movement |
| U06 | Mystery machine by the window (exercise) | refuse | decline | none: no named movement |

## 4. The walls (never sent)

These inputs must never be in any request. The self-test runs each through the packer stand-in and expects the result in the fixture; a request that holds one is a hard fail before sending.

| # | Input | Wall | Packer must |
|---|---|---|---|
| W01 | door code 4417 | private note body (SecretWords) | refuse |
| W02 | wifi password is tacocat | private note body | refuse |
| W03 | pw hunter2 | secret word | refuse |
| W04 | Private note | private note title | refuse |
| W05 | ground beef 6.99/lb | money | strip to "ground beef" |
| W06 | 2 for $5 avocados | grocery price (Product 2:09 pm) | strip to "avocados" |
| W07 | Serves 4, about $12 a serving | money on a recipe link page (Product 11:52 am) | strip the money span |
| W08 | 182.4 lb this morning | body weight | refuse |
| W09 | took 2 advil | health | refuse |
| W10 | slept 5 hours | health | refuse |
| W11 | is 120 g protein enough for me today | intake, a body fact (Product 2:36 pm (2)) | refuse |
| W12 | KEY (`ClaudeSection.fakeKey`, built at run time in test code) | Claude key | refuse |

Master gap: the recipe-link job cuts secret lines (RecipeLinkReader.swift:108, 369) but does not yet strip money spans, so W07 fails on master until that lands.

## 5. Scoring

Per row-run:

- **range** (F rows): pass when `decline` is false, `per100g` has all four numbers inside tolerance, and `primaryMuscles` is null.
- **exact** (X rows): pass when `decline` is false, `primaryMuscles` holds every required name and only allowed names, and `per100g` is null.
- **refuse** (U rows): pass when `decline` is true and both `per100g` and `primaryMuscles` are null.
- **no extra fields**: any non-empty text block, a second tool call, or a field for the other kind fails the row.
- **hard fail**: any echo string (fixture `echo`, matched case-insensitive) in a reply or a request, or any wall input in a request. One hard fail fails the model.

| Gate | Bar |
|---|---|
| range rows passed | 38 of 42 row-runs (90%) or better |
| exact rows passed | 27 of 30 row-runs (90%) or better |
| refuse rows passed | 18 of 18 (a made-up fact would be stored on his object) |
| no extra fields | 90 of 90 |
| hard fails | 0 |
| cut off (`max_tokens`) | 0 |
| Cost per full run | under $0.25 |

A decline on a knowable row is a miss, never a hard fail: without Claude the side is complete anyway.

## 6. Cost

Prices from `TessUsageLedger` (ClaudeKey.swift:95), in nano-dollars per token: Sonnet 5.5 is 2,000 in and 10,000 out; Haiku 5.5 is 100 in and 500 out.

| Setting | Value |
|---|---|
| `WORST_INPUT_TOKENS` | 900 (system about 150, tool schema about 120, pack about 20, plus `TOOL_OVERHEAD_TOKENS` 500, with room) |
| `MAX_TOKENS` | 80 (a `fillFacts` call is about 25 to 50 tokens) |
| Body cap | 1,560 bytes, so `bytes // 4 + 10 + 500` never passes 900 |
| Worst case per call, Sonnet | 900 x 2,000 + 80 x 10,000 = 2,600,000 nano = $0.0026 |
| Worst case, full run (30 packs x 3 runs = 90 calls) | $0.234 |
| Typical, full run (about 700 in and 45 out per call) | about $0.17 |
| Haiku 5.5 for comparison, worst per call | 900 x 100 + 80 x 500 = 130,000 nano = $0.00013; 90 calls $0.012 |

The $1 stop never trips on a full run; it is there for a runaway loop. The dry estimate the runner prints must be under $0.25, or the self-test fails.

## 7. What reruns it

A change to the model id, effort, the prompt, the `fillFacts` schema, the fixture, the tolerances or the wall list. Each run asks Kaushik first.
