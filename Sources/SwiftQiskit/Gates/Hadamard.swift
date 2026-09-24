//
//  Hadamard.swift
//  SwiftQiskit
//
//  Hadamard gate (H)
//  Creates superposition from basis states.
//
//  |0⟩ → (|0⟩ + |1⟩) / √2
//  |1⟩ → (|0⟩ - |1⟩) / √2
//
//  Created by Ali on 2025-01-XX.
//

import Foundation

public enum HadamardGate {

    /// Hadamard matrix:
    ///
    /// 1/√2 * | 1   1 |
    ///        | 1  -1 |
    ///
    public static let matrix: Matrix = {
        let factor = 1.0 / sqrt(2.0)
        return Matrix([
            [Complex(factor, 0), Complex(factor, 0)],
            [Complex(factor, 0), Complex(-factor, 0)]
        ])
    }()
}
