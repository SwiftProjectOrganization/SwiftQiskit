//
//  PauliX.swift
//  SwiftQiskit
//
//  Pauli-X gate (X)
//  Quantum NOT gate.
//
//  |0⟩ → |1⟩
//  |1⟩ → |0⟩
//
//  Matrix form:
//  | 0  1 |
//  | 1  0 |
//
//  Created by Ali on 2025-01-XX.
//

import Foundation

public enum PauliXGate {

    /// Pauli-X matrix
    public static let matrix: Matrix = {
        Matrix([
            [Complex.zero, Complex.one],
            [Complex.one,  Complex.zero]
        ])
    }()
}
