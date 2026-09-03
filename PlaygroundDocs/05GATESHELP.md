# Gates, one at a time — help & usage guide

User-facing guide to the `05Gates` playground page — a gentle, gate-by-gate tour of every
built-in gate in `Sources/SwiftQiskitCore/Gates/` and `Circuit/QuantumCircuit.swift`'s
fluent API (`h/x/y/z/s/sdg/t/tdg/p/rx/ry/rz/cx`). It's the playground's first use of
`QuantumCircuit` itself — earlier pages either worked with raw `Ket`/`StateVector`
(`01Qubits`) or were Bloch-sphere live views (`02`–`04`). As with `01Qubits`/`02Bloch2d`
there is no separate design/plan document; the page and `AdditionalGatesTests.swift` are
the reference.

## What the page shows

**This page has no `print` statements**, like `01Qubits`. Every result — amplitudes,
probabilities, measurement counts — is a bare trailing expression, so Xcode shows its value
only in the results sidebar (or via Quick Look). There is no console output to read, and
**no live view** either — unlike `01Qubits`/`04Bloch3d`, this page has nothing to do with
Bloch spheres; it's purely about the gate API. If you're looking at the console or waiting
for a graphic, the page is working, you're just looking in the wrong (or a nonexistent) pane.

The page runs ten short sections, each on a fresh 1-qubit `QuantumCircuit` (except the
last, which is 2-qubit):

| Section | Gate(s) | What it shows |
|---|---|---|
| 1 | *(none)* | a circuit starts at \|0⟩ until you record gates on it |
| 2 | `x` | bit flip: \|0⟩ → \|1⟩ |
| 3 | `h` | superposition: \|0⟩ → (\|0⟩ + \|1⟩)/√2 |
| 4 | `z` | phase flip — invisible on \|0⟩ alone, invisible on \|+⟩'s probabilities, but flips the bit once a second `h` lets the two paths interfere |
| 5 | `y` | bit flip *and* phase flip together — same probabilities as `x`, different amplitude |
| 6 | `s` / `sdg` | quarter turns around the equator: \|+⟩ → \|+i⟩ / \|-i⟩ |
| 7 | `t` (×2) | eighth turns: two `t`'s equal one `s` |
| 8 | `p(theta:)` | the general phase gate — `p(.pi/2)` ≡ `s`, `p(.pi/4)` ≡ `t`, `p(.pi)` ≡ `z` |
| 9 | `rx` / `ry` / `rz` | continuous rotations — `ry(.pi/2)` lands on the same state as `h`; `rx(.pi/2)` measured half-and-half; `rz` matches `p`'s probabilities but not its raw amplitudes |
| 10 | `h` + `cx` | two qubits, one peek ahead: the Bell state — the full walkthrough (plus GHZ) is `07Entanglement` |

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`05Gates`** page (or follow the
   `[Next]` link from `04Bloch3d` / `[Previous]` from `06Superposition`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. Nothing appears in the console; open the results sidebar (or Quick Look
   individual lines) to see each section's values.

This page is **console/sidebar-only — no SwiftUI, no live view** — so the Xcode 27 beta
evaluator bugs described in `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (the
`libcups.dylib` shim and the `@State` macro issue) do not apply here.

## Expected results

Sidebar values (verified against `Gates/PauliY.swift`, `Gates/Phase.swift`,
`Gates/Rotation.swift`, and `Tests/SwiftQiskitCoreTests/AdditionalGatesTests.swift`; up to
floating-point rounding):

| Section | Expression | Value |
|---|---|---|
| 1 | `qcIdentity.run().probabilities` | `[1.0, 0.0]` |
| 2 | `stateX.amplitudes` | `[0, 1]` |
| 2 | `stateX.probabilities` | `[0.0, 1.0]` |
| 3 | `stateH.amplitudes` | `[0.7071067811865475, 0.7071067811865475]` |
| 3 | `stateH.probabilities` | `[0.5, 0.5]` |
| 4 | `qcZAlone.run().probabilities` | `[1.0, 0.0]` |
| 4 | `stateHZ.amplitudes` | `[0.7071067811865475, -0.7071067811865475]` |
| 4 | `stateHZ.probabilities` | `[0.5, 0.5]` |
| 4 | `qcHZH.run().probabilities` | `[0.0, 1.0]` |
| 5 | `stateY.amplitudes` | `[0, i]` |
| 5 | `stateY.probabilities` | `[0.0, 1.0]` |
| 6 | `qcS.run().amplitudes` | `[0.7071067811865475, 0.7071067811865475i]` (`Ket.plusI`) |
| 6 | `qcSdg.run().amplitudes` | `[0.7071067811865475, -0.7071067811865475i]` (`Ket.minusI`) |
| 7 | `qcTT.run().amplitudes` | matches `qcS.run().amplitudes` to ~1e-16 |
| 8 | `qcPHalfPi.run().amplitudes` | matches `qcS.run().amplitudes` to ~1e-17 (`P(π/2) == S`) |
| 8 | `qcPQuarterPi.run().amplitudes` | `[0.7071067811865475, 0.5 + 0.5i]` — a single `T` (`P(π/4) == T`); **not** the same as `qcTT`, which is `T²` (= `S`) |
| 8 | `qcPPi.run().amplitudes` | matches `stateHZ.amplitudes` to ~1e-17 (`P(π) == Z`) |
| 9 | `qcRY.run().amplitudes` | `[0.7071067811865476, 0.7071067811865476]` |
| 9 | `qcRX.measure(shots: 1000)` | roughly half `"0"`, half `"1"` (statistical) |
| 9 | `qcRZ.run().probabilities` | `[0.5, 0.5]` (same as `qcPHalfPi`, different amplitudes) |
| 10 | `qcBell.run().probabilities` | `[0.5, 0.0, 0.0, 0.5]` |

Reading notes:

- **Section 4 is the page's main lesson.** `z` alone on \|0⟩ does nothing observable
  (`[1.0, 0.0]`), and `h; z` on \|0⟩ still measures 50/50 — the phase flip is real (the
  amplitudes' signs differ) but probabilities only depend on magnitude, so it's invisible
  until a second `h` lets the two now-out-of-phase branches interfere. That interference is
  what turns the hidden phase into the observable bit flip in `qcHZH` — the same construction
  as `circuit2` in `01Qubits`.
- **Section 5 pairs with Section 2.** `y` and `x` both send \|0⟩ to a state with
  probabilities `[0.0, 1.0]`, but `y`'s amplitude is `i`, not `1` — `Y = iXZ`, so it's X and Z
  (a bit flip and a phase flip) applied together.
- **Section 7's identity is exact as matrix algebra, not bit-for-bit in floating point** —
  `t` applied twice is `T² = P(π/4)² = P(π/2) = S`; the two circuits' amplitudes agree to
  about 1e-16 (well within the `1e-10` tolerance `AdditionalGatesTests` uses for the same
  identity), not exactly, because the two paths accumulate rounding differently. Don't
  confuse `qcTT` (`T²`, Section 7) with `qcPQuarterPi` (a single `T`, Section 8) — the two
  are different values.
- **Section 9's `qcRY` looks identical to Section 3's `stateH`** — both are
  `[1/√2, 1/√2]` — but they're reached differently: `h` is a fixed Hadamard reflection,
  `ry(theta:)` is a continuous rotation about the Y axis, and `.pi/2` happens to land on the
  same point `h` does. `qcRZ`'s probabilities match `qcPHalfPi`'s because `RZ(θ)` and `P(θ)`
  are the same gate up to a global phase factor `e^{-iθ/2}` (invisible to probabilities,
  visible only in the raw amplitudes) — see the doc comment in `Gates/Rotation.swift`.
- **Section 10 is a teaser, not the full story.** It's the same Bell-state recipe this page
  used to open with; `07Entanglement` covers it (and a 3-qubit GHZ state) with full
  amplitude/measurement annotation.

## Using it in your own code

Every gate here is a plain `QuantumCircuit` method — no need to touch the underlying
`Matrix`/`Complex` types unless you're building a custom gate, as `09Tensor` (H ⊗ I₂ built
by hand) and `11GroverExample` § 8 (a hand-built CCZ applied via `apply(_:)`) do:

```swift
import SwiftQiskitCore

let qc = QuantumCircuit(qubits: 1)
qc.h(0)                  // superposition
qc.p(.pi / 2, 0)         // a phase gate — same as qc.s(0)
let state = qc.run()
state.amplitudes         // [1/√2, (1/√2)i] — |+i⟩

let qc2 = QuantumCircuit(qubits: 1)
qc2.rx(.pi / 2, 0)       // a continuous rotation, not a fixed gate
let counts = qc2.measure(shots: 1000)   // SimulationResult — roughly half-and-half
```

## Troubleshooting

- **Nothing prints when the page runs** — expected; this page has no `print` calls. Check
  the results sidebar (or Quick Look on individual lines), not the console.
- **Page won't run / no results at all** — the SwiftQiskit scheme must build first; check
  for compile errors in `Sources/SwiftQiskitCore/`.
- **A "match" section (7, 8) looks off by a sign or a tiny fraction** — check you're
  comparing `.amplitudes`, not `.probabilities`; the global-phase differences noted above
  (Section 9) are invisible in probabilities but visible in raw amplitudes.
- **`qcRX.measure(shots: 1000)` isn't exactly 500/500** — expected; measurement is
  probabilistic. Re-run the page or increase `shots` if you want a tighter distribution.
