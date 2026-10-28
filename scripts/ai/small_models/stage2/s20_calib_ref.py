#!/usr/bin/env python3
"""Stage 2, test 2.3's calibration reference: Qwen/Qwen3-8B final hidden states of 64 fixed LoCoMo texts (cloud CPU).

Plan (docs/research/two-plane-memory/5-stage2-plan.md, section 2.3, committed before any stage 2 number), quoted:
  "Calibration first: on 64 fixed LoCoMo texts, the 8-bit final vectors have mean cosine at least 0.99 against a bf16
  reference (s20_calib_ref.py, computed in the cloud, or on the Mac if the cloud cannot), and so do their CLM
  projections. If this fails, the run continues but every 2.3 result is labelled "8-bit form only"."
This script only makes the reference. s23_clm.py applies the bar on the Mac (calib_ok, against "ref"). Nothing is tuned.

Protocol:
  Texts. Questions: all 1,536 LoCoMo questions in common.load_locomo order (chat 0..9, each chat's qs in order) as CLM's
    state head sees them, clm_heads.state_text(q) = q.strip(). Turns: all 5,882 turns in the same order as the action
    head sees them, clm_heads.action_text(t) = the text verbatim. rng = np.random.default_rng(2028); question indices =
    sorted(rng.choice(1536, 32, replace=False)), then, from the same generator, turn indices = sorted(rng.choice(5882,
    32, replace=False)). texts = the 32 questions then the 32 turns, each in index order; all 64 distinct (asserted).
  Model. Qwen/Qwen3-8B (the hybrid instruct model; not Qwen3-8B-Base, not Qwen3-Embedding-8B) at the commit pinned in
    lm_states.REVISIONS, checked equal to the Hub's answer for that revision; its bf16 safetensors, each shard checked
    against the Hub's LFS SHA-256.
  Tokens. No chat template; tok.encode(text, add_special_tokens=False). Qwen3's tokenizer has no BOS (bos_token None)
    and adds no EOS: asserted, and ids with and without special tokens are asserted equal for all 64 texts. No text
    needs truncation (6 to 77 tokens, 1,322 in all; lm_states.MAX_LEN is 512; asserted).
  Vector. The final post-norm hidden state (the model.norm output, Qwen3Model's last_hidden_state) at each text's last
    real token, L2-normalised. "ref": bf16 weights upcast to float32, float32 compute. "ref_bf16": bf16 weights and bf16
    compute, transformers' own bf16 path (RMSNorm statistics in float32 then cast back, rotary cos/sin computed in
    float32 and cast to bf16, torch's CPU SDPA in bf16), as AutoModel.from_pretrained(dtype=torch.bfloat16) runs it.
  Streaming (15 GB RAM and about 25 GB of shared disk, so the 16 GB model is never loaded whole). The shards that hold
    the trunk (Qwen3-8B: 1 to 4; shard 5 is lm_head alone and is never fetched) are downloaded one at a time with
    huggingface_hub into --work, after a free-space check (shard size plus 2 GiB), and each is deleted once the block
    that last needs it has run; a block can straddle two shards, so at most two are on disk. The 64 texts go through as
    one right-padded batch (the tokenizer's pad id, 2-D attention mask; causal, so no real token attends a pad) with
    position ids 0..L-1, layer by layer, using transformers' own modules built from the model's config: the embedding
    rows gathered from embed_tokens, Qwen3RotaryEmbedding, masking_utils.create_causal_mask, one Qwen3DecoderLayer per
    block (made on the meta device and filled with that block's weights, assign=True, strict), attention "sdpa" (what
    AutoModel uses by default), and the final Qwen3RMSNorm applied at the gathered last tokens (a per-position op). Both
    passes run at each block, so every shard is fetched once; only the two hidden-state tensors [64, L, d] are kept
    between blocks.
  Check first (--validate). The same streaming code on Qwen/Qwen3-0.6B (one 1.5 GB file, fetched and deleted the same
    way) against the full transformers AutoModel forward of the same 64 texts in the same padded batch. Bar for this
    check (set by the stage 2 lead for this script, not by the plan), quoted: "streaming output vs the full HF AutoModel
    forward on the same 64 texts, cosine >= 0.99999 per text (fp32)". Exit 1 if any text misses it. Reported, no bar:
    each text run alone without padding (fp32), and the bf16 pass against AutoModel in bf16.
  Provenance. Each JSON log records code_sha256 (this file below the docstring, read at start), whether the code changed
    during the run, and the torch and transformers versions.

Cloud results (Oct 28, 2026, times UTC; torch 2.14.1+cpu, transformers 5.21.0, 2 threads on a shared 4-CPU machine):
  --validate (Qwen3-0.6B), run on this file's code (code_sha256 e20a9a04...e760c; only this docstring was edited after,
    09:28:53-09:37:39, 521 s): pass. Streaming equals AutoModel's padded batch exactly (max abs difference 0.0 in
    fp32, min cos 1 - 2.2e-16; all 64 bf16 rows bit-identical). Reported: each text alone, 1 - cos <= 1.95e-12. The
    two earlier runs (gated on both comparisons) gave the same numbers.
  Qwen3-8B: per-text cos(ref, ref_bf16), the bf16 noise floor, mean 0.999954, min 0.999812 (questions mean 0.999941,
    turns 0.999967); through CLM's heads, state mean 0.999877 (min 0.999262), action mean 0.999893 (min 0.999577).
    Mind the scale: two different texts' raw final vectors already have cos 0.870 on average (0.668 to 0.980) because
    of Qwen3's outlier dimensions; after the heads, 0.61 (max 0.89). 2,843 s (2,833 s compute, 122 s of downloads),
    peak RSS 6.5 GB (of which 2.4 GB anonymous, the rest the shards' mapped pages), at most 7.99 GB of shards on disk.
  Provenance of the npz (corrected after review). From the work folder's file birth times: a first --validate ran
    07:41:20-07:47:25 and passed, then the Qwen3-8B run that wrote the npz ran 07:47:41-08:35:07, then a second
    --validate ran 08:36:29-08:44:17 and passed. (--work/qwen3-8b already held the tokenizer and config from
    07:37:31; what fetched them was not logged.) The file was edited at 08:44:27 and the earlier versions were not
    kept, so neither the 8B run nor those checks can be tied to the code on disk. A stage 2 reviewer closed the gap
    for "ref": the 08:44:27 stream() (byte-identical since, as are calib_texts, Shards, token_ids and padded) re-run on
    Qwen3-8B for texts 1, 7, 49 and 58 (one 4 x 13 batch) matched "ref" to 1 - cos <= 9.5e-13 in fp32. "ref_bf16" is
    one sample of bf16 noise, not a unique value: the same 4 rows moved by up to 1.5e-4 (1 - cos) with the batch's
    padded shape, about the noise floor. It is reported only and enters no bar. After review, --validate was narrowed
    to the lead's bar (it had also gated on the alone comparison, wrongly credited to the lead) and the provenance
    fields were added; the 8B path's numbers do not depend on either change.

Output: results/s20_calib_ref.npz (np.savez, loads with allow_pickle=False): "texts" (64 str), "ref" float32 [64, 4096]
and "ref_bf16" float16 [64, 4096] (both unit rows), "revision" (str), plus "model", "kind" ("q" or "t"), "chat", "index"
(row in that chat's qs or text list) and "ntok". A JSON log (per-text cos(ref, ref_bf16), the bf16 noise floor; timings;
peak RAM; peak shard bytes on disk) goes to --work, never to results/.
Usage (cloud; use at most 2 threads):
  OMP_NUM_THREADS=2 python s20_calib_ref.py --validate   # Qwen3-0.6B check
  OMP_NUM_THREADS=2 python s20_calib_ref.py              # Qwen3-8B -> results/s20_calib_ref.npz
"""
import argparse, hashlib, json, os, resource, shutil, sys, time
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "stage1"))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import get_data  # noqa: E402
from clm_heads import action_text, state_text  # noqa: E402
from lm_states import MAX_LEN, REVISIONS  # noqa: E402

SEED, NQ, NT = 2028, 32, 32
MODEL, CHECK = "Qwen/Qwen3-8B", "Qwen/Qwen3-0.6B"
CHECK_MIN = 0.99999
BAR = "streaming output vs the full HF AutoModel forward on the same 64 texts, cosine >= 0.99999 per text (fp32)"
MARGIN = 2 << 30
SMALL = ("config.json", "generation_config.json", "tokenizer.json", "tokenizer_config.json", "vocab.json", "merges.txt",
         "model.safetensors.index.json")
PASSES = ("fp32", "bf16")


def calib_texts(chats):
    """[(kind, chat, index, text)]: 32 questions then 32 turns (rule in the module docstring)."""
    Q = [(i, r, state_text(q[0])) for i, c in enumerate(chats) for r, q in enumerate(c["qs"])]
    T = [(i, r, action_text(t)) for i, c in enumerate(chats) for r, t in enumerate(c["text"])]
    assert (len(Q), len(T)) == (1536, 5882)
    rng = np.random.default_rng(SEED)
    qi = np.sort(rng.choice(len(Q), NQ, replace=False)); ti = np.sort(rng.choice(len(T), NT, replace=False))
    picked = [("q",) + Q[k] for k in qi] + [("t",) + T[k] for k in ti]
    assert len({p[3] for p in picked}) == NQ + NT
    return picked


def code_sha256():
    """SHA-256 of this file below its module docstring, so a docstring-only edit leaves it unchanged."""
    import ast
    with open(os.path.abspath(__file__), encoding="utf-8") as f:
        src = f.read()
    return hashlib.sha256("".join(src.splitlines(True)[ast.parse(src).body[0].end_lineno:]).encode()).hexdigest()


def peak_rss_mb():
    r = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return r / 2**20 if sys.platform == "darwin" else r / 1024


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 24), b""):
            h.update(block)
    return h.hexdigest()


class Shards:
    """The safetensors files of one Hub revision, fetched one at a time into `root` and deleted after their last use."""

    def __init__(self, repo, revision, root, log):
        from huggingface_hub import HfApi, hf_hub_download
        os.makedirs(root, exist_ok=True)
        self.repo, self.rev, self.root, self.dl, self.log = repo, revision, root, hf_hub_download, log
        info = HfApi().model_info(repo, revision=revision, files_metadata=True)
        assert info.sha == revision, (info.sha, revision)
        self.size = {s.rfilename: s.size for s in info.siblings}
        self.lfs = {s.rfilename: (s.lfs.sha256 if s.lfs else None) for s in info.siblings}
        for f in SMALL:
            if f in self.size:
                self.dl(repo, f, revision=revision, local_dir=root)
        self.open, self.peak_bytes, self.fetched = {}, 0, []
        self.min_free = shutil.disk_usage(root).free
        idx = os.path.join(root, "model.safetensors.index.json")
        if os.path.exists(idx):
            self.where = json.load(open(idx))["weight_map"]
        else:  # one file: list its tensors after fetching it
            self.where = {k: "model.safetensors" for k in self.get("model.safetensors").keys()}

    def get(self, name):
        from safetensors import safe_open
        if name not in self.open:
            free = shutil.disk_usage(self.root).free
            if free < self.size[name] + MARGIN:
                raise SystemExit(f"not enough free disk for {name}: {free / 2**30:.1f} GiB free, "
                                 f"{(self.size[name] + MARGIN) / 2**30:.1f} GiB needed")
            t = time.time()
            p = self.dl(self.repo, name, revision=self.rev, local_dir=self.root)
            dt = time.time() - t
            ok = sha256(p) == self.lfs[name]
            if not ok:
                os.remove(p)
                raise SystemExit(f"{name}: SHA-256 differs from the Hub's LFS hash, deleted")
            self.open[name] = (p, safe_open(p, "pt"))
            self.peak_bytes = max(self.peak_bytes, sum(os.path.getsize(q) for q, _ in self.open.values()))
            self.min_free = min(self.min_free, shutil.disk_usage(self.root).free)
            self.fetched.append(dict(file=name, bytes=self.size[name], seconds=round(dt, 1), sha256_ok=ok))
            self.log(f"  fetched {name} ({self.size[name] / 1e9:.2f} GB, {dt:.0f} s, sha256 ok)")
        return self.open[name][1]

    def drop(self, name):
        p, _ = self.open.pop(name)
        os.remove(p)
        self.log(f"  deleted {name}")

    def drop_all(self):
        for n in list(self.open):
            self.drop(n)


def token_ids(tok, texts):
    assert tok.bos_token is None, tok.bos_token
    ids = [tok.encode(t, add_special_tokens=False) for t in texts]
    assert ids == [tok.encode(t, add_special_tokens=True) for t in texts], "special tokens change the ids"
    assert all(0 < len(e) <= MAX_LEN for e in ids)
    return ids


def padded(ids, pad):
    import torch
    B, L = len(ids), max(map(len, ids))
    x = torch.full((B, L), pad, dtype=torch.long); am = torch.zeros((B, L), dtype=torch.long)
    for r, e in enumerate(ids):
        x[r, :len(e)] = torch.tensor(e); am[r, :len(e)] = 1
    return x, am, torch.tensor([len(e) - 1 for e in ids])


def stream(repo, revision, texts, root, log=print):
    """Final post-norm states at the last real token, {"fp32": float32 [n, d], "bf16": float32 [n, d] (bf16 values)},
    computed block by block from shards fetched one at a time (see the module docstring). Also returns run facts."""
    import torch
    from transformers import AutoConfig, AutoTokenizer
    from transformers.masking_utils import create_causal_mask
    from transformers.models.qwen3.modeling_qwen3 import Qwen3DecoderLayer, Qwen3RMSNorm, Qwen3RotaryEmbedding
    dt = {"fp32": torch.float32, "bf16": torch.bfloat16}
    sh = Shards(repo, revision, root, log)
    try:
        tok = AutoTokenizer.from_pretrained(root)
        ids = token_ids(tok, texts)
        cfg = AutoConfig.from_pretrained(root)
        cfg._attn_implementation = "sdpa"
        assert cfg.model_type == "qwen3" and set(cfg.layer_types) == {"full_attention"}, cfg.layer_types
        n = cfg.num_hidden_layers
        x, am, last = padded(ids, tok.pad_token_id); rows = torch.arange(len(ids))
        pos = torch.arange(x.shape[1]).unsqueeze(0)
        names = [["model.embed_tokens.weight"]] + [[k for k in sh.where if k.startswith(f"model.layers.{i}.")]
                                                   for i in range(n)] + [["model.norm.weight"]]
        assert all(names[1:-1]) and sum(map(len, names)) == len([k for k in sh.where if k != "lm_head.weight"])
        last_use = {}
        for s, ks in enumerate(names):
            for k in ks:
                last_use[sh.where[k]] = s

        def weights(step):
            for f in [f for f in sh.open if last_use.get(f, -1) < step]:
                sh.drop(f)
            return {k: sh.get(sh.where[k]).get_tensor(k) for k in names[step]}

        t0 = time.time()
        with torch.no_grad():
            emb = weights(0)["model.embed_tokens.weight"]
            e = emb[x]; del emb
            h = {p: e.to(dt[p]) for p in PASSES}; del e
            rot = Qwen3RotaryEmbedding(cfg)
            pe = {p: rot(h[p], pos) for p in PASSES}
            mask = {p: create_causal_mask(config=cfg, inputs_embeds=h[p], attention_mask=am, past_key_values=None,
                                          position_ids=pos) for p in PASSES}
            for i in range(n):
                pre = f"model.layers.{i}."
                sd = {k[len(pre):]: v for k, v in weights(1 + i).items()}
                for p in PASSES:
                    with torch.device("meta"):
                        layer = Qwen3DecoderLayer(cfg, i)
                    layer.load_state_dict({k: v.to(dt[p]) for k, v in sd.items()}, strict=True, assign=True)
                    h[p] = layer.eval()(h[p], attention_mask=mask[p], position_ids=pos, position_embeddings=pe[p])
                    del layer
                del sd
                log(f"  block {i + 1}/{n} done, {time.time() - t0:.0f} s, peak RSS {peak_rss_mb():.0f} MB")
            wn = weights(n + 1)["model.norm.weight"]
            out = {}
            for p in PASSES:
                norm = Qwen3RMSNorm(cfg.hidden_size, eps=cfg.rms_norm_eps)
                norm.weight = torch.nn.Parameter(wn.to(dt[p]), requires_grad=False)
                out[p] = norm(h[p][rows, last]).float().numpy()
                assert np.isfinite(out[p]).all()
    finally:
        sh.drop_all()
    facts = dict(n_layers=n, hidden=cfg.hidden_size, batch=list(x.shape), real_tokens=int(am.sum()),
                 pad_id=tok.pad_token_id, attn="sdpa", fetched=sh.fetched, peak_shard_bytes_on_disk=sh.peak_bytes,
                 min_free_disk_bytes=sh.min_free, compute_seconds=round(time.time() - t0, 1))
    return out, ids, facts


def cos_rows(a, b):
    a, b = np.asarray(a, np.float64), np.asarray(b, np.float64)
    return (a * b).sum(1) / (np.linalg.norm(a, axis=1) * np.linalg.norm(b, axis=1))


def summary(c):
    return dict(mean=float(c.mean()), min=float(c.min()), median=float(np.median(c)),
                max_1_minus_cos=float(1 - c.min()))


def validate(texts, work, log):
    """Streaming on Qwen3-0.6B vs the full AutoModel forward: the padded batch (gated, BAR); each text alone and the
    bf16 pass (reported, no bar)."""
    import torch
    from transformers import AutoModel
    rev = REVISIONS[CHECK]
    got, ids, facts = stream(CHECK, rev, texts, os.path.join(work, "qwen3-0.6b"), log)
    from transformers import AutoTokenizer
    pad = AutoTokenizer.from_pretrained(os.path.join(work, "qwen3-0.6b")).pad_token_id
    x, am, last = padded(ids, pad); rows = torch.arange(len(ids))
    res = dict(model=CHECK, revision=rev, stream=facts, bar=BAR, gated_on="fp32_vs_hf_fp32_batch",
               reported_no_bar=["fp32_vs_hf_fp32_alone", "hf_fp32_batch_vs_alone", "bf16_vs_hf_bf16_batch",
                                "bf16_vs_fp32_stream", "hf_bf16_vs_hf_fp32_batch"])
    ref = {}
    with torch.no_grad():
        for p, d in (("fp32", torch.float32), ("bf16", torch.bfloat16)):
            m = AutoModel.from_pretrained(CHECK, revision=rev, dtype=d, attn_implementation="sdpa").eval()
            res[f"hf_{p}_inv_freq_dtype"] = str(m.rotary_emb.inv_freq.dtype)
            out = m(input_ids=x, attention_mask=am, use_cache=False).last_hidden_state
            ref[f"{p}_batch"] = out[rows, last].float().numpy()
            if p == "fp32":
                ref["fp32_alone"] = np.stack([m(input_ids=torch.tensor([e]), use_cache=False).last_hidden_state[0, -1]
                                              .float().numpy() for e in ids])
            del m
    cos = {"fp32_vs_hf_fp32_batch": cos_rows(got["fp32"], ref["fp32_batch"]),
           "fp32_vs_hf_fp32_alone": cos_rows(got["fp32"], ref["fp32_alone"]),
           "hf_fp32_batch_vs_alone": cos_rows(ref["fp32_batch"], ref["fp32_alone"]),
           "bf16_vs_hf_bf16_batch": cos_rows(got["bf16"], ref["bf16_batch"]),
           "bf16_vs_fp32_stream": cos_rows(got["bf16"], got["fp32"]),
           "hf_bf16_vs_hf_fp32_batch": cos_rows(ref["bf16_batch"], ref["fp32_batch"])}
    res["cos"] = {k: summary(v) for k, v in cos.items()}
    res["bf16_identical_to_hf_bf16_rows"] = int((np.abs(got["bf16"] - ref["bf16_batch"]).max(1) == 0).sum())
    res["max_abs_diff_fp32_vs_hf_batch"] = float(np.abs(got["fp32"] - ref["fp32_batch"]).max())
    res["per_text_fp32_vs_hf_batch"] = [round(float(c), 9) for c in cos["fp32_vs_hf_fp32_batch"]]
    res["pass"] = bool(cos["fp32_vs_hf_fp32_batch"].min() >= CHECK_MIN)
    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--validate", action="store_true", help="Qwen3-0.6B: streaming vs the full AutoModel forward")
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--work", default=os.path.join("/tmp/claude-0/stage2", "s20"))
    ap.add_argument("--out", default=os.path.join(HERE, "results", "s20_calib_ref.npz"))
    a = ap.parse_args()
    import torch
    import transformers
    torch.set_num_threads(a.threads)
    os.makedirs(a.work, exist_ok=True)
    t0, code0 = time.time(), code_sha256()
    run = dict(code_sha256=code0, torch=torch.__version__, transformers=transformers.__version__)
    logf = open(os.path.join(a.work, "s20_validate.log" if a.validate else "s20_calib_ref.log"), "a")

    def log(s):
        print(s, flush=True); logf.write(s + "\n"); logf.flush()

    get_data.ensure("locomo")
    picked = calib_texts(C.load_locomo())
    texts = [p[3] for p in picked]
    if a.validate:
        res = validate(texts, a.work, log)
        res.update(seconds=round(time.time() - t0), peak_rss_mb=round(peak_rss_mb()), threads=a.threads,
                   code_edited_during_run=code_sha256() != code0, **run)
        json.dump(res, open(os.path.join(a.work, "s20_validate.json"), "w"), indent=1)
        log(json.dumps({k: v for k, v in res.items() if k not in ("per_text_fp32_vs_hf_batch", "stream")}, indent=1))
        sys.exit(0 if res["pass"] else 1)

    rev = REVISIONS[MODEL]
    got, ids, facts = stream(MODEL, rev, texts, os.path.join(a.work, "qwen3-8b"), log)
    ref = C.unit(got["fp32"]).astype(np.float32); ref16 = C.unit(got["bf16"]).astype(np.float16)
    assert ref.shape == (64, 4096)
    floor = cos_rows(ref, ref16.astype(np.float32))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    np.savez(a.out, texts=np.array(texts), ref=ref, ref_bf16=ref16, revision=np.array(rev), model=np.array(MODEL),
             kind=np.array([p[0] for p in picked]), chat=np.array([p[1] for p in picked], np.int16),
             index=np.array([p[2] for p in picked], np.int16), ntok=np.array([len(e) for e in ids], np.int16))
    z = np.load(a.out, allow_pickle=False)  # the reader's view (s23_clm.py)
    assert [str(t) for t in z["texts"]] == texts and np.array_equal(z["ref"], ref) and str(z["revision"]) == rev
    kinds = np.array([p[0] for p in picked])
    res = dict(model=MODEL, revision=rev, out=a.out, out_bytes=os.path.getsize(a.out), stream=facts,
               cos_ref_vs_ref_bf16=dict(all=summary(floor), questions=summary(floor[kinds == "q"]),
                                        turns=summary(floor[kinds == "t"]),
                                        per_text=[round(float(c), 6) for c in floor]),
               raw_norms=dict(fp32_mean=float(np.linalg.norm(got["fp32"], axis=1).mean()),
                              bf16_mean=float(np.linalg.norm(got["bf16"], axis=1).mean())),
               seconds=round(time.time() - t0), peak_rss_mb=round(peak_rss_mb()), threads=a.threads,
               code_edited_during_run=code_sha256() != code0, **run)
    json.dump(res, open(os.path.join(a.work, "s20_calib_ref.json"), "w"), indent=1)
    log(json.dumps({k: v for k, v in res.items() if k != "stream"}, indent=1))


if __name__ == "__main__":
    main()
