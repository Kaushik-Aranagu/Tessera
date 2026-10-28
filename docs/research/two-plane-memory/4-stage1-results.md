# Two-plane memory: stage 1 results

Run Oct 27 to 28, 2026 on public benchmarks only (LoCoMo, LongMemEval-S). Code, results and the verdict table:
`scripts/ai/small_models/stage1/` (README). Results page with charts:
https://claude.ai/artifact/SPTsVfoGVoMKNyHRWbPizg. Haiku spend $1.28.

## Verdict

Stage 1 clears its gate by the letter only, on learning from cites. Of tests 1.1 to 1.11, three passed (1.2, 1.4,
1.9), seven failed and one was inconclusive. Every test was reread by an independent reviewer who recomputed its key
numbers. Test 1.12, added afterward with its bar set in advance, found no detectable gain from learned keys on top of a
learned ranker.

- **Learning from cites (1.2) is real and small.** Centred pull and push on Haiku's cites: +0.008 recall@10 on the
  bridge read, +0.0065 after BM25 fusion, intervals above zero, holds over 20 question orders, and needs Haiku's
  choice of cites (top hits, random picks and a placebo give nothing). Picked fairly on dev chats the fused interval
  touches zero; the gain comes only from questions that reuse evidence; it ties RMM-style heads.
- **Reading again (1.3) helps answers, not the memory.** +0.047 recall over the first read, but fusing the question's
  own bridge list in place of each of Haiku's searches does as well (`s13b_hops_control.py`). Answer accuracy +7.6
  and +8.9 points comes from the reader: a forced last answer, its notes and more snippets.
- **A learned ranker (1.11) is the big lever.** LightGBM lambdarank reordering the fused top 50, trained on the gold
  evidence of other public chats: +0.094 on LoCoMo, +0.020 on LongMemEval-S (interval just above zero). Score and rank
  features alone give about two thirds of it, so equal-weight RRF fusion wastes signal.
- **Learned keys on top of the ranker (1.12): +0.001** (−0.009 to +0.011, sign-flip p 0.41). Any gain is at most
  about 1 point.
- **The math was mixed.** Fixes held in narrow tests (key-view target, exact forgetting from cite logs); several
  predictions missed (rank effect on LoCoMo, centred drift, month-level summaries, hub cost shape, alias calibration).

## What it does not show

Nothing in stage 1 touched what GPUs would train (hidden-state projector, soft-token injector, joint fine-tuning), so
the trained form of the idea is untested, not refuted. All learning-from-use evidence comes from 10 LoCoMo chats.

## What could go into Tess (pending Kaushik's pick)

1. **Fusion fix, free:** fuse the BM25-fused read with the plain bridge list again (RRF k 60). LoCoMo 0.655 to 0.696,
   LongMemEval-S 0.898 to 0.915, post hoc; needs a check on the Tessera test world before it ships.
2. **Ranker:** the s111 LightGBM model over 25 features (largest gain shares: RRF score, bridge gap to best, bridge
   z-score, fused position, same session as the top hit, BM25 over best). Trained on public data only, so it can ship
   as a fixed model; a small tree ensemble can be evaluated directly in Swift. Needs a Tessera test-world check first.
3. **Read-again as an answer habit:** let Tess search again when the first read is not enough (up to 3 reads). It
   raises answer accuracy, at the cost of extra model calls.
