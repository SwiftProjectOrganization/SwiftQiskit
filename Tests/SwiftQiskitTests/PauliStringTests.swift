import Foundation
import Testing
@testable import SwiftQiskit

struct PauliStringTests {

    private let tolerance = 1e-9

    private func approxEqual(_ a: Matrix, _ b: Matrix) -> Bool {
        guard a.rows == b.rows && a.cols == b.cols else { return false }
        for i in 0..<a.rows {
            for j in 0..<a.cols {
                if (a[i, j] - b[i, j]).magnitude >= tolerance { return false }
            }
        }
        return true
    }

    // MARK: - Single-qubit labels

    @Test func `single-qubit I label is the identity`() {
        #expect(PauliString("I").matrix == Matrix.identity(size: 2))
    }

    @Test func `single-qubit X label matches the Pauli-X gate`() {
        #expect(PauliString("X").matrix == PauliXGate.matrix)
    }

    @Test func `single-qubit Y label matches the Pauli-Y gate`() {
        #expect(PauliString("Y").matrix == PauliYGate.matrix)
    }

    @Test func `single-qubit Z label matches the Pauli-Z gate`() {
        #expect(PauliString("Z").matrix == PauliZGate.matrix)
    }

    @Test func `coefficient scales the matrix`() {
        let scaled = PauliString("X", coefficient: 2.5).matrix
        #expect(approxEqual(scaled, PauliXGate.matrix * 2.5))
    }

    // MARK: - Multi-qubit labels

    @Test func `ZX label matches Z tensor X, pinning qubit ordering`() {
        let expected = PauliZGate.matrix ⊗ PauliXGate.matrix
        #expect(PauliString("ZX").matrix == expected)
    }

    @Test func `label round-trips through init`() {
        #expect(PauliString("IZIX").label == "IZIX")
    }

    @Test func `activeQubits skips identity positions`() {
        #expect(PauliString("IZIX").activeQubits == [1, 3])
    }

    @Test func `qubits reports the label length`() {
        #expect(PauliString("IZIX").qubits == 4)
    }

    // MARK: - Expectation values on known eigenstates

    @Test func `Z expectation is plus one on zero`() {
        #expect(abs(PauliString("Z").expectation(Ket.zero) - 1.0) < tolerance)
    }

    @Test func `Z expectation is minus one on one`() {
        #expect(abs(PauliString("Z").expectation(Ket.one) - (-1.0)) < tolerance)
    }

    @Test func `X expectation is plus one on plus`() {
        #expect(abs(PauliString("X").expectation(Ket.plus) - 1.0) < tolerance)
    }

    @Test func `ZZ expectation is plus one on a Bell pair`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let bell = circuit.run()
        #expect(abs(PauliString("ZZ").expectation(bell) - 1.0) < tolerance)
    }

    // MARK: - H₂ Hamiltonian (page `18VQE`'s six terms)

    private static let h2Coefficients: [Double] = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910]

    private static var h2Hamiltonian: Hamiltonian {
        Hamiltonian([
            PauliString("II", coefficient: h2Coefficients[0]),
            PauliString("ZI", coefficient: h2Coefficients[1]),
            PauliString("IZ", coefficient: h2Coefficients[2]),
            PauliString("ZZ", coefficient: h2Coefficients[3]),
            PauliString("YY", coefficient: h2Coefficients[4]),
            PauliString("XX", coefficient: h2Coefficients[5]),
        ])
    }

    private func h2Ansatz(_ theta: Double) -> Ket {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.x(0)
        circuit.ry(theta, 1)
        circuit.cx(1, 0)
        return circuit.run()
    }

    @Test func `H2 Hamiltonian matrix is Hermitian`() {
        let H = Self.h2Hamiltonian.matrix
        #expect(approxEqual(H, H.adjoint))
    }

    @Test func `H2 Hamiltonian matrix equals the entrywise-built matrix from page 18`() {
        let I2 = Matrix.identity(size: 2)
        let Z = PauliZGate.matrix
        let X = PauliXGate.matrix
        let Y = PauliYGate.matrix
        let g = Self.h2Coefficients

        let terms: [(coefficient: Double, matrix: Matrix)] = [
            (g[0], I2 ⊗ I2), (g[1], Z ⊗ I2), (g[2], I2 ⊗ Z),
            (g[3], Z ⊗ Z), (g[4], Y ⊗ Y), (g[5], X ⊗ X)
        ]
        var expected = Matrix(rows: 4, cols: 4)
        for (coefficient, term) in terms {
            for r in 0..<4 {
                for c in 0..<4 {
                    expected[r, c] = expected[r, c] + term[r, c] * coefficient
                }
            }
        }
        #expect(approxEqual(Self.h2Hamiltonian.matrix, expected))
    }

    @Test func `H2 energy at theta=0 matches page 18's expected value`() {
        let e = Self.h2Hamiltonian.expectation(h2Ansatz(0.0))
        #expect(abs(e - (-1.830200)) < 1e-5)
    }

    @Test func `H2 energy at theta=pi matches page 18's expected value`() {
        let e = Self.h2Hamiltonian.expectation(h2Ansatz(Double.pi))
        #expect(abs(e - (-0.273800)) < 1e-5)
    }

    @Test func `H2 energy matches StateVector expectation directly`() {
        let state = h2Ansatz(0.4)
        let viaHamiltonian = Self.h2Hamiltonian.expectation(state)
        let viaExpectation = state.expectation(Self.h2Hamiltonian.matrix)
        #expect(abs(viaHamiltonian - viaExpectation) < tolerance)
    }

    @Test func `H2 ground energy near theta=-0.22974 matches the closed-form eigenvalue`() {
        let H = Self.h2Hamiltonian.matrix
        let a = H[1, 1].real, b = H[1, 2].real, d = H[2, 2].real
        let exact = (a + d) / 2 - sqrt(pow((a - d) / 2, 2) + b * b)
        let e = Self.h2Hamiltonian.expectation(h2Ansatz(-0.22974))
        #expect(abs(e - exact) < 1e-4)
        #expect(abs(exact - (-1.851199)) < 1e-5)
    }
}
