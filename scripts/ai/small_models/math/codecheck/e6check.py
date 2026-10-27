"""Code-vs-math audit of e6_fixes.py: key-update rules and the cite-noise simulation.

Part A  (synthetic) Plane.learn('move') == normalise(k + eta (s - k)); Plane.learn('anchored') bound
        <k, k0> >= sqrt(1 - cap^2); how far the renormalised anchored key can sit from k0 (cap overshoot);
        unrolled move rule (draft Prop. A.5); angle recursion; projected-gradient identity (Prop. 4.1).
Part B  (LoCoMo, cached embeddings) unmodified e6_fixes.main() with load() patched to the cache -> must reproduce
        e6_result.txt; a replica of its loop that logs the realised wrong-cite rate; the same arms under common
        random numbers (one coin per visit and evidence slot, shared by all arms); noise-seed spread of the
        p = 0.3 arms.
Read-only use of /tmp/claude-0/sm/e5_bridges.py and e6_fixes.py.
"""
import sys, json, io, contextlib, pickle, collections, time
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
import e5_bridges as E5  # noqa: E402
import e6_fixes as E6  # noqa: E402

torch.set_num_threads(1)
out = {}


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


# ---------------- Part A
rng = np.random.default_rng(0)
d, eta, cap = 24, 0.1, 0.3
errs = []
for _ in range(200):
    k = unit(rng.normal(size=d)); s = unit(rng.normal(size=d))
    pl = E6.Plane(k[None].copy(), "move", eta, cap, 0.0); pl.learn(0, s)
    errs.append(np.abs(pl.keys[0] - unit(k + eta * (s - k))).max())
out["A move rule maxabs err"] = float(max(errs))

min_cos, max_dist, max_dist_move = 1.0, 0.0, 0.0
for trial in range(2000):
    k0 = unit(rng.normal(size=d))
    pl = E6.Plane(k0[None].copy(), "anchored", 0.5 if trial % 2 else eta, cap, 0.0)
    pm = E6.Plane(k0[None].copy(), "move", 0.5 if trial % 2 else eta, cap, 0.0)
    for _ in range(40):
        s = unit(rng.normal(size=d) + 3 * rng.normal(size=d) * (trial % 3 == 0))
        pl.learn(0, s); pm.learn(0, s)
        min_cos = min(min_cos, float(pl.keys[0] @ k0)); max_dist = max(max_dist, float(np.linalg.norm(pl.keys[0] - k0)))
        max_dist_move = max(max_dist_move, float(np.linalg.norm(pm.keys[0] - k0)))
out["A anchored min <k,k0>"] = min_cos
out["A bound sqrt(1-cap^2)"] = float(np.sqrt(1 - cap ** 2))
out["A anchored max ||k-k0|| (cap 0.3)"] = max_dist
out["A anchored worst case 2 sin(arcsin(cap)/2)"] = float(2 * np.sin(np.arcsin(cap) / 2))
out["A move max ||k-k0||"] = max_dist_move

# unrolled move rule (draft A, Prop. A.5) and angle recursion
k0 = unit(rng.normal(size=d)); S = unit(rng.normal(size=(15, d)))
k = k0.copy(); u = k0.copy(); norms = [1.0]
for s in S:
    k = unit(k + eta * (s - k))
    u = (1 - eta) * u + eta * np.linalg.norm(u) * s; norms.append(np.linalg.norm(u))
J = len(S)
u_closed = (1 - eta) ** J * k0 + eta * sum((1 - eta) ** (J - j) * norms[j - 1] * S[j - 1] for j in range(1, J + 1))
out["A Prop A.5 unrolled: max|unit(u_closed)-k|"] = float(np.abs(unit(u_closed) - k).max())
out["A Prop A.5 unrolled: max|u_closed-u_iter|"] = float(np.abs(u_closed - u).max())
k = unit(rng.normal(size=d)); s = unit(rng.normal(size=d)); th = np.arccos(k @ s)
k2 = unit(k + eta * (s - k)); th2 = np.arccos(k2 @ s)
out["A angle recursion err"] = float(abs(np.tan(th2) - (1 - eta) * np.sin(th) / ((1 - eta) * np.cos(th) + eta)))
out["A Prop 4.1: unit(k+eta(s-k)) vs unit(k + eta/(1-eta) s)"] = float(np.abs(k2 - unit(k + eta / (1 - eta) * s)).max())

# ---------------- Part B
D = pickle.load(open("/tmp/claude-0/sm/fix-alias-hub/chats.pkl", "rb"))["chats"]
cache = {}


def cached_train(chats, dim, epochs, seed, rank=0):
    key = (seed, rank)
    if key not in cache:
        cache[key] = E5.train(chats, dim, epochs, seed, rank=rank)
    return cache[key]


E6.load = lambda path, model: D
E6.train = cached_train
t0 = time.time()
buf = io.StringIO()
sys.argv = ["e6_fixes.py", "--data", "/tmp/locomo10.json"]
with contextlib.redirect_stdout(buf):
    E6.main()
rep = buf.getvalue()
open("/tmp/claude-0/math/codecheck/e6_rerun.txt", "w").write(rep)
ref = open("/tmp/claude-0/sm/e6_result.txt").read()
out["B e6 rerun identical to e6_result.txt"] = rep.strip() == ref.strip()
out["B e6 rerun time s"] = time.time() - t0


def replica(arms, coin_mode, noise_seed=0, eta=0.1, cap=0.3, margin=0.0):
    """coin_mode 'e6': exactly e6's shared rng stream; 'crn': coins pre-drawn per (visit, evidence slot)."""
    per = collections.defaultdict(list); stats = collections.defaultdict(lambda: [0, 0])
    for fold in range(5):
        test = {2 * fold, 2 * fold + 1}
        heads = {0: cache[(fold, 0)], 16: cache[(fold, 16)]}
        for i in sorted(test):
            c = D[i]
            with torch.no_grad():
                proj = {r: (b.a(torch.tensor(c["nodes"])).numpy(), b.s(torch.tensor(c["asks"])).numpy()) for r, b in heads.items()}
            for o in range(3):
                rng = np.random.default_rng(100 * fold + 10 * i + o)
                order = rng.permutation(len(c["qs"]))
                crng = np.random.default_rng(10_000 * (noise_seed + 1) + 100 * fold + 10 * i + o)
                coins = {r: (crng.random(len(c["qs"][r][1])), crng.random(len(c["qs"][r][1]))) for r in order}
                for name, rank, rule, cites in arms:
                    keys, states = (c["nodes"], c["asks"]) if rank is None else proj[rank]
                    plane = E6.Plane(keys, rule, eta, cap, margin)
                    for r in order:
                        _, ev, cat = c["qs"][r]
                        sc = plane.scores(states[r]); top = list(np.argsort(-sc, kind="stable"))
                        per[name].append(E6.recall(top, ev))
                        if cites == "self":
                            cited = top[:1]
                        else:
                            wrong = [v for v in top[:10] if v not in ev]
                            if coin_mode == "e6":
                                cited = [rng.choice(wrong) if (wrong and rng.random() < cites) else v for v in ev]
                            else:
                                cu, cw = coins[r]
                                cited = [wrong[int(cw[j] * len(wrong))] if (wrong and cu[j] < cites) else v for j, v in enumerate(ev)]
                            st = stats[name]; st[0] += len(ev); st[1] += sum(1 for v in cited if v not in ev)
                        for v in cited:
                            plane.learn(int(v), states[r])
    return per, {k: v[1] / max(v[0], 1) for k, v in stats.items()}


arms_all = [("frozen", None, "none", 0.0), ("bridged", 0, "none", 0.0), ("bridged-lowrank", 16, "none", 0.0)]
for rule in ("move", "alias", "anchored"):
    for cites in (0.0, 0.3, 0.6, "self"):
        arms_all.append((f"{rule} cites={cites}", 16, rule, cites))
t1 = time.time()
per_e6, wrong_e6 = replica(arms_all, "e6")
out["B replica(e6 stream) means"] = {k: round(float(np.mean(v)), 4) for k, v in per_e6.items()}
out["B realised wrong-cite rate (e6 stream)"] = {k: round(v, 4) for k, v in wrong_e6.items() if "cites=0.3" in k or "cites=0.6" in k}
out["B replica time s"] = time.time() - t1

# common random numbers for the noisy move / anchored arms, several noise seeds
noisy = [(f"{rule} cites={p}", 16, rule, p) for rule in ("move", "anchored") for p in (0.3, 0.6)] + [("bridged-lowrank", 16, "none", 0.0)]
spread = collections.defaultdict(list); paired = collections.defaultdict(list)
for seed in range(8):
    per, _ = replica(noisy, "crn", noise_seed=seed)
    base = np.array(per["bridged-lowrank"])
    for name, *_ in noisy[:-1]:
        spread[name].append(float(np.mean(per[name]) - base.mean()))
    for p in (0.3, 0.6):
        paired[p].append(float(np.mean(per[f"anchored cites={p}"]) - np.mean(per[f"move cites={p}"])))
out["B CRN: delta vs lowrank over 8 noise seeds (mean, sd)"] = {k: [round(float(np.mean(v)), 4), round(float(np.std(v, ddof=1)), 4)] for k, v in spread.items()}
out["B CRN: anchored minus move, same coins (mean, sd over seeds)"] = {str(p): [round(float(np.mean(v)), 4), round(float(np.std(v, ddof=1)), 4)] for p, v in paired.items()}
out["B time total s"] = time.time() - t0
print(json.dumps(out, indent=1))
json.dump(out, open("/tmp/claude-0/math/codecheck/e6check.json", "w"), indent=1)
