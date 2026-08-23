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
  (see `Docs/09TENSORPLAN.md` and the user guide `Docs/09TENSORHELP.md`)
- Dirac notation: `Ket`/`Bra`, postfix `†`, inner/outer products
  (`Quantum/Dirac.swift`, demonstrated in playground page `08Dirac`;
  user guide `Docs/08DIRACHELP.md`)
- Bell State example
- Unit tests for correctness

## Roadmap

- [x] General multi-qubit CNOT support
- [x] Additional gates (Y, Phase, Rotation gates)
      → `Gates/PauliY.swift`, `Gates/Phase.swift` (P(θ), S, S†, T, T†),
      `Gates/Rotation.swift` (RX/RY/RZ); circuit API `y/s/sdg/t/tdg/p/rx/ry/rz`,
      tested in `AdditionalGatesTests.swift`
- [ ] Circuit visualization (ASCII / SwiftUI)
- [ ] Noise models
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
- [x] User guide for the 2D Bloch sphere page — `Docs/02BLOCH2DHELP.md`: the Bloch map
      α, β → (x, y, z), page walkthrough and exact expected output, how the oblique
      projection reads, and the general recipe for putting a SwiftUI live view on a
      playground page (explicit root frame, stateless-inline vs. `@State`-in-`Sources/`).
- [x] User guide for the tilted-qubit/plane-projection page —
      `Docs/03BLOCH2DPROJECTIONHELP.md`: the direction-cosine derivation of θ/φ, exact
      expected console output for the round-trip check, and how to read the two
      `BlochProjectionView` panels (including why the x–y panel flips its vertical axis).
- [x] User guide for the 3D Bloch sphere page — `Docs/04BLOCH3DHELP.md`: the θ/φ
      parametrization and why its two sliders are independent, exact expected console
      output, the orbit-camera/perspective-projection model behind `Bloch3DView`
      (near/far wireframe opacity, silhouette scaling, drag-to-orbit), and how the page's
      starting state matches page `08Dirac`'s initial qubit.

## Bra/ket & tensor-product additions (this fork)

- [x] First-look Dirac walkthrough — page `01Qubits`: qubit states via the Dirac API in
      the results sidebar (no prints), plus circuit stage tracking shown live on 2D
      Bloch spheres, with the user guide `Docs/01QUBITSHELP.md`.
- [x] Dirac notation in Core (`Quantum/Dirac.swift`): `Ket`/`Bra`, postfix `†`,
      inner/outer products, basis kets — with `DiracNotationTests.swift`,
      playground page `08Dirac` (Pauli expectation values on a `Bloch3DView`),
      and the user guide `Docs/08DIRACHELP.md`.
- [x] Tensor (Kronecker) products in Core: `tensor(_:)` / `⊗` on `Matrix` and
      `StateVector`; `QuantumCircuit` gate embedding now reuses `Matrix.tensor(_:)`
      — with `TensorProductTests.swift`, playground page `09Tensor`, the
      design notes in `Docs/09TENSORPLAN.md`, and the user guide `Docs/09TENSORHELP.md`.

## Gate-tour and entanglement playground pages (this fork)

- [x] Gate-by-gate tour — page `05Gates`: every built-in gate
      (`x/h/z/y/s/sdg/t/p/rx/ry/rz`) shown individually on a 1-qubit `QuantumCircuit`,
      plus a one-line `h`+`cx` Bell-state teaser, with the user guide
      `Docs/05GATESHELP.md`.
- [x] 4-qubit superposition — page `06Superposition`: every qubit put into
      superposition via `h`, 16-state amplitude/probability/shot inspection, and a
      partial-superposition contrast, with the user guide `Docs/06SUPERPOSITIONHELP.md`.
- [x] Entanglement walkthrough — page `07Entanglement`: the Bell state via `h`+`cx`
      with full amplitude/probability/measurement annotation, plus a 3-qubit GHZ
      state using `cx` across non-adjacent qubits, with the user guide
      `Docs/07ENTANGLEMENTHELP.md`.

## Algorithm playground pages (this fork)

Console-only walkthroughs of the canonical quantum algorithms, each with design
notes (`Docs/*PLAN.md`) and a user guide (`Docs/*HELP.md`):

- [x] Deutsch's algorithm — page `10DeutschExample`: the four 1-bit oracles from
      `x(1)`/`cx(0,1)`, phase kickback stage by stage, and deterministic
      constant-vs-balanced verdicts from a single query
      (`Docs/10DEUTSCHPLAN.md`, `Docs/10DEUTSCHHELP.md`).
- [x] Grover's search — page `11GroverExample`: CZ built as `h(1); cx(0,1); h(1)`,
      X-conjugated phase oracles, inversion about the mean, the diffusion operator
      as 2|s⟩⟨s| − I via the Dirac outer product, and a 3-qubit finale with a
      hand-built CCZ (`Docs/11GROVERPLAN.md`, `Docs/11GROVERHELP.md`).
- [x] Shor's algorithm (compiled, N = 15) — page `12ShorExample`: modular
      multiplication and its controlled powers as hand-built permutation matrices,
      an entrywise 8×8 QFT† embedded with `⊗`, 3-qubit phase estimation of the
      order r, classical gcd post-processing, and a base sweep including the
      a = 14 failure case (`Docs/12SHORPLAN.md`, `Docs/12SHORHELP.md`).
