import Testing
@testable import SwiftQiskit

/// The kernel path (`run()`) against two independent references: the full-matrix embedding
/// and `TensorNetwork.contract()`.
struct StateVectorKernelTests {

    private func closeEnough(_ a: StateVector, _ b: StateVector, _ tol: Double = 1e-12) -> Bool {
        a.amplitudes.indices.allSatisfy {
            abs(a.amplitudes[$0].real - b.amplitudes[$0].real) < tol
                && abs(a.amplitudes[$0].imag - b.amplitudes[$0].imag) < tol
        }
    }

    /// Replays every recorded operation through its full 2ⁿ×2ⁿ matrix and the dense multiply.
    private func runDense(_ circuit: QuantumCircuit) -> StateVector {
        var state = StateVector(qubits: circuit.qubits)
        for op in circuit.operationRecords { state.apply(op.matrix) }
        return state
    }

    private func randomCircuit(qubits n: Int, gates: Int) -> QuantumCircuit {
        let c = QuantumCircuit(qubits: n)
        for _ in 0..<gates {
            let q = Int.random(in: 0..<n)
            let others = (0..<n).filter { $0 != q }.shuffled()
            switch Int.random(in: 0..<10) {
            case 0: c.h(q)
            case 1: c.x(q)
            case 2: c.y(q)
            case 3: c.t(q)
            case 4: c.rx(Double.random(in: 0..<6), q)
            case 5: c.ry(Double.random(in: 0..<6), q)
            case 6: c.rz(Double.random(in: 0..<6), q)
            case 7 where n >= 2: c.cx(q, others[0])
            case 8 where n >= 3: c.ccx(q, others[0], others[1])
            case 9 where n >= 2: c.swap(q, others[0])
            default: c.s(q)
            }
        }
        return c
    }

    @Test func asymmetricGatesAreNotMirrored() {
        let a = QuantumCircuit(qubits: 3); a.x(0); a.cx(0, 2)
        #expect(a.run().probabilities[0b101] > 0.999)   // qubit 0 is the MSB
        let b = QuantumCircuit(qubits: 3); b.x(2); b.cx(2, 0)
        #expect(b.run().probabilities[0b101] > 0.999)
    }

    @Test func kernelMatchesFullMatrixOnRandomCircuits() {
        for n in 1...6 {
            let c = randomCircuit(qubits: n, gates: 40)
            #expect(closeEnough(c.run(), runDense(c)))
        }
    }

    @Test func kernelMatchesTensorNetwork() {
        let c = randomCircuit(qubits: 5, gates: 40)
        #expect(closeEnough(c.run(), TensorNetwork(c).contract()))
    }

    @Test func multiControlledAndPhaseGates() {
        let c = QuantumCircuit(qubits: 4)
        c.h(0); c.h(1); c.h(3)
        c.mcx([0, 1, 3], 2); c.mcz([3, 0], 1); c.cz(1, 3); c.rzz(0.7, 0, 2); c.rxx(1.1, 1, 3)
        #expect(closeEnough(c.run(), runDense(c)))
    }

    @Test func parallelMatchesSerial() {
        let n = 15
        let c = randomCircuit(qubits: n, gates: 30)
        var parallel = StateVector(qubits: n), serial = StateVector(qubits: n)
        for op in c.operationRecords {
            parallel.applyLocal(op.local, targets: op.qubits, parallel: true)
            serial.applyLocal(op.local, targets: op.qubits, parallel: false)
        }
        #expect(parallel.amplitudes == serial.amplitudes)
    }

    @Test func twentyQubitGHZ() {
        let n = 20
        let c = QuantumCircuit(qubits: n)
        c.h(0)
        for q in 1..<n { c.cx(0, q) }
        let p = c.run().probabilities
        #expect(abs(p[0] - 0.5) < 1e-12 && abs(p[(1 << n) - 1] - 0.5) < 1e-12)
    }
}
