import Foundation
import Testing
@testable import SwiftQiskit

struct TwoQubitRotationTests {

    private let tolerance = 1e-10

    /// Entrywise comparison of two matrices within tolerance
    private func approxEqual(_ a: Matrix, _ b: Matrix) -> Bool {
        guard a.rows == b.rows, a.cols == b.cols else { return false }
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

    // MARK: - Gate matrices against expm

    @Test func `RZZGate matches expm of Z tensor Z`() {
        let theta = 0.7
        let zz = PauliZGate.matrix ⊗ PauliZGate.matrix
        let expected = (zz * Complex(0, -theta / 2)).expm()
        #expect(approxEqual(RZZGate.matrix(theta: theta), expected))
        #expect(RZZGate.matrix(theta: theta).isUnitary())
    }

    @Test func `RXXGate matches expm of X tensor X`() {
        let theta = 1.1
        let xx = PauliXGate.matrix ⊗ PauliXGate.matrix
        let expected = (xx * Complex(0, -theta / 2)).expm()
        #expect(approxEqual(RXXGate.matrix(theta: theta), expected))
        #expect(RXXGate.matrix(theta: theta).isUnitary())
    }

    @Test func `RYYGate matches expm of Y tensor Y`() {
        let theta = -0.4
        let yy = PauliYGate.matrix ⊗ PauliYGate.matrix
        let expected = (yy * Complex(0, -theta / 2)).expm()
        #expect(approxEqual(RYYGate.matrix(theta: theta), expected))
        #expect(RYYGate.matrix(theta: theta).isUnitary())
    }

    /// RZZ matches the cx;rz;cx identity already checked in `MatrixExponentialTests`
    @Test func `RZZGate matches the cx-rz-cx identity`() {
        let theta = 0.7
        let cx = CNOTGate.matrix
        let rz1 = Matrix.identity(size: 2) ⊗ RZGate.matrix(theta: theta)
        let viaGates = cx * rz1 * cx
        #expect(approxEqual(RZZGate.matrix(theta: theta), viaGates))
    }

    // MARK: - Circuit wrappers on adjacent qubits

    @Test func `Circuit rzz matches RZZGate on adjacent qubits`() {
        let theta = 0.5
        let prep = QuantumCircuit(qubits: 2)
        prep.h(0)
        prep.ry(0.3, 1)

        let viaCircuit = QuantumCircuit(qubits: 2)
        viaCircuit.h(0)
        viaCircuit.ry(0.3, 1)
        viaCircuit.rzz(theta, 0, 1)

        var expected = prep.run()
        expected.apply(RZZGate.matrix(theta: theta))

        #expect(approxEqual(viaCircuit.run(), expected))
    }

    @Test func `Circuit rxx matches RXXGate on adjacent qubits`() {
        let theta = 0.9

        let viaCircuit = QuantumCircuit(qubits: 2)
        viaCircuit.h(0)
        viaCircuit.ry(0.3, 1)
        viaCircuit.rxx(theta, 0, 1)

        let prep = QuantumCircuit(qubits: 2)
        prep.h(0)
        prep.ry(0.3, 1)
        var expected = prep.run()
        expected.apply(RXXGate.matrix(theta: theta))

        #expect(approxEqual(viaCircuit.run(), expected))
    }

    @Test func `Circuit ryy matches RYYGate on adjacent qubits`() {
        let theta = -0.6

        let viaCircuit = QuantumCircuit(qubits: 2)
        viaCircuit.h(0)
        viaCircuit.ry(0.3, 1)
        viaCircuit.ryy(theta, 0, 1)

        let prep = QuantumCircuit(qubits: 2)
        prep.h(0)
        prep.ry(0.3, 1)
        var expected = prep.run()
        expected.apply(RYYGate.matrix(theta: theta))

        #expect(approxEqual(viaCircuit.run(), expected))
    }

    // MARK: - Non-adjacent qubits

    /// `rzz` on qubits (0, 2) of a 3-qubit register matches expm(-iθ·Z⊗I⊗Z/2)
    @Test func `Circuit rzz on non-adjacent qubits matches expm of Z tensor I tensor Z`() {
        let theta = 0.8
        let I2 = Matrix.identity(size: 2)
        let z = PauliZGate.matrix

        let viaCircuit = QuantumCircuit(qubits: 3)
        viaCircuit.h(0)
        viaCircuit.x(1)
        viaCircuit.ry(0.2, 2)
        viaCircuit.rzz(theta, 0, 2)

        let prep = QuantumCircuit(qubits: 3)
        prep.h(0)
        prep.x(1)
        prep.ry(0.2, 2)
        var expected = prep.run()
        let generator = (z ⊗ I2 ⊗ z) * Complex(0, -theta / 2)
        expected.apply(generator.expm())

        #expect(approxEqual(viaCircuit.run(), expected))
    }

    // MARK: - pauliRotation against hand-built expm

    @Test func `pauliRotation on a 3-qubit string matches a hand-built generator`() {
        let theta = 0.6
        let x = PauliXGate.matrix
        let y = PauliYGate.matrix
        let z = PauliZGate.matrix

        let viaCircuit = QuantumCircuit(qubits: 3)
        viaCircuit.rx(0.4, 0)
        viaCircuit.ry(0.5, 1)
        viaCircuit.rx(0.3, 2)
        viaCircuit.pauliRotation("XYZ", theta: theta)

        let prep = QuantumCircuit(qubits: 3)
        prep.rx(0.4, 0)
        prep.ry(0.5, 1)
        prep.rx(0.3, 2)
        var expected = prep.run()
        let generator = (x ⊗ y ⊗ z) * Complex(0, -theta / 2)
        expected.apply(generator.expm())

        #expect(approxEqual(viaCircuit.run(), expected))
    }

    /// A 4-qubit mixed string with an identity in the middle
    @Test func `pauliRotation on a 4-qubit mixed string matches a hand-built generator`() {
        let theta = -0.35
        let x = PauliXGate.matrix
        let y = PauliYGate.matrix
        let I2 = Matrix.identity(size: 2)
        let z = PauliZGate.matrix

        let viaCircuit = QuantumCircuit(qubits: 4)
        for q in 0..<4 { viaCircuit.ry(0.2 * Double(q + 1), q) }
        viaCircuit.pauliRotation("YXIZ", theta: theta)

        let prep = QuantumCircuit(qubits: 4)
        for q in 0..<4 { prep.ry(0.2 * Double(q + 1), q) }
        var expected = prep.run()
        let generator = (y ⊗ x ⊗ I2 ⊗ z) * Complex(0, -theta / 2)
        expected.apply(generator.expm())

        #expect(approxEqual(viaCircuit.run(), expected))
    }

    // MARK: - Single-qubit strings reduce to rx/ry/rz

    @Test func `pauliRotation with a single-qubit string matches rx, ry, rz`() {
        let theta = 0.45

        let viaX = QuantumCircuit(qubits: 1)
        viaX.pauliRotation("X", theta: theta)
        let rxCircuit = QuantumCircuit(qubits: 1)
        rxCircuit.rx(theta, 0)
        #expect(approxEqual(viaX.run(), rxCircuit.run()))

        let viaY = QuantumCircuit(qubits: 1)
        viaY.pauliRotation("Y", theta: theta)
        let ryCircuit = QuantumCircuit(qubits: 1)
        ryCircuit.ry(theta, 0)
        #expect(approxEqual(viaY.run(), ryCircuit.run()))

        let viaZ = QuantumCircuit(qubits: 1)
        viaZ.pauliRotation("Z", theta: theta)
        let rzCircuit = QuantumCircuit(qubits: 1)
        rzCircuit.rz(theta, 0)
        #expect(approxEqual(viaZ.run(), rzCircuit.run()))
    }

    // MARK: - All-identity string

    @Test func `pauliRotation with an all-identity string applies only a global phase`() {
        let theta = 1.2
        let viaCircuit = QuantumCircuit(qubits: 2)
        viaCircuit.h(0)
        viaCircuit.x(1)
        viaCircuit.pauliRotation("II", theta: theta)

        let prep = QuantumCircuit(qubits: 2)
        prep.h(0)
        prep.x(1)
        let globalPhase = Complex(cos(theta / 2), -sin(theta / 2))
        var expected = prep.run()
        expected.apply(Matrix.identity(size: 4) * globalPhase)

        #expect(approxEqual(viaCircuit.run(), expected))
    }
}
