"""Components B, D, H_c, H_w of the recall-level noise model from noise.json (hub cost per visit taken from unrelated visits)."""
import json
J = json.load(open("/tmp/claude-0/math/theory/noise.json"))["summary"]
print("arm               B (re-ask gain)  D (re-ask loss)  H_c (hub, correct)  H_w (hub, wrong)  p* endpoint  p* if no hub  B/eta  D/eta  H_c/eta H_w/eta")
for rule, eta in [("move", 0.02), ("move", 0.05), ("move", 0.1), ("move", 0.2), ("centered", 0.1)]:
    z, o = J[f"{rule} eta={eta} cites=0.0"], J[f"{rule} eta={eta} cites=1.0"]
    f = z["frac_related"]
    Hc, Hw = -z["d_unrelated"], -o["d_unrelated"]
    B = f * (z["d_related"] + Hc)
    D = -f * (o["d_related"] + Hw)
    ps = (B - Hc) / (B + D + Hw - Hc)
    print(f"{rule} eta={eta:<5}  {B:+.4f}          {D:+.4f}          {Hc:+.4f}             {Hw:+.4f}           {ps:.3f}        {B / (B + D):.3f}       "
          f"{B / eta:.3f}  {D / eta:.3f}  {Hc / eta:.3f}   {Hw / eta:.3f}")
