# 4-qubit superposition — help & usage guide

User-facing guide to the `06Superposition` playground page — a 4-qubit walkthrough that
puts every qubit into superposition at once via `QuantumCircuit.h`, then inspects the
result through `StateVector.amplitudes`/`.probabilities` and `SimulationResult`. It
replaces this page's earlier content (hand-built custom gates from raw `Matrix`/`Complex`
values); that example still lives in `07Entanglement`'s Section 6. As with `01Qubits`/
`05Gates` there is no separate design/plan document — the page itself and
`BellStateTests.swift`/`AdditionalGatesTests.swift` (for the underlying `h`/`measure`
behavior) are the reference.

## What the page shows

The page runs four short sections, each printing annotated output to the console (unlike
`05Gates`, which is sidebar-only):

| Section | What it does | What it shows |
|---|---|---|
| 1 | `QuantumCircuit(qubits: 4)`, then `h(0)`, `h(1)`, `h(2)`, `h(3)` | every qubit Hadamard'd — |0000⟩ → an equal superposition of all 2⁴ = 16 basis states |
| 2 | print `state.amplitudes` (zero-padded binary labels) and `state.probabilities` | all 16 amplitudes ≈ 0.25, all 16 probabilities ≈ 0.0625 |
| 3 | `qc.measure(shots: 1600)`, print `result.sortedCounts` | 16 states, each landing near 1600/16 = 100 counts (statistical) |
| 4 | a second circuit with only `h(0)` and `h(2)` (qubits 1, 3 left at \|0⟩) | only 4 of 16 states have nonzero probability — the untouched qubits are 0 in every outcome, contrasting with Section 1 |

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`06Superposition`** page (or
   follow the `[Next]` link from `05Gates` / `[Previous]` from `07Entanglement`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page and open the console — this page is **print-based**, not sidebar-only
   like `05Gates`.

This page is **console-only — no SwiftUI, no live view** — so the Xcode 27 beta evaluator
bugs described in `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (the
`libcups.dylib` shim and the `@State` macro issue) do not apply here.

## Expected results

Console output (verified against `Circuit/QuantumCircuit.swift`, `Quantum/StateVector.swift`,
and `Quantum/SimulationResult.swift`; up to floating-point rounding and measurement
statistics):

| Section | Expression | Value |
|---|---|---|
| 2 | each `state.amplitudes[i]` | ≈ `0.25` (real, zero imaginary part) |
| 2 | `state.probabilities` | sixteen entries, each `0.0625` |
| 3 | `result.sortedCounts` | 16 states (`0000`…`1111`), each count near 100 out of 1600 shots |
| 4 | `partialState.probabilities` | nonzero only at `0000`, `0010`, `1000`, `1010`, each `0.25`; all other 12 entries `0.0` |

Reading notes:

- **Section 2 is the page's main point.** A Hadamard sends each qubit to
  `(|0⟩ + |1⟩)/√2` independently; tensoring four of them together gives every one of the
  16 combined basis states an amplitude of `(1/√2)⁴ = 1/4`, hence probability `(1/4)² =
  1/16` for each — a perfectly uniform distribution.
- **Section 3 confirms Section 2 statistically**, the same way `05Gates`'s `qcRX.measure`
  confirms a 50/50 split — expect counts to hover near, not exactly at, 100 per state.
- **Section 4 isolates what "all qubits in superposition" means by removing it from two
  qubits.** Only `h(0)` and `h(2)` are applied, so qubits 1 and 3 (the second and fourth
  bit of each label) are 0 in every outcome — probability mass only spreads across the
  4 = 2² combinations of qubits 0 and 2, not all 16.

## Using it in your own code

```swift
import SwiftQiskitCore

let qc = QuantumCircuit(qubits: 4)
for qubit in 0..<4 {
    qc.h(qubit)
}
let state = qc.run()
state.probabilities        // sixteen entries, each 0.0625

let counts = qc.measure(shots: 1600)
counts.sortedCounts         // [(state: "0000", count: ~100), ...] for all 16 states
```

## Troubleshooting

- **Nothing prints when the page runs** — check the console (View ▸ Debug Area ▸ Activate
  Console), not the results sidebar; this page uses `print`, unlike `05Gates`.
- **Measurement counts aren't exactly 100 per state** — expected; measurement is
  probabilistic. Re-run the page or raise `shots` in Section 3 for a tighter distribution.
- **Amplitude labels look inconsistent width** — the page's inline `binaryLabel(_:qubits:)`
  helper zero-pads to 4 digits; if you copy the amplitude-printing loop elsewhere without
  it, `StateVector`'s own `description` does *not* zero-pad and will show ragged widths
  (e.g. `|0⟩` next to `|1111⟩`).
- **Looking for the custom-gate example that used to be here** — it moved to
  `07Entanglement`'s Section 6 (a hand-built Pauli-X `Matrix` applied via `apply(_:)`).
