# SwiftQiskit 

**SwiftQiskit** is a lightweight **quantum computing simulator** written entirely in **Swift**.  
It brings a **Qiskit-like experience** to the Apple ecosystem, with a strong focus on **clarity**, **correctness**, and **future GUI integration**.

>  This project is **experimental and educational**, but grounded in real quantum mechanics principles

Differences between this forked repository ("**fork**") and its [parent](https://github.com/a360n/SwiftQiskit):
1. The usage of Xcode playgrounds.
2. Showing of Bloch spheres (in live playgrounds).
3. Using Swift Testing.

---

##  Features

- ✅ Complex number arithmetic  
- ✅ Matrix operations (including Kronecker products)  
- ✅ Tensor products: `tensor(_:)` / `⊗` on `Matrix` and `StateVector`  
- ✅ Dirac (bra–ket) notation: `Ket`/`Bra`, postfix `†` (dagger), inner & outer products  
- ✅ State vector simulation  
- ✅ Quantum gates (see the gate tables below):
  - Hadamard (H)
  - Pauli-X (X)
  - Pauli-Y (Y)
  - Pauli-Z (Z)
  - Phase gates: S, S†, T, T†, and the general P(θ)
  - Rotations: RX(θ), RY(θ), RZ(θ)
  - CNOT (Controlled-NOT)
- ✅ Single-qubit gate embedding  
- ✅ Quantum circuit abstraction  
- ✅ Measurement & state collapse  
- ✅ Bell State (Entanglement) example  

---

##  Special Qubit States

Named single-qubit basis kets, defined as `Ket` (= `StateVector`) constants in
`Sources/SwiftQiskitCore/Quantum/Dirac.swift`:

| Constant | State | Definition | Bloch sphere |
|----------|-------|------------|--------------|
| `.zero` | \|0⟩ | (1, 0) | +z (north pole) |
| `.one` | \|1⟩ | (0, 1) | −z (south pole) |
| `.plus` | \|+⟩ | (\|0⟩ + \|1⟩)/√2 | +x |
| `.minus` | \|−⟩ | (\|0⟩ − \|1⟩)/√2 | −x |
| `.plusI` | \|i⟩ | (\|0⟩ + i\|1⟩)/√2 | +y |
| `.minusI` | \|−i⟩ | (\|0⟩ − i\|1⟩)/√2 | −y |

Multi-qubit basis kets come from the binary-label initializer, e.g. `Ket("01")` = |01⟩
(qubit 0 is the most-significant bit), with `Bra("01")` as the matching bra.

---

##  Quantum Gates


**Built-in gates** — each is a `public enum` in `Sources/SwiftQiskitCore/Gates/` exposing
`static let matrix: Matrix` (parameterized gates expose `static func matrix(theta:)`),
with a matching convenience method on `QuantumCircuit`:

| Gate | Circuit API | Type | Used in |
|------|-------------|------|---------|
| Hadamard (H) | `h(qubit)` | `HadamardGate` | Bell example; all five test suites; playground pages 02, 05, 07–12 |
| Pauli-X (X) | `x(qubit)` | `PauliXGate` | `TensorProductTests`; pages 02, 07–12 |
| Pauli-Y (Y) | `y(qubit)` | `PauliYGate` | `AdditionalGatesTests`; page 08 (Y† == Y, ⟨ψ\|Y\|ψ⟩) |
| Pauli-Z (Z) | `z(qubit)` | `PauliZGate` | `DiracNotationTests`; pages 02, 06–08 |
| S / S† | `s(qubit)` / `sdg(qubit)` | `SGate` / `SDaggerGate` | `AdditionalGatesTests`; page 02 (the \|±i⟩ states) |
| T / T† | `t(qubit)` / `tdg(qubit)` | `TGate` / `TDaggerGate` | `AdditionalGatesTests` |
| Phase P(θ) | `p(theta, qubit)` | `PhaseGate` | `AdditionalGatesTests` |
| RX/RY/RZ (θ) | `rx/ry/rz(theta, qubit)` | `RXGate` / `RYGate` / `RZGate` | `AdditionalGatesTests` |
| CNOT (CX) | `cx(control, target)` — any distinct pair | `CNOTGate` (also `matrix(qubits:control:target:)`) | Bell example; `BellStateTests`, `CNOTTests`; pages 05, 07–11 |

**Hand-built gates** — constructed in tests/playgrounds from raw `Matrix` values or gate
compositions and applied with `circuit.apply(_:)`; not (yet) part of Core:

| Gate | Built from | Where |
|------|------------|-------|
| Pauli-Y (Y) | raw 2×2 `Matrix` | `DiracNotationTests` (adjoint of a non-symmetric matrix — the test predates `PauliYGate`) |
| Identity / hand-rolled X | raw `Matrix`/`Complex` values | page 06 |
| CZ | `h(1); cx(0,1); h(1)` | page 11 (phase oracles and diffusion operator) |
| CCZ | `Matrix.identity(size: 8)` with the \|111⟩ entry set to −1 | page 11 (3-qubit Grover finale) |
| Modular multiplication U_a (mod 15) | 16×16 / 128×128 basis-state permutations — one `.one` per column; the controlled versions key on a counting bit | page 12 (Shor order finding) |
| QFT† (3-qubit inverse Fourier) | 8×8 inverse-DFT matrix built entrywise from `cos`/`sin`, embedded as `qftDagger ⊗ I₁₆` | page 12 (phase-estimation readout) |

---

##  Special Operators

Custom operators on the quantum types (`Ket` = `StateVector`): the postfix dagger `†` is
declared in `Sources/SwiftQiskitCore/Quantum/Dirac.swift`, and the infix tensor product `⊗`
(at `MultiplicationPrecedence`) in `Sources/SwiftQiskitCore/Math/Matrix.swift`:

| Operator | Expression | Result | Meaning | Defined in |
|----------|------------|--------|---------|------------|
| `†` | `Ket†` | `Bra` | ⟨ψ\| = (\|ψ⟩)† | `Quantum/Dirac.swift` |
| `†` | `Bra†` | `Ket` | \|ψ⟩ = (⟨ψ\|)† | `Quantum/Dirac.swift` |
| `†` | `Matrix†` | `Matrix` | adjoint U† (also `Matrix.adjoint`) | `Quantum/Dirac.swift` |
| `⊗` | `Matrix ⊗ Matrix` | `Matrix` | Kronecker product A ⊗ B (also `tensor(_:)`) | `Math/Matrix.swift` |
| `⊗` | `Ket ⊗ Ket` | `Ket` | \|a⟩ ⊗ \|b⟩ — combines registers, lhs in the high-order bits (also `tensor(_:)`) | `Quantum/StateVector.swift` |
| `⊗` | `Bra ⊗ Bra` | `Bra` | ⟨a\| ⊗ ⟨b\| (also `tensor(_:)`) | `Quantum/Dirac.swift` |
| `⊗` | `Ket ⊗ Bra` | `Matrix` | mixed product = the outer product \|a⟩⟨b\| | `Quantum/Dirac.swift` |
| `⊗` | `Bra ⊗ Ket` | `Matrix` | mixed product ⟨a\| ⊗ \|b⟩ = \|b⟩⟨a\| | `Quantum/Dirac.swift` |
| `*` | `Bra * Ket` | `Complex` | inner product ⟨φ\|ψ⟩ | `Quantum/Dirac.swift` |
| `*` | `Ket * Bra` | `Matrix` | outer product \|ψ⟩⟨φ\| | `Quantum/Dirac.swift` |
| `*` | `Bra * Matrix` | `Bra` | ⟨ψ\|U — enables expectation values `ψ† * U * ψ` | `Quantum/Dirac.swift` |
| `*` | `Matrix * Matrix` | `Matrix` | matrix product AB | `Math/Matrix.swift` |

Scalar `Complex` arithmetic (`+ - * /` and `Double` scaling) lives in `Math/Complex.swift`
and is not listed here — it acts on numbers, not on qubit states or gates.

---

##  Design Philosophy

* No hidden magic — everything is **explicit and readable**
* Mathematical correctness over shortcuts
* Modular architecture (**Core / Examples / GUI-ready**)
* Designed for **learning**, **experimentation**, and **extension**

---

##  Final Note

**SwiftQiskit** is not just a simulator —
it’s an attempt to make **quantum computing accessible, visual, and native** on Apple platforms.

Enjoy exploring the quantum world 

---

##  Project Structure for this fork

```text
SwiftQiskit/
├── Sources/
│   └── SwiftQiskitCore/
│       ├── Math/
│       │   ├── Complex.swift
│       │   └── Matrix.swift
│       ├── Quantum/
│       │   ├── StateVector.swift
│       │   ├── Dirac.swift
│       │   └── SimulationResult.swift
│       ├── Gates/
│       │   ├── Hadamard.swift
│       │   ├── PauliX.swift
│       │   ├── PauliZ.swift
│       │   └── CNOT.swift
│       └── Circuit/
│           └── QuantumCircuit.swift
├── Examples/
│   └── main.swift
├── Tests/
│   └── SwiftQiskitCoreTests/
│       ├── BellStateTests.swift
│       ├── TensorProductTests.swift
│       ├── DiracNotationTests.swift
│       └── CNOTTests.swift
├── Docs/
│   ├── 01QUBITSHELP.md
│   ├── 02BLOCH2DHELP.md
│   ├── 05GATESHELP.md
│   ├── 08DIRACHELP.md
│   ├── 09TENSORPLAN.md
│   ├── 09TENSORHELP.md
│   ├── 10DEUTSCHPLAN.md
│   ├── 10DEUTSCHHELP.md
│   ├── 11GROVERPLAN.md
│   ├── 11GROVERHELP.md
│   ├── 12SHORPLAN.md
│   └── 12SHORHELP.md
├── Playgrounds.playground/
│   ├── Sources/            (code shared by all pages — see PLAYGROUNDSUPPORT.md)
│   └── Pages/
│       ├── 00TOC
│       ├── 01Qubits
│       ├── 02Bloch2d
│       ├── 03Bloch2dProjection
│       ├── 04Bloch3d
│       ├── 05Gates
│       ├── 06Superposition
│       ├── 07Entanglement
│       ├── 08BraKet
│       ├── 09Tensor
│       ├── 10DeutschExample
│       ├── 11GroverExample
│       └── 12ShorExample
└── References (tbd)
└── Package.swift
```

---

##  Getting Started with this fork

### Requirements

* Swift **6.3+**
* macOS **27+**
- Xcode 27.0  

This forked repository is developed using Swift 6.3+ and MacOS 27.0-beta

---

### Clone the Repository

Open Xcode, go to `Integrate` and clone "https://github.com/SwiftProjectOrganization/SwiftQiskit".

### Run the Bell State Example

```bash
swift run SwiftQiskitExamples
```

---

## 🔗 Bell State Example (Entanglement)

The Bell state **|Φ⁺⟩** is defined as:

```
|Φ⁺⟩ = (|00⟩ + |11⟩) / √2
```

### Code Example

```swift
import SwiftQiskitCore

let circuit = QuantumCircuit(qubits: 2)

circuit.h(0)
circuit.apply(CNOTGate.matrix)

let finalState = circuit.run()
print(finalState)

for _ in 0..<10 {
    let result = circuit.runAndMeasure()
    print(result)
}
```
> Note: The core module is currently imported as `SwiftQiskitCore`.

### Expected Measurement Output

```text
00
11
00
11
11
00
```

>  States **01** and **10** never appear —
> this confirms **quantum entanglement**.
> Measurement outputs are probabilistic and may vary per run.

---

##  Playgrounds

`Playgrounds.playground` (at the repo root, macOS target) contains interactive, lecture-style
explorations of the library. Open it in Xcode — pages build against the `SwiftQiskit` scheme
and are linked sequentially with Previous/Next markers.

Code shared by multiple pages (the Bloch-sphere types and views) lives in the playground's
`Sources/` folder — see [PLAYGROUNDSUPPORT.md](PLAYGROUNDSUPPORT.md) for how that works and
what is available.

### 00TOC

Clickable table of contents (markdown only): links to every page with a one-line
description, plus pointers to the guides in `Docs/`.

### 01Qubits

First look at qubit states through the Dirac API, shown in the results sidebar (no
console output): building `Ket`s from amplitudes, the dagger `†`, inner and outer
products, probabilities, and tensoring a ket with itself. Content provisional.

User guide in `Docs/01QUBITSHELP.md`.

### 02Bloch2d

Visualizes single-qubit states on the **Bloch sphere** using a SwiftUI `Canvas` live view.

- **Bloch vector math** — maps a state |ψ⟩ = α|0⟩ + β|1⟩ to sphere coordinates
  (x = 2·Re(ᾱβ), y = 2·Im(ᾱβ), z = |α|² − |β|²) plus the spherical angles θ and φ,
  reusing the `Complex` arithmetic from `SwiftQiskitCore`.
- **Rendering** — a 2D orthographic projection of the sphere with axes, drawn by the
  shared `BlochSphereView`, each sphere accompanied by a numeric readout.
- **Gallery** — six canonical states built with real circuits and shown side by side:
  |0⟩ (north pole), |1⟩ via Pauli-X (south pole), |+⟩ via Hadamard (+x axis),
  |−⟩ via Hadamard + Pauli-Z (−x axis), |+i⟩ via Hadamard + S (+y axis), and
  |−i⟩ via Hadamard + S† (−y axis). The same vectors are also printed to the console.

User guide in `Docs/02BLOCH2DHELP.md`, including the general recipe for putting a SwiftUI
live view on a playground page.

### 03Bloch2dProjection

A *general* single-qubit state, tilted off the equator of the Bloch sphere (45° from x,
60° from y and z), explored in depth.

- **Ket definition** — derives |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩ from direction
  cosines and builds the state directly from its amplitudes with `StateVector`.
- **Console readout** — amplitudes, magnitudes, probabilities, and a round-trip check
  recovering the Bloch vector from the amplitudes.
- **Live view** — the state on a large Bloch sphere plus two **plane projections**
  (x–y seen from +z, z–y seen from +x) drawn by the shared `BlochProjectionView`.

### 04Bloch3d

An **interactive 3D Bloch sphere**: a rotatable wireframe rendered with a pure SwiftUI
`Canvas` (no SceneKit/RealityKit), plus live sliders for the spherical angles.

- **3D rendering** — latitude/longitude circles are perspective-projected through an
  orbit camera; drag the canvas to rotate. The far hemisphere is drawn dimmer as a
  depth cue, and dashed drop lines connect the state vector to the equator plane.
- **θ/φ sliders** — rebuild |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩ on every change.
  The two sliders are independent because the parametrization keeps
  |α|² + |β|² = cos²(θ/2) + sin²(θ/2) = 1 identically — every slider position is a
  valid normalized state, shown live in the numeric readout.
- **Xcode 27 beta note** — running SwiftUI playground pages on the Xcode 27 beta
  currently needs two workarounds, described in
  [PLAYGROUNDSUPPORT.md](PLAYGROUNDSUPPORT.md#xcode-27-beta-workarounds): a shim
  `libcups.dylib` in DerivedData, and keeping `@State`-based views in the playground's
  `Sources/` folder (which is why the slider view `BlochExplorerView` lives there).

### 05Gates

A gentle, gate-by-gate tour of the built-in gate set in the results sidebar (no live
view, no prints): `x`, `h`, `z` (with the interference reveal that makes its phase flip
visible), `y`, `s`/`sdg`, `t`/`tdg`, the general phase gate `p(theta:)`, and the rotations
`rx`/`ry`/`rz`, each shown individually on a 1-qubit `QuantumCircuit`, plus a one-line
`h`+`cx` Bell-state teaser pointing to `07Entanglement`. User guide:
[Docs/05GATESHELP.md](Docs/05GATESHELP.md).

### 06Superposition

Building custom gates from raw `Matrix`/`Complex` values (Identity and a hand-rolled Pauli-X)
and applying them via `circuit.apply(_:)`. Content provisional.

### 07Entanglement

Annotated walkthrough of the Bell state |Φ⁺⟩: builds the circuit (`h` + `cx`), inspects the
resulting state vector and its amplitudes/probabilities, and runs a 1000-shot measurement.
A GHZ section extends the recipe to 3 qubits — `cx(0, 2)` spans non-adjacent qubits — and
the page closes with single-qubit gate demos and a tour of the `Complex`/`Matrix` types.

### 08BraKet

Dirac-notation walkthrough of `Quantum/Dirac.swift`:

- **Bras and kets** — basis kets via `Ket("01")` and the named states
  `.zero/.one/.plus/.minus/.plusI/.minusI`; the postfix dagger `†` turns a `Ket`
  into a `Bra` (and gives `Matrix.adjoint`).
- **Products** — inner products `Bra * Ket` (orthonormality checks) and outer
  products `Ket * Bra` (projectors, completeness).
- **Expectation values** — recovers the page-04 initial qubit's Bloch coordinates
  as the Pauli expectation values ⟨ψ|X|ψ⟩, ⟨ψ|Y|ψ⟩, ⟨ψ|Z|ψ⟩, shown on a static
  `Bloch3DView`.

User guide in `Docs/08DIRACHELP.md`.

### 09Tensor

Tensor-product walkthrough (console only), mirroring
`Tests/SwiftQiskitCoreTests/TensorProductTests.swift` section by section:

- `tensor(_:)` / `⊗` on `Matrix` and `StateVector`, and the mixed-product
  identity (A ⊗ B)(C ⊗ D) = (AC) ⊗ (BD).
- **Gate embedding** — building H ⊗ I by hand and checking it matches what
  `circuit.h(0)` applies across a 2-qubit register.
- **Entanglement** — why the Bell state cannot be factored as a tensor product
  of single-qubit states.

Design notes in `Docs/09TENSORPLAN.md`; user guide in `Docs/09TENSORHELP.md`.

### 10DeutschExample

Deutsch's algorithm (console only) — deciding whether a black-box function
f: {0,1} → {0,1} is constant or balanced with a *single* oracle query:

- **The four oracles** — every 1-bit function's oracle U_f built from gates the
  library already has: identity, `x(1)`, `cx(0,1)`, and `cx(0,1)` + `x(1)`.
- **Phase kickback** — a stage-by-stage state-vector walkthrough showing how the
  |−⟩ ancilla turns the oracle into a phase (−1)^f(x) on the input qubit.
- **Deterministic verdict** — the final Hadamard maps the phase to qubit 0, so one
  measurement reads off constant (0) vs balanced (1) with certainty, confirmed for
  all four oracles and backed by shot statistics.

Design notes in `Docs/10DEUTSCHPLAN.md`; user guide in `Docs/10DEUTSCHHELP.md`.

### 11GroverExample

Grover's search (console only) — finding a marked basis state with quadratically
fewer oracle queries:

- **CZ from existing gates** — the controlled-Z built as `h(1); cx(0,1); h(1)`, then
  conjugated by X gates to make a phase oracle for *any* marked state |w⟩.
- **Inversion about the mean** — an amplitude-by-amplitude walkthrough of one Grover
  iteration, with exact 1-iteration success on 2 qubits and what happens when you
  over-rotate by iterating further.
- **The diffusion operator in Dirac notation** — 2|s⟩⟨s| − I assembled directly from
  the outer product in `Quantum/Dirac.swift` and checked against the gate construction.
- **3-qubit finale** — Grover on 8 states using a hand-built CCZ matrix applied via
  `apply(_:)`, with the theoretical success probability after each iteration.

Design notes in `Docs/11GROVERPLAN.md`; user guide in `Docs/11GROVERHELP.md`.

### 12ShorExample

Compiled Shor's algorithm (console only) — factoring 15 by quantum order finding,
with a 3-qubit counting register and a 4-qubit work register:

- **Factoring reduces to order finding** — the classical gcd reduction, plus the
  "lucky guess" cases where no quantum computer is needed at all.
- **Modular multiplication as permutation matrices** — U_a |w⟩ = |a·w mod 15⟩ and its
  controlled powers hand-built (one `.one` per column) and applied via `apply(_:)`,
  with the orbit |1⟩ → |7⟩ → |4⟩ → |13⟩ → |1⟩ exposing the order geometrically.
- **A hand-built QFT†** — the 8×8 inverse DFT constructed entrywise on the register's
  integer index (no bit-reversal bookkeeping), checked against Hadamard and unitarity.
- **Phase estimation stage by stage** — superposed counts, the entangled orbit, then
  exact peaks at y = 8·s/r; shot statistics sampled from one `run()` (with a note on
  why `measure(shots:)` is too slow at dimension 128).
- **Classical post-processing** — measured phase → lowest terms → verified order →
  gcd factors, then a sweep of every coprime base including the instructive a = 14
  failure (a^(r/2) ≡ −1).

Design notes in `Docs/12SHORPLAN.md`; user guide in `Docs/12SHORHELP.md`.

The Bloch types and views (`BlochVector`, `BlochSphereView`, `BlochProjectionView`,
`Bloch3DView`, `BlochExplorerView`) are shared between these pages via the playground's
`Sources/` folder (not part of Core) — see [PLAYGROUNDSUPPORT.md](PLAYGROUNDSUPPORT.md).

---

##  Contributing

Contributions, ideas, and discussions are welcome.
This project is built **step by step** and open for exploration.

---
##  Status & Roadmap

Project status, what works in v0.1, and the roadmap live in
[STATUSandTODO.md](STATUSandTODO.md), together with this fork's working TODO list.

---

##  License

**MIT License** © 2025 **Ali Nasser**

---

##  References

1. [Ali Nasser](https://github.com/a360n/SwiftQiskit)
2. [Medium](https://medium.com/@brianenochson/our-quantum-future-part-1-quantum-computing-introduction-f03aa4fc5f7f)
3. [Quantum Mechanics](https://www.amazon.com/Quantum-Mechanics-Theoretical-Leonard-Susskind-ebook/dp/B00FD36G1Q?ref_=ast_author_dp_rw&th=1&psc=1&dib=eyJ2IjoiMSJ9.RkHbIvheK8CPtFzsBgBe7r23a7uhLIlprKHFiYC4BOCvoD6WBdvaQA79CYfZj1_xwUNgGM2xOFd-NGea4XGiB8p7tZll3hdPz1B1IWaIf9jLZuA7h2hoqtpM43Ebaii5rpmm3tHvNMEoAEbVniy-PWV35vm2I2ePmaG4bFhykzpwVySzN3XKJPylPmR4lL1GdKme919H-EXrNmLDhJZ7p8eEeOHQzQIdUK8zwBuPWQY.BXHnclSf8mfD4zk9Rtha8_j22VdyFHEKXfjT5yVZ2Ew&dib_tag=AUTHOR)



