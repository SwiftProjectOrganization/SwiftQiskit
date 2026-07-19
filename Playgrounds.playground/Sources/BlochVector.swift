import Foundation
import SwiftQiskitCore

/// A single-qubit state |ψ⟩ = α|0⟩ + β|1⟩ mapped to a point on the
/// Bloch sphere (up to global phase):
///
///   x = 2·Re(ᾱβ)
///   y = 2·Im(ᾱβ)
///   z = |α|² − |β|²
///
/// with spherical angles θ = acos(z), φ = atan2(y, x).
public struct BlochVector {
    public let x: Double
    public let y: Double
    public let z: Double

    /// Compute the Bloch vector of a 1-qubit state.
    public init(_ state: StateVector) {
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
    public var theta: Double { acos(max(-1.0, min(1.0, z))) }

    /// Azimuthal angle in the XY plane, in radians
    public var phi: Double { atan2(y, x) }
}
