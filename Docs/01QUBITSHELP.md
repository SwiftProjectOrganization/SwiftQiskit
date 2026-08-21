# First look at qubits — help & usage guide

User-facing guide to the `01Qubits` playground page — the first page after the table of
contents, and the playground's introduction to the Dirac-notation API
(`Sources/SwiftQiskitCore/Quantum/Dirac.swift`, `Quantum/StateVector.swift`). As with
`02Bloch2d`/`08BraKet` there is no separate design/plan document; the page, its doc
comments, `Circuit/QuantumCircuit.swift`, `Gates/Phase.swift`, and the shared
`Playgrounds.playground/Sources/BlochVector.swift` are the reference.

## What the page shows

**This page has no `print` statements.** Every result — kets, bras, products,
probabilities — is a bare expression, so Xcode shows its value only in the playground's
results sidebar (or via Quick Look: click the eye icon that appears in the sidebar next
to a line, or the "Show Result" inline bubble). There is no console output to read; if
you're looking at the console for output, the page is working, you're just looking in
the wrong pane.

The page has four parts:

1. **Single-qubit examples** — two named Dirac states, `q0 = .zero`, `q1 = .plusI`.
2. **Multi-qubit creation examples** — `sv0`/`sv1` built from binary labels, and `sv2`
   built by tensoring four single-qubit kets together with `⊗`.
3. **Two example circuits** (`circuit1`, `circuit2`) whose intermediate states are turned
   into `BlochVector`s at every stage and shown live at the bottom of the page.
4. **Bra/Ket operations** — `†`, inner and outer products, `⊗`, and a Bra–Matrix product,
   exercised on two states, `ket0` and `ket1`.

## The page's sections

| Section | What it shows |
|---|---|
| 1 — Single-qubit examples | `q0 = Ket.zero` (\|0⟩), `q1 = Ket.plusI` (\|i⟩) — sidebar only, no further use |
| 2 — Multi-qubit creation | `sv0 = Ket("000")`, `sv1 = Ket("010")` from binary labels; `sv2: StateVector = .zero ⊗ .plusI ⊗ .zero ⊗ .zero` — see below |
| 3 — `circuit1` stages | `QuantumCircuit(qubits: 1)` → `h(0)` → `p(1.571, 0)` → `p(3.142, 0)`, each stage's `BlochVector` appended to `stages1` |
| 4 — `circuit2` stages | `QuantumCircuit(qubits: 1)` → `h(0)` → `z(0)` → `h(0)`, each stage's `BlochVector` appended to `stages2`, with `.probabilities` printed to the sidebar between steps |
| 5 — Bra/Ket operations | `ket0` (built from unnormalized amplitudes), `ket1` (the same ψ used in `08DIRACHELP.md`), their bras, inner/outer products, `⊗`, double-dagger, and a `Bra * Matrix.identity` check |
| 6 — Live view | `CircuitStagesView` (an inline, stateless `View`) rendering both stage sequences as two labeled `BlochSphereView` grids |

**`sv2` combines four single-qubit kets into one multi-qubit register via `⊗`.**
`let sv2: StateVector = .zero ⊗ .plusI ⊗ .zero ⊗ .zero` chains three tensor products
(`⊗` is `MultiplicationPrecedence`, so it's left-associative:
`((.zero ⊗ .plusI) ⊗ .zero) ⊗ .zero`) into a single 4-qubit, 16-dimensional
`StateVector` — like `sv0`/`sv1`, a genuine combined register, but built from separate
kets instead of a binary label. Because one of those kets (`.plusI`) is itself in
superposition, so is the result: see the amplitudes below.

`circuit1` and `circuit2` are the two circuits CLAUDE.md's page description calls the
"plusCircuit" and "minusCircuit" (named for the state they pass through mid-circuit); the
page code itself just calls them `circuit1`/`circuit2`.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`01Qubits`** page (or follow
   the `[Next]` link from `00TOC` / `[Previous]` from `02Bloch2d`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. Nothing appears in the console; open the results sidebar (or the
   Assistant editor's live view area) to see the values and the Bloch-sphere grids.

This page **imports SwiftUI and shows a live view**, so the Xcode 27 beta evaluator bugs
apply — if the page fails to run or the live view stays blank, see `PLAYGROUNDSUPPORT.md`
§ "Xcode 27 beta workarounds".

## Expected results

Sidebar values (verified against the library; up to floating-point rounding):

**Section 1 — single-qubit examples**

| Expression | Amplitudes | Probabilities |
|---|---|---|
| `q0 = .zero` | `[1.0, 0.0]` | `[1.0, 0.0]` |
| `q1 = .plusI` | `[0.7071067811865475, 0.7071067811865475i]` | `[0.5, 0.5]` |

**Section 2 — multi-qubit creation**

- `sv0 = Ket("000")` → the 8-dim basis state \|000⟩ (amplitude 1 at index 0, 0 elsewhere).
- `sv1 = Ket("010")` → \|010⟩ (amplitude 1 at index 2 — binary `"010"` = 2).
- `sv2 = .zero ⊗ .plusI ⊗ .zero ⊗ .zero` → a 4-qubit, 16-dimensional `StateVector`:
  amplitude `0.7071067811865475` at \|0000⟩ (index 0) and `0.7071067811865475i` at
  \|0100⟩ (index 4), all other amplitudes `0` — probabilities `0.5` at each of those two
  indices, `0` elsewhere.

**Section 3 — `circuit1` stages (Bloch coordinates x, y, z)**

| Stage | x | y | z |
|---|---|---|---|
| \|0⟩ | 0.0000 | 0.0000 | 1.0000 |
| H → \|+⟩ | 1.0000 | 0.0000 | 0.0000 |
| P(1.571) → \|+i⟩ | −0.0002 | 1.0000 | 0.0000 |
| P(3.142) → \|−i⟩ | 0.0006 | −1.0000 | 0.0000 |

Final `circuit1.run().probabilities` = `[0.5, 0.5]` (both entries `0.4999999999999999`).

**Section 4 — `circuit2` stages (Bloch coordinates and probabilities)**

| Stage | x | y | z | probabilities |
|---|---|---|---|---|
| \|0⟩ | 0.0000 | 0.0000 | 1.0000 | `[1.0, 0.0]` |
| H → \|+⟩ | 1.0000 | 0.0000 | 0.0000 | `[0.5, 0.5]` |
| Z → \|−⟩ | −1.0000 | 0.0000 | 0.0000 | `[0.5, 0.5]` |
| H → \|1⟩ | 0.0000 | 0.0000 | −1.0000 | `[0.0, 1.0]` (`0.9999999999999996`) |

**Section 5 — Bra/Ket operations**

| Expression | Value |
|---|---|
| `ket0.amplitudes` | `[0.7071067811865475, 0.7071067811865475]` |
| `bra0 * ket0` | `0.9999999999999998` |
| `ket1.amplitudes` | `[0.8660254037844387, 0.35355339059327373 + 0.3535533905932737i]` |
| `ket1.probabilities` | `[0.7500000000000001, 0.24999999999999992]` |
| `bra1 * ket1` | `1.0` |
| `ket1.dimension.magnitude` | `2` |
| `ket1 ⊗ ket1` (probabilities) | `[0.5625, 0.1875, 0.1875, 0.0625]` |
| `(ket1†)†` | exactly `ket1` |
| `ket1 * ket1†` | `[[0.75, 0.306186… − 0.306186…i], [0.306186… + 0.306186…i, 0.25]]` |
| `ket1† * Matrix.identity(size: 2)` | exactly `ket1†` |

Reading notes:

- **The `P(1.571)`/`P(3.142)` stages are not exactly \|+i⟩/\|−i⟩.** The page passes the
  literal decimals `1.571` and `3.142` — 3-decimal truncations of π/2 ≈ 1.5707963 and
  π ≈ 3.1415927 — rather than `.pi / 2` / `.pi`. That leaves a genuine (if small) x-axis
  offset of about −2×10⁻⁴ and +6×10⁻⁴ in the two stages' Bloch vectors, much larger than
  the ~10⁻¹⁶ double-precision rounding seen elsewhere in the library. It is invisible at
  three decimals in the y/z coordinates but shows up in x, which "should" be exactly 0.
- **`bra0 * ket0` is `0.9999999999999998`, not exactly `1.0`, while `bra1 * ket1` is
  exactly `1.0`.** `ket0` starts from the unnormalized amplitudes `(0.5, 0.5)`, so its
  initializer *rescales* them (dividing by `√0.5`), which injects ~10⁻¹⁶ of rounding.
  `ket1`'s amplitudes already satisfy Σ|αᵢ|² ≈ 1, so `normalize()` skips rescaling
  entirely (per the guard in `StateVector.normalize()`) and the inner product with itself
  is exact — the same reasoning `08DIRACHELP.md` uses for the exact double-dagger.
- **`ket1 ⊗ ket1`'s probabilities are ket1's own probabilities squared pairwise**:
  0.75² = 0.5625, 0.75·0.25 = 0.1875 (twice), 0.25² = 0.0625 — because tensoring a state
  with itself makes two independent copies of the same 1-qubit distribution.
- **`ket1 * ket1†` is the density-matrix-style projector \|ψ⟩⟨ψ\|** — Hermitian, trace 1
  (0.75 + 0.25), with the off-diagonal entries complex conjugates of each other.

## Reading the live view

`CircuitStagesView` renders two titled sections, `"circuit1"` and `"circuit2"`, each a
2-column `LazyVGrid` of `BlochSphereView`s — one per stage recorded in `stages1`/
`stages2`. Both circuits start at the same \|0⟩ pole and diverge after `h(0)`: `circuit1`
continues around the equator via two phase-gate nudges (ending near \|−i⟩), while
`circuit2` bounces from \|+⟩ to \|−⟩ (via `z(0)`) and back down to the \|1⟩ pole
(via a second `h(0)`). For how to read an individual sphere (axes, projection,
foreshortening), see `02BLOCH2DHELP.md` § "Reading the drawing" — this page reuses the
same `BlochSphereView` with no changes.

The root view is sized `560 × 1340` — two sections of four 260-point cells (2×2 grid)
plus section titles and padding, the widest content this early in the playground.

## Using it in your own code

Everything on this page except the live view is plain `SwiftQiskitCore` API:

```swift
import SwiftQiskitCore

// Named single-qubit states
let plusI: Ket = .plusI                     // (|0⟩ + i|1⟩)/√2

// Basis states from binary labels (qubit 0 = most-significant bit)
let ghz0 = Ket("000")

// Track a circuit's Bloch trajectory stage by stage
let qc = QuantumCircuit(qubits: 1)
var trail: [StateVector] = [qc.run()]
qc.h(0)
trail.append(qc.run())
qc.p(.pi / 2, 0)                            // use .pi, not a decimal literal, for an exact |i⟩
trail.append(qc.run())

// Bra/Ket algebra
let psi = Ket([Complex(0.6), Complex(0.8)])
let overlap = psi† * psi                    // ⟨ψ|ψ⟩ ≈ 1.0
let projector = psi * psi†                  // |ψ⟩⟨ψ| — a Matrix
let doubled = psi ⊗ psi                     // |ψ⟩ ⊗ |ψ⟩ — a 4-dim StateVector
```

## Troubleshooting

- **Nothing prints when the page runs** — expected; this page has no `print` calls.
  Check the results sidebar (or Quick Look on individual lines), not the console.
- **Page won't run / no results at all** — the SwiftQiskit scheme must build first;
  check for compile errors in `Sources/SwiftQiskitCore/`.
- **`Failed to load linked library cups of module SwiftUI`** — the Xcode 27 beta libcups
  bug; install the shim per `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (a clean
  build deletes it — rerun the copies).
- **Live view blank, collapsed, or clipped** — the root view passed to `setLiveView`
  needs an explicit `.frame(width:height:)`; this page's `CircuitStagesView` already has
  one (`560 × 1340`) — if it looks wrong, check for edits to that frame or to `stages1`/
  `stages2`.
- **A Bloch coordinate is slightly off from the "textbook" value** — check whether the
  triggering gate used a decimal literal like `1.571` instead of `.pi / 2`; see the
  reading note above.
- **`Cannot find 'BlochVector'/'BlochSphereView' in scope`** — the `Sources/` declaration
  (or its `init`) isn't `public`, or the file isn't in the playground's top-level
  `Sources/` folder.