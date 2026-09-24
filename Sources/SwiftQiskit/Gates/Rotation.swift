//
//  Rotation.swift
//  SwiftQiskit
//
//  The rotation-gate family RX(θ), RY(θ), RZ(θ):
//  rotations of the Bloch vector by angle θ about the X, Y, and Z axes.
//
//  Each is exp(-iθA/2) for the corresponding Pauli matrix A,
//  so a full turn (θ = 2π) is -I, and RA(π) = -i·A (global phase aside).
//

import Foundation

public enum RXGate {

    /// RX matrix — rotation about the X axis:
    ///
    /// |   cos(θ/2)   -i·sin(θ/2) |
    /// | -i·sin(θ/2)    cos(θ/2)  |
    ///
    public static func matrix(theta: Double) -> Matrix {
        let c = cos(theta / 2)
        let s = sin(theta / 2)
        return Matrix([
            [Complex(c, 0),  Complex(0, -s)],
            [Complex(0, -s), Complex(c, 0)]
        ])
    }
}

public enum RYGate {

    /// RY matrix — rotation about the Y axis (all-real entries):
    ///
    /// | cos(θ/2)  -sin(θ/2) |
    /// | sin(θ/2)   cos(θ/2) |
    ///
    public static func matrix(theta: Double) -> Matrix {
        let c = cos(theta / 2)
        let s = sin(theta / 2)
        return Matrix([
            [Complex(c, 0), Complex(-s, 0)],
            [Complex(s, 0), Complex(c, 0)]
        ])
    }
}

public enum RZGate {

    /// RZ matrix — rotation about the Z axis:
    ///
    /// | e^{-iθ/2}     0     |
    /// |     0     e^{iθ/2}  |
    ///
    /// Equal to P(θ) up to the global phase e^{-iθ/2}.
    public static func matrix(theta: Double) -> Matrix {
        let half = theta / 2
        return Matrix([
            [Complex(cos(half), -sin(half)), Complex.zero],
            [Complex.zero,                   Complex(cos(half), sin(half))]
        ])
    }
}
