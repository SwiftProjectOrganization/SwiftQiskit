//: [Previous](@previous)

import Foundation
import SwiftQiskitCore

// ============================================================
// Deutsch–Jozsa and Bernstein–Vazirani — one query, n bits
// ============================================================
// Page 10's Deutsch algorithm distinguishes constant from balanced
// f: {0,1} → {0,1} with a single query, on 1 input qubit. This page
// is the direct generalization to n input qubits (Deutsch–Jozsa,
// 1992), where the classical cost of the same decision is up to
// 2^(n−1)+1 queries in the worst case — and then reuses the identical
// circuit for Bernstein–Vazirani (1993), which recovers an entire
// hidden n-bit string from one query.
//
// The circuit is page 10's, unchanged except for n input qubits and
// the ancilla moved to the last one:
//
//   1. x(ancilla)             prepare the ancilla as |1⟩
//   2. h on every qubit       inputs → |+⟩^⊗n, ancilla → |−⟩
//   3. oracle U_f             one query, via phase kickback
//   4. h on every input       interfere
//   5. measure the inputs     all-zeros ⇒ constant (DJ), or the
//                             hidden string s itself (BV)

func label(_ i: Int, bits: Int) -> String {
    String(i, radix: 2).leftPadding(toLength: bits, withPad: "0")
}

// ============================================================
// Section 1 — the circuit, n input qubits + 1 ancilla
// ============================================================

let n = 3                 // input qubits 0..<n
let ancilla = n            // qubit n is the ancilla (last / least-significant)
let total = n + 1

func djCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: total)
    qc.x(ancilla)                     // 1. ancilla to |1⟩
    for q in 0...ancilla { qc.h(q) }  // 2. inputs → |+⟩^⊗n, ancilla → |−⟩
    oracle(qc)                        // 3. one query
    for q in 0..<n { qc.h(q) }        // 4. interfere the inputs only
    return qc
}

/// Marginal probability over the n input qubits, summing out the
/// ancilla (which sits in the least-significant position here).
func inputMarginal(_ qc: QuantumCircuit) -> [Double] {
    let probs = qc.run().probabilities
    var marginal = [Double](repeating: 0, count: 1 << n)
    for (i, p) in probs.enumerated() { marginal[i >> 1] += p }
    return marginal
}

// ============================================================
// Section 2 — oracles from `cx`, same recipe as page 10
// ============================================================
// A constant oracle never touches the ancilla, or always flips it.
// A balanced oracle is any nonzero linear function of the inputs
// written as XORs into the ancilla — `cx(q, ancilla)` for whichever
// input qubits appear.

struct Oracle {
    let name: String
    let isBalanced: Bool
    let apply: (QuantumCircuit) -> Void
}

let oracles: [Oracle] = [
    Oracle(name: "constant 0     ", isBalanced: false) { _ in },
    Oracle(name: "constant 1     ", isBalanced: false) { $0.x(ancilla) },
    Oracle(name: "balanced on x0 ", isBalanced: true) { $0.cx(0, ancilla) },
    Oracle(name: "balanced parity", isBalanced: true) { qc in
        for q in 0..<n { qc.cx(q, ancilla) }
    }
]

// ============================================================
// Section 3 — the verdict: one query, certain answer
// ============================================================
// P(all-zero input) is exactly 1 for a constant oracle and exactly 0
// for a balanced one — deterministic, from a single query, no matter
// how large n gets.

print("oracle             P(|000⟩)  verdict    expected")
for oracle in oracles {
    let marginal = inputMarginal(djCircuit(oracle: oracle.apply))
    let allZero = marginal[0]
    let verdict = allZero > 0.5 ? "constant" : "balanced"
    let expected = oracle.isBalanced ? "balanced" : "constant"
    let check = verdict == expected ? "✓" : "✗"
    print("\(oracle.name)   \(String(format: "%.4f", allZero))    \(verdict)   \(expected) \(check)")
}
// Expected: P(|000⟩) = 1.0000 for both constant oracles, 0.0000 for
// both balanced ones — all four verdicts ✓.

// ============================================================
// Section 4 — a gotcha: shots include the ancilla bit
// ============================================================
// `measure(shots:)` reports every qubit, including the ancilla — and
// the ancilla ends the circuit in |−⟩, an equal superposition, so its
// bit is a fair coin. Only the *input* bits (everything but the last
// character of each outcome string) are deterministic.

let balancedShots = djCircuit(oracle: oracles[2].apply).measure(shots: 200)
print("\nbalanced-on-x0, 200 shots, raw outcome strings:")
for (outcome, count) in balancedShots.sortedCounts {
    print("  \(outcome): \(count)")
}
// Expected: two outcomes, both starting "100" (the input bits, fixed)
// but differing in the last character (the ancilla, ~50/50) — e.g.
// "1000" and "1001" roughly evenly split. Slice off the last
// character before reading the verdict off shot data.

// ============================================================
// Section 5 — Bernstein–Vazirani: reading back a hidden string
// ============================================================
// Same circuit, oracle f(x) = s·x mod 2 for a hidden bit string s:
// XOR into the ancilla exactly the input qubits where s has a 1. The
// input register reads back s itself, with certainty, from one query
// — where a classical algorithm needs n separate queries (query e_i,
// the string with a single 1 in position i, to learn bit i).

func bvOracle(_ s: Int) -> (QuantumCircuit) -> Void {
    { qc in
        for q in 0..<n where (s >> (n - 1 - q)) & 1 == 1 {
            qc.cx(q, ancilla)
        }
    }
}

print("\nhidden s   recovered   P")
for s in [0b101, 0b110, 0b111, 0b000] {
    let marginal = inputMarginal(djCircuit(oracle: bvOracle(s)))
    let top = marginal.enumerated().max(by: { $0.element < $1.element })!
    print("\(label(s, bits: n))        \(label(top.offset, bits: n))         \(String(format: "%.4f", top.element))")
}
// Expected: every row recovers s exactly, with P = 1.0000.

// ============================================================
// Section 6 — the query-count gap
// ============================================================
// Quantum: always 1 query, for any n. Classical (worst case):
// Deutsch–Jozsa needs 2^(n−1)+1 queries to be *certain* (a classical
// algorithm can get unlucky and see the same output 2^(n−1) times
// from a balanced function before the 2^(n−1)+1'th query reveals it);
// Bernstein–Vazirani needs exactly n queries, one bit at a time.

print("\nn    quantum queries   classical DJ (worst case)   classical BV")
for bits in 2...5 {
    let classicalDJ = (1 << (bits - 1)) + 1
    print("\(bits)    1                 \(classicalDJ)                          \(bits)")
}
// Expected: quantum stays at 1 while classical DJ grows exponentially
// (3, 5, 9, 17) and classical BV grows linearly (2, 3, 4, 5).

//: [Next](@next)
