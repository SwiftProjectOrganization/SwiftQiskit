//
//  StateVector+Kernels.swift
//  SwiftQiskit
//
//  Applies a gate's small local tensor directly to the amplitudes, in place, in O(2ⁿ) time
//  and O(1) extra memory per gate — no 2ⁿ×2ⁿ embedding. This is what lets
//  `QuantumCircuit.run()` scale past a handful of qubits.
//

import Foundation

/// Wraps a raw pointer so it can be captured by `concurrentPerform`'s closure. Safe here
/// because every chunk touches a disjoint set of amplitude indices.
private struct SharedPointer: @unchecked Sendable {
    let base: UnsafeMutablePointer<Complex>
}

extension StateVector {

    /// States at least this large are updated across CPU cores.
    static let parallelThreshold = 1 << 14

    /// Applies `tensor` (2^k × 2^k, or 1×1 for a leg-less scalar) to the qubits `targets`
    /// (leg order as given, qubit 0 = MSB — Core's convention), leaving every other qubit a
    /// spectator. Equivalent to `apply(fullEmbedding)` but without building it, and without
    /// the per-gate renormalization (callers pass unitaries).
    ///
    /// The state splits into 2ⁿ⁻ᵏ independent groups of 2ᵏ amplitudes (one per setting of the
    /// spectator qubits). Each group is gathered, multiplied by the tensor's non-zero entries
    /// only (so permutation, diagonal and controlled gates cost almost nothing extra), and
    /// scattered back.
    mutating func applyLocal(_ tensor: Matrix, targets: [Int], parallel: Bool = true) {
        let n = dimension.trailingZeroBitCount

        guard !targets.isEmpty else {
            precondition(tensor.rows == 1 && tensor.cols == 1, "A leg-less tensor must be a scalar")
            let scalar = tensor[0, 0]
            for i in amplitudes.indices { amplitudes[i] = amplitudes[i] * scalar }
            return
        }

        let k = targets.count
        precondition(Set(targets).count == k, "Target qubits must be distinct")
        precondition(targets.allSatisfy { $0 >= 0 && $0 < n }, "Target qubit out of range")
        precondition(tensor.rows == 1 << k && tensor.cols == 1 << k,
                     "Tensor dimension must match 2^(number of target qubits)")

        let size = 1 << k

        // offset[s]: index offset of sub-state s (first target = most-significant bit of s).
        var offsets = [Int](repeating: 0, count: size)
        for s in 0..<size {
            for (position, q) in targets.enumerated() where (s >> (k - 1 - position)) & 1 == 1 {
                offsets[s] |= 1 << (n - 1 - q)
            }
        }

        // Sparse rows: for each output row r, the non-zero (column, value) pairs.
        var rowStart = [Int](repeating: 0, count: size + 1)
        var columns: [Int] = []
        var values: [Complex] = []
        for r in 0..<size {
            for c in 0..<size {
                let v = tensor[r, c]
                if v != .zero { columns.append(c); values.append(v) }
            }
            rowStart[r + 1] = columns.count
        }

        // Bit positions (ascending) at which a group number gets a 0 bit inserted.
        let insertAt = targets.map { n - 1 - $0 }.sorted()
        let groupCount = 1 << (n - k)

        // Handles groups [lo, hi) with its own scratch buffer.
        func process(_ base: UnsafeMutablePointer<Complex>, _ lo: Int, _ hi: Int) {
            var gathered = [Complex](repeating: .zero, count: size)
            for group in lo..<hi {
                var index = group
                for position in insertAt {
                    index = ((index >> position) << (position + 1)) | (index & ((1 << position) - 1))
                }
                for s in 0..<size { gathered[s] = base[index + offsets[s]] }
                for r in 0..<size {
                    var sum = Complex.zero
                    for e in rowStart[r]..<rowStart[r + 1] {
                        sum = sum + values[e] * gathered[columns[e]]
                    }
                    base[index + offsets[r]] = sum
                }
            }
        }

        amplitudes.withUnsafeMutableBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            if parallel && buffer.count >= StateVector.parallelThreshold && groupCount > 1 {
                let shared = SharedPointer(base: base)
                let chunks = min(groupCount, ProcessInfo.processInfo.activeProcessorCount * 4)
                let chunkSize = (groupCount + chunks - 1) / chunks
                DispatchQueue.concurrentPerform(iterations: chunks) { chunk in
                    let lo = chunk * chunkSize
                    let hi = min(lo + chunkSize, groupCount)
                    if lo < hi { process(shared.base, lo, hi) }
                }
            } else {
                process(base, 0, groupCount)
            }
        }
    }
}
