//
//  ParameterShift.swift
//  SwiftQiskit
//
//  The parameter-shift gradient rule and a minimal gradient-descent optimizer for
//  variational (VQE-style) circuits.
//

import Foundation

/// Namespace for the parameter-shift gradient rule, generalized to any number of
/// parameters and to any real-valued cost closure — the same rule page `18VQE` derives
/// for its one-parameter ansatz, promoted to Core.
public enum ParameterShift {

    /// The parameter-shift gradient of `cost` at `parameters`: for each parameter `k`,
    /// `[cost(θ + shift·eₖ) − cost(θ − shift·eₖ)] / (2·sin(shift))`. Exact — not a finite-
    /// difference approximation — whenever every parameter enters `cost` as the angle of a
    /// single `exp(-iθP/2)` rotation, which is the shape of every parameterized
    /// `QuantumCircuit` gate (`rx`/`ry`/`rz`/`rzz`/`rxx`/`ryy`/`pauliRotation`). The default
    /// `shift = π/2` makes the divisor 1, matching the textbook rule
    /// `[cost(θ+π/2) − cost(θ−π/2)] / 2`.
    ///
    /// `cost` may be an exact expectation value (`Hamiltonian.expectation`) or a
    /// shot-based one (`QuantumCircuit.measureExpectation`) — the rule itself doesn't care,
    /// only the caller's choice of `cost` does.
    public static func gradient(
        at parameters: [Double],
        shift: Double = .pi / 2,
        _ cost: ([Double]) -> Double
    ) -> [Double] {
        precondition(!parameters.isEmpty, "Must supply at least one parameter")
        let divisor = 2 * sin(shift)
        precondition(divisor != 0, "shift must not be a multiple of π")

        return parameters.indices.map { k in
            var plus = parameters
            var minus = parameters
            plus[k] += shift
            minus[k] -= shift
            return (cost(plus) - cost(minus)) / divisor
        }
    }

    /// Convenience overload for the common VQE shape: the exact expectation value
    /// `hamiltonian.expectation(ansatz(θ).run())` as the cost, differentiated via the rule
    /// above.
    public static func gradient(
        of hamiltonian: Hamiltonian,
        at parameters: [Double],
        shift: Double = .pi / 2,
        ansatz: ([Double]) -> QuantumCircuit
    ) -> [Double] {
        gradient(at: parameters, shift: shift) { theta in
            hamiltonian.expectation(ansatz(theta).run())
        }
    }
}

/// A minimal gradient-descent optimizer — no line search, no momentum, no
/// COBYLA/Nelder-Mead — sufficient for the small, smooth landscapes a VQE-style ansatz
/// produces (page `18VQE`'s one-parameter toy problem converges in ~10 steps).
public enum GradientDescent {

    /// The outcome of a `minimize` run.
    public struct Result {
        /// The final parameter vector.
        public let parameters: [Double]
        /// `cost(parameters)` at the final parameter vector — the last entry of `history`.
        public let value: Double
        /// `cost` evaluated at every visited parameter vector, starting with `initial`.
        public let history: [Double]
        /// Every visited parameter vector, starting with `initial` — `parameterHistory[i]`
        /// is the point `history[i]` was evaluated at, so zipping the two gives the full
        /// optimization trajectory (e.g. for a landscape/descent-path chart).
        public let parameterHistory: [[Double]]
        /// Number of gradient steps actually taken.
        public let iterations: Int
        /// Whether the gradient norm dropped below `tolerance` before `maxIterations`.
        public let converged: Bool
    }

    /// Minimizes `cost` starting from `initial`, taking a fixed-size step of
    /// `learningRate · gradient` each iteration until the gradient's Euclidean norm drops
    /// below `tolerance` or `maxIterations` is reached. `gradient` defaults to
    /// `ParameterShift.gradient(at:_:)` applied to `cost` itself.
    public static func minimize(
        initial: [Double],
        learningRate: Double = 0.1,
        maxIterations: Int = 200,
        tolerance: Double = 1e-10,
        cost: @escaping ([Double]) -> Double,
        gradient: (([Double]) -> [Double])? = nil
    ) -> Result {
        precondition(!initial.isEmpty, "Must supply at least one parameter")
        precondition(learningRate > 0, "learningRate must be positive")
        precondition(maxIterations > 0, "maxIterations must be positive")

        let grad = gradient ?? { ParameterShift.gradient(at: $0, cost) }

        var parameters = initial
        var history: [Double] = [cost(parameters)]
        var parameterHistory: [[Double]] = [parameters]
        var iterations = 0
        var converged = false

        while iterations < maxIterations {
            let g = grad(parameters)
            let norm = sqrt(g.reduce(0.0) { $0 + $1 * $1 })
            if norm < tolerance {
                converged = true
                break
            }
            for k in parameters.indices {
                parameters[k] -= learningRate * g[k]
            }
            history.append(cost(parameters))
            parameterHistory.append(parameters)
            iterations += 1
        }

        return Result(
            parameters: parameters,
            value: history.last!,
            history: history,
            parameterHistory: parameterHistory,
            iterations: iterations,
            converged: converged
        )
    }
}
