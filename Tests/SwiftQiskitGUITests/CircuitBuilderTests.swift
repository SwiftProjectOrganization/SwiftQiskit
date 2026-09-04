import Testing
@testable import SwiftQiskitGUI
import SwiftQiskitCore

@MainActor
@Suite("CircuitBuilder")
struct CircuitBuilderTests {

    @Test("H + CX reproduces the Bell state")
    func bellState() {
        let builder = CircuitBuilder(qubitCount: 2)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.cx, qubits: [0, 1], column: 1)

        let state = builder.buildCircuit().run()

        let expectedAmplitude = 1.0 / 2.0.squareRoot()
        #expect(abs(state[0].magnitude - expectedAmplitude) < 1e-9)
        #expect(state[1].magnitude < 1e-9)
        #expect(state[2].magnitude < 1e-9)
        #expect(abs(state[3].magnitude - expectedAmplitude) < 1e-9)
    }

    @Test("placing a gate on an occupied cell is rejected")
    func occupiedCellRejected() {
        let builder = CircuitBuilder(qubitCount: 2)
        #expect(builder.place(.h, qubits: [0], column: 0))
        #expect(!builder.place(.x, qubits: [0], column: 0))
        #expect(builder.gates.count == 1)
    }

    @Test("placing a gate out of range is rejected")
    func outOfRangeRejected() {
        let builder = CircuitBuilder(qubitCount: 2)
        #expect(!builder.place(.h, qubits: [5], column: 0))
        #expect(builder.gates.isEmpty)
    }

    @Test("shrinking qubitCount drops gates that no longer fit")
    func shrinkingDropsOutOfRangeGates() {
        let builder = CircuitBuilder(qubitCount: 3)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.x, qubits: [2], column: 0)

        builder.qubitCount = 2

        #expect(builder.gates.count == 1)
        #expect(builder.gates.first?.kind == .h)
    }

    @Test("qubitCount is clamped to the supported range")
    func qubitCountClamped() {
        let builder = CircuitBuilder(qubitCount: 2)

        builder.qubitCount = 99
        #expect(builder.qubitCount == CircuitBuilder.maxQubits)

        builder.qubitCount = -5
        #expect(builder.qubitCount == CircuitBuilder.minQubits)
    }

    @Test("updateTheta changes only the targeted parameterized gate")
    func updateThetaChangesAngle() {
        let builder = CircuitBuilder(qubitCount: 1)
        builder.place(.rx(0.1), qubits: [0], column: 0)
        let id = builder.gates[0].id

        builder.updateTheta(id: id, theta: 1.23)

        #expect(builder.gates[0].kind.theta == 1.23)
    }

    @Test("clear removes all placed gates")
    func clearRemovesGates() {
        let builder = CircuitBuilder(qubitCount: 2)
        builder.place(.h, qubits: [0], column: 0)
        builder.place(.x, qubits: [1], column: 0)

        builder.clear()

        #expect(builder.gates.isEmpty)
    }
}
