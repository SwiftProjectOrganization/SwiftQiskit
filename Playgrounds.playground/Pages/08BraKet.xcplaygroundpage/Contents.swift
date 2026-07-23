//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// Section 1 — Kets, bras and the dagger (†)
// ============================================================
// Dirac notation writes a quantum state as a *ket* |ψ⟩ — a column
// vector — and its conjugate transpose as a *bra* ⟨ψ| — a row
// vector. In SwiftQiskit a ket is just a StateVector (`Ket` is a
// typealias), `Bra` holds the conjugated amplitudes, and the
// postfix dagger operator † converts between them (it also gives
// the adjoint of a Matrix — Section 4).

let ketZero = Ket("0")      // |0⟩ from a binary label (same as Ket.zero)
let ketTen = Ket("10")      // |10⟩ — a two-qubit basis ket
let plus = Ket.plus         // |+⟩ = (|0⟩ + |1⟩)/√2

print("|+⟩ as a ket:")
print(plus)
print("\n⟨+| = |+⟩† as a bra:")
print(plus†)

// Dagger is an involution: (|ψ⟩†)† = |ψ⟩
print("\n(|+⟩†)† == |+⟩ → \((plus†)† == plus)")
// Expected: true

// ============================================================
// Section 2 — Inner products ⟨φ|ψ⟩
// ============================================================
// Bra * Ket is the inner product — a single Complex amplitude
// measuring the overlap of two states.

print("\n⟨0|0⟩ = \(Bra("0") * Ket("0"))")
// Expected: 1.0 — basis states are normalized …
print("⟨0|1⟩ = \(Bra("0") * Ket("1"))")
// Expected: 0.0 — … and orthogonal
print("⟨+|0⟩ = \(Ket.plus† * Ket.zero)")
// Expected: 0.7071 = 1/√2

// Any normalized state has ⟨φ|φ⟩ = 1
let ketPhi = Ket([Complex(0.6), Complex(0.8)])

print("⟨φ|φ⟩ = \(ketPhi† * ketPhi)")
// Expected: 1.0

// Conjugate symmetry: ⟨φ|ψ⟩ = ⟨ψ|φ⟩* — swapping bra and ket
// conjugates the amplitude
let forward = ketPhi† * Ket.plusI
let backward = Ket.plusI† * ketPhi
print("⟨φ|i⟩  = \(forward)")
print("⟨i|φ⟩* = \(backward.conjugate)")
// Expected: both 0.4243 + 0.5657i

// ============================================================
// Section 3 — Outer products and projectors |ψ⟩⟨ψ|
// ============================================================
// Ket * Bra is the outer product — a Matrix. |0⟩⟨0| projects any
// state onto |0⟩.

let p0 = Ket.zero * Ket.zero†
let p1 = Ket.one * Ket.one†
print("\n|0⟩⟨0| =\n\(p0)")
// Expected: [[1, 0], [0, 0]]
print("|1⟩⟨1| =\n\(p1)")
// Expected: [[0, 0], [0, 1]]

// Completeness: the basis projectors sum to the identity, so
// |ψ⟩ = |0⟩⟨0|ψ⟩ + |1⟩⟨1|ψ⟩ — every state decomposes over the basis.

// Born rule via a projector: P(0) = ⟨ψ| (|0⟩⟨0|) |ψ⟩
let born = ketPhi† * p0 * ketPhi
print("⟨φ|0⟩⟨0|φ⟩ = \(born)  vs  probabilities[0] = \(ketPhi.probabilities[0])")
// Expected: both 0.36

// ============================================================
// Section 4 — Matrix adjoints U†
// ============================================================
// † on a Matrix is the conjugate transpose. Quantum gates are
// unitary (U†U = I), and the Pauli gates are also Hermitian
// (U† = U) — which is why their expectation values are real
// (Section 6).

print("\nH† == H → \(HadamardGate.matrix† == HadamardGate.matrix)")
// Expected: true

// Core has no Pauli-Y gate yet (see the roadmap) — build it inline:
//   Y = [[0, −i], [i, 0]]
let pauliY = Matrix([
    [.zero, Complex(0, -1)],
    [.i, .zero]
])
print("Y† == Y → \(pauliY† == pauliY)")
// Expected: true

print("H†H =\n\(HadamardGate.matrix† * HadamardGate.matrix)")
// Expected: ≈ identity (up to ~1e-16 rounding)

// ============================================================
// Section 5 — Multi-qubit kets and bras
// ============================================================
// Basis labels follow the qubit-0-is-MSB convention, and ⊗ combines
// registers exactly like label concatenation:

print("\n|01⟩ == |0⟩ ⊗ |1⟩ → \(Ket("01") == Ket.zero ⊗ Ket.one)")
// Expected: true

// Conjugation distributes over ⊗, so (|a⟩ ⊗ |b⟩)† = ⟨a| ⊗ ⟨b|
// — exactly: conjugation doesn't touch the doubles, and
// re-normalizing an already-normalized state is a no-op.
print("⟨+|⊗⟨1| == (|+⟩⊗|1⟩)† → \(Ket.plus† ⊗ Ket.one† == (Ket.plus ⊗ Ket.one)†)")
// Expected: true

// A Bell-state amplitude as a bra–ket product (circuit from page 01):
let bellCircuit = QuantumCircuit(qubits: 2)
bellCircuit.h(0)
bellCircuit.cx(0, 1)
let bellState = bellCircuit.run()
print("⟨11|Φ⁺⟩ = \(Bra("11") * bellState)")
// Expected: 0.7071 = 1/√2

// ============================================================
// Section 6 — The initial qubit from page 07
// ============================================================
// Page 07's Bloch sphere starts at θ = 60°, φ = 45°, using the
// parametrization
//
//   |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
//
// Its console readout *labelled* the amplitudes α = ⟨0|ψ⟩ and
// β = ⟨1|ψ⟩; with bras those are now real expressions.

/// Build |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩ (as on page 07)
func makeState(theta: Double, phi: Double) -> StateVector {
    StateVector([
        Complex(cos(theta / 2)),
        Complex(sin(theta / 2) * cos(phi), sin(theta / 2) * sin(phi))
    ])
}

let theta = Double.pi / 3
let phi = Double.pi / 4
let psi = makeState(theta: theta, phi: phi)

print("\nα = ⟨0|ψ⟩ = \(Bra("0") * psi)")
// Expected: 0.8660 = cos 30°
print("β = ⟨1|ψ⟩ = \(Bra("1") * psi)")
// Expected: 0.3536 + 0.3536i = 0.5·e^{iπ/4}

// The Bloch coordinates drawn on page 07 are exactly the Pauli
// expectation values of |ψ⟩:
//
//   x = ⟨ψ|X|ψ⟩ = sin θ cos φ
//   y = ⟨ψ|Y|ψ⟩ = sin θ sin φ
//   z = ⟨ψ|Z|ψ⟩ = cos θ
//
// Each is real because X, Y, Z are Hermitian (Section 4).

let expectX = psi† * PauliXGate.matrix * psi
let expectY = psi† * pauliY * psi
let expectZ = psi† * PauliZGate.matrix * psi

print(String(format: "⟨ψ|X|ψ⟩ = %.4f   (sin θ cos φ = %.4f)",
             expectX.real, sin(theta) * cos(phi)))
print(String(format: "⟨ψ|Y|ψ⟩ = %.4f   (sin θ sin φ = %.4f)",
             expectY.real, sin(theta) * sin(phi)))
print(String(format: "⟨ψ|Z|ψ⟩ = %.4f   (cos θ     = %.4f)",
             expectZ.real, cos(theta)))
// Expected: 0.6124, 0.6124, 0.5000

// BlochVector (shared Sources) computes the same point from the
// amplitudes directly — x = 2·Re(ᾱβ), y = 2·Im(ᾱβ), z = |α|² − |β|².
let bloch = BlochVector(psi)
print(String(format: "BlochVector: x %.4f  y %.4f  z %.4f",
             bloch.x, bloch.y, bloch.z))
// Expected: the same three numbers

// ============================================================
// Section 7 — |ψ⟩ on the 3D Bloch sphere
// ============================================================
// The same Bloch3DView as page 07, frozen at the initial qubit:
// its x/y/z readout shows the three expectation values from
// Section 6. Drag to rotate. (No @State in page code — the view's
// interaction state lives in Sources, per the Xcode 27 beta
// workaround in PLAYGROUNDSUPPORT.md.)

PlaygroundPage.current.setLiveView(
    Bloch3DView(
        label: "|ψ⟩  θ = 60.0°, φ = 45.0°",
        bloch: bloch,
        size: 320
    )
    .frame(width: 420, height: 470)
)

//: [Next](@next)
