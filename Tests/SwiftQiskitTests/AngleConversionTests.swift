import Foundation
import Testing
import SwiftQiskit

struct AngleConversionTests {

    private let tolerance = 1e-12

    @Test func knownValues() {
        #expect(abs(deg2rad(0)) < tolerance)
        #expect(abs(deg2rad(90) - .pi / 2) < tolerance)
        #expect(abs(deg2rad(180) - .pi) < tolerance)
        #expect(abs(deg2rad(-45) + .pi / 4) < tolerance)
        #expect(abs(deg2rad(360) - 2 * .pi) < tolerance)
        #expect(abs(rad2deg(.pi) - 180) < tolerance)
        #expect(abs(rad2deg(.pi / 2) - 90) < tolerance)
    }

    @Test func roundTrip() {
        for x in [-720.0, -33.3, 0, 1, 45, 123.456, 360] {
            #expect(abs(rad2deg(deg2rad(x)) - x) < tolerance)
        }
    }

    @Test func degreesDriveGates() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.rx(deg2rad(180), 0)
        #expect(abs(circuit.run().probabilities[1] - 1) < tolerance)
    }
}
