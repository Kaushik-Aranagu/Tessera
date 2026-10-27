# Memory pyramid

Kaushik's ask (Oct 27): memory that Tess reads at whatever level of detail an ask needs. Leaves are verbatim. Each
level up is more distilled and more aware of its siblings. It should learn the way a network learns, through a
forward pass and a backward pass, but over memory rather than meaning. Start with small prototypes and learn from
the ones that fail. The full design, with prior art and the diagram, is the "Tess memory pyramid: design" doc.

## The model

- **Leaves** are his things, the op log and conversation turns, word for word. Learning never changes them. A
  private leaf is only its label.
- **Nodes** live on four axes over the same leaves: time, class, room and entity. P1 builds time only: day, week,
  month and year. A day has two parents, its week and its month. Each node keeps:
  - exact totals, computed by the engine and never by a model;
  - a residual per child: what is true of that child and not its siblings (`most sets (42)`). Strict has its own
    set, computed over only the siblings and totals it can see, so a walled sibling never shapes what it reads;
  - a hash of everything under it, so an edit marks only its own chain of ancestors stale;
  - a gist in words with a cite for every sentence (P1b, from a model, checked against its children).
- **Reading.** `zoom(path)` returns the title, the totals, then the children ranked by how much they stand out,
  within 1,200 characters. A day lists its leaves word for word.
- **Walls.** A leaf's path is a short fingerprint of its id (`leaf-3fa2c1d0`). It never names its kind, and it is
  not a count, so a missing number can't give away a walled leaf or when it happened. Under strict, a money, body
  or calendar leaf is not there at all: no line, no path, no count, no effect on a residual. A day that holds only
  walled leaves is "Nothing there". A private workout adds nothing to any total.
- **The store slice must also:**
  - build leaf text from his titles through `ObjectPrivacy.shownLabel` and the PrivateWords taint;
  - taint a told line by `isPrivateText`.
- **Forward pass.** The night pass rebuilds only the nodes whose hash changed.
- **Backward pass** (P3). A read ledger records which nodes were read, which lines were cited, where Tess had to go
  deeper, and how the checks came out. It stores paths only. Each night:
  - a fact she dug for k times is promoted into the node above it;
  - a line nobody cites for 30 days is demoted;
  - a line that misled is rewritten, and every ancestor that cites it is marked dirty.

## P1 (built): the time axis on the test world

`MemoryPyramid` (TesseraTess/Harness/Memory/Pyramid) builds the tree from `PyramidLeaf`s.
`EvalWorld.pyramidLeaves()` supplies the test world as leaves. Anything that must never count never becomes a leaf:
a deleted workout, a reversed spend or a forgotten line.

`MemoryPyramidTests` checks that:

- every level's totals are its children's sum, and the root matches the world;
- every residual is true, meaning its child holds the unique most or fewest of that total among the siblings that
  policy can see;
- a month's zoom fits in one answer and costs under a third of its leaves' text;
- one edited leaf makes exactly six paths stale: the leaf, its day, week, month and year, and the root;
- strict keeps money, sleep and the calendar out of the totals, the leaves, the paths and the counts;
- a day holding only walled leaves is not there under strict;
- strict reads every node exactly as it would if the walled leaves had never happened, and a leaf's name is a
  fingerprint, never a count.

## P1b (built, scripted): gists in words

`PyramidDistiller` (Pyramid/PyramidGist.swift) writes a node's gist through the Door: Haiku, effort low, one strict
tool `writeGist` whose cites can only name the children it was shown.

- **What the model sees** is decided by the Door's policy. It gets the node's totals, then each child it may see with
  that child's totals, residual lines and its own fresh gist, or a day's leaves word for word. Each line goes as a
  fragment with its taint, so the Door filters it too. Under strict a walled child, total or line is never sent.
- **The check** keeps a sentence only when it has a cite, every cite is a child it was shown, every number in it
  appears in its cited children's lines or the node's own totals, and it fits the level's word budget (a day 60, a
  week 120, higher levels 200). Anything else is dropped and counted by reason, never patched.
- **Kept apart by policy.** Lab and strict gists are separate, and a sentence that rests on anything walled is
  `deviceOnly`. Strict reads only strict gists.
- **Stale is exact.** A gist keeps its node's hash. `stale(in:policy:)` lists the nodes to rewrite, lowest level
  first, so `refresh` writes each node after its children and reads their new gists.
- `zoom` shows a fresh gist as "In short:" under the title.

`PyramidGistTests` runs all of it with a scripted brain, no paid call: the check drops each kind of bad sentence,
strict never sends a walled line (and its material is identical to a pyramid built without the walled leaves), a
night writes every gist bottom up, and one edit stales only its chain's gists.

**The live score** (`scripts/ai/pyramid-score.sh`, Kaushik's go Oct 27; runs on the Mac with the key there):

- Haiku writes the gists, bottom up, for the nodes the questions read: the test world's last six months and their
  year. The report counts sentences kept and dropped by reason, words per level, and a few samples.
- `PyramidScore` asks test-world questions at three depths, every answer computed from the world: a day (sets, the
  routine), a month (workouts, the day with the most sets) and a pattern (the routine or recipe he came back to most,
  the month that led the year). The node is given, not found, so this scores what a node holds; finding it is P2.
- Each question is asked three ways: the leaves themselves (flat), one zoom, and one zoom with gists.
- Spend goes through the Door and the runners' one ledger (`~/Library/Application Support/TessEval/ledger.json`),
  under the smaller of $50 and $100 minus the phone's month and the simulator's reserved $20, minus what runners
  spent.
- Under strict, every sent request is scanned for a walled leaf's words and for a key shape.
- Pass line: zoom with gists at least as accurate as flat, with at most 70% of its input tokens.

## P3 simulation (prototype, Oct 27): the backward pass on a made-up year

`scripts/ai/pyramid_sim.py` runs with no model and no API call. It builds a seeded made-up year (workouts, cooks and
notes, where each month favors one routine and one recipe) and a pyramid over it with the same totals and residuals
as `MemoryPyramid`. A reader answers about 8 asks a night, and its answers are checked exactly. It counts the nodes
opened and the tokens read per ask. The asks are: a day's routine or sets, a week's or month's workouts, a month's
busiest day, a month's most-done routine or most-cooked recipe, and "when did I last do Legs".

Four ways, the same asks:
- **flat:** every leaf under the asked node, read at once.
- **static:** the pyramid as P1 builds it. The reader digs when a node lacks the fact.
- **per-node:** the backward pass. A fact dug for k times at one node is promoted onto that node.
- **shared:** the backward pass with a weight shared per level. k digs for a kind of fact at a level promote it
  onto every node of that level, each node's line computed exactly by the engine.

The night pass demotes a line unused for 30 nights and keeps at most 3 promoted kinds per level. From night 30 the
asks stop covering recipes. Results with seed 1, k = 3 (opens per ask, tokens per ask):

| Nights | flat | static | per-node | shared |
|---|---|---|---|---|
| 1 | 1.0, 290 | 14.1, 498 | 14.1, 498 | 10.1, 358 |
| 2-5 | 1.0, 891 | 6.8, 251 | 6.8, 251 | 1.7, 71 |
| 6-10 | 1.0, 658 | 7.3, 273 | 5.8, 219 | 1.0, 44 |
| 11-29 | 1.0, 748 | 7.3, 268 | 4.1, 157 | 1.0, 43 |
| 30-45 | 1.0, 692 | 5.5, 205 | 1.6, 65 | 1.0, 43 |
| 46-60 | 1.0, 747 | 5.7, 214 | 1.5, 61 | 1.0, 43 |

Accuracy is 1.0 for every arm, because the reader digs until it finds the answer.

What it shows:
- **The shared backward pass meets P3's pass line easily.** Opens per ask fall from 10.1 to 1.7 by nights 2-5 and
  to 1.0 after. Tokens fall to about 6% of flat. Seeds 2-5 give the same shape: shared reaches 1.0 opens by nights
  6-10 every time.
- **Sharing per level is what makes it fast.** The per-node arm needs k digs on each month separately, and asks
  spread over months, so it takes about 30 nights to get close. This is the case for shared weights per level with
  per-node offsets.
- **Forgetting works.** The recipe line is demoted 30 nights after the asks stop (the lines after night 60 are
  month: top routine, root: last done).
- **k is the learning rate.** k = 1 learns in one night. k = 10 takes 6-10 nights. Neither costs accuracy here,
  because a promoted line is computed exactly.
- **Budget is the failure case.** With 1 promoted kind per month, the routine and recipe lines evict each other and
  opens stay at 2.4 to 2.9 until the recipe asks stop. With a 5-night forget window, per-node keeps losing lines it
  had earned. Budget and forgetting have to track the size of the ask mix.

What it does not show yet:
- Real asks are open-ended, not 8 fixed kinds.
- A promoted line in words, written by a model, can be wrong. Here every line is the engine's exact fact.
- The learned router and the confidence numbers ("Learned weights" in the design doc) are not in it yet. The next
  version adds them, and paraphrased asks, so that routing has to be learned rather than read off the dates.

## P3b simulation (prototype, Oct 27): learned routing weights and confidence

`scripts/ai/pyramid_router_sim.py` uses the same made-up year, with no model and no API call. Asks name their time
the way people do ("Oct", "October 2026", "last month", "3 months ago", "yesterday", "last Tuesday", "2 Oct"), so
matching the ask's words against node titles is not enough. A router scores each child of a node with weights on
(ask word, child feature) pairs; the features are the child's title words, its recency rank among its siblings and
its level. After every answer the true path is known (hindsight), and one cross-entropy step trains the weights
along it: real backprop on a linear model. Confidence is the router's own probability.

Three ways, the same 20 asks a night:
- **words:** the router frozen at its start, where only "the same word in the ask and the title" counts.
- **learned:** the router trained after every ask, walking level by level.
- **jump:** learned, plus confidence. When every step of the guessed path is at least 0.9 sure, the reader opens
  the guessed node directly; if it is wrong, it walks as usual.

Nights 21-30 (opens per ask, first try right at every step, found within 5 tries per step):

| Seed | words | learned | jump |
|---|---|---|---|
| 1 | 4.9, 48%, 88% | 3.8, 91%, 100% | 2.1 |
| 2 | 4.7, 57%, 90% | 3.8, 96%, 100% | 1.7 |
| 3 | 4.9, 52%, 88% | 3.9, 93%, 98% | 1.8 |

What it shows:
- **The weights learn what words can't.** The strongest pairs after 30 nights are "oct is october", "sep is
  september" and "nov goes to last year" (a November ask can only mean 2025 on Oct 23). Words alone miss 10-12% of
  asks entirely; the learned router finds nearly all.
- **Confidence pays.** Jumping when sure halves the opens again (about 3.8 to about 2). The threshold is the knob:
  0.7 gives 1.6 opens with more wrong jumps, 0.97 gives 2.5. A wrong jump costs one open, never a wrong answer,
  because the walk still runs.
- **About 4,700 pairs are learned for a year of one person's asks.** Small enough to keep on the phone.

Drawbacks it exposes, with the fix for each:
- **Recency features drift.** "rank1" means last year today and two years ago next January. Rank weights should be
  relative ("last month" is rank 1 among months), and a weight tied to an absolute year should decay.
- **Hindsight needs the true path.** Here it is exact. In the app, the path is the node the answer cited, which the
  cite check (P1b) already enforces; an answer with no cite trains nothing.
- **Cold start.** Nights 1-5 are no better than words. The shared per-level prior from P3 and a seed set of date
  phrasings fix this.

### P3b with dates normalized first (`--normalize`)

The input-hygiene plan (docs/ai/harness/input-hygiene.md, stage 5) resolves date words before anything reads them:
"last month" said on Oct 23 becomes "September 2026", "2 Oct" becomes "Fri, Oct 2, 2026". The same run with that
normalizer in front of the router:

| Seed | Night 1, words | Nights 21-30, words | Nights 2-5, jump | Nights 21-30, jump | Weights over 0.5 |
|---|---|---|---|---|---|
| 1 raw | 65% right, 90% found | 48%, 88% | 3.5 opens | 2.1 opens | 200 |
| 1 normalized | 95%, 100% | 99%, 100% | 1.2 opens | 1.1 opens | 36 |
| 2 raw | 35%, 80% | 57%, 90% | 3.5 | 1.7 | 212 |
| 2 normalized | 100%, 100% | 100%, 100% | 1.1 | 1.0 | 22 |
| 3 raw | 75%, 85% | 52%, 88% | 3.5 | 1.8 | 194 |
| 3 normalized | 100%, 100% | 100%, 100% | 1.4 | 1.0 | 39 |

What it shows:
- **Normalizing beats learning for anything that isn't personal.** Words alone, after the normalizer, are right on
  95-100% of asks from the first night. Without it, 30 nights of learning reach 91-96%.
- **Learning on top of clean features can hurt a little at first.** On night 1 the learned router is 80-100% right
  where words alone are 95-100%: early updates move weights that didn't need moving. The fix is to learn only the
  residual: train when the words-only route was wrong or unsure, and start the rate low.
- **What is left to learn is small.** Strong weights drop from about 200 to 22-39. The real work for the router is
  his own words ("leg day", "the chili one"), not the calendar. The next simulation adds those asks.

## P4 simulation (prototype, Oct 27): a topic axis that grows, splits and merges

`scripts/ai/pyramid_topic_sim.py` runs with no model and no API call. Free-text leaves (things he told Tess, notes,
turns) arrive 12 a night about 14 made-up topics that start, run and fade, each with 3 subtopics, with some words
shared between topics. There are no dates to file them by, so the tree grows its own shape. A node's key is the words
that set its leaves apart, counted exactly. The rules come from "Learned weights" in the design doc:

- **Split** a node past 24 children in two by 2-means over its children's words. Both halves start with the parent's
  key (Net2Net), so nothing reads differently at the moment of the split.
- **Merge** two siblings that the same asks keep using, or whose keys converge, if together they hold at most 12
  (hysteresis: well under the split line). **Collapse** a node left with one child.
- **Settle** up to 20 leaves a night into the holder whose key they clearly share more words with: one k-means step
  across the tree.
- At most 3 structural changes a night, each logged so it can be undone.

The reader goes from the root down and keeps a leaf that shares two words with the ask, the same rule flat uses.
Results with seed 1 over nights 46-60 (opens, tokens, recall per ask), from these two commands:

```
python3 scripts/ai/pyramid_topic_sim.py --key 12
python3 scripts/ai/pyramid_topic_sim.py --key 12 --reader index
```

(The script's default key is 6 words; the table uses 12.)

| Reader | flat | grow | merge | churn | settle |
|---|---|---|---|---|---|
| key (top 12 words shown, beam 2) | 1.0, 9681, 0.89 | 2.5, 472, 0.43 | 2.1, 386, 0.33 | 2.2, 384, 0.35 | |
| index (exact, never hides) | 1.0, 9681, 0.89 | 6.2, 1307, 0.89 | 5.9, 1358, 0.89 | 5.5, 1280, 0.89 | 5.0, 1095, 0.89 |

What it shows:

- **A reader that routes by shown keys loses what it can't see.** Recall falls from 0.86 to 0.33-0.43 by nights 46-60
  with 12-word keys (0.24-0.46 with 6, 0.52-0.68 with 24), and a wider beam doesn't help. So the topic axis must route
  by an exact index (which children hold a matching leaf) and use keys and weights only to rank. This is the same rule
  as the time axis: weights rank, they never hide.
- **The index reader's recall equals flat's by construction, not by measurement**: it opens every child holding a
  matching leaf. What is measured is its cost: about 12% of flat's tokens by night 60 across seeds 1-5 (settle:
  1095-1184 tokens against flat's 9676-9684). The index lookup itself (which children hold a match) is not counted in
  opens or tokens; on the phone it is a local search that never goes in a pack.
- **Scatter is the cost.** Opens grow to 5-6 a night because a split cuts a subtopic across holders and new leaves land
  on either side. Settling leaves back is the fix that works: 9-20% fewer tokens than split-only on every seed (QA
  reproduced 10-16% on seeds 1-3). Judging fit by affinity (`--fit affinity`: how many of a holder's other leaves hold
  each of the leaf's words) instead of shared key words does a little better on 4 seeds of 5 (1075-1152 tokens) and
  moves a misfiled leaf even when a small holder's key happens to list its words; the Swift `TopicTree` uses it. Merge
  alone does little here, because hysteresis blocks merging two big halves, which is its job.
- **No flips in this world**, even with no hysteresis and no cap (churn makes 3-4 times as many merges, and no split
  was undone within 10 nights). Changes stay near one a night. Hysteresis and the cap are kept as guards; this world
  doesn't stress them. A world where asks swing between a topic and its subtopics would.

What it does not show yet: real words (here every topic's words are distinct syllables), a model writing the keys or
gists, and a merge driven by asks that use both halves.

## Beyond the app: memory for anything Tess lives through

Kaushik's follow-up (Oct 27): the goal is the general memory problem for a personal assistant, not only his app
records. The app is the first step and the proof, because its numbers are exact and its test world has a key.

- **Any source is a leaf.** Conversations with Tess, things he tells her, notes, pages she reads for him, and later
  messages, mail and documents. Each leaf keeps its source, its time, its words and its taint, exactly as an app
  record does. Nothing above a leaf ever replaces it.
- **The axes generalize.** Time stays. Class and room become topic and entity, learned from free text (people,
  places he names, projects, recurring threads). Add source (where it came from) and task (what it was for).
- **What stays exact.** App records give engine totals. Free text has no engine, so its nodes carry counts and cites
  only, and every sentence in a gist must cite leaves that support it. A claim with no cite is dropped.
- **Two test beds.** The test world, where the key is exact, and public long-term memory benchmarks (LoCoMo,
  LongMemEval), so the pyramid is measured against published systems and not only against itself.
- **The walls travel with the leaf.** A leaf's taint is set where it enters (his private words, health, money,
  location are device-only), and every node above inherits the strictest taint of what it shows.

## Next prototypes

Each has a pass line set before it runs. A failure gets written up here too.

1. **P1b: gists in words.** Built and dry-run with a scripted brain (above); the live score is next.
   - Haiku writes each node's gist from its children, with cites. The check drops any sentence its cites don't
     support.
   - Pass: on test-world questions at three depths (a detail, a trend, a pattern across days), the pyramid is as
     accurate as flat recall with at least 30% fewer input tokens. Run once with residuals and once without.
2. **P2: wire it in.**
   - Add `zoom` as a tool, with a walk budget and cites down to the leaves.
   - Pass: fewer rounds per ask than flat recall.
   - **Wired (Swift, Oct 27), not yet scored:** `TessZoomTool` (`zoom(path)`) reads one node through
     `MemoryPyramid.zoom` under the Door's policy. The picker offers it on an ask about his past ("last week", "when
     did I", a month name), right after the calls that lead, so it never cuts a call he named. Like the
     other reads it runs the moment its block closes (H5, `ToolPicker.runAtOnce`). When it is offered, the pack carries one line on how
     paths look, plus "Start at <path>" when the router is sure of a day or a month. A path with nothing there names
     the nearest node above it. `TessRun` builds the pyramid from his store and keeps it until the store changes or
     the day turns. The walk budget is the run's round limit, and a day lists its leaves by path, so cites reach a
     leaf. The host still has to hand in the router it keeps (`pyramidRouter`) and the night's gists
     (`pyramidGists`). Promotions aren't passed yet.
3. **P3: the backward pass.**
   - Replay test-world asks over ten simulated nights.
   - Pass: descents per ask fall at least 30% by night 5, with no loss of accuracy. If the top fills with trivia,
     raise k.
   - **P3 shared promotion (Swift, built):** `PyramidPromotions` counts what readers had to dig for, by level and
     fact (`busiest:<total>`, `top:<kind>`, `last:<kind>`). After k digs (3) the fact shows on every node of that
     level, each node's line computed exactly by `MemoryPyramid.factLine`, right after the totals in `zoom`. A line
     unused for 30 days goes, and a level keeps 3, freshest first. Under strict a fact line is computed as if the
     walled leaves never happened; under lab a line that read one is `deviceOnly`. Only fact keys (a total or a leaf
     kind, letters only) and level names are stored.
   - **P3b (Swift, built):** `PyramidAsk` resolves an ask's dates first ("last month" on Oct 23 reads "September
     2026") and drops stop words. `PyramidRouter` scores each child by weights on (ask word, child feature) pairs,
     starting from words alone, and learns only the residual from cited answers: a step the words already get right
     and sure trains nothing. Each node keeps right and wrong counts for confidence. At night year pairs fade, nodes
     that are gone lose their counts, and the pairs are pruned to the ones that moved most. Under strict a walled node
     is never an option and a cite through one trains nothing. Weights rank; they never hide a node from a search.
     Ask words become weight keys, so `learn` takes only `PyramidTerms.walled`: an ask holding a key, a secret, a
     private title or a private word teaches nothing, key-shaped pieces are dropped, and a word walled later is
     dropped at night. The router's file is excluded from backups and its keys are never logged.
4. **P4: more axes and more sources.**
   - **Topic axis (Swift, built; simulated in `scripts/ai/pyramid_topic_sim.py`, #1480):** `TopicTree` files free-text
     leaves by their words. A node past 24 children splits by 2-means. Sibling holders merge when asks keep using both
     or their keys converge, and only into at most half of the split size. A node left with one child collapses.
     Leaves settle into the holder they fit a word better. At most 3 structural changes a night, all logged. `find` is
     an exact index: it opens every child holding a matching leaf, so keys rank and never hide. `TopicMemory` keeps
     one tree per policy, and the strict one is built only from claude-safe leaves. Each night starts with a prune,
     outside the cap: a leaf deleted, or walled after it was filed, leaves the trees that may no longer see it, and an
     emptied holder goes; a leaf plain again is filed again. The trees store node and leaf ids, never a word.
   - **Offline check on LoCoMo (`scripts/ai/pyramid_locomo_check.py`, no model):** each chat turn is a leaf and BM25
     reads at every level, so it is a floor for lexical routing. Over 1531 questions (category 5 left out), opening
     the 3 best sessions and then ranking their turns beats flat recall@10 (0.589 against 0.563) while scoring about
     95 items a question against 602. A topic tree grown over the turns by `TopicTree`'s rules, opening its 6 best
     holders, matches flat (0.559) at 183. The union of both reaches 87% of the evidence and helps multi-hop most
     (0.277 against 0.255). Every arm is weak on multi-hop and inference (about 0.26 at 10): that is where model
     gists and lateral links must earn their cost in the paid run. A chat's sessions are its natural first axis;
     the topic axis is for leaves with no session. Run with `--sessions 3` (the default); `--sessions 5` gives
     session 0.588 and topic 0.568 at 10.
   - Add class, entity and room, plus lateral links. Then conversation turns and told lines as free-text leaves,
     with topic and entity learned from their words.
   - Pass: cross-context questions are answered with cites from two axes, and the pyramid beats flat recall on
     LoCoMo and LongMemEval at equal or fewer input tokens.
5. **P5: the phone.**
   - Ships ON, under the walls. Private and money nodes are written by the phone's own model.
6. **P6: learned parts.**
   - A small router that picks the start level, and a small distiller.
   - This is the first step that may need more compute than the Mac. He offered to arrange it.
