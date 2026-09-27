//
//  Toffoli.swift
//  SwiftQiskit
//
//  Toffoli gate (CCNOT / controlled-controlled-NOT).
//  Three-qubit gate: flips the target bit iff both control bits are 1.
//
//  General form: on an n-qubit register, Toffoli(control1, control2, target)
//  flips the target bit of every basis state whose two control bits are
//  both 1 — a permutation of the computational basis.
//
//  Three-qubit truth table (control1 = qubit 0, control2 = qubit 1,
//  target = qubit 2):
//  |000⟩ → |000⟩      |100⟩ → |100⟩
//  |001⟩ → |001⟩      |101⟩ → |101⟩
//  |010⟩ → |010⟩      |110⟩ → |111⟩
//  |011⟩ → |011⟩      |111⟩ → |110⟩
//

import Foundation

public enum ToffoliGate {

    /// Toffoli matrix (controls = qubits 0 and 1, target = qubit 2)
    public static let matrix: Matrix = {
        matrix(qubits: 3, control1: 0, control2: 1, target: 2)
    }()

    /// Full 2ⁿ×2ⁿ Toffoli matrix for an n-qubit register.
    /// Qubit 0 is the most-significant (leftmost) bit.
    public static func matrix(qubits: Int, control1: Int, control2: Int, target: Int) -> Matrix {
        precondition(qubits >= 3, "Toffoli needs at least 3 qubits")
        precondition(control1 >= 0 && control1 < qubits, "First control qubit out of range")
        precondition(control2 >= 0 && control2 < qubits, "Second control qubit out of range")
        precondition(target >= 0 && target < qubits, "Target qubit out of range")
        precondition(control1 != control2, "Controls must differ")
        precondition(control1 != target && control2 != target, "Controls and target must differ")

        let dim = 1 << qubits
        let control1Bit = 1 << (qubits - 1 - control1)
        let control2Bit = 1 << (qubits - 1 - control2)
        let targetBit = 1 << (qubits - 1 - target)

        return Matrix.permutation(size: dim) { col in
            let bothControlsSet = (col & control1Bit) != 0 && (col & control2Bit) != 0
            return bothControlsSet ? col ^ targetBit : col
        }
    }
}
