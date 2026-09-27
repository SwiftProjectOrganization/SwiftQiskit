//
//  SimulationResult.swift
//  SwiftQiskit
//
//  Represents measurement results from a quantum circuit
//

import Foundation

public struct SimulationResult {

    public let shots: Int
    public let counts: [String: Int]

    /// Returns counts sorted by state (binary ascending)
    public var sortedCounts: [(state: String, count: Int)] {
        counts
            .sorted { $0.key < $1.key }
            .map { (state: $0.key, count: $0.value) }
    }
}

// MARK: - Marginals & Parity
public extension SimulationResult {

    /// Number of qubits, read from the width of the observed keys (all must agree).
    private var qubitCount: Int {
        let widths = Set(counts.keys.map(\.count))
        precondition(widths.count <= 1, "All counts keys must have the same length")
        return widths.first ?? 0
    }

    /// Shot counts grouped by a subset of qubits, summing out every other qubit. The
    /// returned keys are the bits of `qubits`, **in the order given**, zero-padded to
    /// `qubits.count` characters. Only observed keys appear, the same as `counts`.
    func marginalCounts(over qubits: [Int]) -> [String: Int] {
        let n = qubitCount
        precondition(!qubits.isEmpty, "Must select at least one qubit")
        precondition(Set(qubits).count == qubits.count, "Qubit indices must be distinct")
        precondition(qubits.allSatisfy { $0 >= 0 && $0 < n }, "Qubit index out of range")

        var marginal: [String: Int] = [:]
        for (state, count) in counts {
            let chars = Array(state)
            let bits = String(qubits.map { chars[$0] })
            marginal[bits, default: 0] += count
        }
        return marginal
    }

    /// The ±1 parity-product average over `counts`, one qubit position per factor
    /// (0 → +1, 1 → −1): `Σ counts · (−1)^(number of 1 bits among `qubits`) / shots`.
    /// This is the shot-based estimator for a Pauli-Z-string expectation value such as
    /// ⟨Z⊗Z⟩ across the listed qubits.
    func parityExpectation(qubits: [Int]) -> Double {
        let n = qubitCount
        precondition(!qubits.isEmpty, "Must select at least one qubit")
        precondition(qubits.allSatisfy { $0 >= 0 && $0 < n }, "Qubit index out of range")

        var sum = 0.0
        for (state, count) in counts {
            let chars = Array(state)
            let ones = qubits.filter { chars[$0] == "1" }.count
            let parity = (ones % 2 == 0) ? 1.0 : -1.0
            sum += parity * Double(count)
        }
        return sum / Double(shots)
    }
}
