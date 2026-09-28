//
//  PauliString.swift
//  SwiftQiskit
//
//  A weighted Pauli tensor product: one Pauli label per qubit (or identity),
//  scaled by a real coefficient — the building block of `Hamiltonian`.
//

import Foundation

/// A single term of a qubit Hamiltonian: `coefficient · P₀ ⊗ P₁ ⊗ … ⊗ Pₙ₋₁`, where each
/// `Pᵢ` is `I` (`labels[i] == nil`) or a Pauli matrix (`labels[i]` gives which one). Qubit 0
/// is the most-significant (leftmost) factor, matching the rest of Core.
///
/// This is the `[PauliBasis?]` type the design note in `PauliBasis.swift` anticipated —
/// shared by tomography (`PauliBasis`/`rotateToZ`), variational (`Hamiltonian`,
/// `measureExpectation`), and Hamiltonian-simulation code (`pauliRotation`'s own string
/// labels, via `label` below) rather than three near-identical types.
public struct PauliString: Equatable, Hashable {

    /// One label per qubit; `nil` means the identity `I`.
    public let labels: [PauliBasis?]

    /// Real scalar multiplying the tensor product. Kept real so `matrix` is always
    /// Hermitian, matching a genuine Hamiltonian term.
    public let coefficient: Double

    /// - Parameters:
    ///   - labels: one entry per qubit, `nil` for `I`. Must be non-empty.
    ///   - coefficient: real scalar multiplying the tensor product (defaults to 1).
    public init(labels: [PauliBasis?], coefficient: Double = 1) {
        precondition(!labels.isEmpty, "PauliString must act on at least one qubit")
        self.labels = labels
        self.coefficient = coefficient
    }

    /// Builds a `PauliString` from a plain label string (e.g. `"XIZ"`, one character per
    /// qubit, `I`/`X`/`Y`/`Z` only) — the same string shape
    /// `QuantumCircuit.pauliRotation(_:theta:)` accepts.
    public init(_ label: String, coefficient: Double = 1) {
        precondition(!label.isEmpty, "PauliString label must not be empty")
        let chars = Array(label)
        precondition(chars.allSatisfy { "IXYZ".contains($0) },
                     "PauliString label may only contain I, X, Y, Z")
        self.init(labels: chars.map { PauliBasis(rawValue: $0) }, coefficient: coefficient)
    }

    /// Number of qubits this term acts on.
    public var qubits: Int {
        labels.count
    }

    /// Indices of every non-identity qubit.
    public var activeQubits: [Int] {
        labels.indices.filter { labels[$0] != nil }
    }

    /// The label string this term was built from (or would be), `I` standing in for `nil`
    /// — round-trips through `init(_:coefficient:)` and feeds `pauliRotation(_:theta:)`.
    public var label: String {
        String(labels.map { $0?.rawValue ?? "I" })
    }

    /// The dense `2ⁿ×2ⁿ` matrix `coefficient · P₀ ⊗ P₁ ⊗ … ⊗ Pₙ₋₁`.
    public var matrix: Matrix {
        var result: Matrix? = nil
        for label in labels {
            let factor = PauliString.matrix(for: label)
            result = result.map { $0 ⊗ factor } ?? factor
        }
        return result! * coefficient
    }

    /// Expectation value `coefficient · ⟨ψ|P₀⊗P₁⊗…|ψ⟩` of this term against `state`, via
    /// `StateVector.expectation(_:)`. Traps if `state`'s dimension doesn't match `qubits`.
    public func expectation(_ state: StateVector) -> Double {
        precondition(state.dimension == 1 << qubits,
                     "State dimension must match the Pauli string's qubit count")
        return state.expectation(matrix)
    }

    /// Whether `self` and `other` are *qubit-wise commuting* (QWC): on every qubit, their
    /// labels either agree or at least one is `I`. Stricter than literal Pauli
    /// commutativity (which only needs an *even* number of disagreeing qubits — e.g. `XI`
    /// and `IY` commute in that sense, since they share no qubit, but so would `XY` and
    /// `YX`, which don't reduce to a single shared basis anywhere) — QWC is the condition
    /// that actually matters for `Hamiltonian.commutingGroups()`: two QWC-compatible terms
    /// share one well-defined per-qubit measurement/rotation basis, since wherever both
    /// specify a label they specify the *same* one.
    ///
    /// Traps if `qubits != other.qubits`.
    public func isQubitWiseCommuting(with other: PauliString) -> Bool {
        precondition(qubits == other.qubits, "Both Pauli strings must act on the same number of qubits")
        return zip(labels, other.labels).allSatisfy { a, b in
            a == nil || b == nil || a == b
        }
    }

    /// The 2×2 matrix for one label: `I` (`nil`) or the corresponding Pauli gate.
    private static func matrix(for label: PauliBasis?) -> Matrix {
        switch label {
        case nil: return Matrix.identity(size: 2)
        case .x: return PauliXGate.matrix
        case .y: return PauliYGate.matrix
        case .z: return PauliZGate.matrix
        }
    }
}
