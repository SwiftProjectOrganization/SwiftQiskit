//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ============================================================
// The discrete-time quantum walk — interference as a resource
// ============================================================
// No earlier page shows interference producing a *distribution*
// rather than answering an oracle question (Deutsch/DJ/BV) or
// amplifying a marked item (Grover). A coin qubit plus a position
// register on a cycle does exactly that.
//
// Register: a coin qubit (q0) plus a 4-bit position register
// (q1..q4, 16 sites, total dimension 32). 16 sites — not 8 — because
// a walk starting at site 0 can reach sites −t..+t after t steps;
// avoiding wraparound self-overlap through t=7 needs 2·7+1 = 15
// distinct sites, and 8 would alias by t≈4.

func fmt(_ d: Double) -> String { String(format: "%.4f", d) }

let numSites = 16
let dim = 32

// ============================================================
// Section 1 — the conditional shift, from increment/decrement
// ============================================================
// |0,x⟩ → |0,x+1 mod 16⟩ (coin 0: step right), |1,x⟩ → |1,x−1 mod 16⟩
// (coin 1: step left). The position register q1..q4 is exactly a
// 4-bit counter, so the shift is a controlled ±1 on it —
// `QuantumCircuit.increment`/`decrement(register:controlledBy:)`
// (most-significant qubit first, matching q1..q4 here) — rather than
// a hand-built `Matrix.permutation`. `decrement` handles coin 1
// directly (`controlledBy` fires on 1); coin 0 reuses the same
// `increment` by flipping the coin around it with `x(0)`.

func appendShift(to qc: QuantumCircuit) {
    qc.decrement(register: [1, 2, 3, 4], controlledBy: 0)
    qc.x(0)
    qc.increment(register: [1, 2, 3, 4], controlledBy: 0)
    qc.x(0)
}

// `QuantumCircuit` has no built-in "give me the matrix" accessor, so
// build S column by column: prepare each of the 32 basis states with
// `x`, run one step of the shift, and read off the resulting
// amplitudes as that column.
func buildShift() -> Matrix {
    var columns: [[Complex]] = []
    for j in 0..<dim {
        let qc = QuantumCircuit(qubits: 5)
        for bit in 0..<5 where j & (1 << (4 - bit)) != 0 {
            qc.x(bit)
        }
        appendShift(to: qc)
        columns.append(qc.run().amplitudes)
    }
    var data = Array(repeating: Array(repeating: Complex.zero, count: dim), count: dim)
    for j in 0..<dim {
        for row in 0..<dim { data[row][j] = columns[j][row] }
    }
    return Matrix(data)
}
let S = buildShift()

// Cross-check against the old hand-built permutation: every gate
// above only ever moves 0/1 amplitudes around, so this equality is
// exact — no floating-point tolerance needed.
func referenceShift() -> Matrix {
    Matrix.permutation(size: dim) { fromIndex in
        let coin = fromIndex / numSites
        let pos = fromIndex % numSites
        let newPos = coin == 0 ? (pos + 1) % numSites : (pos - 1 + numSites) % numSites
        return coin * numSites + newPos
    }
}
print("S matches the hand-built permutation: \(S == referenceShift())")
print("S is unitary: \(S.isUnitary())")
// Expected: both true — the increment/decrement construction agrees
// with the permutation exactly, and is itself a genuine permutation
// (unitary).

// ============================================================
// Section 2 — one step: coin flip, then conditional shift
// ============================================================

let H = HadamardGate.matrix
let I16 = Matrix.identity(size: numSites)
let U = S * H.tensor(I16)

func initialState(coin: Ket) -> Ket {
    var posAmp = Array(repeating: Complex.zero, count: numSites)
    posAmp[0] = .one
    return coin.tensor(StateVector(posAmp))
}
// The coin is qubit 0, the 4-bit position register qubits 1...4 — summing out the coin via
// `StateVector.marginalProbabilities(over:)` instead of a hand-rolled double loop over both
// coin values.
func positionDistribution(_ psi: Ket) -> [Double] {
    let marginal = psi.marginalProbabilities(over: [1, 2, 3, 4])
    return (0..<numSites).map { pos in
        marginal[String(pos, radix: 2).leftPadding(toLength: 4, withPad: "0")]!
    }
}

// ============================================================
// Section 3 — spread: ballistic (quantum) vs. diffusive (classical)
// ============================================================
// A cyclic-coordinate gotcha: computing variance from raw site
// *indices* is wrong once the distribution's support crosses the
// 0/15 wraparound boundary — index 15 is actually adjacent to index
// 0, but naive variance treats them as far apart. Fix: unwrap each
// index to a signed offset from the start site before computing
// variance (valid as long as the spread stays under half the cycle,
// true through t=7 here).

func signedOffset(_ pos: Int) -> Int { pos <= numSites / 2 ? pos : pos - numSites }
func stddevSigned(_ dist: [Double]) -> Double {
    var mean = 0.0
    for (pos, p) in dist.enumerated() { mean += Double(signedOffset(pos)) * p }
    var variance = 0.0
    for (pos, p) in dist.enumerated() { variance += p * pow(Double(signedOffset(pos)) - mean, 2) }
    return variance.squareRoot()
}

var psi = initialState(coin: StateVector.zero)
print("\nt   quantum σ   σ/t")
for t in 1...7 {
    psi.apply(U)
    let sd = stddevSigned(positionDistribution(psi))
    print("\(t)   \(fmt(sd))      \(fmt(sd / Double(t)))")
}
// Expected: σ grows roughly linearly in t (σ/t hovers ~0.5–1.0,
// oscillating at small t — a known finite-size/parity effect, not an
// error) — ballistic spreading.

var classicalDist = Array(repeating: 0.0, count: numSites)
classicalDist[0] = 1.0
func classicalStep(_ d: [Double]) -> [Double] {
    var out = Array(repeating: 0.0, count: numSites)
    for (pos, p) in d.enumerated() {
        out[(pos + 1) % numSites] += 0.5 * p
        out[(pos - 1 + numSites) % numSites] += 0.5 * p
    }
    return out
}
print("\nt   classical σ   σ/√t")
for t in 1...7 {
    classicalDist = classicalStep(classicalDist)
    let sd = stddevSigned(classicalDist)
    print("\(t)   \(fmt(sd))       \(fmt(sd / Double(t).squareRoot()))")
}
// Expected: σ/√t is pinned at exactly 1.0 at every single t — the
// textbook diffusive signature, in sharp contrast to the quantum
// walk's roughly-linear growth above.

// ============================================================
// Section 4 — the asymmetry is interference, not a bug
// ============================================================
// Starting from coin |0⟩ gives a visibly biased distribution.
// Starting from |+i⟩ (Core's existing basis ket) restores left-right
// symmetry exactly — confirming the bias comes from the coin's phase
// relationship to the shift, not from any asymmetry in the shift
// itself.

func finalDistribution(coin: Ket, steps: Int) -> [Double] {
    var s = initialState(coin: coin)
    for _ in 0..<steps { s.apply(U) }
    return positionDistribution(s)
}

let biased = finalDistribution(coin: StateVector.zero, steps: 7)
let symmetric = finalDistribution(coin: StateVector.plusI, steps: 7)

print("\nsite   P(biased, coin=|0⟩)   P(symmetric, coin=|+i⟩)")
for site in 0..<numSites where biased[site] > 1e-9 || symmetric[site] > 1e-9 {
    print("\(site)      \(fmt(biased[site]))                 \(fmt(symmetric[site]))")
}
// Expected: the |0⟩-coin column is visibly asymmetric (e.g. site 3 vs.
// its mirror site 13 differ by ~8×); the |+i⟩-coin column is
// symmetric to 4 decimals at every mirrored pair (1↔15, 3↔13, 5↔11,
// 7↔9).

// ============================================================
// Section 5 — cross-references
// ============================================================
// Grover's search (page 11) can be recast as a quantum walk on the
// search space. The *continuous-time* walk — no coin, no discrete
// steps — is exp(−iAt) for a graph's adjacency matrix A: exactly page
// 21's `expm`, applied to a graph instead of a spin Hamiltonian.

// ============================================================
// Section 6 — live view: the two final distributions
// ============================================================

let quantumPoints = (0..<numSites).map { CGPoint(x: Double(signedOffset($0)), y: biased[$0]) }
    .sorted { $0.x < $1.x }
let classicalPoints = classicalDist.enumerated().map { CGPoint(x: Double(signedOffset($0.offset)), y: $0.element) }
    .sorted { $0.x < $1.x }

//: ### Live view — position distribution at t=7: quantum vs. classical
//: The quantum walk (orange dots, coin=|0⟩) is two-peaked and spread
//: wider than the classical walk (blue dots), which stays a single
//: bell-shaped hump — ballistic vs. diffusive, seen directly.

let chart = CHSHChartView(
    title: "Quantum vs. classical walk, position distribution at t=7",
    xRange: -8.0...8.0,
    yRange: 0.0...0.35,
    series: [
        CHSHChartView.Series(label: "classical", color: .blue, points: classicalPoints, isLine: false),
        CHSHChartView.Series(label: "quantum (coin=|0⟩)", color: .orange, points: quantumPoints, isLine: false)
    ]
)

PlaygroundPage.current.setLiveView(
    chart.frame(width: 560, height: 420)
)

//: [Next](@next)
