# Basis transformations — help & usage guide

User-facing guide to the `41BasisTransformations` playground page. Unlike its neighbor
`40ComplexAndMatrices`, this page is standalone — it doesn't follow a chapter of the
SwiftQiskitApp `INTRODUCTION.md` book. It builds on the Dirac-notation API introduced in
`01Qubits` (`Sources/SwiftQiskit/Quantum/Dirac.swift`) and the `Matrix` type
(`Math/Matrix.swift`); no Core library changes were needed.

## What the page shows

Every other page reads amplitudes off in the computational (Z) basis {|0⟩, |1⟩}. This page
asks the reverse question: given a state's amplitudes in that basis, how do you find its
coordinates in a *different* basis — and, mechanically, what matrix does that?

The construction, in order:

1. Stack the new basis kets as the **columns** of a matrix `T`. Then `|ψ⟩ = T·c`, where `c`
   is the vector of coordinates in the new basis.
2. `T` is unitary (its columns are orthonormal), so its inverse is its conjugate transpose:
   `c = T⁻¹|ψ⟩ = T†|ψ⟩`.
3. The **rows** of `T†` are exactly the bras of the new basis, so each new amplitude is an
   inner product: `cⱼ = ⟨bⱼ|ψ⟩`.
4. A second, complex basis ({|+i⟩, |−i⟩}) demonstrates that a *plain* transpose is not
   enough — the conjugate is essential — by giving a visibly wrong answer for `|+i⟩`.
5. Finally, `T†` turns out to be exactly the gate circuit needed to measure a qubit "in the
   new basis": apply `T†`'s corresponding gate(s), then measure as usual.

This page has **no live view**; every result is printed to the console (unlike `01Qubits`'s
results-sidebar style).

## The page's sections

| Section | What it shows |
|---|---|
| §1 | States the problem: `psi = .zero`; want `c₊`, `c₋` with `ψ = c₊|+⟩ + c₋|−⟩` |
| §2 | Builds `T` column by column from `Ket.plus`/`Ket.minus`'s amplitudes |
| §3 | Builds `Tdag` by hand as `Matrix([Bra(Ket.plus).amplitudes, Bra(Ket.minus).amplitudes])`; checks it against `T.adjoint` and a hand-rolled `plainTranspose(_:)` (both match here) |
| §4 | Computes `c = Tdag.multiply(by: psi.amplitudes)`; confirms `c[j]` equals `⟨bⱼ\|ψ⟩` directly; prints probabilities; repeats for `ket1` (the general state from `01QUBITSHELP.md`) |
| §5 | `Tdag * T ≈ I` (unitarity); `Tdag == HadamardGate.matrix` (the ± change of basis *is* H); a round trip `T·(T†ψ) = ψ` |
| §6 | The {\|+i⟩, \|−i⟩} basis: `TiDag` (hand-built rows of bras) still matches `Ti.adjoint`, but now **differs** from a plain transpose; applying each to `.zero` and `.plusI` shows the plain transpose gives wrong probabilities for `.plusI`, and fails the `* Ti = I` unitarity check |
| §7 | Measuring in the new basis: `h(0)` alone for ± (since `T† = H`); `sdg(0)` then `h(0)` for ±i (since that combined matrix `H * Sdg` equals `TiDag`); shot counts via `measure(shots:)` |

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`41BasisTransformations`** page
   (or follow `[Next]` from `40ComplexAndMatrices` on the table of contents).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. Run the page and read the console — there is no results-sidebar-only content and no live
   view, so this page is unaffected by the Xcode 27 beta SwiftUI evaluator bugs.

## Expected results

Verified against the library (up to floating-point rounding); shot counts are statistical.

**§2–§3 — building T and T†**

| Expression | Value |
|---|---|
| `T` | `[[0.7071067811865475, 0.7071067811865475], [0.7071067811865475, −0.7071067811865475]]` |
| `Tdag == T.adjoint` | `true` |
| `Tdag == plainTranspose(T)` | `true` (the ± basis is real, so transpose and conjugate transpose coincide) |

**§4 — new amplitudes**

| Expression | Value |
|---|---|
| `c` (for `psi = .zero`) | `[0.7071067811865475, 0.7071067811865475]` |
| `Ket.plus† * psi`, `Ket.minus† * psi` | same two values — confirms `c[j] = ⟨bⱼ\|ψ⟩` |
| `c.map { $0.magnitudeSquared }` | `[0.4999999999999999, 0.4999999999999999]` |
| `c1` (for `ket1`) | `[0.8623724356957945+0.25i, 0.3623724356957945−0.25i]` |
| `c1` probabilities | `[0.8061862178478971, 0.1938137821521027]` (vs. `ket1`'s own Z-basis `[0.75, 0.25]`) |

**§5 — unitarity and round trip**

| Expression | Value |
|---|---|
| `Tdag * T` | `≈ [[1, 0], [0, 1]]` (each entry within ~2e-16 of the identity) |
| `Tdag == HadamardGate.matrix` | `true` |
| `rebuilt = T.multiply(by: c)` | `[0.9999999999999998, 0.0]` — back to `.zero` |

**§6 — plain transpose vs. conjugate transpose ({|+i⟩, |−i⟩})**

| Expression | Value |
|---|---|
| `TiDag == Ti.adjoint` | `true` |
| `TiDag == TiTransposeOnly` | `false` |
| `.zero`, plain transpose | `[0.7071067811865475, 0.7071067811865475]`, probs `[0.5, 0.5]` |
| `.zero`, conjugate transpose | identical — `.zero`'s amplitudes are real, so it can't tell the two apart |
| `.plusI`, plain transpose | `[0.0, 0.9999999999999998]`, probs `[0.0, 0.9999999999999996]` — **wrong**: reports `|+i⟩` as if it were `|−i⟩` |
| `.plusI`, conjugate transpose | `[0.9999999999999998, 0.0]`, probs `[0.9999999999999996, 0.0]` — correct |
| `TiTransposeOnly * Ti` | not the identity (fails unitarity) |
| `TiDag * Ti` | `≈` identity |

**§7 — measuring in the new basis (1000 shots each)**

| Circuit | Counts |
|---|---|
| `.zero` then `h(0)`, measure | `["0": 485, "1": 515]` |
| `.plus` then a second `h(0)`, measure | `["0": 1000]` |
| `.zero` then `sdg(0); h(0)`, measure | `["0": 497, "1": 503]` |
| `.plusI` then `sdg(0); h(0)`, measure | `["0": 1000]` |

Exact shot counts will vary run to run — only the ≈50/50 vs. deterministic pattern is the
point.

## Reading notes

- **Why the rows of `T†` are bras, not just "the transpose of the columns."** `T`'s columns
  are the new basis *kets*. Conjugate-transposing turns each column into a row and
  conjugates every entry — which is exactly the definition of a bra (`Bra.init(_:)` does the
  same conjugation). So row `j` of `T†` literally *is* `⟨bⱼ|`, and `(T†ψ)[j] = ⟨bⱼ|ψ⟩` falls
  straight out of ordinary matrix-vector multiplication.
- **Why {|+⟩, |−⟩} doesn't distinguish transpose from conjugate transpose, but {|+i⟩, |−i⟩}
  does.** Conjugation only changes anything on entries with a nonzero imaginary part. `|+⟩`
  and `|−⟩` have entirely real amplitudes (`±1/√2`), so `Tᵀ = T†` for that basis. `|+i⟩` and
  `|−i⟩` have genuinely imaginary entries (`±i/√2`), so their `Tᵀ` and `T†` differ in the
  sign of those entries — and only `T†` is unitary's actual inverse.
- **`Tdag == HadamardGate.matrix` being `true` (not approximately equal) is not a
  coincidence of this page** — `H`'s own matrix entries are the same `Double` literal
  `1/√2` computed the same way `Ket.plus`/`Ket.minus`'s amplitudes are, so both routes reach
  bit-identical values. See `40ComplexAndMatrices`'s unitarity section for a case (`H†H`)
  where similarly-constructed values do *not* come out bit-identical.
- **The gate order for the ±i measurement is `sdg(0)` then `h(0)`, not `h(0)` then
  `sdg(0)`.** `QuantumCircuit` applies gates in placement order, and placing `sdg` before
  `h` composes to the matrix product `H * Sdg` (apply `Sdg` first, then `H`) — and that
  product is exactly `TiDag`, checked directly on the page. Reversing the order gives a
  different (wrong) matrix; see `40ComplexAndMatrices`'s §2.8 for the general "apply A then
  B is B * A, not A * B" rule.

## Using it in your own code

```swift
import SwiftQiskit

// Build the change-of-basis matrix for any two orthonormal kets, columns first...
let T = Matrix((0..<2).map { row in [Ket.plus[row], Ket.minus[row]] })

// ...and its inverse is the conjugate transpose — rows of bras.
let Tdag = Matrix([Bra(Ket.plus).amplitudes, Bra(Ket.minus).amplitudes])
// or equivalently: let Tdag = T.adjoint

// New-basis amplitudes and probabilities, straight from T†:
let psi: Ket = .zero
let c = Tdag.multiply(by: psi.amplitudes)
let probabilities = c.map { $0.magnitudeSquared }

// Measuring "in the new basis" on real hardware/the simulator: apply the gate(s) whose
// combined matrix equals T†, then measure normally.
let qc = QuantumCircuit(qubits: 1)
qc.h(0)                       // T† for the ± basis
let counts = qc.measure(shots: 1000).counts
```

## Troubleshooting

- **Nothing prints when the page runs** — check you're looking at the console, not the
  results sidebar; every result on this page goes through `print(...)`.
- **A probability or matrix entry looks "off" by ~1e-16** — ordinary `Double` rounding, the
  same kind seen throughout the playground (see `01QUBITSHELP.md`'s reading notes and
  `40ComplexAndMatrices`'s §2.9 for why exact `==` on floating-point unitary matrices can be
  misleading).
- **Shot counts don't match the table above exactly** — expected; `measure(shots:)` is
  probabilistic. Only the pattern (≈50/50 vs. all-one-outcome) is guaranteed.
