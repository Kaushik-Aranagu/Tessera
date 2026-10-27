#!/usr/bin/env python3
"""Compare the colleague's saved medians with the rerun, row by row (same 'what' key)."""
import json, os, glob
A = "/tmp/claude-0/algos/bench/results"; B = "/tmp/claude-0/algos/review/rerun/results"
rows = []
for pa in sorted(glob.glob(A + "/*.json")):
    name = os.path.basename(pa); pb = os.path.join(B, name)
    if not os.path.exists(pb):
        print(f"MISSING rerun {name}"); continue
    a = {r["what"].strip(): r for r in json.load(open(pa))}; b = {r["what"].strip(): r for r in json.load(open(pb))}
    for k, ra in a.items():
        rb = b.get(k)
        if rb is None:
            print(f"  no rerun row: {name}: {k}"); continue
        ratio = rb["median_ms"] / ra["median_ms"]
        flag = "" if 1 / 1.3 <= ratio <= 1.3 else "  <-- outside 30%"
        rows.append((name, k, ra["median_ms"], rb["median_ms"], ratio))
        print(f"{name[:-5]:<16} {k[:78]:<78} orig {ra['median_ms']:>11.4f}  rerun {rb['median_ms']:>11.4f}  x{ratio:5.2f}{flag}")
        for key in ("overlap", "overlap_clustered", "overlap_random", "cos_to_fp32", "top10_overlap"):
            if key in ra and key in rb and abs(ra[key] - rb[key]) > 0.005:
                print(f"      {key}: orig {ra[key]:.3f} rerun {rb[key]:.3f}")
        if ra.get("note") != rb.get("note") and ("overlap" in (ra.get("note") or "")):
            print(f"      note orig: {ra.get('note')} | rerun: {rb.get('note')}")
out = [r for r in rows if not (1 / 1.3 <= r[4] <= 1.3)]
print(f"\n{len(rows)} rows compared, {len(out)} outside +-30%")
json.dump(rows, open("/tmp/claude-0/algos/review/side/compare.json", "w"), indent=0)
