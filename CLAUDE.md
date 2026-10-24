# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

SwiftQiskit is a lightweight, educational quantum-computing simulator written in pure Swift,
offering a Qiskit-like API. It is experimental (v0.8.1): the API is unstable and correctness is
prioritized over performance. The fork's former `Playgrounds.playground`/`PlaygroundDocs/` were removed (recoverable at the
`pre-playground-removal` git tag).

SwiftQiskit is the simulation library. The primary educational components are built on it: the
sibling `SwiftQiskitApp` repo (a drag-and-drop "get familiar" app plus the `INTRODUCTION.md` book)
and the sibling `SwiftQiskitPlaygrounds` repo (Xcode playgrounds that pick up where the app stops,
using SwiftQiskit as a remote package).

`API.md` at the repo root is the full API reference for the core library (every public type and
member, with signatures and gotchas). Keep it in sync whenever the public API changes.

## Build, Run & Test

From Xcode, prefer the `xcode-tools` MCP tools (`BuildProject`, `RunProject`, `RunAllTests`).

CLI equivalents:

```bash
swift build                        # build everything
swift test                        # run unit tests
swift run SwiftQiskitExamples     # Bell-state CLI demo
```

## Targets

| Target | Path | Purpose |
|---|---|---|
| `SwiftQiskit` | `Sources/SwiftQiskit/` | Core simulation library |
| `SwiftQiskitViews` | `Sources/SwiftQiskitViews/` | Shared, UI-free-Core-preserving SwiftUI views (`BlochVector`, `CHSHChartView`) |
| `SwiftQiskitExamples` | `Examples/` | CLI Bell-state demo |

The library *product* and the *module* are both named `SwiftQiskit` — `import SwiftQiskit`.
The SwiftUI front-end lives in the sibling `SwiftQiskitApp` repo (and the learner-facing playgrounds in
`SwiftQiskitPlaygrounds`), not in this package; there is
no `SwiftQiskitGUI` target here anymore (it was a duplicate, removed in favor of the app).
`SwiftQiskitViews` is a second, small library product (`import SwiftQiskitViews`) depending
only on `SwiftQiskit` — presentational types shared by `SwiftQiskitApp` and
`SwiftQiskitPlaygrounds`, kept out of `SwiftQiskit` itself so Core stays UI-free.

## Architecture (bottom-up)

- `Math/Complex.swift` — value-type complex numbers (`+ - * /`, scalar mul, `.zero/.one/.i`).
- `Math/Matrix.swift` — row-major `GenericMatrix<Element: MatrixScalar>` (`Math/MatrixScalar.swift`; `Complex` and `Double` conform), with `Matrix = GenericMatrix<Complex>` as the alias all quantum code uses; `Double` scalar `*`, `expm` are Complex-only, `adjoint` lives here now; `* + -`, scalar mul (`Double`/`Complex`,
  either operand order), `multiply(by:)` (matrix × vector), `identity(size:)`, Kronecker
  product `tensor(_:)` / `⊗` (the `⊗` operator is declared here), `isUnitary(tolerance:)`
  (entrywise `U†U ≈ I`, since `==` compares exactly), `trace` (traps if non-square),
  `permutation(size:image:)` (builds a permutation matrix from a column→row map, trapping
  unless `image` is a bijection — the bijection check doubles as the unitarity check),
  `expm(terms:)` (matrix exponential via scaling-and-squaring Taylor series; no implicit
  `-i` — scale by `Complex(0, -theta)` yourself for e^(-iθH)).
- `Utils/Angles.swift` — public free functions `deg2rad(_:)` / `rad2deg(_:)` (`Double`);
  all library angles are radians.
- `Quantum/StateVector+Kernels.swift` — internal `applyLocal(_:targets:parallel:)`: applies a
  gate's small 2ᵏ×2ᵏ tensor to `targets` in place (qubit 0 = MSB), gathering each of the 2ⁿ⁻ᵏ
  spectator groups, multiplying by the tensor's non-zero entries only (so permutation, diagonal
  and controlled gates are cheap), and scattering back; runs via `concurrentPerform` when the
  state has ≥ `parallelThreshold` (2¹⁴) amplitudes. No renormalization (callers pass unitaries).
  `QuantumCircuit.run()`/`runTrajectories` use it; `amplitudes` is `internal(set)` for it.
  `StateVector.sampleIndices(from:count:)` draws many samples from one cumulative sum.
- Performance notes: `Matrix` arithmetic runs on raw row-major buffers (internal `grid`/
  `init(rows:cols:elements:)`, zero-skipping i-k-j multiply). `applyLocal` has dedicated
  diagonal and 1-qubit paths. `PauliString.expectation` is a direct O(2ⁿ) flip-mask/phase sum
  (no dense matrix). `DensityMatrix.applyingLocal`/`applyingKraus` (internal) run the gate
  kernel on ρ as a 2n-qubit vector (U on row bits, conj(U) on column bits), used by
  `runDensityMatrix` and `KrausChannel.apply(to:qubit:)`; `purity`/`expectation` are O(4ⁿ).
  `measure(shots:basis:from:)` (internal) rotates an already-run state, so
  `measureExpectation(of: Hamiltonian)` runs the circuit once for all groups;
  `runTrajectories` takes Kraus weights from the qubit's reduced 2×2 ρ and tallies shots by
  integer index. `Operation.matrix` is now only a test reference.
- `Quantum/StateVector.swift` — amplitudes; auto-normalizes on init and `apply(_:)`;
  `measure()` is probabilistic and **collapses (mutates) the state**; `tensor(_:)` / `⊗`
  combines registers (`self` in the high-order bits, per the qubit-0-is-MSB convention);
  `marginalProbabilities(over:)` sums out every qubit not listed, returning every one of the
  2^k possible keys (including zero-probability ones) in the order the qubits were given.
- `Gates/*.swift` — each fixed gate is a `public enum` exposing `static let matrix: Matrix`
  (`HadamardGate`, `PauliXGate`, `PauliYGate`, `PauliZGate`, `SGate`/`SDaggerGate`,
  `TGate`/`TDaggerGate`, `CNOTGate`, `ToffoliGate`); parameterized gates expose
  `static func matrix(theta:)` instead (`PhaseGate` P(θ) in `Phase.swift`,
  `RXGate`/`RYGate`/`RZGate` in `Rotation.swift`). Follow these patterns for new gates.
  `CNOTGate` additionally offers `matrix(qubits:control:target:)` — the full 2ⁿ×2ⁿ CNOT for
  any distinct control/target pair, built as a basis-state permutation; `ToffoliGate` mirrors
  this with `matrix(qubits:control1:control2:target:)` (`Toffoli.swift`), symmetric in its
  two controls, both built via `Matrix.permutation`. `MultiControlledXGate`
  (`MultiControlledX.swift`) generalizes both to an arbitrary number of controls via the
  same `Matrix.permutation` idiom (0 controls = `x`, 1 = `CNOTGate`, 2 = `ToffoliGate`) —
  the piece `increment`/`decrement` below need for a register wider than 2 bits.
  `RZZGate`/`RXXGate`/`RYYGate` (`TwoQubitRotation.swift`) are the fixed-2-qubit
  `exp(-iθ·P⊗P/2)` family, each checked against `Matrix.expm()` and, for `RZZGate`, against
  the `cx;rz;cx` identity.
- `Circuit/QuantumCircuit.swift` — records operations (**no full matrix is built at record
  time**; `Operation.matrix` is computed on demand from `local` + `qubits`, used only by
  `runDensityMatrix`; `dense` is set only for a caller's `apply(_:)` matrix; circuits are capped
  at 30 qubits). Historically it stored full 2ⁿ×2ⁿ matrices, each tagged
  with the qubits it acts on, a short gate label, and its own small un-embedded *local*
  tensor (`struct Operation { matrix; qubits; name; local }`, recorded via the private
  `record(_:actingOn:name:local:)` rather than the public `apply(_:)`, which — since an
  arbitrary caller-supplied matrix could touch any qubit — records all of them, `name: "U"`,
  `local` equal to the full matrix). The qubits tag is what
  `runDensityMatrix(noise:)`/`runTrajectories(noise:shots:)` below use to place per-gate
  noise precisely; the name/local tensor are consumed by `TensorNetwork` below, not by
  execution. `t(_:)` records `actingOn: [qubit]` like every other single-qubit gate (it used
  to go through `apply(_:)`, wrongly tagging every qubit for noise purposes — fixed).
  `operationRecords` is an internal read-only accessor onto the operation list, for
  `TensorNetwork.init(_:)`. Single-qubit gates are embedded across the register via
  `Matrix.tensor(_:)` (internal, not `private`, `embedSingleQubitGate` — also reused by
  `KrausChannel.apply(to:qubit:)`). API: `h/x/y/z/s/sdg/t/tdg/cx/ccx`, the general
  `mcx(_ controls: [Int], _ target:)` (via `MultiControlledXGate`), parameterized
  `p/rx/ry/rz(_ theta:, _ qubit:)` (θ first, as in Qiskit), `apply(_:)`, `run()`,
  `runAndMeasure()`, `measure(shots:)`; `rzz/rxx/ryy(_ theta:, _ q0:, _ q1:)` on any distinct
  qubit pair (not just adjacent), and the general `pauliRotation(_ pauli: String, theta:)`
  they're built from — a basis change (`rotateToZ`: `h`/`sdg;h`) plus a CNOT-staircase parity
  trick plus one `rz`, matching `Matrix.expm()` on the same Pauli-string generator exactly
  (including the all-`I` global-phase case). `rotateToZ(_ basis: PauliBasis, _ qubit:)`
  appends the rotation making a Z-basis measurement of `qubit` read out `basis` instead;
  `measure(shots:basis:)` applies it per-qubit to a **copy** of the circuit before measuring,
  leaving the receiver's own operation list untouched. `measureExpectation(of:shots:)`
  (overloaded for `PauliString`/`Hamiltonian`) is a shot-based expectation value built on
  `measure(shots:basis:)` + `SimulationResult.parityExpectation(qubits:)`; the `Hamiltonian`
  overload groups `hamiltonian.terms` via `Hamiltonian.commutingGroups()` below and spends
  `shots` once per group rather than once per term (every term in a qubit-wise-commuting
  group shares one `measure(shots:basis:)` call). `evolve(_ hamiltonian:
  time: steps: order:)` appends `steps` repetitions of a Trotterized product formula (one
  `pauliRotation` call per term; `order: 1` full-step Lie–Trotter, `order: 2` half/full/half
  Strang splitting), terms applied in the order `hamiltonian.terms` lists them — no
  automatic commuting-layer grouping (unlike `measureExpectation` above; a caller who wants
  one reorders `terms` via `commutingGroups()` first);
  `Hamiltonian.trotterCircuit(time:steps:order:)` below wraps it on a fresh circuit. `increment`/`decrement(register: [Int], controlledBy: Int?)`
  are a ripple-carry ±1 on `register` (most-significant qubit first) built from `mcx` —
  `increment` applies most-significant to least-significant so every flip's controls are
  read before they're touched; `decrement` is the same gates in reverse (each `mcx` is
  self-inverse). `runDensityMatrix(noise: NoiseModel? = nil) -> DensityMatrix` replays every
  recorded operation on a `DensityMatrix` (starting from |0…0⟩⟨0…0|), applying `noise`'s
  matching-arity `KrausChannel` to every qubit each gate touched right after that gate;
  `noise: nil` is mathematically identical to `DensityMatrix(run())`.
  `runTrajectories(noise:shots:) -> SimulationResult` is the Monte-Carlo "quantum
  trajectories" unraveling of the same thing: `shots` independent pure-state runs, each
  stochastically applying one Kraus operator (probability `‖Kᵢ|ψ⟩‖²`) per noisy gate.
- `Circuit/TensorNetwork.swift` — `TensorNetwork`: a tensor-network view of a
  `QuantumCircuit`'s `operationRecords` above — one node per `|0⟩` input, one per recorded
  gate (`Kind.gate(name)`, carrying that gate's own small `local` tensor and the qubits it
  legs into), one per open output leg, wired by one edge per wire segment. `init(_:)`
  ASAP-schedules each gate's layout `column` (one more than the latest column already
  reached on any qubit it touches, so gates on disjoint qubits share a column).
  `contract() -> StateVector` evaluates the whole diagram from `|0…0⟩` through every gate
  node in recorded order, applying only that node's own small tensor to the legs it names —
  never the full embedded matrices `run()` uses — so agreement between `contract()` and
  `run()` is an independent check of both, not the same computation read twice. Drawn by
  `SwiftQiskitViews.TensorNetworkView` (see "SwiftQiskitViews" below).
- `Quantum/SimulationResult.swift` — shot counts keyed by binary state string;
  `marginalCounts(over:)` (grouped counts, only observed keys) and `parityExpectation(qubits:)`
  (the ±1 parity-product average, e.g. for a shot-based ⟨Z⊗Z⟩) sum over a subset of qubits.
- `Quantum/PauliBasis.swift` — `PauliBasis` (`.x`/`.y`/`.z`, `Character` raw values matching
  the `pauliRotation` string labels): the single-qubit Pauli measurement basis used by
  `rotateToZ`/`measure(shots:basis:)` above.
- `Quantum/PauliString.swift` — `PauliString`: one weighted Pauli tensor-product term
  (`[PauliBasis?]` labels, `nil` = `I`, plus a real `coefficient`), buildable from a label
  string (`"XIZ"`) or from `labels:`; exposes `qubits`, `activeQubits`, `label` (round-trips
  through the string initializer and matches `pauliRotation`'s own labels), `matrix`, and
  `expectation(_ state:)`. `isQubitWiseCommuting(with:)` is true iff, on every qubit, the
  two strings' labels agree or at least one is `I` — stricter than literal Pauli
  commutativity, but the condition `Hamiltonian.commutingGroups()` below actually needs
  (two QWC-compatible terms share one well-defined per-qubit measurement basis).
- `Quantum/Hamiltonian.swift` — `Hamiltonian`: a plain (unmerged, ungrouped) sum of
  `PauliString` terms, with `matrix` (Σ term matrices) and `expectation(_ state:)` (Σ term
  expectations). Replaces entrywise Pauli-term accumulation done by hand.
  `trotterCircuit(time:steps:order:)` is `QuantumCircuit(qubits:)` +
  `QuantumCircuit.evolve(_:time:steps:order:)` above. `commutingGroups() -> [[PauliString]]`
  partitions `terms` into qubit-wise-commuting groups via a greedy heuristic (Qiskit's
  default `group_commuting` strategy: each term joins the first existing group every member
  of which it's compatible with, else starts a new group) — used automatically by
  `measureExpectation(of: Hamiltonian, shots:)` above.
- `Quantum/ParameterShift.swift` — `ParameterShift.gradient(at:shift:_:)`: the
  parameter-shift rule generalized to any number of parameters and any `[Double] ->
  Double` cost closure (exact whenever every parameter is a single `exp(-iθP/2)` rotation's
  angle; default `shift: .pi/2` matches the one-parameter derivation), plus a
  `Hamiltonian`/`ansatz`-closure convenience overload. `GradientDescent.minimize(initial:
  learningRate:maxIterations:tolerance:cost:gradient:)` is a minimal fixed-step optimizer
  (no line search/momentum) defaulting its `gradient` to `ParameterShift.gradient`,
  returning a `Result` (`parameters`, `value`, `history`, `parameterHistory`, `iterations`,
  `converged`) — `parameterHistory[i]` is the parameter vector `history[i]` was evaluated
  at, so zipping the two gives the full optimization trajectory (e.g. for live charts).
- `Quantum/StateTomography.swift` — `StateTomography`: a caseless namespace turning
  `measure(shots:basis:)` results into a reconstructed single-qubit Bloch vector —
  `estimate(qubit:result:)` (a single-qubit `parityExpectation` wrapper),
  `estimateBlochVector(of:qubit:shots:)` (the three X/Y/Z settings), and
  `reconstructSingleQubit`/`clampToPhysical` (physicality check and rescale, not a real MLE
  estimator). Returns `(x:, y:, z:)` tuples rather than a `BlochVector` type, to avoid
  colliding with `SwiftQiskitViews.BlochVector` (see "SwiftQiskitViews" below) — this is
  also why that type doesn't live in `SwiftQiskit` itself.
- `Quantum/Dirac.swift` — Dirac notation: `Ket` (typealias of `StateVector`), `Bra`
  (conjugated row vector), postfix `†` (dagger; also `Matrix.adjoint`), `*` overloads for
  inner (`Bra * Ket`) / outer (`Ket * Bra`) products and `Bra * Matrix -> Bra` (enables
  expectation values `psi† * U * psi`), `StateVector.expectation(_ observable: Matrix) ->
  Double` (named one-liner for the same `(psi† * U * psi).real`), mixed `⊗` overloads
  (`Ket ⊗ Bra` / `Bra ⊗ Ket`, both returning the outer-product `Matrix`), basis kets
  `Ket("01")` / `.zero/.one/.plus/.minus/.plusI/.minusI`.
- `Quantum/DensityMatrix.swift` — `DensityMatrix`: a mixed-state ρ, built from a
  `StateVector` (`Ket * Bra` outer product), a classical mixture
  (`[(probability:, state:)]`), or a raw validated `Matrix` (every initializer checks
  square/2ⁿ/Hermitian/trace-1). `purity`, `probabilities`, `expectation(_:)`,
  `fidelity(to:StateVector)`, `apply(_:) -> DensityMatrix` (UρU†),
  `partialTrace(keeping: [Int])` (n-qubit, any subset, kept qubits in the order given —
  same convention as `StateVector.marginalProbabilities(over:)`), `blochVector` (nil unless
  2×2), `eigenvalues`/`vonNeumannEntropy` (a real-symmetric embedding of the Hermitian
  matrix plus a small file-private cyclic Jacobi solver — adequate for qubit-count sizes,
  not general-purpose).
- `Quantum/KrausChannel.swift` — `KrausChannel`: a channel `ρ' = Σᵢ KᵢρKᵢ†` given by its
  `operators`. `isTracePreserving(tolerance:)` checks `Σᵢ Kᵢ†Kᵢ ≈ I` (mirrors
  `Matrix.isUnitary`'s style); `apply(to: DensityMatrix)` on the whole register;
  `apply(to:qubit:)` embeds a 2×2 channel onto one qubit via the same
  `embedSingleQubitGate` idiom `CNOTGate.matrix(qubits:control:target:)` uses for a 2×2
  gate. Factories `bitFlip`/`phaseFlip`/`depolarizing`/`amplitudeDamping` (the four standard
  channels) plus `phaseDamping` (new: pure T2 dephasing, no energy
  loss, unlike `amplitudeDamping`).
- `Quantum/NoiseModel.swift` — `NoiseModel`: `singleQubitGate`/`multiQubitGate`, each an
  optional single-qubit (2×2), trace-preserving `KrausChannel` applied independently to
  every qubit a gate of that arity touched (`init` traps on a bigger or non-trace-preserving
  channel). `.uniform(_:)` applies the same channel after both gate classes. Consumed by
  `QuantumCircuit.runDensityMatrix`/`runTrajectories` above.

## SwiftQiskitViews

`Sources/SwiftQiskitViews/` — a separate library product/module (`import SwiftQiskitViews`,
depends only on `SwiftQiskit`), holding presentational SwiftUI types shared by
the sibling `SwiftQiskitApp` and `SwiftQiskitPlaygrounds` repos:

- `BlochVector.swift` — `BlochVector`: a single-qubit Bloch-sphere coordinate `(x, y, z)`,
  with `init(_:StateVector)` (pure state), `init(_:StateVector, qubit:)` (reduced/
  partial-trace qubit of a multi-qubit pure state), `init?(_:DensityMatrix)` (nil unless
  2×2 — via `DensityMatrix.blochVector`), `init(_:DensityMatrix, qubit:)` (reduced qubit via
  `partialTrace(keeping:)`), and `init(x:y:z:)` (raw coordinates, for `|r| < 1`); plus
  `magnitude`/`theta`/`phi`. Replaces the three previously hand-vendored copies
  (the playground's `BlochVector.swift`, `SwiftQiskitApp/BlochVector.swift`,
  and the app's `blochOf(_:Matrix)`).
- `BlochSphereView.swift`, `BlochProjectionView.swift`, `Bloch3DView.swift`,
  `BlochExplorerView.swift` — the Bloch-sphere views (2D oblique, plane projection, rotatable 3D,
  and a 3D view with θ/φ sliders), moved here from the former playground's `Sources/` in 0.8.1 so
  `SwiftQiskitApp` and `SwiftQiskitPlaygrounds` can import them.
- `CHSHChartView.swift` — `CHSHChartView`: a minimal, stateless `Canvas`-based 2D
  line/scatter chart, for correlation curves, energy landscapes and distribution comparisons.
- `TensorNetworkView.swift` — `TensorNetworkView`: a stateless, circuit-aligned `Canvas`
  drawing of a `TensorNetwork` (see `Circuit/TensorNetwork.swift` above) — qubit wires left
  to right, `|0⟩` caps on the left, open output legs on the right, gates as labelled boxes
  in time columns (a multi-qubit gate's box spans every row it touches, with a dashed
  overlay on any wire merely crossing the box without being one of its legs).

## Conventions & Gotchas

- **Qubit indexing:** qubit 0 is the most-significant (leftmost) bit.
- **`cx`/`ccx`/`mcx` are general:** `cx(control, target)`/`ccx(control1, control2, target)`/
  `mcx(controls, target)` work for any distinct qubits on an n-qubit circuit, via
  `CNOTGate.matrix(qubits:control:target:)`/`ToffoliGate.matrix(qubits:control1:control2:target:)`/
  `MultiControlledXGate.matrix(qubits:controls:target:)` (all permutation-matrix construction).
- **Other controlled gates:** `cz`/`cy`/`swap`/`mcz`/`mcy` (`ControlledZGate`, `ControlledYGate`,
  `SwapGate`, `MultiControlledZGate`, `MultiControlledYGate`, in `Gates/`) likewise work for any distinct
  qubits, each with a `matrix(qubits:…)` builder.
- Invariants are guarded with `precondition(...)` throughout; keep doing this when extending.
- Measurement result strings are zero-padded binary via `String.leftPadding` (`Utils/String+Padding.swift`).
- Style: 4-space indent, PascalCase types, camelCase members, no force unwrapping.

## Testing

- Tests live in `Tests/SwiftQiskitTests/` (`BellStateTests.swift`,
  `TensorProductTests.swift`, `DiracNotationTests.swift`, `CNOTTests.swift`,
  `AdditionalGatesTests.swift`, `MatrixArithmeticTests.swift`, `MeasurementTests.swift`,
  `MatrixExponentialTests.swift`, `TwoQubitRotationTests.swift`, `ToffoliTests.swift`,
  `ReadoutTests.swift`, `PauliBasisTests.swift`, `PauliStringTests.swift`,
  `MeasureExpectationTests.swift`, `StateTomographyTests.swift`, `TrotterTests.swift`,
  `ParameterShiftTests.swift`, `RegisterArithmeticTests.swift`, `DensityMatrixTests.swift`,
  `KrausChannelTests.swift`, `NoiseModelTests.swift`, `TensorNetworkTests.swift`, `StateVectorKernelTests.swift`, `AngleConversionTests.swift`, `GenericMatrixTests.swift`, `CommutingGroupsTests.swift`, `ControlledYTests.swift`,
  `ControlledZAndSwapTests.swift`, `PerformancePathTests.swift`, `PermutationFastPathTests.swift`,
  `RunBenchmarkTests.swift`).
  `Tests/SwiftQiskitViewsTests/` (`BlochVectorTests.swift`, `CHSHChartViewTests.swift`,
  `TensorNetworkViewTests.swift`) tests the `SwiftQiskitViews` module above.
- Tests use the Swift **`Testing`** framework (`import Testing`, `@Test`, `#expect`,
  struct suites) — not XCTest.
- **Scheme gotcha for Xcode test runs:** all schemes are autogenerated by Xcode for the
  SPM package (no `.xcscheme`/`.xctestplan` files on disk). The per-product `SwiftQiskit`
  scheme's implicit test plan contains **no test targets**, so `RunAllTests`/`GetTestList`
  report 0 tests under it — run tests under the `SwiftQiskit-Package` scheme instead
  (its plan includes `SwiftQiskitTests` and `SwiftQiskitViewsTests`). `swift test` from the
  repo root works regardless of the active scheme.
- Measurement tests are statistical (e.g. 40–60% tolerance over 1000 shots) — expect
  probabilistic assertions, not exact counts.

## Tool hints

When working in Claude Code with Sonnet tools, read-only permission is always granted for
the `SwiftQiskit`, `SwiftQiskitApp` and `SwiftQiskitPlaygrounds` repositories
(`/Users/rob/Projects/Swift/<name>`). Reading and searching them needs no confirmation:

- Read, Grep and Glob, and the `xcode-tools` read tools (`XcodeRead`, `XcodeGrep`,
  `XcodeGlob`, `XcodeLS`).
- Read-only shell commands such as `ls`, `cat`, `git status`, `git log`, `git diff` and
  `git show`.

Edits, state-changing builds, commits and pushes still follow the normal confirmation rules.
Use the siblings freely for reference: `../SwiftQiskitApp` for how the library is consumed by
the app and the `INTRODUCTION.md` book, `../SwiftQiskitPlaygrounds` for the playground pages
that build on it.

## Status & Roadmap

v0.8.1 — see `STATUSandTODO.md` for project status, what works, the core-library roadmap
(circuit visualization, noise models, performance work), and the fork's working TODO list.
