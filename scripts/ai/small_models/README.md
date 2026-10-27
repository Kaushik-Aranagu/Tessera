# Small models and two-plane memory: research scripts

Research for Tess, not app code. Nothing here ships in the app or reads Tessera data: every run uses public
benchmarks only (LoCoMo, pinned by SHA-256, and LongMemEval-S), on CPU, with no paid API calls.

The write-up that explains the method, the math, the results and what failed is the "Two-Plane Memory" page
(linked from the research thread). Section and experiment names below match it.

## Setup

```bash
python3 -m venv /tmp/e1 && /tmp/e1/bin/pip install numpy sentence-transformers \
  torch --extra-index-url https://download.pytorch.org/whl/cpu
curl -L -o /tmp/locomo10.json https://raw.githubusercontent.com/snap-research/locomo/3eb6f2c585f5e1699204e3c3bdf7adc5c28cb376/data/locomo10.json
/tmp/e1/bin/python -I e5_bridges.py --data /tmp/locomo10.json
```

The encoder is `BAAI/bge-small-en-v1.5` (33M weights, 384-d). Many scripts in the subfolders were written in a cloud
container and still name its working paths (`/tmp/claude-0/...`) for caches and inputs; change those before a rerun.
Data caches, pickles, vector files and vendored binaries were left out on purpose.

## Map

| path | what it tests |
|---|---|
| `e1_retriever.py` | E1: BM25, dense, hybrid (RRF k=60), session and pyramid arms on LoCoMo; asserts the BM25 baseline 0.563 |
| `e5_bridges.py` | E5: CLM-style state/action bridge heads (full rank or `I + UV^T`) trained with two-way multi-positive InfoNCE |
| `e6_fixes.py`, `e6_result.txt` | E6: use-driven key updates (move, alias, anchored) under cite noise and self-feedback |
| `e7_longmemeval.py`, `e7_result.txt` | E7: bridges trained on LoCoMo, tested on LongMemEval-S (transfer) |
| `fixes/cite-noise/` | contrastive pull+push key updates under 0/30/60% wrong cites |
| `fixes/alias-hub/` | alias keys with hub correction (the plain alias rule collapses) |
| `fixes/second-hop/` | vector-only second hop for multi-hop asks |
| `pyramid/` | E8: shared internode encoder over a session pyramid; exact recompute under insert, forget, merge and weight swap |
| `algos/bench/` | latency benchmarks b1-b7: encoder, scoring, HNSW, pyramid descent, BM25, internode, training, paths |
| `algos/rerun/`, `algos/side/` | independent reruns and side checks of those benchmarks |
| `math/` | checks behind the math sections: objectives, theory (noise, hub, gating), referee (chat-clustered CIs), code-vs-math audit, shared latent space |
| `audits/` | the review journals: skeptic re-runs and prior-art check (`wf1`), pyramid review (`wf2`), algorithms review (`wf3`, `algos_review.md`), referee and code-vs-math audit (`wf4`) |

The paper's Markdown source is in `docs/research/two-plane-memory/`.
