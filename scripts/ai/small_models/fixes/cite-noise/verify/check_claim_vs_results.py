#!/usr/bin/env python3
"""Compare every number in the claimed JSON (transcribed below) with a results.json produced by the script."""
import json, sys

C = """baseline - 0.6573 0.4749 0 nan nan
move clean 0.6777 0.5026 0.0204 0.0146 0.0267
move wrong30 0.6544 0.4805 -0.0029 -0.0094 0.0033
move wrong60 0.6331 0.4567 -0.0242 -0.0308 -0.0173
move self 0.6341 0.4528 -0.0232 -0.0287 -0.0179
move far30 0.6582 0.4833 0.0009 -0.0052 0.0073
move far60 0.642 0.4661 -0.0153 -0.0217 -0.0085
move visible 0.6549 0.476 -0.0024 -0.0074 0.0028
move-tuned clean 0.6657 0.4856 0.0083 0.0047 0.0119
move-tuned wrong30 0.6609 0.4804 0.0036 0.0004 0.0069
move-tuned wrong60 0.6553 0.475 -0.002 -0.0054 0.0013
move-tuned self 0.6529 0.469 -0.0044 -0.0076 -0.0015
move-tuned far30 0.6609 0.4815 0.0036 0.0004 0.0068
move-tuned far60 0.658 0.4752 0.0007 -0.0025 0.0038
move-tuned visible 0.6584 0.4774 0.0011 -0.0016 0.0038
contrastive clean 0.6831 0.5004 0.0258 0.02 0.0317
contrastive wrong30 0.6714 0.4882 0.0141 0.0084 0.02
contrastive wrong60 0.6604 0.4743 0.0031 -0.0024 0.0086
contrastive self 0.6524 0.4658 -0.0049 -0.0105 0.0001
contrastive far30 0.6742 0.4906 0.0169 0.0112 0.0227
contrastive far60 0.6649 0.4765 0.0076 0.0022 0.013
contrastive visible 0.6657 0.482 0.0084 0.0036 0.0133
agree-bm25 clean 0.6615 0.4849 0.0042 -0.0003 0.0087
agree-bm25 wrong30 0.6594 0.4804 0.0021 -0.0021 0.0061
agree-bm25 wrong60 0.6553 0.4748 -0.002 -0.0058 0.0019
agree-bm25 self 0.6509 0.4647 -0.0064 -0.0102 -0.0025
agree-bm25 far30 0.6606 0.4817 0.0033 -0.0005 0.0073
agree-bm25 far60 0.6582 0.4763 0.0009 -0.0027 0.0042
agree-bm25 visible 0.6573 0.4777 0 -0.0041 0.0041
surprise clean 0.6776 0.5038 0.0203 0.0145 0.026
surprise wrong30 0.6686 0.4931 0.0113 0.0062 0.0165
surprise wrong60 0.6563 0.4824 -0.001 -0.0057 0.0039
surprise self 0.6573 0.4749 0 0 0
surprise far30 0.6594 0.4856 0.0021 -0.0037 0.0081
surprise far60 0.6402 0.4609 -0.0171 -0.0237 -0.0111
surprise visible 0.6585 0.4809 0.0011 -0.0008 0.0031
centered clean 0.6807 0.4981 0.0233 0.0183 0.0289
centered wrong30 0.6655 0.4875 0.0082 0.0026 0.0133
centered wrong60 0.6532 0.4719 -0.0041 -0.0093 0.0012
centered self 0.6521 0.469 -0.0052 -0.009 -0.0015
centered far30 0.6678 0.4879 0.0105 0.0049 0.0158
centered far60 0.6554 0.4697 -0.0019 -0.0072 0.0036
centered visible 0.661 0.481 0.0036 -0.0004 0.0073
slow-adapter clean 0.6732 0.4779 0.0159 0.0095 0.0221
slow-adapter wrong30 0.6673 0.4695 0.01 0.0039 0.0165
slow-adapter wrong60 0.6564 0.4614 -0.0009 -0.0072 0.0051
slow-adapter self 0.6505 0.4587 -0.0068 -0.0128 -0.0007
slow-adapter far30 0.6701 0.4669 0.0128 0.0068 0.0188
slow-adapter far60 0.6534 0.4541 -0.0039 -0.0103 0.0025
slow-adapter visible 0.6665 0.4693 0.0092 0.0035 0.015
verifier+move clean 0.6754 0.5024 0.0181 0.0123 0.0242
verifier+move wrong30 0.665 0.487 0.0077 0.0021 0.0134
verifier+move wrong60 0.6555 0.479 -0.0018 -0.0068 0.0035
verifier+move self 0.6463 0.4629 -0.011 -0.015 -0.0068
verifier+move far30 0.6663 0.4877 0.009 0.0032 0.0146
verifier+move far60 0.6579 0.4819 0.0006 -0.005 0.0056
verifier+move visible 0.6557 0.4791 -0.0016 -0.0066 0.0031
combo clean 0.6756 0.5007 0.0183 0.0133 0.0238
combo wrong30 0.6667 0.4884 0.0094 0.0046 0.0143
combo wrong60 0.6574 0.4776 0.0001 -0.0046 0.0051
combo self 0.6566 0.4707 -0.0007 -0.005 0.0036
combo far30 0.6718 0.4912 0.0145 0.0096 0.0195
combo far60 0.6627 0.4765 0.0054 0.001 0.0096
combo visible 0.6626 0.4843 0.0053 0.0011 0.0097
verifier+combo clean 0.6766 0.5063 0.0193 0.0134 0.0256
verifier+combo wrong30 0.6666 0.4891 0.0093 0.0035 0.015
verifier+combo wrong60 0.6578 0.4831 0.0005 -0.0044 0.0057
verifier+combo self 0.6543 0.4716 -0.003 -0.0071 0.0009
verifier+combo far30 0.6676 0.4926 0.0103 0.0046 0.0162
verifier+combo far60 0.6581 0.4803 0.0008 -0.0042 0.006
verifier+combo visible 0.659 0.4846 0.0017 -0.0031 0.0063"""

rows = json.load(open(sys.argv[1]))["rows"]
idx = {(r["arm"], r["cond"]): r for r in rows}
bad = 0
for line in C.splitlines():
    arm, cond, *v = line.split(); v = [float(x) for x in v]
    r = idx[(arm, cond)]
    got = [r["recall"], r["mh"], r.get("delta", 0.0)] + (list(r["ci"]) if "ci" in r else [float("nan")] * 2)
    for name, want, g in zip(("recall", "mh", "delta", "ci_lo", "ci_hi"), v, got):
        if want != want:
            continue
        if abs(round(g, 4) - want) > 0.00011:
            bad += 1; print(f"MISMATCH {arm}|{cond} {name}: claim {want} results {g:.5f}")
print(f"checked {len(C.splitlines())} rows; mismatches {bad}")
