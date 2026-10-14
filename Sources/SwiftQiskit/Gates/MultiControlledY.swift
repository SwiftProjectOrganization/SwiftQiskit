//
//  MultiControlledY.swift
//  SwiftQiskit
//
//  Multi-controlled Y: applies Pauli-Y to the target iff every control bit is 1.
//  Zero controls is `PauliYGate`; one control is `ControlledYGate`.
//
//  Equals S(target)† · MCX · S(target), since Y = S X S†.
//

import Foundation

public enum MultiControlledYGate {

    /// Full 2ⁿ×2ⁿ multi-controlled Y matrix for an n-qubit register.
    /// Qubit 0 is the most-significant (leftmost) bit.
    public static func matrix(qubits: Int, controls: [Int], target: Int) -> Matrix {
        precondition(qubits >= 1, "Need at least 1 qubit")
        precondition(target >= 0 && target < qubits, "Target qubit out of range")
        precondition(controls.allSatisfy { $0 >= 0 && $0 < qubits }, "Control qubit out of range")
        precondition(Set(controls).count == controls.count, "Controls must be distinct")
        precondition(!controls.contains(target), "Controls and target must differ")

        let dim = 1 << qubits
        let targetBit = 1 << (qubits - 1 - target)
        let controlMask = controls.reduce(0) { $0 | (1 << (qubits - 1 - $1)) }

        var m = Matrix.identity(size: dim)
        for i in 0..<dim where (i & controlMask) == controlMask && (i & targetBit) == 0 {
            let j = i | targetBit
            // Y = [[0, -i], [i, 0]] on the (target = 0, target = 1) subspace.
            m[i, i] = Complex(0, 0)
            m[j, j] = Complex(0, 0)
            m[j, i] = Complex(0, 1)
            m[i, j] = Complex(0, -1)
        }
        return m
    }
}
