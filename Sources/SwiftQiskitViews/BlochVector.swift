import Foundation
import SwiftQiskit

/// A single-qubit state |ψ⟩ = α|0⟩ + β|1⟩ (or a single qubit of a mixed
/// state ρ) mapped to a point on the Bloch sphere (up to global phase):
///
///   x = 2·Re(ᾱβ)
///   y = 2·Im(ᾱβ)
///   z = |α|² − |β|²
///
/// with spherical angles θ = acos(z), φ = atan2(y, x). Shared by the
/// playground and by `SwiftQiskitApp` — see `STATUSandTODO.md`'s
/// "SwiftQiskitViews" entry for why this lives in its own UI-free-Core-
/// preserving module rather than in `SwiftQiskit` itself.
public struct BlochVector: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double

    /// Compute the Bloch vector of a 1-qubit pure state.
    public init(_ state: StateVector) {
        precondition(state.dimension == 2, "Bloch sphere is defined for single-qubit states")

        let alpha = state[0]
        let beta = state[1]

        // ᾱβ — reuses Complex arithmetic from SwiftQiskit
        let ab = alpha.conjugate * beta

        x = 2 * ab.real
        y = 2 * ab.imag
        z = alpha.magnitudeSquared - beta.magnitudeSquared
    }

    /// Reduced Bloch vector for one qubit of an n-qubit pure state, found by
    /// summing over every basis configuration of the other qubits (a partial
    /// trace). Entangled qubits give |r| < 1 — a shorter arrow, drawn inside
    /// the sphere. Qubit 0 is the most-significant bit, matching the rest of
    /// the package.
    public init(_ state: StateVector, qubit: Int) {
        let qubitCount = state.dimension.trailingZeroBitCount
        precondition(qubit >= 0 && qubit < qubitCount, "qubit out of range")

        let stride = 1 << (qubitCount - 1 - qubit)
        var s = Complex.zero
        var p0 = 0.0
        var p1 = 0.0

        for i in 0..<state.dimension where (i / stride) % 2 == 0 {
            let amp0 = state[i]
            let amp1 = state[i + stride]
            s = s + amp0.conjugate * amp1
            p0 += amp0.magnitudeSquared
            p1 += amp1.magnitudeSquared
        }

        x = 2 * s.real
        y = 2 * s.imag
        z = p0 - p1
    }

    /// Bloch vector of a single-qubit `DensityMatrix`, via its own
    /// `blochVector` (`Tr(ρX)`, `Tr(ρY)`, `Tr(ρZ)`). `nil` for anything
    /// other than a 2×2 (one-qubit) density matrix.
    public init?(_ rho: DensityMatrix) {
        guard let bloch = rho.blochVector else { return nil }
        x = bloch.x
        y = bloch.y
        z = bloch.z
    }

    /// Reduced Bloch vector for one qubit of an n-qubit density matrix, via
    /// `partialTrace(keeping:)` followed by the single-qubit `blochVector`.
    public init(_ rho: DensityMatrix, qubit: Int) {
        let reduced = rho.partialTrace(keeping: [qubit])
        // `partialTrace(keeping: [qubit])` always yields a 2×2 (one-qubit)
        // density matrix, so `blochVector` is never nil here.
        let bloch = reduced.blochVector!
        x = bloch.x
        y = bloch.y
        z = bloch.z
    }

    /// Raw coordinates, for mixed-state Bloch vectors — a reduced or
    /// density-matrix-driven init above can produce |r| < 1, which a
    /// normalized `StateVector` can't represent.
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Length of the vector, 1 for a pure state, < 1 for a mixed/entangled one.
    public var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }

    /// Polar angle from +Z (|0⟩ pole), in radians
    public var theta: Double { acos(max(-1.0, min(1.0, z))) }

    /// Azimuthal angle in the XY plane, in radians
    public var phi: Double { atan2(y, x) }
}
