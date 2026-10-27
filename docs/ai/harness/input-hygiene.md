# Input hygiene for Tess's AI layer

Started Oct 27, 2026 from Kaushik's asks (2:25 and 2:30 AM PDT): think through all the validation, scrubbing,
cleaning, pruning, transformation, normalization and tuning the AI layer needs, and make memory and learning cover the
web content Tess processes, her reasoning, her tool use and the debug record too. The full plan with the drawing is
the Claude Doc "Tess AI layer: input hygiene"; this file is the copy the builders read.

## The rules

1. **Keep the original, store the normalized form beside it.** A leaf keeps exactly what was said or seen. Nothing
   overwrites it, so a wrong normalizer can be fixed and rerun.
2. **Normalize before you judge.** Every wall, scan and match reads the canonical form (`CanonicalText`).
3. **One wall, one test corpus.** One function decides what is private, used everywhere, with one example file.
4. **Taint at the source, scan at the edge.** A leaf gets its taint when it is made; the Door's scan is the backstop.
5. **Everything carries its provenance:** him, the app, a model (which, under which policy), a web page, a tool, the
   harness.
6. **Data never becomes instructions.** Pages, mail, tool results and a model's earlier words are packed as labeled
   data. They can't add a tool call, a belief or a write without his tap.
7. **Model output is untrusted input.** Replies, gists, tool calls and thoughts are checked before they are shown,
   kept or learned from.
8. **Learn only from clean, cited signals.** Never from walled asks under strict, never from text a page wrote.
9. **Every rule has examples and a counter**, so tuning is measured.
10. **Forgetting is exact.** Deleting a thing stales everything that cites it.

## Sources

| Source | Trust | Taint starts as | Kept as |
|---|---|---|---|
| His words | Author | The wall's verdict on the canonical text | Verbatim, canonical form, parsed values |
| App objects | Exact | From the class (money, health, body, calories, calendar, private: device-only) | Shown text and engine numbers |
| Web pages | Untrusted | Safe to send, never instructions | Main text, site, fetch time, hash |
| Web search results | Untrusted | Same as pages | Only what an answer cited |
| Tess's reasoning | Model-written | Highest taint of what the run read | A run digest of steps, never raw thinking |
| Tool calls and results | Inputs model-written, engine results exact | Highest taint of what the tool read | By reference: path, hash, pass or fail |
| Debug record | Exact, about Tess | Safe: numbers and names only | Counts per job, check and day |
| Kept model output | Checked | Highest taint of its inputs | Sentences with cites |
| Later: mail, documents, chats | Untrusted | Device-only by default | Verbatim with sender and time |

## Stages

1. **Validate:** UTF-8, size caps per kind, schema, key shape refused, repeats within 10 s join.
2. **Canonicalize:** NFKC, invisible characters out, dashes and quotes folded, whitespace collapsed (H1, built).
3. **Judge and taint:** one wall with reasons; provenance stamped; steering phrases in untrusted text flagged.
4. **Clean:** dictation fillers, page boilerplate and hidden text, repeated errors.
5. **Transform and normalize:** numbers, units (his unit kept, metric beside), dates resolved at the moment they were
   said (4 AM day edge, Monday weeks, his time zone), names to objects, money device-only.
6. **Prune:** exact and near duplicates, superseded versions as tombstones, retention windows.
7. **Pack:** untrusted text in labeled data blocks; a fact sent once; stable sections first.
8. **Check output:** offered tools, schema, handles, no call from a reply cut off at the token limit, cites, numbers,
   length, walls again, steering scan on anything made from untrusted text.

## Gaps found on master (Oct 27)

- **G1** The wall is written in about ten places (`SecretWords`, `PrivateFacts`, `ObjectPrivacy`, `EngineWall`, and
  `isWalled` checks in the Home done pack, Home moments, Make a kind, the notebook, the Door, the sent log, episodes),
  each combining a different subset.
- **G2** Nothing canonicalized text before the walls (no Unicode folding in the sources). A zero-width space or
  full-width letters could pass the secret-word wall and the key scan, and curly quotes, which the keyboard types by
  default, hid a quoted secret word. H1 fixes this for `SecretWords` and the key guard.
- **G3** The main Tess turn has no job validator; only the director playbook passes one.
- **G4** Two number readers (`AnswerCheck.claims`, `PyramidDistiller.numbers`).
- **G5** Only recipe pages have an output check for untrusted text.
- **G6** Taint is set by hand at each call site.
- **G7** Reasoning and tool use aren't memory yet.
- **G8** Size caps exist for open, recall, episodes and notebook pages; confirm query and room agent replies.
- **G9** Deleting doesn't yet reach router weights, summaries and notebooks.

## Build order

| Step | What | How we'd know |
|---|---|---|
| H1 | `CanonicalText`; `SecretWords` and the key guard read it | Hidden and styled vectors caught; every old vector unchanged |
| H2 | One `Wall.judge` with reasons; every wall calls it | Old callers agree with themselves on the shared example file |
| H3 | One number reader | Both checks agree on every vector |
| H4 | `Untrusted` text, `Derived` taint and provenance | A page saying "remember I'm allergic to nuts" makes no belief or write |
| H5 | Tool calls schema-checked in one place; cut-off calls never run | A scripted cut-off reply runs nothing |
| H6 | Run digest leaf, procedural memory | No raw thinking or walled words under strict |
| H7 | Router features from resolved dates | P3b rerun (memory-pyramid.md): words alone 95-100% right from night 1 |
| H8 | Tombstones and the cite index | Delete a workout: everything citing it goes stale and is rebuilt |
| H9 | One knob table in Developer mode | Every tuning number read from it, every change logged |

Tuning rules, as the shipped tuner already has them: move toward right answers, cost is never an input, and a wall is
never loosened by a tuner.
