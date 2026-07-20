//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// Section 1 — The ket definition
// ============================================================
// This page shows a *general* single-qubit state, tilted off
// the equator of the Bloch sphere: a qubit whose Bloch vector
// makes an angle of 45° with the x-axis and 60° with the y-axis.
//
// The components of a unit vector are its direction cosines:
//
//   x = cos 45° = √2/2 ≈ 0.7071
//   y = cos 60° = 1/2
//   z = √(1 − x² − y²) = √(1 − 3/4) = 1/2   (upper hemisphere)
//
// so the vector is also 60° from the z-axis. In spherical angles:
//
//   θ = acos(z) = 60°               (polar angle from |0⟩)
//   φ = atan2(y, x) ≈ 35.264°       (azimuth from the x-axis)
//
// Any single-qubit state can be written (up to global phase) as
//
//   |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
//
// which here becomes
//
//   |ψ⟩ = cos 30°|0⟩ + (cos φ + i·sin φ)·sin 30°|1⟩
//       ≈ 0.8660|0⟩ + (0.4082 + 0.2887i)|1⟩

// ============================================================
// Section 2 — Build the state
// ============================================================
// SwiftQiskit v0.1 has no rotation or phase gates yet, so the
// state is constructed directly from its amplitudes.
// StateVector's initializer normalizes for us.

let theta = Double.pi / 3                       // 60°
let phi = atan2(0.5, sqrt(2) / 2)               // ≈ 35.264°

let alpha = Complex(cos(theta / 2))                                 // cos(θ/2)
let beta = Complex(sin(theta / 2) * cos(phi), sin(theta / 2) * sin(phi))  // e^{iφ}·sin(θ/2)

let psi = StateVector([alpha, beta])

// ============================================================
// Section 3 — Console readout
// ============================================================

print("Ket definition:")
print("  |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩")
print(String(format: "  θ = %.3f rad (%.1f°), φ = %.3f rad (%.1f°)",
             theta, theta * 180 / .pi, phi, phi * 180 / .pi))
print(String(format: "  |ψ⟩ ≈ %.4f|0⟩ + (%.4f + %.4fi)|1⟩",
             alpha.real, beta.real, beta.imag))
print()

print("Amplitudes:")
print("  α = ⟨0|ψ⟩ = \(psi[0])")
print("  β = ⟨1|ψ⟩ = \(psi[1])")
print()

print("Magnitudes:")
print(String(format: "  |α| = %.4f", psi[0].magnitude))
print(String(format: "  |β| = %.4f", psi[1].magnitude))
print()

print("Probabilities:")
let probabilities = psi.probabilities
print(String(format: "  P(0) = |α|² = %.4f", probabilities[0]))
print(String(format: "  P(1) = |β|² = %.4f", probabilities[1]))
print()
// Expected:
//   α ≈ 0.8660, β ≈ 0.4082 + 0.2887i
//   |α| ≈ 0.8660, |β| = 0.5
//   P(0) = 0.75, P(1) = 0.25

// ============================================================
// Section 4 — Bloch vector math
// ============================================================
// A single-qubit state |ψ⟩ = α|0⟩ + β|1⟩ maps to a point on the
// Bloch sphere (up to global phase):
//
//   x = 2·Re(ᾱβ)
//   y = 2·Im(ᾱβ)
//   z = |α|² − |β|²
//
// with spherical angles θ = acos(z), φ = atan2(y, x).
//
// `BlochVector` implements this in the playground's shared
// Sources folder, alongside `BlochSphereView` and
// `BlochProjectionView` used below.

// Round-trip check: recover the Bloch vector from the amplitudes.
let bloch = BlochVector(psi)
print("Bloch vector (recovered from amplitudes):")
print(String(format: "  x %+.4f  y %+.4f  z %+.4f", bloch.x, bloch.y, bloch.z))
print(String(format: "  angle from x-axis: %.1f°", acos(bloch.x) * 180 / .pi))
print(String(format: "  angle from y-axis: %.1f°", acos(bloch.y) * 180 / .pi))
print(String(format: "  angle from z-axis: %.1f°", acos(bloch.z) * 180 / .pi))
// Expected: (√2/2, 1/2, 1/2) — 45° from x, 60° from y, 60° from z.

// ============================================================
// Section 5 — Plane projections
// ============================================================
// An orthographic projection onto a coordinate plane simply drops
// the out-of-plane component of the Bloch vector: the x–y
// projection is the point (x, y), the z–y projection the point
// (y, z). The projected arrow is shorter than the unit circle
// whenever the state points out of the plane — the missing length
// is the dropped component. `BlochProjectionView` (shared Sources)
// draws one such plane.

// ============================================================
// Section 6 — Live view
// ============================================================

struct BlochDetailView: View {
    let bloch: BlochVector
    let state: StateVector

    var body: some View {
        VStack(spacing: 16) {
            BlochSphereView(label: "|ψ⟩  θ = 60°, φ ≈ 35.3°", bloch: bloch, size: 300)

            // Axis orientations match the main sphere (y → right, z → up,
            // x → toward the viewer): looking down from the |0⟩ pole, the
            // x-axis points toward the viewer, i.e. down on the canvas.
            HStack(spacing: 16) {
                BlochProjectionView(
                    label: "x–y plane (from +z)",
                    horizontal: ("y", bloch.y),
                    vertical: ("x", bloch.x),
                    verticalPointsDown: true
                )
                BlochProjectionView(
                    label: "z–y plane (from +x)",
                    horizontal: ("y", bloch.y),
                    vertical: ("z", bloch.z)
                )
            }

            Text(details)
                .font(.system(.caption, design: .monospaced))
        }
        .padding()
    }

    private var details: String {
        let probs = state.probabilities
        return String(
            format: """
            |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
            α = %.4f          |α| = %.4f
            β = %.4f + %.4fi  |β| = %.4f
            P(0) = %.2f  P(1) = %.2f
            """,
            state[0].real, state[0].magnitude,
            state[1].real, state[1].imag, state[1].magnitude,
            probs[0], probs[1]
        )
    }
}

PlaygroundPage.current.setLiveView(
    BlochDetailView(bloch: bloch, state: psi)
        .frame(width: 460, height: 720)
)

//: [Next](@next)
