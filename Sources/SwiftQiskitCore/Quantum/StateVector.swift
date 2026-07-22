//
//  StateVector.swift
//  SwiftQiskit
//
//  Represents a quantum state |ψ⟩ as a vector of complex amplitudes.
//  Provides normalization, probability calculation, and measurement.
//
//  Created by Ali on 2025-01-XX.
//

import Foundation

public struct StateVector: Equatable {

    /// Amplitudes of the quantum state
    public private(set) var amplitudes: [Complex]

    // MARK: - Initializers

    /// Initialize with raw amplitudes (will be normalized)
    public init(_ amplitudes: [Complex]) {
        precondition(!amplitudes.isEmpty, "StateVector cannot be empty")
        self.amplitudes = amplitudes
        normalize()
    }

    /// Initialize |0...0⟩ state for given number of qubits
    public init(qubits: Int) {
        precondition(qubits > 0, "Number of qubits must be positive")
        let size = 1 << qubits
        var amps = Array(repeating: Complex.zero, count: size)
        amps[0] = .one
        self.amplitudes = amps
    }

    // MARK: - Properties

    /// Number of basis states (2^n)
    public var dimension: Int {
        amplitudes.count
    }

    /// Squared magnitudes (probabilities)
    public var probabilities: [Double] {
        amplitudes.map { $0.magnitudeSquared }
    }

    // MARK: - Normalization

    /// Ensure the state is normalized (Σ |αᵢ|² = 1)
    public mutating func normalize() {
        let norm = sqrt(amplitudes.reduce(0.0) { $0 + $1.magnitudeSquared })
        precondition(norm > 0, "Cannot normalize a zero state")

        amplitudes = amplitudes.map { $0 * (1.0 / norm) }
    }

    // MARK: - Measurement

    /// Measure the quantum state and collapse it.
    /// - Returns: measured basis index
    public mutating func measure() -> Int {
        let probs = probabilities
        let r = Double.random(in: 0..<1)

        var cumulative = 0.0
        for (index, p) in probs.enumerated() {
            cumulative += p
            if r < cumulative {
                collapse(to: index)
                return index
            }
        }

        // Fallback (numerical safety)
        let lastIndex = probs.count - 1
        collapse(to: lastIndex)
        return lastIndex
    }

    private mutating func collapse(to index: Int) {
        for i in amplitudes.indices {
            amplitudes[i] = (i == index) ? .one : .zero
        }
    }
}

// MARK: - Applying Operators
public extension StateVector {

    /// Apply a matrix operator to the state (|ψ'⟩ = U |ψ⟩)
    mutating func apply(_ matrix: Matrix) {
        precondition(matrix.cols == amplitudes.count,
                     "Matrix dimension must match state vector dimension")

        let newAmps = matrix.multiply(by: amplitudes)
        amplitudes = newAmps
        normalize()
    }
}

// MARK: - Tensor Product
public extension StateVector {

    /// Tensor product |ψ⟩ ⊗ |φ⟩ combining two registers into one.
    /// Qubit 0 is most-significant, so `self` occupies the high-order bits.
    func tensor(_ other: StateVector) -> StateVector {
        var combined = Array(repeating: Complex.zero, count: dimension * other.dimension)
        for i in 0..<dimension {
            for j in 0..<other.dimension {
                combined[i * other.dimension + j] = amplitudes[i] * other.amplitudes[j]
            }
        }
        return StateVector(combined)
    }

    /// Tensor product: `lhs ⊗ rhs`
    static func ⊗ (lhs: StateVector, rhs: StateVector) -> StateVector {
        lhs.tensor(rhs)
    }
}

// MARK: - CustomStringConvertible
extension StateVector: CustomStringConvertible {
    public var description: String {
        amplitudes
            .enumerated()
            .map { "|\(String($0.offset, radix: 2))⟩: \($0.element)" }
            .joined(separator: "\n")
    }
}
// MARK: - Accessing Amplitudes
public extension StateVector {

    /// Access amplitude by basis index (e.g. |00⟩ = 0, |01⟩ = 1)
    subscript(index: Int) -> Complex {
        precondition(index >= 0 && index < amplitudes.count, "State index out of range")
        return amplitudes[index]
    }
}
