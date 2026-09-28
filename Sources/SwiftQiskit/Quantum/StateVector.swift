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

        // Skip rescaling when already normalized: multiplying by 1/norm when
        // norm ≈ 1 only injects rounding error, and skipping it makes the
        // dagger a true involution — (|ψ⟩†)† == |ψ⟩ exactly.
        guard abs(norm - 1.0) > 1e-12 else { return }

        amplitudes = amplitudes.map { $0 * (1.0 / norm) }
    }

    // MARK: - Measurement

    /// Draw one basis-state index from a probability distribution (cumulative-sum sampling).
    /// Shared by `measure()` and `QuantumCircuit.measure(shots:)`, which samples the same
    /// fixed distribution repeatedly instead of collapsing a state.
    static func sampleIndex(from probabilities: [Double]) -> Int {
        let r = Double.random(in: 0..<1)

        var cumulative = 0.0
        for (index, p) in probabilities.enumerated() {
            cumulative += p
            if r < cumulative {
                return index
            }
        }

        // Fallback (numerical safety)
        return probabilities.count - 1
    }

    /// Measure the quantum state and collapse it.
    /// - Returns: measured basis index
    public mutating func measure() -> Int {
        let index = StateVector.sampleIndex(from: probabilities)
        collapse(to: index)
        return index
    }

    private mutating func collapse(to index: Int) {
        for i in amplitudes.indices {
            amplitudes[i] = (i == index) ? .one : .zero
        }
    }
}

// MARK: - Applying Operators
public extension StateVector {

    /// Apply a matrix operator to the state (|ψ'⟩ = U |ψ⟩). A permutation-shaped matrix
    /// (`cx`/`ccx`/`mcx`, or anything built from `Matrix.permutation(size:image:)`) takes an
    /// O(2ⁿ) reindex via `Matrix.permutationImage` instead of the full O(4ⁿ) dense multiply
    /// every other matrix still uses.
    mutating func apply(_ matrix: Matrix) {
        precondition(matrix.cols == amplitudes.count,
                     "Matrix dimension must match state vector dimension")

        if let image = matrix.permutationImage {
            var newAmps = Array(repeating: Complex.zero, count: amplitudes.count)
            for col in amplitudes.indices { newAmps[image[col]] = amplitudes[col] }
            amplitudes = newAmps
        } else {
            amplitudes = matrix.multiply(by: amplitudes)
        }
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

// MARK: - Marginals
public extension StateVector {

    /// Number of qubits in the register (dimension is always 2ⁿ).
    private var qubitCount: Int {
        dimension.trailingZeroBitCount
    }

    /// Marginal probability distribution over a subset of qubits, summing out every other
    /// qubit. The returned keys are the bits of `qubits`, **in the order given** (not
    /// necessarily ascending qubit index), zero-padded to `qubits.count` characters. Every
    /// one of the 2^k possible keys is present, including those with zero probability, so
    /// callers can always subscript the result.
    func marginalProbabilities(over qubits: [Int]) -> [String: Double] {
        let n = qubitCount
        precondition(!qubits.isEmpty, "Must select at least one qubit")
        precondition(Set(qubits).count == qubits.count, "Qubit indices must be distinct")
        precondition(qubits.allSatisfy { $0 >= 0 && $0 < n }, "Qubit index out of range")

        var marginal: [String: Double] = [:]
        for key in 0..<(1 << qubits.count) {
            let binary = String(key, radix: 2).leftPadding(toLength: qubits.count, withPad: "0")
            marginal[binary] = 0.0
        }

        let probs = probabilities
        for index in 0..<dimension {
            var bits = ""
            for qubit in qubits {
                let bit = (index >> (n - 1 - qubit)) & 1
                bits.append(bit == 1 ? "1" : "0")
            }
            marginal[bits]! += probs[index]
        }

        return marginal
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
