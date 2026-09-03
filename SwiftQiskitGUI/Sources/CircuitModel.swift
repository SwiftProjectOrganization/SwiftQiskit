//
//  CircuitModel.swift
//  SwiftQiskitGUI
//
//  Front-end model for interactively constructing a QuantumCircuit.
//  QuantumCircuit itself only records the resulting full-dimension matrices
//  (no gate identity/qubit metadata), so the builder keeps its own record of
//  placed gates and replays them onto a fresh QuantumCircuit to run.
//

import Foundation
import SwiftQiskitCore

// MARK: - GateKind

public enum GateKind: Equatable, Hashable {
    case h, x, y, z, s, sdg, t, tdg
    case p(Double)
    case rx(Double)
    case ry(Double)
    case rz(Double)
    case cx

    public var symbol: String {
        switch self {
        case .h: return "H"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .s: return "S"
        case .sdg: return "S†"
        case .t: return "T"
        case .tdg: return "T†"
        case .p: return "P"
        case .rx: return "RX"
        case .ry: return "RY"
        case .rz: return "RZ"
        case .cx: return "CX"
        }
    }

    /// Number of qubits this gate occupies (1 for single-qubit gates, 2 for CX).
    public var qubitSpan: Int {
        if case .cx = self { return 2 }
        return 1
    }

    public var isParameterized: Bool {
        theta != nil
    }

    public var theta: Double? {
        switch self {
        case .p(let t), .rx(let t), .ry(let t), .rz(let t): return t
        default: return nil
        }
    }

    /// Returns the same gate with a new angle; a no-op for non-parameterized gates.
    public func withTheta(_ newTheta: Double) -> GateKind {
        switch self {
        case .p: return .p(newTheta)
        case .rx: return .rx(newTheta)
        case .ry: return .ry(newTheta)
        case .rz: return .rz(newTheta)
        default: return self
        }
    }
}

// MARK: - PlacedGate

public struct PlacedGate: Identifiable, Equatable {
    public let id: UUID
    public var kind: GateKind
    public var qubits: [Int]
    public var column: Int

    public init(id: UUID = UUID(), kind: GateKind, qubits: [Int], column: Int) {
        self.id = id
        self.kind = kind
        self.qubits = qubits
        self.column = column
    }
}

// MARK: - CircuitBuilder

@Observable
public final class CircuitBuilder {

    public static let minQubits = 1
    public static let maxQubits = 8

    public var qubitCount: Int {
        didSet {
            let clamped = min(max(qubitCount, Self.minQubits), Self.maxQubits)
            if clamped != qubitCount {
                qubitCount = clamped
                return
            }
            gates.removeAll { gate in gate.qubits.contains { $0 >= qubitCount } }
        }
    }

    public var gates: [PlacedGate] = []

    public init(qubitCount: Int = 2) {
        self.qubitCount = min(max(qubitCount, Self.minQubits), Self.maxQubits)
    }

    /// One past the highest occupied column (0 if empty).
    public func columnCount() -> Int {
        (gates.map(\.column).max() ?? -1) + 1
    }

    public func gate(atColumn column: Int, qubit: Int) -> PlacedGate? {
        gates.first { $0.column == column && $0.qubits.contains(qubit) }
    }

    public func isOccupied(column: Int, qubit: Int) -> Bool {
        gate(atColumn: column, qubit: qubit) != nil
    }

    /// Places a gate if every target qubit is in range and free at that column.
    @discardableResult
    public func place(_ kind: GateKind, qubits: [Int], column: Int) -> Bool {
        guard qubits.allSatisfy({ $0 >= 0 && $0 < qubitCount }) else { return false }
        guard qubits.allSatisfy({ !isOccupied(column: column, qubit: $0) }) else { return false }
        gates.append(PlacedGate(kind: kind, qubits: qubits, column: column))
        return true
    }

    public func remove(id: UUID) {
        gates.removeAll { $0.id == id }
    }

    public func updateTheta(id: UUID, theta: Double) {
        guard let index = gates.firstIndex(where: { $0.id == id }) else { return }
        gates[index].kind = gates[index].kind.withTheta(theta)
    }

    public func clear() {
        gates.removeAll()
    }

    /// Replays the placed gates, in column order, onto a fresh QuantumCircuit.
    public func buildCircuit() -> QuantumCircuit {
        let circuit = QuantumCircuit(qubits: qubitCount)
        for gate in gates.sorted(by: { $0.column < $1.column }) {
            apply(gate, to: circuit)
        }
        return circuit
    }

    private func apply(_ gate: PlacedGate, to circuit: QuantumCircuit) {
        switch gate.kind {
        case .h: circuit.h(gate.qubits[0])
        case .x: circuit.x(gate.qubits[0])
        case .y: circuit.y(gate.qubits[0])
        case .z: circuit.z(gate.qubits[0])
        case .s: circuit.s(gate.qubits[0])
        case .sdg: circuit.sdg(gate.qubits[0])
        case .t: circuit.t(gate.qubits[0])
        case .tdg: circuit.tdg(gate.qubits[0])
        case .p(let theta): circuit.p(theta, gate.qubits[0])
        case .rx(let theta): circuit.rx(theta, gate.qubits[0])
        case .ry(let theta): circuit.ry(theta, gate.qubits[0])
        case .rz(let theta): circuit.rz(theta, gate.qubits[0])
        case .cx: circuit.cx(gate.qubits[0], gate.qubits[1])
        }
    }
}
