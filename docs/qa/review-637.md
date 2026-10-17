# QA review: #637 (Builder B, fix for #597 lows)

Head: eaf588c. Merge-tree clean on master. 2 files, +36/-1.

## Verdict: PASS at eaf588c (2 lows, not blocking)

- L1 closed. ObjectPage latches the note-or-masked choice (noteLatch) at first appearance and on route change; content resolves through resolveOpensAsNote(latched:live:), so a plain note no longer flips to the masked page while typing. A private note still opens masked, because the latch is taken from the live label check at appearance.
- L2 partly closed. Body-only walled notes ("paid 40 for lunch", "slept 5 hours") now have tests, and the latch resolver is tested.

## Lows
1. The body-only test asserts `opensAsNote == (label == nil)`, which holds for any outcome. Pin it to exact outcomes: opensAsNote is false and the label is "Private note" for both bodies.
2. onAppear does not reset a non-nil latch (only a route change does). Fine while a pushed page is recreated per navigation; if the page is ever kept alive across a note being made private elsewhere, it would stay in the editor. Add a one-line comment, or reset on disappear.

Both can ride the next Builder B push.
