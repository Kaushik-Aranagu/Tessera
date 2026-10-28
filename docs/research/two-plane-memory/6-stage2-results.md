# Two-plane memory: stage 2 results

Run Oct 28, 2026 on public benchmarks and public model weights only (LoCoMo, LongMemEval-S). The plan with every pass
bar, committed before any stage 2 number existed: `5-stage2-plan.md`. Code and result files:
`scripts/ai/small_models/stage2/` (README). Results page with charts:
https://claude.ai/artifact/4aCLFzoq5PuYbnpJvgb2QE. The cloud ran 2.2 and the 2.3 ranker; Core ran 2.1, the 2.3 vectors
and 2.4 on the Mac (Apple M4). No paid Claude calls.

## Verdict

The proposed stage 3 gate is not met. It needed P11 to pass (2.4) and a large model to beat bge-small at the ranker
level within the time limit (2.3, or 2.2 for Qwen3-Embedding-0.6B). P11 failed, so the gate fails even with speed
ignored. Of the four tests, 2.1 passed on the Mac and 2.2, 2.3 and 2.4 failed. An independent check reread every result
file against its script and the plan, recomputed the key numbers, and found no number that disagrees; its wording
corrections are applied here and on the results page.

- **2.1 pass on the Mac, phone not checked.** bge-small as a 128-token fp16 Core ML program matches the fp32 model (mean
  cosine 0.99999, lowest 0.99998; bridge read 0.6622 to 0.6621) and takes 1.17 ms at p95 on the Neural Engine against
  the 10 ms bar (median 1.14 ms; first load 1.5 s, later 0.04 s). Core ML puts 74% of its cost on the Neural Engine;
  almost all the rest is the embedding lookup, which runs on the CPU inside the measured time.
- **2.2 fail for both encoders.** Qwen3-Embedding-0.6B is "fail: better but too slow": with the ranker, LoCoMo 0.7732
  against 0.7492, +0.024 (+0.010 to +0.038, Holm p 0.018 one-sided, 0.035 two-sided, 8 of 10 chats better),
  LongMemEval-S +0.004 (−0.012 to +0.020), but 30.1 ms at p95 on the Neural Engine (129 ms on the GPU). bge-base is
  fast (7.2 ms) with no clear gain: +0.008 (−0.005 to +0.024, Holm p 0.17). Reported with no bar: on the bridge read
  both beat bge-small (Qwen3 +0.053, +0.023 to +0.080; bge-base +0.021, +0.002 to +0.039); after BM25 fusion neither
  gain is clear.
- **2.3 fail.** Calibration passed (8-bit against the bf16-weight reference: mean cosine 0.9998 final, 0.9994 after the
  heads). The ranker on CLM-8B's list: 0.641 against 0.749, −0.108 (−0.134 to −0.077), lower in all 10 chats. CLM
  alone 0.193; CLM fused with BM25 0.500, below BM25 alone (0.561) and below the front matter's bar (0.655, −0.156).
  CLM as a third list looked like +0.024 over the fused read, but the control set in the script before the run (the
  bge-small bridge list counted twice) does as well: CLM minus control −0.011 (−0.031 to +0.013). CLM scores as extra
  ranker features: +0.009 (−0.005 to +0.022).
- **2.4 fail (C3 and P11).** C3: the tap closest to bge-small by held-out cosine is block 9 of 36 (0.459), outside the
  55–80% window, whose taps score 0.422 to 0.428. It beats the final tap (0.445) by +0.014 (+0.007 to +0.023), but it
  was picked as the best of 14 on the same numbers. P11: dev pairs picked the final tap in all 5 folds; hidden read
  0.413 against the bar 0.634 (text read 0.662), −0.249 (−0.279 to −0.219), no chat higher. Fused 0.577 against 0.655.
  Best tap seen after the fact: block 15, 0.485.

## What it does not show

- 2.2 does not show that bigger encoders don't help. Qwen3-Embedding's gain is clear; only its speed failed, for one
  build (fp16, 128 tokens) timed on the Mac. An 8-bit or shorter-input build was not tried. For bge-base a gain was
  not established on 10 chats, which is not the same as no gain.
- 2.3 does not show that heads trained for this task would fail. CLM's heads were used as they come, never tuned for
  question-to-evidence matching; on their own they fall below BM25. The gate's rationale ("heads we train ourselves on
  far less data are unlikely to") is an argument, not a measured result.
- 2.4 does not show that hidden states cannot carry memory. The converter Π, trained on 17,707 to 18,386 public texts
  per fold, copied bge-small only loosely (cosine 0.445 at the chosen tap), and the method expects P11 to hold only when
  held-out L_align is low. LoRA, in-domain data, other pooling, bridges retrained on hidden states and the soft-token
  injector are untested. The "more text does not help" hint comes only from the Qwen3-0.6B pilot (s24c: reads 0.369,
  0.368, 0.371, 0.363 for 0, 2k, 8k and 32k added texts while cosine rose 0.407 to 0.454) and was never run on 8B.
- 2.1 does not cover the phone (not connected), texts over 128 tokens (about 2.8% of LongMemEval-S turns), or a p95
  interval (raw timings were not kept; the two test processes gave 1.18 and 1.16 ms).

So stage 2 shows that the simple versions failed. It does not refute the idea; it gives no sign yet that GPUs would pay.

## Post hoc and labelling notes

- Found after the result, deciding nothing: the s23c head-use variants (best alone 0.102, reading "zero-shot CLM is the
  wrong tool for this memory, however its heads are used"), the s24c scaling pilot, the best-tap-by-test-recall figure,
  and the observation that BM25 fusion lowers both bigger encoders' bridge reads.
- Set in code before the run but not in the plan: the one-sided sign-flip convention (two-sided values stored too; no
  verdict changes), the bridge-list-twice control in s23b, bge-base in the 2.1 script, Qwen3's rewritten norm for fp16.
- Chosen after a first look, before any 8B run: s24's `--pi-fit refit` default (after an uncommitted dev-out 0.6B pilot).
- Not saved, so only checked for consistency: 2.1's raw timings and Core ML vectors, and 2.4's 8B per-question arrays
  (C3's interval and P11's paired interval are Mac-only).

## Options (Kaushik's call)

1. **Ship the ranker and the free fusion fix in Tess and stop the research here** (the plan's suggested path when the
   gate fails). The phone side is ready: bge-small on the Neural Engine at about 1 ms per text.
2. **One cheap Mac test first:** time a faster Qwen3-Embedding-0.6B build (8-bit weights or a shorter input) to see
   whether its +0.024 fits under 10 ms. No GPUs.
3. **Stage 3 on rented GPUs anyway**, to train the converter properly (LoRA or in-domain data) until P11 holds. The gate
   does not support it; it needs a cost estimate first.
