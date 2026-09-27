//
//  NoiseModel.swift
//  SwiftQiskit
//
//  Maps gate applications in a `QuantumCircuit` to per-qubit `KrausChannel`s, for
//  `runDensityMatrix(noise:)`/`runTrajectories(noise:shots:)`.
//

import Foundation

/// A noise model applied after every gate in a circuit: `singleQubitGate` after every
/// qubit a 1-qubit gate touched, `multiQubitGate` after every qubit a 2-or-more-qubit gate
/// touched (each qubit independently — this is not a genuinely correlated multi-qubit
/// channel, just a coarser single-qubit rate for the "longer" multi-qubit gates real
/// hardware tends to have). Either may be `nil` to skip noise for that gate class.
public struct NoiseModel {

    /// Applied to every qubit touched by a single-qubit gate, if not `nil`.
    public let singleQubitGate: KrausChannel?

    /// Applied to every qubit touched by a multi-qubit gate (`cx`, `ccx`, `mcx`, …), if
    /// not `nil`.
    public let multiQubitGate: KrausChannel?

    /// Both channels must be single-qubit (2×2) and trace-preserving — they're applied
    /// per-qubit via `KrausChannel.apply(to:qubit:)`, never to a multi-qubit block directly.
    public init(singleQubitGate: KrausChannel? = nil, multiQubitGate: KrausChannel? = nil) {
        for channel in [singleQubitGate, multiQubitGate].compactMap({ $0 }) {
            precondition(channel.operators[0].rows == 2,
                         "NoiseModel channels must be single-qubit (2x2)")
            precondition(channel.isTracePreserving(),
                         "NoiseModel channels must be trace-preserving")
        }
        self.singleQubitGate = singleQubitGate
        self.multiQubitGate = multiQubitGate
    }

    /// The same `channel` applied after both single- and multi-qubit gates.
    public static func uniform(_ channel: KrausChannel) -> NoiseModel {
        NoiseModel(singleQubitGate: channel, multiQubitGate: channel)
    }
}
