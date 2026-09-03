# Status and TODO

Project status, feature status, and the core-library roadmap for SwiftQiskit,
plus this fork's working TODO list.

## Project Status

**SwiftQiskit is currently in an early experimental stage (v0.1).**

- Core quantum simulation is implemented
- API is subject to change
- Performance is not yet optimized
- GUI tools are optional and under development

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
- [ ] Circuit visualization (ASCII / SwiftUI)
- [x] Noise models — addressed at the playground-example level: page `19Noise` builds Kraus
      channels (bit-flip, phase-flip, depolarizing, amplitude damping) as page-level `Matrix`
      operations. Core itself still has no `DensityMatrix` type or built-in noise simulation —
      that remains open if a first-class Core feature is wanted.
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
      the bound, the tilted observable A(θ) = cos θ·Z + sin θ·X built entrywise and measured
      via `ry(-θ)` with the sign pinned against the exact expectation value, correlators
      computed both exactly and via `measure(shots:)`, a Bell pair's S = 2√2 against a
      product-state control and a Tsirelson-bound sweep, and a `CHSHChartView` live chart
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
or interference-driven distributions. All four ship with **no `SwiftQiskitCore` changes**;
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
      Basis rotations pinned against a known Y-eigenstate, the estimator checked against exact
      expectation values, RMS error falling at the 1/√N rate, and the sharper-than-expected
      result that a *pure* state's per-axis reconstruction lands outside the Bloch ball about
      half the time at *any* N (only a genuinely mixed state's frequency shrinks toward zero) —
      plus a Bell pair's marginal reconstructed from shots and the 3ⁿ cost table explaining why
      page 18's VQE measures Pauli terms instead of the full state
      (`PlaygroundDocs/20TOMOGRAPHYPLAN.md`, `PlaygroundDocs/20TOMOGRAPHYHELP.md`).
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
