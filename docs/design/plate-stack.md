# The plate stack (concept, M2): What's running when there are 3 or more processes

A prototype of the idea in Product's `whats-running.md` ("suspended processes sit as stepped slivers behind Now and fan out when you pull Now down"). It's an **alternative to the ledger rows under Now** (`home-v1.md`) for when 3 or more processes are paused or waiting. Recording: `recordings/plate-stack.mp4` (source `studies/plate-stack.html`). It isn't scheduled; Builder B keeps the ledger until Kaushik has tried this.

## Closed: slivers behind Now
- Now is the front plate. Behind it, each paused or waiting process shows only **its seam**, peeking out above the Now line: the most recent sits at y 210, right under Now, and each deeper plate sits 6pt higher and 14pt narrower on each side. You see a stepped stack edge on, like machined plates.
- Seam state is as in the ledger: a lit vermilion seam for suspended, an engraved unlit one for waiting. Deeper plates fade by 18% each.
- It costs about 20pt of height, freeing the ~70pt the ledger row took, so the queue window gets taller.
- Arrival: Now enters, then the slivers step out from under it one by one (70ms stagger, 8pt down, 300ms).

## Pull Now down: the stack fans out
- Dragging the hero down moves the whole Now block (line, hero, key) down 1:1 to 300pt. The plates are revealed behind it as **ledger rows** in place (64pt, subject 21/600, next step at 18, Resume or Open on the right), each sliding from its sliver to its row. They never cross: the most recent lands nearest Now.
- The rows are clipped by Now's top edge, so they appear from behind it rather than over it. The queue fades out as Now covers it.
- Release past 120pt stays open; under that it springs back (house spring). Tess says the count in words: "Two paused, one waiting."
- Pull up, or tap Now, to close.

## Tap a plate: it comes forward
- Now's contents fade (220ms). The tapped plate's resume point grows into the hero (21 → 56, matched geometry, 520ms on the house curve) while the stack closes behind it.
- The old Now becomes the plate right under the new Now ("Paused just now, 22 min left"). That's a z-swap, not a navigation.
- The key becomes Resume (vermilion), and Tess says "Back to bench. Draft is paused."

## Why it might beat the ledger
The ledger spends a full row per process and caps at 3. The stack spends 20pt whatever the count, says "there's more behind this" physically, and turns switching into one gesture with a clear spatial story (pull to look behind, tap to bring forward). The risk is discoverability: a pull on the hero isn't obvious. The slivers are the hint, and Tess can teach it once ("Pull Now down to see what's paused").
