"""Post-hoc follow-up (labelled as such; not a pre-registered arm): does early stopping chosen on DEV chats fix S6?
Per fold: dev = the first 2 of the 8 training chats (index order); train V1 on the other 6, probe dev session recall@3
at epochs {5, 10, 20, 40}; keep the best epoch E*; retrain V1 on all 8 for E* epochs (same seed, same augmentation);
evaluate S4/S5/S6/H2 on the held-out chats with the canonical path. Test chats are never used to choose anything.
Usage: python -I early_stop.py FOLDS (e.g. 0,1)"""
import json, os, sys
import numpy as np
import torch
sys.path.insert(0, "/tmp/claude-0/sm/dyn-pyramid"); sys.path.insert(0, "/tmp/claude-0/sm")
import e8_pyramid_encoder as E  # noqa: E402

GRID = (5, 10, 20, 40)


def srec(b, up, cs):
    tot = cnt = 0
    for c in cs:
        a = b.a(torch.tensor(c["nodes"])); s = b.s(torch.tensor(c["asks"]))
        groups = [g for _, g in c["sessions"]]
        K, slot = up.batch(*E.pad(a, groups), 4, 1)
        top = np.argsort(-E.score_parents(s, K, slot).numpy(), axis=1, kind="stable")[:, :3]
        g_of = np.empty(len(c["ids"]), int)
        for p, g in enumerate(groups):
            g_of[g] = p
        for qi, (_, ev, _) in enumerate(c["qs"]):
            evn = set(g_of[ev].tolist()); tot += len(evn & set(top[qi].tolist())) / len(evn); cnt += 1
    return tot / cnt


def main():
    torch.set_num_threads(1)
    chats = E.load_tree("/tmp/locomo10.json", "BAAI/bge-small-en-v1.5", "/tmp/claude-0/sm/dyn-pyramid/cache")
    folds = [int(x) for x in sys.argv[1].split(",")]
    dkey = os.urandom(32); out = {}
    for f in folds:
        test = {2 * f, 2 * f + 1}
        tr = [c for i, c in enumerate(chats) if i not in test]
        dev, inner = tr[:2], tr[2:]
        curve = {}

        def probe(b, up, sp, ep):
            if ep in GRID:
                curve[ep] = srec(b, up, dev)
        E.train_joint(inner, f, max(GRID), True, False, probe=probe)
        best = max(GRID, key=lambda e: (curve[e], -e))
        b, up, sp, _ = E.train_joint(tr, f, best, True, False)
        m = E.NPModel("V1", f"f{f}/V1es", b, up, sp)
        ctx = E.Ctx(f, {"V1": m}); ctx.s5["V1"], _ = E.tune_s5(m, tr)
        res = {}
        for c in (chats[i] for i in sorted(test)):
            mem = E.build(c, E.orig_struct(c), {"V1": m}, {"S4": E.Enc("kmeans", m), "S6": E.Enc("up", m)}, dkey)
            r = E.evaluate(mem, ctx, arms=["S4", "S5", "S6", "H2"])
            res[c["cid"]] = {a: [[E.recall(r[a][qi][0], [c["ids"][e] for e in c["qs"][qi][1]]), r[a][qi][3]] for qi in range(len(c["qs"]))]
                             for a in r}
        out[f] = dict(dev_curve=curve, best_epoch=best, s5=ctx.s5["V1"], res=res)
        print(f, "dev curve", {k: round(v, 3) for k, v in curve.items()}, "E*", best, flush=True)
    json.dump(out, open(f"/tmp/claude-0/sm/dyn-pyramid/verify/early_stop_{'_'.join(map(str, folds))}.json", "w"))


if __name__ == "__main__":
    main()
