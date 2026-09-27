//: [Previous](@previous)
/*:
 # Basis transformations

 Every other page reads amplitudes off in the computational basis {|0⟩, |1⟩}. This page
 asks: given |ψ⟩ in that basis, what are its coordinates in a *different* basis, say
 {|+⟩, |−⟩}? The mechanics: stack the new basis kets as the **columns** of a matrix `T`,
 so `|ψ⟩ = T·c`. Because `T` is unitary, solving for `c` means inverting `T`, and for a
 unitary matrix the inverse is the conjugate transpose: `c = T⁻¹|ψ⟩ = T†|ψ⟩`. The **rows**
 of `T†` are the bras of the new basis, so each new amplitude is literally an inner product:
 `cⱼ = ⟨bⱼ|ψ⟩`. A second basis, {|+i⟩, |−i⟩}, shows why the *conjugate* transpose is
 required and a plain transpose is not enough.
 */

import Foundation
import SwiftQiskit

// ------------------------------------------------------------
// §1 — The problem: |0⟩ in the {|+⟩, |−⟩} basis
// ------------------------------------------------------------

let psi: Ket = .zero
// Want c₊, c₋ such that |ψ⟩ = c₊|+⟩ + c₋|−⟩

// ------------------------------------------------------------
// §2 — Build T column by column from the new basis kets
// ------------------------------------------------------------

let T = Matrix((0..<2).map { row in [Ket.plus[row], Ket.minus[row]] })
print(T)
// column 0 is |+⟩'s amplitudes, column 1 is |−⟩'s — exactly T·(1,0) = |+⟩, T·(0,1) = |−⟩

// ------------------------------------------------------------
// §3 — Construct the transpose by hand: its rows are the new bras
// ------------------------------------------------------------

let Tdag = Matrix([Bra(Ket.plus).amplitudes, Bra(Ket.minus).amplitudes])
print(Tdag)

func plainTranspose(_ m: Matrix) -> Matrix {
    var result = Matrix(rows: m.cols, cols: m.rows)
    for i in 0..<m.rows {
        for j in 0..<m.cols {
            result[j, i] = m[i, j]
        }
    }
    return result
}

print(Tdag == T.adjoint, Tdag == plainTranspose(T))
// true, true — hand-built row-of-bras matches both the library's T.adjoint and a plain
// transpose, because every amplitude in the ± basis happens to be real (§6 breaks this)

// ------------------------------------------------------------
// §4 — Compute the new amplitudes: row j of T† times ψ is ⟨bⱼ|ψ⟩
// ------------------------------------------------------------

let c = Tdag.multiply(by: psi.amplitudes)
print(c)
// [0.7071067811865475, 0.7071067811865475]

print(Ket.plus† * psi, Ket.minus† * psi)
// identical to c[0], c[1] — T†ψ IS the stack of inner products ⟨+|ψ⟩, ⟨−|ψ⟩

print(c.map { $0.magnitudeSquared })
// [0.4999999999999999, 0.4999999999999999] — |0⟩ is certain in Z, an even split in ±

// Same machinery on a state that isn't a Z eigenstate: ket1 from page 01Qubits
let ket1 = Ket([Complex(0.8660254037844387), Complex(0.35355339059327373, 0.3535533905932737)])
let c1 = Tdag.multiply(by: ket1.amplitudes)
print(c1, c1.map { $0.magnitudeSquared })
// [0.8623724356957945+0.25i, 0.3623724356957945-0.25i], probs [0.806, 0.194] — vs. ket1's
// own Z-basis probabilities [0.75, 0.25]; a different basis, a different distribution

// ------------------------------------------------------------
// §5 — Why the transpose is the inverse: T† is really T⁻¹
// ------------------------------------------------------------

print(Tdag * T)
// ≈ identity — unitarity, i.e. the new basis kets are orthonormal: ⟨bᵢ|bⱼ⟩ = δᵢⱼ

print(Tdag == HadamardGate.matrix)
// true — for the ± basis this whole construction reduces to the Hadamard gate

let rebuilt = T.multiply(by: c)
print(rebuilt)
// [0.9999999999999998, 0.0] — round trip: T·(T†ψ) restores ψ

// ------------------------------------------------------------
// §6 — A complex basis: {|+i⟩, |−i⟩} needs the CONJUGATE transpose
// ------------------------------------------------------------

let Ti = Matrix((0..<2).map { row in [Ket.plusI[row], Ket.minusI[row]] })
let TiDag = Matrix([Bra(Ket.plusI).amplitudes, Bra(Ket.minusI).amplitudes])
let TiTransposeOnly = plainTranspose(Ti)

print(TiDag == Ti.adjoint, TiDag == TiTransposeOnly)
// true, false — this time the hand-built row-of-bras still matches T.adjoint, but a
// PLAIN transpose is a genuinely different matrix (its off-diagonal signs are flipped)

for (name, state) in [("zero", Ket.zero), ("plusI", Ket.plusI)] {
    let viaTranspose = TiTransposeOnly.multiply(by: state.amplitudes)
    let viaAdjoint = TiDag.multiply(by: state.amplitudes)
    print(name, "plain transpose:", viaTranspose, viaTranspose.map { $0.magnitudeSquared })
    print(name, "conjugate transpose:", viaAdjoint, viaAdjoint.map { $0.magnitudeSquared })
}
// |0⟩ can't tell the difference (its amplitudes are real), but |+i⟩ gives it away: the
// plain transpose reports probabilities [0.0, 1.0] — as if |+i⟩ were really |−i⟩ — while
// the conjugate transpose correctly reports [1.0, 0.0]. Only T† is the true inverse of T.

print(TiTransposeOnly * Ti)
print(TiDag * Ti)
// the plain transpose fails the unitarity check (it's a permutation-like matrix, not I),
// while T.adjoint * T IS the identity — confirming T† is Ti's actual inverse

// ------------------------------------------------------------
// §7 — Measuring in the new basis: T† is exactly the gate to apply first
// ------------------------------------------------------------

// ± basis: T† = H, so "measure in ±" means h(0), then measure as usual
let zeroInPM = QuantumCircuit(qubits: 1)
zeroInPM.h(0)
print(zeroInPM.measure(shots: 1000).counts)
// ["0": 485, "1": 515] — |0⟩ splits close to 50/50 in the ± basis

let plusInPM = QuantumCircuit(qubits: 1)
plusInPM.h(0)   // prepare |+⟩
plusInPM.h(0)   // rotate the ± basis onto Z
print(plusInPM.measure(shots: 1000).counts)
// ["0": 1000] — |+⟩ is certain once measured in its own basis

// ±i basis: T† = H · Sdg, i.e. apply sdg(0) FIRST, then h(0) (QuantumCircuit applies
// gates in placement order; the combined matrix is H * Sdg, matching §6's TiDag exactly)
let zeroInPMi = QuantumCircuit(qubits: 1)
zeroInPMi.sdg(0)
zeroInPMi.h(0)
print(zeroInPMi.measure(shots: 1000).counts)
// ["0": 497, "1": 503] — again close to 50/50

let plusIInPMi = QuantumCircuit(qubits: 1)
plusIInPMi.h(0)
plusIInPMi.p(.pi / 2, 0)   // prepare |+i⟩ (use .pi, not a decimal literal — see 01QUBITSHELP.md)
plusIInPMi.sdg(0)
plusIInPMi.h(0)
print(plusIInPMi.measure(shots: 1000).counts)
// ["0": 1000] — |+i⟩ is likewise certain once measured in the ±i basis

//: [Next](@next)
