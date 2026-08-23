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
swift run SwiftQiskitGUI          # SwiftUI macOS app
```

## Targets

| Target | Path | Purpose |
|---|---|---|
| `SwiftQiskitCore` | `Sources/SwiftQiskitCore/` | Core simulation library |
| `SwiftQiskitExamples` | `Examples/` | CLI Bell-state demo |
| `SwiftQiskitGUI` | `SwiftQiskitGUI/Sources/` | SwiftUI macOS app (built with `-parse-as-library`) |

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
  one-line description, plus pointers to the `Docs/` guides. Pages are numbered with an
  ordering prefix (page order is alphabetical); follow this `NNName` naming when adding pages.
- `01Qubits` — first look at qubit states via the Dirac API, results-sidebar style
  (no prints): amplitudes, probabilities, `†`, inner/outer products, `⊗`; plus a live view
  showing `circuit1` (|0⟩ → H → P(π/2) → P(π)) and `circuit2` (|0⟩ → H → Z → H)
  stages on 2D Bloch spheres (content provisional; formerly `02Lecture_01`)
  (user guide in `Docs/01QUBITSHELP.md`).
- `02Bloch2d`, `03Bloch2dProjection` — Bloch-sphere visualizations of single-qubit states
  via SwiftUI Canvas live views, built on the shared types in
  `Playgrounds.playground/Sources/`. Bloch math stays out of Core.
  (User guide for page 02 in `Docs/02BLOCH2DHELP.md`, which also documents the general
  live-view recipe for playground pages; user guide for page 03 — a general tilted state
  plus its x–y/z–y plane projections — in `Docs/03BLOCH2DPROJECTIONHELP.md`.)
- `04Bloch3d` — rotatable 3D Bloch sphere (perspective-projected SwiftUI Canvas,
  no SceneKit/RealityKit) with live θ/φ sliders, via the shared `Bloch3DView` /
  `BlochExplorerView` (user guide in `Docs/04BLOCH3DHELP.md`).
- `05Gates` — a gentle, gate-by-gate tour of the built-in gate set in the results sidebar
  (no live view): `x/h/z/y/s/sdg/t/p/rx/ry/rz` each shown individually on a 1-qubit
  `QuantumCircuit`, plus a one-line `h`+`cx` Bell-state teaser pointing to
  `07Entanglement` (formerly `03Lecture_02`; user guide in `Docs/05GATESHELP.md`).
- `06Superposition` — a 4-qubit console walkthrough: every qubit put into superposition
  via `h`, inspecting the resulting 16-state amplitudes/probabilities and shot counts,
  plus a partial-superposition (2-qubit) contrast
  (user guide in `Docs/06SUPERPOSITIONHELP.md`).
- `07Entanglement` — annotated Bell-state walkthrough (circuit, state vector, probabilities,
  shots), plus a 3-qubit GHZ section showcasing the general `cx` across non-adjacent qubits
  (user guide in `Docs/07ENTANGLEMENTHELP.md`).
- `08Dirac` — Dirac-notation walkthrough (`Quantum/Dirac.swift`): inner/outer products,
  projectors, adjoints, and the page-04 initial qubit's Bloch coordinates as Pauli
  expectation values ⟨ψ|X|ψ⟩, ⟨ψ|Y|ψ⟩, ⟨ψ|Z|ψ⟩, shown on a static `Bloch3DView`
  (user guide in `Docs/08DIRACHELP.md`).
- `09Tensor` — tensor-product walkthrough (console only) mirroring
  `Tests/SwiftQiskitCoreTests/TensorProductTests.swift` section by section: `Matrix`/
  `StateVector` `⊗`, the mixed-product identity, gate embedding vs. circuit `h(0)`, and
  why the Bell state does not factor (entanglement)
  (design notes in `Docs/09TENSORPLAN.md`, user guide in `Docs/09TENSORHELP.md`).
- `10DeutschExample` — Deutsch's algorithm (console only): the four 1-bit oracles from
  `x(1)`/`cx(0,1)`, a stage-by-stage phase-kickback walkthrough, deterministic
  constant-vs-balanced verdicts from a single query, and shot statistics
  (plan in `Docs/10DEUTSCHPLAN.md`, user guide in `Docs/10DEUTSCHHELP.md`).
- `11GroverExample` — Grover's search (console only): CZ built as `h(1);cx(0,1);h(1)`,
  X-conjugated phase oracles, an inversion-about-the-mean walkthrough, exact 1-iteration
  success on 2 qubits, over-rotation, the diffusion operator as 2|s⟩⟨s|−I via the Dirac
  outer product, and a 3-qubit finale using a hand-built CCZ through `apply(_:)`
  (plan in `Docs/11GROVERPLAN.md`, user guide in `Docs/11GROVERHELP.md`).
- `12ShorExample` — compiled Shor factoring of 15 (console only): modular multiplication
  and its controlled powers as hand-built permutation matrices via `apply(_:)`, an
  entrywise 8×8 QFT† embedded with `⊗`, 3-qubit phase estimation of the order r,
  classical gcd post-processing, shots sampled from one `run()` (per-shot
  `measure(shots:)` replay is too slow at dimension 128), and a base sweep including the
  a = 14 failure case (plan in `Docs/12SHORPLAN.md`, user guide in `Docs/12SHORHELP.md`).

Playground notes:

- Pages `import SwiftQiskitCore` and set `buildActiveScheme='true'`, so the **SwiftQiskit scheme
  must build** for pages to run — keep the library compiling at all times.
- Pages are linked sequentially with `//: [Previous](@previous)` / `//: [Next](@next)` markers.
- Code shared by multiple pages lives in `Playgrounds.playground/Sources/` — an auxiliary
  module auto-imported by every page; declarations there must be `public` (including
  explicit `public init`s). See `PLAYGROUNDSUPPORT.md` for the conventions and current API.
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
