#!/usr/bin/env python3
"""Print every saved micro-benchmark row as one Markdown table (raw numbers, single-thread x86)."""
import glob
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
order = ["b1_encoder", "b2_scoring", "b2b_batch", "b2h_hnsw", "b3_pyramid", "b3k_kmeans_tree", "b4_bm25",
         "b5_internode", "b6_train", "b7_paths"]
print("| script | what | median ms | p95 ms | runs | note |")
print("|---|---|---:|---:|---:|---|")
for name in order:
    path = os.path.join(HERE, "results", name + ".json")
    if not os.path.exists(path):
        continue
    for r in json.load(open(path)):
        med, p95 = r["median_ms"], r["p95_ms"]
        fmt = (lambda x: f"{x:.4f}") if med < 1 else ((lambda x: f"{x:.2f}") if med < 1000 else (lambda x: f"{x:,.0f}"))
        print(f"| {name}.py | {r['what'].strip()} | {fmt(med)} | {fmt(p95)} | {r['n']} | {r.get('note', '')} |")
