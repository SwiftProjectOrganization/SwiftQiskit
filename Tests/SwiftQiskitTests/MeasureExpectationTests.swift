import Foundation
import Testing
@testable import SwiftQiskit

struct MeasureExpectationTests {

    private let tolerance = 1e-9

    private func approxEqual(_ a: StateVector, _ b: StateVector) -> Bool {
        guard a.dimension == b.dimension else { return false }
        for i in 0..<a.dimension {
            if (a[i] - b[i]).magnitude >= tolerance { return false }
        }
        return true
    }

    // MARK: - Deterministic single-term cases

    @Test func `Z expectation on zero is exactly plus one`() {
        let circuit = QuantumCircuit(qubits: 1)
        let e = circuit.measureExpectation(of: PauliString("Z"), shots: 200)
        #expect(abs(e - 1.0) < tolerance)
    }

    @Test func `X expectation on plus is exactly plus one`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.h(0)
        let e = circuit.measureExpectation(of: PauliString("X"), shots: 200)
        #expect(abs(e - 1.0) < tolerance)
    }

    @Test func `ZZ expectation on a Bell pair is exactly plus one`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let e = circuit.measureExpectation(of: PauliString("ZZ"), shots: 500)
        #expect(abs(e - 1.0) < tolerance)
    }

    @Test func `XX expectation on a Bell pair is exactly plus one`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let e = circuit.measureExpectation(of: PauliString("XX"), shots: 500)
        #expect(abs(e - 1.0) < tolerance)
    }

    @Test func `YY expectation on a Bell pair is exactly minus one`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let e = circuit.measureExpectation(of: PauliString("YY"), shots: 500)
        #expect(abs(e - (-1.0)) < tolerance)
    }

    @Test func `all-identity term returns its coefficient exactly, without sampling`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        let e = circuit.measureExpectation(of: PauliString("II", coefficient: 3.7), shots: 1)
        #expect(abs(e - 3.7) < tolerance)
    }

    @Test func `measureExpectation does not mutate the receiver`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let before = circuit.run()
        _ = circuit.measureExpectation(of: PauliString("XX"), shots: 500)
        let after = circuit.run()
        #expect(approxEqual(before, after))
    }

    // MARK: - Statistical cases

    @Test func `Z expectation converges to cosine of the RY angle`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.ry(1.0, 0)
        let e = circuit.measureExpectation(of: PauliString("Z"), shots: 50_000)
        #expect(abs(e - cos(1.0)) < 0.05)
    }

    @Test func `H2 energy at theta=0 converges within shot noise`() {
        let g: [Double] = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910]
        let hamiltonian = Hamiltonian([
            PauliString("II", coefficient: g[0]),
            PauliString("ZI", coefficient: g[1]),
            PauliString("IZ", coefficient: g[2]),
            PauliString("ZZ", coefficient: g[3]),
            PauliString("YY", coefficient: g[4]),
            PauliString("XX", coefficient: g[5]),
        ])

        let circuit = QuantumCircuit(qubits: 2)
        circuit.x(0)
        circuit.ry(0.0, 1)
        circuit.cx(1, 0)

        let e = circuit.measureExpectation(of: hamiltonian, shots: 20_000)
        #expect(abs(e - (-1.830200)) < 0.05)
    }

    /// `ZI`, `IZ`, and `ZZ` are all pairwise qubit-wise commuting (see
    /// `CommutingGroupsTests.swift`), so `measureExpectation(of: Hamiltonian, shots:)`
    /// reads all three from the *same* shot batch (basis Z,Z). Direct correctness check
    /// that sharing a batch doesn't conflate the terms: on `|10⟩` (`x(0)`), the three exact
    /// values are −1, +1, −1, so `H = ZI − IZ + 2·ZZ` has exact value
    /// `(−1) − (1) + 2·(−1) = −4`.
    @Test func `terms sharing one QWC group are extracted correctly from a shared shot batch`() {
        let hamiltonian = Hamiltonian([
            PauliString("ZI", coefficient: 1.0),
            PauliString("IZ", coefficient: -1.0),
            PauliString("ZZ", coefficient: 2.0),
        ])
        #expect(hamiltonian.commutingGroups().count == 1)   // confirms the shared-batch path is exercised

        let circuit = QuantumCircuit(qubits: 2)
        circuit.x(0)   // |10>

        let e = circuit.measureExpectation(of: hamiltonian, shots: 20_000)
        #expect(abs(e - (-4.0)) < 0.05)
    }

    /// The grouped implementation still converges to the *exact* Hamiltonian expectation
    /// (not just "close to a hand-picked number"), at a large shot count, for the H₂ case.
    @Test func `Hamiltonian measureExpectation converges to the exact expectation value`() {
        let g: [Double] = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910]
        let hamiltonian = Hamiltonian([
            PauliString("II", coefficient: g[0]),
            PauliString("ZI", coefficient: g[1]),
            PauliString("IZ", coefficient: g[2]),
            PauliString("ZZ", coefficient: g[3]),
            PauliString("YY", coefficient: g[4]),
            PauliString("XX", coefficient: g[5]),
        ])

        let circuit = QuantumCircuit(qubits: 2)
        circuit.x(0)
        circuit.ry(0.4, 1)
        circuit.cx(1, 0)

        let exact = hamiltonian.expectation(circuit.run())
        let sampled = circuit.measureExpectation(of: hamiltonian, shots: 50_000)
        #expect(abs(sampled - exact) < 0.05)
    }

    @Test func `Hamiltonian measureExpectation does not mutate the receiver`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.x(0)
        circuit.ry(0.4, 1)
        circuit.cx(1, 0)
        let before = circuit.run()

        let hamiltonian = Hamiltonian([PauliString("ZI", coefficient: 1.0), PauliString("IZ", coefficient: 1.0)])
        _ = circuit.measureExpectation(of: hamiltonian, shots: 500)

        let after = circuit.run()
        #expect(approxEqual(before, after))
    }
}
