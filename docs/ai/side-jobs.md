# Tess on the side: three jobs (sheet 75)

*AI architecture, Oct 16, 2026. Design's sheet 75 (`every-side.md`, "Tess on the side") asks for three things. Research wrote the fixtures; this file is the job card for each. Product's 2:52 pm rulings apply throughout: a side sends nothing to Claude by default, an opt-in per class covers public facts only, and only Ingredient and Exercise send a public name.*

| Job | Who computes | Claude | Fixture (Research) | Gate |
|---|---|---|---|---|
| 1. Tess's side line | the phone | off; no rewording on sides | `docs/research/fixtures/side-lines.md` (75 rows, 22 glance rows, 10 edge cases) | Swift tests per row (section 6 of the fixture) |
| 2. Ask about this | the phone packs the subject | only through "Tess asks Claude", and only for a public-name class that opted in | `docs/research/fixtures/ask-about-this-walls.md` (AW1 to AW20) | no-call packer tests; zero hard fails |
| 3. Facts Claude may fill | the phone's table first (USDA FoodData Central per 100 g, Kitchen lead accepted) | fills a gap once, kept on the object with its source | `docs/research/fixtures/claude-facts-packs.json` + `claude-facts-eval.md` | `scripts/ai/claude_facts_eval.py`, run only on Kaushik's yes |

## 1. Tess's side line

- **One line, counted on the phone,** in her band at the end of every side. It is the same at the glance and on the full side. No Claude call makes it.
- **Claude never rewords a side line.** Home's "Sonnet on Home" (`home-lines-job.md` 2b) covers finished workouts on Home only. A side line is a count the phone already got right, and AI-5 showed rewording a correct rules line adds nothing (Voice 3/13). Revisit only if Kaushik asks.
- **Caps:** `HomeLines.fitsDetail` (14 words, 80 characters, one sentence, a stop, no "?" or "!"). Glance small facts use the context cap.
- **Never filler.** An empty band is right whenever the fixture's E1 to E8 match (body or money side, private object, walled line, first day, too little history, a zero, live workout, repeats the front). Every row has a filler trap that must stay out.
- **Walls on the finished line:** `SecretWords.mentions` and `PrivateFacts.isWalled` both false, or the line is dropped, never reworded.
- **Data Core builds** (fixture Q5): the task move count, routine last run, cook durations, buy cadence over the op log (bought rows are deleted at the shop's end, so cadence reads the op log or keeps a buy date on the ingredient), and planned cooks. Each line ships when its helper does; until then its band stays empty.
- **Open with Design and Product** (fixture section 7): one sentence for "Moved twice, and today's the day."; count-first lines on a side; rolls are not moves; a body habit's side stays empty.

## 2. Ask about this

- **The subject.** Opening the ask slot on a side makes the thing the subject. The phone sends `{"subject": {"handle", "class", "name"}, "fields", "question"}` to Claude. The real id stays on the phone behind a handle (`s1`), as groceries do.
- **Name only for public names.** `name` goes for Ingredient and Exercise only (Product 2:52), after both walls pass. Every other class sends its class word ("task", "note"), as Plan my day does. That narrows Research's five public-name classes to two; Recipe, Muscle and Equipment send the class word.
- **Fields** are only those the wall table marks Claude yes. Nothing from a Habits, Settings, money or body side goes to Claude at all.
- **Order of checks:** key shape, secret word in the question, money or body in the question, the switch, the cap. A refused ask makes no Claude event and shows the house line ("It's in your private notes." or "That stays on this phone.").
- **Intake stays on the phone.** "Is this enough protein for me" gets one ingredient's table value and never a sum (Product 2:36).
- **Today** the ask slot has no subject and a "?" question stays on the phone (`BottomChrome.swift`). This job is the packer `AskSubjectPack` plus its tests. No eval run is needed: the AW packs are a no-call dry check of the packer, and a hard fail is any private field, note words, money, body fact, secret or key-shaped text in either payload.

## 3. Facts Claude may fill

- **Table first.** With the USDA per-100 g table on the phone, Claude fills only a food the table has no row for, and an exercise's primary muscles. The 14 food packs are gap cases (foods missing from the table), not unknowables.
- **Once, kept, sourced.** One call per thing, ever. The answer is stored on the object with "From Claude, Oct 16" shown beside it. A decline stores nothing and the side is complete without the row.
- **What rides:** the public name and the kind only (`{"kind": "food", "name": "..."}`). No handle, id, notes, history or amounts.
- **Model:** Sonnet 5.5, effort low, one strict tool `fillFacts`, tool choice auto.
- **Gate:** range rows 90%+, exact rows 90%+, refuse rows 18 of 18, no extra fields 90 of 90, zero hard fails, zero cut off, a full run under $0.25 (worst case $0.234). The runner is `scripts/ai/claude_facts_eval.py`, dry by default. A live run needs Kaushik's own ask in the running thread.
- **Opt-in:** per class (Product 2:52), behind "Tess asks Claude" and the monthly cap. It stays off until the eval passes and he says yes.

## 4. Where a filled fact lives (spec for Core)

Nothing here exists yet; Core builds it behind the opt-in. It is a catalog version of its own (the next number, additive).

- **Muscles.** A filled exercise writes its `primaryMuscles` and `secondaryMuscles` refs, the fields Exercise already has, as a pending ghost row through `ActionEngine` (by `.tess`, route `claude`), so undo and the receipt work like every other Claude write. Only `MuscleSeed` names are accepted; anything else drops the whole answer.
- **Nutrition.** An Ingredient gains four optional number fields (kcal, protein g, fat g, carbs g, all per 100 g) and one `factsSource` text field. The table value and a Claude value use the same fields; `factsSource` is empty for the table and "From Claude, Oct 16" for a fill (house date style, written by the phone, never by Claude).
- **Asked once.** A `factsAsked` date on the object. Any answer, including a decline, sets it, so nothing asks that thing again. A decline writes nothing else.
- **Table wins.** A table row, when it lands later, replaces a Claude fill and clears `factsSource`.
- **Checks before a write:** every number is non-negative and under a per-field ceiling, macros do not sum above 100 g, and the walls pass on the name.
- **Never summed.** The app shows one ingredient's values only (Product 2:36 pm).
- **Walls (Product 2:40 and 2:45 pm).** Only public per-100 g food facts and exercise muscles are stored. A measured body value, an intake or an amount is never stored, sent or filled by Claude.
