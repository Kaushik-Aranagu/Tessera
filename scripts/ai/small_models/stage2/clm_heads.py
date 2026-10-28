#!/usr/bin/env python3
"""CLM-v0.1-8B's state and action heads, rebuilt without the contrastive-lm package (stage 2, test 2.3).

Checkpoint: Contrastive-LM/CLM-v0.1-8B, file CLM_v0.1-8B.pt (75,557,149 bytes, Apache-2.0), pinned to revision
e939398d4556fcd9400c76fa8c5a513202f42b0a and SHA-256 b2b4a8c9...4eda5, fetched with huggingface_hub into the HF cache and
read with torch.load(weights_only=True). It holds state_head and action_head state dicts, logit_scale (4.6132) and cfg
{width 1536, depth 3, activation gelu, layernorm True, residual False, hidden_size 4096, projection_dim 512}.

What contrastive-lm 0.1.0 does (clm/heads.py, clm/embedder.py, clm/schema.py of the PyPI wheel, read line by line):
  head(x) = out(GELU(LayerNorm(hidden.0(GELU(inp(x))))))   nn.Linear layers with bias, nn.GELU() (exact erf form),
            nn.LayerNorm(1536) (eps 1e-5, affine); depth 3 means one hidden block; no residual.
  input   the encoder vector is L2-normalised first (Embedder: v / (||v|| + 1e-12)), the vLLM pooler's last-token state.
  output  HeadPair._project: F.normalize(head(x)) (unit 512-d vector).
  score   scale * cos(state_head(s), action_head(c)), scale = exp(logit_scale) clamped at 100, so exactly 100.0 here
          (exp(4.6132) = 100.81). The "clm-raw" ablation uses RAW_SCALE 100 on the raw 4096-d cosine.
  texts   build_pairs(state, {q: {"type": "choice", "instructions": None, "criteria": {key: turn}}}) gives the state text
          state_text(state, None) = to_text(state).strip() (with no instructions the state alone, stripped of outer
          whitespace; a question passed as instructions with an empty state gives the same string) and candidate texts
          to_text(turn) = the turn string verbatim (not stripped; an empty string would fall back to the key). So for
          test 2.3: state head <- question.strip(), action head <- turn text exactly as common.load_locomo builds it
          ("Speaker: text" plus " <blip caption>" when there is one). In LoCoMo one question has a trailing space.

--verify (cloud check, needs contrastive-lm 0.1.0 installed with --no-deps next to torch, numpy and requests): imports
clm.heads (it imports without vllm) and compares HeadPair.project with this module on 256 random 4096-d inputs (max abs
difference must be <= 1e-6), the logit scale, and build_pairs' strings with state_text / action_text on LoCoMo texts.
Usage: python clm_heads.py --verify
"""
import argparse, hashlib, json, os, sys
import numpy as np
import torch

REPO, FILE = "Contrastive-LM/CLM-v0.1-8B", "CLM_v0.1-8B.pt"
REVISION = "e939398d4556fcd9400c76fa8c5a513202f42b0a"
SHA256 = "b2b4a8c9c2d39263eff78a351eb909a342ce9b3bf21a3f07c1d1bf15f1c4eda5"


def checkpoint_path():
    from huggingface_hub import hf_hub_download
    p = hf_hub_download(REPO, FILE, revision=REVISION)
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    if h.hexdigest() != SHA256:
        raise SystemExit("CLM checkpoint checksum mismatch, not used")
    return p


class Head(torch.nn.Module):
    """hidden -> width -> (depth - 2) x [Linear, LayerNorm, GELU] -> proj, as clm.heads.make_head."""

    def __init__(self, width, depth, proj, activation="gelu", layernorm=False, residual=False, hidden=4096):
        super().__init__()
        act = {"gelu": torch.nn.GELU, "relu": torch.nn.ReLU, "silu": torch.nn.SiLU}[activation]
        self.inp = torch.nn.Linear(hidden, width)
        self.hidden = torch.nn.ModuleList(torch.nn.Linear(width, width) for _ in range(depth - 2))
        self.norms = torch.nn.ModuleList((torch.nn.LayerNorm(width) if layernorm else torch.nn.Identity())
                                         for _ in range(depth - 2))
        self.out = torch.nn.Linear(width, proj)
        self.act = act(); self.residual = residual

    def forward(self, x):
        x = self.act(self.inp(x))
        for lin, nrm in zip(self.hidden, self.norms):
            h = self.act(nrm(lin(x)))
            x = x + h if self.residual else h
        return self.out(x)


class CLMHeads:
    """state(x) and action(x): [n, 4096] encoder vectors (any scale) -> [n, 512] unit projections (float32 numpy)."""

    def __init__(self, path=None, device="cpu"):
        ck = torch.load(path or checkpoint_path(), map_location="cpu", weights_only=True)
        cfg = dict(ck["cfg"])
        kw = dict(width=cfg["width"], depth=cfg["depth"], proj=ck.get("projection_dim", cfg.get("projection_dim", 512)),
                  activation=cfg.get("activation", "gelu"), layernorm=cfg.get("layernorm", False),
                  residual=cfg.get("residual", False), hidden=cfg.get("hidden_size", 4096))
        self.state_head, self.action_head = Head(**kw), Head(**kw)
        self.state_head.load_state_dict(ck["state_head"]); self.action_head.load_state_dict(ck["action_head"])
        self.state_head.eval().to(device); self.action_head.eval().to(device)
        self.device, self.cfg, self.dim, self.proj = device, cfg, kw["hidden"], kw["proj"]
        self.scale = float(torch.as_tensor(ck["logit_scale"]).float().exp().clamp(max=100.0))

    def _project(self, head, x, batch=4096):
        x = np.asarray(x, dtype=np.float32)
        x = x / (np.linalg.norm(x, axis=-1, keepdims=True) + 1e-12)
        out = []
        with torch.no_grad():
            for i in range(0, len(x), batch):
                z = head(torch.from_numpy(np.ascontiguousarray(x[i:i + batch])).to(self.device))
                out.append(torch.nn.functional.normalize(z, dim=-1).cpu().numpy())
        return np.concatenate(out) if out else np.zeros((0, self.proj), np.float32)

    def state(self, x):
        return self._project(self.state_head, x)

    def action(self, x):
        return self._project(self.action_head, x)


def state_text(question):
    """clm.schema.state_text(question, None): the question with outer whitespace stripped."""
    return question.strip()


def action_text(turn):
    """clm.schema.candidates for a 'choice' option: the option text verbatim (the key only if it is empty)."""
    return turn


def verify():
    try:
        from clm.heads import HeadPair
        from clm.schema import build_pairs
    except ImportError as e:
        raise SystemExit(f"contrastive-lm not importable here ({e}); install it with pip install --no-deps")
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "stage1"))
    torch.manual_seed(0)
    p = checkpoint_path()
    mine, ref = CLMHeads(p), HeadPair("clm", p, device="cpu").ensure()
    x = np.random.default_rng(0).standard_normal((256, 4096)).astype(np.float32) * 3.0
    xs = x / (np.linalg.norm(x, axis=1, keepdims=True) + 1e-12)  # the package projects already-normalised vectors
    zs, zc = ref.project(xs, xs)
    d_state = float(np.abs(mine.state(x) - zs).max()); d_action = float(np.abs(mine.action(x) - zc).max())
    out = dict(checkpoint=p, revision=REVISION, max_abs_diff_state=d_state, max_abs_diff_action=d_action,
               scale_mine=mine.scale, scale_package=ref.scale, n_params=ref.n_params, cfg=mine.cfg)
    import common as C
    chats = C.load_locomo()
    bad = 0; n = 0; ex = None
    for c in chats:
        for q in c["qs"][:40]:
            turns = c["text"][:25]
            s, keys, texts = build_pairs(q[0], {"q": {"type": "choice", "instructions": None,
                                                      "criteria": {str(i): t for i, t in enumerate(turns)}}})["q"]
            s2 = build_pairs(None, {"q": {"type": "choice", "instructions": q[0],
                                          "criteria": {str(i): t for i, t in enumerate(turns)}}})["q"][0]
            n += 1
            bad += (s != state_text(q[0])) + (s2 != state_text(q[0])) + sum(a != action_text(b) for a, b in zip(texts, turns))
            ex = ex or dict(question=q[0], state_text=s, first_candidate=texts[0], first_turn=turns[0])
    qs = [q[0] for c in chats for q in c["qs"]]
    stripped = [q for q in qs if q != q.strip()]
    s = build_pairs(stripped[0], {"q": {"type": "choice", "criteria": {"0": " padded turn "}}})["q"]
    out.update(text_checks=n, text_mismatches=int(bad), example=ex, questions_changed_by_strip=len(stripped),
               stripped_example=[stripped[0], s[0]], padded_candidate=repr(s[2][0]))
    out["pass"] = d_state <= 1e-6 and d_action <= 1e-6 and mine.scale == ref.scale == 100.0 and bad == 0
    print(json.dumps(out, indent=1))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--verify", action="store_true")
    a = ap.parse_args()
    if a.verify:
        sys.exit(verify())
    h = CLMHeads()
    print(json.dumps(dict(cfg=h.cfg, scale=h.scale), indent=1))
