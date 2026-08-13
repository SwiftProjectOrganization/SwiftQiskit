//: [Previous](@previous)

import Foundation
import SwiftQiskitCore

// ============================================================
// Grover's algorithm — searching with √N queries
// ============================================================
// The problem: among N = 2ⁿ items exactly one, |w⟩, is "marked",
// and all you have is an oracle that answers "is this the one?" —
// as a quantum phase oracle it flips the sign of |w⟩ and leaves
// every other basis state alone:
//
//   U_w |x⟩ = (−1)^[x = w] |x⟩
//
// Classically you can only try items one by one: ~N/2 queries on
// average, N − 1 in the worst case. Grover's algorithm (1996) finds
// |w⟩ with high probability in about (π/4)·√N queries.
//
// One Grover iteration is two reflections:
//
//   1. oracle U_w      — flip the sign of the marked amplitude
//   2. diffusion D     — reflect every amplitude about the mean
//                        (D = 2|s⟩⟨s| − I, with |s⟩ the uniform
//                        superposition)
//
// Together they rotate the state by an angle 2θ toward |w⟩, where
// sin θ = 1/√N. After k iterations P(measure w) = sin²((2k+1)θ).
// For N = 4, sin θ = 1/2 so θ = π/6 — and a *single* iteration
// gives sin²(π/2) = 1: the marked item is found with certainty
// from one oracle query, where a classical search needs 2.25 on
// average.
//
// Controlled-Z is not a native gate, but Section 1 builds it from
// cx and h; Section 8 goes to 3 qubits, where Grover's
// probabilistic, iterative character shows itself.

// ============================================================
// Section 1 — CZ from the gates we already have
// ============================================================
// Controlled-Z flips the sign of |11⟩ only. Conjugating CNOT's
// target with Hadamards turns its X into a Z (H X H = Z), so
//
//   CZ = (I ⊗ H) · CNOT · (I ⊗ H)  →  h(1); cx(0,1); h(1)
//
// and since cx(control, target) now works between any distinct pair
// of qubits, the same trick builds CZ wherever it is needed.

func cz(_ qc: QuantumCircuit) {
    qc.h(1)
    qc.cx(0, 1)
    qc.h(1)
}

/// Format a state as zero-padded basis kets with amplitudes,
/// skipping (numerically) zero terms.
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { index -> String in
            var label = String(index, radix: 2)
            while label.count < qubits { label = "0" + label }
            return "|\(label)⟩: \(state[index])"
        }
        .joined(separator: "   ")
}

let czCheck = QuantumCircuit(qubits: 2)
czCheck.h(0)
czCheck.h(1)
cz(czCheck)
print("CZ on |s⟩:  \(pretty(czCheck.run(), qubits: 2))")
// Expected: |00⟩, |01⟩, |10⟩ at +0.5 and |11⟩ at −0.5 —
// only the |11⟩ amplitude flips sign.

// ============================================================
// Section 2 — The four oracles
// ============================================================
// A phase oracle for any marked state |w⟩ is CZ conjugated by X
// gates: X on every qubit whose bit in w is 0 maps |w⟩ ↔ |11⟩,
// CZ flips the sign there, and the X's map back. (Qubit 0 is the
// most-significant/leftmost bit.)

struct GroverOracle {
    let name: String
    let markedIndex: Int
    let apply: (QuantumCircuit) -> Void
}

/// Phase oracle flipping the sign of the 2-qubit basis state `marked`.
func phaseOracle(marked: Int) -> (QuantumCircuit) -> Void {
    { qc in
        let zeroBits = (0..<2).filter { (marked >> (1 - $0)) & 1 == 0 }
        for q in zeroBits { qc.x(q) }
        cz(qc)
        for q in zeroBits { qc.x(q) }
    }
}

let oracles: [GroverOracle] = (0..<4).map { m in
    var label = String(m, radix: 2)
    while label.count < 2 { label = "0" + label }
    return GroverOracle(name: "|\(label)⟩", markedIndex: m, apply: phaseOracle(marked: m))
}

// Each oracle flips exactly its own term of the uniform superposition:
for oracle in oracles {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0)
    qc.h(1)
    oracle.apply(qc)
    print("U_\(oracle.markedIndex) on |s⟩:  \(pretty(qc.run(), qubits: 2))")
}
// Expected: in row m, only basis state m carries the − sign.

// ============================================================
// Section 3 — Diffusion: inversion about the mean
// ============================================================
// The diffusion operator D = 2|s⟩⟨s| − I reflects each amplitude aᵢ
// about the mean ā:  aᵢ → 2ā − aᵢ. It is the same X-conjugated CZ
// trick, this time sandwiched in Hadamards so the reflection happens
// about |s⟩ instead of |11⟩. (The gate version below actually equals
// −D — a global phase, which no measurement can see.)

func diffusion(_ qc: QuantumCircuit) {
    qc.h(0); qc.h(1)
    qc.x(0); qc.x(1)
    cz(qc)
    qc.x(0); qc.x(1)
    qc.h(0); qc.h(1)
}

// Stage by stage for marked |10⟩. `run()` replays the recorded
// operations on a fresh |00⟩, so we can grow the circuit and peek.

let walk = QuantumCircuit(qubits: 2)

walk.h(0)
walk.h(1)
print("\nuniform |s⟩:      \(pretty(walk.run(), qubits: 2))")
// Expected: all four amplitudes +0.5 — P(any item) = 1/4

walk.x(1)          // oracle for |10⟩: q1 is the 0 bit, so x(1) maps |10⟩ ↔ |11⟩ …
cz(walk)           // … flip the sign there …
walk.x(1)          // … and map back
let afterOracle = walk.run()
print("after oracle:     \(pretty(afterOracle, qubits: 2))")
// Expected: |10⟩ flips to −0.5, the rest stay +0.5. Note P is
// still 1/4 everywhere — the mark is hidden in the *phase*.

var amplitudeSum = Complex.zero
for i in 0..<afterOracle.dimension {
    amplitudeSum = amplitudeSum + afterOracle[i]
}
let mean = amplitudeSum * Complex(0.25)
print("amplitude mean:   \(mean)")
// Expected: (0.5 + 0.5 − 0.5 + 0.5)/4 = 0.25

diffusion(walk)
print("after diffusion:  \(pretty(walk.run(), qubits: 2))")
// Expected: |10⟩ only, amplitude ±1. Reflecting about the mean sends
// the unmarked 0.5 → 2·0.25 − 0.5 = 0 and the marked −0.5 → 1 (the
// gate version's global − makes it print as −1). One query, done.

// ============================================================
// Section 4 — One iteration, certain answer, all four oracles
// ============================================================

func groverCircuit(oracle: (QuantumCircuit) -> Void, iterations: Int) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0)
    qc.h(1)
    for _ in 0..<iterations {
        oracle(qc)
        diffusion(qc)
    }
    return qc
}

print("\nmarked   P(marked)  found")
for oracle in oracles {
    let qc = groverCircuit(oracle: oracle.apply, iterations: 1)
    let p = qc.run().probabilities[oracle.markedIndex]
    let check = p > 0.999 ? "✓" : "✗"
    print("\(oracle.name)     \(String(format: "%.4f", p))     \(check)")
}
// Expected: P(marked) = 1.0000 and ✓ for all four marked states —
// each found with certainty from a single oracle query.

// ============================================================
// Section 5 — Shots: every outcome is the marked item
// ============================================================
// Unlike Deutsch's ancilla coin-flip, here the *whole* register
// carries the answer: with P(marked) = 1 every shot agrees.

let shotCounts = groverCircuit(oracle: oracles[2].apply, iterations: 1).measure(shots: 1000)
print("\nmarked |10⟩, 1000 shots:")
for (state, count) in shotCounts.sortedCounts {
    print("  \(state): \(count)")
}
// Expected: 10: 1000 — no other outcome ever appears.

// ============================================================
// Section 6 — Over-rotation: more queries is not better
// ============================================================
// Each iteration rotates the state by 2θ (θ = π/6 for N = 4), so
// P(marked) = sin²((2k+1)·π/6) — it *oscillates*. k = 1 is exact;
// keep going and you rotate straight past the target.

print("\nk (iterations)  P(marked)")
for k in 0...4 {
    let qc = groverCircuit(oracle: oracles[2].apply, iterations: k)
    let p = qc.run().probabilities[2]
    print("      \(k)           \(String(format: "%.4f", p))")
}
// Expected: 0.2500, 1.0000, 0.2500, 0.2500, 1.0000 — the period-3
// oscillation of sin²((2k+1)π/6). Stopping at the right k matters.

// ============================================================
// Section 7 — The Dirac view: D = 2|s⟩⟨s| − I
// ============================================================
// Page 08's outer product builds the diffusion operator directly:
// |s⟩⟨s| projects onto the uniform superposition, and 2|s⟩⟨s| − I
// reflects about it. Applying it to the post-oracle state must match
// Section 3's gate construction — up to that global −1.

let sPrep = QuantumCircuit(qubits: 2)
sPrep.h(0)
sPrep.h(1)
let s = sPrep.run()

let projector = s * s†                      // |s⟩⟨s|
var d = Matrix(rows: 4, cols: 4)
for i in 0..<4 {
    for j in 0..<4 {
        d[i, j] = Complex(2) * projector[i, j] - (i == j ? Complex(1) : Complex.zero)
    }
}

let viaDirac = QuantumCircuit(qubits: 2)
viaDirac.h(0)
viaDirac.h(1)
viaDirac.x(1); cz(viaDirac); viaDirac.x(1)  // oracle for |10⟩
viaDirac.apply(d)                           // diffusion, built from ⟨bra|ket⟩
print("\nvia 2|s⟩⟨s| − I:  \(pretty(viaDirac.run(), qubits: 2))")
// Expected: |10⟩ at +1 — Section 3 gave −1, the same state up to the
// global phase, with identical probabilities.

// ============================================================
// Section 8 — Real Grover: 3 qubits, N = 8
// ============================================================
// N = 4 is a special case where one iteration is exact. For n > 2
// qubits the oracle needs a multi-controlled Z. cx now works between
// any pair of qubits, but a *doubly*-controlled Z still cannot be
// built from H/X/Z/CNOT alone (it needs phase-type gates the library
// doesn't have yet) — `apply(_:)` takes any full 2ⁿ×2ⁿ matrix, and
// CCZ is just the identity with the |111⟩ entry negated. h(_:) and
// x(_:) embed into registers of any size, so nothing else changes.

var ccz = Matrix.identity(size: 8)
ccz[7, 7] = Complex(-1)

/// Phase oracle flipping the sign of the 3-qubit basis state `marked`.
func oracle3(_ qc: QuantumCircuit, marked: Int) {
    let zeroBits = (0..<3).filter { (marked >> (2 - $0)) & 1 == 0 }
    for q in zeroBits { qc.x(q) }
    qc.apply(ccz)
    for q in zeroBits { qc.x(q) }
}

func diffusion3(_ qc: QuantumCircuit) {
    for q in 0..<3 { qc.h(q) }
    for q in 0..<3 { qc.x(q) }
    qc.apply(ccz)
    for q in 0..<3 { qc.x(q) }
    for q in 0..<3 { qc.h(q) }
}

func grover3(marked: Int, iterations: Int) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 3)
    for q in 0..<3 { qc.h(q) }
    for _ in 0..<iterations {
        oracle3(qc, marked: marked)
        diffusion3(qc)
    }
    return qc
}

// Now sin θ = 1/√8, so θ ≈ 20.7° and the optimal iteration count is
// round(π/(4θ) − 1/2) = 2 — with success probability sin²(5θ) ≈ 0.945,
// high but no longer certain. That is the generic Grover behaviour:
// ~(π/4)√N queries, then measure and *check* the answer (one classical
// evaluation), repeating the whole thing in the unlucky ~5% of runs.

print("\n3 qubits, marked |101⟩:")
print("k (iterations)  P(marked)")
for k in 1...4 {
    let p = grover3(marked: 5, iterations: k).run().probabilities[5]
    print("      \(k)           \(String(format: "%.4f", p))")
}
// Expected: 0.7813, 0.9453, 0.3301, 0.0122 — rising to the k = 2
// peak, then rotating past the target again.

let counts3 = grover3(marked: 5, iterations: 2).measure(shots: 1000)
print("\n1000 shots at the optimal k = 2:")
for (state, count) in counts3.sortedCounts {
    print("  \(state): \(count)")
}
// Expected: |101⟩ ≈ 945, the other seven states sharing the rest —
// versus the 125 per state a blind guess would give.

//: [Next](@next)
