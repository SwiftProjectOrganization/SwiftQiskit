//
//  ControlledZ.swift
//  SwiftQiskit
//
//  Controlled-Z gate (CZ): flips the sign of the |11⟩ component.
//
//  CZ is symmetric in its two qubits — either may be called the control — and equals
//  H(target) · CNOT · H(target).
//
//  Matrix form (4x4):
//  | 1  0  0  0 |
//  | 0  1  0  0 |
//  | 0  0  1  0 |
//  | 0  0  0 -1 |
//

import Foundation

public enum ControlledZGate {

    /// CZ matrix (2 qubits)
    public static let matrix: Matrix = {
        var m = Matrix.identity(size: 4)
        m[3, 3] = Complex(-1, 0)
        return m
    }()

    /// Full 2ⁿ×2ⁿ CZ matrix for an n-qubit register.
    /// Qubit 0 is the most-significant (leftmost) bit.
    public static func matrix(qubits: Int, control: Int, target: Int) -> Matrix {
        precondition(qubits >= 2, "CZ needs at least 2 qubits")
        precondition(control >= 0 && control < qubits, "Control qubit out of range")
        precondition(target >= 0 && target < qubits, "Target qubit out of range")
        precondition(control != target, "Control and target must differ")
        return MultiControlledZGate.matrix(qubits: qubits, controls: [control], target: target)
    }
}
