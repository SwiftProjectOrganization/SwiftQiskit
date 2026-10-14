import Testing
@testable import SwiftQiskit

/// Wall-clock timing of `QuantumCircuit.run()` — prints a table, asserts only that the largest
/// size completes and is normalized. Used to decide whether a GPU (MLX) backend is worth adding.
struct RunBenchmarkTests {

    /// 3n gates: H on every qubit, a CX chain, then RZ on every qubit.
    private func layered(_ n: Int) -> QuantumCircuit {
        let c = QuantumCircuit(qubits: n)
        for q in 0..<n { c.h(q) }
        for q in 0..<(n - 1) { c.cx(q, q + 1) }
        for q in 0..<n { c.rz(0.3 * Double(q + 1), q) }
        return c
    }

    @Test func timeRun() {
        var report = "run() benchmark (3n-gate layered circuit)\n  qubits | build (ms) | run (ms)\n"
        var last = StateVector(qubits: 1)
        for n in [8, 12, 16, 20] {
            let clock = ContinuousClock()
            var circuit: QuantumCircuit?
            let build = clock.measure { circuit = layered(n) }
            let run = clock.measure { if let circuit { last = circuit.run() } }
            func ms(_ d: Duration) -> String {
                String(format: "%.2f", Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15)
            }
            report += "  \(n) | \(ms(build)) | \(ms(run))\n"
        }
        print(report)
        #expect(abs(last.probabilities.reduce(0, +) - 1) < 1e-9)
    }

    @Test func timeDensityMatrixAndExpectation() {
        let clock = ContinuousClock()
        func ms(_ d: Duration) -> String {
            String(format: "%.2f", Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15)
        }
        var report = "runDensityMatrix(noise:) / Hamiltonian.expectation benchmark\n"
        for n in [4, 6, 8] {
            let c = layered(n)
            let noise = NoiseModel.uniform(KrausChannel.depolarizing(0.01))
            let t = clock.measure { _ = c.runDensityMatrix(noise: noise) }
            report += "  density n=\(n): \(ms(t)) ms\n"
        }
        for n in [8, 12] {
            let state = layered(n).run()
            let h = Hamiltonian((0..<n).map { q in
                PauliString(String((0..<n).map { $0 == q ? "Z" : "I" }), coefficient: 1) })
            var value = 0.0
            let t = clock.measure { value = h.expectation(state) }
            report += "  expectation n=\(n): \(ms(t)) ms (\(value))\n"
        }
        print(report)
    }
}
