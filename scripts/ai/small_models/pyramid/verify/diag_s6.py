"""Diagnostic (not part of the pre-registered arms): is S6 < S4 overfitting or an objective/optimisation problem?
Tracks session recall@3 on the 8 TRAINING chats and the 2 held-out chats, per epoch, for V1's learned slots (S6),
untrained k-means slots of the same bridges (S4) and the exact late-pooled score (S5 at tau 0.05, beta 0)."""
import sys, json, numpy as np, torch
sys.path.insert(0, "/tmp/claude-0/sm/dyn-pyramid"); sys.path.insert(0, "/tmp/claude-0/sm")
import e8_pyramid_encoder as E
torch.set_num_threads(1)
chats = E.load_tree("/tmp/locomo10.json", "BAAI/bge-small-en-v1.5", "/tmp/claude-0/sm/dyn-pyramid/cache")
folds = [int(x) for x in sys.argv[1].split(",")] if len(sys.argv) > 1 else [0, 1, 2, 3, 4]
WATCH = {0, 1, 2, 5, 10, 20, 30, 40}
out = {}

def srec(b, up, cs, kind):
    tot = cnt = 0
    for c in cs:
        X = torch.tensor(c["nodes"]); Q = torch.tensor(c["asks"]); a = b.a(X); s = b.s(Q)
        groups = [g for _, g in c["sessions"]]
        if kind == "S5":
            idx, mask = E.pad_index(groups, len(c["ids"]))
            z = torch.cat([s @ a.T / 0.05, torch.full((len(s), 1), float("-inf"))], 1)[:, idx]
            r = z.logsumexp(-1)
        else:
            K, slot = up.batch(*E.pad(a, groups), 4, 1, seeds_only=(kind == "S4"))
            r = E.score_parents(s, K, slot)
        top = np.argsort(-r.numpy(), axis=1, kind="stable")[:, :3]
        g_of = np.empty(len(c["ids"]), int)
        for p, g in enumerate(groups): g_of[g] = p
        for qi, (_, ev, _) in enumerate(c["qs"]):
            evn = set(g_of[ev].tolist()); tot += len(evn & set(top[qi].tolist())) / len(evn); cnt += 1
    return tot / cnt

if __name__ == '__main__':
    for f in folds:
        test = {2 * f, 2 * f + 1}
        tr = [c for i, c in enumerate(chats) if i not in test]; te = [chats[i] for i in sorted(test)]
        rows = []
        def probe(b, up, sp, ep):
            if ep in WATCH:
                row = dict(epoch=ep, **{f"{k}_{nm}": round(srec(b, up, cs, k), 3) for nm, cs in (("train", tr), ("test", te)) for k in ("S4", "S5", "S6")},
                           WO_norm=round(float(up.o.weight.norm()), 3), scale_p=round(float(sp.exp()), 1))
                rows.append(row); print(f, row, flush=True)
        b, up, sp, _ = E.train_joint(tr, f, 0, True, False)
        with torch.no_grad(): probe(b, up, sp, 0)
        E.train_joint(tr, f, 40, True, False, probe=probe)
        out[f] = rows
    json.dump(out, open(f"/tmp/claude-0/sm/dyn-pyramid/verify/diag_s6_{'_'.join(map(str, folds))}.json", "w"), indent=1)
