# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

SwiftQiskit is a lightweight, educational quantum-computing simulator written in pure Swift,
offering a Qiskit-like API. It is experimental (v0.2): the API is unstable and correctness is
prioritized over performance. This fork adds Xcode playground usage (`Playgrounds.playground`).

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
The SwiftUI front-end lives in the sibling `SwiftQiskitApp` repo, not in this package; there is
no `SwiftQiskitGUI` target here anymore (it was a duplicate, removed in favor of the app).
`SwiftQiskitViews` is a second, small library product (`import SwiftQiskitViews`) depending
only on `SwiftQiskit` — presentational types shared by `Playgrounds.playground` and by
`SwiftQiskitApp`, kept out of `SwiftQiskit` itself so Core stays UI-free.

## Architecture (bottom-up)

- `Math/Complex.swift` — value-type complex numbers (`+ - * /`, scalar mul, `.zero/.one/.i`).
- `Math/Matrix.swift` — row-major complex matrix; `* + -`, scalar mul (`Double`/`Complex`,
  either operand order), `multiply(by:)` (matrix × vector), `identity(size:)`, Kronecker
  product `tensor(_:)` / `⊗` (the `⊗` operator is declared here), `isUnitary(tolerance:)`
  (entrywise `U†U ≈ I`, since `==` compares exactly), `trace` (traps if non-square),
  `permutation(size:image:)` (builds a permutation matrix from a column→row map, trapping
  unless `image` is a bijection — the bijection check doubles as the unitarity check),
  `expm(terms:)` (matrix exponential via scaling-and-squaring Taylor series; no implicit
  `-i` — scale by `Complex(0, -theta)` yourself for e^(-iθH)).
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
- `Circuit/QuantumCircuit.swift` — records operations as full 2ⁿ×2ⁿ matrices, each tagged
  with the qubits it acts on (`private struct Operation { matrix; qubits }`, recorded via
  the private `record(_:actingOn:)` rather than the public `apply(_:)`, which — since an
  arbitrary caller-supplied matrix could touch any qubit — records all of them). This tag
  is what `runDensityMatrix(noise:)`/`runTrajectories(noise:shots:)` below use to place
  per-gate noise precisely. Single-qubit gates are embedded across the register via
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
  expectations). Replaces the entrywise Pauli-term accumulation page `18VQE` hand-rolls.
  `trotterCircuit(time:steps:order:)` is `QuantumCircuit(qubits:)` +
  `QuantumCircuit.evolve(_:time:steps:order:)` above. `commutingGroups() -> [[PauliString]]`
  partitions `terms` into qubit-wise-commuting groups via a greedy heuristic (Qiskit's
  default `group_commuting` strategy: each term joins the first existing group every member
  of which it's compatible with, else starts a new group) — used automatically by
  `measureExpectation(of: Hamiltonian, shots:)` above.
- `Quantum/ParameterShift.swift` — `ParameterShift.gradient(at:shift:_:)`: the
  parameter-shift rule generalized to any number of parameters and any `[Double] ->
  Double` cost closure (exact whenever every parameter is a single `exp(-iθP/2)` rotation's
  angle; default `shift: .pi/2` matches page `18VQE`'s one-parameter derivation), plus a
  `Hamiltonian`/`ansatz`-closure convenience overload. `GradientDescent.minimize(initial:
  learningRate:maxIterations:tolerance:cost:gradient:)` is a minimal fixed-step optimizer
  (no line search/momentum) defaulting its `gradient` to `ParameterShift.gradient`,
  returning a `Result` (`parameters`, `value`, `history`, `parameterHistory`, `iterations`,
  `converged`) — `parameterHistory[i]` is the parameter vector `history[i]` was evaluated
  at, so zipping the two gives the full optimization trajectory (e.g. page `15CHSH`'s and
  `18VQE`'s live charts).
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
  gate. Factories `bitFlip`/`phaseFlip`/`depolarizing`/`amplitudeDamping` (page `19Noise`'s
  four channels, same formulas) plus `phaseDamping` (new: pure T2 dephasing, no energy
  loss, unlike `amplitudeDamping`).
- `Quantum/NoiseModel.swift` — `NoiseModel`: `singleQubitGate`/`multiQubitGate`, each an
  optional single-qubit (2×2), trace-preserving `KrausChannel` applied independently to
  every qubit a gate of that arity touched (`init` traps on a bigger or non-trace-preserving
  channel). `.uniform(_:)` applies the same channel after both gate classes. Consumed by
  `QuantumCircuit.runDensityMatrix`/`runTrajectories` above.

## SwiftQiskitViews

`Sources/SwiftQiskitViews/` — a separate library product/module (`import SwiftQiskitViews`,
depends only on `SwiftQiskit`), holding presentational SwiftUI types shared by
`Playgrounds.playground` and by the sibling `SwiftQiskitApp` repo:

- `BlochVector.swift` — `BlochVector`: a single-qubit Bloch-sphere coordinate `(x, y, z)`,
  with `init(_:StateVector)` (pure state), `init(_:StateVector, qubit:)` (reduced/
  partial-trace qubit of a multi-qubit pure state), `init?(_:DensityMatrix)` (nil unless
  2×2 — via `DensityMatrix.blochVector`), `init(_:DensityMatrix, qubit:)` (reduced qubit via
  `partialTrace(keeping:)`), and `init(x:y:z:)` (raw coordinates, for `|r| < 1`); plus
  `magnitude`/`theta`/`phi`. Replaces the three previously hand-vendored copies
  (`Playgrounds.playground/Sources/BlochVector.swift`, `SwiftQiskitApp/BlochVector.swift`,
  and the app's `blochOf(_:Matrix)`).
- `CHSHChartView.swift` — `CHSHChartView`: a minimal, stateless `Canvas`-based 2D
  line/scatter chart, used by pages `15CHSH`/`18VQE`/`21Trotter`/`22Walk`. Moved here
  verbatim from `Playgrounds.playground/Sources/`.

## Xcode Playgrounds

`Playgrounds.playground` at the repo root (macOS target) is this fork's main addition: interactive,
lecture-style explorations of the library. Pages live in `Playgrounds.playground/Pages/`:

- `00TOC` — clickable table of contents (markdown only): links to every page with a
  one-line description, plus pointers to the `PlaygroundDocs/` guides. Pages are numbered with an
  ordering prefix (page order is alphabetical); follow this `NNName` naming when adding pages.
- `01Qubits` — first look at qubit states via the Dirac API, results-sidebar style
  (no prints): amplitudes, probabilities, `†`, inner/outer products, `⊗`; a live view
  showing `circuit1` (|0⟩ → H → P(π/2) → P(π)) and `circuit2` (|0⟩ → H → Z → H)
  stages on 2D Bloch spheres; plus a §7 basis-transformation preview of page
  `41BasisTransformations` §1–4 (the new basis kets as `T`'s columns via the column
  mapping, `T†` — the library's adjoint, not a hand-built row-of-bras — for the new
  amplitudes) (content provisional; formerly `02Lecture_01`)
  (user guide in `PlaygroundDocs/01QUBITSHELP.md`).
- `02Bloch2d`, `03Bloch2dProjection` — Bloch-sphere visualizations of single-qubit states
  via SwiftUI Canvas live views, built on the shared types in
  `Playgrounds.playground/Sources/`. Bloch math stays out of Core.
  (User guide for page 02 in `PlaygroundDocs/02BLOCH2DHELP.md`; user guide for page 03 — a general
  tilted state plus its x–y/z–y plane projections — in `PlaygroundDocs/03BLOCH2DPROJECTIONHELP.md`.
  The general live-view recipe and the shared `Sources/` module are documented in
  `PlaygroundDocs/90LIVEVIEWHELP.md`, not page-numbered since it isn't tied to one page.)
- `04Bloch3d` — rotatable 3D Bloch sphere (perspective-projected SwiftUI Canvas,
  no SceneKit/RealityKit) with live θ/φ sliders, via the shared `Bloch3DView` /
  `BlochExplorerView` (user guide in `PlaygroundDocs/04BLOCH3DHELP.md`).
- `05Gates` — a gentle, gate-by-gate tour of the built-in gate set in the results sidebar
  (no live view): `x/h/z/y/s/sdg/t/p/rx/ry/rz` each shown individually on a 1-qubit
  `QuantumCircuit`, plus a one-line `h`+`cx` Bell-state teaser pointing to
  `07Entanglement` (formerly `03Lecture_02`; user guide in `PlaygroundDocs/05GATESHELP.md`).
- `06Superposition` — a 4-qubit console walkthrough: every qubit put into superposition
  via `h`, inspecting the resulting 16-state amplitudes/probabilities and shot counts,
  plus a partial-superposition (2-qubit) contrast
  (user guide in `PlaygroundDocs/06SUPERPOSITIONHELP.md`).
- `07Entanglement` — annotated Bell-state walkthrough (circuit, state vector, probabilities,
  shots), plus a 3-qubit GHZ section showcasing the general `cx` across non-adjacent qubits
  (user guide in `PlaygroundDocs/07ENTANGLEMENTHELP.md`).
- `08Dirac` — Dirac-notation walkthrough (`Quantum/Dirac.swift`): inner/outer products,
  projectors, adjoints, and the page-04 initial qubit's Bloch coordinates as Pauli
  expectation values ⟨ψ|X|ψ⟩, ⟨ψ|Y|ψ⟩, ⟨ψ|Z|ψ⟩, shown on a static `Bloch3DView`
  (user guide in `PlaygroundDocs/08DIRACHELP.md`).
- `09Tensor` — tensor-product walkthrough (console only) mirroring
  `Tests/SwiftQiskitTests/TensorProductTests.swift` section by section: `Matrix`/
  `StateVector` `⊗`, the mixed-product identity, gate embedding vs. circuit `h(0)`, and
  why the Bell state does not factor (entanglement)
  (design notes in `PlaygroundDocs/09TENSORPLAN.md`, user guide in `PlaygroundDocs/09TENSORHELP.md`).
- `10DeutschExample` — Deutsch's algorithm (console only): the four 1-bit oracles from
  `x(1)`/`cx(0,1)`, a stage-by-stage phase-kickback walkthrough, a factorization check
  (page 09's `α₀₀·α₁₁ = α₀₁·α₁₀` criterion) confirming the register never entangles despite
  the `cx`, unlike page 07's Bell state, deterministic constant-vs-balanced verdicts from a
  single query, and shot statistics
  (plan in `PlaygroundDocs/10DEUTSCHPLAN.md`, user guide in `PlaygroundDocs/10DEUTSCHHELP.md`).
- `11GroverExample` — Grover's search (console only): CZ built as `h(1);cx(0,1);h(1)`,
  X-conjugated phase oracles, an inversion-about-the-mean walkthrough, exact 1-iteration
  success on 2 qubits, over-rotation, the diffusion operator as 2|s⟩⟨s|−I via the Dirac
  outer product, and a 3-qubit finale using a hand-built CCZ through `apply(_:)`
  (plan in `PlaygroundDocs/11GROVERPLAN.md`, user guide in `PlaygroundDocs/11GROVERHELP.md`).
- `12ShorExample` — compiled Shor factoring of 15 (console only): modular multiplication
  and its controlled powers as hand-built permutation matrices via `apply(_:)`, an
  entrywise 8×8 QFT† embedded with `⊗`, 3-qubit phase estimation of the order r,
  classical gcd post-processing, shots sampled from one `run()` (a see-through stand-in
  for what `measure(shots:)` now does internally, kept because it also gives the
  marginal-over-y summary the section wants), and a base sweep including the
  a = 14 failure case (plan in `PlaygroundDocs/12SHORPLAN.md`, user guide in `PlaygroundDocs/12SHORHELP.md`).
- `13Teleportation` — quantum teleportation and superdense coding: the payload prepared with
  `ry`/`rz`, Alice's Bell-basis rotation `cx(0,1); h(0)`, the four measurement branches
  recovered with Dirac projectors `(Ket("ab") * Bra("ab")) ⊗ I₂` (Core has no mid-circuit or
  partial measurement), the corrections applied by *deferred measurement* as `cx(1,2)` +
  CZ(0,2) so the register factors exactly as `|+⟩⊗|+⟩⊗|ψ⟩`, no-cloning read off the
  marginals, and superdense coding with the Bell basis's Gram matrix; live view of |ψ⟩, the
  four uncorrected branches and Bob's corrected state on the shared `BlochSphereView`
  (plan in `PlaygroundDocs/13TELEPORTATIONPLAN.md`, user guide in `PlaygroundDocs/13TELEPORTATIONHELP.md`).
- `14ErrorCorrection` — the 3-qubit bit-flip/phase-flip repetition code: `cx`-based encode
  and syndrome extraction onto two ancillas, a 32×32 permutation correction built from
  `ToffoliGate.matrix`/`MultiControlledXGate.matrix` (three X-conjugated Toffolis, one per
  syndrome branch, since the syndrome→qubit mapping is a 3-way conditional rather than a
  single Toffoli) and applied as one combined `Matrix` via `apply(_:)` — kept as a single
  operation rather than separate gate calls so a `NoiseModel` still sees it as one
  multi-qubit gate — an `rx(θ)` sweep showing a continuous error digitized
  to exact fidelity 1.0000 at every θ, the distance-3 failure mode (two errors alias to a
  wrong syndrome, giving a silent logical X) with the enumerated logical error rate
  p_L = 3p² − 2p³ — reproduced a second way, exactly (`runDensityMatrix`) and by Monte Carlo
  (`runTrajectories`), by driving the page's own circuit through a `KrausChannel.bitFlip`
  `NoiseModel` — and phase-flip protection via Hadamard conjugation (H Z H = X); Bloch
  live view of corrected vs. uncorrected q0
  (plan in `PlaygroundDocs/14ERRORCORRECTIONPLAN.md`, user guide in `PlaygroundDocs/14ERRORCORRECTIONHELP.md`).
- `15CHSH` — the CHSH inequality: all 16 deterministic local-hidden-variable strategies
  enumerated exhaustively (max |S| = 2), plus a shared-direction hidden-variable model that
  saturates the bound and doubles as the classical comparison curve; the tilted observable
  A(θ) = cos θ·Z + sin θ·X built with `Matrix`'s scalar `*`/`+` operators and measured via
  `ry(-θ)` with its sign pinned against the exact expectation value; correlators computed
  both exactly (`state† * (A(a) ⊗ A(b)) * state`) and via `measure(shots:)`; a Bell pair's
  S = 2√2 against a product-state control; and a genuine multi-angle search over all four
  CHSH settings via `ParameterShift.gradient`/`GradientDescent.minimize` — E(x,y) = cos(x−y)
  for this Bell state fits the parameter-shift rule's exactness condition exactly, and three
  fixed starting points all converge to S = 2.8284…, matching 2√2 (Tsirelson's bound); a
  `CHSHChartView`
  live chart of the violation (plan in `PlaygroundDocs/15CHSHPLAN.md`, user guide in
  `PlaygroundDocs/15CHSHHELP.md`).
- `16QFT` — the quantum Fourier transform as a gate circuit (console only): a controlled
  phase CP(θ) derived from `p`+`cx` (`p(θ/2,c); cx(c,t); p(-θ/2,t); cx(c,t); p(θ/2,t)`), the
  QFT ladder checked against page 12's entrywise DFT to ~1e-15, a no-swap bit-reversal
  demonstration, the inverse QFT with a unitarity check, and standalone phase estimation —
  exact for dyadic phases, spread otherwise, with a precision comparison at 3 vs. 6 counting
  qubits (plan in `PlaygroundDocs/16QFTPLAN.md`, user guide in `PlaygroundDocs/16QFTHELP.md`).
- `17DeutschJozsa` — Deutsch–Jozsa and Bernstein–Vazirani (console only): page 10's circuit
  generalized to n input qubits, `cx`-built constant/balanced oracles, a deterministic
  all-zero-vs-not verdict from one query, a `measure(shots:)` gotcha (the ancilla's bit is
  random; only the input bits are deterministic), Bernstein–Vazirani recovering a hidden
  n-bit string from the identical circuit, and a query-count table showing the classical
  cost growing exponentially (DJ) or linearly (BV) while the quantum cost stays at 1 (plan in
  `PlaygroundDocs/17DEUTSCHJOZSAPLAN.md`, user guide in `PlaygroundDocs/17DEUTSCHJOZSAHELP.md`).
- `18VQE` — the variational quantum eigensolver: an H₂ qubit Hamiltonian (Jordan–Wigner,
  minimal basis) built from six Pauli terms combined with `Matrix`'s `+`/scalar `*`, a
  one-parameter ansatz
  `x(0); ry(θ,1); cx(1,0)` provably confined to the `{|01⟩,|10⟩}` subspace, the energy via
  `psi† * H * psi`, a closed-form 2×2 eigenvalue for grading, *exact* parameter-shift
  gradients pinned against a finite difference, gradient descent converging to error
  0.00e+00, and a live chart of the E(θ) landscape with the optimizer's own path, on the
  shared `CHSHChartView` (plan in `PlaygroundDocs/18VQEPLAN.md`, user guide in `PlaygroundDocs/18VQEHELP.md`).
- `19Noise` — open systems, built on Core's `DensityMatrix`/`KrausChannel` (originally
  hand-rolled entrywise; retrofitted once those Core types landed): the density matrix
  ρ = |ψ⟩⟨ψ| via `DensityMatrix(_:)` (itself the existing `Ket * Bra` outer product); a
  classical mixture vs. a superposition at identical Z-statistics; the four `KrausChannel`
  channels (bit-flip, phase-flip, depolarizing, amplitude damping) checked for trace
  preservation via `isTracePreserving()`; coherence decaying exactly as `(1-2p)ⁿ`; amplitude
  damping pulling the Bloch vector *inside* the sphere; a Monte-Carlo unraveling reproducing
  the exact channel from pure-state code alone; and a Bell pair's reduced state
  (`DensityMatrix.partialTrace(keeping:)`) giving entropy exactly 1 bit
  (`.vonNeumannEntropy`) against a product state's 0; live Bloch gallery shrinking from pure
  to fully depolarized, via the additive `BlochVector.init(x:y:z:)`
  (plan in `PlaygroundDocs/19NOISEPLAN.md`, user guide in `PlaygroundDocs/19NOISEHELP.md`).
- `20Tomography` — reconstructing a state from `measure(shots:)` alone: basis rotations
  (`h` for X, `sdg;h` for Y) pinned against a known Y-eigenstate rather than assumed; the
  estimator's 1/√N error scaling; the sharper-than-expected result that a *pure* state's
  per-axis reconstruction lands outside the Bloch ball about half the time at *any* N (only a
  genuinely mixed state's frequency, page 19's territory, shrinks toward zero); a Bell pair's
  marginal reconstructed from shots alone; and the 3ⁿ-settings cost table motivating page 18's
  per-term Pauli measurements; live view of the true vs. reconstructed Bloch point
  (plan in `PlaygroundDocs/20TOMOGRAPHYPLAN.md`, user guide in `PlaygroundDocs/20TOMOGRAPHYHELP.md`).
- `21Trotter` — Hamiltonian simulation of a transverse-field Ising chain: `Matrix.expm()`
  self-checked against `RXGate`; the exact gate identity
  `exp(-iθ·Z⊗Z/2) = cx(0,1); rz(θ,1); cx(0,1)` derived from `RZGate` and checked against
  `expm()`; first- and second-order Trotter error shrinking at the textbook
  O(1/n)/O(1/n²) rates, both at the operator level and the observable level (⟨Z₀⟩(t)); and the
  non-zero commutator `[Z⊗Z, X⊗I]` identified as the error's source (a commuting-only
  Hamiltonian is exact at n=1); live chart of the exact curve against Trotterized samples on
  the shared `CHSHChartView` (plan in `PlaygroundDocs/21TROTTERPLAN.md`, user guide in
  `PlaygroundDocs/21TROTTERHELP.md`).
- `22Walk` — the discrete-time coined quantum walk on a 16-site cycle (no Core changes): a
  conditional-shift permutation built from `increment`/`decrement` on the position register
  (cross-checked for exact equality against the earlier hand-built version) and confirmed
  unitary; ballistic (∝t) spreading
  against an exactly diffusive (∝√t) classical random walk; a caught-and-documented
  cyclic-coordinate variance bug (raw site indices vs. signed offsets from the start); and the
  `|0⟩`-vs-`|+i⟩` coin contrast showing the walk's asymmetry is interference, not a flaw; live
  chart of both final distributions on the shared `CHSHChartView`, with cross-references to
  Grover (page 11) and Hamiltonian simulation (page 21)
  (plan in `PlaygroundDocs/22WALKPLAN.md`, user guide in `PlaygroundDocs/22WALKHELP.md`).
- `40ComplexAndMatrices` — first of the `40+` pages, numbered separately because they
  accompany chapters of the SwiftQiskitApp `INTRODUCTION.md` book rather than continuing the
  01–22 sequence above: every code fragment from that book's Chapter 2, in order —
  `Complex` construction/`*`/`/`/conjugate/magnitude, the Born rule, phase via Euler's
  formula, plain `[Complex]` vector helpers, inner products and normalization, `Matrix` as a
  transformation and why multiplication order matters, unitarity and why exact `==` lies on
  `H`, and the tensor product `⊗` (no live view, no companion `PlaygroundDocs/` guide).
- `41BasisTransformations` — standalone, not tied to a book chapter (console only):
  expressing |ψ⟩ in a different basis by building the change-of-basis matrix `T` from the
  new basis kets as columns, constructing `T†` by hand as the stack of the new bras
  (`Bra(_:).amplitudes`) and checking it against `Matrix.adjoint`, reading off the new
  amplitudes as inner products `⟨bⱼ|ψ⟩`, the {|+⟩, |−⟩} case reducing exactly to `H`, why
  the complex {|+i⟩, |−i⟩} case needs the conjugate transpose and not a plain one (a plain
  transpose silently swaps `|+i⟩`'s probabilities and fails the unitarity check), and
  measuring in the new basis via `h`/`sdg;h` before an ordinary `measure(shots:)`
  (user guide in `PlaygroundDocs/41BASISTRANSFORMATIONSHELP.md`).

Playground notes:

- Pages `import SwiftQiskit` (and, on the twelve pages that use `BlochVector`/
  `CHSHChartView`, `import SwiftQiskitViews`) and set `buildActiveScheme='true'`, so the
  **active scheme must build both products** for pages to run — use the
  `SwiftQiskit-Package` scheme (or the autogenerated `SwiftQiskitViews` scheme), not the
  per-product `SwiftQiskit` scheme, so `SwiftQiskitViews` actually gets built; keep both
  targets compiling at all times.
- Pages are linked sequentially with `//: [Previous](@previous)` / `//: [Next](@next)` markers.
- Code shared by multiple pages lives in `Playgrounds.playground/Sources/` — an auxiliary
  module auto-imported by every page; declarations there must be `public` (including
  explicit `public init`s). `BlochVector`/`CHSHChartView` moved out of here into the
  `SwiftQiskitViews` package target (see "SwiftQiskitViews" above) — the `Sources/` files
  that use them (`Bloch3DView`, `BlochExplorerView`, `BlochSphereView`) now
  `import SwiftQiskitViews` explicitly. See `PLAYGROUNDSUPPORT.md` for the conventions and
  current API, and `PlaygroundDocs/90LIVEVIEWHELP.md` for the user-facing guide (usage
  snippets, the live-view recipe, troubleshooting).
- Playground code is not covered by tests or `swift build`; it only runs inside Xcode.
- **Xcode 27 beta (confirmed present through beta 5, 27A5237l, 2026-08-23):**
  two evaluator bugs break SwiftUI pages — a missing `libcups.dylib` (needs a shim in
  DerivedData, wiped by ordinary run/build activity on beta 5, not just Clean Build
  Folder — re-copy immediately before each run) and `@State` macro expansion failing in
  page code (stateful views must live in `Sources/`). A page that looks fixed after an
  untouched rerun may just be reusing a stale build — only a freshly recompiled page run
  is a valid test. Workarounds and the shim recipe are in `PLAYGROUNDSUPPORT.md`
  § "Xcode 27 beta workarounds".

## Conventions & Gotchas

- **Qubit indexing:** qubit 0 is the most-significant (leftmost) bit.
- **`cx`/`ccx`/`mcx` are general:** `cx(control, target)`/`ccx(control1, control2, target)`/
  `mcx(controls, target)` work for any distinct qubits on an n-qubit circuit, via
  `CNOTGate.matrix(qubits:control:target:)`/`ToffoliGate.matrix(qubits:control1:control2:target:)`/
  `MultiControlledXGate.matrix(qubits:controls:target:)` (all permutation-matrix construction).
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
  `KrausChannelTests.swift`, `NoiseModelTests.swift`). `Tests/SwiftQiskitViewsTests/`
  (`BlochVectorTests.swift`, `CHSHChartViewTests.swift`) tests the `SwiftQiskitViews`
  module above.
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

## Status & Roadmap

v0.2 — see `STATUSandTODO.md` for project status, what works, the core-library roadmap
(circuit visualization, noise models, performance work), and the fork's working TODO list.
