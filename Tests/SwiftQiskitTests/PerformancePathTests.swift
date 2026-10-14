import Testing
@testable import SwiftQiskit

/// The fast paths (kernel-based density matrices, direct Pauli expectation, buffer-based
/// `Matrix` arithmetic) must agree with the straightforward dense formulas.
struct PerformancePathTests {

    private func maxDiff(_ a: Matrix, _ b: Matrix) -> Double {
        var m = 0.0
        for i in 0..<a.rows { for j in 0..<a.cols { m = max(m, (a[i, j] - b[i, j]).magnitude) } }
        return m
    }

    private func randomState(_ n: Int) -> StateVector {
        StateVector((0..<(1 << n)).map { _ in Complex(Double.random(in: -1...1), Double.random(in: -1...1)) })
    }

    @Test func matrixMultiplyMatchesNaive() {
        let a = Matrix((0..<4).map { _ in (0..<5).map { _ in Complex(Double.random(in: -1...1), Double.random(in: -1...1)) } })
        let b = Matrix((0..<5).map { _ in (0..<3).map { _ in Complex(Double.random(in: -1...1), Double.random(in: -1...1)) } })
        var naive = Matrix(rows: 4, cols: 3)
        for i in 0..<4 { for j in 0..<3 {
            var s = Complex.zero
            for k in 0..<5 { s = s + a[i, k] * b[k, j] }
            naive[i, j] = s
        } }
        #expect(maxDiff(a * b, naive) < 1e-12)
    }

    @Test func pauliExpectationMatchesDenseMatrix() {
        let state = randomState(3)
        for label in ["XYZ", "IZI", "YYI", "XIX", "ZZZ", "IIY", "III"] {
            let term = PauliString(label, coefficient: 0.7)
            let dense = (state† * term.matrix * state).real
            #expect(abs(term.expectation(state) - dense) < 1e-12, "\(label)")
        }
    }

    @Test func runDensityMatrixMatchesDenseReference() {
        let c = QuantumCircuit(qubits: 3)
        c.h(0); c.cx(0, 2); c.ry(0.8, 1); c.ccx(0, 1, 2); c.rz(0.3, 2); c.pauliRotation("XYI", theta: 0.4)
        let noise = NoiseModel.uniform(KrausChannel.depolarizing(0.1))

        var ref = DensityMatrix(StateVector(qubits: 3))
        for op in c.operationRecords {
            ref = ref.apply(op.matrix)
            let channel = KrausChannel.depolarizing(0.1)
            for q in op.qubits {
                var acc = Matrix(rows: 8, cols: 8)
                for k in channel.operators {
                    let e = embedSingleQubitGate(k, qubits: 3, target: q)
                    acc = acc + e * ref.matrix * e.adjoint
                }
                ref = DensityMatrix(matrix: acc)
            }
        }
        #expect(maxDiff(c.runDensityMatrix(noise: noise).matrix, ref.matrix) < 1e-12)
    }

    @Test func purityAndExpectationMatchTraceFormulas() {
        let rho = DensityMatrix(mixture: [(0.3, randomState(2)), (0.7, randomState(2))])
        let obs = PauliString("XZ").matrix
        #expect(abs(rho.purity - (rho.matrix * rho.matrix).trace.real) < 1e-12)
        #expect(abs(rho.expectation(obs) - (rho.matrix * obs).trace.real) < 1e-12)
    }

    @Test func oneQubitAndDiagonalKernelsMatchFullEmbedding() {
        let n = 4
        for (gate, q) in [(HadamardGate.matrix, 2), (RZGate.matrix(theta: 0.7), 0), (TGate.matrix, 3),
                          (ControlledZGate.matrix, 1), (RXGate.matrix(theta: 1.1), 1)] {
            var fast = randomState(n)
            var slow = fast
            let targets = gate.rows == 4 ? [q, (q + 2) % n] : [q]
            fast.applyLocal(gate, targets: targets, parallel: false)
            // Reference: columns of the embedding via basis states through the same kernel is
            // circular, so use the single-qubit embedding / explicit CZ phases instead.
            if gate.rows == 2 {
                slow.amplitudes = embedSingleQubitGate(gate, qubits: n, target: q).multiply(by: slow.amplitudes)
            } else {
                let b0 = 1 << (n - 1 - targets[0]), b1 = 1 << (n - 1 - targets[1])
                for i in slow.amplitudes.indices where i & b0 != 0 && i & b1 != 0 {
                    slow.amplitudes[i] = slow.amplitudes[i] * Complex(-1, 0)
                }
            }
            for i in 0..<fast.dimension { #expect((fast[i] - slow[i]).magnitude < 1e-12) }
        }
    }

    @Test func basisMeasurementFromRunStateMatchesExactExpectation() {
        let c = QuantumCircuit(qubits: 2)
        c.h(0); c.cx(0, 1); c.ry(0.4, 1)
        let h = Hamiltonian([PauliString("XX", coefficient: 0.5), PauliString("YY", coefficient: -0.3),
                             PauliString("ZI", coefficient: 0.2)])
        let exact = h.expectation(c.run())
        #expect(abs(c.measureExpectation(of: h, shots: 200_000) - exact) < 0.02)
    }
}
