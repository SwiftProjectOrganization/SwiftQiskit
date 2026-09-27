//
//  Matrix.swift
//  SwiftQiskit
//
//  Basic matrix implementation for quantum simulation.
//  Supports matrix-matrix and matrix-vector multiplication.
//
//  Created by Ali on 2025-01-XX.
//

import Foundation

public struct Matrix: Equatable, Hashable {

    public let rows: Int
    public let cols: Int
    private var grid: [Complex]

    // MARK: - Initializers

    public init(rows: Int, cols: Int, repeating value: Complex = .zero) {
        precondition(rows > 0 && cols > 0, "Matrix dimensions must be positive")
        self.rows = rows
        self.cols = cols
        self.grid = Array(repeating: value, count: rows * cols)
    }

    public init(_ data: [[Complex]]) {
        precondition(!data.isEmpty && !data[0].isEmpty, "Matrix data cannot be empty")

        let r = data.count
        let c = data[0].count
        precondition(data.allSatisfy { $0.count == c }, "All rows must have the same number of columns")

        self.rows = r
        self.cols = c
        self.grid = data.flatMap { $0 }
    }

    // MARK: - Subscript

    public subscript(row: Int, col: Int) -> Complex {
        get {
            precondition(isValidIndex(row, col), "Index out of range")
            return grid[(row * cols) + col]
        }
        set {
            precondition(isValidIndex(row, col), "Index out of range")
            grid[(row * cols) + col] = newValue
        }
    }

    private func isValidIndex(_ row: Int, _ col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < cols
    }
}

// MARK: - Matrix Operations
public extension Matrix {

    /// Matrix × Matrix
    static func * (lhs: Matrix, rhs: Matrix) -> Matrix {
        precondition(lhs.cols == rhs.rows, "Matrix dimensions not compatible for multiplication")

        var result = Matrix(rows: lhs.rows, cols: rhs.cols)

        for i in 0..<lhs.rows {
            for j in 0..<rhs.cols {
                var sum = Complex.zero
                for k in 0..<lhs.cols {
                    sum = sum + lhs[i, k] * rhs[k, j]
                }
                result[i, j] = sum
            }
        }

        return result
    }

    /// Matrix × Vector (StateVector)
    func multiply(by vector: [Complex]) -> [Complex] {
        precondition(cols == vector.count, "Matrix and vector dimensions not compatible")

        var result = Array(repeating: Complex.zero, count: rows)

        for i in 0..<rows {
            var sum = Complex.zero
            for j in 0..<cols {
                sum = sum + self[i, j] * vector[j]
            }
            result[i] = sum
        }

        return result
    }
}

// MARK: - Additive Operations
public extension Matrix {

    /// Entrywise sum A + B; dimensions must match.
    static func + (lhs: Matrix, rhs: Matrix) -> Matrix {
        precondition(lhs.rows == rhs.rows && lhs.cols == rhs.cols,
                     "Matrix dimensions must match for addition")

        var result = Matrix(rows: lhs.rows, cols: lhs.cols)
        for i in 0..<lhs.rows {
            for j in 0..<lhs.cols {
                result[i, j] = lhs[i, j] + rhs[i, j]
            }
        }
        return result
    }

    /// Entrywise difference A − B; dimensions must match.
    static func - (lhs: Matrix, rhs: Matrix) -> Matrix {
        precondition(lhs.rows == rhs.rows && lhs.cols == rhs.cols,
                     "Matrix dimensions must match for subtraction")

        var result = Matrix(rows: lhs.rows, cols: lhs.cols)
        for i in 0..<lhs.rows {
            for j in 0..<lhs.cols {
                result[i, j] = lhs[i, j] - rhs[i, j]
            }
        }
        return result
    }
}

// MARK: - Scalar Operations
public extension Matrix {

    /// Scalar multiple c·M
    static func * (lhs: Matrix, rhs: Complex) -> Matrix {
        var result = Matrix(rows: lhs.rows, cols: lhs.cols)
        for i in 0..<lhs.rows {
            for j in 0..<lhs.cols {
                result[i, j] = lhs[i, j] * rhs
            }
        }
        return result
    }

    /// Scalar multiple c·M
    static func * (lhs: Complex, rhs: Matrix) -> Matrix {
        rhs * lhs
    }

    /// Scalar multiple c·M
    static func * (lhs: Matrix, rhs: Double) -> Matrix {
        lhs * Complex(rhs)
    }

    /// Scalar multiple c·M
    static func * (lhs: Double, rhs: Matrix) -> Matrix {
        rhs * Complex(lhs)
    }
}

// MARK: - Identity Matrix
public extension Matrix {

    static func identity(size: Int) -> Matrix {
        var m = Matrix(rows: size, cols: size)
        for i in 0..<size {
            m[i, i] = .one
        }
        return m
    }
}

// MARK: - Unitarity

public extension Matrix {

    /// Whether this matrix is (approximately) unitary: U†U ≈ I, entrywise within `tolerance`.
    /// Always `false` for a non-square matrix. Replaces the hand-rolled `U†U ≈ I` check
    /// repeated across playground pages and tests — `Matrix.==` compares entries exactly,
    /// so it lies on real unitary matrices whose entries carry floating-point rounding.
    func isUnitary(tolerance: Double = 1e-10) -> Bool {
        guard rows == cols else { return false }

        let product = adjoint * self
        let identity = Matrix.identity(size: rows)
        for i in 0..<rows {
            for j in 0..<cols {
                if (product[i, j] - identity[i, j]).magnitude >= tolerance { return false }
            }
        }
        return true
    }
}

// MARK: - Trace

public extension Matrix {

    /// Sum of the diagonal entries, Σᵢ Aᵢᵢ. Traps if the matrix isn't square.
    var trace: Complex {
        precondition(rows == cols, "Trace is only defined for a square matrix")

        var sum = Complex.zero
        for i in 0..<rows {
            sum = sum + self[i, i]
        }
        return sum
    }
}

// MARK: - Permutation Matrix

public extension Matrix {

    /// Builds the `size`×`size` permutation matrix sending basis column `i` to row
    /// `image(i)`, i.e. `|image(i)⟩ ← |i⟩`. `image` must be a bijection on `0..<size`;
    /// this is checked (each row hit exactly once) rather than assumed, so the
    /// constructor itself doubles as the unitarity check a hand-rolled permutation loop
    /// would otherwise need to verify separately with `U†U == I`.
    static func permutation(size: Int, image: (Int) -> Int) -> Matrix {
        precondition(size > 0, "Matrix size must be positive")

        var m = Matrix(rows: size, cols: size)
        var seenRows = Array(repeating: false, count: size)

        for col in 0..<size {
            let row = image(col)
            precondition(row >= 0 && row < size,
                         "Permutation image out of range")
            precondition(!seenRows[row],
                         "Permutation image must be a bijection on 0..<size (row \(row) hit more than once)")
            seenRows[row] = true
            m[row, col] = .one
        }

        return m
    }
}

// MARK: - Matrix Exponential

public extension Matrix {

    /// The matrix exponential e^A via scaling-and-squaring: a Taylor series
    /// (Σ_{k=0}^{terms} Aᵏ/k!) is accurate only while `A`'s norm is small, so `A` is
    /// repeatedly halved until its ∞-norm (max absolute row sum) is ≤ 0.5, the series is
    /// summed there, and the result is squared back up the same number of times
    /// (e^A = (e^(A/2ˢ))^(2ˢ)). Traps if the matrix isn't square.
    ///
    /// No implicit `-i`: for a Hamiltonian-style evolution e^(-iθH), scale `H` by
    /// `Complex(0, -theta)` (or halve it first, per convention) before calling this.
    func expm(terms: Int = 20) -> Matrix {
        precondition(rows == cols, "Matrix exponential is only defined for a square matrix")
        precondition(terms > 0, "expm needs at least one Taylor term")

        var normEstimate = 0.0
        for i in 0..<rows {
            var rowSum = 0.0
            for j in 0..<cols { rowSum += self[i, j].magnitude }
            normEstimate = max(normEstimate, rowSum)
        }

        var scalingSteps = 0
        var scaled = self
        var scaledNorm = normEstimate
        while scaledNorm > 0.5 {
            scaled = scaled * 0.5
            scaledNorm *= 0.5
            scalingSteps += 1
        }

        var result = Matrix.identity(size: rows)
        var term = Matrix.identity(size: rows)
        for k in 1...terms {
            term = (term * scaled) * (1.0 / Double(k))
            result = result + term
        }

        for _ in 0..<scalingSteps { result = result * result }
        return result
    }
}

// MARK: - Tensor Product

/// Kronecker (tensor) product operator.
infix operator ⊗ : MultiplicationPrecedence

public extension Matrix {

    /// Kronecker (tensor) product A ⊗ B.
    /// Result is (rows·other.rows) × (cols·other.cols); any dimensions are valid.
    func tensor(_ other: Matrix) -> Matrix {
        var result = Matrix(rows: rows * other.rows, cols: cols * other.cols)
        for i in 0..<rows {
            for j in 0..<cols {
                for k in 0..<other.rows {
                    for l in 0..<other.cols {
                        result[i * other.rows + k, j * other.cols + l] = self[i, j] * other[k, l]
                    }
                }
            }
        }
        return result
    }

    /// Kronecker (tensor) product: `lhs ⊗ rhs`
    static func ⊗ (lhs: Matrix, rhs: Matrix) -> Matrix {
        lhs.tensor(rhs)
    }
}

// MARK: - CustomStringConvertible
extension Matrix: CustomStringConvertible {
    public var description: String {
        var lines: [String] = []
        for i in 0..<rows {
            let row = (0..<cols).map { self[i, $0].description }.joined(separator: ", ")
            lines.append("[\(row)]")
        }
        return lines.joined(separator: "\n")
    }
}
