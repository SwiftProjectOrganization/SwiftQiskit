//
//  PauliBasis.swift
//  SwiftQiskit
//
//  A single-qubit Pauli measurement basis: X, Y, or Z.
//

import Foundation

/// The basis a single qubit is measured in: an eigenbasis of the Pauli X, Y, or Z
/// operator. `Character` raw values let a `PauliBasis` interoperate with the plain
/// Pauli-string labels `QuantumCircuit.pauliRotation(_:theta:)` already accepts
/// (`.x.rawValue == "X"`, etc.).
///
/// Design note: a future `PauliString`/`Hamiltonian` type is expected to store
/// `[PauliBasis?]` (one optional label per qubit, `nil` meaning the identity `I`),
/// so this stays the one Pauli-label type shared across tomography, variational, and
/// Hamiltonian-simulation code rather than three near-identical enums.
public enum PauliBasis: Character, CaseIterable {
    case x = "X"
    case y = "Y"
    case z = "Z"
}
