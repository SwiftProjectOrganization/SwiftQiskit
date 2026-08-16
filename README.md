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
  - Pauli-Z (Z)
  - CNOT (Controlled-NOT)
- ✅ Single-qubit gate embedding  
- ✅ Quantum circuit abstraction  
- ✅ Measurement & state collapse  
- ✅ Bell State (Entanglement) example  

---

##  Quantum Gates

**Built-in gates** — each is a `public enum` in `Sources/SwiftQiskitCore/Gates/` exposing
`static let matrix: Matrix`, with a matching convenience method on `QuantumCircuit`:

| Gate | Circuit API | Type | Used in |
|------|-------------|------|---------|
| Hadamard (H) | `h(qubit)` | `HadamardGate` | Bell example; all four test suites; playground pages 01, 03, 05, 08–12 |
| Pauli-X (X) | `x(qubit)` | `PauliXGate` | `TensorProductTests`; pages 01, 05, 08–12 |
| Pauli-Z (Z) | `z(qubit)` | `PauliZGate` | `DiracNotationTests`; pages 01, 04, 05, 08 |
| CNOT (CX) | `cx(control, target)` — any distinct pair | `CNOTGate` (also `matrix(qubits:control:target:)`) | Bell example; `BellStateTests`, `CNOTTests`; pages 01, 03, 08–11 |

**Hand-built gates** — constructed in tests/playgrounds from raw `Matrix` values or gate
compositions and applied with `circuit.apply(_:)`; not (yet) part of Core. Pauli-Y and
phase/rotation gates are on the roadmap (see [STATUSandTODO.md](STATUSandTODO.md)):

| Gate | Built from | Where |
|------|------------|-------|
| Pauli-Y (Y) | raw 2×2 `Matrix` | page 08 (expectation value ⟨ψ\|Y\|ψ⟩); `DiracNotationTests` (adjoint of a non-symmetric matrix) |
| Identity / hand-rolled X | raw `Matrix`/`Complex` values | page 04 |
| CZ | `h(1); cx(0,1); h(1)` | page 11 (phase oracles and diffusion operator) |
| CCZ | `Matrix.identity(size: 8)` with the \|111⟩ entry set to −1 | page 11 (3-qubit Grover finale) |
| Modular multiplication U_a (mod 15) | 16×16 / 128×128 basis-state permutations — one `.one` per column; the controlled versions key on a counting bit | page 12 (Shor order finding) |
| QFT† (3-qubit inverse Fourier) | 8×8 inverse-DFT matrix built entrywise from `cos`/`sin`, embedded as `qftDagger ⊗ I₁₆` | page 12 (phase-estimation readout) |

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
│   ├── BLOCH2DHELP.md
│   ├── DIRACHELP.md
│   ├── TENSORPLAN.md
│   ├── TENSORHELP.md
│   ├── DEUTSCHPLAN.md
│   ├── DEUTSCHHELP.md
│   ├── GROVERPLAN.md
│   ├── GROVERHELP.md
│   ├── SHORPLAN.md
│   └── SHORHELP.md
├── Playgrounds.playground/
│   ├── Sources/            (code shared by all pages — see PLAYGROUNDSUPPORT.md)
│   └── Pages/
│       ├── 01BellExample
│       ├── 02Lecture_01
│       ├── ...
│       ├── 05BlochSphere2D
│       ├── 06BlochSphere2D+Projections
│       ├── 07BlochSphere3D
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

### 01BellExample

Annotated walkthrough of the Bell state |Φ⁺⟩: builds the circuit (`h` + `cx`), inspects the
resulting state vector and its amplitudes/probabilities, and runs a 1000-shot measurement.

### 02Lecture_01

Minimal Bell-state circuit: run, print amplitudes, and measure 1024 shots. TBD.

### 03Lecture_03

Introduces `StateVector` directly and its `probabilities` property. TBD.

### 04Lecture_04

Building custom gates from raw `Matrix`/`Complex` values (Identity and a hand-rolled Pauli-X)
and applying them via `circuit.apply(_:)`. TBD.

### 05BlochSphere2D

Visualizes single-qubit states on the **Bloch sphere** using a SwiftUI `Canvas` live view.

- **Bloch vector math** — maps a state |ψ⟩ = α|0⟩ + β|1⟩ to sphere coordinates
  (x = 2·Re(ᾱβ), y = 2·Im(ᾱβ), z = |α|² − |β|²) plus the spherical angles θ and φ,
  reusing the `Complex` arithmetic from `SwiftQiskitCore`.
- **Rendering** — a 2D orthographic projection of the sphere with axes, drawn by the
  shared `BlochSphereView`, each sphere accompanied by a numeric readout.
- **Gallery** — four canonical states built with real circuits and shown side by side:
  |0⟩ (north pole), |1⟩ via Pauli-X (south pole), |+⟩ via Hadamard (+x axis), and
  |−⟩ via Hadamard + Pauli-Z (−x axis). The same vectors are also printed to the console.

User guide in `Docs/BLOCH2DHELP.md`, including the general recipe for putting a SwiftUI
live view on a playground page.

### 06BlochSphere2D+Projections

A *general* single-qubit state, tilted off the equator of the Bloch sphere (45° from x,
60° from y and z), explored in depth.

- **Ket definition** — derives |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩ from direction
  cosines and builds the state directly from its amplitudes with `StateVector`.
- **Console readout** — amplitudes, magnitudes, probabilities, and a round-trip check
  recovering the Bloch vector from the amplitudes.
- **Live view** — the state on a large Bloch sphere plus two **plane projections**
  (x–y seen from +z, z–y seen from +x) drawn by the shared `BlochProjectionView`.

### 07BlochSphere3D

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

### 08BraKet

Dirac-notation walkthrough of `Quantum/Dirac.swift`:

- **Bras and kets** — basis kets via `Ket("01")` and the named states
  `.zero/.one/.plus/.minus/.plusI/.minusI`; the postfix dagger `†` turns a `Ket`
  into a `Bra` (and gives `Matrix.adjoint`).
- **Products** — inner products `Bra * Ket` (orthonormality checks) and outer
  products `Ket * Bra` (projectors, completeness).
- **Expectation values** — recovers the page-07 initial qubit's Bloch coordinates
  as the Pauli expectation values ⟨ψ|X|ψ⟩, ⟨ψ|Y|ψ⟩, ⟨ψ|Z|ψ⟩, shown on a static
  `Bloch3DView`.

User guide in `Docs/DIRACHELP.md`.

### 09Tensor

Tensor-product walkthrough (console only), mirroring
`Tests/SwiftQiskitCoreTests/TensorProductTests.swift` section by section:

- `tensor(_:)` / `⊗` on `Matrix` and `StateVector`, and the mixed-product
  identity (A ⊗ B)(C ⊗ D) = (AC) ⊗ (BD).
- **Gate embedding** — building H ⊗ I by hand and checking it matches what
  `circuit.h(0)` applies across a 2-qubit register.
- **Entanglement** — why the Bell state cannot be factored as a tensor product
  of single-qubit states.

Design notes in `Docs/TENSORPLAN.md`; user guide in `Docs/TENSORHELP.md`.

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

Design notes in `Docs/DEUTSCHPLAN.md`; user guide in `Docs/DEUTSCHHELP.md`.

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

Design notes in `Docs/GROVERPLAN.md`; user guide in `Docs/GROVERHELP.md`.

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

Design notes in `Docs/SHORPLAN.md`; user guide in `Docs/SHORHELP.md`.

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



