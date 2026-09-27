//
//  MultiControlledX.swift
//  SwiftQiskit
//
//  Multi-controlled X (generalized CNOT/Toffoli): flips the target bit iff every one of
//  an arbitrary number of control bits is 1.
//
//  General form: on an n-qubit register, MultiControlledX(controls, target) flips the
//  target bit of every basis state whose control bits are all 1 — a permutation of the
//  computational basis. Zero controls is an unconditional flip (equivalent to `x`); one
//  control is `CNOTGate`; two controls is `ToffoliGate`. The building block
//  `QuantumCircuit.increment`/`decrement` need for a ripple-carry register: bit `k`'s flip
//  is controlled by every less-significant bit, which is more than two controls past a
//  2-bit register.
//

import Foundation

public enum MultiControlledXGate {

    /// Full 2ⁿ×2ⁿ multi-controlled X matrix for an n-qubit register.
    /// Qubit 0 is the most-significant (leftmost) bit.
    public static func matrix(qubits: Int, controls: [Int], target: Int) -> Matrix {
        precondition(qubits >= 1, "Need at least 1 qubit")
        precondition(target >= 0 && target < qubits, "Target qubit out of range")
        precondition(controls.allSatisfy { $0 >= 0 && $0 < qubits }, "Control qubit out of range")
        precondition(Set(controls).count == controls.count, "Controls must be distinct")
        precondition(!controls.contains(target), "Controls and target must differ")

        let dim = 1 << qubits
        let controlBits = controls.map { 1 << (qubits - 1 - $0) }
        let targetBit = 1 << (qubits - 1 - target)

        return Matrix.permutation(size: dim) { col in
            let allControlsSet = controlBits.allSatisfy { (col & $0) != 0 }
            return allControlsSet ? col ^ targetBit : col
        }
    }
}
