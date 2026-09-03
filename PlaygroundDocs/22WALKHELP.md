# The discrete-time quantum walk — help & usage guide

User-facing guide to the `22Walk` playground page. The implementation plan is in
`22WALKPLAN.md`.

## What the page shows

No earlier page shows interference producing a *distribution* rather than answering an oracle
question (Deutsch/DJ/BV) or amplifying a marked item (Grover). A coin qubit plus a position
register on a cycle spreads **ballistically** (faster than any classical random walk), and the
shape of that spread is a direct signature of interference.

## Section by section

**Section 1 — the shift, as a permutation.** |0,x⟩ → |0,x+1⟩, |1,x⟩ → |1,x−1⟩ (mod 16 sites),
built by hand and checked as a genuine permutation (S†S = I).

**Section 2 — one step.** Coin flip (`H`) then conditional shift; the position marginal is
read off by summing over the coin.

**Section 3 — ballistic vs. diffusive spreading.** The quantum walk's position standard
deviation grows roughly linearly in t; the classical random walk's grows as √t exactly, at
every single t tested. Along the way, the page calls out a genuine gotcha: computing spread
from raw *site indices* is wrong once the distribution nears the cycle's wraparound boundary,
because index 15 is actually adjacent to index 0 — the fix is to unwrap each index to a signed
offset from the start before computing variance.

**Section 4 — the asymmetry is interference, not a bug.** Starting from coin `|0⟩` gives a
visibly lopsided distribution; starting from `|+i⟩` (an existing Core basis ket) restores
left-right symmetry exactly, showing the bias comes from the coin's phase relationship to the
shift.

**Section 5 — cross-references.** Grover's search (page 11) can be recast as a walk; the
continuous-time walk is `expm` (page 21) applied to a graph's adjacency matrix.

**Section 6 — live view.** The two final (t=7) position distributions plotted together.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`22Walk`** (or follow `[Next]` from
   `21Trotter`).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. This page has a SwiftUI live view (`CHSHChartView`). On Xcode 27 betas, re-copy the
   `libcups` shim immediately before running (`PLAYGROUNDSUPPORT.md`
   § "Xcode 27 beta workarounds").
4. Run the page. Every number is exact — no measurement/shot sampling is used anywhere on
   this page, only exact amplitudes.

## Expected output

```text
S†S = I max diff: 0.00e+00

t   quantum σ   σ/t
1   1.0000      1.0000
2   1.4142      0.7071
3   1.6583      0.5528
4   2.0000      0.5000
5   2.5951      0.5190
6   3.1125      0.5187
7   3.4500      0.4929

t   classical σ   σ/√t
1   1.0000       1.0000
2   1.4142       1.0000
3   1.7321       1.0000
4   2.0000       1.0000
5   2.2361       1.0000
6   2.4495       1.0000
7   2.6458       1.0000

site   P(biased, coin=|0⟩)   P(symmetric, coin=|+i⟩)
1      0.1328                 0.1016
3      0.3203                 0.1797
5      0.2891                 0.2109
7      0.0078                 0.0078
9      0.0078                 0.0078
11      0.1328                 0.2109
13      0.0391                 0.1797
15      0.0703                 0.1016
```

Note the quantum `σ/t` column oscillates rather than settling smoothly — a known finite-size
and parity effect in small coined quantum walks, not an error. The classical `σ/√t` column is
pinned at exactly 1.0 at every t: the textbook diffusive signature.

## The live view

`CHSHChartView` plots the classical (blue) and quantum-with-|0⟩-coin (orange) position
distributions at t=7 side by side, both as scatter series against a signed site offset from
the start — visibly wider and two-peaked for the quantum case, single-humped for the classical
one.

## Using it in your own code

```swift
import SwiftQiskitCore

let numSites = 16
let dim = 32   // coin (2) × position (16)

func buildShift() -> Matrix {
    var m = Matrix(rows: dim, cols: dim)
    for coin in 0...1 {
        for pos in 0..<numSites {
            let newPos = coin == 0 ? (pos + 1) % numSites : (pos - 1 + numSites) % numSites
            m[coin * numSites + newPos, coin * numSites + pos] = .one
        }
    }
    return m
}

let U = buildShift() * HadamardGate.matrix.tensor(Matrix.identity(size: numSites))
// Apply U repeatedly to a coin ⊗ position state to run the walk.
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first.
- **`Failed to load linked library cups`** — the Xcode 27 beta evaluator bug; re-copy the
  shim (`PLAYGROUNDSUPPORT.md`).
- **Standard deviation looks non-monotonic or wildly wrong** — this is the cyclic-coordinate
  bug Section 3 calls out: raw site indices near the 0/15 boundary aren't "far apart" on a
  cycle. Make sure variance is computed from the *signed offset* (`pos <= numSites/2 ? pos :
  pos - numSites`), not the raw index.
- **Distribution looks wrong past t=7 (extending this page)** — 16 sites keeps t=7 clean
  (2·7+1 = 15 ≤ 16 distinct reachable sites); go further and the walk's two tails start to
  alias around the cycle, which needs more sites, not a code fix.
