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
