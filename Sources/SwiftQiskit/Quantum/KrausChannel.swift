//
//  KrausChannel.swift
//  SwiftQiskit
//
//  A quantum channel ρ' = Σᵢ KᵢρKᵢ†, given by its Kraus operators.
//

import Foundation

/// A quantum channel specified by its Kraus operators. All operators must be square and
/// the same size; a *trace-preserving* channel additionally satisfies Σᵢ Kᵢ†Kᵢ = I, checked
/// by `isTracePreserving(tolerance:)` rather than assumed.
public struct KrausChannel {

    /// The Kraus operators `Kᵢ`, all square and the same size.
    public let operators: [Matrix]

    /// - Parameter operators: at least one square matrix, all the same size.
    public init(operators: [Matrix]) {
        precondition(!operators.isEmpty, "Kraus channel must have at least one operator")
        let n = operators[0].rows
        precondition(operators.allSatisfy { $0.rows == n && $0.cols == n },
                     "All Kraus operators must be square and the same size")
        self.operators = operators
    }

    /// Whether Σᵢ Kᵢ†Kᵢ ≈ I, entrywise within `tolerance` — the condition for this channel
    /// to preserve trace (probability). Mirrors `Matrix.isUnitary(tolerance:)`'s style.
    public func isTracePreserving(tolerance: Double = 1e-10) -> Bool {
        let n = operators[0].rows
        var sum = Matrix(rows: n, cols: n)
        for k in operators { sum = sum + (k.adjoint * k) }

        let identity = Matrix.identity(size: n)
        for i in 0..<n {
            for j in 0..<n {
                if (sum[i, j] - identity[i, j]).magnitude >= tolerance { return false }
            }
        }
        return true
    }
}

// MARK: - Applying the Channel

public extension KrausChannel {

    /// Applies this channel to the whole register: ρ' = Σᵢ KᵢρKᵢ†. The channel's operator
    /// size must match `rho`'s dimension exactly (use `apply(to:qubit:)` below to embed a
    /// single-qubit channel onto one qubit of a larger register).
    func apply(to rho: DensityMatrix) -> DensityMatrix {
        precondition(operators[0].rows == rho.matrix.rows,
                     "Kraus operator dimension must match density matrix dimension")

        var accumulated = Matrix(rows: rho.matrix.rows, cols: rho.matrix.rows)
        for k in operators {
            accumulated = accumulated + (k * rho.matrix * k.adjoint)
        }
        return DensityMatrix(matrix: accumulated)
    }

    /// Embeds a single-qubit (2×2) channel onto one `qubit` of an n-qubit `rho`, the same
    /// idiom `CNOTGate.matrix(qubits:control:target:)` uses for a 2×2 gate: each Kraus
    /// operator is tensored with identity on every other qubit via
    /// `embedSingleQubitGate`, then applied to the full register.
    func apply(to rho: DensityMatrix, qubit: Int) -> DensityMatrix {
        precondition(operators[0].rows == 2,
                     "Per-qubit application requires a single-qubit (2×2) channel")
        let n = rho.qubits
        precondition(qubit >= 0 && qubit < n, "Qubit index out of range")

        var accumulated = Matrix(rows: rho.matrix.rows, cols: rho.matrix.rows)
        for k in operators {
            let embedded = embedSingleQubitGate(k, qubits: n, target: qubit)
            accumulated = accumulated + (embedded * rho.matrix * embedded.adjoint)
        }
        return DensityMatrix(matrix: accumulated)
    }
}

// MARK: - Standard Channels

public extension KrausChannel {

    /// Flips the qubit (applies X) with probability `p`.
    static func bitFlip(_ p: Double) -> KrausChannel {
        precondition(p >= 0 && p <= 1, "Probability must be in [0, 1]")
        return KrausChannel(operators: [
            Matrix.identity(size: 2) * (1 - p).squareRoot(),
            PauliXGate.matrix * p.squareRoot()
        ])
    }

    /// Applies Z (a relative phase flip) with probability `p`.
    static func phaseFlip(_ p: Double) -> KrausChannel {
        precondition(p >= 0 && p <= 1, "Probability must be in [0, 1]")
        return KrausChannel(operators: [
            Matrix.identity(size: 2) * (1 - p).squareRoot(),
            PauliZGate.matrix * p.squareRoot()
        ])
    }

    /// Replaces the qubit with the maximally mixed state with probability `p` (applies X,
    /// Y, or Z with equal probability `p/4` each, leaving it untouched with probability
    /// `1 - 3p/4`).
    static func depolarizing(_ p: Double) -> KrausChannel {
        precondition(p >= 0 && p <= 1, "Probability must be in [0, 1]")
        return KrausChannel(operators: [
            Matrix.identity(size: 2) * (1 - 0.75 * p).squareRoot(),
            PauliXGate.matrix * (p / 4).squareRoot(),
            PauliYGate.matrix * (p / 4).squareRoot(),
            PauliZGate.matrix * (p / 4).squareRoot()
        ])
    }

    /// T1-style energy relaxation toward |0⟩ with decay probability `gamma`: shrinks x/y by
    /// `√(1-γ)` and pulls z toward +1, moving the Bloch vector *inside* the sphere.
    static func amplitudeDamping(_ gamma: Double) -> KrausChannel {
        precondition(gamma >= 0 && gamma <= 1, "Gamma must be in [0, 1]")
        var k0 = Matrix(rows: 2, cols: 2)
        k0[0, 0] = .one
        k0[1, 1] = Complex((1 - gamma).squareRoot())
        var k1 = Matrix(rows: 2, cols: 2)
        k1[0, 1] = Complex(gamma.squareRoot())
        return KrausChannel(operators: [k0, k1])
    }

    /// T2-style pure dephasing: shrinks x/y by `√(1-λ)` with **no** energy loss (z is left
    /// exactly alone, unlike `amplitudeDamping`).
    static func phaseDamping(_ lambda: Double) -> KrausChannel {
        precondition(lambda >= 0 && lambda <= 1, "Lambda must be in [0, 1]")
        var k0 = Matrix(rows: 2, cols: 2)
        k0[0, 0] = .one
        k0[1, 1] = Complex((1 - lambda).squareRoot())
        var k1 = Matrix(rows: 2, cols: 2)
        k1[1, 1] = Complex(lambda.squareRoot())
        return KrausChannel(operators: [k0, k1])
    }
}
