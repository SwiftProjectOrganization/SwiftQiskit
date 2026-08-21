# Entanglement — help & usage guide

User-facing guide to the `07Entanglement` playground page — an annotated walkthrough that
builds the 2-qubit Bell state |Φ⁺⟩ via `h` + `cx`, inspects its amplitudes, probabilities,
and measurement counts, then extends the same recipe to a 3-qubit GHZ state using `cx`
across non-adjacent qubits. As with `05Gates`/`06Superposition` there is no separate
design/plan document — the page and `Tests/SwiftQiskitCoreTests/BellStateTests.swift` /
`CNOTTests.swift` are the reference.

## What the page shows

The page is **console-only** (like `06Superposition`, unlike the sidebar-only `05Gates`):

| Section | What it does | What it shows |
|---|---|---|
| 1 | `QuantumCircuit(qubits: 2)`, then `h(0)`, `cx(0, 1)` | builds \|Φ⁺⟩ = (\|00⟩ + \|11⟩) / √2 |
| 2 | print the `StateVector`, `.probabilities`, and individual amplitudes `bellState[0]`/`bellState[3]` | amplitudes ≈ 0.7071 at \|00⟩ and \|11⟩, 0 elsewhere; probabilities `[0.5, 0, 0, 0.5]` |
| 3 | `measure(shots: 1000)`, print `sortedCounts` with percentages | only `00` and `11` ever appear, roughly 50/50 |
| 4 | 3-qubit GHZ: `h(0)`, `cx(0, 1)` (prints the intermediate 2-entangled state), then `cx(0, 2)` — a **non-adjacent** pair, skipping qubit 1 | intermediate state \|000⟩/\|110⟩, final GHZ state \|000⟩/\|111⟩, probabilities, and a 1000-shot measurement |
| (finale, untitled) | rebuilds the Section-1 Bell circuit using `apply(CNOTGate.matrix)` instead of `.cx(0, 1)` | identical probabilities `[0.5, 0, 0, 0.5]` — the matrix form and the fluent `cx` API agree |

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`07Entanglement`** page
   (or follow the `[Next]` link from `06Superposition` / `[Previous]` from `08Dirac`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page and open the console — this page is **print-based**, like
   `06Superposition`, not sidebar-only like `05Gates`.

This page is **console-only — no SwiftUI, no live view** — so the Xcode 27 beta
evaluator bugs described in `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" do
not apply here.

## Expected output

One representative run's console output (verified against `Circuit/QuantumCircuit.swift`,
`Quantum/StateVector.swift`, `Gates/CNOT.swift`, and `Quantum/SimulationResult.swift`; up
to floating-point rounding and measurement statistics — the shot counts will differ
slightly on your own run):

```text
Bell state amplitudes:
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.0
|11⟩: 0.7071067811865475

Probabilities: [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
Amplitude |00⟩: 0.7071067811865475
Amplitude |11⟩: 0.7071067811865475

Measurement counts (1000 shots):
  |00⟩ : 498  (49.8%)
  |11⟩ : 502  (50.2%)

GHZ state amplitudes:
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.0
|11⟩: 0.0
|100⟩: 0.0
|101⟩: 0.0
|110⟩: 0.7071067811865475
|111⟩: 0.0

GHZ state amplitudes:
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.0
|11⟩: 0.0
|100⟩: 0.0
|101⟩: 0.0
|110⟩: 0.0
|111⟩: 0.7071067811865475

GHZ probabilities: [0.4999999999999999, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4999999999999999]

GHZ measurement counts (1000 shots):
  |000⟩ : 502
  |111⟩ : 498

Bell state via apply(CNOTGate.matrix) probabilities: [0.4999999999999999, 0.0, 0.0, 0.4999999999999999]
```

Reading notes:

- **Only `00`/`11` (and `000`/`111`) ever appear.** That is the defining signature of
  entanglement: measuring one qubit instantly determines the other(s), so `01`/`10` and
  every mixed GHZ outcome have exactly zero probability, not just low probability.
- **Probabilities print as `0.4999999999999999`, not `0.5`.** A single ±1/√2 amplitude
  squared leaves ~1e-16 of floating-point residue — the same rounding seen elsewhere in
  the library (e.g. `08Dirac`'s `H†H` check); tests compare with a tolerance, not `==`.
- **Raw `StateVector` printouts don't zero-pad labels.** `|10⟩` names basis index 2 in
  binary, not a zero-padded 2-qubit string — that's why the Bell section's four lines
  read `|0⟩ / |1⟩ / |10⟩ / |11⟩` rather than `|00⟩ / |01⟩ / |10⟩ / |11⟩`. Only
  `SimulationResult.sortedCounts` (Section 3's `measure` output) zero-pads, via
  `String.leftPadding` — which is why the "Amplitude |00⟩ / |11⟩" print lines in Section 2
  spell out the padded label explicitly instead of relying on the raw printout.
- **The GHZ section prints the state twice** — once after only `cx(0, 1)` (still just a
  2-qubit-entangled state riding on 3 qubits: `000`/`110`), and again after `cx(0, 2)`
  entangles the third qubit into `000`/`111`. Comparing the two printouts is the point:
  it shows the effect of each additional `cx` in isolation.
- **`cx(0, 2)` is a non-adjacent CNOT** — control qubit 0, target qubit 2, skipping over
  qubit 1 — built via `CNOTGate.matrix(qubits:control:target:)`'s general permutation
  construction, not a fixed 2-qubit matrix. `Tests/SwiftQiskitCoreTests/CNOTTests.swift`
  builds its own GHZ example with a different (adjacent) wiring, `cx(0, 1)` then
  `cx(1, 2)` — both reach the same |000⟩/|111⟩ state, just via different control/target
  pairs, so don't read the difference as one of them being wrong.
- **The finale only works because the circuit has exactly 2 qubits.** `apply(_:)`
  preconditions that the matrix is exactly 2ⁿ×2ⁿ for the circuit's qubit count
  (`QuantumCircuit.swift`), and `CNOTGate.matrix` is a fixed 4×4 — so `apply(CNOTGate.matrix)`
  is a drop-in replacement for `.cx(0, 1)` only on a 2-qubit circuit; it would trap on the
  3-qubit GHZ circuit.

## Using it in your own code

```swift
import SwiftQiskitCore

// Bell state
let qc = QuantumCircuit(qubits: 2)
qc.h(0)
qc.cx(0, 1)
let state = qc.run()
state.probabilities                  // [0.5, 0.0, 0.0, 0.5]

let counts = qc.measure(shots: 1000)
counts.sortedCounts                  // near-even split between "00" and "11"

// Extend to an n-qubit GHZ state: chain more cx calls from the same control.
// cx works on any distinct pair, so the target doesn't need to be adjacent.
let ghz = QuantumCircuit(qubits: 3)
ghz.h(0)
ghz.cx(0, 1)
ghz.cx(0, 2)
```

## Troubleshooting

- **Nothing prints when the page runs** — check the console (View ▸ Debug Area ▸
  Activate Console), not the results sidebar; this page uses `print`, like
  `06Superposition`.
- **Measurement counts aren't exactly 500/500 (or 500/500 for the GHZ state)** —
  expected; measurement is probabilistic. Re-run the page or raise `shots` for a
  tighter distribution.
- **Amplitude printouts show labels like `|10⟩` where you expected `|01⟩` or `|00⟩`** —
  the raw `StateVector` printout doesn't zero-pad; see the "Reading notes" above.
- **Reusing `apply(CNOTGate.matrix)` traps on a circuit that isn't 2 qubits** — the
  matrix is a fixed 4×4; `apply(_:)`'s precondition requires an exact 2ⁿ×2ⁿ match. Use
  `.cx(control, target)` (which builds the right-sized matrix via
  `CNOTGate.matrix(qubits:control:target:)`) for any other register size.
