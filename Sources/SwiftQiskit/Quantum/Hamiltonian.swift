//
//  Hamiltonian.swift
//  SwiftQiskit
//
//  A qubit Hamiltonian: a weighted sum of `PauliString` terms.
//

import Foundation

/// A qubit Hamiltonian `H = Σᵢ termᵢ`, each term a `PauliString`. Replaces the entrywise
/// "build a matrix, then add coefficient·term to it index by index" idiom that page
/// `18VQE` (and the app's VQE/Trotter chapters) hand-roll for an H₂-style Hamiltonian.
///
/// Terms are kept as a plain list — no merging of duplicate labels, no grouping into
/// commuting layers. Grouping belongs to a future `trotterCircuit` builder, not here.
public struct Hamiltonian: Equatable {

    /// The Pauli terms summed to form this Hamiltonian. All must act on the same number
    /// of qubits.
    public let terms: [PauliString]

    /// - Parameter terms: at least one `PauliString`, all acting on the same number of qubits.
    public init(_ terms: [PauliString]) {
        precondition(!terms.isEmpty, "Hamiltonian must have at least one term")
        let n = terms[0].qubits
        precondition(terms.allSatisfy { $0.qubits == n },
                     "All terms must act on the same number of qubits")
        self.terms = terms
    }

    /// Number of qubits this Hamiltonian acts on.
    public var qubits: Int {
        terms[0].qubits
    }

    /// The dense `2ⁿ×2ⁿ` matrix Σᵢ termᵢ.matrix.
    public var matrix: Matrix {
        terms.dropFirst().reduce(terms[0].matrix) { $0 + $1.matrix }
    }

    /// Expectation value `⟨ψ|H|ψ⟩ = Σᵢ ⟨ψ|termᵢ|ψ⟩` against `state`.
    public func expectation(_ state: StateVector) -> Double {
        terms.reduce(0.0) { $0 + $1.expectation(state) }
    }

    /// A fresh `QuantumCircuit` implementing Trotterized time evolution
    /// `exp(-i·self·time)` via `QuantumCircuit.evolve(_:time:steps:order:)`.
    public func trotterCircuit(time: Double, steps: Int, order: Int = 1) -> QuantumCircuit {
        let circuit = QuantumCircuit(qubits: qubits)
        circuit.evolve(self, time: time, steps: steps, order: order)
        return circuit
    }
}
