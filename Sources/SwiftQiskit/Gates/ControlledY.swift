//
//  ControlledY.swift
//  SwiftQiskit
//
//  Controlled-Y gate (CY): applies Pauli-Y to the target when the control is |1⟩.
//  Equals S†(target) · CNOT · S(target).
//
//  Matrix form (4x4, control = qubit 0):
//  | 1  0  0   0 |
//  | 0  1  0   0 |
//  | 0  0  0  -i |
//  | 0  0  i   0 |
//

import Foundation

public enum ControlledYGate {

    /// CY matrix (2 qubits, control = qubit 0, target = qubit 1)
    public static let matrix: Matrix = MultiControlledYGate.matrix(qubits: 2, controls: [0], target: 1)

    /// Full 2ⁿ×2ⁿ CY matrix for an n-qubit register.
    /// Qubit 0 is the most-significant (leftmost) bit.
    public static func matrix(qubits: Int, control: Int, target: Int) -> Matrix {
        precondition(qubits >= 2, "CY needs at least 2 qubits")
        precondition(control >= 0 && control < qubits, "Control qubit out of range")
        precondition(target >= 0 && target < qubits, "Target qubit out of range")
        precondition(control != target, "Control and target must differ")
        return MultiControlledYGate.matrix(qubits: qubits, controls: [control], target: target)
    }
}
