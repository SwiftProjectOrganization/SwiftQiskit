# Tensor networks — help & usage guide

User-facing guide to the `23TensorNetwork` playground page.

## What the page shows

`QuantumCircuit.run()` replays every gate as its full 2ⁿ×2ⁿ embedded matrix.
`TensorNetwork(circuit)` (`Circuit/TensorNetwork.swift`) instead keeps each gate as its own
small *local* tensor — 2^k×2^k for a k-qubit gate — plus the wiring saying which qubit legs it
plugs into, and evaluates the whole diagram (`contract()`) from nothing but those small
tensors and the wiring. Comparing `contract()` against `run()` is therefore a genuine
cross-check of both, not the same computation read twice.

- A qubit wire is a bond-dimension-2 edge.
- A k-qubit gate is a rank-2k tensor node: k incoming legs, k outgoing legs.
- Each qubit's starting `|0⟩` is a small cap on the far left of its wire.

## Section by section

**Section 1 — a Bell pair.** `h(0); cx(0,1)`: 6 nodes (2 inputs + H + CX + 2 outputs), 5 edges.
`contract()` matches `run()` to machine precision.

**Section 2 — a GHZ state with a non-adjacent `cx` (page 07).** `h(0); cx(0,1); cx(0,2)`: the
second `cx`'s legs are q0 and q2, skipping q1 entirely. In the live view, that gate's box spans
all three wires, with q1's wire crossing it *dashed* to show it isn't one of the gate's legs.

**Section 3 — `rzz` unfolds into `cx; rz; cx` (page 21's identity).** `rzz` is built from
`pauliRotation`; for an all-Z string there's no basis change, just a CNOT staircase, one `rz`,
and the staircase undone. On two qubits that's exactly the three gate nodes CX, RZ, CX — the
same identity page 21 checks against `Matrix.expm()`.

**Section 4 — a small (2-qubit) QFT ladder (page 16).** Page 16's controlled-phase gate CP(θ),
built from `p`+`cx` as `p(θ/2,c); cx(c,t); p(-θ/2,t); cx(c,t); p(θ/2,t)`, expands to 5 gate
nodes; a 2-qubit QFT (no swap) — `h(0); CP(π/2,0,1); h(1)` — is 7 gate nodes end to end.

**Live view.** All four networks, drawn circuit-style: wires left to right, `|0⟩` caps on the
left, open output legs on the right, gates as labelled boxes in time columns.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`23TensorNetwork`** (or follow `[Next]`
   from `22Walk`).
2. Make sure the **SwiftQiskit-Package** scheme is active and builds — this page
   `import`s both `SwiftQiskit` and `SwiftQiskitViews`.
3. This page has a SwiftUI live view (`TensorNetworkView`). On Xcode 27 betas, re-copy the
   `libcups` shim immediately before running (`PLAYGROUNDSUPPORT.md`
   § "Xcode 27 beta workarounds").
4. Run the page. Every number is exact — no measurement/shot sampling anywhere on this page.

## Expected output

```text
Bell pair: 6 nodes, 5 edges, contract() vs run() max amplitude error = 0.00e+00
GHZ (non-adjacent cx): 9 nodes, 8 edges, contract() vs run() max amplitude error = 0.00e+00
rzz(0.7, 0, 1): 7 nodes, 7 edges, contract() vs run() max amplitude error = 0.00e+00
rzz's gate nodes in order: ["CX", "RZ(0.700)", "CX"]
2-qubit QFT ladder: 11 nodes, 11 edges, contract() vs run() max amplitude error = 0.00e+00
```

(The exact error printed may show as a tiny nonzero value like `1.11e-16` rather than exactly
`0.00e+00`, depending on floating-point rounding — either is the expected "matches to machine
precision" result.)

## The live view

`TensorNetworkView` draws each network on its own set of horizontal wires: a filled dot and
`|0⟩` label for each input, a labelled box for each single-qubit gate, a taller box spanning
every row a multi-qubit gate touches (with dashed pass-through lines for any wire crossing the
box without being one of its legs), and a plain leg stub with a `q<i>` label for each output.
The `rzz` network makes the wiring easiest to read at a glance: two CX boxes on both wires with
a single RZ box on q1 between them.

## Using it in your own code

```swift
import SwiftQiskit
import SwiftQiskitViews

let circuit = QuantumCircuit(qubits: 2)
circuit.h(0)
circuit.cx(0, 1)

let network = TensorNetwork(circuit)
print(network.nodes.count, network.edges.count)   // 6 5

let contracted = network.contract()   // a StateVector, built only from local tensors + wiring
let exact = circuit.run()             // the same state, built from full embedded matrices

let view = TensorNetworkView(network, title: "Bell pair")
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit-Package scheme must build first (both
  `SwiftQiskit` and `SwiftQiskitViews` products).
- **`Failed to load linked library cups`** — the Xcode 27 beta evaluator bug; re-copy the
  shim (`PLAYGROUNDSUPPORT.md`).
- **A gate's box looks disconnected from its wire** — check `node.qubits`, not `node.column`:
  a box is drawn spanning `node.qubits.min()...node.qubits.max()`, so a gate whose qubits
  aren't adjacent (like the GHZ page's second `cx`) will have a tall box with a dashed
  pass-through line for the skipped row — that's expected, not a bug.
- **Extending this page to more qubits/gates** — `TensorNetworkView`'s size scales with
  `network.columns`/`network.qubits`; pass an explicit `size:` if the default sizing looks
  cramped for a much larger circuit.
