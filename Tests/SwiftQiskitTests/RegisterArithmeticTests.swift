import Foundation
import Testing
@testable import SwiftQiskit

struct RegisterArithmeticTests {

    // MARK: - MultiControlledXGate matches the fixed-arity gates

    /// Zero controls is an unconditional flip — the same matrix as embedding `PauliXGate`.
    @Test func `Zero controls matches an unconditional X`() {
        let mcx = MultiControlledXGate.matrix(qubits: 3, controls: [], target: 1)
        let x = Matrix.identity(size: 2) ⊗ PauliXGate.matrix ⊗ Matrix.identity(size: 2)
        #expect(mcx == x)
    }

    /// One control matches `CNOTGate.matrix(qubits:control:target:)`.
    @Test func `One control matches CNOT`() {
        let mcx = MultiControlledXGate.matrix(qubits: 3, controls: [0], target: 2)
        let cx = CNOTGate.matrix(qubits: 3, control: 0, target: 2)
        #expect(mcx == cx)
    }

    /// Two controls matches `ToffoliGate.matrix(qubits:control1:control2:target:)`,
    /// regardless of the order the two controls are listed in.
    @Test func `Two controls matches Toffoli`() {
        let mcx = MultiControlledXGate.matrix(qubits: 4, controls: [3, 0], target: 1)
        let ccx = ToffoliGate.matrix(qubits: 4, control1: 3, control2: 0, target: 1)
        #expect(mcx == ccx)

        let mcxSwapped = MultiControlledXGate.matrix(qubits: 4, controls: [0, 3], target: 1)
        #expect(mcxSwapped == ccx)
    }

    /// A 4-control gate on a 5-qubit register is unitary and self-inverse.
    @Test func `Four controls is unitary and self-inverse`() {
        let m = MultiControlledXGate.matrix(qubits: 5, controls: [0, 1, 2, 3], target: 4)
        #expect(m.isUnitary())
        #expect(m * m == Matrix.identity(size: 32))
    }

    // MARK: - increment / decrement on a contiguous register

    /// Every value of a 3-bit register (qubits 0–2 on a 3-qubit circuit) increments to
    /// (v+1) mod 8.
    @Test func `Increment steps through every 3-bit value mod 8`() {
        for v in 0..<8 {
            let circuit = QuantumCircuit(qubits: 3)
            let bits = String(v, radix: 2).leftPadding(toLength: 3, withPad: "0")
            for (i, bit) in bits.enumerated() where bit == "1" { circuit.x(i) }

            circuit.increment(register: [0, 1, 2])

            let expected = (v + 1) % 8
            let expectedBits = String(expected, radix: 2).leftPadding(toLength: 3, withPad: "0")
            #expect(circuit.run() == Ket(expectedBits))
        }
    }

    /// Every value of a 3-bit register decrements to (v-1) mod 8.
    @Test func `Decrement steps through every 3-bit value mod 8`() {
        for v in 0..<8 {
            let circuit = QuantumCircuit(qubits: 3)
            let bits = String(v, radix: 2).leftPadding(toLength: 3, withPad: "0")
            for (i, bit) in bits.enumerated() where bit == "1" { circuit.x(i) }

            circuit.decrement(register: [0, 1, 2])

            let expected = (v - 1 + 8) % 8
            let expectedBits = String(expected, radix: 2).leftPadding(toLength: 3, withPad: "0")
            #expect(circuit.run() == Ket(expectedBits))
        }
    }

    /// `increment` followed by `decrement` is the identity, for every starting value.
    @Test func `Increment then decrement is the identity`() {
        for v in 0..<8 {
            let circuit = QuantumCircuit(qubits: 3)
            let bits = String(v, radix: 2).leftPadding(toLength: 3, withPad: "0")
            for (i, bit) in bits.enumerated() where bit == "1" { circuit.x(i) }

            circuit.increment(register: [0, 1, 2])
            circuit.decrement(register: [0, 1, 2])

            #expect(circuit.run() == Ket(bits))
        }
    }

    // MARK: - Non-contiguous register with a spectator qubit

    /// A 3-bit register spread across a 4-qubit circuit (qubits 0, 2, 3), leaving qubit 1
    /// as an untouched spectator, still increments correctly and leaves the spectator
    /// unchanged.
    @Test func `Non-contiguous register increments correctly and leaves the spectator alone`() {
        for v in 0..<8 {
            for spectator in 0...1 {
                let circuit = QuantumCircuit(qubits: 4)
                if spectator == 1 { circuit.x(1) }
                let bits = String(v, radix: 2).leftPadding(toLength: 3, withPad: "0")
                let registerQubits = [0, 2, 3]
                for (i, bit) in bits.enumerated() where bit == "1" { circuit.x(registerQubits[i]) }

                circuit.increment(register: registerQubits)

                let expected = (v + 1) % 8
                let expectedBits = String(expected, radix: 2).leftPadding(toLength: 3, withPad: "0")
                var full = [Character](repeating: "0", count: 4)
                full[1] = spectator == 1 ? "1" : "0"
                for (i, q) in registerQubits.enumerated() { full[q] = Array(expectedBits)[i] }
                #expect(circuit.run() == Ket(String(full)))
            }
        }
    }

    // MARK: - Controlled increment/decrement

    /// A controlled increment only fires when the control qubit is 1.
    @Test func `Controlled increment only fires when the control is 1`() {
        for controlValue in 0...1 {
            let circuit = QuantumCircuit(qubits: 4)
            if controlValue == 1 { circuit.x(3) }
            // Register starts at |011⟩ on qubits 0,1,2.
            circuit.x(1)
            circuit.x(2)

            circuit.increment(register: [0, 1, 2], controlledBy: 3)

            let expected = controlValue == 1 ? 4 : 3 // 011 -> 100 only if control fires
            let expectedBits = String(expected, radix: 2).leftPadding(toLength: 3, withPad: "0")
            let controlBit = controlValue == 1 ? "1" : "0"
            #expect(circuit.run() == Ket(expectedBits + controlBit))
        }
    }

    /// `increment(controlledBy:)` composed with `decrement(controlledBy:)` at the same
    /// control value is the identity (checked as a full unitary, since it must hold
    /// regardless of the control qubit's own state).
    @Test func `Controlled increment then decrement is the identity as a unitary`() {
        let circuit = QuantumCircuit(qubits: 4)
        circuit.increment(register: [0, 1, 2], controlledBy: 3)
        circuit.decrement(register: [0, 1, 2], controlledBy: 3)

        // Reconstruct the composite unitary column by column and check it's the identity.
        let dim = 16
        var result = Matrix(rows: dim, cols: dim)
        for j in 0..<dim {
            let prep = QuantumCircuit(qubits: 4)
            for q in 0..<4 where (j >> (3 - q)) & 1 == 1 { prep.x(q) }
            prep.increment(register: [0, 1, 2], controlledBy: 3)
            prep.decrement(register: [0, 1, 2], controlledBy: 3)
            let column = prep.run().amplitudes
            for i in 0..<dim { result[i, j] = column[i] }
        }
        #expect(result == Matrix.identity(size: dim))
    }
}
