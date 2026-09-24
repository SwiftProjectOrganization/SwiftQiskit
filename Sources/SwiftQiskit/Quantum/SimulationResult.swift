//
//  SimulationResult.swift
//  SwiftQiskit
//
//  Represents measurement results from a quantum circuit
//

import Foundation

public struct SimulationResult {

    public let shots: Int
    public let counts: [String: Int]

    /// Returns counts sorted by state (binary ascending)
    public var sortedCounts: [(state: String, count: Int)] {
        counts
            .sorted { $0.key < $1.key }
            .map { (state: $0.key, count: $0.value) }
    }
}
