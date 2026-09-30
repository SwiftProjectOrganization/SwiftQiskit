# Tensor networks from circuits, as a playground page

## Context

No earlier page reads a circuit as anything other than a sequence of full 2ⁿ×2ⁿ matrices
replayed by `run()`. `QuantumCircuit`'s private `Operation` kept only `matrix` (the full
embedding) and `qubits` (for `runDensityMatrix(noise:)`/`runTrajectories(noise:shots:)` to
place per-gate noise) — it discarded the gate's name and its own small local tensor, which are
exactly what a tensor-network diagram needs. This closes that gap: a small Core addition
(`TensorNetwork`), a drawing (`TensorNetworkView`), and a new page, `23TensorNetwork`,
continuing the `01`–`22` numbered sequence (not the `40`+ book-chapter track).

## Changes

### Core: `QuantumCircuit.Operation` gains a name and a local tensor
(`Sources/SwiftQiskit/Circuit/QuantumCircuit.swift`)

`Operation` (made internal, not `private`, so `TensorNetwork` can read it) adds `name: String`
and `local: Matrix` — the gate's own 2^k×2^k tensor in `qubits`' leg order, *not* embedded
across the register. `record(_:actingOn:)` becomes `record(_:actingOn:name:local:)`; every
gate method passes its own short label (`"H"`, `"CX"`, `"CCX"`, `"MCX"`, `"P(0.785)"`,
`"RX(…)"`, …) and its un-embedded matrix (`HadamardGate.matrix`, `CNOTGate.matrix`,
`MultiControlledXGate.matrix(qubits: controls.count + 1, controls: 0..<controls.count,
target: controls.count)`, …). The public `apply(_:)` records `name: "U"`, `local` equal to
the full matrix it was given (there's no narrower answer since an arbitrary caller-supplied
matrix could touch any qubit — mirrors why it already tags every qubit for noise purposes).
The all-`I` global-phase case in `pauliRotation` records `name: "phase"`, `local` a 1×1
scalar matrix, `actingOn: []`. A new internal `operationRecords` computed property exposes
the operation list read-only, for `TensorNetwork.init(_:)`.

**Bug fixed along the way:** `t(_:)` was recorded via `apply(full)` instead of
`record(full, actingOn: [qubit], …)` like every other single-qubit gate — `apply(_:)` tags
every qubit in the register, so a `NoiseModel` was wrongly applying noise to the *entire*
circuit after a single `t()` on one qubit. Fixed to `record(...)`, with a regression test in
`NoiseModelTests.swift`.

### New Core type: `TensorNetwork`
(`Sources/SwiftQiskit/Circuit/TensorNetwork.swift`)

```swift
public struct TensorNetwork {
    public enum Kind: Equatable { case input; case gate(String); case output }
    public struct Node { id; kind; qubits; column; tensor }
    public struct Edge { id; qubit; from; to }
    public let qubits: Int
    public let nodes: [Node]
    public let edges: [Edge]
    public let columns: Int
    public init(_ circuit: QuantumCircuit)
    public func contract() -> StateVector
}
```

`init(_:)` places one `.input` node per qubit at column 0, one `.gate` node per
`operationRecords` entry (ASAP-scheduled: a gate's column is one more than the latest column
already reached on any qubit it touches, so gates on disjoint qubits share a column), one
`.edge` per wire segment, and one `.output` node per qubit at the final column.
`contract()` walks the gate nodes in recorded order and applies **only** each node's own
`tensor` to the legs it names — a private `apply(_:targets:totalQubits:to:)` gather/scatter
generalizing `embedSingleQubitGate`'s idea to an arbitrary target set, never building the full
embedded matrix. Because it never touches `Operation.matrix`, agreement with `circuit.run()`
is an independent check of both the wiring and the contraction, not the same computation read
twice.

### New view: `TensorNetworkView`
(`Sources/SwiftQiskitViews/TensorNetworkView.swift`)

A stateless `Canvas`-based `View` (`init(_:title:size:)`, same shape as `CHSHChartView`):
qubit wires left to right, `|0⟩` caps on the left, open output legs (`q<i>`) on the right,
single-qubit gates as small labelled boxes, multi-qubit gates as a taller box spanning every
row they touch (with a dashed overlay on any wire that merely crosses the box's row span
without being one of its legs), and the leg-less `"phase"` node in its own small row above
the wires.

### New page `23TensorNetwork`

Console explanation of the wires-as-edges/gate-as-tensor/`|0⟩`-as-cap framing, four worked
networks — a Bell pair, a GHZ state with a non-adjacent `cx` (page 07), `rzz` unfolding into
its `cx;rz;cx` identity (page 21), and a small 2-qubit QFT ladder built from `p`+`cx` (page
16) — each printed with its node/edge counts and `contract()` vs. `run()` max amplitude
error, then a live `VStack` gallery of all four on `TensorNetworkView`.

### Docs

- `API.md`: `TensorNetwork` and `TensorNetworkView` sections.
- `CLAUDE.md`: the `TensorNetwork`/`operationRecords`/`t()`-fix notes in the
  `QuantumCircuit.swift` bullet, a new `TensorNetwork.swift` bullet, a `TensorNetworkView`
  bullet under "SwiftQiskitViews", the `23TensorNetwork` page bullet, the SwiftUI-view page
  count (twelve → thirteen), and the new test files in "Testing".
- `00TOC.xcplaygroundpage`: a bullet for `23TensorNetwork`.
- `PlaygroundDocs/23TENSORNETWORKHELP.md`: the user-facing guide.
- This file records the plan.
- `README.md` deliberately left alone — it had an unrelated uncommitted wording edit at the
  time, committed separately.

## What the verification pass caught

The node/edge counts written into the first draft of `23TENSORNETWORKHELP.md`'s "Expected
output" were **hand-computed wrong** for three of the four networks (right for the Bell pair,
off by one node/edge each for the GHZ and `rzz` networks, and off by one edge for the QFT
ladder). Encoding each claim as a `#expect` in `TensorNetworkTests.swift` and running the
suite caught this immediately — corrected figures, confirmed by `RunAllTests`:

| Network | Nodes | Edges |
|---|---|---|
| Bell pair (`h;cx`) | 6 | 5 |
| GHZ, non-adjacent `cx` (`h;cx;cx`) | 9 | 8 |
| `rzz(0.7, 0, 1)` → `CX, RZ(0.700), CX` | 7 | 7 |
| 2-qubit QFT ladder (`h; p;cx;p;cx;p; h`) | 11 | 11 |

The lesson generalizes: this page's "expected output" numbers are load-bearing claims about
`TensorNetwork`'s construction, not narrative color, so every one of them now has a matching
test rather than resting on hand arithmetic.

## Explicitly not doing

- **No `STATUSandTODO.md`/`PLAYGROUNDSUPPORT.md` entries.** Every other `01`–`22` page has a
  line in both; this page does not yet. Adding them is a small, separate follow-up, not
  bundled into this change.
- **No general n-qubit or arbitrary-topology layout.** `TensorNetworkView`'s row-per-qubit,
  column-per-gate layout only makes sense for the small, illustrative circuits this page
  uses; it isn't meant to scale to a page like `12ShorExample`'s larger registers without
  revisiting the geometry.
- **No tensor-network *contraction-order optimization*.** `contract()` always applies gates
  in recorded order on the full 2ⁿ-amplitude array — it demonstrates the tensor-network
  *reading* of a circuit, not a more efficient simulation strategy (the kind of thing a real
  tensor-network simulator like MPS/PEPS would add).

## Verification

1. `mcp__xcode-tools__BuildProject` on the `SwiftQiskit-Package` scheme — green after every
   Core/view change.
2. `mcp__xcode-tools__RunAllTests` on `SwiftQiskit-Package` — 243 tests passed, including the
   new `TensorNetworkTests.swift` (node/edge counts, every gate tensor `isUnitary()`,
   `contract()` vs. `run()` agreement to 1e-10 across a Bell pair, a non-adjacent-`cx` GHZ
   state, a mixed gate set, an all-identity global phase, and a raw `apply(_:)`) and
   `TensorNetworkViewTests.swift`, plus the `NoiseModelTests.swift` regression test for the
   `t()` fix.
3. Open `23TensorNetwork` in Xcode (follow `[Next]` from `22Walk`) and run it: console output
   should match `PlaygroundDocs/23TENSORNETWORKHELP.md`'s "Expected output" block, and the
   live view should show four circuit-style diagrams. Re-copy the `libcups` shim immediately
   before running on Xcode 27 betas (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds").
