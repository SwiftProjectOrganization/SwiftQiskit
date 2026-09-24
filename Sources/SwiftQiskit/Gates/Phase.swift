//
//  Phase.swift
//  SwiftQiskit
//
//  The phase-gate family: the general phase gate P(θ) and its
//  fixed-angle members S = P(π/2), S† = P(-π/2), T = P(π/4), T† = P(-π/4).
//
//  P(θ):
//  |0⟩ → |0⟩
//  |1⟩ → e^{iθ}|1⟩
//
//  Matrix form:
//  | 1     0    |
//  | 0  e^{iθ}  |
//

import Foundation

public enum PhaseGate {

    /// Phase matrix P(θ) for an arbitrary angle θ (radians).
    public static func matrix(theta: Double) -> Matrix {
        Matrix([
            [Complex.one,  Complex.zero],
            [Complex.zero, Complex(cos(theta), sin(theta))]
        ])
    }
}

public enum SGate {

    /// S matrix — P(π/2), written with exact entries:
    ///
    /// | 1  0 |
    /// | 0  i |
    ///
    public static let matrix: Matrix = {
        Matrix([
            [Complex.one,  Complex.zero],
            [Complex.zero, Complex.i]
        ])
    }()
}

public enum SDaggerGate {

    /// S† matrix — the adjoint (inverse) of S:
    ///
    /// | 1   0 |
    /// | 0  -i |
    ///
    public static let matrix: Matrix = SGate.matrix.adjoint
}

public enum TGate {

    /// T matrix — P(π/4):
    ///
    /// | 1      0     |
    /// | 0  e^{iπ/4}  |
    ///
    public static let matrix: Matrix = PhaseGate.matrix(theta: .pi / 4)
}

public enum TDaggerGate {

    /// T† matrix — the adjoint (inverse) of T:
    ///
    /// | 1      0      |
    /// | 0  e^{-iπ/4}  |
    ///
    public static let matrix: Matrix = TGate.matrix.adjoint
}
