//: [Previous](@previous)

import Foundation
import SwiftQiskitCore

// ============================================================
// Deutsch's algorithm — one query beats two
// ============================================================
// The problem: you are handed a black-box function f: {0,1} → {0,1}
// and must decide whether it is
//
//   constant — f(0) = f(1)   (the two f's:  f(x) = 0,  f(x) = 1)
//   balanced — f(0) ≠ f(1)   (the two f's:  f(x) = x,  f(x) = 1−x)
//
// Classically you must evaluate f twice — knowing f(0) alone tells
// you nothing about f(1). Deutsch's algorithm (1985) decides it with
// a *single* query to a quantum oracle, by asking about a global
// property of f (the parity f(0) ⊕ f(1)) instead of its values.
//
// The circuit, on 2 qubits (qubit 0 = input register, qubit 1 =
// ancilla; remember qubit 0 is the most-significant/leftmost bit):
//
//   1. x(1)              prepare |01⟩
//   2. h(0), h(1)        → |+⟩|−⟩ — input in superposition,
//                          ancilla in the phase-kickback state |−⟩
//   3. oracle U_f        |x⟩|y⟩ → |x⟩|y ⊕ f(x)⟩, one single query
//   4. h(0)              interfere the two branches
//   5. measure qubit 0   0 ⇒ constant, 1 ⇒ balanced — with certainty
//
// The trick is step 3 acting on the |−⟩ ancilla: because
// X|−⟩ = −|−⟩, the oracle leaves the ancilla untouched and instead
// *kicks the value of f back as a phase* on the input qubit:
//
//   |x⟩|−⟩ → (−1)^f(x) |x⟩|−⟩
//
// A constant f phases both branches of |+⟩ equally (a global phase,
// invisible), while a balanced f flips the relative sign, turning
// |+⟩ into |−⟩. The final Hadamard maps |+⟩ → |0⟩ and |−⟩ → |1⟩,
// so one measurement reads off the answer.

// ============================================================
// Section 1 — The four possible oracles
// ============================================================
// There are exactly four functions {0,1} → {0,1}, and every one of
// their oracles U_f: |x⟩|y⟩ → |x⟩|y ⊕ f(x)⟩ is buildable from gates
// the library already has:
//
//   f(x) = 0    constant   y ⊕ 0 = y        → do nothing (identity)
//   f(x) = 1    constant   y ⊕ 1 = NOT y    → x(1)
//   f(x) = x    balanced   y ⊕ x            → cx(0, 1)
//   f(x) = 1−x  balanced   y ⊕ x ⊕ 1        → cx(0, 1) then x(1)
//
// Note the input qubit is only ever a *control* — U_f never changes
// |x⟩ directly, which is what makes the phase-kickback reading valid.

struct DeutschOracle {
    let name: String
    let isBalanced: Bool
    let apply: (QuantumCircuit) -> Void
}

let oracles: [DeutschOracle] = [
    DeutschOracle(name: "f(x) = 0  ", isBalanced: false) { _ in },
    DeutschOracle(name: "f(x) = 1  ", isBalanced: false) { $0.x(1) },
    DeutschOracle(name: "f(x) = x  ", isBalanced: true) { $0.cx(0, 1) },
    DeutschOracle(name: "f(x) = 1−x", isBalanced: true) { $0.cx(0, 1); $0.x(1) }
]

// ============================================================
// Section 2 — Building the algorithm as a circuit
// ============================================================
// Steps 1–4 above, with the oracle passed in as a closure. The
// oracle is queried exactly once.

func deutschCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(1)                 // 1. ancilla to |1⟩:      |01⟩
    qc.h(0)                 // 2. input to |+⟩,
    qc.h(1)                 //    ancilla to |−⟩:      |+⟩|−⟩
    oracle(qc)              // 3. the single query
    qc.h(0)                 // 4. interfere
    return qc
}

/// Format a 2-qubit state as zero-padded basis kets with amplitudes,
/// skipping (numerically) zero terms.
func pretty(_ state: StateVector) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { index -> String in
            let label = String(index, radix: 2).count < 2
                ? "0" + String(index, radix: 2)
                : String(index, radix: 2)
            return "|\(label)⟩: \(state[index])"
        }
        .joined(separator: "   ")
}

// ============================================================
// Section 3 — Watching phase kickback, stage by stage (f(x) = x)
// ============================================================
// `run()` replays all recorded operations on a fresh |00⟩, so we can
// build the circuit up one stage at a time and peek at the state
// after each addition.

let walk = QuantumCircuit(qubits: 2)

walk.x(1)
print("after x(1):        \(pretty(walk.run()))")
// Expected: |01⟩ — input 0, ancilla 1

walk.h(0)
walk.h(1)
print("after h(0), h(1):  \(pretty(walk.run()))")
// Expected: (|00⟩ − |01⟩ + |10⟩ − |11⟩)/2 = |+⟩|−⟩

walk.cx(0, 1)
print("after cx(0,1):     \(pretty(walk.run()))")
// Expected: (|00⟩ − |01⟩ − |10⟩ + |11⟩)/2 = |−⟩|−⟩
// The kickback: the ancilla is unchanged, but the input qubit's
// |1⟩ branch (where f(x)=1) picked up the − sign — |+⟩ became |−⟩.

walk.h(0)
print("after final h(0):  \(pretty(walk.run()))")
// Expected: (|10⟩ − |11⟩)/√2 = |1⟩|−⟩
// Qubit 0 is now *exactly* |1⟩: measuring it must give 1 → balanced.

// ============================================================
// Section 4 — One query, certain answer, for all four oracles
// ============================================================
// P(qubit 0 = 1) is the total probability of |10⟩ and |11⟩
// (basis indices 2 and 3). It comes out exactly 0 for the constant
// f's and exactly 1 for the balanced ones — the measurement is
// deterministic, no statistics needed.

print("\noracle       P(q0=1)  verdict     expected")
for oracle in oracles {
    let qc = deutschCircuit(oracle: oracle.apply)
    let probs = qc.run().probabilities
    let pOne = probs[2] + probs[3]
    let verdict = pOne > 0.5 ? "balanced" : "constant"
    let expected = oracle.isBalanced ? "balanced" : "constant"
    let check = verdict == expected ? "✓" : "✗"
    print("\(oracle.name)   \(String(format: "%.4f", pOne))   \(verdict)    \(expected) \(check)")
}
// Expected: P(q0=1) = 0.0000 for f=0 and f=1, 1.0000 for f=x and
// f=1−x — all four verdicts ✓, each from a single oracle query.

// ============================================================
// Section 5 — Shots: the answer bit vs. the ancilla bit
// ============================================================
// Sampling shows the same thing statistically. The leftmost bit
// (qubit 0) of every outcome string is the verdict and never varies;
// the ancilla ends in |−⟩, so its bit is a fair coin (~50/50) —
// it carried the phase, not the answer.

let constantCounts = deutschCircuit(oracle: oracles[1].apply).measure(shots: 1000)
print("\nf(x) = 1 (constant), 1000 shots:")
for (state, count) in constantCounts.sortedCounts {
    print("  \(state): \(count)")
}
// Expected: only 00 and 01, roughly 500 each — leftmost bit always 0

let balancedCounts = deutschCircuit(oracle: oracles[2].apply).measure(shots: 1000)
print("\nf(x) = x (balanced), 1000 shots:")
for (state, count) in balancedCounts.sortedCounts {
    print("  \(state): \(count)")
}
// Expected: only 10 and 11, roughly 500 each — leftmost bit always 1

// ============================================================
// Section 6 — Why the kickback works: X|−⟩ = −|−⟩
// ============================================================
// The whole algorithm rests on |−⟩ being an eigenvector of X with
// eigenvalue −1 (page 08's Dirac notation makes this a one-liner).
// Writing y ⊕ f(x) as "apply X to the ancilla f(x) times", the
// oracle multiplies each |x⟩ branch by (−1)^f(x) — value becomes
// phase, and interference does the rest.

var xMinus = Ket.minus
xMinus.apply(PauliXGate.matrix)
print("\n⟨−| X |−⟩ = \(Ket.minus† * xMinus)")
// Expected: ≈ −1 (up to rounding) — the eigenvalue powering the algorithm

//: [Next](@next)
