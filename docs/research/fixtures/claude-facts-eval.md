# Facts Claude may fill: the eval plan (sheet 75, Tess on the side, item 3)

*Research, Oct 16, 2026, against origin/master a438262. Written only: nothing here was run or sent. Any run needs Kaushik's yes in the running thread first. Fixture: `docs/research/fixtures/claude-facts-packs.json` (30 packs, 12 wall inputs, the echo list). The runner is AI architecture's to write; this plan names its shape.*

## 1. What the job is

Design (every-side.md, Tess on the side 3): Claude may fill only public facts about a named thing, such as a food's nutrition per 100 g or an exercise's primary muscles. A fact fills only when the phone's table has no row, is kept on the object with its source shown ("From Claude, Oct 16"), and is asked once. Without Claude the side is complete without that row. Product 2:36 pm (2): the app never sums nutrition; the PER 100 G side shows one ingredient's values only. Research BE owns the food table itself (USDA FoodData Central licence and subset).

One call per pack: the system prompt, one strict tool `fillFacts`, and a user turn holding only the public name and the kind (`{"kind": "food", "name": "Banana, raw"}`). Nothing else rides: no handle, no id, no notes, no history.

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
| Self-test before any call | Exactly 30 packs (14 food, 10 exercise, 6 unknowable); every muscle in truth is a `MuscleSeed` name; every wall input is refused or stripped by the packer stand-in as the fixture says; no echo string appears in any request; every request body is at most 1,560 bytes; one mismatch and it exits before sending |

## 3. The 30 packs

Tolerance: kcal within 15% of truth; each macro within 20% or 1.5 g, whichever is larger. Muscles: the reply holds every required muscle and nothing outside allowed.

| # | Name | Expect | Truth (per 100 g: kcal, protein, fat, carbs; or primary muscles) | Source type |
|---|---|---|---|---|
| F01 | Chicken breast, skinless, raw | range | 120, 22.5, 2.6, 0 | USDA FDC, SR Legacy |
| F02 | Ground beef, 80% lean, raw | range | 254, 17.2, 20.0, 0 | USDA FDC, SR Legacy |
| F03 | Egg, whole, raw | range | 143, 12.6, 9.5, 0.7 | USDA FDC, SR Legacy |
| F04 | Atlantic salmon, farmed, raw | range | 208, 20.4, 13.4, 0 | USDA FDC, SR Legacy |
| F05 | White rice, long grain, cooked | range | 130, 2.7, 0.3, 28.2 | USDA FDC, SR Legacy |
| F06 | Rolled oats, dry | range | 379, 13.2, 6.5, 67.7 | USDA FDC, SR Legacy |
| F07 | Black beans, cooked | range | 132, 8.9, 0.5, 23.7 | USDA FDC, SR Legacy |
| F08 | Broccoli, raw | range | 34, 2.8, 0.4, 6.6 | USDA FDC, SR Legacy |
| F09 | Banana, raw | range | 89, 1.1, 0.3, 22.8 | USDA FDC, SR Legacy |
| F10 | Avocado, raw | range | 160, 2.0, 14.7, 8.5 | USDA FDC, SR Legacy |
| F11 | Greek yogurt, plain, nonfat | range | 59, 10.2, 0.4, 3.6 | USDA FDC, SR Legacy |
| F12 | Cheddar cheese | range | 404, 24.0, 33.0, 2.0 | USDA FDC, typical |
| F13 | Peanut butter, smooth | range | 588, 25.0, 50.0, 20.0 | USDA FDC, SR Legacy |
| F14 | Olive oil, extra virgin | range | 884, 0, 100, 0 | USDA FDC, SR Legacy |
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
| U02 | Tacocat bars (food) | refuse | decline | none: made-up product |
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
