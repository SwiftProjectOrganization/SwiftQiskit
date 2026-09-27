//
//  StateTomography.swift
//  SwiftQiskit
//
//  Reconstructing a single qubit's Bloch vector from shot counts alone.
//

import Foundation

/// Namespace for turning per-basis `measure(shots:basis:)` results into a reconstructed
/// Bloch vector — the shot-based estimator every axis of page `20Tomography` (and the
/// app's Tomography chapter) hand-rolls today.
///
/// Returns plain `(x:, y:, z:)` tuples rather than a package-level `BlochVector` type:
/// every playground page already auto-imports its own `BlochVector` from
/// `Playgrounds.playground/Sources/`, and a same-named Core type would collide with it. A
/// single package-level `BlochVector` remains a separate open-systems TODO
/// (`STATUSandTODO.md`, "Proposed Core extensions — open systems").
///
/// This is a shot-noise-aware rescale, not a maximum-likelihood or linear-inversion
/// reconstruction — see `clampToPhysical(_:)`.
public enum StateTomography {

    /// The single-qubit ±1 estimate `(N₀ − N₁)/N` for `qubit`, from a `result` already
    /// measured in the desired basis — a named wrapper over
    /// `SimulationResult.parityExpectation(qubits:)` for a single qubit.
    public static func estimate(qubit: Int, result: SimulationResult) -> Double {
        result.parityExpectation(qubits: [qubit])
    }

    /// Runs three settings — every qubit measured in X, then in Y, then in Z — via
    /// `circuit.measure(shots:basis:)`, and returns `qubit`'s estimated Bloch vector.
    /// Spends `shots` per setting (`3 · shots` total), and never mutates `circuit`.
    public static func estimateBlochVector(
        of circuit: QuantumCircuit,
        qubit: Int,
        shots: Int
    ) -> (x: Double, y: Double, z: Double) {
        precondition(qubit >= 0 && qubit < circuit.qubits, "Qubit index out of range")

        func settle(_ basis: PauliBasis) -> Double {
            let result = circuit.measure(shots: shots, basis: Array(repeating: basis, count: circuit.qubits))
            return estimate(qubit: qubit, result: result)
        }

        return (x: settle(.x), y: settle(.y), z: settle(.z))
    }

    /// Packages a three-axis estimate as a Bloch vector, with `isPhysical` reporting
    /// whether its magnitude is within `tolerance` of the unit ball (`|r| ≤ 1`). A *pure*
    /// state's per-axis shot estimate lands outside the ball about half the time at any
    /// shot count — see `PlaygroundDocs/20TOMOGRAPHYHELP.md` — so `isPhysical == false`
    /// here is expected, not a bug.
    public static func reconstructSingleQubit(
        x: Double,
        y: Double,
        z: Double,
        tolerance: Double = 1e-9
    ) -> (vector: (x: Double, y: Double, z: Double), isPhysical: Bool) {
        let magnitude = sqrt(x * x + y * y + z * z)
        return ((x: x, y: y, z: z), magnitude <= 1 + tolerance)
    }

    /// Rescales an out-of-ball estimate back onto the unit sphere (`r → r/|r|`), leaving
    /// an already-physical vector unchanged. A named, tested version of page
    /// `20Tomography`'s rescaling idea — not a real MLE estimator.
    public static func clampToPhysical(
        _ v: (x: Double, y: Double, z: Double)
    ) -> (x: Double, y: Double, z: Double) {
        let magnitude = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
        guard magnitude > 1 else { return v }
        return (x: v.x / magnitude, y: v.y / magnitude, z: v.z / magnitude)
    }
}
