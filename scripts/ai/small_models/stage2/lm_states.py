#!/usr/bin/env python3
"""Last-real-token hidden states of a Qwen3 causal LM for many short texts (stage 2, tests 2.3 and 2.4).

Two backends with the same semantics:
  mlx    the Mac (mlx==0.32.3, mlx-lm==0.32.0; e.g. mlx-community/Qwen3-8B-8bit). mlx_lm.load, then the decoder is walked
         by hand: h = model.model.embed_tokens(ids); mask = create_attention_mask(h, None) ("causal" when the batch is
         longer than one token, None for one token); h = layer(h, mask, None) for each block of model.model.layers;
         final = model.model.norm(h). Checked against the mlx-lm 0.32.0 wheel: models/qwen3.py (TransformerBlock
         __call__(x, mask=None, cache=None) returns the raw residual stream x + attn + mlp; Qwen3Model returns
         self.norm(h)) and models/base.py (create_attention_mask(h, cache=None, window_size=None, return_array=False)).
         Activations: see below (default: the checkpoint's dtype, bf16 for mlx-community 8-bit and bf16 weights).
  torch  the cloud pilot: transformers AutoModel (the Qwen3Model trunk) in fp32 on CPU. Forward hooks on embed_tokens,
         on every tapped decoder layer (whose output is the raw pre-norm residual stream, as in MLX) and on the final
         norm; the final hook equals last_hidden_state (asserted).
Text handling (both): no chat template; tok.encode(text, add_special_tokens=False) (Qwen3's tokenizer adds no BOS/EOS
either way: bos_token None, and encode with or without special tokens gives the same ids); truncated to the first 512
tokens; right-padded with the tokenizer's pad id (<|endoftext|>, 151643) and gathered at each text's last real token,
which is exact under a causal mask (no real token attends to a pad). Texts are batched in length order under a token
budget, so a batch is nearly free of padding. An empty text (no tokens) is an error.

Taps (plan 2.4): the embedding output, the output of every third block (3, 6, ..., up to the last block) and the final
post-norm state. Qwen3-8B (36 blocks): emb, b3 ... b36, final = 14 taps. Qwen3-0.6B (28 blocks): emb, b3 ... b27, final
= 11 taps. Names are "emb", "b<k>" (output of block k, 1-based) and "final".

Store (resumable): <dir>/meta.json (model, backend, texts sha-256, taps, dim, max_len), tap_<name>.npy (fp16 memmap
[n, dim]), scale_<name>.npy (float32 [n]; per-row power of two s, stored row = h / s, s = 1 unless |h| exceeds 32,768,
so the residual stream's large outlier dimensions never overflow fp16), ntok.npy (tokens used per text) and done.npy
(rows finished). Each chunk of rows is flushed before it is marked done, so a killed run resumes where it stopped. Reading
back: load(dir, name) -> float32 [n, dim] = stored * scale.

Activations (MLX): act "native" (default) computes in the checkpoint's dtype, bf16 for mlx-community weights, as mlx-lm
runs the model; act "float32" casts the embedding output to float32, so every later op computes in float32 (the 8-bit
weights stay 8-bit). The store directory and meta record which one was used.

Self-test (--selftest): the same 16 texts through torch fp32 (Qwen/Qwen3-0.6B, one text at a time and in padded
batches) and MLX (mlx-community/Qwen3-0.6B-bf16 by default, or --mlx-model, e.g. a float32 conversion made with
mlx_lm.convert --dtype float32; --mlx-act float32 for float32 activations); prints per-tap cosines and the final tap's
cosine per text, and exits 1 unless the token ids match and either (float32 activations) every tap's minimum cosine is
at least 0.9999, or (native) the final tap's median cosine is at least 0.99. Needs torch and mlx in one environment (env B).
Cloud results on Linux CPU (mlx[cpu] 0.32.3): float32 activations, 1 - cos <= 1.8e-7 at every tap; bf16 activations,
block taps >= 0.9997 but the final tap's mean 0.9921 (min 0.8752); 8-bit weights (dequantised, float32 compute), block
taps >= 0.9987, final per text >= 0.9991 except the degenerate text "a " * 600 at 0.861.

Usage:
  python lm_states.py --backend mlx --model mlx-community/Qwen3-8B-8bit --texts texts.json --out <dir>
  python lm_states.py --selftest [--mlx-model mlx-community/Qwen3-0.6B-bf16]
"""
import argparse, hashlib, json, os, sys, time
import numpy as np

MAX_LEN = 512
FP16_SAFE = 32768.0
REVISIONS = {  # Hugging Face commits pinned for stage 2 (checked Oct 28, 2026)
    "mlx-community/Qwen3-8B-8bit": "48a0b75b1ae72503e21e1558d040bc227510ff06",
    "Qwen/Qwen3-8B": "b968826d9c46dd6066d109eabc6255188de91218",
    "Qwen/Qwen3-0.6B": "c1899de289a04d12100db370d81485cdf75e47ca",
    "mlx-community/Qwen3-0.6B-bf16": "42096995f6402fde107068cf530136fe64b604f8",
    "mlx-community/Qwen3-0.6B-8bit": "11de96878523501bcaa86104e3c186de07ff9068",
}


def tap_names(n_layers):
    return ["emb"] + [f"b{k}" for k in range(3, n_layers + 1, 3)] + ["final"]


def locomo_text_set(chats):
    """The LoCoMo text list shared by tests 2.3 and 2.4 (one cache): every turn, every question verbatim (2.4) and
    every question with outer whitespace stripped (CLM's state text, 2.3), deduplicated and sorted."""
    s = {t for c in chats for t in c["text"]} | {q[0] for c in chats for q in c["qs"]}
    return sorted(s | {q[0].strip() for c in chats for q in c["qs"]})


def texts_sha(texts):
    h = hashlib.sha256()
    for t in texts:
        h.update(t.encode("utf-8")); h.update(b"\x00")
    return h.hexdigest()


# ---------------------------------------------------------------- backends

class TorchLM:
    """HF AutoModel trunk in fp32 (default) with forward hooks; outputs float32 numpy per tap."""

    def __init__(self, model_id, threads=2, device="cpu", dtype="float32"):
        import torch
        from transformers import AutoModel, AutoTokenizer
        torch.set_num_threads(threads)
        self.torch, self.device = torch, device
        rev = REVISIONS.get(model_id)
        self.tok = AutoTokenizer.from_pretrained(model_id, revision=rev)
        self.model = AutoModel.from_pretrained(model_id, revision=rev, dtype=getattr(torch, dtype)).to(device).eval()
        self.quant = f"{dtype} weights and compute (torch, {device})"
        self.n_layers = len(self.model.layers); self.dim = self.model.config.hidden_size
        self.taps = tap_names(self.n_layers); self.pad = self.tok.pad_token_id
        self._got, self._idx = {}, None
        want = {int(t[1:]) for t in self.taps if t.startswith("b")}

        def grab(name):
            def hook(_m, _i, out):
                o = out[0] if isinstance(out, tuple) else out
                self._got[name] = o[self._idx].detach().float().cpu().numpy()
            return hook
        self.model.embed_tokens.register_forward_hook(grab("emb"))
        for k, layer in enumerate(self.model.layers, 1):
            if k in want:
                layer.register_forward_hook(grab(f"b{k}"))
        self.model.norm.register_forward_hook(grab("final"))

    def encode_ids(self, text, max_len=MAX_LEN):
        return self.tok.encode(text, add_special_tokens=False)[:max_len]

    def forward(self, batch):
        torch = self.torch
        B, L = len(batch), max(map(len, batch))
        ids = torch.full((B, L), self.pad, dtype=torch.long); am = torch.zeros((B, L), dtype=torch.long)
        for r, e in enumerate(batch):
            ids[r, :len(e)] = torch.tensor(e); am[r, :len(e)] = 1
        last = torch.tensor([len(e) - 1 for e in batch])
        self._idx = (torch.arange(B), last); self._got = {}
        with torch.no_grad():
            out = self.model(input_ids=ids.to(self.device), attention_mask=am.to(self.device), use_cache=False)
        fin = out.last_hidden_state[self._idx].float().cpu().numpy()
        assert np.array_equal(fin, self._got["final"]), "final hook differs from last_hidden_state"
        return {t: self._got[t] for t in self.taps}


class MlxLM:
    """mlx-lm model walked block by block (no KV cache); outputs float32 numpy per tap. act="native" keeps the
    checkpoint's activation dtype (bf16 for mlx-community weights, as mlx-lm runs them); act="float32" casts the
    embedding output to float32 so every later op (quantized matmuls included) computes in float32."""

    def __init__(self, model_id, act="native"):
        import mlx.core as mx
        from mlx_lm import load
        from mlx_lm.models.base import create_attention_mask
        self.mx, self.cam = mx, create_attention_mask
        self.model, self.tok, cfg = load(model_id, revision=REVISIONS.get(model_id), return_config=True)
        q = cfg.get("quantization")
        self.quant = (f"mlx {q.get('mode', 'affine')} {q['bits']}-bit, group {q['group_size']}" if q else
                      f"mlx {cfg.get('torch_dtype', cfg.get('dtype', 'unquantised'))}")
        self.act = act
        if act == "float32":
            self.quant += ", float32 activations"
        self.trunk = self.model.model
        self.n_layers = len(self.trunk.layers); self.dim = self.model.args.hidden_size
        self.taps = tap_names(self.n_layers)
        self.pad = self.tok.pad_token_id if self.tok.pad_token_id is not None else self.tok.eos_token_id
        self.want = {int(t[1:]) for t in self.taps if t.startswith("b")}

    def encode_ids(self, text, max_len=MAX_LEN):
        return self.tok.encode(text, add_special_tokens=False)[:max_len]

    def forward(self, batch):
        mx = self.mx
        B, L = len(batch), max(map(len, batch))
        ids = mx.array([e + [self.pad] * (L - len(e)) for e in batch])
        rows, last = mx.arange(B), mx.array([len(e) - 1 for e in batch])
        h = self.trunk.embed_tokens(ids)
        if self.act == "float32":
            h = h.astype(mx.float32)
        mask = self.cam(h, None)
        got = {"emb": h[rows, last]}
        mx.eval(h, got["emb"])
        for k, layer in enumerate(self.trunk.layers, 1):
            h = layer(h, mask, None)
            if k in self.want:
                got[f"b{k}"] = h[rows, last]
            mx.eval(h, *got.values())
        got["final"] = self.trunk.norm(h[rows, last])  # RMSNorm is per position, so norm-then-gather is the same
        mx.eval(got["final"])
        out = {t: np.array(got[t].astype(mx.float32)) for t in self.taps}
        del h, got
        mx.clear_cache()
        return out


def make_backend(backend, model_id, threads=2, device="cpu", act="native"):
    if backend == "torch":
        return TorchLM(model_id, threads=threads, device=device)
    if backend == "mlx":
        return MlxLM(model_id, act=act)
    raise ValueError(backend)


# ---------------------------------------------------------------- resumable store

def batches(order, ids, token_budget=8192, max_batch=64):
    """Consecutive runs of `order` (already sorted by length) whose padded size stays within the token budget."""
    out, b0 = [], 0
    while b0 < len(order):
        b1 = b0 + 1
        while b1 < len(order) and b1 - b0 < max_batch and (b1 - b0 + 1) * len(ids[order[b1]]) <= token_budget:
            b1 += 1
        out.append(list(order[b0:b1])); b0 = b1
    return out


def _new(d, name, dtype, shape):
    return np.lib.format.open_memmap(os.path.join(d, f"{name}.npy"), mode="w+", dtype=dtype, shape=shape)


def _mm(d, name, mode="r"):
    return np.load(os.path.join(d, f"{name}.npy"), mmap_mode=mode)


def encode(texts, out_dir, lm=None, backend=None, model_id=None, max_len=MAX_LEN, token_budget=8192, max_batch=64,
           chunk=512, threads=2, log=None, max_seconds=None, keep=None):
    """Hidden states of every text at every tap (or only the taps in `keep`) into out_dir (resumes). Returns True when
    all rows are done."""
    log = log or (lambda m: print(m, flush=True))
    os.makedirs(out_dir, exist_ok=True)
    meta_p = os.path.join(out_dir, "meta.json"); sha = texts_sha(texts); n = len(texts)
    if os.path.exists(meta_p):
        meta = json.load(open(meta_p))
        if (meta["sha"] != sha or meta["max_len"] != max_len or (model_id and meta["model"] != model_id)
                or (lm is not None and meta.get("quant") != lm.quant)):
            raise SystemExit(f"{out_dir} holds other texts, another model or another precision; use a fresh directory")
        done = np.load(os.path.join(out_dir, "done.npy"))
        if done.all():
            return True
    else:
        meta = None
    if lm is None:
        lm = make_backend(backend, model_id, threads=threads)
    if meta is None:
        meta = dict(model=model_id, revision=REVISIONS.get(model_id), backend=type(lm).__name__, quant=lm.quant,
                    sha=sha, n=n, dim=lm.dim, n_layers=lm.n_layers,
                    taps=[t for t in lm.taps if keep is None or t in keep], all_taps=lm.taps, max_len=max_len,
                    fp16_scale_above=FP16_SAFE, created=time.strftime("%Y-%m-%d %H:%M"))
        for t in meta["taps"]:
            _new(out_dir, f"tap_{t}", np.float16, (n, lm.dim)).flush()
            s = _new(out_dir, f"scale_{t}", np.float32, (n,)); s[:] = 1.0; s.flush()
        _new(out_dir, "ntok", np.int32, (n,)).flush()
        np.save(os.path.join(out_dir, "done.npy"), np.zeros(n, dtype=bool))
        json.dump(meta, open(meta_p + ".tmp", "w"), indent=1); os.replace(meta_p + ".tmp", meta_p)
    done = np.load(os.path.join(out_dir, "done.npy"))
    taps = meta["taps"]; assert meta.get("all_taps", taps) == lm.taps and meta["dim"] == lm.dim
    assert keep is None or taps == [t for t in lm.taps if t in keep], "stored taps differ from the ones asked for"
    store = {t: _mm(out_dir, f"tap_{t}", "r+") for t in taps}
    scale = {t: _mm(out_dir, f"scale_{t}", "r+") for t in taps}
    ntok = _mm(out_dir, "ntok", "r+")
    todo = np.flatnonzero(~done)
    ids = {int(i): lm.encode_ids(texts[i], max_len) for i in todo}
    if any(len(v) == 0 for v in ids.values()):
        raise SystemExit("empty text (no tokens) in the set")
    order = sorted(ids, key=lambda i: (len(ids[i]), i))
    t0 = time.time(); ndone = int(done.sum()); toks = 0
    for c0 in range(0, len(order), chunk):
        if max_seconds and time.time() - t0 > max_seconds:
            log(f"time limit after {ndone}/{n} rows; re-run to continue"); return False
        part = order[c0:c0 + chunk]
        for rows in batches(part, ids, token_budget, max_batch):
            got = lm.forward([ids[i] for i in rows])
            for t in taps:
                v = got[t]
                m = np.abs(v).max(1)
                s = np.where(m > FP16_SAFE, 2.0 ** np.ceil(np.log2(np.maximum(m, 1.0) / FP16_SAFE)), 1.0).astype(np.float32)
                q = (v / s[:, None]).astype(np.float16)
                if not np.isfinite(q).all():
                    raise SystemExit(f"non-finite hidden state at tap {t}")
                store[t][rows] = q; scale[t][rows] = s
            ntok[rows] = [len(ids[i]) for i in rows]; toks += sum(len(ids[i]) for i in rows)
        for t in taps:
            store[t].flush(); scale[t].flush()
        ntok.flush()
        done[part] = True
        np.save(os.path.join(out_dir, "done.tmp.npy"), done); os.replace(os.path.join(out_dir, "done.tmp.npy"),
                                                                         os.path.join(out_dir, "done.npy"))
        ndone += len(part); el = time.time() - t0
        log(f"  {ndone}/{n} rows, {toks / max(el, 1e-9):.0f} tok/s, {el:.0f}s")
    return True


def load(out_dir, tap, rows=None):
    """float32 [n, dim] (or the given rows) of one tap, scale applied."""
    v, s = _mm(out_dir, f"tap_{tap}"), _mm(out_dir, f"scale_{tap}")
    if rows is not None:
        v, s = v[rows], s[rows]
    return np.asarray(v, dtype=np.float32) * np.asarray(s, dtype=np.float32)[:, None]


def meta(out_dir):
    return json.load(open(os.path.join(out_dir, "meta.json")))


def stats(out_dir):
    """Token counts, truncations and fp16 rescaled rows of a finished store."""
    m = meta(out_dir); nt = np.asarray(_mm(out_dir, "ntok"))
    scaled = {t: int((np.asarray(_mm(out_dir, f"scale_{t}")) > 1).sum()) for t in m["taps"]}
    return dict(n=m["n"], tokens=int(nt.sum()), mean_tokens=round(float(nt.mean()), 2), truncated=int((nt >= m["max_len"]).sum()),
                rows_rescaled_for_fp16={t: v for t, v in scaled.items() if v}, model=m["model"], backend=m["backend"])


def is_done(out_dir):
    p = os.path.join(out_dir, "done.npy")
    return os.path.exists(p) and bool(np.load(p).all())


# ---------------------------------------------------------------- self-test

SELFTEST_TEXTS = [
    "Caroline: I went to a LGBTQ support group yesterday and it was so powerful.",
    "When did Melanie paint a sunrise?",
    "Hi!",
    "What did Jon and Gina both have in common?",
    "Nate: I just won my second tournament! It was intense, but I pulled through.",
    "How many times has Joanna found new hiking trails?",
    "I'm trying to plan a trip to Japan next spring. Can you suggest an itinerary for two weeks that covers Tokyo, Kyoto "
    "and Osaka, with a day trip to Nara? I like temples, food markets and quiet gardens more than nightlife.",
    "Tim: a photo of a bookshelf filled with fantasy novels",
    "  leading and trailing spaces  ",
    "Line one\nLine two\n\nLine four",
    "Numbers 3.14159, 2,718 and dates like 7 May 2023 or 2023-05-07.",
    "Ünïcödé: café, naïve, 東京, emoji 🙂",
    "a " * 600,
    "What is the name of Audrey's dog?",
    "John: Yeah, it's been tough, but I'm hanging in there.",
    "Did Deborah go to the yoga retreat before or after her mother passed away?",
]


def selftest(a):
    t0 = time.time()
    ref = TorchLM(a.torch_model, threads=a.threads)
    ids_t = [ref.encode_ids(t) for t in SELFTEST_TEXTS]
    order = sorted(range(len(ids_t)), key=lambda i: (len(ids_t[i]), i))
    groups = batches(order, ids_t, token_budget=1024, max_batch=16)

    def run(lm, ids):  # length-sorted right-padded batches, as encode() runs them
        out = {}
        for g in groups:
            for k, v in lm.forward([ids[i] for i in g]).items():
                out.setdefault(k, np.zeros((len(ids), v.shape[1]), np.float32))[g] = v
        return out
    single = [ref.forward([e]) for e in ids_t]
    R = {k: np.stack([o[k][0] for o in single]) for k in ref.taps}
    Rb = run(ref, ids_t)  # each text alone vs in padded batches: right padding must change nothing
    pad_err = max(float(np.abs(Rb[k] - R[k]).max() / (np.abs(R[k]).max() + 1e-9)) for k in ref.taps)
    del ref
    m = MlxLM(a.mlx_model, act=a.mlx_act)
    ids_m = [m.encode_ids(t) for t in SELFTEST_TEXTS]
    same_ids = ids_m == ids_t
    M = run(m, ids_m)
    out = dict(torch_model=a.torch_model, mlx_model=a.mlx_model, mlx_act=a.mlx_act, same_token_ids=same_ids,
               tokens=[len(e) for e in ids_t], torch_pad_vs_single_max_rel_err=pad_err, taps={})
    for k in M:
        c = np.sum(unit(M[k]) * unit(R[k]), 1)
        out["taps"][k] = dict(mean=round(float(c.mean()), 6), min=round(float(c.min()), 6),
                              max_one_minus_cos=float(f"{float((1 - c).max()):.2e}"))
    fin = np.sum(unit(M["final"]) * unit(R["final"]), 1)
    out["final_cos_by_text"] = [round(float(x), 6) for x in fin]
    if a.mlx_act == "float32":  # same weights, same precision: every tap of every text must match
        out["bar"] = "token ids equal and every tap's minimum cosine >= 0.9999"
        out["pass"] = bool(same_ids and min(v["min"] for v in out["taps"].values()) >= 0.9999)
    else:  # bf16 (or 8-bit) compute against fp32: informative; one degenerate 512-token text is far more sensitive
        out["bar"] = "token ids equal and the final tap's median cosine >= 0.99"
        out["pass"] = bool(same_ids and np.median(fin) >= 0.99)
    out["seconds"] = round(time.time() - t0, 1)
    print(json.dumps(out, indent=1))
    if a.out:
        json.dump(out, open(a.out, "w"), indent=1)
    return 0 if out["pass"] else 1


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--backend", choices=["mlx", "torch"])
    ap.add_argument("--model")
    ap.add_argument("--texts", help="JSON list of strings")
    ap.add_argument("--out")
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--token-budget", type=int, default=8192)
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--torch-model", default="Qwen/Qwen3-0.6B")
    ap.add_argument("--mlx-model", default="mlx-community/Qwen3-0.6B-bf16")
    ap.add_argument("--mlx-act", choices=["native", "float32"], default="native")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest(a))
    texts = json.load(open(a.texts))
    encode(texts, a.out, lm=make_backend(a.backend, a.model, a.threads, act=a.mlx_act), model_id=a.model,
           token_budget=a.token_budget)


if __name__ == "__main__":
    main()
