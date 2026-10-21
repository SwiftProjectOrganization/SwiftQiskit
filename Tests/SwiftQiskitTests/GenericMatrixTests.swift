import Testing
@testable import SwiftQiskit

struct GenericMatrixTests {

    typealias RealMatrix = GenericMatrix<Double>

    @Test func matrixIsComplexAlias() {
        let m: GenericMatrix<Complex> = Matrix.identity(size: 2)
        #expect(m == Matrix.identity(size: 2))
    }

    @Test func realArithmetic() {
        let a = RealMatrix([[1, 2], [3, 4]])
        let b = RealMatrix([[0, 1], [1, 0]])
        #expect(a * b == RealMatrix([[2, 1], [4, 3]]))
        #expect(a + b == RealMatrix([[1, 3], [4, 4]]))
        #expect(a - b == RealMatrix([[1, 1], [2, 4]]))
        #expect(a * 2.0 == RealMatrix([[2, 4], [6, 8]]))
        #expect(2.0 * a == a * 2.0)
        #expect(a.trace == 5)
        #expect(a * RealMatrix.identity(size: 2) == a)
    }

    @Test func realTensorAndAdjoint() {
        let a = RealMatrix([[1, 2], [3, 4]])
        #expect(a.adjoint == RealMatrix([[1, 3], [2, 4]]))
        let t = RealMatrix.identity(size: 2) ⊗ a
        #expect(t.rows == 4 && t[0, 1] == 2 && t[3, 3] == 4 && t[0, 2] == 0)
    }

    @Test func realUnitarity() {
        let c = 0.5.squareRoot(), s = 0.5.squareRoot()
        #expect(RealMatrix([[c, -s], [s, c]]).isUnitary())
        #expect(!RealMatrix([[1, 1], [0, 1]]).isUnitary())
    }

    @Test func realPermutation() {
        let p = RealMatrix.permutation(size: 3) { ($0 + 1) % 3 }
        #expect(p[1, 0] == 1 && p[2, 1] == 1 && p[0, 2] == 1)
        #expect(p.isUnitary())
    }

    @Test func realProductMatchesComplexLift() {
        let a = RealMatrix([[1, 2], [3, 4]]), b = RealMatrix([[5, 6], [7, 8]])
        let lift = { (m: RealMatrix) in Matrix(rows: m.rows, cols: m.cols, elements: m.grid.map { Complex($0) }) }
        #expect(lift(a * b) == lift(a) * lift(b))
    }
}
