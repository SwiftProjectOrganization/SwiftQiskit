//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// Trotterization — Hamiltonian simulation, what quantum computers
// were originally for
// ============================================================
// No earlier page simulates physics — Feynman's 1982 motivation for
// quantum computers in the first place. Page 18's VQE gets closest,
// but it minimizes an energy rather than evolving a state in time.
//
// Target: a 2-qubit transverse-field Ising chain
//   H = −J·Z⊗Z − h·(X⊗I + I⊗X)
// assembled entrywise from Pauli tensor products (page 18's idiom).

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

func addM(_ a: Matrix, _ b: Matrix) -> Matrix {
    var r = Matrix(rows: a.rows, cols: a.cols)
    for i in 0..<a.rows { for j in 0..<a.cols { r[i, j] = a[i, j] + b[i, j] } }
    return r
}
func scaleM(_ a: Matrix, _ s: Complex) -> Matrix {
    var r = Matrix(rows: a.rows, cols: a.cols)
    for i in 0..<a.rows { for j in 0..<a.cols { r[i, j] = a[i, j] * s } }
    return r
}
func scaleM(_ a: Matrix, _ s: Double) -> Matrix { scaleM(a, Complex(s)) }
func maxDiff(_ a: Matrix, _ b: Matrix) -> Double {
    var m = 0.0
    for i in 0..<a.rows { for j in 0..<a.cols { m = max(m, (a[i, j] - b[i, j]).magnitude) } }
    return m
}

let I2 = Matrix.identity(size: 2)
let X = PauliXGate.matrix
let Z = PauliZGate.matrix
let ZZ = Z.tensor(Z)

// ============================================================
// Section 1 — expm, self-checked before it's trusted as ground truth
// ============================================================
// `Matrix` has no `expm`, so it's built here by scaling-and-squaring
// Taylor series — and checked against an *exact* gate, `RXGate`,
// before it's used to grade anything else.

func expm(_ A: Matrix, terms: Int = 20) -> Matrix {
    let n = A.rows
    var normEst = 0.0
    for i in 0..<n { for j in 0..<n { normEst = max(normEst, A[i, j].magnitude) } }
    var s = 0
    var scaled = A
    var normS = normEst
    while normS > 0.5 { scaled = scaleM(scaled, 0.5); normS *= 0.5; s += 1 }

    var result = Matrix.identity(size: n)
    var term = Matrix.identity(size: n)
    for k in 1...terms {
        term = scaleM(term * scaled, 1.0 / Double(k))
        result = addM(result, term)
    }
    for _ in 0..<s { result = result * result }
    return result
}

let theta = 0.7
let expmRX = expm(scaleM(X, Complex(0, -theta / 2)))
let rxExact = RXGate.matrix(theta: theta)
print("expm(-iθX/2) vs. RXGate.matrix(θ=0.7): max diff = \(String(format: "%.2e", maxDiff(expmRX, rxExact)))")
// Expected: ~1e-16 — expm is trustworthy.

// ============================================================
// Section 2 — the ZZ-rotation identity, derived and checked
// ============================================================
// exp(-iθ·Z⊗Z/2) = cx(0,1); rz(θ,1); cx(0,1) — Core's RZGate is
// exactly exp(-iθZ/2), and CX-conjugation maps I⊗Z ↔ Z⊗Z, so this
// holds with no sign correction in Core's convention.

func zzViaGates(_ theta: Double) -> Matrix {
    let cx = CNOTGate.matrix(qubits: 2, control: 0, target: 1)
    let rz1 = I2.tensor(RZGate.matrix(theta: theta))
    return cx * rz1 * cx
}

let expmZZ = expm(scaleM(ZZ, Complex(0, -theta / 2)))
let gateZZ = zzViaGates(theta)
print("expm(-iθZ⊗Z/2) vs. cx;rz;cx (θ=0.7): max diff = \(String(format: "%.2e", maxDiff(expmZZ, gateZZ)))")
// Expected: ~1e-16 — the gate-level identity is exact, not approximate.

// ============================================================
// Section 3 — Trotter error scales as 1/n (order 1), 1/n² (order 2)
// ============================================================

let J = 1.0, h = 0.5
let Hising = addM(addM(scaleM(ZZ, -J), scaleM(X.tensor(I2), -h)), scaleM(I2.tensor(X), -h))

func trotterUnitary(_ t: Double, _ n: Int, order: Int) -> Matrix {
    let dt = t / Double(n)
    let uZZ = zzViaGates(-2 * J * dt)
    let rxQ0 = RXGate.matrix(theta: -2 * h * dt).tensor(I2)
    let rxQ1 = I2.tensor(RXGate.matrix(theta: -2 * h * dt))
    let step: Matrix
    if order == 1 {
        step = rxQ1 * rxQ0 * uZZ
    } else {
        let uZZhalf = zzViaGates(-2 * J * (dt / 2))
        step = uZZhalf * rxQ1 * rxQ0 * uZZhalf
    }
    var result = Matrix.identity(size: 4)
    for _ in 0..<n { result = step * result }
    return result
}

let t = 1.0
let exact = expm(scaleM(Hising, Complex(0, -t)))

print("\n1st-order Trotter error (max diff from exact), t=1:")
for n in [1, 2, 4, 8, 16, 32] {
    print("  n=\(n)   \(fmt(maxDiff(exact, trotterUnitary(t, n, order: 1))))")
}
// Expected: roughly halves each time n doubles — O(1/n).

print("\n2nd-order (Suzuki) Trotter error:")
for n in [1, 2, 4, 8, 16, 32] {
    print("  n=\(n)   \(fmt(maxDiff(exact, trotterUnitary(t, n, order: 2))))")
}
// Expected: roughly quarters each time n doubles — O(1/n²).

// ============================================================
// Section 4 — the observable-level view: ⟨Z₀⟩(t)
// ============================================================

func expectationZ0(_ state: Ket) -> Double { (state† * Z.tensor(I2) * state).real }

var psi0 = StateVector(qubits: 2)
var exactState = psi0
exactState.apply(exact)
print("\n⟨Z₀⟩ at t=1, exact:            \(fmt(expectationZ0(exactState)))")
for n in [2, 8] {
    var s = psi0
    s.apply(trotterUnitary(t, n, order: 1))
    print("⟨Z₀⟩ at t=1, 1st-order n=\(n):  \(fmt(expectationZ0(s)))")
}
// Expected: exact ≈ 0.671987; n=2 visibly off (≈0.6460); n=8 much
// closer (≈0.6705) — the observable-level error shrinks the same way
// the operator-level error does.

// ============================================================
// Section 5 — why the error exists: the commutator
// ============================================================
// Trotter error comes from splitting a Hamiltonian whose terms don't
// commute. Shown directly, not asserted: the commutator [Z⊗Z, X⊗I]
// is non-zero, and a Hamiltonian with only *one* term (nothing to
// split) is exact at n=1.

let X0 = X.tensor(I2)
let commutator = addM(ZZ * X0, scaleM(X0 * ZZ, -1))
var commNorm = 0.0
for i in 0..<4 { for j in 0..<4 { commNorm = max(commNorm, commutator[i, j].magnitude) } }
print("\nmax |[Z⊗Z, X⊗I]| entry: \(fmt(commNorm))")
// Expected: 2.0 — manifestly non-zero.

let Hcomm = scaleM(ZZ, -J)
let exactComm = expm(scaleM(Hcomm, Complex(0, -t)))
let trotterComm1 = zzViaGates(-2 * J * t)
print("commuting-only Hamiltonian, n=1 error: \(String(format: "%.2e", maxDiff(exactComm, trotterComm1)))")
// Expected: 0.0 — with only one term, first-order Trotter is exact.

// ============================================================
// Section 6 — live view: exact curve vs. Trotterized samples
// ============================================================

func exactZ0(at time: Double) -> Double {
    var s = psi0
    s.apply(expm(scaleM(Hising, Complex(0, -time))))
    return expectationZ0(s)
}
func trotterZ0(at time: Double, n: Int) -> Double {
    var s = psi0
    s.apply(trotterUnitary(time, n, order: 1))
    return expectationZ0(s)
}

var exactCurve: [CGPoint] = []
var tSweep = 0.0
while tSweep <= 3.0 {
    exactCurve.append(CGPoint(x: tSweep, y: exactZ0(at: tSweep)))
    tSweep += 0.05
}

var trotterN2: [CGPoint] = []
var trotterN8: [CGPoint] = []
var sampleT = 0.2
while sampleT <= 3.0 {
    trotterN2.append(CGPoint(x: sampleT, y: trotterZ0(at: sampleT, n: 2)))
    trotterN8.append(CGPoint(x: sampleT, y: trotterZ0(at: sampleT, n: 8)))
    sampleT += 0.3
}

//: ### Live view — ⟨Z₀⟩(t): exact curve vs. Trotterized samples
//: The blue curve is the exact evolution; the orange (n=2) and green
//: (n=8) dots are single-step-count Trotter approximations sampled at
//: several times — n=8 tracks the curve far more closely than n=2.

let chart = CHSHChartView(
    title: "Trotterized ⟨Z₀⟩(t) vs. exact evolution",
    xRange: 0.0...3.0,
    yRange: -1.0...1.0,
    series: [
        CHSHChartView.Series(label: "exact", color: .blue, points: exactCurve, isLine: true),
        CHSHChartView.Series(label: "Trotter n=2", color: .orange, points: trotterN2, isLine: false),
        CHSHChartView.Series(label: "Trotter n=8", color: .green, points: trotterN8, isLine: false)
    ]
)

PlaygroundPage.current.setLiveView(
    chart.frame(width: 560, height: 420)
)

//: [Next](@next)
