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
  - later, a gist in words with a cite for every sentence (P1b, from a model, checked against its children).
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

1. **P1b: gists in words.**
   - Haiku writes each node's gist and residual lines from its children, with cites. The night pass drops any
     sentence its cites don't support.
   - Pass: on test-world questions at three depths (a detail, a trend, a pattern across days), the pyramid is as
     accurate as flat recall with at least 30% fewer input tokens. Run once with residuals and once without.
2. **P2: wire it in.**
   - Add `zoom` as a tool, with a walk budget and cites down to the leaves.
   - Pass: fewer rounds per ask than flat recall.
3. **P3: the backward pass.**
   - Replay test-world asks over ten simulated nights.
   - Pass: descents per ask fall at least 30% by night 5, with no loss of accuracy. If the top fills with trivia,
     raise k.
4. **P4: more axes and more sources.**
   - Add class, entity and room, plus lateral links. Then conversation turns and told lines as free-text leaves,
     with topic and entity learned from their words.
   - Pass: cross-context questions are answered with cites from two axes, and the pyramid beats flat recall on
     LoCoMo and LongMemEval at equal or fewer input tokens.
5. **P5: the phone.**
   - Ships ON, under the walls. Private and money nodes are written by the phone's own model.
6. **P6: learned parts.**
   - A small router that picks the start level, and a small distiller.
   - This is the first step that may need more compute than the Mac. He offered to arrange it.
