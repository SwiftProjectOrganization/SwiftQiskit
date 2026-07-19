import Foundation
import Testing
@testable import SwiftQiskitCore

struct BellStateTests {

    /// Test that Bell state |Φ+⟩ is created correctly
    @Test func `Bell state produces correct amplitudes`() {
        let qc = QuantumCircuit(qubits: 2)
        qc.h(0)
        qc.cx(0, 1)

        let state = qc.run()

        // Expected amplitudes
        // |00⟩ = 1/√2 , |11⟩ = 1/√2
        let amp00 = state[0]   // |00⟩
        let amp01 = state[1]   // |01⟩
        let amp10 = state[2]   // |10⟩
        let amp11 = state[3]   // |11⟩

        let expected = 1.0 / sqrt(2.0)
        let tolerance = 1e-10

        #expect(abs(amp00.real - expected) < tolerance)
        #expect(abs(amp11.real - expected) < tolerance)

        #expect(amp01.magnitude < tolerance)
        #expect(amp10.magnitude < tolerance)
    }

    /// Test measurement statistics of Bell state
    @Test func `Bell state measurement yields only 00 and 11`() {
        let qc = QuantumCircuit(qubits: 2)
        qc.h(0)
        qc.cx(0, 1)

        let shots = 1000
        let result = qc.measure(shots: shots)

        let count00 = result.counts["00", default: 0]
        let count11 = result.counts["11", default: 0]
        let count01 = result.counts["01", default: 0]
        let count10 = result.counts["10", default: 0]

        // Bell state should only produce 00 or 11
        #expect(count01 == 0)
        #expect(count10 == 0)

        // Expect roughly 50/50 distribution
        let ratio00 = Double(count00) / Double(shots)
        let ratio11 = Double(count11) / Double(shots)

        #expect(ratio00 > 0.4 && ratio00 < 0.6)
        #expect(ratio11 > 0.4 && ratio11 < 0.6)
    }
}
