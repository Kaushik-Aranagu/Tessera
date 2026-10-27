import json, sys, numpy as np
sys.path.insert(0, "/tmp/claude-0/sm/dyn-pyramid"); sys.path.insert(0, "/tmp/claude-0/sm")
import e8_pyramid_encoder as E
R = json.load(open("/tmp/claude-0/sm/dyn-pyramid/results.json"))
es = {}
for fn in ("early_stop_0_1_2.json", "early_stop_3_4.json"):
    es.update(json.load(open(fn)))
chats = E.load_tree("/tmp/locomo10.json", "BAAI/bge-small-en-v1.5", "/tmp/claude-0/sm/dyn-pyramid/cache")
cats = np.array([q[2] for c in chats for q in c["qs"]])
vec = {a: np.array([x[0] for f in sorted(es, key=int) for cid in sorted(es[f]["res"], key=int) for x in es[f]["res"][cid][a]]) for a in ("S4", "S5", "S6", "H2")}
srec = {a: np.nanmean([x[1] for f in es for cid in es[f]["res"] for x in es[f]["res"][cid][a]]) for a in ("S4", "S5", "S6")}
print("E*:", {f: es[f]["best_epoch"] for f in sorted(es)}, "n", len(vec["S6"]))
for a in vec: print(f"  es {a} r@10 {vec[a].mean():.3f} mh {vec[a][cats==1].mean():.3f}" + (f" sess@3 {srec[a]:.3f}" if a in srec else ""))
print("  es S6 - es S4", E.fmt(E.boot(vec["S6"] - vec["S4"])), " es S6 - es S5", E.fmt(E.boot(vec["S6"] - vec["S5"])))
print("  main (40 ep) S6", R["main"]["S6"]["recall10"], "S4", R["main"]["S4"]["recall10"], "S5", R["main"]["S5"]["recall10"], "H2", R["main"]["H2"]["recall10"])
