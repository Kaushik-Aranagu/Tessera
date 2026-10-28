# Stage 2: the Mac, the phone and the bigger models

Kaushik picked "Stage 2 on the Mac anyway" on Oct 27, 2026 at 9:33 PM PDT. The plan, with every pass bar fixed before
any run, is `docs/research/two-plane-memory/5-stage2-plan.md`. Public data and public weights only; no Tessera data.
Every script's docstring holds its protocol and bar; anything added after a result is seen is marked post hoc.

## Files

| file | test | runs on |
|---|---|---|
| `get_data.py` | fetches LoCoMo (GitHub) and LongMemEval-S (Hugging Face), checked by SHA-256 against stage 1 | both |
| `s21_coreml.py` | 2.1 Core ML conversion, parity, timing, Neural Engine share (bge-small, Qwen3-Embedding-0.6B, bge-base) | Mac, env A |
| `encode_texts.py` | 2.2 vectors for bge-base and Qwen3-Embedding-0.6B, resumable shards | cloud |
| `pipeline.py` | the stage 1 read stack for any vectors (tuned rank-16 bridges, BM25 fusion, the s111 ranker); reproduces stage 1 exactly with bge-small | cloud |
| `s22_encoders.py` | 2.2 bigger encoders against bge-small at every level, ranker included | cloud |
| `s20_calib_ref.py` | 2.3 bf16 reference vectors of Qwen3-8B for 64 LoCoMo texts (`results/s20_calib_ref.npz`, made in the cloud) | cloud |
| `lm_states.py` | last-token hidden states of Qwen3 models, MLX (Mac) or torch (cloud), 14 taps for Qwen3-8B | both |
| `clm_heads.py` | CLM-v0.1-8B's state and action heads, checked against contrastive-lm 0.1.0's own code (max difference 0.0) | both |
| `s23_clm.py` | 2.3 CLM vectors and score matrices, calibration, CLM-alone and fused reads | Mac, env B |
| `s23b_clm_ranker.py` | 2.3 the pass bar: the s111 ranker on the CLM list against the bge-small ranker | cloud |
| `s24_tap.py` | 2.4 the projector Π per tap, C3 and P11 | Mac, env B (pilot in the cloud) |

`results/r16_bridges.npz` holds the stage 1 rank-16 bridges the Mac scripts read with.

## Mac run (Core)

The Tessera clone on the Mac is `~/pilot`; work from `~/pilot/scripts/ai/small_models/stage2` on branch
`claude/project-thread-j9x62n`. Each model run is a heavy job for the lane cap. Close the simulator before s23 and s24.

```
# 2.1, env A (35 to 70 min, peak about 8 GB while Qwen3 converts, about 1.4 GB of packages under ~/tess-s21)
python3.12 -m venv ~/venvs/tess-coreml && source ~/venvs/tess-coreml/bin/activate
pip install torch==2.7.0 coremltools==9.0 transformers==4.57.6 tokenizers==0.22.2 huggingface_hub==0.36.2 \
  safetensors==0.8.0 sentence-transformers==5.1.2 numpy==2.2.6
python -I get_data.py locomo
python -I s21_coreml.py all --work ~/tess-s21 --stage1-cache ~/tess-s21/stage1_cache --threads 8
# phone, only if the iPhone is connected: open -a Xcode ~/tess-s21/bge-small-s128.mlpackage, Performance tab,
# add a report on the iPhone with "CPU and Neural Engine", then:
python -I s21_coreml.py verdict --phone-median-ms <median ms from the report>

# 2.3 and 2.4, env B (about 13 GB disk; about 11 GB memory at peak during the hidden-state pass)
python3.12 -m venv ~/venvs/tess-llm && source ~/venvs/tess-llm/bin/activate
pip install mlx==0.32.3 mlx-lm==0.32.0 transformers==5.19.0 tokenizers==0.23.2 huggingface_hub==1.33.0 \
  safetensors==0.8.0 torch==2.14.1 sentence-transformers==6.1.0 numpy==2.4.6
pip install --no-deps contrastive-lm==0.1.0
export STAGE2_CACHE=$HOME/stage2_cache
python -I get_data.py locomo lme
python -I clm_heads.py --verify          # under a minute
python -I s23_clm.py --threads 8         # 15 to 25 min; caches all 14 taps of the LoCoMo texts for s24
python -I s24_tap.py --backend mlx --model mlx-community/Qwen3-8B-8bit --threads 8 --device cpu   # about 1.5 to 3 h
# optional, only if the Mac is free for hours: python -I s23_clm.py --threads 8 --lme --max-seconds 14400 (re-run resumes)
```

Bring back by pushing to the branch: `results/s21_coreml.json`, `results/s23_clm.json`, `results/s23_clm_scores.npz`
(plus any other `s23_clm_scores_*.npz` the run's "s23b input:" line names) and `results/s24_tap.json`. Each file is
under 3 MB. If any step fails, push its log instead and stop; do not change versions or settings.

## Cloud run

```
cd scripts/ai/small_models/stage2
/tmp/e1/bin/python -I s22_encoders.py                       # about 12 to 18 min per encoder
/tmp/e1/bin/python -I s23b_clm_ranker.py --scores <the comma list from s23's "s23b input:" line>
```

## Checks done before any real run

- `pipeline.py` reproduces stage 1 per question with zero deviation: bridge read 0.6622, fused 0.6553, ranker 0.7492 on
  LoCoMo and 0.9187 on LongMemEval-S. With bge-small passed in as a second encoder every difference in s22 is exactly 0.
- `s21_coreml.py` converts all three models on Linux (714, 714 and 4,865 ops, none left in fp32); the traced models
  match sentence-transformers to cosine 0.9999999. Predictions and timing need the Mac.
- `s20_calib_ref.py` streams Qwen3-8B one layer at a time; on Qwen3-0.6B the streamed forward equals the full
  forward (max difference 0.0 in fp32). bf16 compute against fp32: mean cosine 0.99991.
- `s23_clm.py` and `s24_tap.py` ran end to end on Qwen3-0.6B. The 2.4 pilot (`results/s24_tap_pilot_qwen3-0.6b.json`,
  decides nothing): the hidden-state read reaches 0.375 against the text read's 0.662, and the best tap is the last.
- Known limits: the score files store float16, so a few scores tie (recorded in s23b's output); the s111 ranker can
  move by up to about 0.005 from last-bit changes in its inputs, so a borderline result is reported as borderline.
