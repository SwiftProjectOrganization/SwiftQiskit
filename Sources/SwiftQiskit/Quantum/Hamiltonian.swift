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
    /// `exp(-i·self·time)` via `QuantumCircuit.evolve(_:time:steps:order:)`. `evolve` applies
    /// `terms` in the order this `Hamiltonian` lists them — reorder via `commutingGroups()`
    /// first (`Hamiltonian(hamiltonian.commutingGroups().flatMap { $0 })`) if a grouped
    /// layering is wanted; there is no automatic grouping here.
    public func trotterCircuit(time: Double, steps: Int, order: Int = 1) -> QuantumCircuit {
        let circuit = QuantumCircuit(qubits: qubits)
        circuit.evolve(self, time: time, steps: steps, order: order)
        return circuit
    }

    /// Partitions `terms` into groups where every pair within a group is *qubit-wise
    /// commuting* (`PauliString.isQubitWiseCommuting(with:)`) — the condition
    /// `QuantumCircuit.measureExpectation(of:shots:)` uses to measure every term in a group
    /// from a single shared shot batch, and that a caller can use to co-locate commuting
    /// terms before `evolve`/`trotterCircuit` (see there).
    ///
    /// Built via a greedy heuristic (the same strategy Qiskit's default
    /// `group_commuting` uses): each term joins the *first* existing group every one of
    /// whose members it's QWC-compatible with, or starts a new group if none fits.
    /// Deterministic — depends only on the order `terms` lists them in — but *not*
    /// guaranteed to minimize the number of groups; finding the true minimum is graph
    /// coloring, NP-hard in general, and not needed for the sizes this library deals with.
    ///
    /// Example — the six-term H₂ Hamiltonian page `18VQE` builds (`II, ZI, IZ, ZZ, YY, XX`)
    /// groups into exactly three: `{II, ZI, IZ, ZZ}` (a shared Z,Z basis), `{YY}`, `{XX}` —
    /// three measurement settings instead of six.
    public func commutingGroups() -> [[PauliString]] {
        var groups: [[PauliString]] = []
        for term in terms {
            if let index = groups.firstIndex(where: { group in
                group.allSatisfy { $0.isQubitWiseCommuting(with: term) }
            }) {
                groups[index].append(term)
            } else {
                groups.append([term])
            }
        }
        return groups
    }
}
