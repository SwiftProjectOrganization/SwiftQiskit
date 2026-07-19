# SwiftQiskit 

**SwiftQiskit** is a lightweight **quantum computing simulator** written entirely in **Swift**.  
It brings a **Qiskit-like experience** to the Apple ecosystem, with a strong focus on **clarity**, **correctness**, and **future GUI integration**.

>  This project is **experimental and educational**, but grounded in real quantum mechanics principles

> The main difference between this repository and it's parent is the usage of Xcode playgounds.
---

##  Features

- ✅ Complex number arithmetic  
- ✅ Matrix operations (including Kronecker products)  
- ✅ State vector simulation  
- ✅ Quantum gates:
  - Hadamard (H)
  - Pauli-X (X)
  - Pauli-Z (Z)
  - CNOT (Controlled-NOT)
- ✅ Single-qubit gate embedding  
- ✅ Quantum circuit abstraction  
- ✅ Measurement & state collapse  
- ✅ Bell State (Entanglement) example  

---

##  Project Structure

```text
SwiftQiskit/
├── Sources/
│   └── SwiftQiskitCore/
│       ├── Math/
│       │   ├── Complex.swift
│       │   └── Matrix.swift
│       ├── Quantum/
│       │   └── StateVector.swift
│       ├── Gates/
│       │   ├── Hadamard.swift
│       │   ├── PauliX.swift
│       │   ├── PauliZ.swift
│       │   └── CNOT.swift
│       └── Circuit/
│           └── QuantumCircuit.swift
├── Examples/
│   └── main.swift
├── Playgrounds.playground/
│   ├── Sources/            (code shared by all pages — see PLAYGROUNDSUPPORT.md)
│   └── Pages/
│       ├── 01BellExample
│       ├── 02Lecture_01
│       ├── ...
│       ├── 05BlochSphere
│       └── 06BlochSphere_02
└── References (tbd)
└── Package.swift
```

---

##  Getting Started

### Requirements

* Swift **5.9+**
* macOS **13+**
  *(iOS 16+ planned for future UI integration)*

This forked repository is developed using Swift 6.3+ and MacOS 27+.

---

### Clone the Repository

```bash
git clone https://github.com/a360n/SwiftQiskit.git
cd SwiftQiskit
```

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

Minimal Bell-state circuit: run, print amplitudes, and measure 1024 shots.

### 03Lecture_03

Introduces `StateVector` directly and its `probabilities` property.

### 04Lecture_04

Building custom gates from raw `Matrix`/`Complex` values (Identity and a hand-rolled Pauli-X)
and applying them via `circuit.apply(_:)`.

### 05BlochSphere

Visualizes single-qubit states on the **Bloch sphere** using a SwiftUI `Canvas` live view.

- **Bloch vector math** — maps a state |ψ⟩ = α|0⟩ + β|1⟩ to sphere coordinates
  (x = 2·Re(ᾱβ), y = 2·Im(ᾱβ), z = |α|² − |β|²) plus the spherical angles θ and φ,
  reusing the `Complex` arithmetic from `SwiftQiskitCore`.
- **Rendering** — a 2D orthographic projection of the sphere with axes, drawn by the
  shared `BlochSphereView`, each sphere accompanied by a numeric readout.
- **Gallery** — four canonical states built with real circuits and shown side by side:
  |0⟩ (north pole), |1⟩ via Pauli-X (south pole), |+⟩ via Hadamard (+x axis), and
  |−⟩ via Hadamard + Pauli-Z (−x axis). The same vectors are also printed to the console.

### 06BlochSphere_02

A *general* single-qubit state, tilted off the equator of the Bloch sphere (45° from x,
60° from y and z), explored in depth.

- **Ket definition** — derives |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩ from direction
  cosines and builds the state directly from its amplitudes with `StateVector`.
- **Console readout** — amplitudes, magnitudes, probabilities, and a round-trip check
  recovering the Bloch vector from the amplitudes.
- **Live view** — the state on a large Bloch sphere plus two **plane projections**
  (x–y seen from +z, z–y seen from +x) drawn by the shared `BlochProjectionView`.

The Bloch types and views (`BlochVector`, `BlochSphereView`, `BlochProjectionView`) are
shared between these pages via the playground's `Sources/` folder (not part of Core) —
see [PLAYGROUNDSUPPORT.md](PLAYGROUNDSUPPORT.md).

---

##  Design Philosophy

* No hidden magic — everything is **explicit and readable**
* Mathematical correctness over shortcuts
* Modular architecture (**Core / Examples / GUI-ready**)
* Designed for **learning**, **experimentation**, and **extension**


---

##  Contributing

Contributions, ideas, and discussions are welcome.
This project is built **step by step** and open for exploration.

---
##  Project Status

 **SwiftQiskit is currently in an early experimental stage (v0.1).**

- Core quantum simulation is implemented
- API is subject to change
- Performance is not yet optimized
- GUI tools are optional and under development

The project is actively evolving, and major features are planned.
---
## ✅ What Works (v0.1)

- QuantumCircuit abstraction
- Single-qubit gates: H, X, Z
- Two-qubit entanglement (CNOT – limited v0.1)
- StateVector simulation
- Measurement with shots & counts
- Bell State example
- Unit tests for correctness
---
##  Roadmap

- [ ] General multi-qubit CNOT support
- [ ] Additional gates (Y, Phase, Rotation gates)
- [ ] Circuit visualization (ASCII / SwiftUI)
- [ ] Noise models
- [ ] Performance optimizations
- [ ] Stable public API (v1.0)

---

##  License

**MIT License** © 2025 **Ali Nasser**

---

##  Final Note

**SwiftQiskit** is not just a simulator —
it’s an attempt to make **quantum computing accessible, visual, and native** on Apple platforms.

Enjoy exploring the quantum world 

---

##  References

1. [Ali Nasser](https://github.com/a360n/SwiftQiskit)
2. [Medium](https://medium.com/@brianenochson/our-quantum-future-part-1-quantum-computing-introduction-f03aa4fc5f7f)
3. [Quantum Mechanics](https://www.amazon.com/Quantum-Mechanics-Theoretical-Leonard-Susskind-ebook/dp/B00FD36G1Q?ref_=ast_author_dp_rw&th=1&psc=1&dib=eyJ2IjoiMSJ9.RkHbIvheK8CPtFzsBgBe7r23a7uhLIlprKHFiYC4BOCvoD6WBdvaQA79CYfZj1_xwUNgGM2xOFd-NGea4XGiB8p7tZll3hdPz1B1IWaIf9jLZuA7h2hoqtpM43Ebaii5rpmm3tHvNMEoAEbVniy-PWV35vm2I2ePmaG4bFhykzpwVySzN3XKJPylPmR4lL1GdKme919H-EXrNmLDhJZ7p8eEeOHQzQIdUK8zwBuPWQY.BXHnclSf8mfD4zk9Rtha8_j22VdyFHEKXfjT5yVZ2Ew&dib_tag=AUTHOR)



