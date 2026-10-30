# SwiftQiskit 

**SwiftQiskit** is a lightweight **quantum computing simulator** written entirely in **Swift**. It brings a **Qiskit-like experience** to the Apple ecosystem, with a strong focus on **clarity**, **correctness**, and **GUI integration**. 

To get familiar with SwiftQiskit, it is suggested to start with the introductory documentation in [SwiftQiskitApp](https://github.com/SwiftProjectOrganization/SwiftQiskitApp) and [SwiftQiskitPlaygrounds](https://github.com/SwiftProjectOrganization/SwiftQiskitPlaygrounds), the two primary educational components, both built on SwiftQiskit.

Differences between this forked repository ("**fork**") and Ali Nasser's [parent, see reference 1](https://github.com/a360n/SwiftQiskit):
1. A separate App, [SwiftQiskitApp](https://github.com/SwiftProjectOrganization/SwiftQiskitApp), targeting macOS, iOS and iPadOS, is the SwiftUI "drag and drop" front-end for this package. SwiftQiskitGUI has been dropped from this fork.
2. Another project, [SwiftQiskitPlaygrounds](https://github.com/SwiftProjectOrganization/SwiftQiskitPlaygrounds) picks up where the App can't go and enables experimentation using Swift in Xcode playgrounds.
3. A template system is available to generate Swift apps, e.g. see the [SwiftQiskitWalkDemo](https://github.com/SwiftProjectOrganization/SwiftQiskitWalkDemo) application as an example. Or you can generate these by an AI coding solution, e.g. Claude Code+Sonnet.
4. A second library product in this repo, `SwiftQiskitViews` (`import SwiftQiskitViews`), holds presentational SwiftUI types (`BlochVector`, the Bloch-sphere views, `CHSHChartView`, `TensorNetworkView`) shared by `SwiftQiskitApp` and `SwiftQiskitPlaygrounds`, keeping the core `SwiftQiskit` module UI-free.
5. Using Swift Testing.

---

##  Features

- ✅ Complex number arithmetic  
- ✅ Matrix operations (`+ - *`, scalar multiply, Kronecker products)  
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
  - CNOT (Controlled-NOT), Toffoli (CCX), and general multi-controlled X (MCX)
  - CZ, CY, SWAP, and multi-controlled Z/Y (MCZ, MCY)
  - Two-qubit rotations RZZ(θ), RXX(θ), RYY(θ), and the general `pauliRotation`
- ✅ Single-qubit gate embedding  
- ✅ Quantum circuit abstraction  
- ✅ Measurement & state collapse  
- ✅ Bell State (Entanglement) example  
- ✅ Pauli strings & Hamiltonians (`PauliString`/`Hamiltonian`), Pauli-basis measurement and
  shot-based expectation values (`measureExpectation`)
- ✅ Hamiltonian simulation via Trotterized time evolution (`evolve`/`trotterCircuit`)
- ✅ Variational algorithms: exact parameter-shift gradients and a minimal gradient-descent
  optimizer (`ParameterShift`, `GradientDescent`)
- ✅ State tomography from measurement statistics (`StateTomography`)
- ✅ Open-system simulation: density matrices, Kraus channels, and noise models
  (`DensityMatrix`, `KrausChannel`, `NoiseModel`, `runDensityMatrix`/`runTrajectories`)
- ✅ Register arithmetic (`increment`/`decrement`) and marginal/parity readout helpers
- ✅ `SwiftQiskitViews` — a small, UI-only companion library (Bloch-vector math, a 2D chart
  view) shared by `SwiftQiskitApp` and `SwiftQiskitPlaygrounds`

---

##  Special Qubit States

Named single-qubit basis kets, defined as `Ket` (= `StateVector`) constants in
`Sources/SwiftQiskit/Quantum/Dirac.swift`:

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


**Built-in gates** — each is a `public enum` in `Sources/SwiftQiskit/Gates/` exposing
`static let matrix: Matrix` (parameterized gates expose `static func matrix(theta:)`),
with a matching convenience method on `QuantumCircuit`:

| Gate | Circuit API | Type |
|------|-------------|------|
| Hadamard (H) | `h(qubit)` | `HadamardGate` |
| Pauli-X (X) | `x(qubit)` | `PauliXGate` |
| Pauli-Y (Y) | `y(qubit)` | `PauliYGate` |
| Pauli-Z (Z) | `z(qubit)` | `PauliZGate` |
| S / S† | `s(qubit)` / `sdg(qubit)` | `SGate` / `SDaggerGate` |
| T / T† | `t(qubit)` / `tdg(qubit)` | `TGate` / `TDaggerGate` |
| Phase P(θ) | `p(theta, qubit)` | `PhaseGate` |
| RX/RY/RZ (θ) | `rx/ry/rz(theta, qubit)` | `RXGate` / `RYGate` / `RZGate` |
| CNOT (CX) | `cx(control, target)` | `CNOTGate` |
| Toffoli (CCX) | `ccx(control1, control2, target)` | `ToffoliGate` |
| CZ / multi-controlled Z | `cz(a, b)` / `mcz(controls, target)` | `ControlledZGate` / `MultiControlledZGate` |
| CY / multi-controlled Y | `cy(control, target)` / `mcy(controls, target)` | `ControlledYGate` / `MultiControlledYGate` |
| SWAP | `swap(a, b)` | `SwapGate` |
| MCX | `mcx(controls, target)` | `MultiControlledXGate` |
| RZZ/RXX/RYY (θ) | `rzz/rxx/ryy(theta, q0, q1)` | `RZZGate` / `RXXGate` / `RYYGate` |

`QuantumCircuit` also has a few operations that aren't tied to a single fixed-size gate enum:
`pauliRotation(_ pauli:theta:)` (the general Pauli-string rotation `rzz`/`rxx`/`ryy` are built
from), `rotateToZ(_:_:)` / `measure(shots:basis:)` (Pauli-basis measurement), `evolve(_:time:
steps:order:)` (Trotterized Hamiltonian simulation), and `increment`/`decrement(register:
controlledBy:)` (ripple-carry ±1 on a register, built from `mcx`). See [`API.md`](API.md) for
full signatures.

---

##  Special Operators

Custom operators on the quantum types (`Ket` = `StateVector`): the postfix dagger `†` is
declared in `Sources/SwiftQiskit/Quantum/Dirac.swift`, and the infix tensor product `⊗`
(at `MultiplicationPrecedence`) in `Sources/SwiftQiskit/Math/Matrix.swift`:

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
| `+` | `Matrix + Matrix` | `Matrix` | entrywise sum A + B | `Math/Matrix.swift` |
| `-` | `Matrix - Matrix` | `Matrix` | entrywise difference A − B | `Math/Matrix.swift` |
| `*` | `Matrix * Double` / `Double * Matrix` | `Matrix` | scalar multiple c·M | `Math/Matrix.swift` |
| `*` | `Matrix * Complex` / `Complex * Matrix` | `Matrix` | scalar multiple c·M | `Math/Matrix.swift` |

Scalar `Complex` arithmetic (`+ - * /`, negation, `Double` scaling) and the polar form
(`argument`, `Complex(magnitude:argument:)`, `Complex.exp`, `Complex.pow`) live in
`Math/Complex.swift`. Arithmetic on plain `[Complex]` vectors (`adding`, `subtracting`,
`scaled(by:)`, `inner`, `norm`, `normalized()`) lives in `Math/ComplexVector.swift`. Neither is
listed in the table — they act on numbers and raw vectors, not on qubit states or gates.

---

##  Design Philosophy

* No hidden magic — everything is **explicit and readable**
* Mathematical correctness over shortcuts
* Modular architecture (**Core / Views / Examples**, with the front-ends — `SwiftQiskitApp` and `SwiftQiskitPlaygrounds` — in sibling repos)
* Designed for **learning**, **experimentation**, and **extension**

---

##  Final Note

**SwiftQiskit** is not just a simulator —
it’s an attempt to make **quantum computing accessible, visual, and native** on Apple platforms.

Enjoy exploring the quantum world 

---

##  API Reference

For a full listing of every public type and member in the core library, see [`API.md`](API.md).

##  Project Structure for this fork

```text
SwiftQiskit/
├── Sources/
│   ├── SwiftQiskit/
│   │   ├── Math/
│   │   │   ├── Complex.swift
│   │   │   ├── ComplexVector.swift
│   │   │   ├── Matrix.swift
│   │   │   └── MatrixScalar.swift
│   │   ├── Quantum/
│   │   │   ├── StateVector.swift
│   │   │   ├── Dirac.swift
│   │   │   ├── SimulationResult.swift
│   │   │   ├── PauliBasis.swift
│   │   │   ├── PauliString.swift
│   │   │   ├── Hamiltonian.swift
│   │   │   ├── ParameterShift.swift
│   │   │   ├── StateTomography.swift
│   │   │   ├── DensityMatrix.swift
│   │   │   ├── KrausChannel.swift
│   │   │   ├── NoiseModel.swift
│   │   │   └── StateVector+Kernels.swift
│   │   ├── Gates/
│   │   │   ├── Hadamard.swift
│   │   │   ├── PauliX.swift
│   │   │   ├── PauliY.swift
│   │   │   ├── PauliZ.swift
│   │   │   ├── Phase.swift
│   │   │   ├── Rotation.swift
│   │   │   ├── CNOT.swift
│   │   │   ├── Toffoli.swift
│   │   │   ├── MultiControlledX.swift
│   │   │   ├── ControlledY.swift
│   │   │   ├── ControlledZ.swift
│   │   │   ├── Swap.swift
│   │   │   ├── MultiControlledY.swift
│   │   │   ├── MultiControlledZ.swift
│   │   │   └── TwoQubitRotation.swift
│   │   ├── Circuit/
│   │   │   ├── QuantumCircuit.swift
│   │   │   └── TensorNetwork.swift
│   │   └── Utils/
│   │       ├── Angles.swift
│   │       └── String+Padding.swift
│   └── SwiftQiskitViews/
│       ├── BlochVector.swift
│       ├── CHSHChartView.swift
│       └── TensorNetworkView.swift
├── Examples/
│   └── main.swift
├── Tests/
│   ├── SwiftQiskitTests/
│   │   ├── BellStateTests.swift
│   │   ├── TensorProductTests.swift
│   │   ├── DiracNotationTests.swift
│   │   ├── CNOTTests.swift
│   │   ├── AdditionalGatesTests.swift
│   │   ├── MatrixArithmeticTests.swift
│   │   ├── MeasurementTests.swift
│   │   ├── MatrixExponentialTests.swift
│   │   ├── TwoQubitRotationTests.swift
│   │   ├── ToffoliTests.swift
│   │   ├── ReadoutTests.swift
│   │   ├── PauliBasisTests.swift
│   │   ├── PauliStringTests.swift
│   │   ├── MeasureExpectationTests.swift
│   │   ├── StateTomographyTests.swift
│   │   ├── TrotterTests.swift
│   │   ├── ParameterShiftTests.swift
│   │   ├── RegisterArithmeticTests.swift
│   │   ├── DensityMatrixTests.swift
│   │   ├── KrausChannelTests.swift
│   │   ├── NoiseModelTests.swift
│   │   ├── CommutingGroupsTests.swift
│   │   ├── AngleConversionTests.swift
│   │   ├── GenericMatrixTests.swift
│   │   ├── StateVectorKernelTests.swift
│   │   ├── ControlledYTests.swift
│   │   ├── ControlledZAndSwapTests.swift
│   │   ├── PerformancePathTests.swift
│   │   ├── RunBenchmarkTests.swift
│   │   ├── PermutationFastPathTests.swift
│   │   └── TensorNetworkTests.swift
│   └── SwiftQiskitViewsTests/
│       ├── BlochVectorTests.swift
│       ├── CHSHChartViewTests.swift
│       └── TensorNetworkViewTests.swift
├── Package.swift
├── API.md               (full public API reference for the core library)
├── CLAUDE.md             (guidance for Claude Code working in this repo)
├── STATUSandTODO.md      (project status, roadmap, working TODO list)
└── References (tbd)
```

---

##  Getting Started with this fork

### Requirements

The package itself (`Package.swift`) declares `swift-tools-version: 5.9` and targets
macOS 27+ / iOS 27+, matching the deployment target of its consumer apps
(`SwiftQiskitApp`, `SwiftQiskitWalkDemo`).

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
import SwiftQiskit

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
> Note: This is the same code as `Examples/main.swift`, run via `swift run SwiftQiskitExamples`.

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

The proof-of-concept `Playgrounds.playground` and its `PlaygroundDocs/` guides were removed from
this repo (last present at the `pre-playground-removal` git tag). For learning, use
[SwiftQiskitApp](https://github.com/SwiftProjectOrganization/SwiftQiskitApp) and
[SwiftQiskitPlaygrounds](https://github.com/SwiftProjectOrganization/SwiftQiskitPlaygrounds).

The shared SwiftUI types — the Bloch-sphere views (`BlochSphereView`, `BlochProjectionView`,
`Bloch3DView`, `BlochExplorerView`), `BlochVector`, `CHSHChartView` and `TensorNetworkView` — live in
the `SwiftQiskitViews` package product, a small SwiftUI library depending only on `SwiftQiskit`, so
Core itself stays UI-free.

---

##  Contributing

Contributions, ideas, and discussions are welcome.
This project is built **step by step** and open for exploration.

---
##  Status & Roadmap

Project status, what works in v0.8.1, and the roadmap live in
[STATUSandTODO.md](STATUSandTODO.md), together with this fork's working TODO list.

---

##  License

**MIT License** © 2025 **Ali Nasser**

---

##  References

1. [Ali Nasser](https://github.com/a360n/SwiftQiskit)
2. [Quantum Computing for everyone](https://www.amazon.com/Quantum-Computing-Everyone-Mit-Press/dp/0262539535/ref=sr_1_1?crid=2FZXZMKUHTCMY&dib=eyJ2IjoiMSJ9.P7qqxqmMDjw-ATyR5LpVdh5xPQ4Y0b2Dzmdh3sxSRGv9O0zg3c4tC3cxXmuFSARdd16gdrlAtvEt4sjIXeZS4pYp3-V78bvNcF2QvOz5I8GsSjxKQvXwCqZE3pb_p8kHyldF_pJ2hZW2HNzJmFYV_MWw4BFvDKddzLBrDhMzSWEH8F_MRHIb2nt27dEMEVnUZNOByHEF6ZmBu_-HunbuU8Z7zWhQF2AvZUFBhHNOtHU.JVmku_grNC3YTp28qmqeX5hDii-RdfSijIAJlmX2gGE&dib_tag=se&keywords=chris+bernhardt%2C+quantum+computing+for+everyone&qid=1790170950&sprefix=Chris+Bern%2Caps%2C224&sr=8-1)
3. [Medium](https://medium.com/@brianenochson/our-quantum-future-part-1-quantum-computing-introduction-f03aa4fc5f7f)
4. [Quantum Mechanics](https://www.amazon.com/Quantum-Mechanics-Theoretical-Leonard-Susskind-ebook/dp/B00FD36G1Q?ref_=ast_author_dp_rw&th=1&psc=1&dib=eyJ2IjoiMSJ9.RkHbIvheK8CPtFzsBgBe7r23a7uhLIlprKHFiYC4BOCvoD6WBdvaQA79CYfZj1_xwUNgGM2xOFd-NGea4XGiB8p7tZll3hdPz1B1IWaIf9jLZuA7h2hoqtpM43Ebaii5rpmm3tHvNMEoAEbVniy-PWV35vm2I2ePmaG4bFhykzpwVySzN3XKJPylPmR4lL1GdKme919H-EXrNmLDhJZ7p8eEeOHQzQIdUK8zwBuPWQY.BXHnclSf8mfD4zk9Rtha8_j22VdyFHEKXfjT5yVZ2Ew&dib_tag=AUTHOR)



