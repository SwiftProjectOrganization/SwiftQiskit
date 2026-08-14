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
- `Gates/*.swift` — each gate is a `public enum` exposing `static let matrix: Matrix`
  (`HadamardGate`, `PauliXGate`, `PauliZGate`, `CNOTGate`). Follow this pattern for new gates.
  `CNOTGate` additionally offers `matrix(qubits:control:target:)` — the full 2ⁿ×2ⁿ CNOT for
  any distinct control/target pair, built as a basis-state permutation.
- `Circuit/QuantumCircuit.swift` — records operations as full 2ⁿ×2ⁿ matrices. Single-qubit
  gates are embedded across the register via `Matrix.tensor(_:)` (file-private
  `embedSingleQubitGate`). API: `h/x/z/cx`, `apply(_:)`, `run()`, `runAndMeasure()`,
  `measure(shots:)`.
- `Quantum/SimulationResult.swift` — shot counts keyed by binary state string.
- `Quantum/Dirac.swift` — Dirac notation: `Ket` (typealias of `StateVector`), `Bra`
  (conjugated row vector), postfix `†` (dagger; also `Matrix.adjoint`), `*` overloads for
  inner (`Bra * Ket`) / outer (`Ket * Bra`) products, basis kets `Ket("01")` /
  `.zero/.one/.plus/.minus/.plusI/.minusI`.

## Xcode Playgrounds

`Playgrounds.playground` at the repo root (macOS target) is this fork's main addition: interactive,
lecture-style explorations of the library. Pages live in `Playgrounds.playground/Pages/`:

- `01BellExample` — annotated Bell-state walkthrough (circuit, state vector, probabilities,
  shots), plus a 3-qubit GHZ section showcasing the general `cx` across non-adjacent qubits.
- `02Lecture_01`, `03Lecture_03`, `04Lecture_04`, … — per-lecture pages, numbered with an
  ordering prefix; follow this `NNName` naming when adding pages.
- `05BlochSphere2D`, `06BlochSphere2D+Projections` — Bloch-sphere visualizations of single-qubit states
  via SwiftUI Canvas live views, built on the shared types in
  `Playgrounds.playground/Sources/`. Bloch math stays out of Core.
- `07BlochSphere3D` — rotatable 3D Bloch sphere (perspective-projected SwiftUI Canvas,
  no SceneKit/RealityKit) with live θ/φ sliders, via the shared `Bloch3DView` /
  `BlochExplorerView`.
- `08BraKet` — Dirac-notation walkthrough (`Quantum/Dirac.swift`): inner/outer products,
  projectors, adjoints, and the page-07 initial qubit's Bloch coordinates as Pauli
  expectation values ⟨ψ|X|ψ⟩, ⟨ψ|Y|ψ⟩, ⟨ψ|Z|ψ⟩, shown on a static `Bloch3DView`.
- `09Tensor` — tensor-product walkthrough (console only) mirroring
  `Tests/SwiftQiskitCoreTests/TensorProductTests.swift` section by section: `Matrix`/
  `StateVector` `⊗`, the mixed-product identity, gate embedding vs. circuit `h(0)`, and
  why the Bell state does not factor (entanglement)
  (design notes in `Docs/TENSORPLAN.md`, user guide in `Docs/TENSORHELP.md`).
- `10DeutschExample` — Deutsch's algorithm (console only): the four 1-bit oracles from
  `x(1)`/`cx(0,1)`, a stage-by-stage phase-kickback walkthrough, deterministic
  constant-vs-balanced verdicts from a single query, and shot statistics
  (plan in `Docs/DEUTSCHPLAN.md`, user guide in `Docs/DEUTSCHHELP.md`).
- `11GroverExample` — Grover's search (console only): CZ built as `h(1);cx(0,1);h(1)`,
  X-conjugated phase oracles, an inversion-about-the-mean walkthrough, exact 1-iteration
  success on 2 qubits, over-rotation, the diffusion operator as 2|s⟩⟨s|−I via the Dirac
  outer product, and a 3-qubit finale using a hand-built CCZ through `apply(_:)`
  (plan in `Docs/GROVERPLAN.md`, user guide in `Docs/GROVERHELP.md`).
- `12ShorExample` — compiled Shor factoring of 15 (console only): modular multiplication
  and its controlled powers as hand-built permutation matrices via `apply(_:)`, an
  entrywise 8×8 QFT† embedded with `⊗`, 3-qubit phase estimation of the order r,
  classical gcd post-processing, shots sampled from one `run()` (per-shot
  `measure(shots:)` replay is too slow at dimension 128), and a base sweep including the
  a = 14 failure case (plan in `Docs/SHORPLAN.md`, user guide in `Docs/SHORHELP.md`).

Playground notes:

- Pages `import SwiftQiskitCore` and set `buildActiveScheme='true'`, so the **SwiftQiskit scheme
  must build** for pages to run — keep the library compiling at all times.
- Pages are linked sequentially with `//: [Previous](@previous)` / `//: [Next](@next)` markers.
- Code shared by multiple pages lives in `Playgrounds.playground/Sources/` — an auxiliary
  module auto-imported by every page; declarations there must be `public` (including
  explicit `public init`s). See `PLAYGROUNDSUPPORT.md` for the conventions and current API.
- Playground code is not covered by tests or `swift build`; it only runs inside Xcode.
- **Xcode 27 beta (machine-specific; still present on some Macs in beta 4, 27A5228h):**
  two evaluator bugs break SwiftUI pages — a missing `libcups.dylib` (needs a shim in
  DerivedData, wiped by clean builds and playground rebuilds) and `@State` macro expansion
  failing in page code (stateful views must live in `Sources/`). A fresh clone on another
  Mac with identical Xcode/macOS betas showed neither bug. Workarounds and the shim recipe
  are in `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds".

## Conventions & Gotchas

- **Qubit indexing:** qubit 0 is the most-significant (leftmost) bit.
- **`cx` is general:** `cx(control, target)` works for any distinct pair of qubits on an
  n-qubit circuit, via `CNOTGate.matrix(qubits:control:target:)` (permutation-matrix construction).
- Invariants are guarded with `precondition(...)` throughout; keep doing this when extending.
- Measurement result strings are zero-padded binary via `String.leftPadding` (`Utils/String+Padding.swift`).
- Style: 4-space indent, PascalCase types, camelCase members, no force unwrapping.

## Testing

- Tests live in `Tests/SwiftQiskitCoreTests/` (`BellStateTests.swift`,
  `TensorProductTests.swift`, `DiracNotationTests.swift`, `CNOTTests.swift`).
- Tests use the Swift **`Testing`** framework (`import Testing`, `@Test`, `#expect`,
  struct suites) — not XCTest.
- Measurement tests are statistical (e.g. 40–60% tolerance over 1000 shots) — expect
  probabilistic assertions, not exact counts.

## Status & Roadmap

v0.1 — see `STATUSandTODO.md` for project status, what works, the core-library roadmap
(Y/phase/rotation gates, circuit visualization, noise models, performance work), and the
fork's working TODO list.
