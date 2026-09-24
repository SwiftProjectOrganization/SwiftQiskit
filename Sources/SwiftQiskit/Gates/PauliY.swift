//
//  PauliY.swift
//  SwiftQiskit
//
//  Pauli-Y gate (Y)
//  Bit flip combined with a phase flip.
//
//  |0⟩ → i|1⟩
//  |1⟩ → -i|0⟩
//
//  Matrix form:
//  | 0  -i |
//  | i   0 |
//

import Foundation

public enum PauliYGate {

    /// Pauli-Y matrix
    public static let matrix: Matrix = {
        Matrix([
            [Complex.zero, Complex(0, -1)],
            [Complex.i,    Complex.zero]
        ])
    }()
}
