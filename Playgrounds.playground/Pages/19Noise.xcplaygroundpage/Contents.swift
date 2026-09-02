//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// Noise — mixed states, quantum channels, and decoherence
// ============================================================
// Every earlier page assumed a perfect, isolated, *pure* state — even
// page 14 modeled errors as a discrete, coherent `rx(θ)` rotation, not
// decoherence. This page introduces the object that makes mixtures,
// noise, and reduced states of entangled systems expressible: the
// density matrix ρ.
//
// `Matrix` has no `+`, scalar multiply, or trace, so those are added
// here as page-level helpers — the same shape as page 12's QFT† and
// page 18's Hamiltonian, both built entrywise for the same reason.

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

func addM(_ a: Matrix, _ b: Matrix) -> Matrix {
    var r = Matrix(rows: a.rows, cols: a.cols)
    for i in 0..<a.rows { for j in 0..<a.cols { r[i, j] = a[i, j] + b[i, j] } }
    return r
}
func scaleM(_ a: Matrix, _ s: Double) -> Matrix {
    var r = Matrix(rows: a.rows, cols: a.cols)
    for i in 0..<a.rows { for j in 0..<a.cols { r[i, j] = a[i, j] * s } }
    return r
}
func trace(_ a: Matrix) -> Complex {
    var s = Complex.zero
    for i in 0..<a.rows { s = s + a[i, i] }
    return s
}
func rho(_ psi: Ket) -> Matrix { psi * (psi†) }
func purity(_ r: Matrix) -> Double { trace(r * r).real }

let I2 = Matrix.identity(size: 2)
let X = PauliXGate.matrix
let Y = PauliYGate.matrix
let Z = PauliZGate.matrix

// ============================================================
// Section 1 — the density matrix, and a mixture vs. a superposition
// ============================================================
// ρ = |ψ⟩⟨ψ| reuses the existing outer product (Quantum/Dirac.swift).
// ½|0⟩⟨0| + ½|1⟩⟨1| (a coin flip between two *known* states) and
// |+⟩⟨+| (a genuine superposition) give identical Z-statistics but
// different X-statistics — coherence lives in the off-diagonal terms
// a mixture doesn't have.

let rhoPlus = rho(Ket.plus)
let rhoMix = scaleM(addM(rho(Ket.zero), rho(Ket.one)), 0.5)

print("ρ(|+⟩):        diag \(fmt(rhoPlus[0,0].real)), \(fmt(rhoPlus[1,1].real))   off-diag \(rhoPlus[0,1])")
print("ρ(mixture):    diag \(fmt(rhoMix[0,0].real)), \(fmt(rhoMix[1,1].real))   off-diag \(rhoMix[0,1])")
print("purity: |+⟩ = \(fmt(purity(rhoPlus))),  mixture = \(fmt(purity(rhoMix)))")
// Expected: both diag exactly (0.5, 0.5) — a Z measurement can't tell
// them apart — but |+⟩'s off-diagonal is 0.5 (coherent) vs. the
// mixture's 0.0. Purity 1.0 vs. 0.5: only one of these is a
// superposition.

// ============================================================
// Section 2 — Kraus channels
// ============================================================
// A quantum channel is ρ' = Σ Kᵢ ρ Kᵢ†. Trace preservation
// (Σ Kᵢ†Kᵢ = I) is checked before any channel is trusted.

func bitFlipKraus(_ p: Double) -> [Matrix] {
    [scaleM(I2, (1 - p).squareRoot()), scaleM(X, p.squareRoot())]
}
func phaseFlipKraus(_ p: Double) -> [Matrix] {
    [scaleM(I2, (1 - p).squareRoot()), scaleM(Z, p.squareRoot())]
}
func depolarizingKraus(_ p: Double) -> [Matrix] {
    [scaleM(I2, (1 - 0.75 * p).squareRoot()),
     scaleM(X, (p / 4).squareRoot()),
     scaleM(Y, (p / 4).squareRoot()),
     scaleM(Z, (p / 4).squareRoot())]
}
func ampDampingKraus(_ g: Double) -> [Matrix] {
    var k0 = Matrix(rows: 2, cols: 2)
    k0[0, 0] = .one; k0[1, 1] = Complex((1 - g).squareRoot())
    var k1 = Matrix(rows: 2, cols: 2)
    k1[0, 1] = Complex(g.squareRoot())
    return [k0, k1]
}

func traceResidual(_ ks: [Matrix]) -> Double {
    var sum: Matrix? = nil
    for k in ks {
        let term = (k†) * k
        sum = sum == nil ? term : addM(sum!, term)
    }
    let diff = addM(sum!, scaleM(I2, -1))
    var maxAbs = 0.0
    for i in 0..<2 { for j in 0..<2 { maxAbs = max(maxAbs, diff[i, j].magnitude) } }
    return maxAbs
}

print("\nΣKᵢ†Kᵢ − I max residual, p = 0.3:")
print("  bit-flip:      \(String(format: "%.2e", traceResidual(bitFlipKraus(0.3))))")
print("  phase-flip:    \(String(format: "%.2e", traceResidual(phaseFlipKraus(0.3))))")
print("  depolarizing:  \(String(format: "%.2e", traceResidual(depolarizingKraus(0.3))))")
print("  amp-damping:   \(String(format: "%.2e", traceResidual(ampDampingKraus(0.3))))")
// Expected: all ~0 (≤1.2e-16) — every channel is trace-preserving.

// ============================================================
// Section 3 — coherence decay, and the maximally mixed state
// ============================================================
// Repeated phase-flip(p) on |+⟩ decays the off-diagonal exactly as
// (1 − 2p)ⁿ — a closed form checked against the simulation, not
// assumed.

func applyChannel(_ ks: [Matrix], _ r: Matrix) -> Matrix {
    var out: Matrix? = nil
    for k in ks {
        let term = k * r * (k†)
        out = out == nil ? term : addM(out!, term)
    }
    return out!
}

print("\nn    off-diag (measured)   (1-2p)ⁿ predicted   [p = 0.1]")
for n in [1, 5, 10, 20] {
    var r = rhoPlus
    for _ in 1...n { r = applyChannel(phaseFlipKraus(0.1), r) }
    let predicted = 0.5 * pow(0.8, Double(n))
    print("\(n)     \(fmt(r[0, 1].real))              \(fmt(predicted))")
}
// Expected: measured and predicted agree to every printed digit.

let fullyDepolarized = applyChannel(depolarizingKraus(1.0), rho(Ket.zero))
print("\nfully depolarized (p=1) on |0⟩: diag \(fmt(fullyDepolarized[0,0].real)), \(fmt(fullyDepolarized[1,1].real)), purity \(fmt(purity(fullyDepolarized)))")
// Expected: diag (0.5, 0.5), purity 0.5 — the maximally mixed state,
// indistinguishable from a fair coin in any basis.

// ============================================================
// Section 4 — amplitude damping: T1-style decay toward |0⟩
// ============================================================
// Unlike dephasing, amplitude damping also moves the Bloch vector's
// z-coordinate, pulling it toward the |0⟩ pole while x, y shrink —
// the picture no pure state can draw, since it leaves the sphere's
// surface entirely.

func blochOf(_ r: Matrix) -> (x: Double, y: Double, z: Double) {
    (trace(r * X).real, trace(r * Y).real, trace(r * Z).real)
}

var damped = rhoPlus
for _ in 1...20 { damped = applyChannel(ampDampingKraus(0.2), damped) }
let dampedBloch = blochOf(damped)
print("\n|+⟩ after 20 rounds of amplitude damping (γ=0.2):")
print("  Bloch (x,y,z) = (\(fmt(dampedBloch.x)), \(fmt(dampedBloch.y)), \(fmt(dampedBloch.z)))")
print("  purity = \(fmt(purity(damped)))")
// Expected: x ≈ 0.107374 (= 0.8^10, since x shrinks by √(1-γ) per
// round), z ≈ 0.988471 (rising toward +1), purity ≈ 0.994302 —
// *inside* the sphere, not on it.

// ============================================================
// Section 5 — Monte-Carlo unraveling
// ============================================================
// The exact channel above can be reproduced from pure-state code
// alone: per shot, flip a biased coin and apply the error gate or
// not, then measure. This is how you add noise to a state-vector
// simulator without a density-matrix type.

let H = HadamardGate.matrix
let Sdg = SDaggerGate.matrix

func monteCarloPhaseFlipXBasis(_ p: Double, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots {
        var s = StateVector.plus
        if Double.random(in: 0..<1) < p { s.apply(Z) }
        s.apply(H)
        if s.measure() == 0 { plus += 1 }
    }
    return Double(plus) / Double(shots)
}

let mcP = monteCarloPhaseFlipXBasis(0.1, shots: 20000)
print("\nMonte-Carlo phase-flip(0.1) on |+⟩, 20000 shots: P(+x) = \(fmt(mcP))")
print("exact prediction (1+(1-2p))/2 = \(fmt((1 + (1 - 2 * 0.1)) / 2))")
// Expected: measured ≈ 0.900 ± ~0.002 (shot noise), matching the
// exact 0.9 prediction.

// ============================================================
// Section 6 — entanglement, seen through a reduced state
// ============================================================
// Tracing out one qubit of an entangled pair leaves the other
// *mixed*, even though the full 2-qubit state is pure — the
// explanation page 13's marginals were owed.

var bell = StateVector(qubits: 2)
bell.apply(H.tensor(I2))
bell.apply(CNOTGate.matrix(qubits: 2, control: 0, target: 1))
let rhoBell = rho(bell)

func partialTraceLast(_ r: Matrix) -> Matrix {
    var out = Matrix(rows: 2, cols: 2)
    for i in 0..<2 {
        for j in 0..<2 {
            var s = Complex.zero
            for k in 0..<2 { s = s + r[i * 2 + k, j * 2 + k] }
            out[i, j] = s
        }
    }
    return out
}

func entropy(of r: Matrix) -> Double {
    let b = blochOf(r)
    let mag = (b.x * b.x + b.y * b.y + b.z * b.z).squareRoot()
    let l1 = (1 + mag) / 2, l2 = (1 - mag) / 2
    func log2safe(_ v: Double) -> Double { v <= 0 ? 0 : log2(v) }
    return -(l1 * log2safe(l1) + l2 * log2safe(l2))
}

let rhoA = partialTraceLast(rhoBell)
print("\nBell pair |Φ⁺⟩: full-state purity = \(fmt(purity(rhoBell)))")
print("qubit 0's reduced state ρ_A: diag \(fmt(rhoA[0,0].real)), \(fmt(rhoA[1,1].real)), purity \(fmt(purity(rhoA))), entropy \(fmt(entropy(of: rhoA))) bits")
// Expected: full-state purity 1.0 (pure), but ρ_A = diag(0.5, 0.5),
// purity 0.5, entropy exactly 1.0 bit — maximal entanglement.

var product = StateVector(qubits: 2)
product.apply(H.tensor(I2))
let rhoProdA = partialTraceLast(rho(product))
print("product state |+⟩⊗|0⟩: ρ_A entropy = \(fmt(entropy(of: rhoProdA))) bits")
// Expected: ≈0.0 — no entanglement, the marginal stays pure.

// ============================================================
// Section 7 — live view: three Bloch points, shrinking inward
// ============================================================
// The pure |+⟩, next to its dephased and fully-depolarized images —
// the same state getting less "pointy" as it loses coherence. Uses
// this page's additive `BlochVector(x:y:z:)`, since these vectors
// are shorter than 1 and can't come from a normalized `StateVector`.

struct NoiseGalleryView: View {
    let stages: [(name: String, bloch: BlochVector)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A pure state losing coherence").font(.title3.bold())
            HStack(spacing: 16) {
                ForEach(stages, id: \.name) { stage in
                    BlochSphereView(label: stage.name, bloch: stage.bloch, size: 220)
                }
            }
        }
        .padding()
    }
}

let dephasedForView = { () -> Matrix in
    var r = rhoPlus
    for _ in 1...10 { r = applyChannel(phaseFlipKraus(0.1), r) }
    return r
}()
let dephasedBlochForView = blochOf(dephasedForView)

let stages: [(name: String, bloch: BlochVector)] = [
    ("pure |+⟩", BlochVector(Ket.plus)),
    ("dephased (10× p=0.1)", BlochVector(x: dephasedBlochForView.x, y: dephasedBlochForView.y, z: dephasedBlochForView.z)),
    ("fully depolarized", BlochVector(x: 0, y: 0, z: 0))
]

PlaygroundPage.current.setLiveView(
    NoiseGalleryView(stages: stages)
        .frame(width: 820, height: 360)
)

//: [Next](@next)
