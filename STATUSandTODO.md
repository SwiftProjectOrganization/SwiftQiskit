# Status and TODO

Project status, feature status, and the core-library roadmap for SwiftQiskit,
plus this fork's working TODO list.

## Project Status

**SwiftQiskit is currently in an early experimental stage (v0.2).**

- Core quantum simulation is implemented
- API is subject to change
- Performance is not yet optimized
- GUI tools are available in separate projects or through the template system
- An extensive set of playgrounds is included in /Playgounds and documented in /PlaygroundDocs

The project is actively evolving, and major features are planned.

## Prioritized TODO (2026-09-27)

A short, prioritized list of what's actually left, pulled from the detailed sections below
(each of which stays as history/design-rationale). Check those sections for the "why" behind
any item here.

**P1 — doc drift (quick, do first)**
- [x] Fix stale "no Toffoli" claims now that `ToffoliGate`/`ccx` exist: the `14ErrorCorrection`
      page comment and `CLAUDE.md`'s page-14 entry (both updated to note the retrofit is open
      rather than impossible); `PlaygroundDocs/14ERRORCORRECTIONHELP.md`'s explanation likewise.
- [x] `PlaygroundDocs/21TROTTERHELP.md`: add the callout noted under "Proposed Core extensions
      — Hamiltonian simulation" below (reversing a Trotter step's layer order gives an
      identical error curve, to floating-point precision, at every step count).

**P2 — page retrofits onto Core helpers that have already landed**
(see "Suggested implementation sequence" below for the full checklist this summarizes)
- [x] `18VQE`: `Hamiltonian`/`PauliString` for the H₂ Hamiltonian, `Hamiltonian.expectation(_:)`
      for the energy, `ParameterShift.gradient`/`GradientDescent.minimize` for the optimizer loop.
- [x] `21Trotter`: page-level `trotterUnitary` → `Hamiltonian` + `trotterCircuit`/`evolve`.
- [x] `20Tomography`: page-level `estimate`/`estimateQubit0` → `StateTomography.estimate`/
      `estimateBlochVector` (the mixed-ensemble section's per-shot re-preparation still needs
      its own loop).
- [x] `11GroverExample`, `22Walk`: hand-rolled marginal loop-and-sum →
      `StateVector.marginalProbabilities`/`SimulationResult.marginalCounts` (only `22Walk` had
      one to retrofit; see the detailed checklist below).
- [x] `12ShorExample`, `14ErrorCorrection`: hand-built permutations that are really
      controlled-controlled flips → `ToffoliGate`/`ccx` (only `14ErrorCorrection` had one to
      retrofit — see the detailed checklist below).
- [x] (Low priority) `22Walk`: express `buildShift` via `increment`/`decrement` instead of a
      hand-built permutation. Done — the position register (q1..q4) is exactly a 4-bit counter
      on the 16-site cycle, so the shift is a controlled ±1 on it; `appendShift(to:)` builds it
      from `decrement(register:controlledBy:)` (coin 1) and `increment` flipped around `x(0)`
      (coin 0), with the matrix reconstructed column-by-column via `run()` (no
      `QuantumCircuit` → `Matrix` accessor exists). Cross-checked for exact equality against the
      original `Matrix.permutation` construction (kept as `referenceShift`) — no floating-point
      tolerance needed, since every gate involved only ever permutes basis amplitudes.

**P3 — new Core features**
- [x] A shared, UI-free-Core-preserving `SwiftQiskitViews` module for `CHSHChartView` and a
      single package-level `BlochVector`, replacing the hand-vendored copies in the playground
      and in `SwiftQiskitApp` (see "Proposed Core extensions — open systems" below for why this
      is deliberately *not* a `SwiftQiskit`-namespaced type). Done — a new `SwiftQiskitViews`
      library product/target (`Sources/SwiftQiskitViews/`, depends only on `SwiftQiskit`),
      tagged `0.2.0`. `BlochVector` gains `DensityMatrix`-driven initializers
      (`init?(_:DensityMatrix)`, `init(_:DensityMatrix, qubit:)`) alongside the two
      `StateVector` ones and the raw `init(x:y:z:)`; `CHSHChartView` moved verbatim.
      `Playgrounds.playground/Sources/BlochVector.swift`/`CHSHChartView.swift` are deleted;
      every page/`Sources/` file that used either type now `import SwiftQiskitViews`.
      `SwiftQiskitApp`'s own `BlochVector.swift` is deleted too, retargeted onto the same
      module, and its package dependency bumped to `0.2.0`. Tested in
      `Tests/SwiftQiskitViewsTests/` (`BlochVectorTests.swift`: pure-state, reduced,
      `DensityMatrix`-driven, and raw-coordinate agreement checks; `CHSHChartViewTests.swift`:
      instantiation smoke test).
- [x] A permutation-aware fast path in `StateVector.apply(_:)` — the first concrete step under
      "Performance optimizations" below; every walk step, Shor's modular multiplication, and
      the error-correction syndrome fix are permutation matrices today paying for a full dense
      multiply. Done — `Matrix.permutationImage: [Int]?` (internal; `Math/Matrix.swift`)
      detects an *exact* permutation (0/1 entries, bijective) via cheap comparisons that bail
      out on the first entry ruling it out, so a genuinely dense gate (H, RX/RY/RZ, a
      Trotter-step matrix) pays almost nothing extra; `apply(_:)` uses it for an O(2ⁿ) reindex
      instead of the O(4ⁿ) dense multiply. Tested in `PermutationFastPathTests.swift`
      (detection against `cx`/`ccx`/`mcx` truth tables, rejection of dense gates/non-square/
      non-bijective 0-1 matrices, and bit-for-bit agreement between the fast and dense paths).
- [x] Commuting-term grouping for `Hamiltonian.trotterCircuit`/`QuantumCircuit.evolve` and for
      `measureExpectation(of: Hamiltonian, shots:)` (currently one `pauliRotation`/measurement
      per term, caller-ordered). Done, in two different ways per consumer (see "Proposed Core
      extensions — variational"/"— Hamiltonian simulation" below for the split reasoning):
      `measureExpectation(of: Hamiltonian, shots:)` now groups and measures automatically
      (`Hamiltonian.commutingGroups()`, built on new `PauliString.isQubitWiseCommuting(with:)`
      — H₂'s six terms group into three settings); `evolve`/`trotterCircuit` keep their
      existing term order by default (reordering changes the *finite-step* Trotter error, and
      `TrotterTests.swift`/page `21Trotter` already pin numbers against the current order) —
      `commutingGroups()` is available for a caller who wants to opt into a grouped layering.
      Tested in `CommutingGroupsTests.swift` (the grouping algorithm itself: QWC pairwise
      checks, the H₂ 3-group case, an all-commuting collapse, a pairwise-conflicting
      singleton case, and partition/determinism invariants on a 15-term synthetic
      Hamiltonian), `MeasureExpectationTests.swift` (a hand-picked shared-batch correctness
      check plus convergence to the exact value), and `TrotterTests.swift` (grouping doesn't
      break convergence, and — verified numerically before writing the assertion — is never
      worse than a scrambled order at a fixed step count, for this example).
- [ ] A real linear-inversion or maximum-likelihood state tomography reconstruction, beyond
      `StateTomography`'s per-axis estimate + physicality clamp.
- [x] `15CHSH`: a genuine multi-angle search over all four CHSH settings confirming Tsirelson's
      bound, rather than today's single-setting sweep. Done — reuses page 18's
      `ParameterShift`/`GradientDescent` rather than a hand-rolled grid search: `E(x,y) =
      cos(x−y)` for this Bell state, so gradient ascent on S is exact, and three fixed generic
      starting points all converge to 2√2 (verified against a hand-derived analytic gradient
      first, which caught a sign error before trusting the page code).

**P4 — longer horizon**
- [ ] General performance work: apply gates directly to state-vector amplitudes instead of
      building full 2ⁿ×2ⁿ operation matrices (the permutation fast path above is the first slice
      of this).
- [ ] Mid-circuit / partial measurement — pages `13Teleportation` and `14ErrorCorrection` both
      route around its absence today (deferred measurement, hand-built permutation corrections).
- [ ] Stable public API (v1.0) — a deliberate breaking-change review pass, keeping `API.md` in
      sync as it happens rather than after.

**SwiftQiskitApp (separate repo — tracked here only for sequencing against Core work above)**
Signed θ range (no Core dependency) → Toffoli tile (unblocked by `ccx`) → marginal/grouped
`ResultsView` (unblocked by `marginalProbabilities`/`marginalCounts`) → Energy panel (unblocked
by `Hamiltonian`/`measureExpectation`) → density-matrix/noise views (unblocked by
`DensityMatrix`/`KrausChannel`/`NoiseModel`) → adopt the shared `SwiftQiskitViews` module
(done — see P3 item 1 above; the app's package dependency now pins `0.2.0` and its own
`BlochVector.swift` is gone).

## What Works (v0.2)

- QuantumCircuit abstraction
- Single-qubit gates: H, X, Y, Z, S, S†, T, T†, the general phase gate P(θ), and
  rotations RX(θ)/RY(θ)/RZ(θ) — circuit methods `h/x/y/z/s/sdg/t/tdg/p/rx/ry/rz`
  (tested in `AdditionalGatesTests.swift`)
- General multi-qubit CNOT: `cx(control, target)` for any distinct pair of qubits
  (`CNOTGate.matrix(qubits:control:target:)`, tested in `CNOTTests.swift`)
- StateVector simulation
- Measurement with shots & counts
- Tensor (Kronecker) products: `tensor(_:)` / `⊗` on `Matrix` and `StateVector`
  (see `PlaygroundDocs/09TENSORPLAN.md` and the user guide `PlaygroundDocs/09TENSORHELP.md`)
- Matrix arithmetic: `+ -` and scalar multiply (`Double`/`Complex`, either operand order) on
  `Matrix` (`Math/Matrix.swift`, tested in `MatrixArithmeticTests.swift`)
- Dirac notation: `Ket`/`Bra`, postfix `†`, inner/outer products
  (`Quantum/Dirac.swift`, demonstrated in playground page `08Dirac`;
  user guide `PlaygroundDocs/08DIRACHELP.md`)
- Bell State example
- Unit tests for correctness
- `SwiftQiskitViews`: a shared, UI-free-Core-preserving SwiftUI library (`BlochVector`,
  `CHSHChartView`) used by both `Playgrounds.playground` and `SwiftQiskitApp`
  (`Sources/SwiftQiskitViews/`, tested in `Tests/SwiftQiskitViewsTests/`)

## Roadmap

- [x] General multi-qubit CNOT support
- [x] Additional gates (Y, Phase, Rotation gates)
      → `Gates/PauliY.swift`, `Gates/Phase.swift` (P(θ), S, S†, T, T†),
      `Gates/Rotation.swift` (RX/RY/RZ); circuit API `y/s/sdg/t/tdg/p/rx/ry/rz`,
      tested in `AdditionalGatesTests.swift`
- [x] Noise models — first addressed at the playground-example level (page `19Noise` builds
      Kraus channels — bit-flip, phase-flip, depolarizing, amplitude damping — as page-level
      `Matrix` operations), now a first-class Core feature too: `DensityMatrix`, `KrausChannel`
      (the same four channels plus a new `phaseDamping`), `NoiseModel`, and
      `QuantumCircuit.runDensityMatrix(noise:)`/`runTrajectories(noise:shots:)` — see "Proposed
      Core extensions — open systems" below for details. Page `19Noise` has since been
      retrofitted onto the Core types directly — see "Suggested implementation sequence" below.
- [x] `SimulationResult.parityExpectation(qubits:)` — a ±1 parity-product average over
      `counts` (one qubit position per factor, 0→+1/1→−1). Would replace the
      `sampledCorrelator` boilerplate in page `15CHSH` and would likely also simplify
      page `18VQE`'s ZZ-term measurement and page `20Tomography`'s shot-based estimators.
      Implemented in `Quantum/SimulationResult.swift` alongside `marginalCounts(over:)`;
      tested in `ReadoutTests.swift`. Pages `15CHSH` and `20Tomography` have since been
      retrofitted onto it directly (see the retrofit checklist further below); `18VQE`'s own
      ZZ-term measurement is still open.
- [x] `StateVector.expectation(_ observable: Matrix) -> Double` wrapping
      `(self† * observable * self).real` — bumped up from low priority: four independent app
      chapters (21, 22, 23, 24) now hand-roll this exact three-line idiom under their own
      `expectationZ0`/`energy`-style wrapper names, so it's cheap and no longer marginal. Also
      listed under "Proposed Core extensions — open systems" and "— variational" below.
      Implemented in `Quantum/Dirac.swift`; tested in `DiracNotationTests.swift`.
- [x] Page `15CHSH`: extend the Tsirelson-bound check from a sweep over one setting (b, with
      a, a′ fixed) to a genuine multi-angle search over all four settings, if a true
      confirmation of the bound (rather than a consistency check) is wanted. Done — see the
      P3 checklist above for the implementation.
- [x] `QuantumCircuit.measure(shots:)` runs the circuit once and samples the resulting
      `probabilities` `shots` times, instead of calling `runAndMeasure()` (which replays every
      recorded operation via `run()`) once per shot — only the final random draw differs shot
      to shot for a full measurement of a pure state. The shared cumulative-probability sampler
      moved to `StateVector.sampleIndex(from:)`, used by both this and `StateVector.measure()`.
      Tested in `MeasurementTests.swift`, including a regression check against the old
      replay-per-shot behavior. Pages 12 and 13's own local samplers (added to route around the
      old cost) are kept as see-through stand-ins and updated to say so.
- [ ] Performance optimizations — first slice done: a permutation-aware fast path in
      `StateVector.apply(_:)` (see "Proposed Core extensions — open systems" below); applying
      gates directly to amplitudes instead of building full 2ⁿ×2ⁿ operation matrices remains open.
- [ ] Stable public API (v1.0)

## Bloch sphere playground pages (this fork)

- [x] Try a 3D Bloch sphere (e.g. SceneKit/RealityKit or a perspective-projected
      SwiftUI Canvas) as an alternative to the current 2D projections in
      `Playgrounds.playground/Sources/BlochSphereView.swift`.
      → `Bloch3DView` (perspective-projected SwiftUI Canvas with drag-to-orbit),
      used by page `04Bloch3d`.
- [x] Add constrained live sliders for the spherical angles θ and φ to the
      Bloch sphere live display (θ ∈ [0, π], φ ∈ [0, 2π)), updating the
      rendered state vector interactively.
      → page `04Bloch3d`; the θ/φ parametrization keeps |α|² + |β|² = 1
      for every slider position, so the two sliders are independent.
- [x] User guide for the 2D Bloch sphere page — `PlaygroundDocs/02BLOCH2DHELP.md`: the Bloch map
      α, β → (x, y, z), page walkthrough, exact expected output, and how the oblique
      projection reads.
- [x] User guide for the playground's shared code and live views —
      `PlaygroundDocs/90LIVEVIEWHELP.md` (not page-numbered): the `Sources/` module mechanics, an
      at-a-glance table of all six shared types (including the non-view `BlochVector`),
      the general live-view recipe (explicit root frame, stateless-inline vs.
      `@State`-in-`Sources/`), and consolidated troubleshooting — deduplicating what was
      previously repeated across `01QUBITSHELP.md`/`02BLOCH2DHELP.md`/
      `03BLOCH2DPROJECTIONHELP.md`/`04BLOCH3DHELP.md`.
- [x] User guide for the tilted-qubit/plane-projection page —
      `PlaygroundDocs/03BLOCH2DPROJECTIONHELP.md`: the direction-cosine derivation of θ/φ, exact
      expected console output for the round-trip check, and how to read the two
      `BlochProjectionView` panels (including why the x–y panel flips its vertical axis).
- [x] User guide for the 3D Bloch sphere page — `PlaygroundDocs/04BLOCH3DHELP.md`: the θ/φ
      parametrization and why its two sliders are independent, exact expected console
      output, the orbit-camera/perspective-projection model behind `Bloch3DView`
      (near/far wireframe opacity, silhouette scaling, drag-to-orbit), and how the page's
      starting state matches page `08Dirac`'s initial qubit.
- [x] The `SwiftQiskitGUI` target (this package's own SwiftPM-executable UI) was removed. It had
      drifted behind `SwiftQiskitApp` — which has the Bloch-sphere `BlochDisplayView`, the
      measurement-model refactor, and several views the package copy lacked — with no upside to
      maintaining two UIs. `SwiftQiskitApp` is now the only SwiftUI front-end for this package.

## Bra/ket & tensor-product additions (this fork)

- [x] First-look Dirac walkthrough — page `01Qubits`: qubit states via the Dirac API in
      the results sidebar (no prints), plus circuit stage tracking shown live on 2D
      Bloch spheres, with the user guide `PlaygroundDocs/01QUBITSHELP.md`.
- [x] Dirac notation in Core (`Quantum/Dirac.swift`): `Ket`/`Bra`, postfix `†`,
      inner/outer products, basis kets — with `DiracNotationTests.swift`,
      playground page `08Dirac` (Pauli expectation values on a `Bloch3DView`),
      and the user guide `PlaygroundDocs/08DIRACHELP.md`.
- [x] Tensor (Kronecker) products in Core: `tensor(_:)` / `⊗` on `Matrix` and
      `StateVector`; `QuantumCircuit` gate embedding now reuses `Matrix.tensor(_:)`
      — with `TensorProductTests.swift`, playground page `09Tensor`, the
      design notes in `PlaygroundDocs/09TENSORPLAN.md`, and the user guide `PlaygroundDocs/09TENSORHELP.md`.
- [x] Matrix arithmetic in Core (`Math/Matrix.swift`): `+`, `-`, and scalar multiply
      (`Matrix * Double`/`Complex`, either operand order) — closing a gap several pages had
      previously routed around with page-level helpers (`19Noise`'s `addM`/`scaleM`, `21Trotter`'s
      `addM`/`scaleM`, `18VQE`'s and `15CHSH`'s entrywise term accumulation). Tested in
      `MatrixArithmeticTests.swift`. `19Noise`, `21Trotter`, `18VQE`, and `15CHSH` have all
      since been retrofitted onto the operators directly (see the item just below for
      `21Trotter`/`18VQE`).
- [x] Retrofit pages `21Trotter` (`addM`/`scaleM`) and `18VQE` (its entrywise Hamiltonian loop) to
      use the `Matrix` `+`/scalar-`*` operators directly, the same modernization the
      `SwiftQiskitApp` book's Chapters 23 and 24 already made for their own copies of this code
      (`~/Documents/SwiftQiskit-Chapter23-VQE-Extensions.md`,
      `-Chapter24-Trotter-Extensions.md`). Done — `21Trotter`'s `addM`/`scaleM` are retired
      (`maxDiff` remains; no `Matrix` equivalent exists for it), and `18VQE`'s entrywise loop is
      now one `terms.reduce(...) { $0 + $1.coefficient * $1.matrix }`.

## Gate-tour and entanglement playground pages (this fork)

- [x] Gate-by-gate tour — page `05Gates`: every built-in gate
      (`x/h/z/y/s/sdg/t/p/rx/ry/rz`) shown individually on a 1-qubit `QuantumCircuit`,
      plus a one-line `h`+`cx` Bell-state teaser, with the user guide
      `PlaygroundDocs/05GATESHELP.md`.
- [x] 4-qubit superposition — page `06Superposition`: every qubit put into
      superposition via `h`, 16-state amplitude/probability/shot inspection, and a
      partial-superposition contrast, with the user guide `PlaygroundDocs/06SUPERPOSITIONHELP.md`.
- [x] Entanglement walkthrough — page `07Entanglement`: the Bell state via `h`+`cx`
      with full amplitude/probability/measurement annotation, plus a 3-qubit GHZ
      state using `cx` across non-adjacent qubits, with the user guide
      `PlaygroundDocs/07ENTANGLEMENTHELP.md`.

## Algorithm playground pages (this fork)

Walkthroughs of the canonical quantum algorithms and protocols, each with design
notes (`PlaygroundDocs/*PLAN.md`) and a user guide (`PlaygroundDocs/*HELP.md`). Pages 10–12 are console-only;
page 13 adds a Bloch-sphere live view:

- [x] Deutsch's algorithm — page `10DeutschExample`: the four 1-bit oracles from
      `x(1)`/`cx(0,1)`, phase kickback stage by stage, and deterministic
      constant-vs-balanced verdicts from a single query
      (`PlaygroundDocs/10DEUTSCHPLAN.md`, `PlaygroundDocs/10DEUTSCHHELP.md`).
- [x] Grover's search — page `11GroverExample`: CZ built as `h(1); cx(0,1); h(1)`,
      X-conjugated phase oracles, inversion about the mean, the diffusion operator
      as 2|s⟩⟨s| − I via the Dirac outer product, and a 3-qubit finale with a
      hand-built CCZ (`PlaygroundDocs/11GROVERPLAN.md`, `PlaygroundDocs/11GROVERHELP.md`).
- [x] Shor's algorithm (compiled, N = 15) — page `12ShorExample`: modular
      multiplication and its controlled powers as hand-built permutation matrices,
      an entrywise 8×8 QFT† embedded with `⊗`, 3-qubit phase estimation of the
      order r, classical gcd post-processing, and a base sweep including the
      a = 14 failure case (`PlaygroundDocs/12SHORPLAN.md`, `PlaygroundDocs/12SHORHELP.md`).
- [x] Teleportation & superdense coding — page `13Teleportation`: entanglement as a
      communication resource; Bell-basis measurement branches via Dirac projectors
      `(Ket("ab") * Bra("ab")) ⊗ I₂`, the corrections applied through the
      deferred-measurement principle (`cx(1,2)` + CZ(0,2)) so the register factors exactly
      as `|+⟩⊗|+⟩⊗|ψ⟩`, no-cloning read off the marginals, and two classical bits carried
      by one qubit; Bloch-sphere live view of every branch
      (`PlaygroundDocs/13TELEPORTATIONPLAN.md`, `PlaygroundDocs/13TELEPORTATIONHELP.md`).
- [x] 3-qubit error correction — page `14ErrorCorrection`: `cx`-based encode and syndrome
      extraction onto two ancillas, a hand-built 32×32 permutation correction via
      `apply(_:)`, an `rx(θ)` sweep showing continuous errors digitized to exact fidelity
      1.0000 at every θ, the distance-3 failure mode with the enumerated logical error rate
      p_L = 3p² − 2p³, and phase-flip protection via Hadamard conjugation
      (`PlaygroundDocs/14ERRORCORRECTIONPLAN.md`, `PlaygroundDocs/14ERRORCORRECTIONHELP.md`).
- [x] CHSH inequality — page `15CHSH`: all 16 deterministic local-hidden-variable strategies
      enumerated exhaustively (max \|S\| = 2) plus a shared-direction model that saturates
      the bound, the tilted observable A(θ) = cos θ·Z + sin θ·X built with `Matrix`'s scalar
      `*`/`+` operators and measured via `ry(-θ)` with the sign pinned against the exact
      expectation value, correlators computed both exactly (the Dirac `state† * M * state`
      idiom) and via `measure(shots:)`, a Bell pair's S = 2√2 against a product-state control
      and a sweep over the second setting consistent with Tsirelson's bound, and a
      `CHSHChartView` live chart
      (`PlaygroundDocs/15CHSHPLAN.md`, `PlaygroundDocs/15CHSHHELP.md`).
- [x] The QFT gate decomposition — page `16QFT`: a controlled phase CP(θ) derived from
      `p`+`cx`, the QFT ladder (Hadamards, CP cascade, swap network) checked against page
      12's entrywise matrix to ~1e-15, a no-swap bit-reversal demonstration, the inverse QFT
      with a unitarity check, and standalone phase estimation — exact for dyadic phases,
      spread otherwise, with precision improving at more counting qubits
      (`PlaygroundDocs/16QFTPLAN.md`, `PlaygroundDocs/16QFTHELP.md`).
- [x] Deutsch–Jozsa and Bernstein–Vazirani — page `17DeutschJozsa`: page 10's one-query
      circuit generalized to n input qubits, `cx`-built constant/balanced oracles, a
      deterministic verdict, a `measure(shots:)` gotcha about the ancilla's free bit,
      Bernstein–Vazirani recovering a hidden n-bit string from the identical circuit, and a
      query-count table contrasting the classical exponential/linear costs against the
      quantum constant of 1 (`PlaygroundDocs/17DEUTSCHJOZSAPLAN.md`, `PlaygroundDocs/17DEUTSCHJOZSAHELP.md`).

## Variational (NISQ-era) playground page (this fork)

- [x] VQE — page `18VQE`: the first page where the circuit isn't fixed in advance. An H₂
      qubit Hamiltonian (Jordan–Wigner, minimal basis) built from six Pauli terms combined
      with `Matrix`'s `+`/scalar `*`, a one-parameter ansatz confined to the `{|01⟩,|10⟩}`
      subspace, the energy via page 08's
      `psi† * H * psi`, a closed-form 2×2 eigenvalue for grading, exact parameter-shift
      gradients pinned against a finite difference, gradient descent converging to error
      0.00e+00, and a live chart (the shared `CHSHChartView`) of the energy landscape with
      the optimizer's own path (`PlaygroundDocs/18VQEPLAN.md`, `PlaygroundDocs/18VQEHELP.md`).

## Open systems, measurement, and dynamics playground pages (this fork)

Four more pages, closing gaps pages 01–18 left open: every earlier page assumed a perfect,
pure, noiseless state read out by direct amplitude access, and none of them simulated physics
or interference-driven distributions. All four ship with **no `SwiftQiskit` changes**;
page 19 adds one small additive initializer to the playground's shared `BlochVector`
(now `SwiftQiskitViews.BlochVector` — see P3 item 1 above).

- [x] Noise — page `19Noise`: the density matrix ρ = |ψ⟩⟨ψ| via the existing `Ket * Bra`
      outer product, a mixture vs. a superposition contrasted at identical Z-statistics,
      four Kraus channels (bit-flip, phase-flip, depolarizing, amplitude damping) checked for
      trace preservation, coherence decaying exactly as (1−2p)ⁿ, amplitude damping pulling the
      Bloch vector *inside* the sphere, a Monte-Carlo unraveling reproducing the exact channel
      from pure-state code alone, and a Bell pair's reduced state giving entropy exactly 1 bit
      against a product state's 0 — with a live Bloch gallery shrinking from pure to fully
      depolarized (`PlaygroundDocs/19NOISEPLAN.md`, `PlaygroundDocs/19NOISEHELP.md`).
- [x] Tomography — page `20Tomography`: reconstructing a state from `measure(shots:)` alone.
      Basis rotations — Core's `PauliBasis`/`rotateToZ` rather than bare strings, pinned against
      a known Y-eigenstate, plus a note that `rx(π/2)` is a one-gate alternative to `sdg; h` —
      the estimator checked against exact expectation values, RMS error falling at the 1/√N
      rate, and the sharper-than-expected result that a *pure* state's per-axis reconstruction
      lands outside the Bloch ball about half the time at *any* N (only a genuinely mixed
      state's frequency shrinks toward zero) — plus a Bell pair's marginal reconstructed from
      shots and the 3ⁿ cost table explaining why page 18's VQE measures Pauli terms instead of
      the full state (`PlaygroundDocs/20TOMOGRAPHYPLAN.md`, `PlaygroundDocs/20TOMOGRAPHYHELP.md`).
- [x] Trotterization — page `21Trotter`: Hamiltonian simulation of a transverse-field Ising
      chain. A page-level `expm` (scaling-and-squaring Taylor series) self-checked against
      `RXGate`, the exact gate identity exp(−iθ·Z⊗Z/2) = `cx(0,1); rz(θ,1); cx(0,1)`, first-
      and second-order Trotter error shrinking at the textbook O(1/n)/O(1/n²) rates, the
      observable-level ⟨Z₀⟩(t) tracking the exact curve more closely at higher step counts, and
      the non-zero commutator [Z⊗Z, X⊗I] identified as the error's source (a commuting-only
      Hamiltonian is exact at n=1) — with a live chart of the exact curve against Trotterized
      samples (`PlaygroundDocs/21TROTTERPLAN.md`, `PlaygroundDocs/21TROTTERHELP.md`).
- [x] Quantum walk — page `22Walk`: the discrete-time coined walk on a 16-site cycle. A
      hand-built conditional-shift permutation checked as unitary, ballistic (∝t) spreading
      against an exactly diffusive (∝√t) classical random walk, a caught-and-documented
      cyclic-coordinate variance bug (raw site indices vs. signed offsets), and the |0⟩-vs-|+i⟩
      coin contrast showing the walk's asymmetry is interference, not a flaw — with a live
      chart of both final distributions and cross-references to Grover (page 11) and
      Hamiltonian simulation (page 21) (`PlaygroundDocs/22WALKPLAN.md`, `PlaygroundDocs/22WALKHELP.md`).

## Proposed Core extensions — open systems (from the app's Chapter 21 findings)

Writing the SwiftQiskitApp book's Noise chapter (`Docs/Introduction/21-Noise.md`) surfaced a
set of Core gaps that page `19Noise` and that chapter both route around today with page/app-
level helpers. All of these, including the package-level `BlochVector` (see P3 item 1 above),
are now implemented, turning open-systems support into a first-class Core feature (see the
Roadmap's "Noise models" entry above):

- [x] `Matrix.trace` — sum of the diagonal entries; retires `19Noise`'s last page-level helper.
      Implemented in `Math/Matrix.swift`; tested in `MatrixArithmeticTests.swift`.
- [x] `DensityMatrix` type: `init(_:StateVector)`/`init(mixture:)`, `purity`, `probabilities`,
      `expectation(_:)`, `apply(_:) -> DensityMatrix`, `partialTrace(keeping:)` (generalizing
      `19Noise`'s 2-qubit `partialTraceLast` to n qubits and an arbitrary subset),
      `blochVector` (nil unless 2×2), `vonNeumannEntropy` (closed form for 2×2 via the Bloch
      magnitude; a small file-private Jacobi eigensolver, on a real-symmetric embedding of the
      Hermitian matrix, for larger ρ). Also validates every initializer (square, 2ⁿ, Hermitian,
      trace ≈ 1) rather than trusting the caller. Implemented in `Quantum/DensityMatrix.swift`;
      tested in `DensityMatrixTests.swift`.
- [x] `KrausChannel` type: `operators`, `isTracePreserving(tolerance:)`, `apply(to:qubit:)`
      (embedding a 2×2 channel onto one qubit of an n-qubit ρ, the same idiom
      `CNOTGate.matrix(qubits:control:target:)` already uses for a 2×2 gate), and factories
      `bitFlip`/`phaseFlip`/`depolarizing`/`amplitudeDamping`/`phaseDamping` (the last one new —
      dephasing without energy loss, not in `19Noise`). Implemented in
      `Quantum/KrausChannel.swift`; tested in `KrausChannelTests.swift`, including the phase-flip
      `(1-2p)ⁿ` coherence decay and amplitude damping's closed-form x/z trajectories, both
      checked against `19Noise`'s own numbers.
- [x] Noisy circuit execution: a `NoiseModel` mapping gate applications to a `KrausChannel`
      (`singleQubitGate`/`multiQubitGate`, each applied per-qubit to every qubit a gate of that
      arity touched), `QuantumCircuit.runDensityMatrix(noise:) -> DensityMatrix`, and
      `runTrajectories(noise:shots:) -> SimulationResult` (the Monte-Carlo unraveling
      generalized to full circuits). Needed tagging each recorded `QuantumCircuit` operation
      with the qubits it acts on (previously only the full matrix was kept) so noise can be
      placed precisely rather than on every qubit for every gate. Implemented in
      `Quantum/NoiseModel.swift`/`Circuit/QuantumCircuit.swift`; tested in
      `NoiseModelTests.swift` (no-noise equivalence to `DensityMatrix(run())`, exact single- and
      multi-qubit noise placement, and `runTrajectories` converging to `runDensityMatrix`).
      Reproducing page `14ErrorCorrection`'s p_L = 3p² − 2p³ under a real bit-flip channel
      (instead of one hand-injected `x` gate — flagged there as "not doing" in
      `14ERRORCORRECTIONPLAN.md`'s analogue) is checked directly against `KrausChannel`/
      `DensityMatrix` in `KrausChannelTests.swift`. Retrofitting the *page itself* onto a
      `NoiseModel`-driven `runDensityMatrix`/`runTrajectories` call is now done too — see
      "Suggested implementation sequence" below.
- [x] `DensityMatrix.fidelity(to:StateVector)` — remaining half of this pair;
      `StateVector.expectation(_:Matrix)` (the other half — [x] above) would simplify
      `19Noise`'s `blochOf` helper to one line and help `20Tomography`, which measures
      exactly these three expectation values per qubit. The app's Chapter 22 findings hit
      this same gap again independently (its `exactExpectation(_:_:)` re-derives the
      one-liner `(psi† * A * psi).real`) — see "Proposed Core extensions — tomography"
      below. Implemented in `Quantum/DensityMatrix.swift`; tested in `DensityMatrixTests.swift`.
- [x] A single package-level `BlochVector` (pure-state and `DensityMatrix`-driven initializers),
      replacing the three hand-vendored copies (`Playgrounds.playground/Sources/BlochVector.swift`,
      `SwiftQiskitApp/BlochVector.swift`, and the app's `blochOf(_:Matrix)`). The app's
      Chapter 22 findings add a fourth hand-vendored consumer (its tomography live-view
      section, this time for a *reconstructed* rather than exact vector) — also retargeted.
      Deliberately not done alongside `DensityMatrix` above, and not folded into
      `SwiftQiskit` itself: a Core type named `BlochVector` would collide with the
      playground's own (see `StateTomography`'s identical reasoning, "Proposed Core
      extensions — tomography" below) — done later, together with `CHSHChartView`, as the
      standalone `SwiftQiskitViews` module (P3 item 1 above).
- [x] Tests (Swift `Testing`, shape of `AdditionalGatesTests.swift`): trace preservation for all
      five channels at a few p/γ values; `DensityMatrix.purity`/`vonNeumannEntropy` on a known
      pure state, a maximally mixed state, and a partially mixed state with a hand-computed
      eigenvalue pair; `partialTrace` qubit isolation (mirroring
      `SwiftQiskitApp/SwiftQiskitAppTests/BlochVectorTests.swift`'s reduced-vector-isolation
      test); `runTrajectories` converging to `runDensityMatrix`'s prediction within shot noise.
      Done across `DensityMatrixTests.swift`/`KrausChannelTests.swift`/`NoiseModelTests.swift`.

## Proposed Core extensions — tomography (from the app's Chapter 22 findings)

Writing the SwiftQiskitApp book's Tomography chapter (`Docs/Introduction/22-Tomography.md`)
surfaced a set of Core gaps that page `20Tomography` and that chapter both route around today
with page/app-level helpers (`~/Documents/SwiftQiskit-Chapter22-Findings.md`). All but the
real MLE/linear-inversion reconstruction are implemented now:

- [x] `PauliBasis` enum (`.x`/`.y`/`.z`) and `QuantumCircuit.rotateToZ(_ basis: PauliBasis, _
      qubit: Int)` appending the rotation that turns a measurement of `qubit` in that basis
      into an ordinary Z-basis read (`h` for X, `sdg; h` for Y, nothing for Z) — would replace
      page `20Tomography`'s page-level `PauliBasis`/`basisRotation` and the app chapter's
      identical string-typed version. This same basis-change step is also what Chapter 24's
      proposed `pauliRotation(_:theta:)` needs to move a non-Z Pauli label onto the Z axis before
      its CNOT staircase, and what Chapter 23's proposed `measureExpectation(of:shots:)` needs per
      term — design one Pauli-label type shared by all three (see "— variational" and "—
      Hamiltonian simulation" below) rather than three near-identical enums.
      Implemented in `Quantum/PauliBasis.swift` and `Circuit/QuantumCircuit.swift`
      (`rotateToZ`/private `rotateFromZ`); `pauliRotation`'s own basis-change loops were
      refactored onto `rotateToZ`/`rotateFromZ` rather than duplicating the switch. Tested in
      `PauliBasisTests.swift` against the six single-qubit eigenstates. Page `20Tomography`
      has since been retrofitted onto it directly.
- [x] `QuantumCircuit.measure(shots: Int, basis: [PauliBasis]) -> SimulationResult` — appends
      each qubit's basis rotation (applied to a copy, leaving the circuit's own operation list
      untouched), then measures. Folds the hand-appended rotate-then-measure pattern every
      estimator in page `20Tomography` (and the app chapter) repeats into the call itself.
      Implemented in `Circuit/QuantumCircuit.swift`; tested in `PauliBasisTests.swift`,
      including that it leaves the receiver's operation list untouched and a Bell pair's
      ⟨XX⟩/⟨YY⟩ via `parityExpectation(qubits:)`.
- [x] `StateTomography` helper: `estimate(qubit:result:) -> Double` ((N₀−N₁)/N from one
      basis's `SimulationResult`), `estimateBlochVector(of:qubit:shots:)` (runs the three X/Y/Z
      settings via `measure(shots:basis:)` and estimates one qubit's vector),
      `reconstructSingleQubit(x:y:z:tolerance:) -> (vector:(x:Double,y:Double,z:Double),
      isPhysical: Bool)` (packages a three-axis estimate, `isPhysical` = `|r| <= 1 +
      tolerance`), and `clampToPhysical(_:)` (rescales an out-of-ball estimate back onto the
      unit sphere, `r -> r/|r|` — a named, tested version of page `20Tomography`'s rescaling
      idea, not a real MLE estimator). Returns `(x:, y:, z:)` tuples rather than a
      package-level `BlochVector`, to avoid colliding with `SwiftQiskitViews.BlochVector`
      (P3 item 1 above). Implemented in `Quantum/StateTomography.swift`; tested (against a known pure
      state's exact Pauli expectations and a Bell pair's qubit-0 marginal, without needing
      `DensityMatrix`) in `StateTomographyTests.swift`. Retrofitting page `20Tomography` onto
      it is still open — see "SwiftQiskitApp follow-ups" below.
- [ ] A real maximum-likelihood or linear-inversion reconstruction — a bigger lift than
      `StateTomography` above; a reasonable follow-up once that lands, not blocking it.
- See also `SimulationResult.parityExpectation(qubits:)` and `StateVector.expectation(_:)` in
  the Roadmap above, and the `BlochVector`/`StateVector.expectation` carry-over notes under
  "Proposed Core extensions — open systems" — Chapter 22 hit both gaps again independently.

## Proposed Core extensions — variational (from the app's Chapter 23 findings)

Writing the SwiftQiskitApp book's VQE chapter (`Docs/Introduction/23-VQE.md`) surfaced Core gaps
that page `18VQE` and that chapter both route around today
(`~/Documents/SwiftQiskit-Chapter23-VQE-Extensions.md`). The chapter needed no `SwiftQiskit`
changes to write (its one-real-parameter, closed-form-graded ansatz is deliberately small), but
flagged the following as what a *bigger* VQE-style chapter — or the app's own "Energy" panel —
would need:

- [x] A `PauliString`/`Hamiltonian` type: a list of per-qubit Pauli labels with a coefficient
      (rather than pre-multiplied `⊗` chains), plus `matrix` (dense form, for grading/small
      systems) and `expectation(_ state: StateVector) -> Double`. The single most reusable piece
      here — every future variational or Hamiltonian-simulation chapter (VQE past H₂, Trotter's
      spin chain, QAOA) currently re-derives "a weighted sum of Pauli tensor products" from
      scratch at the page level. Shares its Pauli-label type with the tomography `PauliBasis`
      proposal and Chapter 24's `pauliRotation` below — see the note on that item above.
      Implemented in `Quantum/PauliString.swift`/`Quantum/Hamiltonian.swift`; tested against
      the H₂ Hamiltonian's closed-form eigenvalue (and the hand-built matrix page `18VQE`
      assembles from `Matrix`'s `+`/scalar `*`) in `PauliStringTests.swift`. Retrofitting page
      `18VQE` onto it is still open — see "SwiftQiskitApp follow-ups" below.
- [x] `measureExpectation(of: PauliString, shots: Int) -> Double` (and an overload for
      `Hamiltonian`) on `QuantumCircuit`, built on `measure(shots:basis:)` +
      `SimulationResult.parityExpectation(qubits:)` (both already proposed above) — would let a
      chapter show the actual noisy VQE loop (energy with shot noise) instead of the exact
      `ψ†Hψ` every chapter uses today, and would give the app's proposed Energy panel real
      statistical jitter instead of a hand-computed exact number. The `Hamiltonian` overload
      spends `shots` per term. Implemented in `Circuit/QuantumCircuit.swift`; tested in
      `MeasureExpectationTests.swift`, including the H₂ energy converging within shot noise
      and that neither overload mutates the receiver. The `Hamiltonian` overload was later
      upgraded to spend `shots` per *commuting group* rather than per term — see
      `Hamiltonian.commutingGroups()` under "Proposed Core extensions — Hamiltonian
      simulation" below.
- [x] A general multi-parameter parameter-shift gradient — generalizing this chapter's
      one-parameter `parameterShiftGradient(_ theta: Double) -> Double` to a `[Double]` of angles
      over an arbitrary `[Double] -> Double` cost closure (plus a `Hamiltonian`/ansatz-closure
      convenience overload) — plus a minimal gradient-descent optimizer (no COBYLA/Nelder-Mead
      needed; gradient descent already converges in ~10 steps on the toy problem). Unblocks any
      ansatz bigger than one parameter replacing the current single-block toy case. Implemented
      in `Quantum/ParameterShift.swift` (`ParameterShift.gradient`, `GradientDescent.minimize`);
      tested in `ParameterShiftTests.swift` against finite differences on a 2-parameter ansatz
      and page 18's own one-parameter ansatz, and gradient descent converging to a known
      closed-form single-qubit ground energy. Retrofitting page `18VQE` onto it is still open —
      see "SwiftQiskitApp follow-ups" below.
- [x] Lower priority, purely presentational: promoting `CHSHChartView` into a shared module
  the app can import, so the app can draw the same E(θ)-with-optimizer-path chart the
  playground already has. Done as part of the `SwiftQiskitViews` module (P3 item 1 above) —
  this didn't unlock new computation, only a nicer view of computation the app can already do.

## Proposed Core extensions — Hamiltonian simulation (from the app's Chapter 24 findings)

Writing the SwiftQiskitApp book's Trotter chapter (`Docs/Introduction/24-Trotter.md`) surfaced
further Core gaps that page `21Trotter` and that chapter both route around today
(`~/Documents/SwiftQiskit-Chapter24-Trotter-Extensions.md`). No `SwiftQiskit` changes were made
for the chapter itself (matching `21TROTTERPLAN.md`'s own choice); the app did gain a fully
tappable first-order Trotter step from the existing `cx`/`rz`/`rx` palette. Proposed Core work:

- [x] `Matrix.expm(terms: Int = 20) -> Matrix` (scaling-and-squaring Taylor series) in
      `Math/Matrix.swift` — the single most-repeated page-level helper across the playground
      set; promoting it removes the last hand-rolled linear-algebra idiom `21Trotter` was
      re-deriving, and is a prerequisite for any future chapter wanting an exact ground truth
      for a Hamiltonian bigger than 2 qubits (where a closed-form eigen-decomposition stops being
      available by hand). Also wanted independently by Chapter 25 (quantum walks) — see below.
      Tested in `MatrixExponentialTests.swift` against `RXGate`/`RYGate`/`RZGate.matrix(theta:)`,
      the zero matrix, a diagonal matrix, the ZZ `cx;rz;cx` identity, and a large-norm generator
      (exercising the squaring path). `21Trotter`'s page-level `expm` was migrated onto it,
      verified to produce identical output; `PlaygroundDocs/21TROTTERHELP.md` updated to match.
- [x] Native two-qubit Pauli rotations `RZZGate`/`RXXGate`/`RYYGate` (matrix level, mirroring
      `RZGate.matrix(theta:)`'s shape, in `Gates/TwoQubitRotation.swift`) plus
      `QuantumCircuit.rzz/rxx/ryy(_ theta:, _ q0:, _ q1:)`. The ZZ interaction is the single most
      common two-qubit term in condensed-matter/quantum-chemistry Hamiltonians; every future
      Ising- or Heisenberg-model chapter, and VQE ansätze beyond H₂, need it. Went one qubit-pair
      further than originally proposed: rather than being fixed to adjacent qubits, all three are
      thin wrappers around `pauliRotation` below, so they work on *any* distinct pair on an
      *n*-qubit circuit. Tested in `TwoQubitRotationTests.swift` against `Matrix.expm()` and,
      for `rzz`, against the hand-written `cx;rz;cx` identity.
- [x] `QuantumCircuit.pauliRotation(_ pauli: String, theta: Double)` — `exp(−iθ·P/2)` for an
      arbitrary Pauli string (e.g. `"ZIZ"`), via a CNOT staircase computing the parity of every
      non-identity qubit into one qubit, a single `rz` there, then the staircase undone, with a
      basis change (`h`/`sdg;h`) where `P` calls for X or Y — reusing the same basis-rotation step
      as the tomography `PauliBasis` proposal above. Generalizes this chapter's 2-qubit Ising
      chain to an arbitrary-length spin chain without every future chapter re-deriving the
      staircase from scratch. Landed ahead of the `PauliString`/`Hamiltonian` type it was
      originally scoped under (roadmap step 4, below) since it needed no new type — it takes a
      plain Pauli `String` and is built entirely from existing gate methods. An all-`I` string
      applies the global phase `e^{-iθ/2}·I` directly, so the circuit matches `Matrix.expm()` on
      the same generator exactly rather than dropping the phase. Implemented in
      `Circuit/QuantumCircuit.swift`; tested in `TwoQubitRotationTests.swift` against
      `Matrix.expm()` for 3- and 4-qubit strings (including a mixed string with an interior `I`),
      against `rx`/`ry`/`rz` for single-qubit strings, and against the global-phase identity for
      an all-`I` string.
- [x] `QuantumCircuit.evolve(_ hamiltonian: Hamiltonian, time: Double, steps: Int, order: Int =
      1)` and `Hamiltonian.trotterCircuit(time:steps:order:) -> QuantumCircuit` — appends `steps`
      repetitions of a Trotterized product formula (one `pauliRotation` call per term); `order:
      1` is first-order (Lie–Trotter), `order: 2` is second-order (Strang/Suzuki: every term but
      the last at half step, the last term at full step, then every term but the last again at
      half step in reverse). No automatic grouping into commuting layers — the caller controls
      layering by ordering `hamiltonian.terms` — so this is a narrower scope than originally
      proposed (which asked for commuting-layer grouping); grouping remains available but
      opt-in, below. Would let both this chapter's Ising chain and a future, larger
      Hamiltonian-simulation chapter be expressed and run in the app directly, instead of
      hand-assembled matrix code with no path onto a circuit builder. Implemented in
      `Circuit/QuantumCircuit.swift`/`Quantum/Hamiltonian.swift`; tested in
      `TrotterTests.swift` against `Matrix.expm()`, including the O(1/n)/O(1/n²) error-scaling
      rates for first- and second-order steps on page `21Trotter`'s transverse-field Ising
      chain, exactness for a single term and for commuting terms at one step, the all-`I`
      global-phase case, and a 3-qubit chain. Retrofitting page `21Trotter` onto it is still
      open — see "SwiftQiskitApp follow-ups" below.
- [x] Commuting-term grouping for `evolve`/`trotterCircuit` above — grouping a `Hamiltonian`'s
      terms into commuting layers before emitting `pauliRotation` calls, so a caller doesn't have
      to hand-order `terms` to get the cheapest split. Landed as `Hamiltonian.commutingGroups()`
      (`Quantum/Hamiltonian.swift`) — a caller opts in via
      `Hamiltonian(hamiltonian.commutingGroups().flatMap { $0 })` before calling
      `evolve`/`trotterCircuit`, rather than `evolve` grouping automatically: reordering
      changes the *finite-step* Trotter error (never the ∞-step limit), and `TrotterTests.swift`
      plus page `21Trotter`'s printed output already pin exact error-scaling numbers against
      the current term order, so a default-behavior change would have silently moved them.
      `commutingGroups()` doubles as the primitive `measureExpectation(of: Hamiltonian,
      shots:)` now uses automatically (below) — same algorithm, different opt-in-vs-automatic
      choice per consumer. Built on new `PauliString.isQubitWiseCommuting(with:)`: a greedy
      heuristic (Qiskit's default `group_commuting` strategy) partitioning terms into groups
      where every pair is *qubit-wise commuting* — on every qubit, labels agree or one is `I`
      — the stricter-than-literal-Pauli-commutativity condition that actually hands you one
      shared per-qubit basis. Tested in `CommutingGroupsTests.swift` (the algorithm itself)
      and `TrotterTests.swift` (a scrambled-vs-grouped Ising example, verified numerically in
      Python before writing the assertion to confirm the grouped order's error is never worse
      at a fixed step count, for that example, while both still converge to `Matrix.expm()`).
- [x] Doc TODO: a one-line callout in `PlaygroundDocs/21TROTTERHELP.md` noting that reversing a
      Trotter step's internal layer order (X-layer before ZZ instead of after) produces an error
      curve identical to the original order to floating-point precision, at every step count —
      a mildly surprising fact about product-formula splitting the current guide doesn't mention
      either way. Done — added as an "Aside" after Section 3, with the transpose argument for
      *why* (Z⊗Z/X⊗I/I⊗X are real symmetric, so reversing a step's layers is transposing it, and
      the exact e^(−iHt) is symmetric too), numerically confirmed at n = 1…32 (order-1 step
      matrices genuinely differ, ~0.06 max entry, yet their errors match to ~1e-16) and the
      order-2 case noted as a trivial palindrome rather than a distinct instance.

## Proposed Core extensions — permutations, Toffoli & registers (from the app's Chapter 25 findings)

Writing the SwiftQiskitApp book's quantum-walk chapter (`Docs/Introduction/25-QuantumWalks.md`)
surfaced further Core gaps that page `22Walk` and that chapter both route around today
(`~/Documents/SwiftQiskit-Chapter25-QuantumWalk-Extensions.md`). No `SwiftQiskit` changes were
made for the chapter itself; the app did gain an exact 3-gate decomposition of the 4-site walk's
shift (`cx(0,1); cx(2,1); x(2)`), raising that one chapter's app badge from ○ to ◐. Proposed Core
work:

- [x] `Matrix.permutation(size: Int, image: (Int) -> Int) -> Matrix` — the hand-rolled
      `for i in 0..<n { m[image(i), i] = .one }` loop that pages `12ShorExample` (modular
      multiplication), `14ErrorCorrection` (the 32×32 correction), and `22Walk` (the shift) each
      write from scratch. `precondition` that `image` is a bijection (making the constructor
      itself the unitarity check, replacing each page's separate manual `S†S = I` check).
      Implemented in `Math/Matrix.swift`; tested in `MatrixArithmeticTests.swift`. All three
      pages above (`12ShorExample`'s `modMultiplyGate`/`controlledModMultiply`,
      `14ErrorCorrection`'s `correction`, `22Walk`'s `buildShift`) are now migrated onto it,
      each verified to produce a matrix identical to its old hand-rolled loop; the manual
      `S†S ≈ I` checks in `14ErrorCorrection` and `22Walk` were replaced with `isUnitary()`.
- [x] `Matrix.isUnitary(tolerance: Double) -> Bool` — replaces the hand `M†M ≈ I` check repeated
      since page `12ShorExample`; also wanted by Chapter 24's findings (restated there as the
      third page in a row, 21/24/25, wanting a unitarity helper alongside `expm`). Implemented
      in `Math/Matrix.swift`; tested in `MatrixArithmeticTests.swift`.
- [x] `ToffoliGate.matrix(qubits: Int, control1:, control2:, target:) -> Matrix` (a permutation:
      flip `target` iff both controls are `1`) via `Matrix.permutation` above, plus a
      `QuantumCircuit.ccx(_:_:_:)` circuit method. This chapter's central finding is that the
      coin-controlled shift needs a genuine `AND` (not just XOR/CNOT) beyond a 4-site cycle — the
      same "no Toffoli" wall pages `14ErrorCorrection` and `12ShorExample` already hit and
      hand-built permutation matrices specifically to route around. The single change that would
      let the 8-site (and 16-site) walk move from ○/◐ to fully tappable in the app.
      Implemented in `Gates/Toffoli.swift`; tested in `ToffoliTests.swift` (truth table,
      unitarity/self-inverse on non-adjacent qubits, symmetry in its two controls). Retrofitting
      pages `12ShorExample`/`14ErrorCorrection`/`22Walk` onto it is still open — see
      "SwiftQiskitApp follow-ups" below.
- [x] `QuantumCircuit` register builder `increment`/`decrement(register: [Int], controlledBy:
      Int?)` emitting the ripple-carry sequence (generalizing this chapter's 2-bit
      `cx(control,high); cx(low,high); x(low)` with one more layer per additional bit). Needed a
      new `MultiControlledXGate`/`mcx` first (below) — a register wider than 2 bits needs more
      controls than `ccx` alone provides. `register[0]` is the most-significant qubit, matching
      Core's convention; `increment` applies most-significant to least-significant so every
      flip's controls are read before they're themselves touched, and `decrement` is the same
      gates in reverse (each `mcx` is self-inverse). Would let a future edition of this chapter
      build the actual 16-site shift from named building blocks instead of one 32×32 permutation
      matrix, and generalizes directly to page `12ShorExample`'s modular-arithmetic needs (a
      controlled increment is most of a controlled adder). Implemented in
      `Circuit/QuantumCircuit.swift`; tested in `RegisterArithmeticTests.swift` (every 3-bit
      value mod 8, a non-contiguous register with a spectator qubit, and the controlled variant).
- [x] `MultiControlledXGate.matrix(qubits:controls:target:)` (+ `QuantumCircuit.mcx(_:_:)`) — the
      general multi-controlled X the `increment`/`decrement` builders above need: 0 controls is
      an unconditional flip (`x`), 1 is `CNOTGate`, 2 is `ToffoliGate`, via the same
      `Matrix.permutation` idiom both already use. Not part of the original Chapter 25 proposal
      list, but a prerequisite this pass surfaced. Implemented in `Gates/MultiControlledX.swift`;
      tested in `RegisterArithmeticTests.swift` against `PauliXGate`/`CNOTGate`/`ToffoliGate` for
      0/1/2 controls, and for unitarity/self-inverse at 4 controls.
- [x] `StateVector.marginalProbabilities(over qubits: [Int]) -> [String: Double]` (summing
      probability over every *other* qubit) and an analogous grouping helper on
      `SimulationResult` for shot-based marginals — replaces the three-line manual
      loop-and-sum repeated with small variations in pages `11GroverExample`, `19Noise`, and now
      `22Walk` every time a sub-register's marginal is needed.
      Implemented in `Quantum/StateVector.swift` (`marginalProbabilities`, returning every
      key including zero-probability ones) and `Quantum/SimulationResult.swift`
      (`marginalCounts`, observed keys only); tested in `ReadoutTests.swift`. The page
      retrofits are still open — see "SwiftQiskitApp follow-ups" below.
- [x] A permutation-aware fast path in `StateVector.apply(_:)` — a permutation matrix (every walk
      step, Shor's modular multiplication, the error-correction syndrome fix) needs only one
      multiply-free array reindex per amplitude rather than a full dense matrix-vector multiply.
      Done — see the Roadmap's "Performance optimizations" entry above for the implementation;
      it turned out to be the natural first slice of that entry, exactly as flagged here.
- [x] Tests: `increment`/`decrement` against modular arithmetic on a small register — done in
      `RegisterArithmeticTests.swift`, above. (`Matrix.permutation`/`isUnitary` landed with those
      helpers themselves, `ToffoliGate`/`ccx` in `ToffoliTests.swift`, and
      `marginalProbabilities` in `ReadoutTests.swift`, all above.)

## SwiftQiskitApp follow-ups (tracked here for sequencing)

App-side changes proposed by the Chapter 23–25 findings notes that are not `SwiftQiskit` changes,
gathered here so they can be sequenced against the Core work above rather than tracked only in
`~/Documents`:

- [ ] A signed range (or a numeric text field alongside the slider) for the θ popover, currently
      0–2π only — every Trotter/VQE-style chapter since Chapter 20 has needed a `2π − x`
      workaround for a negative angle. No Core dependency; can be done independently of everything
      else in this file.
- [x] CZ, multi-controlled Z, and SWAP — `cz`/`mcz`/`swap` with `ControlledZ.swift`,
      `MultiControlledZ.swift`, `Swap.swift` and `ControlledZAndSwapTests`; the app's CZ/SWAP tiles use them.
- [ ] A Toffoli tile in `GatePaletteView`/`GateKind` — `ccx` (above) is now implemented, so this
      is unblocked. The single highest cross-chapter-leverage app change on this list: Chapters
      14, 17 (Shor), and 25 all hit the same "no Toffoli" wall independently.
- [x] An `rzz` tile (and `rxx`/`ryy`) — those gates (above) are now implemented, so this is
      unblocked. Turns today's three-tap `cx; rz; cx` sequence into one tap. Done in the
      `SwiftQiskitApp` repo: `GateKind.rzz/rxx/ryy` (each with a θ parameter), a symmetric
      two-tap placement flow distinguished from `cx`'s control/target flow by a new
      `GateKind.isControlled`, a palette section, and both qubits of the placed gate
      rendering as boxed tiles (unlike `cx`'s dot/⊕).
- [ ] A position-marginal / histogram-grouping view in `ResultsView` —
      `marginalProbabilities`/`SimulationResult` grouping (above) are now implemented, so this
      is unblocked. Today `ResultsView` only shows the raw per-basis-state state vector and shot
      histogram, with no way to display a probability summed over a subset of qubits, which every
      multi-register chapter (11, 19, 25) actually wants to look at.
- [ ] An "Energy" panel (alongside the existing State Vector / Results / Display buttons) letting a
      user attach a fixed Hamiltonian and read its expectation value live — the `Hamiltonian`
      type and `measureExpectation` (above) are now implemented, so this is unblocked.
- [x] Promote `CHSHChartView` and a single package-level `BlochVector` out of
      `Playgrounds.playground/Sources/` into a shared, importable module (a new SwiftUI library
      target, `SwiftQiskitViews`, so Core itself stays UI-free) — replaces the hand-vendored
      copies in the playground and in `SwiftQiskitApp`. Done — see P3 item 1 above; the app now
      `import SwiftQiskitViews` in place of its own `BlochVector.swift`.
- [ ] Density-matrix / noise-channel views in the app — `DensityMatrix`/`KrausChannel`/
      `NoiseModel` (under "Proposed Core extensions — open systems" above) are now
      implemented, so this is unblocked.

## Suggested implementation sequence

A dependency-ordered path through all the proposed Core extensions above, for whichever project
picks this up next:

**`SwiftQiskit` (Core):**

1. Foundation one-liners with no dependencies on each other: `StateVector.expectation`,
   `Matrix.trace`, `Matrix.isUnitary`, `Matrix.permutation`, `Matrix.expm`. Each retires a
   repeated page-level helper; each is tested by self-check against an existing gate. **Done**
   — all five landed (`Matrix.expm` last, in `MatrixExponentialTests.swift`).
2. Gates built on step 1: `ToffoliGate`/`ccx` (via `Matrix.permutation`),
   `RZZGate`/`RXXGate`/`RYYGate`/`rzz`/`rxx`/`ryy` (tested against `Matrix.expm`), and
   `QuantumCircuit.pauliRotation` are all **done** — `pauliRotation` landed here rather than
   in step 4, since it turned out to need no `PauliString`/`Hamiltonian` type: it takes a plain
   Pauli `String` and is built entirely from existing gate methods (`h`/`sdg;h`/`cx`/`rz`).
   `ToffoliGate` tested in `ToffoliTests.swift`.
3. Readout helpers: `StateVector.marginalProbabilities`, the `SimulationResult` marginal /
   `parityExpectation` helpers, `PauliBasis` + `rotateToZ` + `measure(shots:basis:)`. **Done**
   — tested in `ReadoutTests.swift` and `PauliBasisTests.swift`.
4. The Pauli-algebra hub: `PauliString` → `Hamiltonian` (`matrix`, `expectation`,
   `measureExpectation`) → the tomography `StateTomography` helper. **Done** — `PauliString`/
   `Hamiltonian` in `PauliStringTests.swift`, `measureExpectation` in
   `MeasureExpectationTests.swift`, `StateTomography` in `StateTomographyTests.swift`.
   (`pauliRotation` moved to step 2, above — done; `PauliBasis` moved to step 3, above — done.)
5. Builders on top of 2–4: `Hamiltonian.trotterCircuit`, the multi-parameter parameter-shift
   gradient + optimizer, and `increment`/`decrement` are all **done** —
   `Hamiltonian.trotterCircuit`/`QuantumCircuit.evolve` in `TrotterTests.swift`,
   `ParameterShift`/`GradientDescent` in `ParameterShiftTests.swift`, and
   `increment`/`decrement` (plus the `MultiControlledXGate`/`mcx` gate they needed first) in
   `RegisterArithmeticTests.swift`.
6. Open systems track (independent of 2–5, only needs step 1): `DensityMatrix` →
   `KrausChannel` → `NoiseModel`/`runDensityMatrix`/`runTrajectories` are all **done** —
   `DensityMatrix` in `DensityMatrixTests.swift`, `KrausChannel` in `KrausChannelTests.swift`,
   `NoiseModel`/`runDensityMatrix`/`runTrajectories` in `NoiseModelTests.swift`. The
   package-level `BlochVector` is also **done**, as part of the `SwiftQiskitViews` module
   (P3 item 1 above) rather than folded into `SwiftQiskit` itself.
7. Performance: the permutation-aware fast path in `apply` is **done** (`Matrix.permutationImage`,
   `Math/Matrix.swift`; tested in `PermutationFastPathTests.swift`); general optimizations
   (applying gates directly to amplitudes instead of full 2ⁿ×2ⁿ operation matrices) remain open.

Page retrofits (`21Trotter`/`18VQE` onto the `Matrix` operators; `12`/`14`/`22` onto
`Matrix.permutation`) can follow immediately after the step that lands each helper. `21Trotter`
onto `Matrix.expm` and both pages onto the `Matrix` `+`/scalar-`*` operators are **done**;
`19Noise` was never a retrofit target — it has no page-level `expm` of its own.

Now that step 2's `ToffoliGate`/`ccx` and step 3's readout helpers have landed, the same kind of
retrofit is open against them (not done as part of landing the helpers themselves, to keep that
change additive-only):

- [x] Page `15CHSH`: replace its hand-rolled `sampledCorrelator` with
      `SimulationResult.parityExpectation(qubits:)`. Done.
- [x] Page `20Tomography`: replace its page-level `PauliBasis`/`basisRotation` and the
      hand-appended rotate-then-measure pattern with `QuantumCircuit.rotateToZ`/
      `measure(shots:basis:)`. Done — the mixed-ensemble section (each shot needs a fresh
      random preparation, so `measure(shots:)` can't sample it directly) now builds its two
      branch circuits once per basis via `rotateToZ` and calls `runAndMeasure()` per shot.
- [x] Pages `11GroverExample`, `22Walk`: replace their hand-rolled marginal
      loop-and-sum with `StateVector.marginalProbabilities`/`SimulationResult.marginalCounts`.
      Done for `22Walk` — `positionDistribution` now sums out the coin qubit via
      `psi.marginalProbabilities(over: [1, 2, 3, 4])` instead of a double loop over both coin
      values, converting the returned `[String: Double]` back into the page's `[Double]`
      (indexed by site) so `stddevSigned`/the chart-point code stay unchanged. Nothing to do
      for `11GroverExample` on inspection — it never actually sums a marginal (it reads single
      basis-state probabilities via `probabilities[oracle.markedIndex]`/`probabilities[5]` and
      groups shot counts via the pre-existing `SimulationResult.sortedCounts`, not a hand-rolled
      loop); the original proposal note was speculative about which pages would need this.
- [x] Pages `12ShorExample`, `14ErrorCorrection`: where a hand-built permutation matrix is
      really a controlled-controlled flip, replace it with `ToffoliGate`/`ccx`. Done for
      `14ErrorCorrection` — the `correction` matrix is now three X-conjugated
      `ToffoliGate.matrix`/`MultiControlledXGate.matrix` branches multiplied together (kept as
      one combined `Matrix` fed to a single `apply(_:)`, not separate circuit gate calls, so
      Section 6's `NoiseModel` still sees it as one multi-qubit operation and doesn't pick up
      new single-qubit `x` noise points the original design never had), verified identical to
      the old hand-rolled permutation entry by entry before the swap. Nothing to do for
      `12ShorExample` on inspection — `modMultiplyGate`/`controlledModMultiply` are modular
      *multiplication* permutations (an arbitrary bijection on 15 values), not single-target
      controlled flips, so they don't fit the `ToffoliGate`/`ccx`/`mcx` shape at all; the
      original proposal note was speculative here too.

Now that step 4's Pauli-algebra hub has landed, its own retrofit is open too:

- [x] Page `18VQE`: replace its entrywise-built H₂ Hamiltonian with `Hamiltonian`/
      `PauliString`, and its exact `ψ†Hψ` energy call with `Hamiltonian.expectation(_:)`. Done —
      the six terms are now `PauliString("II"/"ZI"/"IZ"/"ZZ"/"YY"/"XX", coefficient: g[i])`
      summed into a `Hamiltonian`; `energy(_:)` calls `H.expectation(ansatz(theta))`; Section 4's
      2×2-block grading uses `H.matrix[1,1]`/etc. in place of the old bare `Matrix` subscripts.
- [x] Page `20Tomography`: replace its page-level per-axis `estimate`/basis-rotation helpers
      with `StateTomography.estimate`/`estimateBlochVector`. Done — `estimate`/`estimateQubit0`
      (Section 5's Bell-marginal estimator) now wrap `StateTomography.estimate(qubit:result:)`;
      `reconstructedMagnitude` (Section 4's pure-state unphysical-frequency check) uses
      `StateTomography.estimateBlochVector(of:qubit:shots:)` directly instead of three separate
      `estimate` calls. `estimateMixed`/`unphysicalFrequencyMixed` (the mixed-ensemble
      per-shot-re-preparation section) are unchanged, as noted — no Core helper samples a
      fresh classical mixture per shot.

Now that step 5's builders have landed, their own retrofit is open too:

- [x] Page `21Trotter`: replace its page-level `trotterUnitary`/hand-rolled Ising Hamiltonian
      with `Hamiltonian`/`PauliString` + `Hamiltonian.trotterCircuit(time:steps:order:)` (or
      `QuantumCircuit.evolve(_:time:steps:order:)` on a prepared circuit). Done — `Hising` is
      now a 3-term `Hamiltonian`; `trotterUnitary` builds its matrix by running
      `qc.evolve(Hising, ...)` from every computational basis input (a new page-level
      `matrixFromCircuit` helper, since `QuantumCircuit.run()` always starts from |0…0⟩ and a
      circuit has no public way to expose its combined unitary directly). Verified numerically
      identical to the old hand-rolled version at every pinned n in `21TROTTERHELP.md` (exactly,
      not just to displayed precision — `XI`/`IX` commute, so `evolve`'s generic per-term Suzuki
      split reduces algebraically to the old 2-group split).
- [x] Page `18VQE`: replace its hand-written `parameterShiftGradient`/gradient-descent loop with
      `ParameterShift.gradient`/`GradientDescent.minimize`. Done — `parameterShiftGradient` now
      calls `ParameterShift.gradient(at:_:)`; Section 6 uses `GradientDescent.minimize`
      (`tolerance: 0` to keep running the full 40 steps, matching the page's original
      unconditional loop). Needed a small Core addition, `GradientDescent.Result
      .parameterHistory: [[Double]]` (mirroring `history`), since the page's live chart plots
      the (θ, E) trajectory gradient descent visited, which `Result` didn't previously expose;
      tested in `ParameterShiftTests.swift`.
- [x] Page `22Walk`: where `buildShift`'s permutation is really a ripple-carry ±1 on the site
      register, express it via `QuantumCircuit.increment`/`decrement` instead. Done —
      `appendShift(to:)` builds the coin-controlled shift from `increment`/`decrement` on the
      4-qubit position register (q1..q4, 16-site cycle); the resulting `Matrix` (assembled
      column-by-column via `run()`, since `QuantumCircuit` has no direct unitary accessor) is
      cross-checked for exact equality against the original `Matrix.permutation` construction.

Now that step 6's open-systems track has landed, its own retrofit is open too:

- [x] Page `19Noise`: replace its page-level `rho`/`purity`/`*Kraus`/`applyChannel`/`blochOf`/
      `partialTraceLast`/`entropy` helpers with `DensityMatrix`/`KrausChannel` directly — done;
      only `fmt` and a small `traceResidual` (for the numeric residual `isTracePreserving()`
      doesn't expose) remain as page-level helpers.
- [x] Page `14ErrorCorrection`: reproduces its enumerated p_L = 3p² − 2p³ empirically under a
      real `NoiseModel`/`KrausChannel.bitFlip` (via `runDensityMatrix`/`runTrajectories`) in
      addition to the original hand-injected `x` gate — flagged there as "not doing" in
      `14ERRORCORRECTIONPLAN.md`'s analogue, now done. The circuit's own `cx`/`apply(_:)` steps
      are recorded as multi-qubit, so a `singleQubitGate`-only `NoiseModel` needs an idle-tick
      `p(0, q)` on each data qubit as the hook for the noise; the logical input is \|0⟩ so a
      prep-gate error (unprotectable regardless) never enters. `KrausChannelTests.swift`
      already checked the same formula directly against `KrausChannel`/`DensityMatrix` (no page
      change there); this item was specifically about the page's own presentation.

**`SwiftQiskitApp`:**

1. The signed-range θ popover — no Core dependency, do this first.
2. The Toffoli tile — after Core step 2; highest leverage across pages/chapters 12, 14, 22.
3. The `rzz` tile — also after Core step 2. **Done.**
4. The marginal/grouped `ResultsView` — after Core step 3.
5. The Energy panel — Core step 4 is done, so this is unblocked.
6. The shared views module (`CHSHChartView`/`BlochVector`) — purely presentational. **Done**
   (`SwiftQiskitViews`, tag `0.2.0`; the app's package dependency and `import`s updated).
7. Density-matrix / noise views — after Core step 6.
