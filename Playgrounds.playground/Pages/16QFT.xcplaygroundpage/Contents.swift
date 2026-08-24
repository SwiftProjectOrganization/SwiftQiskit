//: [Previous](@previous)

import Foundation
import SwiftQiskitCore

// ============================================================
// The quantum Fourier transform — the gate decomposition
// ============================================================
// Page 12 needed the (inverse) QFT for phase estimation but built it
// as a single entrywise matrix, with a note that the textbook gate
// decomposition — Hadamards and controlled phase rotations, then a
// bit reversal — needed phase gates the library didn't expose at the
// time. It does now: `p(theta, qubit)` is the phase gate P(θ), and a
// *controlled* phase is buildable from `p` + `cx` alone. This page
// builds the real circuit and checks it against page 12's matrix.

func fmt(_ d: Double) -> String { String(format: "%.4f", d) }

// ============================================================
// Section 1 — the missing gate: controlled phase CP(θ)
// ============================================================
// CP(θ) should act as |11⟩ → e^(iθ)|11⟩ and leave |00⟩, |01⟩, |10⟩
// alone. The standard identity CP(θ) = P(θ/2)_c · CX · P(−θ/2)_t · CX
// · P(θ/2)_t needs no new Core gate — it's five calls to gates that
// already exist. `QuantumCircuit` records operations by mutating a
// circuit in place (`apply`/`h`/`cx`/…), so `cp` and every helper
// below follow the same shape: take a circuit, append to it.

func cp(_ qc: QuantumCircuit, _ theta: Double, _ control: Int, _ target: Int) {
    qc.p(theta / 2, control)
    qc.cx(control, target)
    qc.p(-theta / 2, target)
    qc.cx(control, target)
    qc.p(theta / 2, target)
}

/// SWAP as three CNOTs — needed for the bit-reversal step in Section 2.
func swapQubits(_ qc: QuantumCircuit, _ a: Int, _ b: Int) {
    qc.cx(a, b); qc.cx(b, a); qc.cx(a, b)
}

print("CP(θ) vs. the diagonal it should produce:")
for c in 0..<4 {
    let qc = QuantumCircuit(qubits: 2)
    if (c >> 1) & 1 == 1 { qc.x(0) }
    if c & 1 == 1 { qc.x(1) }
    cp(qc, Double.pi, 0, 1)
    let amps = qc.run().amplitudes
    let want = c == 3 ? "-1" : " 1"
    print("  input \(String(c, radix: 2).leftPadding(toLength: 2, withPad: "0")): amplitude at that index = \(amps[c])  (want \(want))")
}
// Expected: 1, 1, 1, and -1 (up to ~1e-16 rounding) — CP(π) on two
// qubits is exactly CZ, page 11's diffusion-operator building block,
// derived here instead of asserted.

// ============================================================
// Section 2 — the QFT circuit
// ============================================================
// For each qubit j (0 = most-significant, per the library's
// convention): a Hadamard, then a CP(2π/2^(k−j+1)) controlled by
// every later qubit k. That alone produces the transform with its
// output bits in *reversed* order — Section 3 shows why — so a swap
// network un-reverses them at the end. Written as an append-to-an-
// existing-circuit function, so it composes with a state-prep step
// on the same circuit (`QuantumCircuit` has no way to splice two
// separately-built circuits together).

func appendQFT(_ qc: QuantumCircuit, qubits n: Int, uncompute: Bool = false) {
    for j in 0..<n {
        qc.h(j)
        for k in (j + 1)..<n {
            cp(qc, 2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j)
        }
    }
    if !uncompute {
        for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
    }
}

func basisPrep(_ qc: QuantumCircuit, _ c: Int, qubits n: Int) {
    for q in 0..<n where (c >> (n - 1 - q)) & 1 == 1 { qc.x(q) }
}

// Compare every basis state's transform against page 12's entrywise
// formula QFT[y, c] = e^(2πi·y·c/N)/√N (this page builds the forward
// QFT; page 12 used its inverse).

let n = 3, N = 8
var maxDeviation = 0.0
for c in 0..<N {
    let qc = QuantumCircuit(qubits: n)
    basisPrep(qc, c, qubits: n)
    appendQFT(qc, qubits: n)
    let amps = qc.run().amplitudes
    for y in 0..<N {
        let theta = 2 * Double.pi * Double(y * c) / Double(N)
        let want = Complex(cos(theta), sin(theta)) * (1.0 / sqrt(Double(N)))
        maxDeviation = max(maxDeviation, (amps[y] - want).magnitude)
    }
}
print("\ngate-level QFT vs. entrywise formula: max amplitude deviation = \(maxDeviation)")
// Expected: ~1e-15 — the five-gate CP(θ) and the swap network really
// do implement the same unitary as page 12's hand-written matrix.

// ============================================================
// Section 3 — why the swaps: output order without them
// ============================================================
// Skip the final swap network (`uncompute: true` above) and the
// *amplitudes* land at the bit-reversal of where they belong — a
// direct consequence of qubit 0 being the most-significant bit
// throughout the H/CP ladder.

func bitReverse(_ y: Int, bits: Int) -> Int {
    var r = 0
    for i in 0..<bits { if (y >> i) & 1 == 1 { r |= 1 << (bits - 1 - i) } }
    return r
}

let probeInput = 3
let withSwapsCircuit = QuantumCircuit(qubits: n)
basisPrep(withSwapsCircuit, probeInput, qubits: n)
appendQFT(withSwapsCircuit, qubits: n)
let withSwaps = withSwapsCircuit.run().amplitudes

let withoutSwapsCircuit = QuantumCircuit(qubits: n)
basisPrep(withoutSwapsCircuit, probeInput, qubits: n)
appendQFT(withoutSwapsCircuit, qubits: n, uncompute: true)
let withoutSwaps = withoutSwapsCircuit.run().amplitudes

var reorderDeviation = 0.0
for y in 0..<N {
    reorderDeviation = max(reorderDeviation, (withSwaps[y] - withoutSwaps[bitReverse(y, bits: n)]).magnitude)
}
print("\nno-swap amplitude at y equals swapped amplitude at bit-reverse(y): max deviation = \(reorderDeviation)")
// Expected: ~1e-16 — confirming the swap network is exactly an
// un-reversal, not an incidental fix.

// ============================================================
// Section 4 — the inverse QFT, and unitarity
// ============================================================
// QFT† reverses the circuit and negates every angle — same gates,
// opposite order, opposite phases.

func appendInverseQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
    for j in stride(from: n - 1, through: 0, by: -1) {
        for k in stride(from: n - 1, through: j + 1, by: -1) {
            cp(qc, -2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j)
        }
        qc.h(j)
    }
}

// QFT then QFT† should return every basis state to itself.
var unitarityDeviation = 0.0
for c in 0..<N {
    let qc = QuantumCircuit(qubits: n)
    basisPrep(qc, c, qubits: n)
    appendQFT(qc, qubits: n)
    appendInverseQFT(qc, qubits: n)
    let state = qc.run()
    unitarityDeviation = max(unitarityDeviation, (state[c].magnitude - 1.0).magnitude)
}
print("\nQFT then QFT†, every basis state: max |amplitude at c| deviation from 1 = \(unitarityDeviation)")
// Expected: ~1e-15 — QFT and QFT† really are inverses.

// ============================================================
// Section 5 — phase estimation, standalone
// ============================================================
// The reason page 12 needed the QFT† at all: estimate an unknown
// phase φ encoded in a 1-qubit unitary P(2πφ), using n counting
// qubits and one eigenstate qubit prepared in |1⟩ (P(2πφ)|1⟩ =
// e^(2πiφ)|1⟩). Controlled powers P(2πφ)^(2^k) write φ's binary
// digits into the phases of the counting register; QFT† reads them
// back out as amplitudes.

func phaseEstimation(counting n: Int, phase: Double) -> [Double] {
    let total = n + 1
    let qc = QuantumCircuit(qubits: total)
    qc.x(n)                                    // eigenstate |1⟩ of P(θ)
    for q in 0..<n { qc.h(q) }
    for j in 0..<n {
        let power = 1 << (n - 1 - j)
        cp(qc, 2 * Double.pi * phase * Double(power), j, n)
    }
    appendInverseQFT(qc, qubits: n)
    let probs = qc.run().probabilities
    var marginal = [Double](repeating: 0, count: 1 << n)
    for (i, p) in probs.enumerated() { marginal[i >> 1] += p }   // eigenstate qubit is the LSB
    return marginal
}

print("\nphase       best estimate   P(that estimate)")
for phase in [0.125, 0.5, 0.75] {
    let marginal = phaseEstimation(counting: 3, phase: phase)
    let top = marginal.enumerated().max(by: { $0.element < $1.element })!
    let estimate = Double(top.offset) / 8.0
    print("\(fmt(phase))       \(fmt(estimate))          \(fmt(top.element))")
}
// Expected: exact recovery (P = 1.0000) for every dyadic phase (a
// multiple of 1/8) — 3 counting qubits resolve eighths exactly.

// A phase that isn't a multiple of 1/8 can't land on a single
// counting value; the distribution spreads over its neighbors.
let spreadMarginal = phaseEstimation(counting: 3, phase: 0.3)
print("\nφ = 0.3 (not a multiple of 1/8), 3 counting qubits:")
for (y, p) in spreadMarginal.enumerated() where p > 0.01 {
    print("  y=\(y) (estimate \(fmt(Double(y) / 8.0))): P = \(fmt(p))")
}
// Expected: peak at y=2 (estimate 0.25, P≈0.578) and runner-up at
// y=3 (estimate 0.375, P≈0.259) — together ≈0.84, above the textbook
// worst-case bound of 8/π² ≈ 0.81 for landing within 1 unit of the
// true value.

// ============================================================
// Section 6 — precision scales with counting qubits
// ============================================================
// More counting qubits narrow the grid the estimate is rounded to
// (1/2^n), so the same φ = 0.3 is resolved more tightly.

print("\ncounting qubits   best estimate   error     P")
for counting in [3, 6] {
    let marginal = phaseEstimation(counting: counting, phase: 0.3)
    let top = marginal.enumerated().max(by: { $0.element < $1.element })!
    let estimate = Double(top.offset) / Double(1 << counting)
    print("\(counting)                 \(fmt(estimate))          \(fmt(abs(estimate - 0.3)))    \(fmt(top.element))")
}
// Expected: 3 counting qubits land on 0.2500 (error 0.0500, P=0.578);
// 6 counting qubits land on 0.2969 (error 0.0031, P=0.875) — both the
// error and the concentration of probability improve together.

//: [Next](@next)
