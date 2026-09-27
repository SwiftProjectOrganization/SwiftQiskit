import Foundation
import Testing
@testable import SwiftQiskit

struct KrausChannelTests {

    private let tolerance = 1e-8

    // MARK: - Trace preservation

    @Test func `all five standard channels are trace-preserving at several probabilities`() {
        for p in [0.0, 0.3, 1.0] {
            #expect(KrausChannel.bitFlip(p).isTracePreserving())
            #expect(KrausChannel.phaseFlip(p).isTracePreserving())
            #expect(KrausChannel.depolarizing(p).isTracePreserving())
            #expect(KrausChannel.amplitudeDamping(p).isTracePreserving())
            #expect(KrausChannel.phaseDamping(p).isTracePreserving())
        }
    }

    // MARK: - Phase-flip coherence decay

    @Test func `phase-flip channel decays coherence exactly as (1-2p)^n`() {
        let p = 0.1
        let channel = KrausChannel.phaseFlip(p)
        var rho = DensityMatrix(Ket.plus)
        for n in 1...20 {
            rho = channel.apply(to: rho)
            if [1, 5, 10, 20].contains(n) {
                let predicted = 0.5 * pow(1 - 2 * p, Double(n))
                #expect(abs(rho.matrix[0, 1].real - predicted) < 1e-9)
            }
        }
    }

    // MARK: - Amplitude damping

    @Test func `amplitude damping on plus matches its closed-form x and z trajectories`() {
        let gamma = 0.2
        let channel = KrausChannel.amplitudeDamping(gamma)
        var rho = DensityMatrix(Ket.plus)
        for _ in 1...20 { rho = channel.apply(to: rho) }
        let bloch = rho.blochVector!

        // x shrinks by √(1-γ) each round (so (1-γ)^10 after 20 rounds); z relaxes toward
        // +1 as 1-(1-γ)ⁿ — the two closed forms page 19's own simulation checks against
        // (there: x ≈ 0.107374 = 0.8¹⁰, z ≈ 0.988471 = 1 - 0.8²⁰).
        #expect(abs(bloch.x - pow(1 - gamma, 10)) < 1e-9)
        #expect(abs(bloch.z - (1 - pow(1 - gamma, 20))) < 1e-9)
    }

    // MARK: - Phase damping (pure dephasing, no energy loss)

    @Test func `phase damping preserves the diagonal`() {
        let lambda = 0.35
        let channel = KrausChannel.phaseDamping(lambda)
        let rho = DensityMatrix(mixture: [(0.3, Ket.zero), (0.7, Ket.one)])
        let after = channel.apply(to: rho)

        #expect(abs(after.matrix[0, 0].real - rho.matrix[0, 0].real) < tolerance)
        #expect(abs(after.matrix[1, 1].real - rho.matrix[1, 1].real) < tolerance)
    }

    @Test func `phase damping shrinks coherence by sqrt(1-lambda) without moving z`() {
        let lambda = 0.35
        let channel = KrausChannel.phaseDamping(lambda)
        let after = channel.apply(to: DensityMatrix(Ket.plus))
        let bloch = after.blochVector!

        #expect(abs(bloch.x - (1 - lambda).squareRoot()) < tolerance)
        #expect(abs(bloch.z - 0.0) < tolerance)
    }

    // MARK: - A known closed-form application: the 3-qubit repetition code

    @Test func `independent bit-flip errors on a repetition codeword give the logical error rate 3p^2 - 2p^3`() {
        // Encode logical |1⟩ as the codeword |111⟩.
        let circuit = QuantumCircuit(qubits: 3)
        circuit.x(0)
        circuit.cx(0, 1)
        circuit.cx(0, 2)

        let p = 0.15
        var rho = DensityMatrix(circuit.run())
        for qubit in 0..<3 {
            rho = KrausChannel.bitFlip(p).apply(to: rho, qubit: qubit)
        }

        // Majority-vote decode each basis outcome by hand (the ancilla-based correction
        // *circuit* — reversible, unlike a bare majority vote — is `14ErrorCorrection`'s
        // own territory; here only the noise channel + density matrix are under test) and
        // sum the probability landing on the wrong logical value. Two or more bit flips
        // (out of three, independently at rate p) is exactly the textbook p_L = 3p² - 2p³.
        let probabilities = rho.probabilities
        var logicalErrorProbability = 0.0
        for index in 0..<8 {
            let ones = (index & 1) + ((index >> 1) & 1) + ((index >> 2) & 1)
            if ones < 2 { logicalErrorProbability += probabilities[index] }
        }

        let expected = 3 * p * p - 2 * p * p * p
        #expect(abs(logicalErrorProbability - expected) < 1e-9)
    }

    // MARK: - Per-qubit embedding is local

    @Test func `embedding a channel onto one qubit leaves the other qubits' reduced states unchanged`() {
        let circuit = QuantumCircuit(qubits: 3)
        circuit.h(0)
        circuit.x(2)
        let rho = DensityMatrix(circuit.run())

        let after = KrausChannel.bitFlip(0.4).apply(to: rho, qubit: 1)

        for qubit in [0, 2] {
            let before = rho.partialTrace(keeping: [qubit])
            let afterReduced = after.partialTrace(keeping: [qubit])
            for i in 0..<2 {
                for j in 0..<2 {
                    #expect((before.matrix[i, j] - afterReduced.matrix[i, j]).magnitude < tolerance)
                }
            }
        }
    }
}
