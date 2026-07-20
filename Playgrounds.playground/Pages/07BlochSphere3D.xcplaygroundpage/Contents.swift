//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// Section 1 — The θ/φ parametrization
// ============================================================
// Any single-qubit state can be written (up to global phase) as
//
//   |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
//
// with θ ∈ [0, π] the polar angle from the |0⟩ pole and
// φ ∈ [0, 2π) the azimuth from the x-axis (see the previous page
// for the derivation).
//
// Why can θ and φ vary *independently*? A quantum state must be
// normalized: |α|² + |β|² = 1. The parametrization satisfies this
// identically —
//
//   |α|² + |β|² = cos²(θ/2) + |e^{iφ}|²·sin²(θ/2)
//               = cos²(θ/2) + sin²(θ/2) = 1
//
// for every θ and φ, because e^{iφ} is a pure phase (|e^{iφ}| = 1)
// and never changes a magnitude. That is exactly why this page
// exposes sliders for the *angles* rather than the amplitudes:
// every slider position is a valid normalized state — the sliders
// can only move around the surface of the Bloch sphere, never off
// of it.

/// Build |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
func makeState(theta: Double, phi: Double) -> StateVector {
    StateVector([
        Complex(cos(theta / 2)),
        Complex(sin(theta / 2) * cos(phi), sin(theta / 2) * sin(phi))
    ])
}

// ============================================================
// Section 2 — Console readout for the starting state
// ============================================================
// The live view starts at θ = 60°, φ = 45°.

let initialTheta = Double.pi / 3
let initialPhi = Double.pi / 4

let psi = makeState(theta: initialTheta, phi: initialPhi)

print("Starting state:")
print(String(format: "  θ = %.3f rad (%.1f°), φ = %.3f rad (%.1f°)",
             initialTheta, initialTheta * 180 / .pi,
             initialPhi, initialPhi * 180 / .pi))
print("  α = ⟨0|ψ⟩ = \(psi[0])")
print("  β = ⟨1|ψ⟩ = \(psi[1])")
print(String(format: "  |α|² + |β|² = %.6f",
             psi[0].magnitudeSquared + psi[1].magnitudeSquared))
// Expected: |α|² + |β|² = 1.000000 — and it stays 1 for any θ, φ.

// ============================================================
// Section 3 — The 3D view
// ============================================================
// `Bloch3DView` (shared Sources) draws the sphere as a rotatable
// wireframe: latitude/longitude circles are perspective-projected
// through an orbit camera, the far hemisphere is drawn dimmer as a
// depth cue, and dragging the canvas orbits the camera. Compare
// with the fixed oblique projection of `BlochSphereView` on the
// previous pages.

// ============================================================
// Section 4 — Live view with θ/φ sliders
// ============================================================
// `BlochExplorerView` (shared Sources) wraps `Bloch3DView` with live
// sliders for θ ∈ [0, π] and φ ∈ [0, 2π), rebuilding the state from
// the parametrization above on every change. Its details readout
// shows |α|² + |β|² staying at 1 for every slider position.
//
// The view lives in Sources rather than inline here because the
// Xcode 27 beta playground evaluator cannot expand the SDK 27
// `@State` macro in page code; the Sources module is compiled by
// the regular build system, where the macro works.

PlaygroundPage.current.setLiveView(
    BlochExplorerView()
        .frame(width: 460, height: 640)
)

//: [Next](@next)
