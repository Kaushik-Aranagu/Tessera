## Reviewer corrections to "Algorithms and latency"

**Rerun setup.** I reran every script unchanged from a copy in `/tmp/claude-0/algos/review/rerun/` (results in `results/*.json`, logs in `logs/`). All runs were sequential, with OMP_NUM_THREADS=1, on an idle 4-core VM. The CPU reports as "Intel Xeon @ 2.10GHz" with AMX and a 260 MiB L3. My side checks are in `/tmp/claude-0/algos/review/side/` (`s1_checks.py`, `s2_int8batch.py`, `s3_within_chat.py`, `compare.py`; output in `s1.out` and `s2.out`).

### 1. What reproduced
- **Listed medians:** 44 of 54 fall within ±30%.
- **All raw rows:** 139 of 188 fall within ±30%. Of the 49 misses, 36 take under 1 ms (Python overhead).
- **Overlaps and fidelities:** every one reproduces exactly.
- **Encoder rows:** all reproduce within 17%.
- **Rows ≥ 1 ms that missed, and how to change the text:**

| row | reported | rerun | change to the text |
|---|---|---|---|
| int8 batched scan, 1e5, Q=4 | 2.45 ms | 4.49 ms (Q=1: 1.86) | Repeats gave Q=1 1.7–3.3 and Q=4 2.5–3.4. At 1e6, Q=4 is 63 ms vs 34 ms for Q=1. Write "per-query cost falls ~2x at Q=4 and 4–5x at Q=16", not "four for the price of one". |
| internode whole tree, 1e6 | 28.4 s | 19.0 s; chunked by subtree: 9.7 s | Allocation-bound is confirmed in direction, but the "35x for 10x" ratio is unstable (20x here). Chunking measured 2–3x faster. |
| internode whole tree, 1e4 | 64 ms | 93 ms | Treat as noise. |
| RRF over full 1e4 lists | 7.4 ms | 5.1 ms | Conclusion unchanged. |
| BM25 postings, 1e5 | 0.34 ms | 0.58 ms | Still under 1 ms. |
| memory-only pyramid hop, 65k | 0.35 ms | 0.51 ms | Still under 1 ms. |

### 2. Timing-method problems
- **Hot cache.**
  - The timing loops re-scan the same keys, and the 260 MiB L3 holds 1e4 and 1e5 fp32 keys.
  - Cold-cache figures (768 MB sweep before each scan): **1.32 ms at 1e4** (0.60 hot) and **12.4 ms at 1e5** (7.3 hot).
  - Use the cold figures for the phone projection. The "memory-bound 13 GB/s" argument holds only at 1e6.
- **Wrong single-query baseline in perf item 6.** Compare against the GEMV at 6.8–7.1 ms (b2), not the GEMM-shaped Q=1 call at ~10 ms (b2b). The fp32 gain at Q=16 is then about 4x. fp32 numpy at Q=4 gains nothing.
- **Algorithm R line 3 times the wrong path.**
  - The annotation times only the int8 GEMM.
  - The path R specifies (int8 scan, top-100, fp32 rerank) measures **2.27 ms at 1e5 and 0.40 ms at 1e4, with top-10 overlap 1.000**.
  - Update perf item 5 to these numbers. The raw 0.95–0.97 overlap understates fidelity.
- **Single cold runs.** The 1e6 whole tree (warmup=0), the HNSW builds and the E5 fold are each n=1. Label them as order-of-magnitude figures.
- **Bugs I looked for and did not find:**
  - No lazy evaluation; warm-up is present.
  - The b6 online update really executes: the cited s·k values are 0.38–0.46, above the 0.2 filter.
  - The postings BM25 matches the e1 ranking (top-10 agreement 0.988).
  - e5/e6 really use stable argsort, so the argsort baseline is correct.
- **Labels to fix.**
  - b7 "minus encoder (… + context)" excludes the state head and the context fetch.
  - "Refit ~8–12 s [M]" is an extrapolation from 50 steps: mark it [X].
  - Forget with an index is now measured: the naive purge is **11.3 ms of the 12.6–13.2 ms** total, and an index lookup takes **0.5 µs**.

### 3. Statements to change
- **Finding 1.**
  - Replace "≥95% of a hop" with: *"On the shipping (flat) path the encoder is 86% of a hop at 65k (39.7 ms total, 5.5 ms memory) and about 67% at 1e5 with fp32 and a cold cache. It reaches ≥95% only for the pyramid path or N ≤ ~1e4."*
  - Quote one hop as **25–40 ms**.
- **Finding 2.**
  - The synthetic keys (convex mixes of two random turns) understate fidelity.
  - A k-means tree over real LoCoMo vectors (N=4096) keeps **0.82 / 0.96 / 0.99 at B = 8 / 32 / 64**.
  - Inside one persona (N=512, F=8, depth 3, the chat's own asks) it keeps **0.74 at B=8**, vs 0.57 synthetic.
  - The gate is still needed, but "loses most of the top-10" is too strong.
- **Perf item 3.** Truncating RRF to top-50 lists changes the ranking. Re-measure recall before calling it a pure code fix.
- **Section 3.3.**
  - With TTFT at 0.35 s and a 20 ms hop, memory is 5.7% of TTFT, so write "≤ ~6%" rather than "under 2–5%".
  - The underbrace "prefetched" for hop 1 is misleading. Hop 1 runs serially before the request is sent, overlapping only with request assembly and a cache pre-warm.

### 4. Pseudocode corrections
- **C (online update).**
  1. Re-source the evidence. The quoted figures come from the unfiltered move rule with oracle cites, scored dense-only. Under C's own `C ∩ O` rule (the "visible" condition), move gives **−0.002 [−0.007, +0.003]**, and the hybrid gain is only +0.005 even with oracle cites.
  2. Drop the s·k ≥ 0.2 filter. It passes 99.97% of opened nodes and is not independent of the ranker.
  3. Adopt the *contrastive* rule (pull cited, push opened-but-not-cited). It gave +0.008 [0.004, 0.013] on visible cites and +0.014 at 30% wrong cites.
  4. Log `x = E(q)` as well as `s`; refitting S needs the pre-head input.
- **A (pretraining).**
  - Compute `L_write` against the true parent with v masked (leave-one-out).
  - Retrain W after B changes the parents.
- **B (pyramid).**
  - Tie `p_v` to `unit(A t_v)`, not `t_v`. Apply the same change to the stale-parent fallback and to W step 5.
  - Measure F_B nightly on the user's store at its real N; depth matters.
- **R (read).**
  - Compute the leaf-max feature before pi_stop, or drop it from the stop head.
  - Choose the top-B′ last-level parents globally (IVF-style) instead of a hierarchical beam, since every parent is scored anyway.
  - Skip blank or stale gists (`gist_stale` set, or `‖p_v − unit(A t_v)‖ > δ`).
  - De-duplicate a gist against its descendants.
  - Hold HNSW to the same ≥0.95 bar as the pyramid.
- **RA (read again).**
  - `for h in 1..H_max: …; if h == H_max: break` before the LLM "what is missing?" call. This saves one TTFT in the worst case.
  - Exclude `seen` before selecting top-K.
  - Set `state ← ask ⊕ thought`.
  - Termination is already guaranteed by H_max.
- **D (consolidation).**
  - **Split:** fit 70%, select 10%, gate 20%, by time.
  - **Negatives:** use `O \ C`, not `O \ C'`.
  - **Gate keys:** gate both arms on anchor keys `k0`, without drift.
  - **Logging:** log the top-50 candidates with their ranks so improvements are measurable.
  - **Gate floor:** gate against theta_cur by ±ε *and* against theta_ship on G plus a frozen user eval set (no ratchet).
  - **Drift:** evaluate drift prequentially.
  - **RE-KEY:** `k ← unit(k0_new + R·drift)`, or drop drift on a re-key.
  - **Gist gate:** keep the old gist unless the new one passes a support/entailment check against its children.
  - **Structure gate:** while READ is flat, gate structure ops on the granularity/gist path, since leaf recall cannot change.
  - **Commit:** replay the W/F journal since the snapshot before committing, and apply forgets to the rollback V_t too.
  - **Tainted weights:** if they are tainted, the fallback is theta_ship, never theta_cur.
- **F (forget).** It must also handle:
  - drift that the forgotten ask induced on other nodes (store per-node drift contributions keyed by ask, or reset those nodes to k0);
  - log rows where the target is the ask;
  - co-citation links;
  - BM25 statistics;
  - WAL checkpoint(TRUNCATE) and FTS5 secure-delete;
  - the rollback snapshot.

  Then:
  - Switch to untainted weights immediately (a re-key costs 0.16–0.23 s at 1e5).
  - Verify over a derived-from provenance index rather than a content hash.
  - State that Claude-side copies are out of reach.
- **W (write).** Put the leaf, its placement, the FTS5 row and the ancestor flags in one transaction.

### 5. External numbers: status
| claim | status |
|---|---|
| Apple AFM: 0.6 ms per prompt token, 30 tok/s, iPhone 15 Pro | **Verified** on the 2024 page; it describes the 2024 model, so treat it as a proxy. |
| ANE: latency roughly flat over sequence length 32–128 | **Verified.** Add the article's own figure: **3.47 ms** at sequence 128, batch 1, on the iPhone 13 ANE (distilbert, 66M params). |
| Sonnet 5.5 low ~1.05 s; medium 4.5–12 s; Haiku 5.5 / Sonnet 5.5 at 137 / 99 tok/s | **Does not match the source.** AA on 2026-10-27: Sonnet 5.5 low 1.29 s at 109 tok/s; Sonnet 5.5 medium 2.99 s at 109 tok/s; Haiku 5.5 medium 11.39 s at 174 tok/s. |
| Haiku 4.5 0.35–0.71 s | **Unsourced**: no figure on either cited page. |
| iPhone 17 Pro 70–86 tok/s | **Unverifiable**: no URL. |
| Qwen3-8B TTFT 2.3–3.7 s | **Not on the page.** The page shows 657 ms warm, ~737 tok/s prefill and ~80 tok/s decode on M4 Max, all estimates. |
| Pre-warm with max_tokens 0 | **Confirmed**, with caveats: no streaming, settings must match, 5-min TTL, minimum cacheable prefix 512–4096 tokens. |
| Forum 850058 | **Exists.** Per a search summary (the thread is behind a bot check), later loads were *not* cached on the A20 Pro. Measure on the target phone. |
| CLM 16.5 ms; Jev 70–500 ms | **Unverified**: cited only as the task brief. |

Add two constraints: the Apple on-device context is **4096 tokens per session** (TN3193; read `contextSize` at runtime), and BGProcessingTask time and background Foundation Models use need checking before relying on them.

Sources: [Apple foundation models 2024](https://machinelearning.apple.com/research/introducing-apple-foundation-models), [ANE transformers](https://machinelearning.apple.com/research/neural-engine-transformers), [AA Haiku 5.5 vs Sonnet 5.5 (low)](https://artificialanalysis.ai/models/comparisons/claude-haiku-5-5-vs-claude-sonnet-5-5-low), [AA Haiku 5.5 vs Sonnet 5.5 (medium)](https://artificialanalysis.ai/models/comparisons/claude-haiku-5-5-medium-vs-claude-sonnet-5-5-medium), [willitrunai Qwen3-8B](https://willitrunai.com/can-run/qwen-3-8b-on-m4-max-96gb), [Apple forum 850058](https://developer.apple.com/forums/thread/850058), [TN3193](https://developer.apple.com/tutorials/data/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window.md), [modelgrep Haiku 4.5](https://www.modelgrep.com/models/anthropic/claude-haiku-4.5), [cloudprice Haiku 4.5](https://cloudprice.net/models/claude-haiku-4-5).

ISSUES
- REPRODUCTION: 44 of the 54 listed medians fall within 30% (all scripts rerun sequentially with OMP_NUM_THREADS=1 on an idle 4-core VM; side checks overlapped only the 1e6 HNSW build). Over all 188 raw rows, 49 fall outside 30%, and 36 of those take under 1 ms (Python-overhead noise). Every overlap and fidelity value reproduces exactly. The original 1e3-key rows in b2 read about 3x high, probably from contention.
- NOT ROBUST: 'With int8, four queries cost about the same as one (2.45 vs 2.28 ms at 1e5)'. The rerun gave Q=4 4.49 ms vs Q=1 1.86 ms. A 3x repeat gave Q=1 1.7-3.3 ms and Q=4 2.5-3.4 ms. At 1e6, Q=4 costs 63 ms vs 34 ms for Q=1. Say instead: 'int8 per-query cost falls about 2x at Q=4 and 4-5x at Q=16'.
- BATCH-VS-SINGLE BASELINE (perf item 6): '1.85 ms per query versus about 10 ms alone' compares against the GEMM-shaped Q=1 call in b2b. The right single-query baseline is the b2 GEMV, 6.8-7.1 ms, so the gain is about 4x, not 5x. Also, fp32 numpy at Q=4 gains nothing (24.6-27 ms vs 4 x 6.8 ms).
- HOT-CACHE BIAS: this VM reports a 260 MiB L3, and each timing loop re-scans the same K. So the 1e4 (15 MB) and 1e5 (154 MB) fp32 scans run cache-resident. With a 768 MB sweep before each scan they measure 1.32 ms at 1e4 (0.60 hot) and 12.4 ms at 1e5 (7.3 hot). iPhone caches are far smaller, so project from the cold numbers. The '13 GB/s memory-bound' argument holds only for the 1e6 row.
- WRONG HEADLINE: 'The encoder is at least 95% of a memory hop.' Under Algorithm R, flat leaf scoring is the default until F_B >= 0.95. On that path the encoder is 86% of the hop at 65k (39.7 ms total, 5.5 ms memory) and about 67% at 1e5 fp32 with a cold cache. 95% or more holds only for the pyramid path or N <= ~1e4. Quote the hop as 25-40 ms (flat).
- Algorithm R annotation '1.9 ms int8 at 1e5' times only the int8 GEMM. The path R actually specifies (int8 scan + argpartition top-100 + fp32 rerank) measures 2.27 ms at 1e5 and 0.40 ms at 1e4, with top-10 overlap 1.000. The raw 0.95-0.97 overlap in item 5 therefore understates fidelity. Quote the post-rerank numbers.
- SINGLE COLD RUNS: the b5 1e6 whole-tree run (warmup=0, n=1), the HNSW builds and the E5 fold are single runs. The 1e6 whole tree measured 19.0 s in the rerun vs 28.4 s, and 9.7 s when chunked by 65536-leaf subtrees. Allocation-bound is confirmed in direction, but '35x the 1e5 time for 10x' is not stable (the rerun gives 20x). Chunking measured 2-3x faster.
- LABEL ERRORS: the b7 'read hop minus encoder (... + context)' row excludes the state head and the context fetch. 'Refit ~8-12 s [M]' (D step 3) and '8.4/11.5 s per 1e4 asks x 5 epochs' are extrapolated from 50 steps, so they are [X]. 'With the step-4 index it becomes sub-millisecond [X]' can now be [M]: the naive purge takes 11.3 ms of the 12.6-13.2 ms forget, and an index lookup takes 0.5 us.
- SYNTHETIC KEYS UNDERSTATE DESCENT FIDELITY (finding 2): a k-means tree over REAL LoCoMo turn vectors (N=4096) keeps 0.82 at B=8, 0.96 at B=32 and 0.99 at B=64, vs 0.56/0.84/0.94 on synthetic keys. Within one persona (N=512, F=8, depth 3, that chat's own asks), B=8 keeps 0.74 (range 0.70-0.78) vs 0.57 synthetic. The conclusion holds (untrained parents miss 0.95 at small B), but 'loses most of the exact top-10' is too pessimistic. Label the synthetic-key caveat.
- NOT A PURE CODE FIX: RRF over top-50 lists gives a different ranking from the full-list RRF used for the E1/E5/E6 recall numbers. Re-measure recall@10 before calling it speed-only. (The BM25 postings replacement is equivalent: top-10 agreement 0.988, ties only.)
- ALGORITHM C EVIDENCE MISATTRIBUTED: +0.020 [0.014, 0.027] and the -0.003/-0.023/-0.023 figures come from the UNFILTERED move rule, with oracle cites, scored dense-only. Under C's own step 2 (cites restricted to opened nodes, the 'visible' condition in fix-cite-noise), move gives -0.002 [-0.007, +0.003]. Fused with BM25, as READ does, the oracle-cite gain is only +0.005. The 's.k >= 0.2 OR BM25 rank <= 10' filter was never evaluated. agree-bm25 alone cut the clean gain to +0.004.
- ALGORITHM C FILTER IS VACUOUS: with bridged rank-16 heads on held-out chats, s.k >= 0.2 holds for 99.97% of opened top-10 nodes (p1 = 0.244) and 90% of gold. It is the system's own score, not an independent signal. Because step 2 already restricts cites to opened nodes, step 4 removes nothing. Replace it with a rule that was measured under visible cites: contrastive gave +0.008 [0.004, 0.013], and +0.014 at 30% wrong cites. Note also that capping at the '3 best by s.k' favours nodes that already rank high.
- LOGGING BUG (C step 7 -> D step 3): the log stores s = unit(S x), but refitting S needs the pre-head x = E(q). Log x, and treat it as user data under FORGET.
- D STEP 3 NEGATIVES: 'hard negatives O \ C'' include genuine cites that C's cap or filter removed, so they get trained as negatives. Use O \ C (raw cites).
- D GATE CANNOT SEE IMPROVEMENT AND IS LEAKY: (1) T_eval positives are cites, and C makes those a subset of theta_cur's own top-10, so theta_cur scores about 1 by construction. Any reordering can only lose, which means the gate measures agreement with theta_cur. (2) The refit early-stops on T_eval and is then gated on T_eval (selection bias). (3) Online drift was learned from T_eval's own cites, so drift-keyed evaluation leaks labels. Step 5's 'keep drift only if replay says it helps' tests drift on its own training data. Fix: split fit/select/gate by time; gate both arms on anchor keys k0; log the top-50 candidates with ranks so gains can show up (recall@50, MRR); judge gains on G and by interleaving; evaluate drift prequentially from scores logged at ask time.
- D RATCHET: a non-inferiority margin of eps = 0.005 per night, measured against theta_cur, compounds over many nights. Also require no loss against a fixed floor (theta_ship on G plus a frozen user eval set).
- D UNGATED STEPS: step 7 re-distils gists with no faithfulness check, and those gists are shown to R and used as fallback keys. Step 8's structure gate is vacuous while READ uses flat leaf scoring (leaf recall unchanged, so it 'does not drop'), and many proposals tested on one T_eval invites a winner's curse. Step 5 RE-KEY lacks unit() and adds drift computed in the old key space to the new one.
- CONSOLIDATION RACE: D snapshots V_t and later commits V_{t+1} atomically. Writes and forgets that arrive during consolidation are lost at commit, and forgotten items come back. Journal every W/F operation since the snapshot and replay it onto V_{t+1} before commit. The retained rollback copy V_t must also get the forgets.
- FORGET LEAVES DERIVED DATA: (a) online drift that moved other nodes toward the forgotten ask's state is not reverted; (b) log entries where the target was the ASK (hash(q), s, x) survive, because step 4 checks only O/C; (c) lateral links created by co-citation with the target remain; (d) BM25 df/avgdl still count it; (e) SQLite WAL frames keep it (secure_delete does not scrub the WAL; run wal_checkpoint(TRUNCATE)), and FTS5 segments keep it until merge (enable FTS5 secure-delete, SQLite >= 3.44, after checking the iOS SQLite version); (f) the V_t snapshot keeps it; (g) Claude-side copies (prompt cache, provider retention) are out of reach, so document that. A content-hash check cannot find embeddings or paraphrased gists: verify by id over a derived-from provenance index.
- FORGET VS GATE: F step 5 restarts the refit from theta_ship on the purged log, but D's gate compares against the tainted theta_cur and keeps theta_cur on reject, which blocks unlearning. When weights are tainted, fall back to theta_ship or the last untainted checkpoint immediately (re-key at 1e5 costs 0.16-0.23 s) rather than at night.
- GISTS ON FORGET AND READ: blanking every ancestor gist means every forget blanks the root and top gists, which also invalidates the Claude cached prefix that perf item 2 builds around the root gist. R step 2 emits gists via pi_stop with no blank/stale check, although W step 5 says readers descend past stale gists.
- ALGORITHM R ORDER: pi_stop uses l_max_leaf but runs in step 2, before leaves are scored in step 3, and l_max_leaf is undefined in pruned mode. Step 2 also scores every parent exactly anyway, so the hierarchical beam only discards information: take the top-B' last-level parents globally (IVF-style) instead. Gists emitted while the flat scan also returns their descendants need de-duplication.
- INCONSISTENT GATES: HNSW is accepted at overlap 0.92 (1e6, ef=128) while the pyramid must reach F_B >= 0.95. Apply the same bar. HNSW keys also go stale under online drift.
- ALGORITHM RA: termination is guaranteed by H_max, but at h = H_max the LLM 'what is still missing?' call is wasted (its thought never drives a read), which costs about one TTFT; skip it on the last hop. 'READ(state) minus seen' removes items after top-K, so it can return few or none; exclude seen items before selecting top-K. Use state = ask + thought (the thought alone drops the ask's entities from BM25). pi_stop on 'global features' is undefined.
- ALGORITHM A WRITE-HEAD LEAKAGE: L_write scores v against parent states computed from children that include v, which makes it trivially solvable. Mask v (leave-one-out) when training placement. Retrain W after B changes the parents.
- ALGORITHM B SPACE MISMATCH: p_v is pooled from action keys unit(A e), while t_v = E(g_v) lives in raw encoder space. The gist tie, the stale-parent fallback and W step 5's ||p_v - t_v|| should all use unit(A t_v). F_B measured on ~600-leaf dev haystacks (depth about 2) does not certify fidelity at depth 4-5 (b3k shows fidelity falls with depth). Measure F_B nightly on the user's store at its real N.
- MINOR: multi-positive InfoNCE keeps other positives in each denominator, and L_bwd treats asks that share the same evidence as negatives. E6 and fix-cite-noise CIs resample visits (3 orders per question); quote the question-level q-CI (move clean: +0.020, q-CI [0.012, 0.030]).
- EXTERNAL, VERIFIED: Apple 2024 page, 'time-to-first-token latency of about 0.6 millisecond per prompt token, and a generation rate of 30 tokens per second' on iPhone 15 Pro. It describes the 2024 on-device model, so label it a proxy for the iOS 27 model.
- EXTERNAL, VERIFIED AND INCOMPLETE: the ANE article does say latency stays 'approximately constant across sequence lengths of 32, 64, and 128 (with batch size 1)'. The doc missed its absolute anchor: 3.47 ms at sequence length 128, batch 1, on the iPhone 13 ANE (0.454 W) for the optimized distilbert (66M params). Cite it as support for the 3-10 ms [X] encoder estimate. bge-small still has to be measured.
- EXTERNAL, DOES NOT MATCH THE SOURCE: Artificial Analysis, fetched 2026-10-27, shows Sonnet 5.5 (Low) TTFT 1.29 s at 109 tok/s; Sonnet 5.5 (medium) TTFT 2.99 s at 109 tok/s; Haiku 5.5 (medium) TTFT 11.39 s at 174 tok/s. '~4.5-12 s at medium' mixes Haiku-medium into the Sonnet figure, and '137/99 tok/s' is stale. Cite with an access date, or measure TTFT from the app.
- EXTERNAL, UNSOURCED: 'Haiku 4.5 p50 TTFT 0.35-0.71 s'. Neither modelgrep nor cloudprice shows a TTFT value in the fetched page. Haiku 4.5 is also the previous generation. Thinking cannot be disabled on Opus 5.5 (effort is the lever), and Sonnet 5.5 needs thinking type between_tools to turn it off, so 'no reasoning' TTFT must be stated per model.
- PROMPT-CACHE PRE-WARM, CONFIRMED WITH CAVEATS: max_tokens 0 writes the cache, but it is rejected with stream:true. It must match the real request's thinking/effort settings. The default TTL is 5 min (1 h optional). The minimum cacheable prefix is 512-4096 tokens depending on model, so a short system prompt plus root gist may not cache at all, and every change to the root gist invalidates it. 'Begin your visible answer immediately' is a prompt technique, not a documented feature.
- EXTERNAL, UNVERIFIABLE: 'iPhone 17 Pro 70-86 tok/s (DeviceMark via search)' has no URL. Drop it or mark it low-confidence.
- EXTERNAL, NOT ON THE PAGE: willitrunai now shows Qwen3-8B Q4_K_M on M4 Max at ~80 tok/s, TTFT 657 ms warm, ~737 tok/s prefill, and M3 Max at 51.3 tok/s, all llama.cpp model estimates. 'TTFT 2.3-3.7 s' does not appear there; if it was derived (2k tokens / 737 tok/s = 2.7 s), label it 'derived from E'.
- EXTERNAL, LIKELY WRONG: Apple developer forum thread 850058 exists ('iPhone 18 Pro: First Core ML load on Neural Engine up to 65x slower than on iPhone 17 Pro'). Per a search summary (the thread itself is behind a bot check), the poster reports ~113 s loads and that later loads were NOT cached on that device, the opposite of the doc's 'later loads cached'. Measure first and second load on the target phone.
- EXTERNAL, NEEDS CITATIONS: CLM-8B 16.5 ms and Jev 70-500 ms are cited as 'task brief'. Add the paper and vendor references, or mark them 'unverified, from brief'.
- MISSING CONSTRAINTS: Apple's on-device model has a 4096-token context per session covering instructions, prompt, tools and response (TN3193). Read SystemLanguageModel.contextSize at runtime (iOS 26.4+) and size the Apple-path memory context to fit. The BGProcessingTask '10 min' budget is not guaranteed, and Foundation Models calls from the background may be rate-limited. Verify both before relying on nightly on-device gist distillation.