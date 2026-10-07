//
//  MultiControlledZ.swift
//  SwiftQiskit
//
//  Multi-controlled Z: flips the sign of every basis state in which all the control bits
//  and the target bit are 1. A diagonal matrix, symmetric in all of its qubits. Zero
//  controls is `PauliZGate`; one control is `ControlledZGate`; two controls is CCZ.
//

import Foundation

public enum MultiControlledZGate {

    /// Full 2ⁿ×2ⁿ multi-controlled Z matrix for an n-qubit register.
    /// Qubit 0 is the most-significant (leftmost) bit.
    public static func matrix(qubits: Int, controls: [Int], target: Int) -> Matrix {
        precondition(qubits >= 1, "Need at least 1 qubit")
        precondition(target >= 0 && target < qubits, "Target qubit out of range")
        precondition(controls.allSatisfy { $0 >= 0 && $0 < qubits }, "Control qubit out of range")
        precondition(Set(controls).count == controls.count, "Controls must be distinct")
        precondition(!controls.contains(target), "Controls and target must differ")

        let dim = 1 << qubits
        let mask = (controls + [target]).reduce(0) { $0 | (1 << (qubits - 1 - $1)) }

        var m = Matrix.identity(size: dim)
        for i in 0..<dim where (i & mask) == mask {
            m[i, i] = Complex(-1, 0)
        }
        return m
    }
}
