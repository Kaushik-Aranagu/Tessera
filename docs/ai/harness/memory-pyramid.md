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
  - a residual per child: what is true of that child and not its siblings (`most sets (42)`);
  - a hash of everything under it, so an edit marks only its own chain of ancestors stale;
  - later, a gist in words with a cite for every sentence (P1b, from a model, checked against its children).
- **Reading.** `zoom(path)` returns the title, the totals, then the children ranked by how much they stand out,
  within 1,200 characters. A day lists its leaves word for word.
- **Walls.** A leaf's path is neutral (`leaf-3`) and never names its kind. Under strict, a money, body or calendar
  leaf is not there at all: no line, no path, no count. A day that holds only walled leaves is "Nothing there". A
  private workout adds nothing to any total.
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
- every residual is true, meaning its child holds the unique most or fewest of that total among its siblings;
- a month's zoom fits in one answer and costs under a third of its leaves' text;
- one edited leaf makes exactly six paths stale: the leaf, its day, week, month and year, and the root;
- strict keeps money, sleep and the calendar out of the totals, the leaves, the paths and the counts;
- a day holding only walled leaves is not there under strict.

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
4. **P4: more axes.**
   - Add class, entity and room, plus lateral links.
   - Pass: cross-context questions are answered with cites from two axes.
5. **P5: the phone.**
   - Ships ON, under the walls. Private and money nodes are written by the phone's own model.
6. **P6: learned parts.**
   - A small router that picks the start level, and a small distiller.
   - This is the first step that may need more compute than the Mac. He offered to arrange it.
