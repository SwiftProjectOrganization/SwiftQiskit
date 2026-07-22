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
    /// Measure the circuit multiple times and return counts
    public func measure(shots: Int) -> SimulationResult {
        precondition(shots > 0, "Number of shots must be positive")

        var counts: [String: Int] = [:]

        for _ in 0..<shots {
            let result = runAndMeasure()
            let binary = String(result, radix: 2)
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
// MARK: - Single-Qubit Gates
public extension QuantumCircuit {
    /// Apply CNOT gate (control -> target)
    func cx(_ control: Int, _ target: Int) {
        precondition(qubits == 2, "cx currently supports only 2-qubit circuits")
        precondition(control == 0 && target == 1, "Only cx(0,1) supported in v0.1")

        apply(CNOTGate.matrix)
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
    /// Apply Pauli-Z gate to a specific qubit
    func z(_ qubit: Int) {
        let full = embedSingleQubitGate(
            PauliZGate.matrix,
            qubits: qubits,
            target: qubit
        )
        apply(full)
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
