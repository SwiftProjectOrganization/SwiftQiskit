import SwiftUI
import SwiftQiskitCore

/// Interactive Bloch-sphere explorer: a `Bloch3DView` driven by live
/// sliders for the spherical angles θ ∈ [0, π] and φ ∈ [0, 2π).
///
/// The sliders are independent because the θ/φ parametrization
///
///   |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
///
/// satisfies |α|² + |β|² = 1 identically — every slider position is a
/// valid normalized state.
///
/// This view lives in the shared Sources folder (rather than inline in
/// page 07) because the Xcode 27 beta playground evaluator cannot expand
/// the SDK 27 `@State` macro in page code; Sources is compiled by the
/// regular build system, where the macro works.
public struct BlochExplorerView: View {

    @State private var theta: Double
    @State private var phi: Double

    public init() {
        theta = .pi / 3
        phi = .pi / 4
    }

    /// |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
    private var state: StateVector {
        StateVector([
            Complex(cos(theta / 2)),
            Complex(sin(theta / 2) * cos(phi), sin(theta / 2) * sin(phi))
        ])
    }

    public var body: some View {
        let bloch = BlochVector(state)

        VStack(spacing: 12) {
            Bloch3DView(label: title, bloch: bloch, size: 320)

            // θ ∈ [0, π]; φ ∈ [0, 2π) — 2π itself is excluded because
            // it is the same state as φ = 0
            angleSlider("θ", value: $theta, range: 0...Double.pi)
            angleSlider("φ", value: $phi, range: 0...(2 * Double.pi).nextDown)

            Text(details)
                .font(.system(.caption, design: .monospaced))
        }
        .padding()
    }

    private var title: String {
        String(format: "|ψ⟩  θ = %.1f°, φ = %.1f°",
               theta * 180 / .pi, phi * 180 / .pi)
    }

    private func angleSlider(
        _ label: String, value: Binding<Double>, range: ClosedRange<Double>
    ) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range)
            Text(String(format: "%6.1f°", value.wrappedValue * 180 / .pi))
                .font(.system(.caption, design: .monospaced))
                .frame(width: 52, alignment: .trailing)
        }
    }

    private var details: String {
        let probs = state.probabilities
        return String(
            format: """
            |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
            α = %.4f            |α| = %.4f
            β = %.4f %+.4fi     |β| = %.4f
            P(0) = %.4f  P(1) = %.4f  |α|² + |β|² = %.4f
            """,
            state[0].real, state[0].magnitude,
            state[1].real, state[1].imag, state[1].magnitude,
            probs[0], probs[1],
            state[0].magnitudeSquared + state[1].magnitudeSquared
        )
    }
}
