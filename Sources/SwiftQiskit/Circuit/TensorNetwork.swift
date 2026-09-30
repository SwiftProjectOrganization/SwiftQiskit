//
//  TensorNetwork.swift
//  SwiftQiskit
//
//  A tensor-network view of a `QuantumCircuit`: every `|0⟩` input, every recorded gate,
//  and every open output leg becomes a node, wired together by one edge per wire segment.
//  `contract()` evaluates the network from only those small local tensors and the wiring —
//  never the full 2ⁿ×2ⁿ matrices `QuantumCircuit.run()` uses — so agreement between the two
//  is an independent check of both.
//

import Foundation

// MARK: - TensorNetwork

public struct TensorNetwork {

    /// What a node represents. `.gate` carries the gate's `QuantumCircuit` label (`"H"`,
    /// `"CX"`, `"RX(1.571)"`, …) — see `QuantumCircuit.Operation.name`. The all-identity
    /// global phase `pauliRotation` can append is also a `.gate("phase")` node, with no
    /// qubit legs at all (a disconnected scalar).
    public enum Kind: Equatable {
        case input
        case gate(String)
        case output
    }

    /// One node in the network.
    public struct Node {
        public let id: Int
        public let kind: Kind
        /// The qubits this node's legs connect to, in the local tensor's leg order.
        /// Empty only for the leg-less global-phase `.gate("phase")` node.
        public let qubits: [Int]
        /// Layout column (time step), used for drawing — ASAP-scheduled: a node's column is
        /// one more than the latest column already reached on any qubit it touches, so gates
        /// on disjoint qubits can share a column.
        public let column: Int
        /// The node's own small tensor: 2^qubits.count × 2^qubits.count for a gate (1×1 for
        /// the leg-less phase node), or a 2×1 ket/1×2-shaped placeholder for `.input`/
        /// `.output` (not consumed by `contract()`, which starts every qubit at `|0⟩` and
        /// reads amplitudes straight off the wires; present so a drawing has something to
        /// show at the two ends of every wire).
        public let tensor: Matrix
    }

    /// One wire segment between two nodes, carrying a single qubit (bond dimension 2).
    public struct Edge {
        public let id: Int
        public let qubit: Int
        public let from: Int
        public let to: Int
    }

    public let qubits: Int
    public let nodes: [Node]
    public let edges: [Edge]
    /// One past the highest column any node occupies.
    public let columns: Int

    /// Builds the network for `circuit`'s currently recorded operations. One `.input` node
    /// per qubit at column 0, one `.gate` node per recorded operation (see
    /// `QuantumCircuit.operationRecords`), and one `.output` node per qubit at the final
    /// column — each gate wired to the most recent node on every qubit it touches.
    public init(_ circuit: QuantumCircuit) {
        let n = circuit.qubits
        qubits = n

        var nodes: [Node] = []
        var edges: [Edge] = []
        var nextNodeID = 0
        var nextEdgeID = 0
        var lastNode = [Int](repeating: -1, count: n)
        var lastColumn = [Int](repeating: 0, count: n)

        for q in 0..<n {
            let id = nextNodeID; nextNodeID += 1
            nodes.append(Node(id: id, kind: .input, qubits: [q], column: 0,
                               tensor: Matrix([[Complex.one], [Complex.zero]])))
            lastNode[q] = id
        }

        for op in circuit.operationRecords {
            let column = op.qubits.isEmpty
                ? 1 + (lastColumn.max() ?? 0)
                : 1 + op.qubits.map { lastColumn[$0] }.max()!

            let id = nextNodeID; nextNodeID += 1
            nodes.append(Node(id: id, kind: .gate(op.name), qubits: op.qubits, column: column, tensor: op.local))

            for q in op.qubits {
                let edgeID = nextEdgeID; nextEdgeID += 1
                edges.append(Edge(id: edgeID, qubit: q, from: lastNode[q], to: id))
                lastNode[q] = id
                lastColumn[q] = column
            }
        }

        let finalColumn = (lastColumn.max() ?? 0) + 1
        for q in 0..<n {
            let id = nextNodeID; nextNodeID += 1
            let edgeID = nextEdgeID; nextEdgeID += 1
            edges.append(Edge(id: edgeID, qubit: q, from: lastNode[q], to: id))
            nodes.append(Node(id: id, kind: .output, qubits: [q], column: finalColumn,
                               tensor: Matrix.identity(size: 2)))
        }

        self.nodes = nodes
        self.edges = edges
        columns = finalColumn + 1
    }

    /// Contracts the network into the final state, from `|0…0⟩` through every `.gate` node
    /// in the order the circuit recorded them — applying only each node's own small
    /// `tensor` to the legs it names, never the full embedded matrix. Agreement with
    /// `circuit.run()` (built from the full matrices) is therefore an independent check of
    /// this type's wiring and contraction.
    public func contract() -> StateVector {
        var amplitudes = [Complex](repeating: .zero, count: 1 << qubits)
        amplitudes[0] = .one

        for node in nodes {
            guard case .gate = node.kind else { continue }
            amplitudes = TensorNetwork.apply(node.tensor, targets: node.qubits, totalQubits: qubits, to: amplitudes)
        }
        return StateVector(amplitudes)
    }

    /// Applies a local tensor (`2^targets.count × 2^targets.count`, or 1×1 for a leg-less
    /// scalar) to `amplitudes`, treating `targets` (in the given leg order, qubit 0 = MSB —
    /// Core's convention throughout) as the only qubits it touches and leaving every other
    /// qubit's value as a spectator. For each fixed setting of the spectator qubits, the
    /// `2^targets.count` amplitudes matching every value of the target qubits are gathered,
    /// multiplied by `tensor`, and scattered back — the same idea
    /// `QuantumCircuit.embedSingleQubitGate` uses for one qubit, generalized to an arbitrary
    /// target set without ever building the full embedded matrix.
    private static func apply(_ tensor: Matrix, targets: [Int], totalQubits n: Int, to amplitudes: [Complex]) -> [Complex] {
        guard !targets.isEmpty else {
            precondition(tensor.rows == 1 && tensor.cols == 1, "A leg-less tensor must be a scalar")
            let scalar = tensor[0, 0]
            return amplitudes.map { $0 * scalar }
        }

        let k = targets.count
        precondition(tensor.rows == 1 << k && tensor.cols == 1 << k,
                     "Tensor dimension must match 2^(number of target qubits)")

        let spectators = (0..<n).filter { !targets.contains($0) }
        var result = amplitudes

        for group in 0..<(1 << spectators.count) {
            var baseIndices = [Int](repeating: 0, count: 1 << k)
            for sub in 0..<(1 << k) {
                var index = 0
                for (position, q) in spectators.enumerated() {
                    let bit = (group >> (spectators.count - 1 - position)) & 1
                    index |= bit << (n - 1 - q)
                }
                for (position, q) in targets.enumerated() {
                    let bit = (sub >> (k - 1 - position)) & 1
                    index |= bit << (n - 1 - q)
                }
                baseIndices[sub] = index
            }

            let slice = baseIndices.map { amplitudes[$0] }
            let transformed = tensor.multiply(by: slice)
            for sub in 0..<(1 << k) {
                result[baseIndices[sub]] = transformed[sub]
            }
        }

        return result
    }
}
