import Foundation
import Testing
@testable import SwiftQiskit

struct PermutationFastPathTests {

    // MARK: - permutationImage detects genuine permutations

    /// `permutationImage` recovers exactly the `image` closure a hand-built permutation was
    /// constructed from.
    @Test func `permutationImage matches the image a permutation was built from`() {
        let image: [Int] = [3, 1, 0, 2]   // an arbitrary bijection on 0..<4
        let m = Matrix.permutation(size: 4) { image[$0] }
        #expect(m.permutationImage == image)
    }

    /// `CNOTGate`, `ToffoliGate`, and `MultiControlledXGate` (0/1/2 controls) are all
    /// permutations; `permutationImage` matches each gate's own truth table.
    @Test func `permutationImage matches CNOT Toffoli and MultiControlledX truth tables`() {
        let cnot = CNOTGate.matrix(qubits: 2, control: 0, target: 1)
        #expect(cnot.permutationImage == [0, 1, 3, 2])   // |00>,|01>,|10>,|11> -> |00>,|01>,|11>,|10>

        let toffoli = ToffoliGate.matrix(qubits: 3, control1: 0, control2: 1, target: 2)
        #expect(toffoli.permutationImage == [0, 1, 2, 3, 4, 5, 7, 6])

        let mcxNoControls = MultiControlledXGate.matrix(qubits: 1, controls: [], target: 0)
        #expect(mcxNoControls.permutationImage == [1, 0])   // an unconditional flip, i.e. x

        let mcxFourControls = MultiControlledXGate.matrix(qubits: 5, controls: [0, 1, 2, 3], target: 4)
        var expected = Array(0..<32)
        expected[30] = 31   // |11110> -> |11111>
        expected[31] = 30   // |11111> -> |11110>
        #expect(mcxFourControls.permutationImage == expected)
    }

    // MARK: - permutationImage rejects everything else

    /// A genuinely dense (non-0/1) unitary — `HadamardGate`, and `RXGate` at a generic
    /// angle — is not a permutation.
    @Test func `permutationImage is nil for dense gates`() {
        #expect(HadamardGate.matrix.permutationImage == nil)
        #expect(RXGate.matrix(theta: 0.37).permutationImage == nil)
    }

    /// A non-square matrix is never a permutation.
    @Test func `permutationImage is nil for a non-square matrix`() {
        let m = Matrix(rows: 2, cols: 3)
        #expect(m.permutationImage == nil)
    }

    /// A 0/1 matrix that isn't a bijection (two columns both mapping to the same row) must
    /// not be mistaken for a permutation — it isn't unitary, and treating it as one would
    /// corrupt the state's norm.
    @Test func `permutationImage is nil for a non-bijective 0-1 matrix`() {
        var m = Matrix(rows: 2, cols: 2)
        m[0, 0] = .one
        m[0, 1] = .one   // both columns point at row 0 — row 1 is never hit
        #expect(m.permutationImage == nil)
    }

    // MARK: - StateVector.apply(_:) fast path agrees with the dense path

    /// `apply(_:)`'s permutation fast path and a manual dense `multiply(by:)` + `normalize`
    /// give the exact same result, for a `cx`-shaped permutation on a superposed state.
    @Test func `apply fast path matches manual dense multiply for a CNOT-shaped matrix`() {
        let cnot = CNOTGate.matrix(qubits: 2, control: 0, target: 1)

        var viaApply = StateVector([Complex(0.6), Complex(0, 0.3), Complex(-0.5), Complex(0.4, 0.2)])
        viaApply.apply(cnot)

        var viaDense = StateVector([Complex(0.6), Complex(0, 0.3), Complex(-0.5), Complex(0.4, 0.2)])
        let denseAmps = cnot.multiply(by: (0..<4).map { viaDense[$0] })
        viaDense = StateVector(denseAmps)

        for i in 0..<4 { #expect(viaApply[i] == viaDense[i]) }
    }

    /// Same cross-check for a wider permutation — `mcx` with 4 controls on a 5-qubit state.
    @Test func `apply fast path matches manual dense multiply for an mcx-shaped matrix`() {
        let mcx = MultiControlledXGate.matrix(qubits: 5, controls: [0, 1, 2, 3], target: 4)
        let amps = (0..<32).map { Complex(sin(Double($0)), cos(Double($0))) }

        var viaApply = StateVector(amps)
        viaApply.apply(mcx)

        var viaDense = StateVector(amps)
        let denseAmps = mcx.multiply(by: (0..<32).map { viaDense[$0] })
        viaDense = StateVector(denseAmps)

        for i in 0..<32 { #expect(viaApply[i] == viaDense[i]) }
    }

    /// A dense (non-permutation) gate still goes through the original path unchanged —
    /// `apply(_:)` on `HadamardGate.matrix` matches its known closed-form action.
    @Test func `apply still handles dense gates correctly`() {
        var state = StateVector.zero
        state.apply(HadamardGate.matrix)
        let expected = 1.0 / sqrt(2.0)
        #expect(abs(state[0].real - expected) < 1e-12)
        #expect(abs(state[1].real - expected) < 1e-12)
    }
}
