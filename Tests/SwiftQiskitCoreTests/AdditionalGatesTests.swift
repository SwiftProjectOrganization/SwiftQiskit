import Foundation
import Testing
@testable import SwiftQiskitCore

struct AdditionalGatesTests {

    private let tolerance = 1e-10

    // MARK: - Helpers

    /// Entrywise comparison of two matrices within tolerance
    private func approxEqual(_ a: Matrix, _ b: Matrix) -> Bool {
        guard a.rows == b.rows && a.cols == b.cols else { return false }
        for i in 0..<a.rows {
            for j in 0..<a.cols {
                if (a[i, j] - b[i, j]).magnitude >= tolerance { return false }
            }
        }
        return true
    }

    /// Entrywise comparison of two state vectors within tolerance
    private func approxEqual(_ a: StateVector, _ b: StateVector) -> Bool {
        guard a.dimension == b.dimension else { return false }
        for i in 0..<a.dimension {
            if (a[i] - b[i]).magnitude >= tolerance { return false }
        }
        return true
    }

    /// Scalar multiple c·M (Matrix has no scalar-multiply operator)
    private func scale(_ m: Matrix, by c: Complex) -> Matrix {
        var result = Matrix(rows: m.rows, cols: m.cols)
        for i in 0..<m.rows {
            for j in 0..<m.cols {
                result[i, j] = c * m[i, j]
            }
        }
        return result
    }

    // MARK: - Pauli-Y

    @Test func `Pauli-Y is unitary and self-inverse`() {
        let y = PauliYGate.matrix
        let identity = Matrix.identity(size: 2)

        #expect(y.adjoint * y == identity)
        #expect(y * y == identity)
    }

    @Test func `Pauli-Y maps basis states with the right phases`() {
        var zero = Ket.zero
        zero.apply(PauliYGate.matrix)
        #expect(approxEqual(zero, StateVector([.zero, .i])))

        var one = Ket.one
        one.apply(PauliYGate.matrix)
        #expect(approxEqual(one, StateVector([Complex(0, -1), .zero])))
    }

    @Test func `Y equals i times XZ`() {
        let ixz = scale(PauliXGate.matrix * PauliZGate.matrix, by: .i)
        #expect(approxEqual(PauliYGate.matrix, ixz))
    }

    // MARK: - Phase family

    @Test func `S squared is Z and T squared is S`() {
        let s = SGate.matrix
        let t = TGate.matrix

        #expect(approxEqual(s * s, PauliZGate.matrix))
        #expect(approxEqual(t * t, s))
        #expect(approxEqual(t * t * t * t, PauliZGate.matrix))
    }

    @Test func `Dagger gates invert S and T`() {
        let identity = Matrix.identity(size: 2)

        #expect(SGate.matrix * SDaggerGate.matrix == identity)
        #expect(approxEqual(TGate.matrix * TDaggerGate.matrix, identity))
    }

    @Test func `General phase gate matches its fixed-angle members`() {
        #expect(approxEqual(PhaseGate.matrix(theta: .pi / 2), SGate.matrix))
        #expect(approxEqual(PhaseGate.matrix(theta: .pi / 4), TGate.matrix))
        #expect(approxEqual(PhaseGate.matrix(theta: .pi), PauliZGate.matrix))
    }

    @Test func `S rotates plus to plus-i on the equator`() {
        var state = Ket.plus
        state.apply(SGate.matrix)
        #expect(approxEqual(state, Ket.plusI))
    }

    // MARK: - Rotations

    @Test func `Rotations are unitary at an arbitrary angle`() {
        let theta = 0.7
        let identity = Matrix.identity(size: 2)

        #expect(approxEqual(RXGate.matrix(theta: theta).adjoint * RXGate.matrix(theta: theta), identity))
        #expect(approxEqual(RYGate.matrix(theta: theta).adjoint * RYGate.matrix(theta: theta), identity))
        #expect(approxEqual(RZGate.matrix(theta: theta).adjoint * RZGate.matrix(theta: theta), identity))
    }

    @Test func `Pi rotations are Paulis up to global phase -i`() {
        let minusI = Complex(0, -1)

        #expect(approxEqual(RXGate.matrix(theta: .pi), scale(PauliXGate.matrix, by: minusI)))
        #expect(approxEqual(RYGate.matrix(theta: .pi), scale(PauliYGate.matrix, by: minusI)))
        #expect(approxEqual(RZGate.matrix(theta: .pi), scale(PauliZGate.matrix, by: minusI)))
    }

    @Test func `RY rotates zero by half the angle`() {
        let theta = 2.0 * .pi / 3.0

        var state = Ket.zero
        state.apply(RYGate.matrix(theta: theta))

        let expected = StateVector([
            Complex(cos(theta / 2), 0),
            Complex(sin(theta / 2), 0)
        ])
        #expect(approxEqual(state, expected))
    }

    @Test func `RZ is the phase gate up to global phase`() {
        let theta = 1.3
        let globalPhase = Complex(cos(theta / 2), -sin(theta / 2))

        let expected = scale(PhaseGate.matrix(theta: theta), by: globalPhase)
        #expect(approxEqual(RZGate.matrix(theta: theta), expected))
    }

    @Test func `Successive RX rotations add their angles`() {
        let a = 0.4
        let b = 1.1

        let composed = RXGate.matrix(theta: a) * RXGate.matrix(theta: b)
        #expect(approxEqual(composed, RXGate.matrix(theta: a + b)))
    }

    // MARK: - Circuit integration

    @Test func `Circuit y matches hand-embedded Y tensor I`() {
        let qc = QuantumCircuit(qubits: 2)
        qc.y(0)
        let state = qc.run()

        var expected = Ket("00")
        expected.apply(PauliYGate.matrix ⊗ Matrix.identity(size: 2))

        #expect(approxEqual(state, expected))
    }

    @Test func `Two circuit t gates equal one s gate`() {
        let twoT = QuantumCircuit(qubits: 1)
        twoT.h(0)
        twoT.t(0)
        twoT.t(0)

        let oneS = QuantumCircuit(qubits: 1)
        oneS.h(0)
        oneS.s(0)

        #expect(approxEqual(twoT.run(), oneS.run()))
    }

    @Test func `Circuit p and rz agree on measurement probabilities`() {
        let theta = 0.9

        let pCircuit = QuantumCircuit(qubits: 1)
        pCircuit.h(0)
        pCircuit.p(theta, 0)
        pCircuit.h(0)

        let rzCircuit = QuantumCircuit(qubits: 1)
        rzCircuit.h(0)
        rzCircuit.rz(theta, 0)
        rzCircuit.h(0)

        let pState = pCircuit.run()
        let rzState = rzCircuit.run()

        for i in 0..<pState.dimension {
            #expect(abs(pState[i].magnitudeSquared - rzState[i].magnitudeSquared) < tolerance)
        }
    }

    @Test func `RX quarter turn measures half and half`() {
        let qc = QuantumCircuit(qubits: 1)
        qc.rx(.pi / 2, 0)

        let shots = 1000
        let result = qc.measure(shots: shots)

        let zeros = result.counts["0", default: 0]
        let ones = result.counts["1", default: 0]
        #expect(zeros + ones == shots)
        #expect(zeros > 400 && zeros < 600)
        #expect(ones > 400 && ones < 600)
    }
}
