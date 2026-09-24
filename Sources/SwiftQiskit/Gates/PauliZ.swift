//
//  PauliZ.swift
//  SwiftQiskit
//
//  Pauli-Z gate (Z)
//  Phase flip gate.
//
//  |0⟩ → |0⟩
//  |1⟩ → -|1⟩
//
//  Matrix form:
//  | 1   0 |
//  | 0  -1 |
//
//  Created by Ali on 2025-01-XX.
//

import Foundation

public enum PauliZGate {

    /// Pauli-Z matrix
    public static let matrix: Matrix = {
        Matrix([
            [Complex.one,  Complex.zero],
            [Complex.zero, Complex(-1, 0)]
        ])
    }()
}
