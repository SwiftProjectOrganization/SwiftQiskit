//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// The CHSH inequality — quantum correlations beat classical ones
// ============================================================
// Pages 10–14 showed quantum computers *doing* things faster or more
// reliably than a classical machine. This page asks a different
// question: are the *correlations* a Bell pair produces even
// possible for two classical particles carrying pre-agreed
// instructions (a "local hidden variable")? Bell's theorem says no,
// and the CHSH inequality (Clauser–Horne–Shimony–Holt, 1969) makes it
// a single number you can compute from measured statistics:
//
//   S = E(a,b) − E(a,b′) + E(a′,b) + E(a′,b′)
//
// where a, a′ are Alice's two measurement choices, b, b′ are Bob's,
// and E(x,y) is the correlation between their ±1 outcomes. Any
// theory where Alice and Bob's outcomes are determined by their own
// setting plus a shared-in-advance variable λ obeys |S| ≤ 2. A Bell
// pair, measured the right way, gives S = 2√2 ≈ 2.8284 — no shared
// instruction list can produce that.

func fmt(_ d: Double) -> String { String(format: "%.4f", d) }

// ============================================================
// Section 1 — the classical bound, in plain Swift
// ============================================================
// A deterministic local-hidden-variable strategy is just four fixed
// answers — what Alice outputs for each of her two settings, and
// what Bob outputs for each of his — each ±1, chosen in advance and
// independent of what the *other* side measures (that's "local").
// There are 2⁴ = 16 such strategies; enumerate every one.

var strategies: [(a: Int, ap: Int, b: Int, bp: Int)] = []
for a in [-1, 1] {
    for ap in [-1, 1] {
        for b in [-1, 1] {
            for bp in [-1, 1] {
                strategies.append((a, ap, b, bp))
            }
        }
    }
}

var maxClassicalS = 0
for s in strategies {
    let S = s.a * s.b - s.a * s.bp + s.ap * s.b + s.ap * s.bp
    maxClassicalS = max(maxClassicalS, abs(S))
}
print("deterministic strategies checked: \(strategies.count)")
print("max |S| over all of them: \(maxClassicalS)")
// Expected: 16 strategies, max |S| = 2 — no fixed instruction list
// ever beats 2, and this is exhaustive, not a sample.

// A *randomized* λ can only average over these fixed strategies, so
// it cannot escape the bound either — but it's worth checking with an
// actual model. Here λ is a shared random direction, and each side's
// deterministic response is "which side of my axis does λ fall on":
//
//   A(a, λ) = sign(cos(a − λ)),   B(b, λ) = sign(cos(b − λ))
//
// This is the naive "classical polarizer" model — and it turns out to
// saturate the bound exactly, which is why Section 6 reuses it as the
// classical comparison curve.

func lhvSign(_ setting: Double, _ lambda: Double) -> Double {
    cos(setting - lambda) >= 0 ? 1.0 : -1.0
}

func lhvCorrelator(_ a: Double, _ b: Double, trials: Int) -> Double {
    var sum = 0.0
    for _ in 0..<trials {
        let lambda = Double.random(in: 0..<(2 * Double.pi))
        sum += lhvSign(a, lambda) * lhvSign(b, lambda)
    }
    return sum / Double(trials)
}

let a = 0.0, ap = Double.pi / 2, b = Double.pi / 4, bp = 3 * Double.pi / 4
let lhvS = lhvCorrelator(a, b, trials: 200_000) - lhvCorrelator(a, bp, trials: 200_000)
    + lhvCorrelator(ap, b, trials: 200_000) + lhvCorrelator(ap, bp, trials: 200_000)
print("\nshared-direction model, 200,000 trials per correlator: S ≈ \(fmt(lhvS))")
// Expected: ≈ 2.0 (statistical, ±~0.01) — this particular classical
// model saturates the bound rather than merely satisfying it.

// ============================================================
// Section 2 — measuring along a tilted axis
// ============================================================
// A(θ) = cos θ·Z + sin θ·X is the observable "spin along the axis
// tilted θ from Z toward X" — built entrywise, since `Matrix` has no
// `+` or scalar multiply (page 12's QFT† idiom). Measuring A(θ) is
// `ry(−θ)` followed by an ordinary computational-basis measurement;
// the sign is pinned numerically against the exact expectation value
// before any CHSH number is trusted.

func A(_ theta: Double) -> Matrix {
    Matrix([
        [Complex(cos(theta), 0), Complex(sin(theta), 0)],
        [Complex(sin(theta), 0), Complex(-cos(theta), 0)]
    ])
}

let testQubit = QuantumCircuit(qubits: 1)
testQubit.ry(Double.pi / 3, 0)
testQubit.rz(Double.pi / 4, 0)
let testPsi = testQubit.run()

print("\nangle    exact ⟨A(θ)⟩   via ry(−θ)+Z")
for angle in [0.0, Double.pi / 6, Double.pi / 4, Double.pi / 2] {
    let matrix = A(angle)
    var exact = Complex.zero
    for i in 0...1 { for j in 0...1 { exact = exact + testPsi[i].conjugate * matrix[i, j] * testPsi[j] } }

    var rotated = testPsi
    rotated.apply(RYGate.matrix(theta: -angle))
    let viaMeasurement = rotated.probabilities[0] - rotated.probabilities[1]

    print("\(fmt(angle))   \(fmt(exact.real))         \(fmt(viaMeasurement))")
}
// Expected: the two columns agree at every angle. angle=0 gives
// 0.5000 — page 04/08's ⟨Z⟩ for this same qubit; angle=π/2 gives
// 0.6124 — their ⟨X⟩. A(θ) really does interpolate between Z and X.

// ============================================================
// Section 3 — correlators two ways
// ============================================================
// On a Bell pair, E(a,b) = ⟨ψ|A(a)⊗A(b)|ψ⟩ computed exactly with the
// Dirac/Core `⊗`, and independently as a shot-sampled average of
// ±1 = "same"/"different" outcomes after `ry(-a,0); ry(-b,1)`.

let bell = QuantumCircuit(qubits: 2)
bell.h(0)
bell.cx(0, 1)
let bellState = bell.run()

func exactCorrelator(_ x: Double, _ y: Double) -> Double {
    let observable = A(x) ⊗ A(y)
    var v = Complex.zero
    for i in 0..<4 { for j in 0..<4 { v = v + bellState[i].conjugate * observable[i, j] * bellState[j] } }
    return v.real
}

func sampledCorrelator(_ x: Double, _ y: Double, shots: Int) -> Double {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0)
    qc.cx(0, 1)
    qc.ry(-x, 0)
    qc.ry(-y, 1)
    let counts = qc.measure(shots: shots)
    var total = 0.0
    for (outcome, count) in counts.counts {
        let bits = Array(outcome)
        total += (bits[0] == bits[1] ? 1.0 : -1.0) * Double(count)
    }
    return total / Double(shots)
}

print("\nsetting pair      exact E    sampled E   cos(a−b)")
for (x, y, name) in [(a, b, "(a, b)  "), (a, bp, "(a, b') "), (ap, b, "(a', b) "), (ap, bp, "(a', b')")] {
    print("\(name)   \(fmt(exactCorrelator(x, y)))    \(fmt(sampledCorrelator(x, y, shots: 4000)))     \(fmt(cos(x - y)))")
}
// Expected: exact E always equals cos(a−b) to four decimals; sampled
// E lands within ~±0.03 of it (4000 shots, statistical).

// ============================================================
// Section 4 — the violation
// ============================================================
// a = 0, a′ = π/2, b = π/4, b′ = 3π/4 make each |E| = 1/√2 with
// signs that all add constructively in S.

let exactS = exactCorrelator(a, b) - exactCorrelator(a, bp)
    + exactCorrelator(ap, b) + exactCorrelator(ap, bp)
print("\nexact S = \(fmt(exactS))   (2√2 = \(fmt(2 * sqrt(2))))")
// Expected: 2.8284 — above the classical 2, and Section 1 showed
// that bound is exhaustive, not just unbeaten by one model.

let sampledS = sampledCorrelator(a, b, shots: 4000) - sampledCorrelator(a, bp, shots: 4000)
    + sampledCorrelator(ap, b, shots: 4000) + sampledCorrelator(ap, bp, shots: 4000)
print("sampled S = \(fmt(sampledS))")
// Expected: within ~±0.05 of 2.8284 (statistical; a run might print
// e.g. 2.8360) — comfortably clear of the classical 2.

// ============================================================
// Section 5 — the control experiments
// ============================================================
// Entanglement is *necessary*: a product state gives |S| ≤ 2 at
// these same angles, no matter which product state.

let product = QuantumCircuit(qubits: 2)
product.h(0)
product.h(1)          // |+⟩⊗|+⟩ — no `cx`, so no entanglement
let productState = product.run()

func productCorrelator(_ x: Double, _ y: Double) -> Double {
    let observable = A(x) ⊗ A(y)
    var v = Complex.zero
    for i in 0..<4 { for j in 0..<4 { v = v + productState[i].conjugate * observable[i, j] * productState[j] } }
    return v.real
}
let productS = productCorrelator(a, b) - productCorrelator(a, bp)
    + productCorrelator(ap, b) + productCorrelator(ap, bp)
print("\nproduct state |+⟩⊗|+⟩: S = \(fmt(productS))")
// Expected: 1.4142 = √2 — comfortably inside |S| ≤ 2.

// Quantum mechanics violates the classical bound but doesn't reach
// the algebraic maximum of 4 either: sweep the second setting and
// confirm the ceiling is exactly 2√2 (Tsirelson's bound).
var maxSweptS = 0.0
var probe = 0.0
while probe < Double.pi {
    let s = exactCorrelator(0, probe) - exactCorrelator(0, probe + Double.pi / 2)
        + exactCorrelator(Double.pi / 2, probe) + exactCorrelator(Double.pi / 2, probe + Double.pi / 2)
    maxSweptS = max(maxSweptS, abs(s))
    probe += 0.001
}
print("max |S| over a full angle sweep: \(fmt(maxSweptS))   (Tsirelson: \(fmt(2 * sqrt(2))))")
// Expected: 2.8284 again — the sweep's ceiling and the hand-picked
// angles from Section 4 agree; nothing beats 2√2.

// ============================================================
// Section 6 — the angle sweep, and the gap made visible
// ============================================================
// E(θ) = ⟨A(0)⊗A(θ)⟩ = cos θ against the shared-direction classical
// model from Section 1 (which is exactly the line 1 − 2θ/π on
// [0, π]) — the gap between the two curves *is* the violation.

print("\nθ        quantum cos θ   classical line")
var sweepPoints: [(theta: Double, cosine: Double, line: Double)] = []
for k in 0...8 {
    let theta = Double(k) * Double.pi / 8
    let line = 1 - 2 * theta / Double.pi
    sweepPoints.append((theta, cos(theta), line))
    print("\(fmt(theta))    \(fmt(cos(theta)))          \(fmt(line))")
}
// Expected: the two columns agree at θ = 0, π/2, π and diverge most
// (~0.207) near θ = π/4 and 3π/4 — exactly where Section 4's angles
// sit.

let sampledSweep: [(theta: Double, value: Double)] = (0...8).map { k in
    let theta = Double(k) * Double.pi / 8
    return (theta, sampledCorrelator(0, theta, shots: 500))
}

//: ### Live view — E(θ): quantum vs. the classical comparison line
//: The exact cos θ curve, 500-shot samples at nine angles, and the
//: shared-direction model's line, all on one chart.

let chart = CHSHChartView(
    title: "E(θ) = ⟨A(0) ⊗ A(θ)⟩",
    xRange: 0...Double.pi,
    yRange: -1...1,
    series: [
        CHSHChartView.Series(
            label: "quantum (cos θ)",
            color: .blue,
            points: sweepPoints.map { CGPoint(x: $0.theta, y: $0.cosine) },
            isLine: true
        ),
        CHSHChartView.Series(
            label: "classical line",
            color: .red,
            points: sweepPoints.map { CGPoint(x: $0.theta, y: $0.line) },
            isLine: true
        ),
        CHSHChartView.Series(
            label: "500-shot samples",
            color: .green,
            points: sampledSweep.map { CGPoint(x: $0.theta, y: $0.value) },
            isLine: false
        )
    ]
)

PlaygroundPage.current.setLiveView(
    chart.frame(width: 560, height: 420)
)

//: [Next](@next)

