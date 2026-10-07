//
//  Swap.swift
//  SwiftQiskit
//
//  SWAP gate: exchanges the states of two qubits — a permutation of the computational
//  basis that swaps the two bits. Equals CNOT(a,b) · CNOT(b,a) · CNOT(a,b).
//
//  Matrix form (4x4):
//  | 1  0  0  0 |
//  | 0  0  1  0 |
//  | 0  1  0  0 |
//  | 0  0  0  1 |
//

import Foundation

public enum SwapGate {

    /// SWAP matrix (2 qubits)
    public static let matrix: Matrix = matrix(qubits: 2, q0: 0, q1: 1)

    /// Full 2ⁿ×2ⁿ SWAP matrix for an n-qubit register.
    /// Qubit 0 is the most-significant (leftmost) bit.
    public static func matrix(qubits: Int, q0: Int, q1: Int) -> Matrix {
        precondition(qubits >= 2, "SWAP needs at least 2 qubits")
        precondition(q0 >= 0 && q0 < qubits, "Qubit out of range")
        precondition(q1 >= 0 && q1 < qubits, "Qubit out of range")
        precondition(q0 != q1, "SWAP qubits must differ")

        let bit0 = 1 << (qubits - 1 - q0)
        let bit1 = 1 << (qubits - 1 - q1)

        return Matrix.permutation(size: 1 << qubits) { col in
            let a = (col & bit0) != 0
            let b = (col & bit1) != 0
            return a == b ? col : col ^ bit0 ^ bit1
        }
    }
}
