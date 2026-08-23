# The CHSH inequality — help & usage guide

User-facing guide to the `15CHSH` playground page. The implementation plan is in
`15CHSHPLAN.md`.

## What the page shows

Suppose Alice and Bob share a pair of particles prepared in advance, then separate. Each
picks one of two measurement settings and gets a ±1 outcome. **Local realism** says: if
their outcomes were fixed all along by *some* shared variable λ (unknown to us, but the same
for both), no matter how λ is distributed or how convoluted the rule mapping (setting, λ) to
an outcome is, the CHSH statistic

```text
S = E(a,b) − E(a,b′) + E(a′,b) + E(a′,b′)
```

(E(x,y) = the average of the product of their ±1 outcomes at settings x, y) can never exceed
2 in magnitude. A **Bell pair**, measured the right way, gives S = 2√2 ≈ 2.8284. That gap is
Bell's theorem made numeric: no shared instruction list, however clever, reproduces quantum
correlations.

## Section by section

**Section 1 — the classical bound.** Every deterministic strategy is just four fixed
answers (Alice's response to each of her two settings, Bob's to each of his) — 16 in total,
enumerated exhaustively; every one satisfies \|S\| ≤ 2. A second model — a "shared-direction"
hidden variable λ where each side answers sign(cos(setting − λ)) — is checked by Monte Carlo
and turns out to **saturate** the bound (S ≈ 2.0) rather than fall short of it. This same
model's correlator, as a function of the angle difference, is exactly the line 1 − 2θ/π used
later as the classical comparison curve.

**Section 2 — measuring along a tilted axis.** A(θ) = cos θ·Z + sin θ·X is "spin measured
along an axis tilted θ from Z toward X." There's no `+` on `Matrix`, so it's built entrywise
(page 12's QFT† trick). Measuring it is `ry(-θ)` then an ordinary computational-basis read —
and the page checks this against the exact expectation value before trusting anything
downstream, using the same test qubit as pages 04/08 so the θ=0 and θ=π/2 cases reproduce
their published ⟨Z⟩ and ⟨X⟩ values exactly.

**Section 3 — correlators two ways.** On a Bell pair, every E(a,b) is computed both exactly
(`psi† * (A(a) ⊗ A(b)) * psi`) and by sampling 4000 shots after rotating each qubit into its
measurement basis. Both agree with cos(a − b).

**Section 4 — the violation.** At a = 0, a′ = π/2, b = π/4, b′ = 3π/4, all four correlators
have magnitude 1/√2 and their signs add constructively: S = 2√2 exactly.

**Section 5 — the controls.** A product state (`h` on both qubits, no `cx`) gives S = √2 —
entanglement is *necessary* for the violation, not incidental. A fine sweep over the second
setting confirms the ceiling is exactly 2√2 — quantum mechanics beats the classical bound but
doesn't reach the algebraic maximum of 4 (Tsirelson's bound).

**Section 6 — the sweep, plotted.** E(θ) = ⟨A(0)⊗A(θ)⟩ as an exact cos θ curve, 500-shot
samples, and the Section 1 classical line, all on one chart — the visible gap between the
blue and red curves *is* the Bell violation.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`15CHSH`** (or follow `[Next]` from
   `14ErrorCorrection`).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. This page has a SwiftUI live view (`CHSHChartView`, in `Sources/`). On Xcode 27 betas,
   re-copy the `libcups` shim immediately before running (`PLAYGROUNDSUPPORT.md`
   § "Xcode 27 beta workarounds").
4. Run the page. Output is annotated inline with `// Expected:` comments; anything with a
   shot count attached is statistical, not exact.

## Expected output

```text
deterministic strategies checked: 16
max |S| over all of them: 2

shared-direction model, 200,000 trials per correlator: S ≈ 2.00   (statistical, ±~0.01)

angle    exact ⟨A(θ)⟩   via ry(−θ)+Z
0.0000   0.5000         0.5000
0.5236   0.7392         0.7392
0.7854   0.7866         0.7866
1.5708   0.6124         0.6124

setting pair      exact E    sampled E   cos(a−b)
(a, b)     0.7071    ~0.69      0.7071
(a, b')   -0.7071    ~-0.71    -0.7071
(a', b)    0.7071    ~0.70      0.7071
(a', b')   0.7071    ~0.71      0.7071

exact S = 2.8284   (2√2 = 2.8284)
sampled S ≈ 2.83   (statistical, ±~0.05)

product state |+⟩⊗|+⟩: S = 1.4142
max |S| over a full angle sweep: 2.8284   (Tsirelson: 2.8284)

θ        quantum cos θ   classical line
0.0000    1.0000          1.0000
0.3927    0.9239          0.7500
0.7854    0.7071          0.5000
1.1781    0.3827          0.2500
1.5708    0.0000          0.0000
1.9635   -0.3827         -0.2500
2.3562   -0.7071         -0.5000
2.7489   -0.9239         -0.7500
3.1416   -1.0000         -1.0000
```

The quantum and classical columns agree only at θ = 0, π/2, π and diverge most (~0.207)
near θ = π/4 and 3π/4 — precisely where Section 4's four angles sit.

## The live view

`CHSHChartView` plots three series on one chart: the exact cos θ curve (blue line), the
classical comparison line 1 − 2θ/π (red line), and nine 500-shot samples (green dots)
scattered near the blue curve. The visible gap between the blue and red lines around
θ = π/4 is the CHSH violation made geometric.

## Using it in your own code

```swift
import SwiftQiskitCore

/// The observable "spin along the axis tilted theta from Z toward X".
func A(_ theta: Double) -> Matrix {
    Matrix([
        [Complex(cos(theta), 0), Complex(sin(theta), 0)],
        [Complex(sin(theta), 0), Complex(-cos(theta), 0)]
    ])
}

/// E(a,b) on a fresh Bell pair, sampled instead of computed exactly.
func correlator(_ a: Double, _ b: Double, shots: Int) -> Double {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.cx(0, 1)
    qc.ry(-a, 0)
    qc.ry(-b, 1)
    let counts = qc.measure(shots: shots)
    var total = 0.0
    for (outcome, count) in counts.counts {
        let bits = Array(outcome)
        total += (bits[0] == bits[1] ? 1.0 : -1.0) * Double(count)
    }
    return total / Double(shots)
}

let a = 0.0, ap = Double.pi / 2, b = Double.pi / 4, bp = 3 * Double.pi / 4
let s = correlator(a, b, shots: 4000) - correlator(a, bp, shots: 4000)
      + correlator(ap, b, shots: 4000) + correlator(ap, bp, shots: 4000)
print(s)   // ≈ 2.83, above the classical bound of 2
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first.
- **`Failed to load linked library cups`** — the Xcode 27 beta evaluator bug; re-copy the
  shim (`PLAYGROUNDSUPPORT.md`).
- **Sampled S far from 2.83 (more than ~±0.1)** — check the shot count wasn't reduced;
  4000 shots per correlator keeps the combined statistical error around ±0.03–0.05. Fewer
  shots is fine for a quick check but expect more spread.
- **A different sign convention gives you a wrong-looking correlator** — Section 2 exists
  precisely to catch this: recompute the exact ⟨A(θ)⟩ via the outer-product/adjoint route
  and compare before trusting a `ry`-based measurement in your own variant.
