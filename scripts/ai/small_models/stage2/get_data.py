#!/usr/bin/env python3
"""Fetch the two public benchmarks to the paths stage 1 uses, and check them byte for byte (SHA-256).

LoCoMo:        github.com/snap-research/locomo data/locomo10.json  -> /tmp/locomo10.json
LongMemEval-S: huggingface.co/datasets/xiaowu0162/longmemeval-cleaned longmemeval_s_cleaned.json (277 MB)
               -> /tmp/claude-0/data/lme_s.json
Standard library only. Nothing else is downloaded; nothing is uploaded.
"""
import hashlib, os, sys, urllib.request

FILES = {
    "locomo": ("https://raw.githubusercontent.com/snap-research/locomo/main/data/locomo10.json", "/tmp/locomo10.json",
               "79fa87e90f04081343b8c8debecb80a9a6842b76a7aa537dc9fdf651ea698ff4"),
    "lme": ("https://huggingface.co/datasets/xiaowu0162/longmemeval-cleaned/resolve/main/longmemeval_s_cleaned.json",
            "/tmp/claude-0/data/lme_s.json", "d6f21ea9d60a0d56f34a05b609c79c88a451d2ae03597821ea3d5a9678c3a442"),
}


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def ensure(name):
    url, path, want = FILES[name]
    if os.path.exists(path) and sha256(path) == want:
        return path
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".part"
    urllib.request.urlretrieve(url, tmp)
    got = sha256(tmp)
    if got != want:
        os.remove(tmp)
        raise SystemExit(f"{name}: checksum mismatch ({got[:12]}), not used")
    os.replace(tmp, path)
    return path


if __name__ == "__main__":
    for n in sys.argv[1:] or FILES:
        print(n, ensure(n))
