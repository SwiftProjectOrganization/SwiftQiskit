//
//  CNOT.swift
//  SwiftQiskit
//
//  Controlled-NOT gate (CNOT)
//  Two-qubit gate used to create entanglement.
//
//  General form: on an n-qubit register, CNOT(control, target) flips the
//  target bit of every basis state whose control bit is 1 — a permutation
//  of the computational basis.
//
//  Two-qubit truth table (control = qubit 0, target = qubit 1):
//  |00⟩ → |00⟩
//  |01⟩ → |01⟩
//  |10⟩ → |11⟩
//  |11⟩ → |10⟩
//
//  Matrix form (4x4):
//  | 1  0  0  0 |
//  | 0  1  0  0 |
//  | 0  0  0  1 |
//  | 0  0  1  0 |
//
//  Created by Ali on 2025-01-XX.
//

import Foundation

public enum CNOTGate {

    /// CNOT matrix (control qubit = 0, target qubit = 1)
    public static let matrix: Matrix = {
        Matrix([
            [Complex.one,  Complex.zero, Complex.zero, Complex.zero],
            [Complex.zero, Complex.one,  Complex.zero, Complex.zero],
            [Complex.zero, Complex.zero, Complex.zero, Complex.one ],
            [Complex.zero, Complex.zero, Complex.one,  Complex.zero]
        ])
    }()

    /// Full 2ⁿ×2ⁿ CNOT matrix for an n-qubit register.
    /// Qubit 0 is the most-significant (leftmost) bit.
    public static func matrix(qubits: Int, control: Int, target: Int) -> Matrix {
        precondition(qubits >= 2, "CNOT needs at least 2 qubits")
        precondition(control >= 0 && control < qubits, "Control qubit out of range")
        precondition(target >= 0 && target < qubits, "Target qubit out of range")
        precondition(control != target, "Control and target must differ")

        let dim = 1 << qubits
        let controlBit = 1 << (qubits - 1 - control)
        let targetBit = 1 << (qubits - 1 - target)

        var m = Matrix(rows: dim, cols: dim)
        for col in 0..<dim {
            let row = (col & controlBit) != 0 ? col ^ targetBit : col
            m[row, col] = .one
        }
        return m
    }
}
