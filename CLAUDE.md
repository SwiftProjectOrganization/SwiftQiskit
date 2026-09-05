# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

SwiftQiskit is a lightweight, educational quantum-computing simulator written in pure Swift,
offering a Qiskit-like API. It is experimental (v0.1): the API is unstable and correctness is
prioritized over performance. This fork adds Xcode playground usage (`Playgrounds.playground`).

## Build, Run & Test

From Xcode, prefer the `xcode-tools` MCP tools (`BuildProject`, `RunProject`, `RunAllTests`).

CLI equivalents:

```bash
swift build                        # build everything
swift test                        # run unit tests
swift run SwiftQiskitExamples     # Bell-state CLI demo
swift run SwiftQiskitGUI          # SwiftUI macOS/iOS app
```

## Targets

| Target | Path | Purpose |
|---|---|---|
| `SwiftQiskitCore` | `Sources/SwiftQiskitCore/` | Core simulation library |
| `SwiftQiskitExamples` | `Examples/` | CLI Bell-state demo |
| `SwiftQiskitGUI` | `Sources/SwiftQiskitGUI/` | SwiftUI macOS/iOS app (built with `-parse-as-library`); `ContentView` picks a regular (macOS/iPad) or compact (iPhone) layout by size class |

**Import gotcha:** the library *product* is named `SwiftQiskit` but the *module* is
`SwiftQiskitCore` — always `import SwiftQiskitCore`.

## Architecture (bottom-up)

- `Math/Complex.swift` — value-type complex numbers (`+ - * /`, scalar mul, `.zero/.one/.i`).
- `Math/Matrix.swift` — row-major complex matrix; `*`, `multiply(by:)` (matrix × vector),
  `identity(size:)`, Kronecker product `tensor(_:)` / `⊗` (the `⊗` operator is declared here).
- `Quantum/StateVector.swift` — amplitudes; auto-normalizes on init and `apply(_:)`;
  `measure()` is probabilistic and **collapses (mutates) the state**; `tensor(_:)` / `⊗`
  combines registers (`self` in the high-order bits, per the qubit-0-is-MSB convention).
- `Gates/*.swift` — each fixed gate is a `public enum` exposing `static let matrix: Matrix`
  (`HadamardGate`, `PauliXGate`, `PauliYGate`, `PauliZGate`, `SGate`/`SDaggerGate`,
  `TGate`/`TDaggerGate`, `CNOTGate`); parameterized gates expose
  `static func matrix(theta:)` instead (`PhaseGate` P(θ) in `Phase.swift`,
  `RXGate`/`RYGate`/`RZGate` in `Rotation.swift`). Follow these patterns for new gates.
  `CNOTGate` additionally offers `matrix(qubits:control:target:)` — the full 2ⁿ×2ⁿ CNOT for
  any distinct control/target pair, built as a basis-state permutation.
- `Circuit/QuantumCircuit.swift` — records operations as full 2ⁿ×2ⁿ matrices. Single-qubit
  gates are embedded across the register via `Matrix.tensor(_:)` (file-private
  `embedSingleQubitGate`). API: `h/x/y/z/s/sdg/t/tdg/cx`, parameterized
  `p/rx/ry/rz(_ theta:, _ qubit:)` (θ first, as in Qiskit), `apply(_:)`, `run()`,
  `runAndMeasure()`, `measure(shots:)`.
- `Quantum/SimulationResult.swift` — shot counts keyed by binary state string.
- `Quantum/Dirac.swift` — Dirac notation: `Ket` (typealias of `StateVector`), `Bra`
  (conjugated row vector), postfix `†` (dagger; also `Matrix.adjoint`), `*` overloads for
  inner (`Bra * Ket`) / outer (`Ket * Bra`) products and `Bra * Matrix -> Bra` (enables
  expectation values `psi† * U * psi`), mixed `⊗` overloads (`Ket ⊗ Bra` /
  `Bra ⊗ Ket`, both returning the outer-product `Matrix`), basis kets `Ket("01")` /
  `.zero/.one/.plus/.minus/.plusI/.minusI`.

## Xcode Playgrounds

`Playgrounds.playground` at the repo root (macOS target) is this fork's main addition: interactive,
lecture-style explorations of the library. Pages live in `Playgrounds.playground/Pages/`:

- `00TOC` — clickable table of contents (markdown only): links to every page with a
  one-line description, plus pointers to the `PlaygroundDocs/` guides. Pages are numbered with an
  ordering prefix (page order is alphabetical); follow this `NNName` naming when adding pages.
- `01Qubits` — first look at qubit states via the Dirac API, results-sidebar style
  (no prints): amplitudes, probabilities, `†`, inner/outer products, `⊗`; plus a live view
  showing `circuit1` (|0⟩ → H → P(π/2) → P(π)) and `circuit2` (|0⟩ → H → Z → H)
  stages on 2D Bloch spheres (content provisional; formerly `02Lecture_01`)
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
  `Tests/SwiftQiskitCoreTests/TensorProductTests.swift` section by section: `Matrix`/
  `StateVector` `⊗`, the mixed-product identity, gate embedding vs. circuit `h(0)`, and
  why the Bell state does not factor (entanglement)
  (design notes in `PlaygroundDocs/09TENSORPLAN.md`, user guide in `PlaygroundDocs/09TENSORHELP.md`).
- `10DeutschExample` — Deutsch's algorithm (console only): the four 1-bit oracles from
  `x(1)`/`cx(0,1)`, a stage-by-stage phase-kickback walkthrough, deterministic
  constant-vs-balanced verdicts from a single query, and shot statistics
  (plan in `PlaygroundDocs/10DEUTSCHPLAN.md`, user guide in `PlaygroundDocs/10DEUTSCHHELP.md`).
- `11GroverExample` — Grover's search (console only): CZ built as `h(1);cx(0,1);h(1)`,
  X-conjugated phase oracles, an inversion-about-the-mean walkthrough, exact 1-iteration
  success on 2 qubits, over-rotation, the diffusion operator as 2|s⟩⟨s|−I via the Dirac
  outer product, and a 3-qubit finale using a hand-built CCZ through `apply(_:)`
  (plan in `PlaygroundDocs/11GROVERPLAN.md`, user guide in `PlaygroundDocs/11GROVERHELP.md`).
- `12ShorExample` — compiled Shor factoring of 15 (console only): modular multiplication
  and its controlled powers as hand-built permutation matrices via `apply(_:)`, an
  entrywise 8×8 QFT† embedded with `⊗`, 3-qubit phase estimation of the order r,
  classical gcd post-processing, shots sampled from one `run()` (per-shot
  `measure(shots:)` replay is too slow at dimension 128), and a base sweep including the
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
  and syndrome extraction onto two ancillas, a hand-built 32×32 permutation correction via
  `apply(_:)` (Core has no Toffoli), an `rx(θ)` sweep showing a continuous error digitized
  to exact fidelity 1.0000 at every θ, the distance-3 failure mode (two errors alias to a
  wrong syndrome, giving a silent logical X) with the enumerated logical error rate
  p_L = 3p² − 2p³, and phase-flip protection via Hadamard conjugation (H Z H = X); Bloch
  live view of corrected vs. uncorrected q0
  (plan in `PlaygroundDocs/14ERRORCORRECTIONPLAN.md`, user guide in `PlaygroundDocs/14ERRORCORRECTIONHELP.md`).
- `15CHSH` — the CHSH inequality: all 16 deterministic local-hidden-variable strategies
  enumerated exhaustively (max |S| = 2), plus a shared-direction hidden-variable model that
  saturates the bound and doubles as the classical comparison curve; the tilted observable
  A(θ) = cos θ·Z + sin θ·X built entrywise (no `+`/scalar ops on `Matrix`) and measured via
  `ry(-θ)` with its sign pinned against the exact expectation value; correlators computed
  both exactly (`psi† * (A(a) ⊗ A(b)) * psi`) and via `measure(shots:)`; a Bell pair's
  S = 2√2 against a product-state control and a Tsirelson-bound sweep; a `CHSHChartView`
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
  minimal basis) built entrywise from six Pauli terms, a one-parameter ansatz
  `x(0); ry(θ,1); cx(1,0)` provably confined to the `{|01⟩,|10⟩}` subspace, the energy via
  `psi† * H * psi`, a closed-form 2×2 eigenvalue for grading, *exact* parameter-shift
  gradients pinned against a finite difference, gradient descent converging to error
  0.00e+00, and a live chart of the E(θ) landscape with the optimizer's own path, on the
  shared `CHSHChartView` (plan in `PlaygroundDocs/18VQEPLAN.md`, user guide in `PlaygroundDocs/18VQEHELP.md`).
- `19Noise` — open systems (no Core changes): the density matrix ρ = |ψ⟩⟨ψ| via the existing
  `Ket * Bra` outer product; a classical mixture vs. a superposition at identical
  Z-statistics; four Kraus channels (bit-flip, phase-flip, depolarizing, amplitude damping)
  checked for trace preservation; coherence decaying exactly as `(1-2p)ⁿ`; amplitude damping
  pulling the Bloch vector *inside* the sphere; a Monte-Carlo unraveling reproducing the exact
  channel from pure-state code alone; and a Bell pair's reduced state giving entropy exactly 1
  bit against a product state's 0; live Bloch gallery shrinking from pure to fully
  depolarized, via the additive `BlochVector.init(x:y:z:)`
  (plan in `PlaygroundDocs/19NOISEPLAN.md`, user guide in `PlaygroundDocs/19NOISEHELP.md`).
- `20Tomography` — reconstructing a state from `measure(shots:)` alone: basis rotations
  (`h` for X, `sdg;h` for Y) pinned against a known Y-eigenstate rather than assumed; the
  estimator's 1/√N error scaling; the sharper-than-expected result that a *pure* state's
  per-axis reconstruction lands outside the Bloch ball about half the time at *any* N (only a
  genuinely mixed state's frequency, page 19's territory, shrinks toward zero); a Bell pair's
  marginal reconstructed from shots alone; and the 3ⁿ-settings cost table motivating page 18's
  per-term Pauli measurements; live view of the true vs. reconstructed Bloch point
  (plan in `PlaygroundDocs/20TOMOGRAPHYPLAN.md`, user guide in `PlaygroundDocs/20TOMOGRAPHYHELP.md`).
- `21Trotter` — Hamiltonian simulation of a transverse-field Ising chain (no Core changes): a
  page-level `expm` (scaling-and-squaring Taylor series) self-checked against `RXGate`; the
  exact gate identity `exp(-iθ·Z⊗Z/2) = cx(0,1); rz(θ,1); cx(0,1)` derived from `RZGate` and
  checked against `expm`; first- and second-order Trotter error shrinking at the textbook
  O(1/n)/O(1/n²) rates, both at the operator level and the observable level (⟨Z₀⟩(t)); and the
  non-zero commutator `[Z⊗Z, X⊗I]` identified as the error's source (a commuting-only
  Hamiltonian is exact at n=1); live chart of the exact curve against Trotterized samples on
  the shared `CHSHChartView` (plan in `PlaygroundDocs/21TROTTERPLAN.md`, user guide in
  `PlaygroundDocs/21TROTTERHELP.md`).
- `22Walk` — the discrete-time coined quantum walk on a 16-site cycle (no Core changes): a
  hand-built conditional-shift permutation checked as unitary; ballistic (∝t) spreading
  against an exactly diffusive (∝√t) classical random walk; a caught-and-documented
  cyclic-coordinate variance bug (raw site indices vs. signed offsets from the start); and the
  `|0⟩`-vs-`|+i⟩` coin contrast showing the walk's asymmetry is interference, not a flaw; live
  chart of both final distributions on the shared `CHSHChartView`, with cross-references to
  Grover (page 11) and Hamiltonian simulation (page 21)
  (plan in `PlaygroundDocs/22WALKPLAN.md`, user guide in `PlaygroundDocs/22WALKHELP.md`).

Playground notes:

- Pages `import SwiftQiskitCore` and set `buildActiveScheme='true'`, so the **SwiftQiskit scheme
  must build** for pages to run — keep the library compiling at all times.
- Pages are linked sequentially with `//: [Previous](@previous)` / `//: [Next](@next)` markers.
- Code shared by multiple pages lives in `Playgrounds.playground/Sources/` — an auxiliary
  module auto-imported by every page; declarations there must be `public` (including
  explicit `public init`s). See `PLAYGROUNDSUPPORT.md` for the conventions and current
  API, and `PlaygroundDocs/90LIVEVIEWHELP.md` for the user-facing guide (usage snippets, the
  live-view recipe, troubleshooting).
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
- **`cx` is general:** `cx(control, target)` works for any distinct pair of qubits on an
  n-qubit circuit, via `CNOTGate.matrix(qubits:control:target:)` (permutation-matrix construction).
- Invariants are guarded with `precondition(...)` throughout; keep doing this when extending.
- Measurement result strings are zero-padded binary via `String.leftPadding` (`Utils/String+Padding.swift`).
- Style: 4-space indent, PascalCase types, camelCase members, no force unwrapping.

## Testing

- Tests live in `Tests/SwiftQiskitCoreTests/` (`BellStateTests.swift`,
  `TensorProductTests.swift`, `DiracNotationTests.swift`, `CNOTTests.swift`,
  `AdditionalGatesTests.swift`).
- Tests use the Swift **`Testing`** framework (`import Testing`, `@Test`, `#expect`,
  struct suites) — not XCTest.
- **Scheme gotcha for Xcode test runs:** all schemes are autogenerated by Xcode for the
  SPM package (no `.xcscheme`/`.xctestplan` files on disk). The per-product `SwiftQiskit`
  scheme's implicit test plan contains **no test targets**, so `RunAllTests`/`GetTestList`
  report 0 tests under it — run tests under the `SwiftQiskit-Package` scheme instead
  (its plan includes `SwiftQiskitCoreTests`). `swift test` from the repo root works
  regardless of the active scheme.
- Measurement tests are statistical (e.g. 40–60% tolerance over 1000 shots) — expect
  probabilistic assertions, not exact counts.

## Status & Roadmap

v0.1 — see `STATUSandTODO.md` for project status, what works, the core-library roadmap
(circuit visualization, noise models, performance work), and the fork's working TODO list.
