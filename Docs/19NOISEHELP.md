# Noise (open systems and decoherence) — help & usage guide

User-facing guide to the `19Noise` playground page. The implementation plan is in
`19NOISEPLAN.md`.

## What the page shows

Every earlier page assumed a perfect, isolated, *pure* state — even page 14 modeled errors as
a discrete, coherent `rx(θ)` rotation, not decoherence. This page introduces the density
matrix ρ, the object that makes mixtures, noise, and reduced states of entangled systems
expressible, and shows how to add noise to a state-vector simulator without ever adding a
`DensityMatrix` type to Core.

## Section by section

**Section 1 — ρ, and a mixture vs. a superposition.** ρ = |ψ⟩⟨ψ| reuses the existing outer
product. ½|0⟩⟨0| + ½|1⟩⟨1| (a coin flip between known states) and |+⟩⟨+| (a genuine
superposition) give identical Z-diagonals but different off-diagonals — coherence lives in the
off-diagonal, which a mixture simply doesn't have.

**Section 2 — Kraus channels.** ρ' = Σ Kᵢ ρ Kᵢ† for bit-flip, phase-flip, depolarizing, and
amplitude damping, each checked for trace preservation (Σ Kᵢ†Kᵢ = I) before being trusted.

**Section 3 — coherence decay.** Repeated phase-flip(p) decays the off-diagonal exactly as
(1−2p)ⁿ, checked against the closed form. A single full depolarizing round lands on the
maximally mixed state, diag(0.5, 0.5).

**Section 4 — amplitude damping.** Unlike dephasing, this also moves the Bloch vector's
z-coordinate toward the |0⟩ pole while x, y shrink — landing strictly *inside* the sphere,
a picture no pure state can draw.

**Section 5 — Monte-Carlo unraveling.** The exact channel is reproduced from ordinary
pure-state code: per shot, flip a biased coin and apply the error gate or not, then measure.
This is the section that makes the page a programming example, not just linear algebra.

**Section 6 — entanglement through a reduced state.** Tracing out one qubit of a Bell pair
leaves the other mixed (purity 0.5, entropy exactly 1 bit) even though the full 2-qubit state
is pure — the explanation page 13's marginals were owed. A product-state control gives entropy
0.

**Section 7 — live view.** Three Bloch points side by side — pure |+⟩, its dephased image, and
the fully depolarized point at the sphere's center — using this page's additive
`BlochVector(x:y:z:)`.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`19Noise`** (or follow `[Next]` from
   `18VQE`).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. This page has a SwiftUI live view (`BlochSphereView`, in `Sources/`). On Xcode 27 betas,
   re-copy the `libcups` shim immediately before running (`PLAYGROUNDSUPPORT.md`
   § "Xcode 27 beta workarounds").
4. Run the page. Most output is exact (channels are deterministic given p); Section 5's
   Monte-Carlo estimate is statistical (± a couple of parts per thousand over 20,000 shots).

## Expected output

```text
ρ(|+⟩):        diag 0.500000, 0.500000   off-diag 0.4999999999999999
ρ(mixture):    diag 0.500000, 0.500000   off-diag 0.0
purity: |+⟩ = 1.000000,  mixture = 0.500000

ΣKᵢ†Kᵢ − I max residual, p = 0.3:
  bit-flip:      0.00e+00
  phase-flip:    0.00e+00
  depolarizing:  1.11e-16
  amp-damping:   0.00e+00

n    off-diag (measured)   (1-2p)ⁿ predicted   [p = 0.1]
1     0.400000              0.400000
5     0.163840              0.163840
10     0.053687              0.053687
20     0.005765              0.005765

fully depolarized (p=1) on |0⟩: diag 0.500000, 0.500000, purity 0.500000

|+⟩ after 20 rounds of amplitude damping (γ=0.2):
  Bloch (x,y,z) = (0.107374, 0.000000, 0.988471)
  purity = 0.994302

Monte-Carlo phase-flip(0.1) on |+⟩, 20000 shots: P(+x) = 0.900400  (statistical)
exact prediction (1+(1-2p))/2 = 0.900000

Bell pair |Φ⁺⟩: full-state purity = 1.000000
qubit 0's reduced state ρ_A: diag 0.500000, 0.500000, purity 0.500000, entropy 1.000000 bits
product state |+⟩⊗|0⟩: ρ_A entropy = 0.000000 bits
```

## The live view

Three `BlochSphereView`s: `pure |+⟩` on the equator, `dephased (10× p=0.1)` shrunk toward the
center along the same direction, and `fully depolarized` sitting exactly at the origin.

## Using it in your own code

```swift
import SwiftQiskitCore

func addM(_ a: Matrix, _ b: Matrix) -> Matrix {
    var r = Matrix(rows: a.rows, cols: a.cols)
    for i in 0..<a.rows { for j in 0..<a.cols { r[i, j] = a[i, j] + b[i, j] } }
    return r
}
func scaleM(_ a: Matrix, _ s: Double) -> Matrix {
    var r = Matrix(rows: a.rows, cols: a.cols)
    for i in 0..<a.rows { for j in 0..<a.cols { r[i, j] = a[i, j] * s } }
    return r
}
func rho(_ psi: Ket) -> Matrix { psi * (psi†) }

let I2 = Matrix.identity(size: 2)
func phaseFlipKraus(_ p: Double) -> [Matrix] {
    [scaleM(I2, (1 - p).squareRoot()), scaleM(PauliZGate.matrix, p.squareRoot())]
}
func applyChannel(_ ks: [Matrix], _ r: Matrix) -> Matrix {
    var out: Matrix? = nil
    for k in ks {
        let term = k * r * (k†)
        out = out == nil ? term : addM(out!, term)
    }
    return out!
}

var r = rho(Ket.plus)
r = applyChannel(phaseFlipKraus(0.1), r)   // one round of dephasing
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first.
- **`Failed to load linked library cups`** — the Xcode 27 beta evaluator bug; re-copy the
  shim (`PLAYGROUNDSUPPORT.md`).
- **Monte-Carlo estimate looks off by more than a percent or two** — it's statistical over
  20,000 shots; rerun the page, or increase the shot count in Section 5's call.
- **A channel's trace residual isn't ~0** — check the Kraus operators satisfy Σ Kᵢ†Kᵢ = I for
  the specific probability/coefficient convention used (the depolarizing channel here uses the
  `1 − ¾p` / `p/4` convention, not `1 − p` / `p/3`).
