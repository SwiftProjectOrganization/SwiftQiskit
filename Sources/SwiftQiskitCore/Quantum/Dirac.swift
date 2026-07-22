//
//  Dirac.swift
//  SwiftQiskit
//
//  Dirac (bra–ket) notation: kets, bras, the dagger (†) operator,
//  and inner/outer products.
//

import Foundation

/// A ket |ψ⟩ — a `StateVector` viewed as a column vector.
public typealias Ket = StateVector

// MARK: - Bra

/// A bra ⟨ψ| — the conjugate transpose (row vector) of a ket.
public struct Bra: Equatable {

    /// Entries of the row vector, stored already conjugated,
    /// so products with kets are plain (unconjugated) dot products.
    public private(set) var amplitudes: [Complex]

    /// Conjugate transpose of a ket: ⟨ψ| = (|ψ⟩)†
    public init(_ ket: StateVector) {
        self.amplitudes = ket.amplitudes.map { $0.conjugate }
    }

    /// Basis bra from a binary label, e.g. `Bra("01")` = ⟨01|.
    public init(_ label: String) {
        self.init(StateVector(label))
    }

    /// Raw row-vector entries; not necessarily normalized (e.g. after ⟨ψ|U).
    fileprivate init(conjugatedAmplitudes: [Complex]) {
        self.amplitudes = conjugatedAmplitudes
    }

    /// The corresponding ket: |ψ⟩ = (⟨ψ|)†
    public var ket: StateVector {
        StateVector(amplitudes.map { $0.conjugate })
    }

    /// Number of basis states (2^n)
    public var dimension: Int {
        amplitudes.count
    }
}

// MARK: - Dagger (†)

/// Conjugate-transpose (adjoint) operator: `ψ†`, `bra†`, `U†`.
postfix operator †

/// ⟨ψ| = (|ψ⟩)†
public postfix func † (ket: StateVector) -> Bra {
    Bra(ket)
}

/// |ψ⟩ = (⟨ψ|)†
public postfix func † (bra: Bra) -> StateVector {
    bra.ket
}

/// U† — conjugate transpose of a matrix.
public postfix func † (matrix: Matrix) -> Matrix {
    matrix.adjoint
}

public extension Matrix {

    /// Conjugate transpose (adjoint) A†.
    var adjoint: Matrix {
        var result = Matrix(rows: cols, cols: rows)
        for i in 0..<rows {
            for j in 0..<cols {
                result[j, i] = self[i, j].conjugate
            }
        }
        return result
    }
}

// MARK: - Inner & Outer Products

public extension Bra {

    /// Inner product ⟨φ|ψ⟩.
    static func * (lhs: Bra, rhs: StateVector) -> Complex {
        precondition(lhs.dimension == rhs.dimension,
                     "Bra and ket dimensions must match")

        var sum = Complex.zero
        for i in 0..<lhs.dimension {
            sum = sum + lhs.amplitudes[i] * rhs[i]
        }
        return sum
    }

    /// Row vector × matrix: ⟨ψ|U — enables expectation values `ψ† * U * ψ`.
    static func * (lhs: Bra, rhs: Matrix) -> Bra {
        precondition(lhs.dimension == rhs.rows,
                     "Bra and matrix dimensions not compatible")

        var result = Array(repeating: Complex.zero, count: rhs.cols)
        for j in 0..<rhs.cols {
            var sum = Complex.zero
            for i in 0..<rhs.rows {
                sum = sum + lhs.amplitudes[i] * rhs[i, j]
            }
            result[j] = sum
        }
        return Bra(conjugatedAmplitudes: result)
    }
}

public extension StateVector {

    /// Outer product |ψ⟩⟨φ|.
    static func * (lhs: StateVector, rhs: Bra) -> Matrix {
        var result = Matrix(rows: lhs.dimension, cols: rhs.dimension)
        for i in 0..<lhs.dimension {
            for j in 0..<rhs.dimension {
                result[i, j] = lhs[i] * rhs.amplitudes[j]
            }
        }
        return result
    }
}

// MARK: - Basis Kets

public extension StateVector {

    /// Basis ket from a binary label, e.g. `Ket("01")` = |01⟩.
    /// Qubit 0 is the most-significant (leftmost) bit.
    init(_ label: String) {
        precondition(label.allSatisfy { $0 == "0" || $0 == "1" },
                     "Ket label must contain only 0s and 1s")
        guard let index = Int(label, radix: 2) else {
            preconditionFailure("Ket label must be a non-empty binary string")
        }

        var amps = Array(repeating: Complex.zero, count: 1 << label.count)
        amps[index] = .one
        self.init(amps)
    }

    /// |0⟩
    static let zero = StateVector([.one, .zero])

    /// |1⟩
    static let one = StateVector([.zero, .one])

    /// |+⟩ = (|0⟩ + |1⟩)/√2
    static let plus = StateVector([.one, .one])

    /// |−⟩ = (|0⟩ − |1⟩)/√2
    static let minus = StateVector([.one, Complex(-1)])

    /// |i⟩ = (|0⟩ + i|1⟩)/√2
    static let plusI = StateVector([.one, .i])

    /// |−i⟩ = (|0⟩ − i|1⟩)/√2
    static let minusI = StateVector([.one, Complex(0, -1)])
}

// MARK: - Tensor Product

public extension Bra {

    /// Tensor product ⟨a| ⊗ ⟨b| combining two registers into one.
    /// As with kets, `self` occupies the high-order bits.
    func tensor(_ other: Bra) -> Bra {
        var combined = Array(repeating: Complex.zero, count: dimension * other.dimension)
        for i in 0..<dimension {
            for j in 0..<other.dimension {
                combined[i * other.dimension + j] = amplitudes[i] * other.amplitudes[j]
            }
        }
        return Bra(conjugatedAmplitudes: combined)
    }

    /// Tensor product: `lhs ⊗ rhs`
    static func ⊗ (lhs: Bra, rhs: Bra) -> Bra {
        lhs.tensor(rhs)
    }
}

// MARK: - CustomStringConvertible

extension Bra: CustomStringConvertible {
    public var description: String {
        amplitudes
            .enumerated()
            .map { "⟨\(String($0.offset, radix: 2))|: \($0.element)" }
            .joined(separator: "\n")
    }
}
