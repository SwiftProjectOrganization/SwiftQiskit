//: [Previous](@previous)

import Foundation
import SwiftQiskitCore

// ============================================================
// Shor's algorithm — factoring 15 by finding a period
// ============================================================
// The problem: given a composite N, find a nontrivial factor.
// Every known classical algorithm takes super-polynomial time —
// the presumed hardness of factoring is what RSA encryption rests
// on. Shor's algorithm (1994) factors in polynomial time on a
// quantum computer.
//
// The quantum part solves a different-looking problem. Pick a
// base a coprime to N and find its *order*: the smallest r > 0
// with
//
//   a^r ≡ 1 (mod N)
//
// Section 1 shows the classical reduction from factoring to order
// finding. The order is found by phase estimation on the modular
// multiplication operator
//
//   U_a |w⟩ = |a·w mod N⟩
//
// whose eigenvalues e^(2πi·s/r), s = 0 … r−1, encode r. Two
// registers (qubit 0 is the most-significant bit, as always):
//
//   qubits 0–2   counting register — 3 qubits, reads out the phase
//   qubits 3–6   work register     — 4 qubits, holds w mod 15
//
// and five steps:
//
//   1. h(0); h(1); h(2)         uniform superposition of counts c
//   2. x(6)                     work register ← |1⟩ (the value 1)
//   3. controlled-U_a powers    work register ← |a^c mod 15⟩
//   4. QFT† on qubits 0–2       turn the period into a phase peak
//   5. measure qubits 0–2       y ≈ 8·s/r for a random s
//
// This is a *compiled* Shor: N = 15 is baked in, and the
// controlled multiplications are hand-built permutation matrices
// fed to apply(_:) — page 11's CCZ trick, scaled up. One genuine
// luxury: every order mod 15 divides 4, hence divides 2³, so
// three counting qubits give perfectly sharp peaks, and reducing
// y/8 to lowest terms replaces the continued-fraction step that a
// full-size Shor (with ~2n counting qubits) needs.

// ============================================================
// Section 1 — Factoring reduces to order finding
// ============================================================
// Two classical helpers do all the number theory on this page.

func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

/// base^exponent mod modulus, by square-and-multiply.
func modPow(_ base: Int, _ exponent: Int, _ modulus: Int) -> Int {
    var result = 1
    var square = base % modulus
    var e = exponent
    while e > 0 {
        if e & 1 == 1 { result = result * square % modulus }
        square = square * square % modulus
        e >>= 1
    }
    return result
}

// The reduction: suppose r = ord_N(a) is even and a^(r/2) ≢ −1
// (mod N). Then (a^(r/2) − 1)(a^(r/2) + 1) = a^r − 1 ≡ 0 (mod N)
// while neither factor is itself ≡ 0 — so each shares a
// nontrivial divisor with N, and gcd extracts it.
//
// And if the guess a is not even coprime to N, no quantum
// computer is needed: gcd(a, N) is already a factor.

print(" a   gcd(a,15)")
for a in 2...14 {
    let g = gcd(a, 15)
    let note = g > 1 ? "lucky guess — \(g) is already a factor" : "coprime — needs the order r"
    print(String(format: "%2d       %2d      ", a, g) + note)
}
// Expected: six lucky guesses (a = 3, 5, 6, 9, 10, 12) where gcd
// alone factors 15; the other seven (2, 4, 7, 8, 11, 13, 14) are
// coprime and genuinely need order finding.

// ============================================================
// Section 2 — The classical answer key: powers of 7 mod 15
// ============================================================
// Take a = 7. Computing the powers directly shows the period the
// quantum circuit is about to find — a cheat sheet to check the
// hardware against.

var powers: [Int] = []
for k in 0..<8 { powers.append(modPow(7, k, 15)) }
print("\n7^k mod 15, k = 0…7:  \(powers.map(String.init).joined(separator: " "))")
// Expected: 1 7 4 13 1 7 4 13 — the sequence repeats with period
// r = 4: ord₁₅(7) = 4.

let answerHalf = modPow(7, 2, 15)
print("7^(r/2) = 7² ≡ \(answerHalf):  gcd(\(answerHalf - 1), 15) = \(gcd(answerHalf - 1, 15)),  gcd(\(answerHalf + 1), 15) = \(gcd(answerHalf + 1, 15))")
// Expected: 7² ≡ 4, gcd(3, 15) = 3 and gcd(5, 15) = 5 — Section
// 1's reduction delivers 15 = 3 × 5. Everything from here on is
// about finding r = 4 *without* the cheat sheet.

// ============================================================
// Section 3 — Modular multiplication as a permutation matrix
// ============================================================
// For a coprime to 15, w ↦ a·w mod 15 permutes {0, …, 14} — it is
// reversible, hence unitary, with exactly one 1 per column. The
// 4-qubit work register has 16 basis states; the unused |15⟩ is
// left as a fixed point.

/// U_a on the 4-qubit work register: |w⟩ ↦ |a·w mod 15⟩ for
/// w < 15, |15⟩ fixed. A 16×16 permutation — one `.one` per column.
func modMultiplyGate(_ a: Int) -> Matrix {
    var m = Matrix(rows: 16, cols: 16)
    for w in 0..<15 {
        m[(a * w) % 15, w] = .one
    }
    m[15, 15] = .one
    return m
}

/// Round an amplitude for display: 4 decimals, dropping components
/// below 1e-9 (the QFT†'s cos/sin leave ~1e-16 residues that would
/// otherwise swamp the output).
func fmt(_ value: Complex) -> String {
    func rounded(_ x: Double) -> Double {
        abs(x) < 1e-9 ? 0 : (x * 10_000).rounded() / 10_000
    }
    return Complex(rounded(value.real), rounded(value.imag)).description
}

/// Format a state as zero-padded basis kets with amplitudes,
/// skipping (numerically) zero terms.
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { index -> String in
            var label = String(index, radix: 2)
            while label.count < qubits { label = "0" + label }
            return "|\(label)⟩: \(fmt(state[index]))"
        }
        .joined(separator: "   ")
}

let u7 = modMultiplyGate(7)
print("\nU₇ exactly unitary: \(u7† * u7 == Matrix.identity(size: 16))")
// Expected: true — and *exactly* true: a permutation matrix holds
// only 0s and 1s, so Matrix's == has no rounding to forgive.

// Walking U₇ from |1⟩ traces the orbit 1 → 7 → 4 → 13 → 1. The
// orbit closes after exactly r steps — the order is a geometric
// fact about U₇ before it is a spectral one.

let orbit = QuantumCircuit(qubits: 4)
orbit.x(3)                          // |0001⟩ — the value 1
print("start:  \(pretty(orbit.run(), qubits: 4))")
for step in 1...4 {
    orbit.apply(u7)
    print("U₇^\(step):   \(pretty(orbit.run(), qubits: 4))")
}
// Expected: |0001⟩ → |0111⟩ → |0100⟩ → |1101⟩ → back to |0001⟩
// (1 → 7 → 4 → 13 → 1): the orbit length is the order r = 4.

// ============================================================
// Section 4 — The inverse quantum Fourier transform
// ============================================================
// Phase estimation ends by undoing a Fourier transform on the
// counting register. The textbook QFT is a *gate decomposition* —
// Hadamards and controlled phase rotations, then a bit reversal —
// and those phase gates aren't in the library. But the matrix
// itself is just the inverse discrete Fourier transform,
//
//   QFT†[y, c] = e^(−2πi·y·c/8) / √8
//
// built entrywise on the register's integer index. Working with
// the whole matrix sidesteps the decomposition's bit-reversal
// bookkeeping entirely: qubit 0 is the MSB and Matrix.tensor puts
// its left factor in the high bits, so the counting register's
// index within its 8-dimensional block *is* the integer c.

/// The inverse QFT on `size` basis states, built entrywise.
func inverseQFT(size: Int) -> Matrix {
    var m = Matrix(rows: size, cols: size)
    let scale = 1.0 / sqrt(Double(size))
    for y in 0..<size {
        for c in 0..<size {
            let theta = -2.0 * Double.pi * Double(y * c) / Double(size)
            m[y, c] = Complex(cos(theta), sin(theta)) * scale
        }
    }
    return m
}

// Three sanity checks. Unlike Section 3's permutation, cos/sin
// leave ~1e-16 residues, so compare with a tolerance instead of ==.

let dft2 = inverseQFT(size: 2)
var hadamardDeviation = 0.0
for i in 0..<2 {
    for j in 0..<2 {
        hadamardDeviation = max(hadamardDeviation, (dft2[i, j] - HadamardGate.matrix[i, j]).magnitude)
    }
}
print("\n1 qubit:  max |QFT† − H| entry = \(hadamardDeviation)")
// Expected: ~1e-16 — on one qubit the (inverse) QFT *is* the
// Hadamard, which is its own inverse.

let qft3Dagger = inverseQFT(size: 8)
let shouldBeIdentity = qft3Dagger† * qft3Dagger
var unitarityDeviation = 0.0
for i in 0..<8 {
    for j in 0..<8 {
        let target = i == j ? Complex.one : Complex.zero
        unitarityDeviation = max(unitarityDeviation, (shouldBeIdentity[i, j] - target).magnitude)
    }
}
print("3 qubits: max |QFT·QFT† − I| entry = \(unitarityDeviation)")
// Expected: ~1e-15 — unitary to machine precision.

let uniformTest = QuantumCircuit(qubits: 3)
uniformTest.h(0); uniformTest.h(1); uniformTest.h(2)
uniformTest.apply(qft3Dagger)
print("QFT† of uniform |s⟩: \(pretty(uniformTest.run(), qubits: 3))")
// Expected: |000⟩: 1.0 — the uniform superposition is the Fourier
// transform of |0⟩, so QFT† maps it straight back. This is the
// y = 8·s/r peak for the trivial phase s = 0.

// ============================================================
// Section 5 — The full circuit for a = 7, stage by stage
// ============================================================
// Phase estimation wants counting qubit k to control U₇ raised to
// that qubit's *bit weight* in the count. With qubit 0 as MSB the
// weights run 4, 2, 1, so qubit k controls U₇^(2^(2−k)). Each
// controlled power is one 128×128 permutation: where the control
// bit is set, permute the work value; elsewhere, leave the basis
// state alone.

/// Controlled modular multiplication on the full 7-qubit register:
/// |c⟩|w⟩ ↦ |c⟩|multiplier·w mod 15⟩ when counting bit
/// `controlQubit` of c is 1 (and w < 15), identity otherwise.
/// State index = count·16 + work.
func controlledModMultiply(controlQubit: Int, multiplier: Int) -> Matrix {
    var m = Matrix(rows: 128, cols: 128)
    for index in 0..<128 {
        let count = index >> 4
        let work = index & 15
        var newWork = work
        if (count >> (2 - controlQubit)) & 1 == 1 && work < 15 {
            newWork = (multiplier * work) % 15
        }
        m[(count << 4) | newWork, index] = .one
    }
    return m
}

print("\ncounting qubit k → controlled power of 7:")
for k in 0..<3 {
    let power = 1 << (2 - k)
    print("  qubit \(k) (bit weight \(power)):  U₇^\(power) = ×\(modPow(7, power, 15)) mod 15")
}
// Expected: qubit 0 → ×1, qubit 1 → ×4, qubit 2 → ×7. The top
// qubit's operation is the *identity*: 7⁴ ≡ 1 because r = 4
// divides its bit weight. That degeneracy is exactly why the
// final distribution below repeats with period 8/r = 2.

// Grow the circuit and peek after each stage — run() replays the
// recorded operations on a fresh |0…0⟩. At dimension 128 every
// operation is a dense 128×128 matrix, but one run() is still
// only ~40 ms.

let shor7 = QuantumCircuit(qubits: 7)
for q in 0..<3 { shor7.h(q) }
shor7.x(6)
print("\nstage 1 — superposed counts, work register = 1:")
print("  \(pretty(shor7.run(), qubits: 7))")
// Expected: eight states |ccc 0001⟩ at 0.3536 = 1/√8 — every
// count c from 000 to 111, work register frozen at the value 1.

for k in 0..<3 {
    shor7.apply(controlledModMultiply(controlQubit: k, multiplier: modPow(7, 1 << (2 - k), 15)))
}
print("\nstage 2 — work register = 7^c mod 15, entangled with c:")
print("  \(pretty(shor7.run(), qubits: 7))")
// Expected: |0000001⟩ |0010111⟩ |0100100⟩ |0111101⟩ |1000001⟩
// |1010111⟩ |1100100⟩ |1111101⟩, all at 0.3536 — the work value
// cycles 1, 7, 4, 13 as c counts up, repeating with period r = 4.
// The period is now written across the state, but measuring here
// would just return one random (c, 7^c) pair.

shor7.apply(qft3Dagger ⊗ Matrix.identity(size: 16))
let final7 = shor7.run()
let finalProbabilities = final7.probabilities

print("\nstage 3 — after QFT†, grouped by counting value y:")
for y in 0..<8 {
    let terms = (0..<16)
        .filter { final7[(y << 4) | $0].magnitude > 1e-10 }
        .map { w in "work \(w): \(fmt(final7[(y << 4) | w]))" }
    if !terms.isEmpty {
        print("  y = \(y):  \(terms.joined(separator: "   "))")
    }
}
// Expected — only even y survive, each with the four work values
// 1, 4, 7, 13 at magnitude 0.25 and y-dependent phases:
//   y = 0:  0.25    0.25    0.25     0.25
//   y = 2:  0.25   -0.25   -0.25i    0.25i
//   y = 4:  0.25    0.25   -0.25    -0.25
//   y = 6:  0.25   -0.25    0.25i   -0.25i
// The QFT† has interfered the period-4 pattern into sharp peaks
// at y = 8·s/r = 2s.

// The work register is never read — Shor only needs the counting
// register's *marginal* distribution. (The library has no partial
// measurement, so sum the probabilities over the work values.)

var marginals = [Double](repeating: 0, count: 8)
for index in 0..<128 { marginals[index >> 4] += finalProbabilities[index] }
print("\ny    P(y)")
for y in 0..<8 {
    print("\(y)    \(String(format: "%.4f", marginals[y]))")
}
// Expected: exactly 0.2500 at y = 0, 2, 4, 6 and 0.0000 at odd
// y — one sharp peak per eigenphase s/4, s = 0…3. The work
// register's |1⟩ is an equal superposition of U₇'s eigenvectors,
// so phase estimation picks one of the four phases at random.

// ============================================================
// Section 6 — 1000 shots
// ============================================================
// One caveat before sampling: measure(shots:) replays every
// recorded operation for every shot. Page 11's dimension-8
// circuit didn't care; here each replay costs ~40 ms, so 1000
// shots would take most of a minute. Every shot re-prepares the
// same pure state and measures all qubits, so sampling the
// probabilities of a single run() is statistically identical —
// and instant.

/// Draw `shots` samples from a probability distribution.
func sample(_ probabilities: [Double], shots: Int) -> [Int: Int] {
    var counts: [Int: Int] = [:]
    for _ in 0..<shots {
        var u = Double.random(in: 0..<1)
        var outcome = probabilities.count - 1
        for (index, p) in probabilities.enumerated() {
            u -= p
            if u < 0 { outcome = index; break }
        }
        counts[outcome, default: 0] += 1
    }
    return counts
}

var histogram = [Int: Int]()
for (index, count) in sample(finalProbabilities, shots: 1000) {
    histogram[index >> 4, default: 0] += count
}
print("\n1000 shots of the counting register:")
for y in 0..<8 {
    guard let count = histogram[y] else { continue }
    var label = String(y, radix: 2)
    while label.count < 3 { label = "0" + label }
    print("  \(label): \(count)")
}
// Expected: four bins near 250 at 000, 010, 100, 110 (statistical
// — ±40 is normal); the odd counting values never appear.

// ============================================================
// Section 7 — Classical post-processing: from y to the factors
// ============================================================
// A measured y estimates the phase y/8 ≈ s/r for a uniformly
// random s ∈ {0, …, r−1}. Because r divides 8 here, y/8 *equals*
// s/r, and reducing to lowest terms reveals a candidate r — which
// must still be *verified*, since s can share a factor with r.

print("\ny   phase   lowest terms   candidate r   7^r mod 15   verdict")
for y in [0, 2, 4, 6] {
    let g = gcd(y, 8)
    let s = y / g
    let candidate = 8 / g
    let check = modPow(7, candidate, 15)
    let verdict = check == 1 ? "✓ order found" : "✗ retry"
    print("\(y)   \(y)/8     \(s)/\(candidate)            \(candidate)             \(check)            \(verdict)")
}
// Expected: y = 2 and y = 6 both yield r = 4 ✓. y = 0 reduces to
// 0/1 — s = 0 says nothing, retry. y = 4 reduces to 1/2, so the
// candidate is r = 2, but 7² ≡ 4 ≠ 1: s = 2 shared a factor with
// r = 4. Half of all shots find the order outright; a real run
// just measures again. (The lcm of two failed candidates works
// too.)

let foundOrder = 4
let half = modPow(7, foundOrder / 2, 15)
let factor1 = gcd(half - 1, 15)
let factor2 = gcd(half + 1, 15)
print("\nr = \(foundOrder):  7^(r/2) ≡ \(half),  gcd(\(half - 1), 15) = \(factor1),  gcd(\(half + 1), 15) = \(factor2)")
print("15 = \(factor1) × \(factor2)  ✓")
// Expected: 15 = 3 × 5 — the quantum computer has factored 15.

// ============================================================
// Section 8 — Every base: sweep the coprime guesses
// ============================================================
// Nothing above was special to a = 7. One function builds the
// order-finding circuit for any coprime base — the powers
// a^(2^(2−k)) mod 15 come from modPow — and a second applies
// Section 1's reduction. Seven runs at dimension 128 take well
// under a second.

/// The full 7-qubit order-finding circuit for base `a`.
func shorCircuit(a: Int) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 7)
    for q in 0..<3 { qc.h(q) }
    qc.x(6)
    for k in 0..<3 {
        qc.apply(controlledModMultiply(controlQubit: k, multiplier: modPow(a, 1 << (2 - k), 15)))
    }
    qc.apply(qft3Dagger ⊗ Matrix.identity(size: 16))
    return qc
}

/// Read ord₁₅(a) off the counting marginals: the smallest
/// *verified* candidate among the peaked y values.
func shorOrder(a: Int) -> Int? {
    let probabilities = shorCircuit(a: a).run().probabilities
    var counting = [Double](repeating: 0, count: 8)
    for index in 0..<128 { counting[index >> 4] += probabilities[index] }
    var best: Int?
    for y in 1..<8 where counting[y] > 1e-9 {
        let candidate = 8 / gcd(y, 8)
        if modPow(a, candidate, 15) == 1 {
            best = best.map { min($0, candidate) } ?? candidate
        }
    }
    return best
}

/// Section 1's reduction: factors of 15 from an even order —
/// unless a^(r/2) ≡ −1, the unlucky branch.
func shorFactors(a: Int, order: Int) -> (Int, Int)? {
    guard order % 2 == 0 else { return nil }
    let h = modPow(a, order / 2, 15)
    guard (h + 1) % 15 != 0 else { return nil }
    return (gcd(h - 1, 15), gcd(h + 1, 15))
}

print("\n a    r    a^(r/2)   result")
for a in [2, 4, 7, 8, 11, 13, 14] {
    guard let order = shorOrder(a: a) else {
        print(String(format: "%2d    ?", a))
        continue
    }
    let h = modPow(a, order / 2, 15)
    if let (f1, f2) = shorFactors(a: a, order: order) {
        print(String(format: "%2d    %d    %2d        15 = %d × %d", a, order, h, f1, f2))
    } else {
        print(String(format: "%2d    %d    %2d        ✗ a^(r/2) ≡ −1 — trivial factors, pick another a", a, order, h))
    }
}
// Expected:
//    2    4     4        15 = 3 × 5
//    4    2     4        15 = 3 × 5
//    7    4     4        15 = 3 × 5
//    8    4     4        15 = 3 × 5
//   11    2    11        15 = 5 × 3
//   13    4     4        15 = 3 × 5
//   14    2    14        ✗ a^(r/2) ≡ −1 — trivial factors, pick another a
// Six of the seven coprime bases factor 15; only a = 14 ≡ −1 hits
// the unlucky branch, where gcd(15, 15) and gcd(13, 15) are
// trivial. The r = 2 bases peak only at y ∈ {0, 4}, P = 1/2 each
// — fewer peaks, same story. Real Shor guesses a at random, so a
// retry or two settles it: 15 = 3 × 5, in polynomial time.

//: [Next](@next)
