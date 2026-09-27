import Foundation
import Testing
@testable import SwiftQiskit

struct TrotterTests {

    private let tolerance = 1e-10

    /// Entrywise max-abs-difference comparison of two matrices.
    private func maxDiff(_ a: Matrix, _ b: Matrix) -> Double {
        precondition(a.rows == b.rows && a.cols == b.cols)
        var m = 0.0
        for i in 0..<a.rows {
            for j in 0..<a.cols {
                m = max(m, (a[i, j] - b[i, j]).magnitude)
            }
        }
        return m
    }

    /// Builds the full `2ⁿ×2ⁿ` unitary of an evolution appended by `build`, by preparing
    /// each basis state |j⟩ (via `x` gates) on a fresh circuit, applying `build`, and
    /// reading off the resulting column.
    private func unitaryMatrix(qubits: Int, build: (QuantumCircuit) -> Void) -> Matrix {
        let dim = 1 << qubits
        var result = Matrix(rows: dim, cols: dim)
        for j in 0..<dim {
            let circuit = QuantumCircuit(qubits: qubits)
            for q in 0..<qubits where (j >> (qubits - 1 - q)) & 1 == 1 {
                circuit.x(q)
            }
            build(circuit)
            let column = circuit.run().amplitudes
            for i in 0..<dim {
                result[i, j] = column[i]
            }
        }
        return result
    }

    private func exactEvolution(_ hamiltonian: Hamiltonian, time: Double) -> Matrix {
        (hamiltonian.matrix * Complex(0, -time)).expm()
    }

    // MARK: - Exactness for a single term / commuting terms

    /// A single-term Hamiltonian has nothing to split — first-order Trotter with one step
    /// matches `expm()` exactly.
    @Test func `single term Hamiltonian is exact at one step`() {
        let hamiltonian = Hamiltonian([PauliString("ZZ", coefficient: 1.0)])
        let exact = exactEvolution(hamiltonian, time: 1.0)
        let trotter = unitaryMatrix(qubits: 2) { $0.evolve(hamiltonian, time: 1.0, steps: 1, order: 1) }
        #expect(maxDiff(exact, trotter) < tolerance)
    }

    /// Commuting terms (ZZ and ZI both diagonal in the same basis) split with no error even
    /// at one step, for both orders.
    @Test func `commuting terms are exact at one step`() {
        let hamiltonian = Hamiltonian([
            PauliString("ZZ", coefficient: 1.0),
            PauliString("ZI", coefficient: 0.3),
        ])
        let exact = exactEvolution(hamiltonian, time: 0.8)
        let order1 = unitaryMatrix(qubits: 2) { $0.evolve(hamiltonian, time: 0.8, steps: 1, order: 1) }
        let order2 = unitaryMatrix(qubits: 2) { $0.evolve(hamiltonian, time: 0.8, steps: 1, order: 2) }
        #expect(maxDiff(exact, order1) < tolerance)
        #expect(maxDiff(exact, order2) < tolerance)
    }

    /// An all-`I` term contributes the exact global phase, matched by `expm()`.
    @Test func `identity term contributes the exact global phase`() {
        let hamiltonian = Hamiltonian([
            PauliString("XI", coefficient: 1.0),
            PauliString("II", coefficient: 0.4),
        ])
        let exact = exactEvolution(hamiltonian, time: 0.5)
        let trotter = unitaryMatrix(qubits: 2) { $0.evolve(hamiltonian, time: 0.5, steps: 1, order: 1) }
        #expect(maxDiff(exact, trotter) < tolerance)
    }

    // MARK: - `trotterCircuit` matches `evolve`

    @Test func `trotterCircuit matches evolve on a fresh circuit`() {
        let hamiltonian = Hamiltonian([
            PauliString("ZZ", coefficient: 1.0),
            PauliString("XI", coefficient: 0.5),
            PauliString("IX", coefficient: 0.5),
        ])
        let viaEvolve = unitaryMatrix(qubits: 2) { $0.evolve(hamiltonian, time: 1.0, steps: 4, order: 1) }
        let viaBuilder = unitaryMatrix(qubits: 2) { circuit in
            // Mirror what `trotterCircuit` does internally, on the same prepared circuit.
            circuit.evolve(hamiltonian, time: 1.0, steps: 4, order: 1)
        }
        #expect(maxDiff(viaEvolve, viaBuilder) < tolerance)

        // And the standalone builder itself reproduces the same unitary from |0...0⟩.
        var expected = StateVector(qubits: 2)
        expected.apply(viaEvolve)
        let built = hamiltonian.trotterCircuit(time: 1.0, steps: 4, order: 1).run()
        for i in 0..<expected.dimension {
            #expect((expected[i] - built[i]).magnitude < tolerance)
        }
    }

    // MARK: - Error scaling (page 21Trotter's transverse-field Ising chain)

    /// First-order Trotter error roughly halves each time the step count doubles (O(1/n)).
    @Test func `first-order Trotter error scales as one over n`() {
        let hamiltonian = Hamiltonian([
            PauliString("ZZ", coefficient: 1.0),
            PauliString("XI", coefficient: 0.5),
            PauliString("IX", coefficient: 0.5),
        ])
        let exact = exactEvolution(hamiltonian, time: 1.0)

        func error(_ n: Int) -> Double {
            let trotter = unitaryMatrix(qubits: 2) { $0.evolve(hamiltonian, time: 1.0, steps: n, order: 1) }
            return maxDiff(exact, trotter)
        }

        let e8 = error(8), e16 = error(16), e32 = error(32)
        #expect((1.6...2.4).contains(e8 / e16))
        #expect((1.6...2.4).contains(e16 / e32))
    }

    /// Second-order (Suzuki) Trotter error roughly quarters each time the step count
    /// doubles (O(1/n²)).
    @Test func `second-order Trotter error scales as one over n squared`() {
        let hamiltonian = Hamiltonian([
            PauliString("ZZ", coefficient: 1.0),
            PauliString("XI", coefficient: 0.5),
            PauliString("IX", coefficient: 0.5),
        ])
        let exact = exactEvolution(hamiltonian, time: 1.0)

        func error(_ n: Int) -> Double {
            let trotter = unitaryMatrix(qubits: 2) { $0.evolve(hamiltonian, time: 1.0, steps: n, order: 2) }
            return maxDiff(exact, trotter)
        }

        let e4 = error(4), e8 = error(8), e16 = error(16)
        #expect((3.0...5.0).contains(e4 / e8))
        #expect((3.0...5.0).contains(e8 / e16))
    }

    // MARK: - Multi-qubit (3-qubit chain)

    /// A 3-qubit Ising chain also converges to `expm()` as the step count grows.
    @Test func `three qubit chain converges to expm at large step counts`() {
        let hamiltonian = Hamiltonian([
            PauliString("ZZI", coefficient: 1.0),
            PauliString("IZZ", coefficient: 1.0),
            PauliString("XII", coefficient: 0.5),
            PauliString("IXI", coefficient: 0.5),
            PauliString("IIX", coefficient: 0.5),
        ])
        let exact = exactEvolution(hamiltonian, time: 0.6)
        let trotter = unitaryMatrix(qubits: 3) { $0.evolve(hamiltonian, time: 0.6, steps: 64, order: 2) }
        #expect(maxDiff(exact, trotter) < 1e-4)
    }
}
