# Status and TODO

Project status, feature status, and the core-library roadmap for SwiftQiskit,
plus this fork's working TODO list.

## Project Status

**SwiftQiskit is currently in an early experimental stage (v0.1).**

- Core quantum simulation is implemented
- API is subject to change
- Performance is not yet optimized
- GUI tools are available in separate projects or through the template system
- An extensive set of playgrounds is included in /Playgounds and documented in /PlaygroundDocs

The project is actively evolving, and major features are planned.

## What Works (v0.1)

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

## Roadmap

- [x] General multi-qubit CNOT support
- [x] Additional gates (Y, Phase, Rotation gates)
      → `Gates/PauliY.swift`, `Gates/Phase.swift` (P(θ), S, S†, T, T†),
      `Gates/Rotation.swift` (RX/RY/RZ); circuit API `y/s/sdg/t/tdg/p/rx/ry/rz`,
      tested in `AdditionalGatesTests.swift`
- [x] Noise models — addressed at the playground-example level: page `19Noise` builds Kraus
      channels (bit-flip, phase-flip, depolarizing, amplitude damping) as page-level `Matrix`
      operations. Core itself still has no `DensityMatrix` type or built-in noise simulation —
      see "Proposed Core extensions — open systems" below for what a first-class Core feature
      would look like.
- [ ] `SimulationResult.parityExpectation(qubits:)` — a ±1 parity-product average over
      `counts` (one qubit position per factor, 0→+1/1→−1). Would replace the
      `sampledCorrelator` boilerplate in page `15CHSH` and would likely also simplify
      page `18VQE`'s ZZ-term measurement and page `20Tomography`'s shot-based estimators.
      Needs tests if added to Core.
- [ ] `StateVector.expectation(_ observable: Matrix) -> Double` wrapping
      `(self† * observable * self).real` — low priority, since the Dirac idiom is already
      one line once adopted (see page `15CHSH`'s `exactCorrelator`). Also listed under
      "Proposed Core extensions — open systems" below, since Chapter 21's findings hit the
      same gap independently.
- [ ] Page `15CHSH`: extend the Tsirelson-bound check from a sweep over one setting (b, with
      a, a′ fixed) to a genuine multi-angle search over all four settings, if a true
      confirmation of the bound (rather than a consistency check) is wanted.
- [x] `QuantumCircuit.measure(shots:)` runs the circuit once and samples the resulting
      `probabilities` `shots` times, instead of calling `runAndMeasure()` (which replays every
      recorded operation via `run()`) once per shot — only the final random draw differs shot
      to shot for a full measurement of a pure state. The shared cumulative-probability sampler
      moved to `StateVector.sampleIndex(from:)`, used by both this and `StateVector.measure()`.
      Tested in `MeasurementTests.swift`, including a regression check against the old
      replay-per-shot behavior. Pages 12 and 13's own local samplers (added to route around the
      old cost) are kept as see-through stand-ins and updated to say so.
- [ ] Performance optimizations
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
      `addM`/`scaleM`, `18VQE`'s and `15CHSH`'s entrywise term accumulation). `19Noise` now uses
      the operators directly (its `trace` helper is the only one left); `21Trotter`, `18VQE`,
      and `15CHSH` are unchanged and still work with their own helpers. Tested in
      `MatrixArithmeticTests.swift`.

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
      qubit Hamiltonian (Jordan–Wigner, minimal basis) built entrywise from six Pauli terms,
      a one-parameter ansatz confined to the `{|01⟩,|10⟩}` subspace, the energy via page 08's
      `psi† * H * psi`, a closed-form 2×2 eigenvalue for grading, exact parameter-shift
      gradients pinned against a finite difference, gradient descent converging to error
      0.00e+00, and a live chart (the shared `CHSHChartView`) of the energy landscape with
      the optimizer's own path (`PlaygroundDocs/18VQEPLAN.md`, `PlaygroundDocs/18VQEHELP.md`).

## Open systems, measurement, and dynamics playground pages (this fork)

Four more pages, closing gaps pages 01–18 left open: every earlier page assumed a perfect,
pure, noiseless state read out by direct amplitude access, and none of them simulated physics
or interference-driven distributions. All four ship with **no `SwiftQiskit` changes**;
page 19 adds one small additive initializer to the playground's shared `BlochVector`.

- [x] Noise — page `19Noise`: the density matrix ρ = |ψ⟩⟨ψ| via the existing `Ket * Bra`
      outer product, a mixture vs. a superposition contrasted at identical Z-statistics,
      four Kraus channels (bit-flip, phase-flip, depolarizing, amplitude damping) checked for
      trace preservation, coherence decaying exactly as (1−2p)ⁿ, amplitude damping pulling the
      Bloch vector *inside* the sphere, a Monte-Carlo unraveling reproducing the exact channel
      from pure-state code alone, and a Bell pair's reduced state giving entropy exactly 1 bit
      against a product state's 0 — with a live Bloch gallery shrinking from pure to fully
      depolarized (`PlaygroundDocs/19NOISEPLAN.md`, `PlaygroundDocs/19NOISEHELP.md`).
- [x] Tomography — page `20Tomography`: reconstructing a state from `measure(shots:)` alone.
      Basis rotations — a page-level `PauliBasis` enum rather than bare strings, pinned against
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
level helpers. None of these are implemented yet; they're recorded here as the working list for
turning open-systems support into a first-class Core feature (see the Roadmap's "Noise models"
entry above):

- [ ] `Matrix.trace` — sum of the diagonal entries; retires `19Noise`'s last page-level helper.
- [ ] `DensityMatrix` type: `init(_:StateVector)`/`init(mixture:)`, `purity`, `probabilities`,
      `expectation(_:)`, `apply(_:) -> DensityMatrix`, `partialTrace(keeping:)` (generalizing
      `19Noise`'s 2-qubit `partialTraceLast` to n qubits and an arbitrary subset),
      `blochVector` (nil unless 2×2), `vonNeumannEntropy` (closed form for 2×2 via the Bloch
      magnitude; a Jacobi eigensolver for larger ρ).
- [ ] `KrausChannel` type: `operators`, `isTracePreserving(tolerance:)`, `apply(to:qubit:)`
      (embedding a 2×2 channel onto one qubit of an n-qubit ρ, the same idiom
      `CNOTGate.matrix(qubits:control:target:)` already uses for a 2×2 gate), and factories
      `bitFlip`/`phaseFlip`/`depolarizing`/`amplitudeDamping`/`phaseDamping` (the last one new —
      dephasing without energy loss, not in `19Noise`).
- [ ] Noisy circuit execution: a `NoiseModel` mapping gate applications to a `KrausChannel`,
      `QuantumCircuit.runDensityMatrix(noise:) -> DensityMatrix`, and
      `runTrajectories(noise:shots:) -> SimulationResult` (the Monte-Carlo unraveling
      generalized to full circuits). Would let page `14ErrorCorrection`'s p_L = 3p² − 2p³ be
      reproduced empirically under a real bit-flip noise model instead of one hand-injected `x`
      gate — flagged there as "not doing" in `14ERRORCORRECTIONPLAN.md`'s analogue.
- [ ] `DensityMatrix.fidelity(to:StateVector)` and `StateVector.expectation(_:Matrix)` — the
      latter would simplify `19Noise`'s `blochOf` helper to one line and help `20Tomography`,
      which measures exactly these three expectation values per qubit. The app's Chapter 22
      findings hit this same gap again independently (its `exactExpectation(_:_:)` re-derives
      the one-liner `(psi† * A * psi).real`) — see "Proposed Core extensions — tomography"
      below.
- [ ] A single package-level `BlochVector` (pure-state and `DensityMatrix`-driven initializers),
      replacing the three hand-vendored copies (`Playgrounds.playground/Sources/BlochVector.swift`,
      `SwiftQiskitApp/BlochVector.swift`, and the app's `blochOf(_:Matrix)`) — do together with
      `DensityMatrix`. The app's Chapter 22 findings add a fourth hand-vendored consumer (its
      tomography live-view section, this time for a *reconstructed* rather than exact vector).
- [ ] Tests (Swift `Testing`, shape of `AdditionalGatesTests.swift`): trace preservation for all
      five channels at a few p/γ values; `DensityMatrix.purity`/`vonNeumannEntropy` on a known
      pure state, a maximally mixed state, and a partially mixed state with a hand-computed
      eigenvalue pair; `partialTrace` qubit isolation (mirroring
      `SwiftQiskitApp/SwiftQiskitAppTests/BlochVectorTests.swift`'s reduced-vector-isolation
      test); `runTrajectories` converging to `runDensityMatrix`'s prediction within shot noise.

## Proposed Core extensions — tomography (from the app's Chapter 22 findings)

Writing the SwiftQiskitApp book's Tomography chapter (`Docs/Introduction/22-Tomography.md`)
surfaced a set of Core gaps that page `20Tomography` and that chapter both route around today
with page/app-level helpers (`~/Documents/SwiftQiskit-Chapter22-Findings.md`). None of these
are implemented yet:

- [ ] `PauliBasis` enum (`.x`/`.y`/`.z`) and `QuantumCircuit.rotateToZ(_ basis: PauliBasis, _
      qubit: Int)` appending the rotation that turns a measurement of `qubit` in that basis
      into an ordinary Z-basis read (`h` for X, `sdg; h` for Y, nothing for Z) — would replace
      page `20Tomography`'s page-level `PauliBasis`/`basisRotation` and the app chapter's
      identical string-typed version.
- [ ] `QuantumCircuit.measure(shots: Int, basis: [PauliBasis]) -> SimulationResult` — appends
      each qubit's basis rotation (applied to a copy, leaving the circuit's own operation list
      untouched), then measures. Folds the hand-appended rotate-then-measure pattern every
      estimator in page `20Tomography` (and the app chapter) repeats into the call itself.
- [ ] `StateTomography` helper: `estimate(_:qubit:result:) -> Double` ((N₀−N₁)/N from one
      basis's `SimulationResult` marginal), `reconstructSingleQubit(qubit:x:y:z:) ->
      (vector:(x:Double,y:Double,z:Double), isPhysical: Bool)` (the three-axis estimate as a
      Bloch vector, `isPhysical` = `|r| <= 1`), and `clampToPhysical(_:)` (projects an
      out-of-ball estimate back onto the unit sphere, `r -> r/|r|` — a named, tested version of
      page `20Tomography`'s rescaling idea, not a real MLE estimator). Nothing in Core today
      turns per-basis shot counts into a reconstructed state, checks physicality, or
      generalizes past one qubit.
- [ ] A real maximum-likelihood or linear-inversion reconstruction — a bigger lift than
      `StateTomography` above; a reasonable follow-up once that lands, not blocking it.
- [ ] Tests (Swift `Testing`, shape of `AdditionalGatesTests.swift`): `PauliBasis`/`rotateToZ`
      against known eigenstates (`|+i⟩` for Y, `|+⟩` for X, `|0⟩`/`|1⟩` for Z);
      `measure(shots:basis:)` reproducing page `20Tomography`'s hand-rolled estimator within
      shot noise; `StateTomography.reconstructSingleQubit` against a known pure state and a
      known mixed state (reusing the Chapter 21 proposal's `DensityMatrix` fixtures above once
      that lands).
- See also `SimulationResult.parityExpectation(qubits:)` and `StateVector.expectation(_:)` in
  the Roadmap above, and the `BlochVector`/`StateVector.expectation` carry-over notes under
  "Proposed Core extensions — open systems" — Chapter 22 hit both gaps again independently.
