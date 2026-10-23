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

/// A row-major matrix over any `MatrixScalar`. Quantum code uses `Matrix`, the
/// `GenericMatrix<Complex>` alias; `GenericMatrix<Double>` gives real matrices.
public struct GenericMatrix<Element: MatrixScalar>: Equatable, Hashable {

    public let rows: Int
    public let cols: Int
    /// Row-major entries. Internal so hot paths in this module can use raw buffers.
    var grid: [Element]

    // MARK: - Initializers

    public init(rows: Int, cols: Int, repeating value: Element = .zero) {
        precondition(rows > 0 && cols > 0, "Matrix dimensions must be positive")
        self.rows = rows
        self.cols = cols
        self.grid = Array(repeating: value, count: rows * cols)
    }

    public init(_ data: [[Element]]) {
        precondition(!data.isEmpty && !data[0].isEmpty, "Matrix data cannot be empty")

        let r = data.count
        let c = data[0].count
        precondition(data.allSatisfy { $0.count == c }, "All rows must have the same number of columns")

        self.rows = r
        self.cols = c
        self.grid = data.flatMap { $0 }
    }

    // MARK: - Subscript

    public subscript(row: Int, col: Int) -> Element {
        get {
            precondition(isValidIndex(row, col), "Index out of range")
            return grid[(row * cols) + col]
        }
        set {
            precondition(isValidIndex(row, col), "Index out of range")
            grid[(row * cols) + col] = newValue
        }
    }

    /// Wraps already-laid-out row-major entries without per-entry copying.
    init(rows: Int, cols: Int, elements: [Element]) {
        precondition(rows > 0 && cols > 0 && elements.count == rows * cols, "Bad matrix element count")
        self.rows = rows
        self.cols = cols
        self.grid = elements
    }

    private func isValidIndex(_ row: Int, _ col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < cols
    }
}

/// The quantum-simulation matrix: complex entries.
public typealias Matrix = GenericMatrix<Complex>

// MARK: - Matrix Operations
public extension GenericMatrix {

    /// Matrix × Matrix
    @_specialize(where Element == Complex)
    static func * (lhs: GenericMatrix, rhs: GenericMatrix) -> GenericMatrix {
        precondition(lhs.cols == rhs.rows, "Matrix dimensions not compatible for multiplication")

        let n = lhs.rows, m = lhs.cols, p = rhs.cols
        var out = [Element](repeating: .zero, count: n * p)
        // i-k-j order streams both operands row-wise; zero lhs entries (most gate
        // matrices are sparse) are skipped.
        lhs.grid.withUnsafeBufferPointer { a in
            rhs.grid.withUnsafeBufferPointer { b in
                out.withUnsafeMutableBufferPointer { c in
                    for i in 0..<n {
                        for k in 0..<m {
                            let aik = a[i * m + k]
                            if aik == .zero { continue }
                            for j in 0..<p { c[i * p + j] = c[i * p + j] + aik * b[k * p + j] }
                        }
                    }
                }
            }
        }
        return GenericMatrix(rows: n, cols: p, elements: out)
    }

    /// Matrix × Vector (StateVector)
    @_specialize(where Element == Complex)
    func multiply(by vector: [Element]) -> [Element] {
        precondition(cols == vector.count, "Matrix and vector dimensions not compatible")

        var result = Array(repeating: Element.zero, count: rows)
        grid.withUnsafeBufferPointer { g in
            for i in 0..<rows {
                var sum = Element.zero
                for j in 0..<cols { sum = sum + g[i * cols + j] * vector[j] }
                result[i] = sum
            }
        }
        return result
    }
}

// MARK: - Additive Operations
public extension GenericMatrix {

    /// Entrywise sum A + B; dimensions must match.
    static func + (lhs: GenericMatrix, rhs: GenericMatrix) -> GenericMatrix {
        precondition(lhs.rows == rhs.rows && lhs.cols == rhs.cols,
                     "Matrix dimensions must match for addition")

        return GenericMatrix(rows: lhs.rows, cols: lhs.cols, elements: zip(lhs.grid, rhs.grid).map { $0 + $1 })
    }

    /// Entrywise difference A − B; dimensions must match.
    static func - (lhs: GenericMatrix, rhs: GenericMatrix) -> GenericMatrix {
        precondition(lhs.rows == rhs.rows && lhs.cols == rhs.cols,
                     "Matrix dimensions must match for subtraction")

        return GenericMatrix(rows: lhs.rows, cols: lhs.cols, elements: zip(lhs.grid, rhs.grid).map { $0 - $1 })
    }
}

// MARK: - Scalar Operations
public extension GenericMatrix {

    /// Scalar multiple c·M
    static func * (lhs: GenericMatrix, rhs: Element) -> GenericMatrix {
        return GenericMatrix(rows: lhs.rows, cols: lhs.cols, elements: lhs.grid.map { $0 * rhs })
    }

    /// Scalar multiple c·M
    static func * (lhs: Element, rhs: GenericMatrix) -> GenericMatrix {
        rhs * lhs
    }
}

// MARK: - Identity Matrix
public extension GenericMatrix {

    static func identity(size: Int) -> GenericMatrix {
        var m = GenericMatrix(rows: size, cols: size)
        for i in 0..<size {
            m[i, i] = .one
        }
        return m
    }
}

// MARK: - Unitarity

public extension GenericMatrix {

    /// Whether this matrix is (approximately) unitary: U†U ≈ I, entrywise within `tolerance`.
    /// Always `false` for a non-square matrix. Replaces the hand-rolled `U†U ≈ I` check
    /// repeated across tests — `Matrix.==` compares entries exactly,
    /// so it lies on real unitary matrices whose entries carry floating-point rounding.
    func isUnitary(tolerance: Double = 1e-10) -> Bool {
        guard rows == cols else { return false }

        let product = adjoint * self
        let identity = GenericMatrix.identity(size: rows)
        for i in 0..<rows {
            for j in 0..<cols {
                if (product[i, j] - identity[i, j]).magnitude >= tolerance { return false }
            }
        }
        return true
    }
}

// MARK: - Adjoint

public extension GenericMatrix {

    /// Conjugate transpose (adjoint) A†; plain transpose for real entries.
    var adjoint: GenericMatrix {
        var out = [Element](repeating: .zero, count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols { out[j * rows + i] = grid[i * cols + j].conjugate }
        }
        return GenericMatrix(rows: cols, cols: rows, elements: out)
    }
}

// MARK: - Trace

public extension GenericMatrix {

    /// Sum of the diagonal entries, Σᵢ Aᵢᵢ. Traps if the matrix isn't square.
    var trace: Element {
        precondition(rows == cols, "Trace is only defined for a square matrix")

        var sum = Element.zero
        for i in 0..<rows {
            sum = sum + self[i, i]
        }
        return sum
    }
}

// MARK: - Permutation Matrix

public extension GenericMatrix {

    /// Builds the `size`×`size` permutation matrix sending basis column `i` to row
    /// `image(i)`, i.e. `|image(i)⟩ ← |i⟩`. `image` must be a bijection on `0..<size`;
    /// this is checked (each row hit exactly once) rather than assumed, so the
    /// constructor itself doubles as the unitarity check a hand-rolled permutation loop
    /// would otherwise need to verify separately with `U†U == I`.
    static func permutation(size: Int, image: (Int) -> Int) -> GenericMatrix {
        precondition(size > 0, "Matrix size must be positive")

        var m = GenericMatrix(rows: size, cols: size)
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

// MARK: - Permutation detection

extension GenericMatrix {

    /// If this matrix is *exactly* a permutation matrix (every entry exactly `.zero` or
    /// `.one`, each row and column holding exactly one `.one`), the column→row mapping —
    /// the same `image` `permutation(size:image:)` above is built from. `nil` for anything
    /// else (non-square, a non-0/1 entry, or a 0/1 matrix that isn't a bijection), including
    /// an "almost" permutation with floating-point rounding — every permutation-shaped gate
    /// this library actually builds (`permutation(size:image:)` and everything built from
    /// it: `CNOTGate`, `ToffoliGate`, `MultiControlledXGate`) uses exact `.zero`/`.one`
    /// entries, never a rounded unitary, so this is the same "exact, not approximate"
    /// standard `Matrix.==` already holds permutation matrices to elsewhere.
    ///
    /// Internal: a private implementation detail behind `StateVector.apply(_:)`'s fast
    /// path, not something a caller needs directly. Detection is O(rows·cols) comparisons
    /// (no arithmetic) and bails out on the first entry that rules out a permutation, so
    /// it's cheap for the common dense (non-permutation) gate — H, RX/RY/RZ, a Trotter-step
    /// matrix — which fails on its very first non-0/1 entry.
    var permutationImage: [Int]? {
        guard rows == cols else { return nil }
        var image = Array(repeating: -1, count: rows)
        var seenRows = Array(repeating: false, count: rows)
        for col in 0..<cols {
            var foundRow: Int?
            for row in 0..<rows {
                let entry = self[row, col]
                if entry == .one {
                    guard foundRow == nil else { return nil }
                    foundRow = row
                } else if entry != .zero {
                    return nil
                }
            }
            guard let row = foundRow, !seenRows[row] else { return nil }
            seenRows[row] = true
            image[col] = row
        }
        return image
    }
}

// MARK: - Tensor Product

/// Kronecker (tensor) product operator.
infix operator ⊗ : MultiplicationPrecedence

public extension GenericMatrix {

    /// Kronecker (tensor) product A ⊗ B.
    /// Result is (rows·other.rows) × (cols·other.cols); any dimensions are valid.
    @_specialize(where Element == Complex)
    func tensor(_ other: GenericMatrix) -> GenericMatrix {
        let outCols = cols * other.cols
        var out = [Element](repeating: .zero, count: rows * other.rows * outCols)
        for i in 0..<rows {
            for j in 0..<cols {
                let a = grid[i * cols + j]
                if a == .zero { continue }
                for k in 0..<other.rows {
                    let rowBase = (i * other.rows + k) * outCols + j * other.cols
                    for l in 0..<other.cols { out[rowBase + l] = a * other.grid[k * other.cols + l] }
                }
            }
        }
        return GenericMatrix(rows: rows * other.rows, cols: outCols, elements: out)
    }

    /// Kronecker (tensor) product: `lhs ⊗ rhs`
    static func ⊗ (lhs: GenericMatrix, rhs: GenericMatrix) -> GenericMatrix {
        lhs.tensor(rhs)
    }
}

// MARK: - CustomStringConvertible
extension GenericMatrix: CustomStringConvertible {
    public var description: String {
        var lines: [String] = []
        for i in 0..<rows {
            let row = (0..<cols).map { self[i, $0].description }.joined(separator: ", ")
            lines.append("[\(row)]")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Complex-only (Double scalars, Matrix Exponential)

public extension GenericMatrix where Element == Complex {

    /// Scalar multiple c·M
    static func * (lhs: GenericMatrix, rhs: Double) -> GenericMatrix {
        lhs * Complex(rhs)
    }

    /// Scalar multiple c·M
    static func * (lhs: Double, rhs: GenericMatrix) -> GenericMatrix {
        rhs * Complex(lhs)
    }


    /// The matrix exponential e^A via scaling-and-squaring: a Taylor series
    /// (Σ_{k=0}^{terms} Aᵏ/k!) is accurate only while `A`'s norm is small, so `A` is
    /// repeatedly halved until its ∞-norm (max absolute row sum) is ≤ 0.5, the series is
    /// summed there, and the result is squared back up the same number of times
    /// (e^A = (e^(A/2ˢ))^(2ˢ)). Traps if the matrix isn't square.
    ///
    /// No implicit `-i`: for a Hamiltonian-style evolution e^(-iθH), scale `H` by
    /// `Complex(0, -theta)` (or halve it first, per convention) before calling this.
    func expm(terms: Int = 20) -> GenericMatrix {
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

        var result = GenericMatrix.identity(size: rows)
        var term = GenericMatrix.identity(size: rows)
        for k in 1...terms {
            term = (term * scaled) * (1.0 / Double(k))
            result = result + term
        }

        for _ in 0..<scalingSteps { result = result * result }
        return result
    }
}
