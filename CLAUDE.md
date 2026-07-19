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
- `Math/Matrix.swift` — row-major complex matrix; `*`, `multiply(by:)` (matrix × vector), `identity(size:)`.
- `Quantum/StateVector.swift` — amplitudes; auto-normalizes on init and `apply(_:)`;
  `measure()` is probabilistic and **collapses (mutates) the state**.
- `Gates/*.swift` — each gate is a `public enum` exposing `static let matrix: Matrix`
  (`HadamardGate`, `PauliXGate`, `PauliZGate`, `CNOTGate`). Follow this pattern for new gates.
- `Circuit/QuantumCircuit.swift` — records operations as full 2ⁿ×2ⁿ matrices. Single-qubit
  gates are embedded across the register via Kronecker products (file-private
  `embedSingleQubitGate` / `kron`). API: `h/x/z/cx`, `apply(_:)`, `run()`, `runAndMeasure()`,
  `measure(shots:)`.
- `Quantum/SimulationResult.swift` — shot counts keyed by binary state string.

## Xcode Playgrounds

`Playgrounds.playground` at the repo root (macOS target) is this fork's main addition: interactive,
lecture-style explorations of the library. Pages live in `Playgrounds.playground/Pages/`:

- `01BellExample` — annotated Bell-state walkthrough (circuit, state vector, probabilities, shots).
- `02Lecture_01`, `03Lecture_03`, `04Lecture_04`, … — per-lecture pages, numbered with an
  ordering prefix; follow this `NNName` naming when adding pages.
- `05BlochSphere` — Bloch-sphere visualization of single-qubit states (|0⟩, |1⟩, |+⟩, |−⟩)
  via a SwiftUI Canvas live view; Bloch math is inline in the page, not in Core.

Playground notes:

- Pages `import SwiftQiskitCore` and set `buildActiveScheme='true'`, so the **SwiftQiskit scheme
  must build** for pages to run — keep the library compiling at all times.
- Pages are linked sequentially with `//: [Previous](@previous)` / `//: [Next](@next)` markers.
- Playground code is not covered by tests or `swift build`; it only runs inside Xcode.

## Conventions & Gotchas

- **Qubit indexing:** qubit 0 is the most-significant (leftmost) bit.
- **`cx` v0.1 limitation:** only 2-qubit circuits and only `cx(0, 1)` — enforced by preconditions.
- Invariants are guarded with `precondition(...)` throughout; keep doing this when extending.
- Measurement result strings are zero-padded binary via `String.leftPadding` (`Utils/String+Padding.swift`).
- Style: 4-space indent, PascalCase types, camelCase members, no force unwrapping.

## Testing

- Tests live in `Tests/SwiftQiskitCoreTests/` (currently `BellStateTests.swift`).
- Tests use the Swift **`Testing`** framework (`import Testing`, `@Test`, `#expect`,
  struct suites) — not XCTest.
- Measurement tests are statistical (e.g. 40–60% tolerance over 1000 shots) — expect
  probabilistic assertions, not exact counts.

## Status & Roadmap

v0.1 — see README for the roadmap (general multi-qubit CNOT, Y/phase/rotation gates,
circuit visualization, noise models, performance work).
