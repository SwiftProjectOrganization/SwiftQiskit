//
//  TwoQubitRotation.swift
//  SwiftQiskit
//
//  The two-qubit Pauli-rotation family RZZ(θ), RXX(θ), RYY(θ): each is
//  exp(-iθ·(P⊗P)/2) for the corresponding Pauli matrix P, on a pair of
//  adjacent qubits (qubit 0 = control-side, qubit 1 = target-side, matching
//  the fixed 2-qubit `CNOTGate.matrix`'s convention).
//
//  Since P⊗P squares to I⊗I for any Pauli P, each closed form follows
//  exp(-iθA/2) = cos(θ/2)·I - i·sin(θ/2)·A for A² = I.
//

import Foundation

public enum RZZGate {

    /// RZZ matrix — exp(-iθ·Z⊗Z/2). Z⊗Z is diagonal with eigenvalues
    /// (+1, -1, -1, +1) on (|00⟩, |01⟩, |10⟩, |11⟩), so this is
    /// diag(e^{-iθ/2}, e^{iθ/2}, e^{iθ/2}, e^{-iθ/2}) — exactly the
    /// `cx(0,1); rz(θ,1); cx(0,1)` identity Core's `RZGate` and `CNOTGate`
    /// already give, with no sign correction.
    public static func matrix(theta: Double) -> Matrix {
        let half = theta / 2
        let plus = Complex(cos(half), -sin(half))   // e^{-iθ/2}
        let minus = Complex(cos(half), sin(half))   // e^{iθ/2}
        return Matrix([
            [plus,          .zero,          .zero,          .zero],
            [.zero,         minus,          .zero,          .zero],
            [.zero,         .zero,          minus,          .zero],
            [.zero,         .zero,          .zero,          plus]
        ])
    }
}

public enum RXXGate {

    /// RXX matrix — exp(-iθ·X⊗X/2) = cos(θ/2)·I₄ - i·sin(θ/2)·(X⊗X).
    /// X⊗X is the anti-diagonal permutation (flips both bits), so the
    /// result is c on the diagonal and -i·s on the anti-diagonal.
    public static func matrix(theta: Double) -> Matrix {
        let c = Complex(cos(theta / 2), 0)
        let s = Complex(0, -sin(theta / 2))
        return Matrix([
            [c,     .zero, .zero, s    ],
            [.zero, c,     s,     .zero],
            [.zero, s,     c,     .zero],
            [s,     .zero, .zero, c    ]
        ])
    }
}

public enum RYYGate {

    /// RYY matrix — exp(-iθ·Y⊗Y/2) = cos(θ/2)·I₄ - i·sin(θ/2)·(Y⊗Y).
    /// Y⊗Y = [[0,0,0,-1],[0,0,1,0],[0,1,0,0],[-1,0,0,0]], so the result is
    /// c on the diagonal, +i·s at the (0,3)/(3,0) corners, and -i·s at the
    /// (1,2)/(2,1) corners.
    public static func matrix(theta: Double) -> Matrix {
        let c = Complex(cos(theta / 2), 0)
        let plusIS = Complex(0, sin(theta / 2))
        let minusIS = Complex(0, -sin(theta / 2))
        return Matrix([
            [c,     .zero,    .zero,    plusIS],
            [.zero, c,        minusIS,  .zero ],
            [.zero, minusIS,  c,        .zero ],
            [plusIS, .zero,   .zero,    c     ]
        ])
    }
}
