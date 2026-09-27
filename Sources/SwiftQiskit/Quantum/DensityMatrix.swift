//
//  DensityMatrix.swift
//  SwiftQiskit
//
//  A mixed-state density matrix ρ, the open-systems generalization of a pure
//  `StateVector`. Built on the existing `Ket * Bra` outer product and `Matrix`
//  arithmetic — no new linear-algebra primitives beyond a small eigenvalue solver
//  used only by `vonNeumannEntropy`/`eigenvalues` for a system bigger than one qubit.
//

import Foundation

/// A density matrix ρ on an n-qubit register (`matrix.rows == matrix.cols == 2ⁿ`).
/// Every public initializer validates that `matrix` is square, `2ⁿ`-sized, (approximately)
/// Hermitian, and has trace ≈ 1 — the three defining properties of a physical density
/// matrix — rather than trusting the caller.
public struct DensityMatrix: Equatable {

    /// The underlying `2ⁿ×2ⁿ` matrix.
    public let matrix: Matrix

    /// Tolerance used to validate Hermiticity/trace on construction, and by
    /// `partialTrace`/`apply` on their (mathematically exact, but floating-point-noisy)
    /// results.
    private static let tolerance = 1e-6

    /// ρ = |ψ⟩⟨ψ| for a pure state, via the existing Dirac outer product.
    public init(_ state: StateVector) {
        self.matrix = state * (state†)
    }

    /// A classical mixture Σᵢ pᵢ|ψᵢ⟩⟨ψᵢ| of pure states, all on the same number of qubits.
    /// `probability` values must be non-negative and sum to ≈ 1.
    public init(mixture: [(probability: Double, state: StateVector)]) {
        precondition(!mixture.isEmpty, "Mixture must have at least one component")
        let dimension = mixture[0].state.dimension
        precondition(mixture.allSatisfy { $0.state.dimension == dimension },
                     "All states in a mixture must have the same dimension")
        precondition(mixture.allSatisfy { $0.probability >= -1e-12 },
                     "Mixture probabilities must be non-negative")
        let totalProbability = mixture.reduce(0.0) { $0 + $1.probability }
        precondition(abs(totalProbability - 1.0) < 1e-9,
                     "Mixture probabilities must sum to 1")

        var accumulated = Matrix(rows: dimension, cols: dimension)
        for (probability, state) in mixture {
            accumulated = accumulated + (state * (state†)) * probability
        }
        self.init(matrix: accumulated)
    }

    /// Wraps a raw `2ⁿ×2ⁿ` matrix as a density matrix, checking it's square, a power-of-two
    /// size, (approximately) Hermitian, and trace ≈ 1.
    public init(matrix: Matrix) {
        precondition(matrix.rows == matrix.cols, "Density matrix must be square")
        let n = matrix.rows
        precondition(n > 0 && (n & (n - 1)) == 0,
                     "Density matrix dimension must be a power of two")

        let residual = matrix.adjoint - matrix
        var maxResidual = 0.0
        for i in 0..<n {
            for j in 0..<n {
                maxResidual = max(maxResidual, residual[i, j].magnitude)
            }
        }
        precondition(maxResidual < DensityMatrix.tolerance, "Density matrix must be Hermitian")
        precondition(abs(matrix.trace.real - 1.0) < DensityMatrix.tolerance,
                     "Density matrix must have trace 1")

        self.matrix = matrix
    }

    /// Number of qubits (`matrix.rows == 2^qubits`).
    public var qubits: Int {
        matrix.rows.trailingZeroBitCount
    }
}

// MARK: - Purity, Probabilities, Expectation

public extension DensityMatrix {

    /// Tr(ρ²) — 1 for a pure state, 1/2ⁿ for the maximally mixed state on n qubits.
    var purity: Double {
        (matrix * matrix).trace.real
    }

    /// The diagonal of ρ (real parts): the probability of each basis state.
    var probabilities: [Double] {
        (0..<matrix.rows).map { matrix[$0, $0].real }
    }

    /// Expectation value Tr(ρA) of an observable `A`. As with
    /// `StateVector.expectation(_:)`, only the real part is returned — exact for a
    /// Hermitian `A`.
    func expectation(_ observable: Matrix) -> Double {
        (matrix * observable).trace.real
    }

    /// Fidelity ⟨ψ|ρ|ψ⟩ of this mixed state against a pure state `state`.
    func fidelity(to state: StateVector) -> Double {
        precondition(state.dimension == matrix.rows,
                     "State dimension must match density matrix dimension")
        return (state† * matrix * state).real
    }
}

// MARK: - Applying Unitaries

public extension DensityMatrix {

    /// UρU† — the density-matrix analogue of `StateVector.apply(_:)`.
    func apply(_ unitary: Matrix) -> DensityMatrix {
        precondition(unitary.cols == matrix.rows,
                     "Unitary dimension must match density matrix dimension")
        return DensityMatrix(matrix: unitary * matrix * unitary.adjoint)
    }
}

// MARK: - Partial Trace

public extension DensityMatrix {

    /// Traces out every qubit *not* listed in `qubits`, returning the reduced density
    /// matrix on the kept qubits. As with `StateVector.marginalProbabilities(over:)`, the
    /// kept qubits appear **in the order given** (not necessarily ascending index) in the
    /// result's basis ordering.
    func partialTrace(keeping qubits: [Int]) -> DensityMatrix {
        let n = self.qubits
        precondition(!qubits.isEmpty, "Must keep at least one qubit")
        precondition(Set(qubits).count == qubits.count, "Qubit indices must be distinct")
        precondition(qubits.allSatisfy { $0 >= 0 && $0 < n }, "Qubit index out of range")

        let traced = (0..<n).filter { !qubits.contains($0) }
        let keptCount = qubits.count
        let keptDimension = 1 << keptCount
        let tracedDimension = 1 << traced.count

        // Reassembles a full n-bit basis index from the kept qubits' bits (per `qubits`
        // order) and the traced-out qubits' bits (in ascending qubit order).
        func fullIndex(keptBits: Int, tracedBits: Int) -> Int {
            var index = 0
            for (position, qubit) in qubits.enumerated() {
                let bit = (keptBits >> (keptCount - 1 - position)) & 1
                index |= bit << (n - 1 - qubit)
            }
            for (position, qubit) in traced.enumerated() {
                let bit = (tracedBits >> (traced.count - 1 - position)) & 1
                index |= bit << (n - 1 - qubit)
            }
            return index
        }

        var reduced = Matrix(rows: keptDimension, cols: keptDimension)
        for row in 0..<keptDimension {
            for col in 0..<keptDimension {
                var sum = Complex.zero
                for t in 0..<tracedDimension {
                    let fullRow = fullIndex(keptBits: row, tracedBits: t)
                    let fullCol = fullIndex(keptBits: col, tracedBits: t)
                    sum = sum + matrix[fullRow, fullCol]
                }
                reduced[row, col] = sum
            }
        }
        return DensityMatrix(matrix: reduced)
    }
}

// MARK: - Bloch Vector

public extension DensityMatrix {

    /// `(Tr(ρX), Tr(ρY), Tr(ρZ))`, `nil` unless this is a single-qubit density matrix.
    /// Unlike a pure state's Bloch vector, `|r|` need not be 1 — it shrinks toward the
    /// origin as the state becomes more mixed.
    var blochVector: (x: Double, y: Double, z: Double)? {
        guard matrix.rows == 2 else { return nil }
        return (
            expectation(PauliXGate.matrix),
            expectation(PauliYGate.matrix),
            expectation(PauliZGate.matrix)
        )
    }
}

// MARK: - Eigenvalues & von Neumann Entropy

public extension DensityMatrix {

    /// The (real, non-negative) eigenvalues of ρ, ascending. Computed via a real-symmetric
    /// embedding of the Hermitian matrix (see `jacobiEigenvalues` below) rather than a
    /// complex eigensolver.
    var eigenvalues: [Double] {
        let n = matrix.rows
        var embedded = Array(repeating: Array(repeating: 0.0, count: 2 * n), count: 2 * n)
        for i in 0..<n {
            for j in 0..<n {
                let entry = matrix[i, j]
                embedded[i][j] = entry.real
                embedded[i][j + n] = -entry.imag
                embedded[i + n][j] = entry.imag
                embedded[i + n][j + n] = entry.real
            }
        }

        // Every eigenvalue of the n×n Hermitian matrix appears twice in the 2n×2n real
        // symmetric embedding's spectrum; take every other value once sorted.
        let doubled = jacobiEigenvalues(embedded).sorted()
        var result: [Double] = []
        var index = 0
        while index < doubled.count {
            result.append(doubled[index])
            index += 2
        }
        return result
    }

    /// Von Neumann entropy S(ρ) = −Σᵢ λᵢ log₂λᵢ, in bits. Uses the closed form from the
    /// Bloch vector's magnitude for a single qubit (avoiding the Jacobi solver on the
    /// common case); falls back to `eigenvalues` otherwise.
    var vonNeumannEntropy: Double {
        if let bloch = blochVector {
            let magnitude = (bloch.x * bloch.x + bloch.y * bloch.y + bloch.z * bloch.z).squareRoot()
            let lambda1 = (1 + magnitude) / 2
            let lambda2 = (1 - magnitude) / 2
            return -(plogp(lambda1) + plogp(lambda2))
        }
        return -eigenvalues.reduce(0.0) { $0 + plogp($1) }
    }
}

/// `λ·log₂λ`, treating `λ ≤ 0` (including floating-point noise just below zero) as
/// contributing nothing — the standard convention for entropy sums.
private func plogp(_ lambda: Double) -> Double {
    lambda <= 1e-15 ? 0 : lambda * log2(lambda)
}

/// Eigenvalues of a real symmetric matrix via the classical cyclic Jacobi eigenvalue
/// algorithm. Internal to `DensityMatrix.eigenvalues`'s real-symmetric embedding of a
/// Hermitian matrix — not a general-purpose linear-algebra routine, and not exposed
/// publicly. Adequate for the small (≤ a few dozen rows) matrices a qubit-count register
/// produces; not tuned for performance or numerical edge cases beyond that.
private func jacobiEigenvalues(_ input: [[Double]], sweeps: Int = 100, tolerance: Double = 1e-12) -> [Double] {
    let n = input.count
    var a = input

    for _ in 0..<sweeps {
        var offDiagonalNormSquared = 0.0
        for p in 0..<n {
            for q in (p + 1)..<n {
                offDiagonalNormSquared += a[p][q] * a[p][q]
            }
        }
        if offDiagonalNormSquared.squareRoot() < tolerance { break }

        for p in 0..<n {
            for q in (p + 1)..<n {
                guard abs(a[p][q]) > tolerance else { continue }

                let theta = (a[q][q] - a[p][p]) / (2 * a[p][q])
                let t = (theta >= 0 ? 1.0 : -1.0) / (abs(theta) + (theta * theta + 1).squareRoot())
                let c = 1 / (t * t + 1).squareRoot()
                let s = t * c

                let app = a[p][p], aqq = a[q][q], apq = a[p][q]
                a[p][p] = c * c * app - 2 * s * c * apq + s * s * aqq
                a[q][q] = s * s * app + 2 * s * c * apq + c * c * aqq
                a[p][q] = 0
                a[q][p] = 0

                for i in 0..<n where i != p && i != q {
                    let aip = a[i][p], aiq = a[i][q]
                    a[i][p] = c * aip - s * aiq
                    a[p][i] = a[i][p]
                    a[i][q] = s * aip + c * aiq
                    a[q][i] = a[i][q]
                }
            }
        }
    }

    return (0..<n).map { a[$0][$0] }
}
