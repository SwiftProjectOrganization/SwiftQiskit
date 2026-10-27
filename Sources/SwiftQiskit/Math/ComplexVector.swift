//
//  ComplexVector.swift
//  SwiftQiskit
//
//  Arithmetic on plain `[Complex]` vectors. Unlike `StateVector`, which normalizes its
//  input, these hold raw amplitudes such as |0⟩ + |1⟩ before normalization.
//
//  Named methods rather than operators: `Array` already has `+` for concatenation, and a
//  more specific `+` here would silently change what `a + b` means for `[Complex]`.
//

import Foundation

public extension Array where Element == Complex {

    /// Element-wise sum. Both vectors must have the same length.
    func adding(_ other: [Complex]) -> [Complex] {
        precondition(count == other.count, "Vector lengths must match")
        return zip(self, other).map { $0 + $1 }
    }

    /// Element-wise difference. Both vectors must have the same length.
    func subtracting(_ other: [Complex]) -> [Complex] {
        precondition(count == other.count, "Vector lengths must match")
        return zip(self, other).map { $0 - $1 }
    }

    /// Every element multiplied by the complex scalar `c`.
    func scaled(by c: Complex) -> [Complex] {
        map { c * $0 }
    }

    /// Every element multiplied by the real scalar `x`.
    func scaled(by x: Double) -> [Complex] {
        map { $0 * x }
    }

    /// The inner product ⟨self|other⟩ = Σ conj(selfᵢ)·otherᵢ. Conjugates the receiver.
    func inner(_ other: [Complex]) -> Complex {
        precondition(count == other.count, "Vector lengths must match")
        var sum = Complex.zero
        for i in indices { sum = sum + self[i].conjugate * other[i] }
        return sum
    }

    /// Σ |aᵢ|²
    var normSquared: Double {
        reduce(0.0) { $0 + $1.magnitudeSquared }
    }

    /// The Euclidean norm √⟨self|self⟩.
    var norm: Double {
        normSquared.squareRoot()
    }

    /// The vector divided by its norm. The norm must be nonzero.
    func normalized() -> [Complex] {
        let n = norm
        precondition(n > 0, "Cannot normalize a zero vector")
        return scaled(by: 1.0 / n)
    }
}
