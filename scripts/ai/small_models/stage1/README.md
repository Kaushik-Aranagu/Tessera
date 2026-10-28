# Stage 1: the cheap, decisive tests of two-plane memory

Kaushik approved stage 1 on Oct 27, 2026 at 5:26 PM PDT. The plan, with each pass bar fixed in advance, is the
"What to do next" table in `docs/research/two-plane-memory/1-front.md` (tests 1.1 to 1.11). Public data only:
LoCoMo (pinned by SHA-256) and LongMemEval-S (`longmemeval_s_cleaned.json`, checked byte for byte against the copy
on Hugging Face). No Tessera data anywhere.

## What changed from the earlier scripts (method section 8)

- LoCoMo evidence parsed with `D:?(\d+):(\d+)`, leading zeros stripped: 1,536 questions (was 1,531).
- Logit scale fixed at 20; read loss is forward-only L_mask.
- Learning rate tuned per rank on dev chats carved from each fold's training chats (nested), never on test chats.
- Chat-clustered paired bootstraps on LoCoMo, question-clustered on LongMemEval-S; common random numbers across arms.
- Centred rules use a mean state frozen per bridge version, not a running mean.

## Files

| file | test |
|---|---|
| `common.py` | loaders, BM25, fusion, bridges, folds, clustered bootstrap |
| `s11_rank.py` | 1.1 rank sweep with tuned learning rates; LongMemEval-S transfer; label-free centring |
| `retrieval.py` | the read Haiku sees: tuned rank-16 bridges fused with BM25; probe reads for later hops |
| `build_tasks.py` | the reader's task files, one hop at a time (`runs/`) |
| `haiku_run.py` | Claude Haiku 5.5 reads, answers, cites, asks for the next search; a second call grades against the gold answer. Standard library only; dry unless `--live` |
| `s12_cites.py` | 1.2 cite quality and the learning rules on real cites |
| `s13_hops.py` | 1.3 read-again with Haiku's own probes |
| `s14_*` to `s111_*` | 1.4 to 1.11 (key-view move, self-feedback, hub cost, alias calibration, deeper pyramids, exact deletion, session fusion, prior-art baselines) |

Results are in `results/`. Run order: `s11_rank.py`, `build_tasks.py --hop 0`, `haiku_run.py ... --live`,
`build_tasks.py --hop 1`, run it, `build_tasks.py --hop 2`, run it, then `s12_cites.py` and `s13_hops.py`.
Caches go to `$STAGE1_CACHE` (default `/tmp/claude-0/stage1`).

Known issue in the saved runs: the hop 2 tasks in `runs/` were built before `build_tasks.py` tracked every snippet shown
at earlier hops (`seen`), so 2,453 of the 3,670 "new" hop 2 snippets were hop 0 snippets shown again. Recall metrics
are unaffected (they use lists, not what was shown); the hop 2 answers saw some repeated text.

The CPU checks `s14_keyview.py` to `s111_baselines.py` each run on their own after `s12_cites.py` (they read the hop 0
answers in `runs/`). Each script's docstring holds its protocol and pass bar, written before it ran; anything added
after a result was seen is marked post hoc. Python needs numpy, scipy, torch, sentence-transformers (bge-small),
threadpoolctl and, for `s111_baselines.py`, lightgbm 4.7.

## Verdicts (Oct 27 to 28, 2026)

| test | verdict | in one line |
|---|---|---|
| 1.1 | fail | full rank still leads the LoCoMo bridge read by 0.016 to 0.020 (chat CI > 0); ranks agree on LongMemEval-S and after fusion |
| 1.2 | pass | combo (centred pull and push) on Haiku's cites: +0.008 bridge read, +0.0065 after fusion, CIs > 0, holds over 20 orders; picked on dev chats the fused CI touches zero |
| 1.3 | fail | reading again +0.047 LoCoMo recall over hop 0, but a no-search control (s13b) matches it (−0.007 vs control); multi-hop 0.462 < 0.480 single bridge read |
| 1.4 | pass | the key-view target removes the self-feedback loss (−0.023 to −0.003) and keeps the clean gain |
| 1.5 | fail | the centred rule keeps drifting (−0.063) instead of settling near −0.04 |
| 1.6 | inconclusive | too few intrusions on LongMemEval-S; LoCoMo leans against Remark 6.1 |
| 1.7 | fail | calibrated alias bonus loses to F3 by 0.007 |
| 1.8 | fail | log-sum-exp keeps 72% of leaf signal at LoCoMo months, 54% at LongMemEval-S weeks |
| 1.9 | pass | log-defined keys forget exactly, byte for byte, 90 of 90 cases |
| 1.10 | fail | session fusion does not carry over to LongMemEval-S (+0.011, CI spans zero; multi-session −0.013 point loss) |
| 1.11 | fail | ties RMM-style heads; a LightGBM ranker trained on other chats' gold evidence gains +0.094 over the current read |
