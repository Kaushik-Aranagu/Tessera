#!/usr/bin/env python3
"""Stage 2, test 2.1: bge-small (and Qwen3-Embedding-0.6B) as fixed-shape Core ML programs on the Mac's Neural Engine.

Plan (docs/research/two-plane-memory/5-stage2-plan.md, section 2.1, committed before any stage 2 number), quoted:
  "`s21_coreml.py`. Convert BAAI/bge-small-en-v1.5 to a fixed-shape Core ML program (sequence 128, fp16, iOS 18 target,
  CLS output, normalised on the host). Same for Qwen3-Embedding-0.6B (last-token output), which 2.2 needs for its
  latency side.
  - **Parity:** on 1,000 LoCoMo texts the Core ML vector (CPU and Neural Engine) has mean cosine at least 0.999 and
    minimum at least 0.99 against fp32 sentence-transformers, and the LoCoMo rank-16 bridge read with Core ML vectors is
    within 0.002 of the fp32 read.
  - **Speed (the bar):** p95 per encode at most 10 ms on the Mac Neural Engine, which leaves the 2x phone allowance
    under the front matter's 20 ms memory hop. If the phone is connected, its Performance Report median must also be at
    most 20 ms. A question's memory step (up to 3 hops, each one encode plus a dot product over the keys) then stays
    under 60 ms.
  - Reported, no bar: first load (fresh compile) and second load, the four compute-unit settings, and the share of the
    model's cost placed on the Neural Engine."
  Common rules: "Timing on the Mac's Neural Engine stands in for the phone with a 2x allowance (phone chips run the same
  ANE generation with less memory bandwidth). The phone itself is checked with Xcode's Performance Report on the
  connected iPhone, which loads the model only, not the Tessera app, so the install gate is untouched."
  Test 2.2 reads this file: "X meets the 2.1 speed bar on the Mac Neural Engine (or on the GPU if that is faster)."

Models (--models, default bge-small,qwen3-emb-0.6b,bge-base: all three are in the planned Mac run). Weights come from
one Hugging Face snapshot per model (revision recorded) that both the reference and the converted wrapper load.
  bge-small       BAAI/bge-small-en-v1.5. Inputs input_ids, attention_mask int32 (1,128); output "embedding" (1,384) =
                  the CLS final hidden state. token_type_ids are the model's zero buffer (folded into a constant).
  qwen3-emb-0.6b  Qwen/Qwen3-Embedding-0.6B. Inputs input_ids int32 (1,128) RIGHT-padded with the pad id, and
                  last_index int32 (1,) = number of real tokens - 1 (the tokenizer appends <|endoftext|>, which is the
                  pooled token); output "embedding" (1,1024) = the final post-norm state gathered IN-GRAPH at last_index
                  (the choice made here; no (1,128,1024) output). No attention-mask input: under causal attention right
                  padding leaves every real token exact. Questions get the model's stored "query" prompt, turns none.
  bge-base        BAAI/bge-base-en-v1.5 as bge-small (768-d). Not named in 2.1, but 2.2 tests it and needs its speed_ok
                  (s22_encoders.py reads models.bge-base.speed_ok), so it is in the default list. Its parity is
                  reported, outside the 2.1 verdict.
  Every model: fp16 mlprogram (compute_precision FLOAT16), minimum_deployment_target iOS18, fixed shape, torch.jit.trace
  of an eager-attention wrapper, L2 normalisation on the host. Host text = ST's own preprocessing: the prompt prepended
  (Qwen questions), strip(), lower() when the ST module has do_lower_case; tokenizer padding to 128 on the right,
  truncation at 128 (counts of truncated texts are reported).
  fp16 choices (same function in exact arithmetic, checked by the torch check below): the additive attention masks are
  built in the wrapper with -1e4 instead of HF's finfo(float32).min, which turns into -inf in fp16 (and HF's
  (1 - mask) * min then gives 0 * -inf = NaN for real tokens). Qwen3's RMSNorms (residual, final, q_norm, k_norm) are
  computed on x / max|x| (SafeRMSNorm) so no square can overflow fp16, because HF's form squares explicitly
  (x.pow(2), an fp16 op after conversion) and Qwen3's residual stream exceeds 255.9; --qwen-norm stock keeps HF's form.
  BERT keeps the native layer_norm op (--bert-ln native, fixed before any Mac run): its fp32 inputs also exceed 255.9,
  but the op is fused and how the backend squares is Apple's; parity on the Mac tests it. --bert-ln safe (a decomposed
  LayerNorm on x / max|x|) exists for a labelled follow-up only; using it after seeing a parity result is post hoc.

Subcommands (one JSON, --out, updated in place; every run recomputes speed_ok and the verdict from what it holds):
  convert  Linux or Mac. Snapshot; sentence-transformers fp32 reference (CPU) on the first 200 of the 1,000 parity
           texts; the wrapper's fp32 activation ranges and a torch CPU fp16 emulation (--n-sim texts; Qwen3's norms
           emulated without HF's internal fp32 up-cast, as the converted all-fp16 graph runs them; emulation only, not
           Core ML, decides nothing); trace; TORCH CHECK (traced wrapper vs ST fp32 on the 200 texts, every cosine
           >= 0.99999); convert; save <work>/<tag>-s128.mlpackage; list the MIL ops, fp32 ops left, non-finite and
           out-of-fp16-range constants (and what uses them), and the package size. The package is saved under
           <work>/.<tag>-s128.partial/ and renamed into place only after the save completes (the old package, if any,
           is renamed aside first), so <work>/<tag>-s128.mlpackage is always either absent or a complete package.
  plan     Mac. Compile to a fresh path; coremltools.models.compute_plan.MLComputePlan.load_from_path(mlmodelc,
           compute_units=CPU_AND_NE) (and ALL): preferred device and estimated cost per MIL operation.
           ane_cost_share = summed cost of operations whose preferred device is the Neural Engine / summed cost of all.
  parity   Mac. The 1,000 texts: a fixed sample (np.random.default_rng(0).permutation, first 1,000) of every LoCoMo turn
           and question in common.load_locomo order (7,418 texts). Core ML (CompiledMLModel, CPU_AND_NE) vs
           sentence-transformers fp32 on CPU: per-text cosine, mean and min (the bar), with counts and percentiles.
           bge-small: the fp32 vectors are common.load_locomo's, computed on this machine's CPU with ST fp32 into
           --stage1-cache (point it at a FRESH folder on the Mac; common reads STAGE1_CACHE at import, set here from the
           flag), and all 7,418 texts are encoded by Core ML. Bridge read = stage 1's dense rank-16 bridge read
           (results/r16_bridges.npz, chat i read by fold i // 2's bridge, common.chat_recalls, recall@10 over 1,536
           questions) once with the fp32 vectors and once with the Core ML vectors; |difference| <= 0.002 is the bar.
           The fp32 read is also compared with stage 1's 0.6622 (reported, no bar). Reported, no bar: the same cosines
           on CPU_AND_GPU for the first 200 texts. Qwen3 and bge-base: cosine bars only (the rank-16 bridges live in
           bge-small's 384-d space), reported, outside the 2.1 verdict.
  bench    Mac. Real tokenised inputs (the 1,000 parity texts, cycled). Per compute unit (CPU_AND_NE, ALL, CPU_AND_GPU,
           CPU_ONLY): ct.models.utils.compile_model to a FRESH .mlmodelc path (compile_s), then two fresh processes on
           that same path: the first gives load_first_s (CompiledMLModel construction, the ANE compiles for a new path)
           and first_pred_ms, the second load_second_s; each process then runs 50 warm-up and 1,000 timed predictions
           (time.perf_counter around predict, Python's input conversion included). p50_ms / p95_ms pool the 2,000 timed
           predictions of both processes (each process's own values are kept). Host tokenisation per text is timed
           separately (tokenize_p50_ms / tokenize_p95_ms, reported, not in the bar). Close Xcode builds and the
           simulator while this runs.
  all      convert (if the .mlpackage is missing or --reconvert; an interrupted save leaves it missing, see convert),
           then bench (first, so its first loads are the first Core ML loads of each package), plan, parity.
  verdict  Anywhere: recompute speed_ok and the verdict, e.g. after --phone-median-ms.
  Every subcommand takes --phone-median-ms (the Xcode Performance Report's median prediction time on the phone).

Bars, computed mechanically from unrounded values:
  models.<tag>.parity.parity_ok   mean_cos >= 0.999 and min_cos >= 0.99 on the 1,000 texts (CPU_AND_NE), and for
                                  bge-small also |bridge_read_coreml - bridge_read_fp32| <= 0.002.
  models.<tag>.speed_ok (2.2)     the relevant p95 <= 10 ms, the relevant p95 being CPU_AND_NE's, or CPU_AND_GPU's when
                                  that is lower ("or on the GPU if that is faster"; speed_basis names it). Missing
                                  timings leave it out (2.2 reads that as pending). It is about speed only; parity_ok
                                  sits next to it.
  verdict (2.1)                   bge-small parity_ok, and bge-small CPU_AND_NE p95 <= 10 ms (the Neural Engine only;
                                  the GPU clause is 2.2's), and, when --phone-median-ms is given, that median <= 20 ms.
                                  "pass" / "fail: <conditions>" / "pending: <conditions>"; without a phone number the
                                  pass reads "pass (phone not checked)".
  "per encode" is timed as one Core ML prediction on pre-tokenised input (the protocol above); tokenisation is reported.

Phone (Xcode Performance Report; model only, nothing is built or installed, Tessera is not opened):
  1. Run `all` first. Connect the iPhone by cable, unlock it, tap Trust if asked. Developer Mode must be on (Settings >
     Privacy & Security > Developer Mode; it is if Tessera has been run from Xcode before). Quit the simulator.
  2. open -a Xcode <work>/bge-small-s128.mlpackage   (opens Xcode's model editor only; no project, no scheme).
  3. In the model editor pick the Performance tab, press "+" (Create Performance Report), choose the iPhone under
     Devices, set Compute Units to "CPU and Neural Engine" (the setting of the Mac bar), press Run Test. Xcode compiles
     the model, sends it to the phone's performance service, loads it and times predictions.
  4. Read the Prediction median (ms); note the Load and Compilation medians and the per-unit operation counts.
     Optionally repeat with Compute Units "All" (reported, no bar).
  5. python -I s21_coreml.py verdict --phone-median-ms <median>   (records it and recomputes the verdict).
  If the report cannot run (no phone, or it errors on the int32 inputs), leave the phone out: the verdict says so.

Mac (Core), env A from the plan (Python 3.12):
  python3.12 -m venv ~/venvs/tess-coreml && source ~/venvs/tess-coreml/bin/activate
  pip install torch==2.7.0 coremltools==9.0 transformers==4.57.6 tokenizers==0.22.2 huggingface_hub==0.36.2 \\
      safetensors==0.8.0 sentence-transformers==5.1.2 numpy==2.2.6
  cd scripts/ai/small_models/stage2
  python -I s21_coreml.py all --work ~/tess-s21 --stage1-cache ~/tess-s21/stage1_cache --threads 8
  (all three models. If it stops, rerun the same command: complete packages are not converted again, and bench, plan
  and parity rerun for every listed model.)
Cost (cloud convert measured; Mac figures are estimates): downloads 133 MB + 1.19 GB + 438 MB (bge-small, Qwen3,
bge-base); packages 63 MB + 1.14 GB + 208 MB under --work, plus one compiled copy at a time (deleted after use) and,
while a package saves, its partial copy; peak memory about 8 GB while Qwen3 converts; 35 to 70 min for `all` on the
M4, most of it Qwen3's CPU_ONLY timing.
Outputs: results/s21_coreml.json on the Mac (on Linux the default is <work>/s21_coreml_linux.json, so a cloud convert
never writes results/). Packages and compiled models stay under --work, which must be outside the repository.
Safety: public weights and data only; no network listener; this script's own code reads or prints no environment
variable (it sets STAGE1_CACHE and TOKENIZERS_PARALLELISM); nothing is unpickled (weights load from safetensors, npz
files without pickle); no .pyc is written.
"""
import argparse, collections, copy, gc, json, os, platform, shutil, subprocess, sys, tempfile, time

os.environ["TOKENIZERS_PARALLELISM"] = "false"
sys.dont_write_bytecode = True  # never write .pyc files into stage1/ (read-only here) or stage2/
import numpy as np  # noqa: E402
import torch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
STAGE1 = os.path.join(HERE, "..", "stage1")
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
RESULTS = os.path.join(HERE, "results")
R16 = os.path.join(RESULTS, "r16_bridges.npz")
MAC = sys.platform == "darwin"

MODELS = {"bge-small": dict(hf="BAAI/bge-small-en-v1.5", kind="bert", dim=384, qprompt=None),
          "qwen3-emb-0.6b": dict(hf="Qwen/Qwen3-Embedding-0.6B", kind="qwen3", dim=1024, qprompt="query"),
          "bge-base": dict(hf="BAAI/bge-base-en-v1.5", kind="bert", dim=768, qprompt=None)}
SEQ, NEG, SEED = 128, -1e4, 0
N_PARITY, N_TORCH, N_WARM, N_TIMED = 1000, 200, 50, 1000
UNITS = ("CPU_AND_NE", "ALL", "CPU_AND_GPU", "CPU_ONLY")
BAR = dict(mean_cos=0.999, min_cos=0.99, bridge_tol=0.002, p95_ms=10.0, phone_median_ms=20.0, torch_cos=0.99999)
STAGE1_BRIDGE = 0.6622
ALLOW = ["*.json", "*.txt", "*.safetensors"]
FP16_MAX = 65504.0


# ---------------------------------------------------------------- data and models

def locomo(a):
    """common.load_locomo with ST fp32 on CPU for any fresh cache; texts = each chat's turns then its questions."""
    os.environ["STAGE1_CACHE"] = os.path.abspath(os.path.expanduser(a.stage1_cache))
    sys.path.insert(0, STAGE1); sys.path.insert(0, HERE)
    import common as C
    import get_data
    from sentence_transformers import SentenceTransformer
    get_data.ensure("locomo")
    fresh = not os.path.exists(os.path.join(C.CACHE, "locomo_emb.npz"))
    C.encoder = lambda: SentenceTransformer(C.MODEL, device="cpu", model_kwargs={"torch_dtype": torch.float32})
    chats = C.load_locomo()
    texts, isq, where = [], [], []
    for i, c in enumerate(chats):
        for j, t in enumerate(c["text"]):
            texts.append(t); isq.append(False); where.append((i, 0, j))
        for j, q in enumerate(c["qs"]):
            texts.append(q[0]); isq.append(True); where.append((i, 1, j))
    sample = np.random.default_rng(SEED).permutation(len(texts))[:N_PARITY]
    return dict(C=C, chats=chats, texts=texts, isq=np.array(isq), where=where, sample=sample, cache=C.CACHE,
                cache_fresh=fresh)


def snapshot(hf):
    from huggingface_hub import snapshot_download
    path = snapshot_download(hf, allow_patterns=ALLOW)
    return path, os.path.basename(path.rstrip("/"))


def st_model(path):
    from sentence_transformers import SentenceTransformer
    st = SentenceTransformer(path, device="cpu", model_kwargs={"torch_dtype": torch.float32})
    assert next(st.parameters()).dtype == torch.float32
    return st


def host_texts(st, spec, texts, isq):
    """ST's preprocessing for the Core ML side: prompt + text (questions, if the model has one), strip, lower."""
    prompt = st.prompts.get(spec["qprompt"], "") if spec["qprompt"] else ""
    lower = bool(getattr(st[0], "do_lower_case", False))
    out = [((prompt + t) if q else t).strip() for t, q in zip(texts, isq)]
    return [t.lower() for t in out] if lower else out, prompt, lower


def ref_vectors(st, spec, texts, isq):
    """fp32 sentence-transformers unit vectors; questions with the stored query prompt where the model has one."""
    out = np.zeros((len(texts), spec["dim"]), np.float32)
    for want in (False, True):
        idx = [k for k, q in enumerate(isq) if bool(q) == want]
        if idx:
            kw = {"prompt_name": spec["qprompt"]} if (want and spec["qprompt"]) else {}
            out[idx] = st.encode([texts[k] for k in idx], normalize_embeddings=True, batch_size=32, **kw)
    return out


def tokenizer(path):
    from transformers import AutoTokenizer
    tok = AutoTokenizer.from_pretrained(path)
    tok.padding_side = "right"
    return tok


def tokenize(tok, texts):
    enc = tok(texts, padding="max_length", max_length=SEQ, truncation="longest_first", return_tensors="np")
    ids, am = enc["input_ids"].astype(np.int32), enc["attention_mask"].astype(np.int32)
    ntrunc = int(sum(len(x) > SEQ for x in tok(texts)["input_ids"]))
    return ids, am, (am.sum(1) - 1).astype(np.int32), ntrunc


def feeds(spec, ids, am, last):
    if spec["kind"] == "bert":
        return dict(input_ids=ids, attention_mask=am)
    return dict(input_ids=ids, last_index=last)


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def cosines(v, ref):
    """Per-row cosine of raw vectors with unit references; a non-finite or all-zero vector is degenerate (-1)."""
    n = np.linalg.norm(v, axis=1); bad = ~(np.isfinite(n) & (n > 0))
    with np.errstate(invalid="ignore", divide="ignore"):
        c = (v / n[:, None] * ref).sum(1)
    return np.where(bad, -1.0, c), bad


def cos_stats(c):
    c = np.asarray(c, np.float64)
    return dict(n=int(len(c)), mean_cos=float(c.mean()), min_cos=float(c.min()), p01_cos=float(np.percentile(c, 1)),
                n_below_0_99=int((c < 0.99).sum()), n_below_0_999=int((c < 0.999).sum()))


# ---------------------------------------------------------------- wrappers

class BertCLS(torch.nn.Module):
    """CLS final hidden state; additive key mask (mask - 1) * 1e4, fp16-safe."""

    def __init__(self, m):
        super().__init__()
        self.m = m

    def forward(self, input_ids, attention_mask):
        h = self.m.embeddings(input_ids=input_ids)
        ext = (attention_mask[:, None, None, :].to(h.dtype) - 1.0) * (-NEG)
        return self.m.encoder(h, attention_mask=ext, return_dict=False)[0][:, 0]


class SafeRMSNorm(torch.nn.Module):
    """w * x * rsqrt(mean(x^2) + eps), computed on y = x / max|x| (and eps / max|x|^2): no fp16 square overflows."""

    def __init__(self, norm):
        super().__init__()
        self.weight = norm.weight; self.eps = norm.variance_epsilon

    def forward(self, x):
        s = x.abs().amax(-1, keepdim=True) + 1e-4  # an add, not clamp: clamp(min=) converts with a +inf bound
        y = x / s
        return self.weight * (y * torch.rsqrt((y * y).mean(-1, keepdim=True) + self.eps / s / s))


class SafeLayerNorm(torch.nn.Module):
    """LayerNorm on y = x / max|x| (eps / max|x|^2), decomposed into primitive ops: no fp16 square overflows."""

    def __init__(self, ln):
        super().__init__()
        self.weight, self.bias, self.eps = ln.weight, ln.bias, ln.eps

    def forward(self, x):
        s = x.abs().amax(-1, keepdim=True) + 1e-4
        y = x / s; y = y - y.mean(-1, keepdim=True)
        return self.weight * (y * torch.rsqrt((y * y).mean(-1, keepdim=True) + self.eps / s / s)) + self.bias


class QwenLast(torch.nn.Module):
    """Final post-norm state at last_index; constant causal mask (-1e4 above the diagonal) and rotary tables."""

    def __init__(self, m):
        super().__init__()
        self.m = m
        pos = torch.arange(SEQ)[None]
        cos, sin = m.rotary_emb(torch.zeros(1, SEQ, m.config.hidden_size), pos)
        self.register_buffer("pos", pos); self.register_buffer("cos", cos); self.register_buffer("sin", sin)
        self.register_buffer("mask", torch.triu(torch.full((SEQ, SEQ), NEG), 1)[None, None])

    def forward(self, input_ids, last_index):
        h = self.m.embed_tokens(input_ids)
        for layer in self.m.layers:
            h = layer(h, attention_mask=self.mask, position_ids=self.pos, position_embeddings=(self.cos, self.sin))
            h = h[0] if isinstance(h, tuple) else h
        return torch.index_select(self.m.norm(h), 1, last_index)[:, 0]


def safe_norms(w):
    """Swap every Qwen3RMSNorm for SafeRMSNorm and every LayerNorm for SafeLayerNorm, in place."""
    for name, mod in list(w.named_modules()):
        new = dict(Qwen3RMSNorm=SafeRMSNorm, LayerNorm=SafeLayerNorm).get(type(mod).__name__)
        if new:
            parent, _, leaf = name.rpartition(".")
            setattr(w.get_submodule(parent) if parent else w, leaf, new(mod))
    return w


def wrapper(spec, path):
    from transformers import AutoModel
    m = AutoModel.from_pretrained(path, attn_implementation="eager", torch_dtype=torch.float32).eval()
    return (BertCLS(m) if spec["kind"] == "bert" else QwenLast(m)).eval()


def run_torch(f, spec, ids, am, last):
    out = []
    with torch.no_grad():
        for k in range(len(ids)):
            x = feeds(spec, torch.from_numpy(ids[k:k + 1]), torch.from_numpy(am[k:k + 1]),
                      torch.from_numpy(last[k:k + 1]))
            out.append(f(*x.values()).float().numpy()[0])
    return np.array(out, np.float32)


def act_stats(w, spec, ids, am, last):
    """fp32 max |activation| per module role over all 128 positions (pads included: a non-finite pad key would poison
    real tokens through the additive mask), and the largest mean square entering a norm."""
    st = collections.defaultdict(lambda: dict(max_abs_in=0.0, max_abs_out=0.0, max_mean_sq_in=0.0))
    keep = ("Linear", "LayerNorm", "Qwen3RMSNorm", "SafeRMSNorm", "Embedding", "BertLayer", "Qwen3DecoderLayer")
    hooks = []
    for name, mod in w.named_modules():
        cls = type(mod).__name__
        if cls not in keep:
            continue
        key = f"{cls}:{name.split('.')[-1]}" if cls in ("Linear", "Qwen3RMSNorm", "SafeRMSNorm") else cls

        def hook(mod, inp, out, key=key, norm="Norm" in cls):
            x = inp[0] if inp else None; o = out[0] if isinstance(out, tuple) else out
            s = st[key]
            if torch.is_tensor(x) and x.is_floating_point():
                s["max_abs_in"] = max(s["max_abs_in"], float(x.abs().max()))
                if norm:
                    s["max_mean_sq_in"] = max(s["max_mean_sq_in"], float(x.double().pow(2).mean(-1).max()))
            if torch.is_tensor(o) and o.is_floating_point():
                s["max_abs_out"] = max(s["max_abs_out"], float(o.abs().max()))
        hooks.append(mod.register_forward_hook(hook))
    run_torch(w, spec, ids, am, last)
    for h in hooks:
        h.remove()
    st = {k: {kk: float(f"{vv:.4g}") for kk, vv in v.items()} for k, v in sorted(st.items())}
    top = max(max(v["max_abs_in"], v["max_abs_out"]) for v in st.values())
    norm_in = max([v["max_abs_in"] for k, v in st.items() if "Norm" in k] or [0.0])
    return dict(n_texts=int(len(ids)), max_abs_any=top, max_abs_norm_input=norm_in,
                norm_square_beyond_fp16=bool(norm_in ** 2 > FP16_MAX),
                any_value_beyond_fp16=bool(top > FP16_MAX), per_module=st)


class PlainRMSNorm(torch.nn.Module):
    """HF's RMSNorm formula without its fp32 up-cast, i.e. as an all-fp16 Core ML graph runs it (emulation only)."""

    def __init__(self, norm):
        super().__init__()
        self.weight = norm.weight; self.eps = norm.variance_epsilon

    def forward(self, x):
        return self.weight * (x * torch.rsqrt(x.pow(2).mean(-1, keepdim=True) + self.eps))


def plain_norms(w):
    for name, mod in list(w.named_modules()):
        if type(mod).__name__ == "Qwen3RMSNorm":
            parent, _, leaf = name.rpartition(".")
            setattr(w.get_submodule(parent) if parent else w, leaf, PlainRMSNorm(mod))
    return w


def fp16_sim(w, spec, ids, am, last, ref, swap=None):
    """torch CPU fp16 copy of a wrapper vs the ST fp32 reference (an emulation of fp16 storage, not Core ML)."""
    h = copy.deepcopy(w)
    h = (swap(h) if swap else h).half()
    v = run_torch(h, spec, ids, am, last)
    del h; gc.collect()
    c, bad = cosines(v, ref)
    return dict(cos_stats(c), n_degenerate_vectors=int(bad.sum()))


# ---------------------------------------------------------------- MIL inspection

def mil_report(ml):
    from coremltools.converters.mil.mil import types
    ops = []

    def walk(block):
        for op in block.operations:
            ops.append(op)
            for b in getattr(op, "blocks", None) or []:
                walk(b)
    walk(ml._mil_program.functions["main"])
    counts = collections.Counter(op.op_type for op in ops)
    fp32 = collections.Counter(op.op_type for op in ops if op.op_type != "const" and any(
        getattr(v, "dtype", None) is not None and types.builtin_to_string(v.dtype) == "fp32" for v in op.outputs))
    nonfinite, big, max_abs, used = [], [], 0.0, collections.Counter()
    for op in ops:
        if op.op_type != "const" or op.outputs[0].val is None:
            continue
        v = np.asarray(op.outputs[0].val)
        if v.dtype.kind != "f" or v.size == 0:
            continue
        if not np.isfinite(v).all():
            nonfinite.append(op.name); used.update(c.op_type for c in op.outputs[0].child_ops)
        m = float(np.abs(v[np.isfinite(v)]).max(initial=0.0)); max_abs = max(max_abs, m)
        if m > FP16_MAX:
            big.append(op.name)
    desc = ml.get_spec().description
    return dict(n_ops=len(ops), op_counts=dict(sorted(counts.items())), fp32_ops=dict(sorted(fp32.items())),
                const_nonfinite=nonfinite[:20], n_const_nonfinite=len(nonfinite), const_nonfinite_used_by=dict(used),
                const_beyond_fp16=big[:20],
                max_abs_const=max_abs, io=[f"{x.name}: {' '.join(str(x.type).split())}"
                                           for d in (desc.input, desc.output) for x in d])


def du_mb(path):
    return sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(path) for f in fs) / 2 ** 20


# ---------------------------------------------------------------- subcommands

def pkg_path(a, tag):
    return os.path.join(a.work, f"{tag}-s128.mlpackage")


def save_pkg(ml, out):
    """ml.save into <work>/.<tag>-s128.partial/, then rename into place, so <out> is always absent or complete."""
    tmpd = os.path.join(os.path.dirname(out), "." + os.path.basename(out).replace(".mlpackage", ".partial"))
    shutil.rmtree(tmpd, ignore_errors=True); os.makedirs(tmpd)
    new, old = os.path.join(tmpd, "new.mlpackage"), os.path.join(tmpd, "old.mlpackage")
    ml.save(new)  # coremltools needs the .mlpackage extension, hence a folder rather than an <out>.partial suffix
    if os.path.exists(out):
        os.replace(out, old)  # renames are atomic; dying between the two leaves <out> absent, so `all` reconverts
    os.replace(new, out)
    shutil.rmtree(tmpd)


def convert(a, res, data):
    import coremltools as ct
    for tag in a.models:
        spec = MODELS[tag]; t0 = time.time(); path, rev = snapshot(spec["hf"])
        first = data["sample"][:N_TORCH]
        texts = [data["texts"][k] for k in first]; isq = data["isq"][first]
        st = st_model(path)
        htexts, prompt, lower = host_texts(st, spec, texts, isq)
        ref = ref_vectors(st, spec, texts, isq)
        del st; gc.collect()
        tok = tokenizer(path); ids, am, last, ntrunc = tokenize(tok, htexts)
        w = wrapper(spec, path); rep = dict(hf_id=spec["hf"], revision=rev, seq=SEQ, n_truncated_of_200=ntrunc,
                                            host=dict(prompt_on_questions=prompt, lower=lower, padding="right"))
        ns = min(a.n_sim, N_TORCH)
        rep["activations_fp32"] = act_stats(w, spec, ids[:max(ns, 1)], am[:max(ns, 1)], last[:max(ns, 1)])
        rep["norm"] = a.qwen_norm if spec["kind"] == "qwen3" else a.bert_ln
        if rep["norm"] == "safe":
            if ns and spec["kind"] == "qwen3":
                # HF's own RMSNorm up-casts to fp32 inside, which torch honours but Core ML's fp16 graph does not
                # (convert leaves no fp32 op), so the stock form is emulated without that cast
                rep["fp16_emulation_stock_norm"] = fp16_sim(w, spec, ids[:ns], am[:ns], last[:ns], ref[:ns],
                                                            swap=plain_norms)
            safe_norms(w)
        if ns:
            rep["fp16_emulation"] = fp16_sim(w, spec, ids[:ns], am[:ns], last[:ns], ref[:ns],
                                             swap=plain_norms if spec["kind"] == "qwen3" else None)
        ex = tuple(torch.from_numpy(x) for x in feeds(spec, ids[:1], am[:1], last[:1]).values())
        with torch.no_grad():
            traced = torch.jit.trace(w, ex, check_trace=False)
        v = unit(run_torch(traced, spec, ids, am, last)); c = (v * ref).sum(1)
        tc = cos_stats(c); tc["ok"] = bool(c.min() >= BAR["torch_cos"]); rep["torch_check"] = tc
        print(f"{tag}: torch check mean {c.mean():.7f} min {c.min():.7f} ({'ok' if tc['ok'] else 'FAIL'})", flush=True)
        names = list(feeds(spec, ids, am, last))
        t1 = time.time()
        ml = ct.convert(traced, source="pytorch", convert_to="mlprogram",
                        inputs=[ct.TensorType(name=n, shape=(1, SEQ) if n != "last_index" else (1,), dtype=np.int32)
                                for n in names],
                        outputs=[ct.TensorType(name="embedding")], compute_precision=ct.precision.FLOAT16,
                        minimum_deployment_target=ct.target.iOS18, skip_model_load=True)
        ml.short_description = f"{spec['hf']} ({rev[:8]}), seq {SEQ}, fp16; L2-normalise the output on the host"
        ml.user_defined_metadata.update({"hf_id": spec["hf"], "revision": rev, "pooling": "cls" if spec["kind"] ==
                                         "bert" else "last_index", "query_prompt": prompt})
        out = pkg_path(a, tag); save_pkg(ml, out)
        rep["mil"] = mil_report(ml); rep["convert_s"] = round(time.time() - t1, 1)
        rep["mlpackage"] = out; rep["mlpackage_mb"] = round(du_mb(out), 1); rep["total_s"] = round(time.time() - t0, 1)
        rep["fp16_risks"] = fp16_risks(spec, rep)
        res["models"].setdefault(tag, {})["convert"] = rep
        print(f"{tag}: {out} {rep['mlpackage_mb']} MB, {rep['mil']['n_ops']} MIL ops, "
              f"fp32 ops {rep['mil']['fp32_ops']},"
              f" risks: {rep['fp16_risks'] or 'none found'}", flush=True)
        del ml, traced, w; gc.collect()


def fp16_risks(spec, rep):
    r, act, mil = [], rep["activations_fp32"], rep["mil"]
    if mil["n_const_nonfinite"]:
        r.append(f"{mil['n_const_nonfinite']} non-finite constants, used by {mil['const_nonfinite_used_by']}")
    if mil["const_beyond_fp16"]:
        r.append(f"constants beyond fp16 range: {mil['const_beyond_fp16'][:5]}")
    if act["any_value_beyond_fp16"]:
        r.append(f"fp32 activations reach {act['max_abs_any']:.4g} > 65504: fp16 overflow")
    if act["max_abs_norm_input"] ** 2 > FP16_MAX:
        r.append(f"norm inputs reach {act['max_abs_norm_input']:.4g} (> 255.9), so their squares exceed fp16: "
                 + ("handled (safe norm on x / max|x|)" if rep["norm"] == "safe" else
                    "an explicit fp16 x.pow(2) overflows (HF's RMSNorm form)" if spec["kind"] == "qwen3" else
                    "native layer_norm op; safe only if the backend does not square in fp16 (parity on the Mac tells)"))
    for k in ("fp16_emulation", "fp16_emulation_stock_norm"):
        e = rep.get(k)
        if e and (e["n_degenerate_vectors"] or e["min_cos"] < BAR["min_cos"]):
            r.append(f"{k}: {e['n_degenerate_vectors']} of {e['n']} vectors zero or non-finite, min cos "
                     f"{e['min_cos']:.4f}" + (" (HF's stock norm, NOT in this package: why the safe norm is used)"
                                              if k.endswith("stock_norm") else ""))
    return r


def mac_only(what):
    if not MAC:
        raise SystemExit(f"`{what}` needs macOS: Core ML predictions, compilation and MLComputePlan run only on a Mac. "
                         "On Linux only `convert` (and `verdict`) work.")


def compile_fresh(a, tag, label):
    import coremltools as ct
    d = tempfile.mkdtemp(prefix=f"{tag}-{label}-", dir=os.path.join(a.work, "compiled"))
    dst = os.path.join(d, f"{tag}.mlmodelc")
    t = time.perf_counter(); ct.models.utils.compile_model(pkg_path(a, tag), dst)
    return d, dst, time.perf_counter() - t


def plan(a, res, data=None):
    mac_only("plan")
    import coremltools as ct
    from coremltools.models.compute_device import MLCPUComputeDevice, MLGPUComputeDevice, MLNeuralEngineComputeDevice
    from coremltools.models.compute_plan import MLComputePlan

    def dev(d):
        return ("ane" if isinstance(d, MLNeuralEngineComputeDevice) else "gpu" if isinstance(d, MLGPUComputeDevice)
                else "cpu" if isinstance(d, MLCPUComputeDevice) else "none")
    for tag in a.models:
        d, dst, _ = compile_fresh(a, tag, "plan"); rep = {}
        for u in ("CPU_AND_NE", "ALL"):
            p = MLComputePlan.load_from_path(dst, compute_units=getattr(ct.ComputeUnit, u))
            ops = []

            def walk(block):
                for op in block.operations:
                    ops.append(op)
                    for b in op.blocks or []:
                        walk(b)
            walk(p.model_structure.program.functions["main"].block)
            n, w, off = collections.Counter(), collections.Counter(), []
            for op in ops:
                use = p.get_compute_device_usage_for_mlprogram_operation(op)
                cost = p.get_estimated_cost_for_mlprogram_operation(op)
                k = dev(use.preferred_compute_device) if use else "none"; c = float(cost.weight) if cost else 0.0
                n[k] += 1; w[k] += c
                if use and k != "ane" and op.operator_name != "const":
                    off.append(dict(op=op.operator_name, device=k, cost=c,
                                    supported=sorted({dev(s) for s in use.supported_compute_devices})))
            tot = sum(w.values())
            rep[u] = dict(n_ops=len(ops), ops_by_device=dict(n), cost_by_device={k: round(v, 6) for k, v in w.items()},
                          ane_cost_share=(w["ane"] / tot) if tot else None, off_ane=off[:60], n_off_ane=len(off))
        shutil.rmtree(d)
        m = res["models"].setdefault(tag, {}); m["plan"] = rep
        m["ane_cost_share"] = rep["CPU_AND_NE"]["ane_cost_share"]
        print(f"{tag}: ANE cost share {m['ane_cost_share']}, ops off the ANE {rep['CPU_AND_NE']['n_off_ane']}",
              flush=True)


def parity(a, res, data):
    mac_only("parity")
    import coremltools as ct
    C, texts, isq, sample = data["C"], data["texts"], data["isq"], data["sample"]
    for tag in a.models:
        spec = MODELS[tag]; path, rev = snapshot(spec["hf"]); st = st_model(path)
        if tag == "bge-small":
            idx = np.arange(len(texts))
            ref = np.stack([data["chats"][i]["nodes" if k == 0 else "asks"][j] for i, k, j in data["where"]])
        else:
            idx = sample; ref = np.zeros((len(texts), spec["dim"]), np.float32)
            ref[sample] = ref_vectors(st, spec, [texts[k] for k in sample], isq[sample])
        htexts, prompt, lower = host_texts(st, spec, [texts[k] for k in idx], isq[idx])
        del st; gc.collect()
        tok = tokenizer(path); ids, am, last, ntrunc = tokenize(tok, htexts)
        d, dst, _ = compile_fresh(a, tag, "parity")
        rep = dict(revision=rev, compute_units="CPU_AND_NE", n_truncated=ntrunc, n_encoded=int(len(idx)),
                   fp32_reference=("common.load_locomo vectors (ST fp32, CPU) in " + data["cache"] +
                                   (" (computed in this run)" if data["cache_fresh"] else " (cache found)"))
                   if tag == "bge-small" else "sentence-transformers fp32 on CPU, this run")
        row = {int(t): r for r, t in enumerate(idx)}; f = feeds(spec, ids, am, last); out = {}
        for u, rows in (("CPU_AND_NE", list(idx)), ("CPU_AND_GPU", list(sample[:N_TORCH]))):
            cm = ct.models.CompiledMLModel(dst, compute_units=getattr(ct.ComputeUnit, u))
            V = np.zeros((len(texts), spec["dim"]), np.float32)
            for t in rows:
                r = row[int(t)]
                V[t] = np.asarray(cm.predict({k: v[r:r + 1] for k, v in f.items()})["embedding"], np.float32).ravel()
            del cm
            cos, bad = cosines(V, ref)
            with np.errstate(invalid="ignore", divide="ignore"):
                out[u] = (unit(V), cos, bad)
        shutil.rmtree(d)
        Vn, cos, bad = out["CPU_AND_NE"]
        rep.update(cos_stats(cos[sample])); rep["n_degenerate_vectors"] = int(bad[sample].sum())
        if tag == "bge-small":
            rep["all_7418"] = dict(cos_stats(cos), n_degenerate_vectors=int(bad.sum()))
        g = sample[:N_TORCH]
        rep["cpu_and_gpu_first_200"] = dict(cos_stats(out["CPU_AND_GPU"][1][g]),
                                            n_degenerate_vectors=int(out["CPU_AND_GPU"][2][g].sum()))
        ok = rep["mean_cos"] >= BAR["mean_cos"] and rep["min_cos"] >= BAR["min_cos"]
        if tag == "bge-small":
            nodes32, asks32, nodescm, askscm = ([[] for _ in data["chats"]] for _ in range(4))
            for (i, k, j), r32, rcm in zip(data["where"], ref, Vn):
                (nodes32 if k == 0 else asks32)[i].append(r32); (nodescm if k == 0 else askscm)[i].append(rcm)
            r32 = bridge_read(C, data["chats"], nodes32, asks32); rcm = bridge_read(C, data["chats"], nodescm, askscm)
            diff = float(rcm.mean() - r32.mean())
            rep.update(bridge_read_fp32=float(r32.mean()), bridge_read_coreml=float(rcm.mean()), bridge_diff=diff,
                       bridge_questions_changed=int((r32 != rcm).sum()), bridge_ok=bool(abs(diff) <= BAR["bridge_tol"]),
                       fp32_read_vs_stage1=dict(stage1=STAGE1_BRIDGE, here=round(float(r32.mean()), 4),
                                                same_4dp=bool(round(float(r32.mean()), 4) == STAGE1_BRIDGE)))
            ok = ok and rep["bridge_ok"]
        else:
            rep["bridge"] = "n/a: the rank-16 bridges live in bge-small's 384-d space"
        rep["parity_ok"] = bool(ok)
        res["models"].setdefault(tag, {})["parity"] = rep
        print(f"{tag}: parity mean {rep['mean_cos']:.6f} min {rep['min_cos']:.6f}"
              + (f" bridge fp32 {rep['bridge_read_fp32']:.4f} coreml {rep['bridge_read_coreml']:.4f}"
                 if tag == "bge-small" else "") + f" -> parity_ok {ok}", flush=True)


def bridge_read(C, chats, nodes, asks):
    from retrieval import load_bridge
    z = np.load(R16); rec = []
    for i, c in enumerate(chats):
        c2 = dict(c, nodes=np.array(nodes[i], np.float32), asks=np.array(asks[i], np.float32))
        rec += C.chat_recalls(load_bridge(z, f"f{i // 2}_r16"), c2)
    return np.array(rec)


def bench(a, res, data):
    mac_only("bench")
    texts, isq, sample = data["texts"], data["isq"], data["sample"]
    for tag in a.models:
        spec = MODELS[tag]; path, rev = snapshot(spec["hf"]); st = st_model(path)
        htexts, _, _ = host_texts(st, spec, [texts[k] for k in sample], isq[sample])
        del st; gc.collect()
        tok = tokenizer(path); ids, am, last, _ = tokenize(tok, htexts)
        inp = os.path.join(a.work, f"bench_inputs_{tag}.npz"); np.savez(inp, **feeds(spec, ids, am, last))
        tt = []
        for t in htexts[:N_TORCH]:
            t0 = time.perf_counter()
            tok([t], padding="max_length", max_length=SEQ, truncation=True, return_tensors="np")
            tt.append((time.perf_counter() - t0) * 1e3)
        rep = dict(revision=rev, inputs=f"{len(ids)} real tokenised LoCoMo texts, cycled", warmup=N_WARM,
                   timed_per_process=N_TIMED, tokenize_p50_ms=float(np.percentile(tt, 50)),
                   tokenize_p95_ms=float(np.percentile(tt, 95)))
        for u in UNITS:
            d, dst, comp = compile_fresh(a, tag, u)
            r1, r2 = child_run(dst, u, inp), child_run(dst, u, inp)
            shutil.rmtree(d)
            if "error" in r1 or "error" in r2:
                rep[u] = dict(error=r1.get("error") or r2.get("error")); print(f"{tag} {u}: {rep[u]}", flush=True)
                continue
            ts = np.array(r1.pop("times_ms") + r2.pop("times_ms"))
            rep[u] = dict(compile_s=comp, load_first_s=r1["load_s"], load_second_s=r2["load_s"],
                          first_pred_ms=r1["first_pred_ms"], first_pred_ms_second_load=r2["first_pred_ms"],
                          p50_ms=float(np.percentile(ts, 50)), p95_ms=float(np.percentile(ts, 95)),
                          mean_ms=float(ts.mean()), max_ms=float(ts.max()), first_process=r1, second_process=r2)
            print(f"{tag} {u}: load {r1['load_s']:.3f}s / {r2['load_s']:.3f}s, first {r1['first_pred_ms']:.1f} ms, "
                  f"p50 {rep[u]['p50_ms']:.2f} ms, p95 {rep[u]['p95_ms']:.2f} ms", flush=True)
        res["models"].setdefault(tag, {})["bench"] = rep


def child_run(dst, u, inp):
    cmd = [sys.executable, "-I", os.path.abspath(__file__), "_child", "--mlmodelc", dst, "--unit", u, "--inputs", inp]
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=3600)
    lines = [x for x in p.stdout.splitlines() if x.startswith("{")]
    if p.returncode or not lines:
        return dict(error=f"exit {p.returncode}: {p.stderr.strip()[-600:]}")
    return json.loads(lines[-1])


def child(a):
    """One fresh process: load (timed), first prediction, 50 warm-up, 1,000 timed predictions."""
    import coremltools as ct
    z = dict(np.load(a.inputs)); n = len(z["input_ids"])
    fs = [{k: np.ascontiguousarray(v[i:i + 1]) for k, v in z.items()} for i in range(n)]
    t = time.perf_counter(); m = ct.models.CompiledMLModel(a.mlmodelc, compute_units=getattr(ct.ComputeUnit, a.unit))
    load = time.perf_counter() - t
    t = time.perf_counter(); m.predict(fs[0]); first = (time.perf_counter() - t) * 1e3
    for k in range(N_WARM):
        m.predict(fs[(k + 1) % n])
    ts = []
    for k in range(N_TIMED):
        x = fs[k % n]; t = time.perf_counter(); m.predict(x); ts.append((time.perf_counter() - t) * 1e3)
    print(json.dumps(dict(load_s=load, first_pred_ms=first, p50_ms=float(np.percentile(ts, 50)),
                          p95_ms=float(np.percentile(ts, 95)), times_ms=ts)))


# ---------------------------------------------------------------- verdict and file

def finish(res, phone):
    if phone is not None:
        res["phone"] = dict(median_ms=float(phone), source="Xcode Performance Report, CPU and Neural Engine",
                            ok=bool(phone <= BAR["phone_median_ms"]))
    for tag, m in res["models"].items():
        b = m.get("bench", {}); ne = b.get("CPU_AND_NE", {}).get("p95_ms"); gpu = b.get("CPU_AND_GPU", {}).get("p95_ms")
        m.pop("speed_ok", None); m.pop("speed_basis", None)
        if ne is not None and ne <= BAR["p95_ms"]:
            m["speed_ok"], m["speed_basis"] = True, f"CPU_AND_NE p95 {ne:.3f} ms <= 10"
        elif ne is not None and gpu is not None:
            best, name = (gpu, "CPU_AND_GPU") if gpu < ne else (ne, "CPU_AND_NE")
            m["speed_ok"], m["speed_basis"] = bool(best <= BAR["p95_ms"]), f"{name} p95 {best:.3f} ms (the faster)"
        if "parity" in m:
            m["parity_ok"] = m["parity"]["parity_ok"]
    bs = res["models"].get("bge-small", {})
    ne = bs.get("bench", {}).get("CPU_AND_NE", {}).get("p95_ms")
    cond = dict(bge_small_parity=bs.get("parity", {}).get("parity_ok"),
                bge_small_ne_p95_le_10ms=None if ne is None else bool(ne <= BAR["p95_ms"]),
                phone_median_le_20ms=res.get("phone", {}).get("ok"))
    bad = [k for k, v in cond.items() if v is False]
    wait = [k for k, v in cond.items() if v is None and k != "phone_median_le_20ms"]
    res["verdict_conditions"] = cond
    res["verdict"] = (f"fail: {', '.join(bad)}" if bad else f"pending: {', '.join(wait)}" if wait else
                      "pass" if cond["phone_median_le_20ms"] else "pass (phone not checked)")
    return res


def load_res(path):
    if os.path.exists(path):
        return json.load(open(path))
    return dict(test="2.1", plan="docs/research/two-plane-memory/5-stage2-plan.md", bars=BAR,
                protocol="see s21_coreml.py docstring", models={})


def env_info():
    import coremltools, sentence_transformers, transformers
    e = dict(python=platform.python_version(), platform=platform.platform(), machine=platform.machine(),
             coremltools=coremltools.__version__, torch=torch.__version__, transformers=transformers.__version__,
             sentence_transformers=sentence_transformers.__version__, numpy=np.__version__,
             utc=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()))
    if MAC:
        e["macos"] = platform.mac_ver()[0]
        try:
            e["chip"] = subprocess.run(["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True,
                                       text=True).stdout.strip()
        except OSError:
            e["chip"] = "unknown"
    return e


def save(path, res):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(res, f, indent=1, default=lambda o: o.item() if hasattr(o, "item") else str(o))
    os.replace(tmp, path)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("cmd", choices=["convert", "plan", "parity", "bench", "all", "verdict", "_child"])
    ap.add_argument("--models", default="bge-small,qwen3-emb-0.6b,bge-base")
    ap.add_argument("--work", default="~/tess-s21" if MAC else "/tmp/claude-0/stage2/coreml")
    ap.add_argument("--stage1-cache", default=None, help="STAGE1_CACHE for common (default <work>/stage1_cache)")
    ap.add_argument("--out", default=None)
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--n-sim", type=int, default=32, help="texts for the torch fp16 emulation in convert (0: skip)")
    ap.add_argument("--qwen-norm", choices=["safe", "stock"], default="safe")
    ap.add_argument("--bert-ln", choices=["native", "safe"], default="native")
    ap.add_argument("--reconvert", action="store_true")
    ap.add_argument("--phone-median-ms", type=float, default=None)
    ap.add_argument("--mlmodelc"); ap.add_argument("--unit"); ap.add_argument("--inputs")
    a = ap.parse_args()
    if a.cmd == "_child":
        return child(a)
    a.models = [m.strip() for m in a.models.split(",") if m.strip()]
    for m in a.models:
        if m not in MODELS:
            raise SystemExit(f"unknown model {m}; known: {', '.join(MODELS)}")
    a.work = os.path.abspath(os.path.expanduser(a.work))
    if os.path.commonpath([a.work, REPO]) == REPO:
        raise SystemExit("--work must be outside the repository (packages are large)")
    os.makedirs(os.path.join(a.work, "compiled"), exist_ok=True)
    a.stage1_cache = a.stage1_cache or os.path.join(a.work, "stage1_cache")
    out = a.out or (os.path.join(RESULTS, "s21_coreml.json") if MAC else os.path.join(a.work, "s21_coreml_linux.json"))
    torch.set_num_threads(a.threads)
    res = load_res(out)
    if a.cmd == "verdict":
        save(out, finish(res, a.phone_median_ms)); print("s21 VERDICT:", res["verdict"]); return
    if a.cmd in ("plan", "parity", "bench", "all"):
        mac_only(a.cmd)
    res["env"] = env_info()
    data = None if a.cmd == "plan" else locomo(a)
    steps = {"convert": [convert], "plan": [plan], "parity": [parity], "bench": [bench],
             "all": [convert, bench, plan, parity]}[a.cmd]
    for step in steps:
        try:  # models finished before a crash are kept
            if step is convert and a.cmd == "all":
                todo = [m for m in a.models if a.reconvert or not os.path.exists(pkg_path(a, m))]
                if todo:
                    step(argparse.Namespace(**{**vars(a), "models": todo}), res, data)
            else:
                step(a, res, data)
        finally:
            save(out, finish(res, a.phone_median_ms))
    print(f"wrote {out}\ns21 VERDICT: {res['verdict']}", flush=True)


if __name__ == "__main__":
    main()
