//
//  QuantumCircuit.swift
//  SwiftQiskit
//
//  High-level abstraction for building and running quantum circuits.
//
//  Created by Ali on 2025-01-XX.
//
import Foundation
// MARK: - QuantumCircuit
public final class QuantumCircuit {

    // MARK: - Types
    private struct Operation {
        let matrix: Matrix
    }

    // MARK: - Properties
    public let qubits: Int
    private var operations: [Operation] = []

    // MARK: - Initializer
    public init(qubits: Int) {
        precondition(qubits > 0, "Number of qubits must be positive")
        self.qubits = qubits
    }

    // MARK: - Core Gate API

    /// Apply a full-dimension gate (2^n x 2^n)
    public func apply(_ matrix: Matrix) {
        let expectedDim = 1 << qubits
        precondition(
            matrix.rows == expectedDim && matrix.cols == expectedDim,
            "Gate matrix must match circuit dimension (2^n x 2^n)"
        )
        operations.append(Operation(matrix: matrix))
    }

    // MARK: - Execution
    /// Measure the circuit multiple times and return counts.
    ///
    /// Runs the circuit once and draws `shots` samples from the resulting probability
    /// distribution, rather than replaying every recorded operation per shot: only the final
    /// random draw differs shot to shot, since a full measurement of a pure state never
    /// changes the state itself.
    public func measure(shots: Int) -> SimulationResult {
        precondition(shots > 0, "Number of shots must be positive")

        let probs = run().probabilities
        var counts: [String: Int] = [:]

        for _ in 0..<shots {
            let index = StateVector.sampleIndex(from: probs)
            let binary = String(index, radix: 2)
                .leftPadding(toLength: qubits, withPad: "0")

            counts[binary, default: 0] += 1
        }

        return SimulationResult(shots: shots, counts: counts)
    }

    /// Run the circuit and return the final state
    public func run() -> StateVector {
        var state = StateVector(qubits: qubits)
        for op in operations {
            state.apply(op.matrix)
        }
        return state
    }

    /// Run the circuit and measure once
    public func runAndMeasure() -> Int {
        var state = run()
        return state.measure()
    }
}
// MARK: - Gate API
public extension QuantumCircuit {
    /// Apply CNOT gate (control -> target); any distinct pair of qubits.
    func cx(_ control: Int, _ target: Int) {
        apply(CNOTGate.matrix(qubits: qubits, control: control, target: target))
    }

    /// Apply Hadamard gate to a specific qubit
    func h(_ qubit: Int) {
        let full = embedSingleQubitGate(
            HadamardGate.matrix,
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply Pauli-X gate to a specific qubit
    func x(_ qubit: Int) {
        let full = embedSingleQubitGate(
            PauliXGate.matrix,
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }
    /// Apply Pauli-Y gate to a specific qubit
    func y(_ qubit: Int) {
        let full = embedSingleQubitGate(
            PauliYGate.matrix,
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply Pauli-Z gate to a specific qubit
    func z(_ qubit: Int) {
        let full = embedSingleQubitGate(
            PauliZGate.matrix,
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply S gate (phase π/2) to a specific qubit
    func s(_ qubit: Int) {
        let full = embedSingleQubitGate(
            SGate.matrix,
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply S† gate (phase -π/2) to a specific qubit
    func sdg(_ qubit: Int) {
        let full = embedSingleQubitGate(
            SDaggerGate.matrix,
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply T gate (phase π/4) to a specific qubit
    func t(_ qubit: Int) {
        let full = embedSingleQubitGate(
            TGate.matrix,
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply T† gate (phase -π/4) to a specific qubit
    func tdg(_ qubit: Int) {
        let full = embedSingleQubitGate(
            TDaggerGate.matrix,
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply phase gate P(θ) to a specific qubit
    func p(_ theta: Double, _ qubit: Int) {
        let full = embedSingleQubitGate(
            PhaseGate.matrix(theta: theta),
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply rotation RX(θ) about the X axis to a specific qubit
    func rx(_ theta: Double, _ qubit: Int) {
        let full = embedSingleQubitGate(
            RXGate.matrix(theta: theta),
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply rotation RY(θ) about the Y axis to a specific qubit
    func ry(_ theta: Double, _ qubit: Int) {
        let full = embedSingleQubitGate(
            RYGate.matrix(theta: theta),
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply rotation RZ(θ) about the Z axis to a specific qubit
    func rz(_ theta: Double, _ qubit: Int) {
        let full = embedSingleQubitGate(
            RZGate.matrix(theta: theta),
            qubits: qubits,
            target: qubit
        )
        apply(full)
    }

    /// Apply the two-qubit rotation exp(-iθ·Z⊗Z/2) to any distinct pair of qubits.
    /// Equivalent to `pauliRotation` with `Z` at `q0`/`q1` and `I` elsewhere — expands to
    /// exactly `cx(q0, q1); rz(theta, q1); cx(q0, q1)`.
    func rzz(_ theta: Double, _ q0: Int, _ q1: Int) {
        pauliRotation(pauliString(q0: q0, q1: q1, pauli: "Z"), theta: theta)
    }

    /// Apply the two-qubit rotation exp(-iθ·X⊗X/2) to any distinct pair of qubits.
    func rxx(_ theta: Double, _ q0: Int, _ q1: Int) {
        pauliRotation(pauliString(q0: q0, q1: q1, pauli: "X"), theta: theta)
    }

    /// Apply the two-qubit rotation exp(-iθ·Y⊗Y/2) to any distinct pair of qubits.
    func ryy(_ theta: Double, _ q0: Int, _ q1: Int) {
        pauliRotation(pauliString(q0: q0, q1: q1, pauli: "Y"), theta: theta)
    }

    /// Builds a `qubits`-length Pauli string with `pauli` at `q0` and `q1` and `I`
    /// elsewhere, for the `rzz`/`rxx`/`ryy` wrappers above.
    private func pauliString(q0: Int, q1: Int, pauli: Character) -> String {
        precondition(q0 >= 0 && q0 < qubits && q1 >= 0 && q1 < qubits,
                     "Qubit index out of range")
        precondition(q0 != q1, "The two qubits must differ")
        var chars = Array(repeating: Character("I"), count: qubits)
        chars[q0] = pauli
        chars[q1] = pauli
        return String(chars)
    }

    /// Apply exp(-iθ·P/2) for an arbitrary Pauli string `pauli` (e.g. `"XIZ"`, one character
    /// per qubit, `I`/`X`/`Y`/`Z` only), via a basis change into Z on every non-identity
    /// qubit (`h` for X, `sdg;h` for Y), a CNOT staircase computing the joint parity of every
    /// active qubit into the last one, a single `rz` there, the staircase undone, and the
    /// basis change undone. An all-`I` string is the global phase e^{-iθ/2}·I, applied
    /// directly so the circuit matches `expm()` exactly rather than dropping the phase.
    func pauliRotation(_ pauli: String, theta: Double) {
        precondition(pauli.count == qubits, "Pauli string must have one character per qubit")
        let chars = Array(pauli)
        precondition(chars.allSatisfy { "IXYZ".contains($0) },
                     "Pauli string may only contain I, X, Y, Z")

        let active = chars.indices.filter { chars[$0] != "I" }

        guard !active.isEmpty else {
            let globalPhase = Complex(cos(theta / 2), -sin(theta / 2))
            apply(Matrix.identity(size: 1 << qubits) * globalPhase)
            return
        }

        for i in active {
            switch chars[i] {
            case "X": h(i)
            case "Y": sdg(i); h(i)
            default: break
            }
        }

        for k in 0..<(active.count - 1) {
            cx(active[k], active[k + 1])
        }
        rz(theta, active.last!)
        for k in stride(from: active.count - 2, through: 0, by: -1) {
            cx(active[k], active[k + 1])
        }

        for i in active {
            switch chars[i] {
            case "X": h(i)
            case "Y": h(i); s(i)
            default: break
            }
        }
    }

}
/// Embed a single-qubit gate into an n-qubit system at a specific qubit index.
/// Qubit indexing: 0 = most-significant (leftmost)
private func embedSingleQubitGate(
    _ gate: Matrix,
    qubits: Int,
    target: Int
) -> Matrix {
    precondition(target >= 0 && target < qubits, "Target qubit out of range")

    var result: Matrix? = nil

    for i in 0..<qubits {
        let factor: Matrix = (i == target) ? gate : Matrix.identity(size: 2)
        if result == nil {
            result = factor
        } else {
            result = result! ⊗ factor
        }
    }

    return result!
}
