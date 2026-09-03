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
| Hadamard (H) | `h(qubit)` | `HadamardGate` | Bell example; all five test suites; playground pages 01, 02, 05–16; pages 19–22 (`HadamardGate.matrix` applied directly via `StateVector.apply(_:)` — Bell-pair prep, basis rotations, the walk's coin flip — rather than the circuit method, since 19–22 don't use `QuantumCircuit` at all) |
| Pauli-X (X) | `x(qubit)` | `PauliXGate` | `TensorProductTests`, `AdditionalGatesTests`; pages 02, 05, 09–14, 17, 18; page 19 (`PauliXGate.matrix` as a Kraus operator) |
| Pauli-Y (Y) | `y(qubit)` | `PauliYGate` | `AdditionalGatesTests`; pages 05 (`y(0)`), 08 (Y† == Y, ⟨ψ\|Y\|ψ⟩); page 18 (`PauliYGate.matrix` as a raw Hamiltonian term, not via `y(qubit)`); pages 19–20 (`PauliYGate.matrix` as a Kraus operator / an exact-expectation check) |
| Pauli-Z (Z) | `z(qubit)` | `PauliZGate` | `DiracNotationTests`, `AdditionalGatesTests`; pages 01, 02, 05, 08, 13, 14; page 18 (`PauliZGate.matrix` as a raw Hamiltonian term); pages 19–21 (`PauliZGate.matrix` as a Kraus operator, an Ising-chain term, and the ZZ-rotation identity's core piece) |
| S / S† | `s(qubit)` / `sdg(qubit)` | `SGate` / `SDaggerGate` | `AdditionalGatesTests`; pages 02 (the \|±i⟩ states), 05; page 20 (`SDaggerGate.matrix` applied raw for the Y-basis measurement rotation, sign-checked against a known Y-eigenstate) |
| T / T† | `t(qubit)` / `tdg(qubit)` | `TGate` / `TDaggerGate` | `AdditionalGatesTests`; page 05 (`t` applied twice, T² == S — `tdg` isn't used on any page) |
| Phase P(θ) | `p(theta, qubit)` | `PhaseGate` | `AdditionalGatesTests`; pages 01, 05; page 16 (the building block of the hand-built controlled-phase CP(θ), five gates deep) |
| RX/RY/RZ (θ) | `rx/ry/rz(theta, qubit)` | `RXGate` / `RYGate` / `RZGate` | `AdditionalGatesTests`; page 05; page 13 (`ry`/`rz` prepare the teleported payload); page 14 (`rx(θ)` as a partial bit-flip error); page 15 (`ry(-θ)` rotates into a tilted measurement basis); page 18 (`ry(θ)` is the VQE ansatz's only parameter); page 20 (`RYGate`/`RZGate.matrix(θ)` build a generic tilted state, raw); page 21 (`RXGate.matrix(θ)` self-checks `expm` and drives the Ising field term; `RZGate.matrix(θ)` is the core of the exact ZZ-rotation identity) |
| CNOT (CX) | `cx(control, target)` — any distinct pair | `CNOTGate` (also `matrix(qubits:control:target:)`) | Bell example; `BellStateTests`, `CNOTTests`; pages 05, 07–11, 13–18; pages 19–21 (`CNOTGate.matrix(qubits:control:target:)` applied directly via `StateVector.apply(_:)` for Bell-pair prep and the ZZ-rotation identity) |

**Hand-built gates** — constructed in tests/playgrounds from raw `Matrix` values or gate
compositions and applied with `circuit.apply(_:)` (or, on pages 19–22, which don't build a
`QuantumCircuit` at all, directly via `StateVector.apply(_:)`); not (yet) part of Core:

| Gate | Built from | Where |
|------|------------|-------|
| Pauli-Y (Y) | raw 2×2 `Matrix` | `DiracNotationTests` (adjoint of a non-symmetric matrix — the test predates `PauliYGate`) |
| CZ | `h(1); cx(0,1); h(1)` | page 11 (phase oracles and diffusion operator); page 13 (`h(2); cx(0,2); h(2)` — the deferred Z^a correction) |
| Bell-basis projector | `(Ket("ab") * Bra("ab")) ⊗ Matrix.identity(size: 2)` | page 13 (recovering one measurement branch without `measure()`) |
| 3-qubit code correction | 32×32 permutation decoding two syndrome bits and flipping the accused data qubit | page 14 (syndrome-driven error correction via `apply(_:)`) |
| Tilted observable A(θ) | `cos θ·Z + sin θ·X`, built entrywise | page 15 (CHSH correlators; measured via `ry(-θ)`) |
| CCZ | `Matrix.identity(size: 8)` with the \|111⟩ entry set to −1 | page 11 (3-qubit Grover finale) |
| Modular multiplication U_a (mod 15) | 16×16 / 128×128 basis-state permutations — one `.one` per column; the controlled versions key on a counting bit | page 12 (Shor order finding) |
| QFT† (3-qubit inverse Fourier) | 8×8 inverse-DFT matrix built entrywise from `cos`/`sin`, embedded as `qftDagger ⊗ I₁₆` | page 12 (phase-estimation readout) |
| Controlled phase CP(θ) | `p(θ/2, c); cx(c,t); p(-θ/2, t); cx(c,t); p(θ/2, t)` | page 16 (the QFT ladder and standalone phase estimation; reduces to CZ at θ=π) |
| H₂ Hamiltonian (Jordan–Wigner, 2 qubits) | six Pauli terms (I⊗I, Z⊗I, I⊗Z, Z⊗Z, Y⊗Y, X⊗X) combined entrywise | page 18 (VQE's energy operator) |
| Kraus channels (bit-flip, phase-flip, depolarizing, amplitude damping) | pairs/quadruples of scaled `Matrix` values satisfying ΣKᵢ†Kᵢ = I | page 19 (noise channels, applied as ρ' = ΣKᵢρKᵢ†) |
| `expm` (matrix exponential) | scaling-and-squaring Taylor series on `Matrix *` | page 21 (ground truth for Trotterized Hamiltonian simulation, self-checked against `RXGate`) |
| ZZ-rotation exp(−iθ·Z⊗Z/2) | `cx(0,1); rz(θ,1); cx(0,1)` | page 21 (the exact building block of every Trotter step) |
| Ising chain H = −J·Z⊗Z − h·(X⊗I + I⊗X) | two Pauli terms combined entrywise | page 21 (Hamiltonian simulation target) |
| Coined-walk shift S | 32×32 permutation on (coin ⊗ 16-site position) — one `.one` per column | page 22 (the conditional shift \|0,x⟩→\|0,x+1⟩, \|1,x⟩→\|1,x−1⟩) |

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
│   │   ├── Math/
│   │   │   ├── Complex.swift
│   │   │   └── Matrix.swift
│   │   ├── Quantum/
│   │   │   ├── StateVector.swift
│   │   │   ├── Dirac.swift
│   │   │   └── SimulationResult.swift
│   │   ├── Gates/
│   │   │   ├── Hadamard.swift
│   │   │   ├── PauliX.swift
│   │   │   ├── PauliY.swift
│   │   │   ├── PauliZ.swift
│   │   │   ├── Phase.swift
│   │   │   ├── Rotation.swift
│   │   │   └── CNOT.swift
│   │   ├── Circuit/
│   │   │   └── QuantumCircuit.swift
│   │   ├── Utils/
│   │   │   └── String+Padding.swift
│   │   └── SwiftQiskitCore.swift
├── Examples/
│   └── main.swift
├── SwiftQiskitGUI/
│   └── Sources/
│       ├── main.swift
│       └── ContentView.swift
├── Tests/
│   └── SwiftQiskitCoreTests/
│       ├── BellStateTests.swift
│       ├── TensorProductTests.swift
│       ├── DiracNotationTests.swift
│       ├── CNOTTests.swift
│       └── AdditionalGatesTests.swift
├── PlaygroundDocs/
│   ├── 01QUBITSHELP.md
│   ├── 02BLOCH2DHELP.md
│   ├── 03BLOCH2DPROJECTIONHELP.md
│   ├── 04BLOCH3DHELP.md
│   ├── 05GATESHELP.md
│   ├── 06SUPERPOSITIONHELP.md
│   ├── 07ENTANGLEMENTHELP.md
│   ├── 08DIRACHELP.md
│   ├── 09TENSORPLAN.md
│   ├── 09TENSORHELP.md
│   ├── 10DEUTSCHPLAN.md
│   ├── 10DEUTSCHHELP.md
│   ├── 11GROVERPLAN.md
│   ├── 11GROVERHELP.md
│   ├── 12SHORPLAN.md
│   ├── 12SHORHELP.md
│   ├── 13TELEPORTATIONPLAN.md
│   ├── 13TELEPORTATIONHELP.md
│   ├── 14ERRORCORRECTIONPLAN.md
│   ├── 14ERRORCORRECTIONHELP.md
│   ├── 15CHSHPLAN.md
│   ├── 15CHSHHELP.md
│   ├── 16QFTPLAN.md
│   ├── 16QFTHELP.md
│   ├── 17DEUTSCHJOZSAPLAN.md
│   ├── 17DEUTSCHJOZSAHELP.md
│   ├── 18VQEPLAN.md
│   ├── 18VQEHELP.md
│   ├── 19NOISEPLAN.md
│   ├── 19NOISEHELP.md
│   ├── 20TOMOGRAPHYPLAN.md
│   ├── 20TOMOGRAPHYHELP.md
│   ├── 21TROTTERPLAN.md
│   ├── 21TROTTERHELP.md
│   ├── 22WALKPLAN.md
│   ├── 22WALKHELP.md
│   └── 90LIVEVIEWHELP.md   (not page-numbered — sorts last on purpose; the shared-code/live-view guide)
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
│       ├── 08Dirac
│       ├── 09Tensor
│       ├── 10DeutschExample
│       ├── 11GroverExample
│       ├── 12ShorExample
│       ├── 13Teleportation
│       ├── 14ErrorCorrection
│       ├── 15CHSH
│       ├── 16QFT
│       ├── 17DeutschJozsa
│       ├── 18VQE
│       ├── 19Noise
│       ├── 20Tomography
│       ├── 21Trotter
│       └── 22Walk
├── Package.swift
└── References (tbd)
```

---

##  Getting Started with this fork

### Requirements

The package itself (`Package.swift`) declares `swift-tools-version: 5.9` and targets
macOS 13+ / iOS 16+.

This fork's playground pages, however, are developed and tested against **Xcode 27.0 beta**
and **macOS 27 beta** — some SwiftUI live-view pages need the beta-specific workarounds in
[PLAYGROUNDSUPPORT.md](PLAYGROUNDSUPPORT.md#xcode-27-beta-workarounds) on Xcode 27 betas
(confirmed still needed on beta 5, 27A5237l).

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
circuit.cx(0, 1)

let finalState = circuit.run()
print(finalState)

let result = circuit.measure(shots: 1000)
for (state, count) in result.sortedCounts {
    let probability = Double(count) / Double(1000)
    print("\(state): \(count) (\(String(format: "%.2f", probability)))")
}
```
> Note: The core module is currently imported as `SwiftQiskitCore`. This is the same code as
> `Examples/main.swift`, run via `swift run SwiftQiskitExamples`.

### Expected Measurement Output

```text
00: 498 (0.50)
11: 502 (0.50)
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
`Sources/` folder — see [PlaygroundDocs/90LIVEVIEWHELP.md](PlaygroundDocs/90LIVEVIEWHELP.md) for a user-facing
guide to that shared code and to putting a live view on a page, and
[PLAYGROUNDSUPPORT.md](PLAYGROUNDSUPPORT.md) for the terse implementation reference.

### 00TOC

Clickable table of contents (markdown only): links to every page with a one-line
description, plus pointers to the guides in `PlaygroundDocs/`.

### 01Qubits

First look at qubit states through the Dirac API, shown in the results sidebar (no
console output): building `Ket`s from amplitudes, the dagger `†`, inner and outer
products, probabilities, and tensoring a ket with itself. Content provisional.

User guide in `PlaygroundDocs/01QUBITSHELP.md`.

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

User guide in `PlaygroundDocs/02BLOCH2DHELP.md`; the general recipe for putting a SwiftUI live
view on a playground page is in [PlaygroundDocs/90LIVEVIEWHELP.md](PlaygroundDocs/90LIVEVIEWHELP.md).

### 03Bloch2dProjection

A *general* single-qubit state, tilted off the equator of the Bloch sphere (45° from x,
60° from y and z), explored in depth.

- **Ket definition** — derives |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩ from direction
  cosines and builds the state directly from its amplitudes with `StateVector`.
- **Console readout** — amplitudes, magnitudes, probabilities, and a round-trip check
  recovering the Bloch vector from the amplitudes.
- **Live view** — the state on a large Bloch sphere plus two **plane projections**
  (x–y seen from +z, z–y seen from +x) drawn by the shared `BlochProjectionView`.

User guide in `PlaygroundDocs/03BLOCH2DPROJECTIONHELP.md`.

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
  `Sources/` folder (which is why the slider view `BlochExplorerView` lives there). Both
  are confirmed still present on beta 5 (27A5237l).

User guide: [PlaygroundDocs/04BLOCH3DHELP.md](PlaygroundDocs/04BLOCH3DHELP.md).

### 05Gates

A gentle, gate-by-gate tour of the built-in gate set in the results sidebar (no live
view, no prints): `x`, `h`, `z` (with the interference reveal that makes its phase flip
visible), `y`, `s`/`sdg`, `t` (applied twice to show `T² == S`), the general phase gate
`p(theta:)`, and the rotations `rx`/`ry`/`rz`, each shown individually on a 1-qubit
`QuantumCircuit`, plus a one-line `h`+`cx` Bell-state teaser pointing to `07Entanglement`.
User guide: [PlaygroundDocs/05GATESHELP.md](PlaygroundDocs/05GATESHELP.md).

### 06Superposition

A 4-qubit console walkthrough: every qubit put into superposition via `h`, inspecting the
resulting 16-state amplitudes/probabilities and a 1600-shot measurement, plus a
partial-superposition (2-qubit) contrast. User guide:
[PlaygroundDocs/06SUPERPOSITIONHELP.md](PlaygroundDocs/06SUPERPOSITIONHELP.md).

### 07Entanglement

Annotated walkthrough of the Bell state |Φ⁺⟩: builds the circuit (`h` + `cx`), inspects the
resulting state vector and its amplitudes/probabilities, and runs a 1000-shot measurement.
A GHZ section extends the recipe to 3 qubits — `cx(0, 2)` spans non-adjacent qubits — and
the page closes by rebuilding the Bell state via `apply(CNOTGate.matrix)` to show the
matrix form agrees with the fluent `cx` API.

User guide in `PlaygroundDocs/07ENTANGLEMENTHELP.md`.

### 08Dirac

Dirac-notation walkthrough of `Quantum/Dirac.swift`:

- **Bras and kets** — basis kets via `Ket("01")` and the named states
  `.zero/.one/.plus/.minus/.plusI/.minusI`; the postfix dagger `†` turns a `Ket`
  into a `Bra` (and gives `Matrix.adjoint`).
- **Products** — inner products `Bra * Ket` (orthonormality checks) and outer
  products `Ket * Bra` (projectors, completeness).
- **Expectation values** — recovers the page-04 initial qubit's Bloch coordinates
  as the Pauli expectation values ⟨ψ|X|ψ⟩, ⟨ψ|Y|ψ⟩, ⟨ψ|Z|ψ⟩, shown on a static
  `Bloch3DView`.

User guide in `PlaygroundDocs/08DIRACHELP.md`.

### 09Tensor

Tensor-product walkthrough (console only), mirroring
`Tests/SwiftQiskitCoreTests/TensorProductTests.swift` section by section:

- `tensor(_:)` / `⊗` on `Matrix` and `StateVector`, and the mixed-product
  identity (A ⊗ B)(C ⊗ D) = (AC) ⊗ (BD).
- **Gate embedding** — building H ⊗ I by hand and checking it matches what
  `circuit.h(0)` applies across a 2-qubit register.
- **Entanglement** — why the Bell state cannot be factored as a tensor product
  of single-qubit states.

Design notes in `PlaygroundDocs/09TENSORPLAN.md`; user guide in `PlaygroundDocs/09TENSORHELP.md`.

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

Design notes in `PlaygroundDocs/10DEUTSCHPLAN.md`; user guide in `PlaygroundDocs/10DEUTSCHHELP.md`.

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

Design notes in `PlaygroundDocs/11GROVERPLAN.md`; user guide in `PlaygroundDocs/11GROVERHELP.md`.

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

Design notes in `PlaygroundDocs/12SHORPLAN.md`; user guide in `PlaygroundDocs/12SHORHELP.md`.

### 13Teleportation

Quantum teleportation and its dual, superdense coding — entanglement used as a
*communication resource*, with a Bloch-sphere live view:

- **Teleportation on 3 qubits** — Alice's payload, a shared Bell pair, her Bell-basis
  rotation (`cx(0,1); h(0)`), and Bob's X^b Z^a correction.
- **Measurement branches without measuring** — the four outcomes recovered with Dirac
  projectors (\|ab⟩⟨ab\|) ⊗ I₂, showing P(ab) = ¼ regardless of \|ψ⟩ (no signalling) and
  fidelity 1 once each branch gets its own correction.
- **Deferred measurement** — classical feedback replaced by `cx(1,2)` and CZ(0,2), after
  which the register factors exactly as \|+⟩ ⊗ \|+⟩ ⊗ \|ψ⟩ (~8e-17).
- **No cloning, concretely** — Bob's marginal reproduces \|ψ\|² while Alice's qubit is left
  in \|+⟩: the state moved rather than copied.
- **Superdense coding** — two classical bits carried by one qubit, decoded with certainty,
  with the Bell basis's Gram matrix printed as the identity to show why.

Design notes in `PlaygroundDocs/13TELEPORTATIONPLAN.md`; user guide in `PlaygroundDocs/13TELEPORTATIONHELP.md`.

### 14ErrorCorrection

The 3-qubit bit-flip/phase-flip repetition code — how a quantum computer protects one
fragile qubit without ever looking at it directly, with a Bloch-sphere live view:

- **Encode and extract a syndrome** — `cx`-based encoding and two ancilla parities that
  name the flipped qubit (or "none") without touching α or β.
- **A hand-built correction** — a 32×32 permutation (Core has no Toffoli) that flips
  whichever qubit the syndrome accuses, applied via `apply(_:)`.
- **Continuous errors, digitized exactly** — an `rx(θ)` sweep shows the coherent correction
  restoring fidelity 1.0000 at *every* θ, while the syndrome ancillas alone carry the
  cos²(θ/2)/sin²(θ/2) branch weights.
- **Where distance 3 breaks** — two simultaneous errors alias to the wrong syndrome,
  producing a silent, fully "corrected" logical X; the exact logical error rate
  p_L = 3p² − 2p³ is confirmed by enumeration.
- **Phase flips for free** — Hadamard-conjugating the same code (H Z H = X) turns a Z error
  into the X error the rest of the page already fixes.

Design notes in `PlaygroundDocs/14ERRORCORRECTIONPLAN.md`; user guide in `PlaygroundDocs/14ERRORCORRECTIONHELP.md`.

### 15CHSH

The CHSH inequality — whether a Bell pair's correlations could ever come from a shared
classical instruction list — with a live chart of the violation:

- **The classical bound, exhaustively** — all 16 deterministic ±1 strategies checked by
  brute force (max \|S\| = 2), plus a shared-direction hidden-variable model that saturates
  the bound and doubles as the chart's classical comparison curve.
- **A pinned measurement convention** — the tilted observable A(θ) = cos θ·Z + sin θ·X,
  built entrywise, measured via `ry(-θ)`, with the sign checked against the exact
  expectation value (and against page 04/08's ⟨Z⟩/⟨X⟩ for the same qubit) before it's trusted.
- **Correlators two ways** — exact via `psi† * (A(a) ⊗ A(b)) * psi` and sampled via
  `measure(shots:)`, agreeing with cos(a−b).
- **The violation and its limits** — a Bell pair's S = 2√2 against a product-state control
  (S = √2) and a fine angle sweep confirming the Tsirelson ceiling of 2√2, never higher.
- **A live chart** — `CHSHChartView` (new shared `Sources/` type) plots the exact cos θ
  curve, sampled points, and the classical line together.

Design notes in `PlaygroundDocs/15CHSHPLAN.md`; user guide in `PlaygroundDocs/15CHSHHELP.md`.

### 16QFT

The quantum Fourier transform as a gate circuit (console only) — closing the gap page 12 left
open when it built the QFT as a single entrywise matrix:

- **The missing gate** — controlled phase CP(θ) derived from `p` + `cx` alone
  (`p(θ/2,c); cx(c,t); p(-θ/2,t); cx(c,t); p(θ/2,t)`), checked against CZ at θ = π.
- **The QFT ladder** — Hadamards and CP's per qubit, plus a swap network, checked against
  page 12's entrywise DFT to ~1e-15 on every basis state.
- **Why the swaps** — dropping them reproduces the exact bit-reversal of the correct output.
- **The inverse QFT and unitarity** — QFT then QFT† returns every basis state to itself.
- **Standalone phase estimation** — exact recovery of dyadic phases, a spread for phases that
  aren't, and a precision comparison at 3 vs. 6 counting qubits.

Design notes in `PlaygroundDocs/16QFTPLAN.md`; user guide in `PlaygroundDocs/16QFTHELP.md`.

### 17DeutschJozsa

Deutsch–Jozsa and Bernstein–Vazirani (console only) — page 10's algorithm generalized from 1
bit to n:

- **The n-qubit circuit** — page 10's shape widened to n input qubits + 1 ancilla.
- **Oracles from `cx`** — constant and balanced functions built the same way page 10 did.
- **The verdict** — P(all-zero input) is exactly 1 or 0, from a single query, for any n.
- **A shot-sampling gotcha** — the ancilla's bit is a free coin flip; only the input bits are
  deterministic in `measure(shots:)` output.
- **Bernstein–Vazirani** — the identical circuit recovers an entire hidden n-bit string in
  one query.
- **The query-count gap** — quantum stays at 1 while classical Deutsch–Jozsa's worst case
  grows exponentially and classical Bernstein–Vazirani grows linearly.

Design notes in `PlaygroundDocs/17DEUTSCHJOZSAPLAN.md`; user guide in `PlaygroundDocs/17DEUTSCHJOZSAHELP.md`.

### 18VQE

The variational quantum eigensolver — the one page where the circuit isn't fixed in advance,
with a live chart of the optimization:

- **The Hamiltonian** — the qubit Hamiltonian for H₂ (Jordan–Wigner, minimal basis), assembled
  entrywise from six Pauli terms.
- **A one-parameter ansatz** — `x(0); ry(θ,1); cx(1,0)`, provably confined to the
  {\|01⟩,\|10⟩} subspace.
- **The energy** — `psi† * H * psi`, page 08's Dirac expectation-value idiom.
- **The exact answer** — a closed-form 2×2 eigenvalue, used only to grade the optimizer.
- **Parameter-shift gradients** — exact, not approximate, for a single-rotation ansatz;
  pinned against a finite difference.
- **Gradient descent** — converges to the exact ground energy (error 0.00e+00) in ~10 steps.
- **A live chart** — the E(θ) landscape and the optimizer's own visited points, on the shared
  `CHSHChartView`.

Design notes in `PlaygroundDocs/18VQEPLAN.md`; user guide in `PlaygroundDocs/18VQEHELP.md`.

### 19Noise

Open systems: the density matrix, and how noise enters a state-vector simulator with **no
`SwiftQiskitCore` changes**, plus a live Bloch gallery:

- **ρ and coherence** — the density matrix ρ = |ψ⟩⟨ψ| from the existing `Ket * Bra` outer
  product; a classical mixture ½|0⟩⟨0| + ½|1⟩⟨1| contrasted against the superposition |+⟩⟨+| —
  identical Z-statistics, different off-diagonals.
- **Kraus channels** — bit-flip, phase-flip, depolarizing, and amplitude damping, each checked
  for trace preservation (ΣKᵢ†Kᵢ = I) before being trusted.
- **Decoherence, exactly** — coherence decaying as (1−2p)ⁿ under repeated dephasing, and
  amplitude damping pulling the Bloch vector *inside* the sphere — the picture no pure state
  can draw.
- **A Monte-Carlo unraveling** — the exact channel reproduced from ordinary pure-state code:
  flip a coin per shot, apply the error gate or not, then measure.
- **Entanglement via a reduced state** — tracing out one qubit of a Bell pair gives entropy
  exactly 1 bit, against 0 for a product state — the explanation page 13's marginals were owed.

Design notes in `PlaygroundDocs/19NOISEPLAN.md`; user guide in `PlaygroundDocs/19NOISEHELP.md`.

### 20Tomography

Reconstructing a state from `measure(shots:)` statistics alone — the honest version of "what a
real device gives you," depending on page 19's mixed states for its sharpest result:

- **Basis rotations, pinned by hand** — `h` for X, `sdg`+`h` for Y, checked against a known
  Y-eigenstate rather than assumed.
- **The estimator and its 1/√N error** — RMS error against the exact expectation value falls
  by roughly √10 each time the shot count grows tenfold.
- **Pure vs. mixed unphysical estimates** — a *pure* state's per-axis reconstruction lands
  outside the Bloch ball about half the time at *any* N (it sits exactly on the boundary);
  only a genuinely mixed state's frequency shrinks toward zero.
- **An entangled qubit's marginal, from shots** — a Bell pair's qubit-0 Bloch vector
  reconstructs to the origin, restating page 13's no-cloning result statistically.
- **Why full tomography doesn't scale** — a 3ⁿ-settings cost table, motivating page 18's
  per-term Pauli measurements.

Design notes in `PlaygroundDocs/20TOMOGRAPHYPLAN.md`; user guide in `PlaygroundDocs/20TOMOGRAPHYHELP.md`.

### 21Trotter

Hamiltonian simulation — evolving a state in time under a Hamiltonian too large for a single
gate, the original motivation for quantum computers, with a live chart:

- **`expm`, self-checked** — a page-level matrix exponential (scaling-and-squaring Taylor
  series) validated against Core's exact `RXGate` before being trusted as ground truth.
- **An exact gate identity** — exp(−iθ·Z⊗Z/2) = `cx(0,1); rz(θ,1); cx(0,1)`, derived from
  Core's `RZGate` and checked against `expm`, not assumed.
- **Trotter error scaling** — first-order error shrinking as O(1/n), second-order (Suzuki) as
  O(1/n²), at the observable level (⟨Z₀⟩(t)) as well as the operator level.
- **Why the error exists** — the non-zero commutator [Z⊗Z, X⊗I] identified as the cause; a
  commuting-only Hamiltonian is exact at n=1.

Design notes in `PlaygroundDocs/21TROTTERPLAN.md`; user guide in `PlaygroundDocs/21TROTTERHELP.md`.

### 22Walk

The discrete-time quantum walk — interference producing a *distribution*, rather than
answering an oracle question or amplifying a marked item, with a live chart:

- **The shift, as a permutation** — a hand-built conditional shift on a 16-site cycle, checked
  as unitary (S†S = I).
- **Ballistic vs. diffusive spreading** — the quantum walk's spread grows roughly linearly in
  t; a classical random walk's grows as exactly √t, at every step.
- **A cyclic-coordinate gotcha, caught and documented** — computing spread from raw site
  indices breaks near the cycle's wraparound boundary; the fix is a signed offset from the
  start.
- **Interference, not asymmetry** — an |0⟩ coin gives a lopsided distribution; Core's existing
  `|+i⟩` basis ket restores left-right symmetry exactly.

Design notes in `PlaygroundDocs/22WALKPLAN.md`; user guide in `PlaygroundDocs/22WALKHELP.md`.

The Bloch types and views (`BlochVector`, `BlochSphereView`, `BlochProjectionView`,
`Bloch3DView`, `BlochExplorerView`) and the shared 2D chart (`CHSHChartView`, used by pages 15,
18, 21, and 22) are shared between these pages via the playground's `Sources/` folder (not
part of Core) — see [PlaygroundDocs/90LIVEVIEWHELP.md](PlaygroundDocs/90LIVEVIEWHELP.md) for a user guide to each type
and [PLAYGROUNDSUPPORT.md](PLAYGROUNDSUPPORT.md) for the implementation reference. `BlochVector`
gained an additive `init(x:y:z:)` for page 19's mixed-state (sub-unit-length) vectors, used by
pages 19 and 20; every earlier call site is unaffected.

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



