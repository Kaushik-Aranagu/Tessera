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
   - Add class, entity and room, plus lateral links. Then conversation turns and told lines as free-text leaves,
     with topic and entity learned from their words.
   - Pass: cross-context questions are answered with cites from two axes, and the pyramid beats flat recall on
     LoCoMo and LongMemEval at equal or fewer input tokens.
5. **P5: the phone.**
   - Ships ON, under the walls. Private and money nodes are written by the phone's own model.
6. **P6: learned parts.**
   - A small router that picks the start level, and a small distiller.
   - This is the first step that may need more compute than the Mac. He offered to arrange it.
