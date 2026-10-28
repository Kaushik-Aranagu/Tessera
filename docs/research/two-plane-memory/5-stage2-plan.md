# Two-plane memory: stage 2 plan, with pass bars fixed before anything runs

Kaushik picked "Stage 2 on the Mac anyway" on Oct 27, 2026 at 9:33 PM PDT. That pick lets Core install the Python
packages listed below on the Mac and run the encoder, phone speed and open model tests. This file was committed before
any stage 2 number existed; anything added after a result is seen will be marked post hoc.

Public data only (LoCoMo, LongMemEval-S, public model weights). No Tessera data. Every slow weight trained here (the
projector in 2.4) is trained on public text only.

## What changed since the front matter

Stage 1 found that a learned ranker (LightGBM over the fused top 50, test 1.11) adds +0.094 recall@10 on LoCoMo, far
more than anything learned from use. So every stage 2 quality test is now measured at the ranker level too: a bigger
model only counts if it beats **bge-small plus bridges plus the ranker** (LoCoMo 0.7492, LongMemEval-S 0.9187), not
just the plain bridge read. The front matter's own bar is still reported alongside.

## Common rules

- LoCoMo: 1,536 questions, 10 chats, the stage 1 outer folds (chat pairs) and dev pairs. Nothing is chosen on test chats.
- Statistics: paired difference per question; chat-clustered bootstrap (4,000 draws, seed 0) and the exact chat
  sign-flip test (all 1,024 sign patterns). "CI > 0" means the 95% interval's lower end is above zero.
- LongMemEval-S: 428 questions, question-clustered bootstrap. A "loss" there is a point estimate below −0.005.
- Two new encoders are tested in 2.2, so their sign-flip p values get Holm's correction.
- Timing on the Mac's Neural Engine stands in for the phone with a 2x allowance (phone chips run the same ANE generation
  with less memory bandwidth). The phone itself is checked with Xcode's Performance Report on the connected iPhone,
  which loads the model only, not the Tessera app, so the install gate is untouched.

## The tests

### 2.1 bge-small on the Neural Engine (Mac, Core)

`s21_coreml.py`. Convert BAAI/bge-small-en-v1.5 to a fixed-shape Core ML program (sequence 128, fp16, iOS 18 target,
CLS output, normalised on the host). Same for Qwen3-Embedding-0.6B (last-token output), which 2.2 needs for its
latency side.

- **Parity:** on 1,000 LoCoMo texts the Core ML vector (CPU and Neural Engine) has mean cosine at least 0.999 and minimum
  at least 0.99 against fp32 sentence-transformers, and the LoCoMo rank-16 bridge read with Core ML vectors is within
  0.002 of the fp32 read.
- **Speed (the bar):** p95 per encode at most 10 ms on the Mac Neural Engine, which leaves the 2x phone allowance under
  the front matter's 20 ms memory hop. If the phone is connected, its Performance Report median must also be at most
  20 ms. A question's memory step (up to 3 hops, each one encode plus a dot product over the keys) then stays under
  60 ms.
- Reported, no bar: first load (fresh compile) and second load, the four compute-unit settings, and the share of the
  model's cost placed on the Neural Engine.

### 2.2 Bigger frozen encoders (cloud)

`s22_encoders.py`. Encoders: bge-small (the reference, must reproduce stage 1 exactly), **bge-base-en-v1.5** (110M,
same family) and **Qwen3-Embedding-0.6B** (595M, with its stored query instruction; documents get none).
EmbeddingGemma-300m is gated behind Google's license click-through and no account here has accepted it, so it is left
out unless an accepted copy exists; bge-base takes its place as the middle size.

For each encoder, the whole stage 1 pipeline is rebuilt in that encoder's space with no new choices: rank-16 bridges
with the learning rate tuned on dev pairs (s11 protocol), the BM25-fused read, and the s111 ranker (same 25 features,
same dev-chosen hyperparameter grid, same inner bridges for training chats).

- **Pass:** for an encoder X, the ranker read with X beats the ranker read with bge-small on LoCoMo with CI > 0 and Holm
  sign-flip p below 0.05; no loss on LongMemEval-S; and X meets the 2.1 speed bar on the Mac Neural Engine (or on the
  GPU if that is faster).
- If X wins on quality but misses the speed bar, the verdict is "fail: better but too slow", reported as such.
- Reported, no bar: frozen read, bridge read and fused read per encoder, with CIs against bge-small (the front matter's
  bar is "beats bge-small with bridges", i.e. the bridge and fused reads).

### 2.3 CLM-8B's heads as the bridge (Mac for the vectors, cloud for the ranker)

`s23_clm.py` on the Mac: Qwen3-8B (MLX, 8-bit) last-token final hidden state, no chat template, through CLM-v0.1-8B's
state head (questions) and action head (turns); score = cosine of the 512-d projections. Zero-shot, so every chat is
held out. A raw arm uses the 4096-d cosine without the heads.

- **Calibration first:** on 64 fixed LoCoMo texts, the 8-bit final vectors have mean cosine at least 0.99 against a
  bf16 reference (`s20_calib_ref.py`, computed in the cloud, or on the Mac if the cloud cannot), and so do their CLM projections. If this fails, the run
  continues but every 2.3 result is labelled "8-bit form only".
- **Pass (measured against the ranker):** the s111 ranker built on the CLM list (`s23b_clm_ranker.py`, cloud, from the
  exported score matrices; CLM scores fill the bridge features and the raw cosine fills the frozen ones) beats the bge-small ranker read (0.7492) on LoCoMo with CI > 0 and sign-flip p below 0.05.
- **Front matter's bar, reported:** CLM fused with BM25 against bge-small rank-16 fused with BM25 (0.6553), same test.
- Reported, no bar: CLM alone, raw cosine, CLM added as a third list to the bge-small fused read and to the ranker's
  features. LongMemEval-S only if the Mac has time (about 83,000 turns, 3 to 5 hours).

### 2.4 First steps of stage A: hidden states, the projector Π, the tap layer (Mac; cloud pilot)

`s24_tap.py`. Qwen3-8B (MLX, 8-bit), hidden state at the last token of the raw text, at the embedding output and after
every third block (3, 6, …, 36), plus the final normed state: 14 taps. Π is the method's
$\mathrm n(W_2\,\mathrm{GELU}(W_1\,\mathrm{LN}(\mathbf h)))$, width 1024, output 384, trained on the symmetric InfoNCE
alignment loss against bge-small's vector of the same text (logit scale 20, AdamW lr 1e-3, weight decay 0.01, batch 256,
at most 30 epochs, stopping on the dev pair's loss).

- Training text for each outer fold: every turn and question of its 8 training chats, plus 12,000 LongMemEval-S user
  turns (fixed sample, seed 0). Test chats never reach Π. The read uses the stage 1 rank-16 bridges, unchanged:
  $s=\mathrm n(S\,\Pi(\mathbf h_q))$ against keys $A f(\text{turn})$.
- Sanity first: the Mac's own bge-small text read must reproduce the stage 1 bridge read (0.6622) within 0.005, or the
  run stops.
- **C3 passes** if the tap with the best mean held-out cosine $\langle\Pi(\mathbf h_q), f(q)\rangle$ sits between 55% and
  80% of the depth (taps 21, 24 or 27 of 36) and beats the last tap with CI > 0 on per-question cosine.
- **P11 passes** if, at the tap chosen on dev pairs only, the hidden-state bridge read's LoCoMo recall@10 is at least
  the lower end of the text-state read's chat-clustered 95% interval. The paired difference and its CI are reported,
  and the same comparison after BM25 fusion.
- A cloud pilot with Qwen3-0.6B (torch, fp32) runs the same script first to check the code. It is labelled a pilot and
  decides nothing.

### 2.5 and 2.6

2.5 (a vec2text-style inverter) needs a GPU and stays deferred. 2.6 (the read wired into Tessera behind a flag, tested
on the Tessera test world) waits for Kaushik's pick on what goes into Tess from stage 1.

## Proposed gate for stage 3 (Kaushik's call when stage 2 is done)

Rent GPUs for stage 3 only if **P11 passes** (hidden states can carry the read) **and** a large model beats bge-small at
the ranker level (2.3 passes, or 2.2 passes for Qwen3-Embedding-0.6B). If CLM's heads, trained on about 60 million
pairs, cannot beat a small encoder plus a ranker on this memory task, heads we train ourselves on far less data are
unlikely to, and the better spend is shipping the ranker.

## Who runs what

| part | where | needs |
|---|---|---|
| 2.1 convert, parity, timing | Mac (Core) | env A below; Xcode Performance Report if the phone is connected |
| 2.2 encoders | cloud | already installed here |
| 2.3 CLM vectors, calibration | Mac (Core); bf16 reference and ranker in the cloud | env B below; about 9 GB download |
| 2.4 hidden states and Π | Mac (Core); pilot in the cloud | env B |

Env A (Python 3.12): `torch==2.7.0 coremltools==9.0 transformers==4.57.6 tokenizers==0.22.2 huggingface_hub==0.36.2
safetensors==0.8.0 sentence-transformers==5.1.2 numpy==2.2.6`.

Env B (Python 3.12): `mlx==0.32.3 mlx-lm==0.32.0 transformers==5.19.0 tokenizers==0.23.2 huggingface_hub==1.33.0
safetensors==0.8.0 torch==2.14.1 sentence-transformers==6.1.0 numpy==2.4.6`, then
`contrastive-lm==0.1.0` with `--no-deps` (its vLLM dependency has no macOS build; only its heads code is used).

Data on the Mac: LoCoMo from its GitHub repo and LongMemEval-S from Hugging Face, each checked by SHA-256 against the
stage 1 copies.

Safety on the Mac: models load with `weights_only=True`; nothing listens on a network port; no environment variable is
printed; only small JSON and score files come back, pushed to this branch. Weights: Qwen3-8B 8-bit (about 9 GB),
Qwen3-Embedding-0.6B (1.2 GB), bge-small, the CLM heads (76 MB).
