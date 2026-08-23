//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// The 3-qubit bit-flip code — protecting one qubit from noise
// ============================================================
// A physical qubit is fragile: any stray rotation corrupts it, and
// you cannot "look" at it to check without destroying the very
// superposition you are trying to protect. The 3-qubit repetition
// code sidesteps both problems by spreading one logical qubit across
// three physical ones and reading out an *error syndrome* — two bits
// that reveal which qubit is wrong without ever revealing α or β.
//
// Register (qubit 0 is the most-significant/leftmost bit):
//
//   q0, q1, q2 — the encoded data (q0 also holds |ψ⟩ before encoding)
//   q3, q4     — syndrome ancillas
//
// `SwiftQiskitCore` has no Toffoli and no partial measurement, so the
// coherent correction — "look at the syndrome, then flip the accused
// qubit" — is built as a single 32×32 permutation matrix fed to
// `apply(_:)`, in the spirit of pages 11–12's hand-built gates.

func lbl(_ i: Int, _ n: Int) -> String {
    var s = String(i, radix: 2)
    while s.count < n { s = "0" + s }
    return s
}
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-9 }
        .map { "|\(lbl($0, qubits))⟩: \(state[$0])" }
        .joined(separator: "   ")
}

let theta = Double.pi / 3
let phi = Double.pi / 4

// ============================================================
// Section 1 — the code
// ============================================================
// `cx(0,1); cx(0,2)` copies q0's *basis label* — not its amplitudes
// — onto q1 and q2: α|0⟩+β|1⟩ becomes α|000⟩+β|111⟩. This is not
// cloning (page 13's theorem still holds): the two terms are
// entangled, and neither q1 nor q2 alone holds a copy of |ψ⟩.

let enc = QuantumCircuit(qubits: 5)
enc.ry(theta, 0)
enc.rz(phi, 0)
print("|ψ⟩ on q0:  \(pretty(enc.run(), qubits: 5))")
// Expected: |00000⟩: 0.8001 − 0.3314i   |10000⟩: 0.4619 + 0.1913i

enc.cx(0, 1)
enc.cx(0, 2)
print("encoded (α|000⟩+β|111⟩):  \(pretty(enc.run(), qubits: 5))")
// Expected: |00000⟩: 0.8001 − 0.3314i   |11100⟩: 0.4619 + 0.1913i —
// the same two amplitudes, now on |000⟩ and |111⟩.

// ============================================================
// Section 2 — syndrome extraction, without looking
// ============================================================
// `cx(0,3); cx(1,3)` puts the parity q0⊕q1 onto q3; `cx(1,4); cx(2,4)`
// puts q1⊕q2 onto q4. The ancillas learn *which* qubit disagrees with
// its neighbors — never α or β — which is exactly why this doesn't
// collapse the encoded superposition.

func syndromeCircuit(errors: [Int]) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 5)
    qc.ry(theta, 0)
    qc.rz(phi, 0)
    qc.cx(0, 1)
    qc.cx(0, 2)
    for q in errors { qc.x(q) }
    qc.cx(0, 3); qc.cx(1, 3)
    qc.cx(1, 4); qc.cx(2, 4)
    return qc
}

print("\nerror   syndrome (q3 q4)   P")
for (name, errs) in [("none", []), ("q0  ", [0]), ("q1  ", [1]), ("q2  ", [2])] {
    let state = syndromeCircuit(errors: errs).run()
    var maxIdx = 0, maxP = 0.0
    for i in 0..<32 where state.probabilities[i] > maxP {
        maxP = state.probabilities[i]; maxIdx = i
    }
    let bits = lbl(maxIdx, 5)
    print("\(name)     \(bits.suffix(2))              \(String(format: "%.4f", maxP))")
}
// Expected: none→00, q0→10, q1→11, q2→01 — every syndrome value
// distinct, so it uniquely names the flipped qubit (or "none").

// ============================================================
// Section 3 — coherent correction
// ============================================================
// One 32×32 basis-state permutation, built by index arithmetic: for
// each basis index, decode the syndrome bits (q3, q4) and flip the
// data qubit they accuse. This is three Toffoli-with-mixed-controls
// folded into a single matrix — exactly page 11/12's "hand-build the
// permutation, hand it to `apply(_:)`" idiom.

var correction = Matrix(rows: 32, cols: 32)
for i in 0..<32 {
    let bits = lbl(i, 5).map { Int(String($0))! }
    var c = bits
    switch (bits[3], bits[4]) {
    case (1, 0): c[0] = 1 - c[0]   // syndrome 10 accuses q0
    case (1, 1): c[1] = 1 - c[1]   // syndrome 11 accuses q1
    case (0, 1): c[2] = 1 - c[2]   // syndrome 01 accuses q2
    default: break                 // syndrome 00: nothing to fix
    }
    let j = c[0] * 16 + c[1] * 8 + c[2] * 4 + c[3] * 2 + c[4]
    correction[j, i] = Complex(1)
}

var isUnitary = true
let adj = correction.adjoint
outer: for i in 0..<32 {
    for j in 0..<32 {
        let expected = (i == j) ? Complex(1) : Complex.zero
        var v = Complex.zero
        for k in 0..<32 { v = v + adj[i, k] * correction[k, j] }
        if (v - expected).magnitude > 1e-9 { isUnitary = false; break outer }
    }
}
print("\ncorrection matrix is unitary: \(isUnitary)")
// Expected: true — it's a permutation, so it can't help but be unitary.

let psiOnly: StateVector = {
    let qc = QuantumCircuit(qubits: 1)
    qc.ry(theta, 0); qc.rz(phi, 0)
    return qc.run()
}()
let codeword = StateVector([psiOnly[0], .zero, .zero, .zero, .zero, .zero, .zero, psiOnly[1]])
let syndromeIndex: [String: Int] = ["none": 0, "q0  ": 2, "q1  ": 3, "q2  ": 1]

func withCorrection(errors: [Int]) -> QuantumCircuit {
    let qc = syndromeCircuit(errors: errors)
    qc.apply(correction)
    return qc
}

print("\nerror   fidelity to (α|000⟩+β|111⟩)⊗|syndrome⟩")
for (name, errs) in [("none", []), ("q0  ", [0]), ("q1  ", [1]), ("q2  ", [2])] {
    let state = withCorrection(errors: errs).run()
    var syndromeAmps = Array(repeating: Complex.zero, count: 4)
    syndromeAmps[syndromeIndex[name]!] = Complex(1)
    let expected = codeword ⊗ StateVector(syndromeAmps)
    var overlap = Complex.zero
    for i in 0..<32 { overlap = overlap + state[i].conjugate * expected[i] }
    print("\(name)     \(String(format: "%.4f", overlap.magnitudeSquared))")
}
// Expected: 1.0000 for all four — the correction exactly restores the
// codeword, whatever the syndrome, and the syndrome itself survives
// unerased on q3, q4.

// ============================================================
// Section 4 — decode and check
// ============================================================
// `cx(0,2); cx(0,1)` — the encoding run in reverse — collapses the
// three data qubits back onto q0 alone, provided the codeword is
// intact (which Section 3 just guaranteed).

func withDecode(errors: [Int]) -> QuantumCircuit {
    let qc = withCorrection(errors: errors)
    qc.cx(0, 2)
    qc.cx(0, 1)
    return qc
}

let zeroKet = StateVector([Complex(1), .zero])
print("\nerror   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩")
for (name, errs) in [("none", []), ("q0  ", [0]), ("q1  ", [1]), ("q2  ", [2])] {
    let state = withDecode(errors: errs).run()
    var syndromeAmps = Array(repeating: Complex.zero, count: 4)
    syndromeAmps[syndromeIndex[name]!] = Complex(1)
    let expected = psiOnly ⊗ zeroKet ⊗ zeroKet ⊗ StateVector(syndromeAmps)
    var overlap = Complex.zero
    for i in 0..<32 { overlap = overlap + state[i].conjugate * expected[i] }
    print("\(name)     \(String(format: "%.4f", overlap.magnitudeSquared))")
}
// Expected: 1.0000 for all four again — |ψ⟩ is back on q0 alone,
// undisturbed, no matter which single qubit the error hit.

// ============================================================
// Section 5 — errors are continuous, syndromes are discrete
// ============================================================
// Replace the X error with `rx(θ)` — a *partial* bit flip, i.e. a
// coherent superposition of "no error" and "X error" on q0. Since
// the correction is unitary (never measured), it corrects *both*
// branches at once: the data comes back exactly, for every θ, while
// the syndrome ancillas end up holding the superposition weights.
// This is the least intuitive fact about QEC — that a continuous
// error becomes a discrete correction — and it drops straight out of
// the simulator once you stop assuming the syndrome is measured.

print("\nθ       fidelity   P(syndrome none)  P(syndrome q0)")
for (name, t) in [("0    ", 0.0), ("π/6  ", Double.pi / 6), ("π/3  ", Double.pi / 3),
                   ("π/2  ", Double.pi / 2), ("π    ", Double.pi)] {
    let qc = QuantumCircuit(qubits: 5)
    qc.ry(theta, 0); qc.rz(phi, 0)
    qc.cx(0, 1); qc.cx(0, 2)
    qc.rx(t, 0)
    qc.cx(0, 3); qc.cx(1, 3)
    qc.cx(1, 4); qc.cx(2, 4)
    qc.apply(correction)
    qc.cx(0, 2); qc.cx(0, 1)
    let state = qc.run()

    let ancilla = StateVector([Complex(cos(t / 2)), .zero, Complex(0, -sin(t / 2)), .zero])
    let expected = psiOnly ⊗ zeroKet ⊗ zeroKet ⊗ ancilla
    var overlap = Complex.zero
    for i in 0..<32 { overlap = overlap + state[i].conjugate * expected[i] }

    var pNone = 0.0, pQ0 = 0.0
    for i in 0..<32 {
        let suffix = lbl(i, 5).suffix(2)
        if suffix == "00" { pNone += state.probabilities[i] }
        if suffix == "10" { pQ0 += state.probabilities[i] }
    }
    print("\(name)   \(String(format: "%.4f", overlap.magnitudeSquared))     \(String(format: "%.4f", pNone))            \(String(format: "%.4f", pQ0))")
}
// Expected: fidelity 1.0000 at *every* θ, while P(syndrome) tracks
// cos²(θ/2)/sin²(θ/2) exactly — 1.0000/0, 0.9330/0.0670, 0.7500/0.2500,
// 0.5000/0.5000, 0/1.0000. The correction doesn't care how much error
// there was; it undoes all of it, every time — as long as it's never
// measured (Section 6 shows what happens when correction is forced
// to guess wrong).

// ============================================================
// Section 6 — the limits of distance 3
// ============================================================
// Two simultaneous errors fool the code: X on q0 *and* q1 gives
// syndrome 01 — the same syndrome as a lone error on q2 — so the
// correction "fixes" q2, which was never wrong. Net effect: all three
// data qubits end up flipped, a full **logical X** on the encoded
// qubit. With |ψ⟩ = |1⟩ the failure is unmistakable: it decodes to |0⟩.

let oneCircuit: (Int...) -> QuantumCircuit = { errs in
    let qc = QuantumCircuit(qubits: 5)
    qc.x(0)                      // |ψ⟩ = |1⟩, a stark test case
    qc.cx(0, 1); qc.cx(0, 2)
    for q in errs { qc.x(q) }
    qc.cx(0, 3); qc.cx(1, 3)
    qc.cx(1, 4); qc.cx(2, 4)
    qc.apply(correction)
    qc.cx(0, 2); qc.cx(0, 1)
    return qc
}
let twoErrorState = oneCircuit(0, 1).run()
var p0 = 0.0, p1 = 0.0
for i in 0..<32 {
    if (i >> 4) & 1 == 0 { p0 += twoErrorState.probabilities[i] } else { p1 += twoErrorState.probabilities[i] }
}
print("\n|ψ⟩ = |1⟩, errors on q0 AND q1 (syndrome wrongly accuses q2):")
print("decoded P(0) = \(String(format: "%.4f", p0))   P(1) = \(String(format: "%.4f", p1))")
// Expected: P(0) = 1.0000 — the code confidently returns the *wrong*
// answer. A miscorrection is worse than no correction: it's silent.

// The exact logical error rate: enumerate all 8 independent
// single-qubit-flip patterns (each qubit flips with probability p),
// weight by the pattern's probability, and sum the ones the
// syndrome-driven correction gets wrong.
func minorityCorrectionFails(_ flippedQubits: [Int]) -> Bool {
    var flips = [0, 0, 0]
    for q in flippedQubits { flips[q] = 1 }
    var corrected = flips
    switch (flips[0] ^ flips[1], flips[1] ^ flips[2]) {
    case (1, 0): corrected[0] ^= 1
    case (1, 1): corrected[1] ^= 1
    case (0, 1): corrected[2] ^= 1
    default: break
    }
    return corrected != [0, 0, 0]
}

func logicalErrorRate(_ p: Double) -> Double {
    var total = 0.0
    for mask in 0..<8 {
        let pattern = (0..<3).filter { (mask >> $0) & 1 == 1 }
        let k = pattern.count
        if minorityCorrectionFails(pattern) {
            total += pow(p, Double(k)) * pow(1 - p, Double(3 - k))
        }
    }
    return total
}

print("\np       p_L (encoded)   p (unencoded)   formula 3p²−2p³")
for p in [0.05, 0.1, 0.2, 0.3, 0.5] {
    let formula = 3 * p * p - 2 * p * p * p
    print("\(String(format: "%.2f", p))    \(String(format: "%.4f", logicalErrorRate(p)))          \(String(format: "%.4f", p))          \(String(format: "%.4f", formula))")
}
// Expected: p_L = 3p² − 2p³ exactly (the code fails only on 2- or
// 3-qubit patterns). At p = 0.1: 0.0280 vs 0.1000 unencoded — 3.6×
// better. Break-even is p = ½: below that the code helps, above it
// it actively hurts (more ways to accumulate 2 wrongs than to have 0).

// ============================================================
// Section 7 — phase flips, by conjugation
// ============================================================
// The same code protects against Z errors too, if you look at it in
// the X basis: `h` the three data qubits, suffer a Z error, `h` them
// back. H Z H = X, so a Z error becomes exactly the X error Sections
// 1–6 already know how to fix — page 08's basis-change lesson doing
// real work.

func phaseFlipCircuit(errors: [Int]) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 5)
    qc.ry(theta, 0); qc.rz(phi, 0)
    qc.cx(0, 1); qc.cx(0, 2)
    qc.h(0); qc.h(1); qc.h(2)
    for q in errors { qc.z(q) }
    qc.h(0); qc.h(1); qc.h(2)
    qc.cx(0, 3); qc.cx(1, 3)
    qc.cx(1, 4); qc.cx(2, 4)
    qc.apply(correction)
    qc.cx(0, 2); qc.cx(0, 1)
    return qc
}

print("\nphase-flip error   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩")
for (name, errs) in [("none", []), ("q0  ", [0]), ("q1  ", [1]), ("q2  ", [2])] {
    let state = phaseFlipCircuit(errors: errs).run()
    var syndromeAmps = Array(repeating: Complex.zero, count: 4)
    syndromeAmps[syndromeIndex[name]!] = Complex(1)
    let expected = psiOnly ⊗ zeroKet ⊗ zeroKet ⊗ StateVector(syndromeAmps)
    var overlap = Complex.zero
    for i in 0..<32 { overlap = overlap + state[i].conjugate * expected[i] }
    print("\(name)     \(String(format: "%.4f", overlap.magnitudeSquared))")
}
// Expected: 1.0000 for all four, same syndrome table as Section 2 —
// literally the same correction matrix, applied on the other side of
// three Hadamards.

// ============================================================
// Section 8 — what's next
// ============================================================
// A code that fixes *either* kind of error needs both ideas at once:
// Shor's original 9-qubit code concatenates this bit-flip code
// inside a phase-flip code (3 blocks of 3). It is deliberately not
// built here: `QuantumCircuit` records every operation as a full
// 2ⁿ×2ⁿ matrix (`Circuit/QuantumCircuit.swift`), and a 9-data-qubit
// version of this page's circuit (plus ancillas) would sit at
// dimension 2¹³ or higher — tens of operations at 100+ MB each, with
// slow Kronecker builds along the way. Noise models belong on the
// roadmap in `STATUSandTODO.md`, not bolted onto v0.1's dense-matrix
// circuit representation.

//: ### Live view — the payload's Bloch point, correction vs. none
//: |ψ⟩ as prepared, what q0 looks like after decoding a single X
//: error *without* running the correction first (a clean X|ψ⟩ — the
//: decode still separates cleanly, it just returns the wrong answer),
//: and the fully corrected state.

struct ErrorCorrectionGalleryView: View {
    let stages: [(name: String, bloch: BlochVector)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("3-qubit bit-flip code: q0's Bloch point").font(.title3.bold())
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(240)), count: 3), spacing: 16) {
                ForEach(stages, id: \.name) { stage in
                    BlochSphereView(label: stage.name, bloch: stage.bloch)
                }
            }
        }
        .padding()
    }
}

func decodeWithoutCorrection(errors: [Int]) -> StateVector {
    let qc = syndromeCircuit(errors: errors)   // no `apply(correction)`
    qc.cx(0, 2)
    qc.cx(0, 1)
    return qc.run()
}
let noCorrectionState = decodeWithoutCorrection(errors: [0])
// Undoing the encoding without fixing the error first leaves q1, q2
// flipped to |1⟩ too (only q0 ends up clean) — slice at that fixed
// index: |q0 1 1 1 0⟩ is index q0·16 + 8 + 4 + 2 = q0·16 + 14.
let noCorrectionQ0 = StateVector([noCorrectionState[14], noCorrectionState[30]])
let decodedState = withDecode(errors: [0]).run()
let correctedQ0 = StateVector([decodedState[0], decodedState[1]])

PlaygroundPage.current.setLiveView(
    ErrorCorrectionGalleryView(stages: [
        ("|ψ⟩ as prepared", BlochVector(psiOnly)),
        ("q0, X error, no correction", BlochVector(noCorrectionQ0)),
        ("q0, X error, corrected", BlochVector(correctedQ0))
    ])
    .frame(width: 820, height: 360)
)

//: [Next](@next)
