//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// Section 1 — Bloch vector math
// ============================================================
// A single-qubit state |ψ⟩ = α|0⟩ + β|1⟩ maps to a point on the
// Bloch sphere (up to global phase):
//
//   x = 2·Re(ᾱβ)
//   y = 2·Im(ᾱβ)
//   z = |α|² − |β|²
//
// with spherical angles θ = acos(z), φ = atan2(y, x).

struct BlochVector {
    let x: Double
    let y: Double
    let z: Double

    /// Compute the Bloch vector of a 1-qubit state.
    init(_ state: StateVector) {
        precondition(state.dimension == 2, "Bloch sphere is defined for single-qubit states")

        let alpha = state[0]
        let beta = state[1]

        // ᾱβ — reuses Complex arithmetic from SwiftQiskitCore
        let ab = alpha.conjugate * beta

        x = 2 * ab.real
        y = 2 * ab.imag
        z = alpha.magnitudeSquared - beta.magnitudeSquared
    }

    /// Polar angle from +Z (|0⟩ pole), in radians
    var theta: Double { acos(max(-1.0, min(1.0, z))) }

    /// Azimuthal angle in the XY plane, in radians
    var phi: Double { atan2(y, x) }
}

// ============================================================
// Section 2 — Bloch sphere view (2D orthographic projection)
// ============================================================
// Projection: y → right, z → up, x → toward the viewer,
// drawn obliquely toward the lower-left (foreshortened).

struct BlochSphereView: View {

    let label: String
    let bloch: BlochVector

    /// Foreshortening factor for the x-axis (depth)
    private let depth = 0.5 * sqrt(0.5)

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.headline)

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 24

                drawSphere(context, center: center, radius: radius)
                drawAxes(context, center: center, radius: radius)
                drawStateVector(context, center: center, radius: radius)
            }
            .frame(width: 220, height: 220)

            Text(readout)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var readout: String {
        String(
            format: "x %+.3f  y %+.3f  z %+.3f\nθ %.3f rad  φ %.3f rad",
            bloch.x, bloch.y, bloch.z, bloch.theta, bloch.phi
        )
    }

    /// Project a 3D point on the unit sphere to canvas coordinates
    private func project(
        _ x: Double, _ y: Double, _ z: Double,
        center: CGPoint, radius: Double
    ) -> CGPoint {
        CGPoint(
            x: center.x + (y - x * depth) * radius,
            y: center.y - (z - x * depth) * radius
        )
    }

    private func drawSphere(_ context: GraphicsContext, center: CGPoint, radius: Double) {
        // Sphere outline
        let outline = Path(
            ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            )
        )
        context.stroke(outline, with: .color(.primary.opacity(0.6)), lineWidth: 1)

        // Equator (flattened, dashed)
        let equator = Path(
            ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius * depth,
                width: radius * 2, height: radius * depth * 2
            )
        )
        context.stroke(
            equator,
            with: .color(.secondary.opacity(0.5)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
        )
    }

    private func drawAxes(_ context: GraphicsContext, center: CGPoint, radius: Double) {
        let axes: [(x: Double, y: Double, z: Double, label: String)] = [
            (1, 0, 0, "x"),
            (0, 1, 0, "y"),
            (0, 0, 1, "|0⟩"),
            (0, 0, -1, "|1⟩")
        ]

        for axis in axes {
            let tip = project(axis.x, axis.y, axis.z, center: center, radius: radius)
            let tail = project(-axis.x, -axis.y, -axis.z, center: center, radius: radius)

            var line = Path()
            line.move(to: tail)
            line.addLine(to: tip)
            context.stroke(line, with: .color(.secondary.opacity(0.5)), lineWidth: 0.5)

            // Label just beyond the axis tip
            let labelPoint = project(
                axis.x * 1.15, axis.y * 1.15, axis.z * 1.15,
                center: center, radius: radius
            )
            context.draw(
                Text(axis.label).font(.caption2).foregroundStyle(.secondary),
                at: labelPoint
            )
        }
    }

    private func drawStateVector(_ context: GraphicsContext, center: CGPoint, radius: Double) {
        let tip = project(bloch.x, bloch.y, bloch.z, center: center, radius: radius)

        var arrow = Path()
        arrow.move(to: center)
        arrow.addLine(to: tip)
        context.stroke(arrow, with: .color(.red), lineWidth: 2)

        let dot = Path(
            ellipseIn: CGRect(x: tip.x - 4, y: tip.y - 4, width: 8, height: 8)
        )
        context.fill(dot, with: .color(.red))
    }
}

// ============================================================
// Section 3 — Demo states built with SwiftQiskitCore
// ============================================================

// |0⟩ — empty circuit
let zeroCircuit = QuantumCircuit(qubits: 1)

// |1⟩ — Pauli-X flips |0⟩
let oneCircuit = QuantumCircuit(qubits: 1)
oneCircuit.x(0)

// |+⟩ = (|0⟩ + |1⟩)/√2 — Hadamard
let plusCircuit = QuantumCircuit(qubits: 1)
plusCircuit.h(0)

// |−⟩ = (|0⟩ − |1⟩)/√2 — Hadamard then Pauli-Z
let minusCircuit = QuantumCircuit(qubits: 1)
minusCircuit.h(0)
minusCircuit.z(0)

let states: [(name: String, bloch: BlochVector)] = [
    ("|0⟩", BlochVector(zeroCircuit.run())),
    ("|1⟩", BlochVector(oneCircuit.run())),
    ("|+⟩", BlochVector(plusCircuit.run())),
    ("|−⟩", BlochVector(minusCircuit.run()))
]

// Console readout
for state in states {
    let b = state.bloch
    print(
        String(
            format: "%@  x %+.3f  y %+.3f  z %+.3f  (θ %.3f, φ %.3f)",
            state.name, b.x, b.y, b.z, b.theta, b.phi
        )
    )
}
// Expected:
//   |0⟩ → (0, 0, +1)   north pole
//   |1⟩ → (0, 0, −1)   south pole
//   |+⟩ → (+1, 0, 0)   +x axis
//   |−⟩ → (−1, 0, 0)   −x axis

// ============================================================
// Section 4 — Live view
// ============================================================

struct BlochGalleryView: View {
    let states: [(name: String, bloch: BlochVector)]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(260)), count: 2), spacing: 16) {
            ForEach(states, id: \.name) { state in
                BlochSphereView(label: state.name, bloch: state.bloch)
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    BlochGalleryView(states: states)
        .frame(width: 560, height: 640)
)

//: [Next](@next)
