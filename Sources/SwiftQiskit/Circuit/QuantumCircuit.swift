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
    struct Operation {
        let matrix: Matrix
        /// The qubits this operation acts on, used by `runDensityMatrix(noise:)`/
        /// `runTrajectories(noise:shots:)` to know where to apply per-gate noise.
        let qubits: [Int]
        /// A short human-readable gate label (`"H"`, `"CX"`, `"RX(1.571)"`, …), used by
        /// `TensorNetwork` to label each node.
        let name: String
        /// The gate's own small tensor — 2^qubits.count × 2^qubits.count (or 1×1 for a
        /// leg-less global phase) — in the leg order `qubits` lists, *not* embedded across
        /// the full register. `matrix` above stays the full 2ⁿ×2ⁿ embedding every existing
        /// caller (`run()` etc.) uses; `local` is only consumed by `TensorNetwork`, which
        /// contracts from these small tensors rather than the full matrices, making its
        /// result an independent check of `run()`.
        let local: Matrix
    }

    // MARK: - Properties
    public let qubits: Int
    private var operations: [Operation] = []

    /// This circuit's recorded operations, in order — each one's name, the qubits it
    /// acts on, and its local (un-embedded) tensor. Internal: consumed by `TensorNetwork`'s
    /// `init(_:)`, not part of the public gate-building API.
    var operationRecords: [Operation] { operations }

    // MARK: - Initializer
    public init(qubits: Int) {
        precondition(qubits > 0, "Number of qubits must be positive")
        self.qubits = qubits
    }

    // MARK: - Core Gate API

    /// Apply a full-dimension gate (2^n x 2^n). Recorded as touching every qubit — an
    /// arbitrary caller-supplied matrix could act on any of them, so there's no narrower
    /// answer to give a noise model than "all of them".
    public func apply(_ matrix: Matrix) {
        let expectedDim = 1 << qubits
        precondition(
            matrix.rows == expectedDim && matrix.cols == expectedDim,
            "Gate matrix must match circuit dimension (2^n x 2^n)"
        )
        record(matrix, actingOn: Array(0..<qubits), name: "U", local: matrix)
    }

    /// Records an operation, the qubits it acts on, and its name/local tensor for
    /// `TensorNetwork`. Used internally by every gate method below (instead of the public
    /// `apply(_:)`) so `runDensityMatrix(noise:)`/`runTrajectories(noise:shots:)` can place
    /// per-gate noise precisely, rather than on every qubit for every gate.
    private func record(_ matrix: Matrix, actingOn: [Int], name: String, local: Matrix) {
        operations.append(Operation(matrix: matrix, qubits: actingOn, name: name, local: local))
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

    /// Runs this circuit's operations on a density matrix (starting from |0…0⟩⟨0…0|),
    /// optionally applying `noise`'s single-/multi-qubit channel to every qubit a gate
    /// touched, right after that gate. With `noise: nil` this is mathematically identical
    /// to `DensityMatrix(run())` — the exact result, no Monte-Carlo sampling.
    public func runDensityMatrix(noise: NoiseModel? = nil) -> DensityMatrix {
        var rho = DensityMatrix(StateVector(qubits: qubits))
        for op in operations {
            rho = rho.apply(op.matrix)
            guard let noise = noise, !op.qubits.isEmpty else { continue }
            guard let channel = op.qubits.count == 1 ? noise.singleQubitGate : noise.multiQubitGate else { continue }
            for qubit in op.qubits {
                rho = channel.apply(to: rho, qubit: qubit)
            }
        }
        return rho
    }

    /// The Monte-Carlo "quantum trajectories" unraveling of `runDensityMatrix(noise:)`:
    /// runs `shots` independent pure-state simulations, each stochastically applying one
    /// Kraus operator (chosen with probability ‖Kᵢ|ψ⟩‖²) after every noisy gate, then
    /// measures once per shot. Converges to `runDensityMatrix(noise:)`'s probabilities as
    /// `shots` grows.
    public func runTrajectories(noise: NoiseModel, shots: Int) -> SimulationResult {
        precondition(shots > 0, "Number of shots must be positive")

        var counts: [String: Int] = [:]
        for _ in 0..<shots {
            var state = StateVector(qubits: qubits)
            for op in operations {
                state.apply(op.matrix)
                guard !op.qubits.isEmpty else { continue }
                guard let channel = op.qubits.count == 1 ? noise.singleQubitGate : noise.multiQubitGate else { continue }
                for qubit in op.qubits {
                    state = applyChannelTrajectory(channel, to: state, qubit: qubit)
                }
            }
            let index = state.measure()
            let binary = String(index, radix: 2).leftPadding(toLength: qubits, withPad: "0")
            counts[binary, default: 0] += 1
        }
        return SimulationResult(shots: shots, counts: counts)
    }
}

private extension QuantumCircuit {

    /// Stochastically applies one operator of `channel`, embedded onto `qubit`, to
    /// `state` — chosen with probability ‖Kᵢ|ψ⟩‖², the Monte-Carlo unraveling of the
    /// channel. Used by `runTrajectories(noise:shots:)`.
    func applyChannelTrajectory(_ channel: KrausChannel, to state: StateVector, qubit: Int) -> StateVector {
        let embedded = channel.operators.map { embedSingleQubitGate($0, qubits: qubits, target: qubit) }
        let weights = embedded.map { op in
            op.multiply(by: state.amplitudes).reduce(0.0) { $0 + $1.magnitudeSquared }
        }
        let totalWeight = weights.reduce(0.0, +)
        precondition(totalWeight > 1e-12, "Kraus channel annihilated the state (not trace-preserving?)")
        let normalizedWeights = weights.map { $0 / totalWeight }

        let choice = StateVector.sampleIndex(from: normalizedWeights)
        var result = state
        result.apply(embedded[choice])
        return result
    }
}
// MARK: - Gate API
public extension QuantumCircuit {
    /// Apply CNOT gate (control -> target); any distinct pair of qubits.
    func cx(_ control: Int, _ target: Int) {
        record(CNOTGate.matrix(qubits: qubits, control: control, target: target), actingOn: [control, target],
               name: "CX", local: CNOTGate.matrix)
    }

    /// Apply Toffoli gate (CCNOT): flips `target` iff both controls are 1;
    /// any three distinct qubits.
    func ccx(_ control1: Int, _ control2: Int, _ target: Int) {
        record(ToffoliGate.matrix(qubits: qubits, control1: control1, control2: control2, target: target),
               actingOn: [control1, control2, target], name: "CCX", local: ToffoliGate.matrix)
    }

    /// Apply a multi-controlled X (flips `target` iff every qubit in `controls` is 1) to
    /// any distinct set of qubits. `controls` may be empty (an unconditional flip,
    /// equivalent to `x(target)`); one control is equivalent to `cx`, two to `ccx`.
    func mcx(_ controls: [Int], _ target: Int) {
        let local = MultiControlledXGate.matrix(
            qubits: controls.count + 1, controls: Array(0..<controls.count), target: controls.count
        )
        record(MultiControlledXGate.matrix(qubits: qubits, controls: controls, target: target),
               actingOn: controls + [target], name: "MCX", local: local)
    }

    /// Apply controlled-Z (symmetric in its two qubits); any distinct pair of qubits.
    func cz(_ control: Int, _ target: Int) {
        record(ControlledZGate.matrix(qubits: qubits, control: control, target: target),
               actingOn: [control, target], name: "CZ", local: ControlledZGate.matrix)
    }

    /// Apply a multi-controlled Z (negates the amplitude where `target` and every qubit in
    /// `controls` are 1) to any distinct set of qubits. `controls` may be empty (equivalent
    /// to `z(target)`); one control is equivalent to `cz`, two to CCZ.
    func mcz(_ controls: [Int], _ target: Int) {
        let local = MultiControlledZGate.matrix(
            qubits: controls.count + 1, controls: Array(0..<controls.count), target: controls.count
        )
        record(MultiControlledZGate.matrix(qubits: qubits, controls: controls, target: target),
               actingOn: controls + [target], name: "MCZ", local: local)
    }

    /// Apply SWAP, exchanging the states of any two distinct qubits.
    func swap(_ q0: Int, _ q1: Int) {
        record(SwapGate.matrix(qubits: qubits, q0: q0, q1: q1),
               actingOn: [q0, q1], name: "SWAP", local: SwapGate.matrix)
    }

    /// Apply Hadamard gate to a specific qubit
    func h(_ qubit: Int) {
        let full = embedSingleQubitGate(
            HadamardGate.matrix,
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "H", local: HadamardGate.matrix)
    }

    /// Apply Pauli-X gate to a specific qubit
    func x(_ qubit: Int) {
        let full = embedSingleQubitGate(
            PauliXGate.matrix,
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "X", local: PauliXGate.matrix)
    }
    /// Apply Pauli-Y gate to a specific qubit
    func y(_ qubit: Int) {
        let full = embedSingleQubitGate(
            PauliYGate.matrix,
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "Y", local: PauliYGate.matrix)
    }

    /// Apply Pauli-Z gate to a specific qubit
    func z(_ qubit: Int) {
        let full = embedSingleQubitGate(
            PauliZGate.matrix,
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "Z", local: PauliZGate.matrix)
    }

    /// Apply S gate (phase π/2) to a specific qubit
    func s(_ qubit: Int) {
        let full = embedSingleQubitGate(
            SGate.matrix,
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "S", local: SGate.matrix)
    }

    /// Apply S† gate (phase -π/2) to a specific qubit
    func sdg(_ qubit: Int) {
        let full = embedSingleQubitGate(
            SDaggerGate.matrix,
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "S†", local: SDaggerGate.matrix)
    }

    /// Apply T gate (phase π/4) to a specific qubit
    func t(_ qubit: Int) {
        let full = embedSingleQubitGate(
            TGate.matrix,
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "T", local: TGate.matrix)
    }

    /// Apply T† gate (phase -π/4) to a specific qubit
    func tdg(_ qubit: Int) {
        let full = embedSingleQubitGate(
            TDaggerGate.matrix,
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "T†", local: TDaggerGate.matrix)
    }

    /// Apply phase gate P(θ) to a specific qubit
    func p(_ theta: Double, _ qubit: Int) {
        let full = embedSingleQubitGate(
            PhaseGate.matrix(theta: theta),
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "P(\(formatted(theta)))", local: PhaseGate.matrix(theta: theta))
    }

    /// Apply rotation RX(θ) about the X axis to a specific qubit
    func rx(_ theta: Double, _ qubit: Int) {
        let full = embedSingleQubitGate(
            RXGate.matrix(theta: theta),
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "RX(\(formatted(theta)))", local: RXGate.matrix(theta: theta))
    }

    /// Apply rotation RY(θ) about the Y axis to a specific qubit
    func ry(_ theta: Double, _ qubit: Int) {
        let full = embedSingleQubitGate(
            RYGate.matrix(theta: theta),
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "RY(\(formatted(theta)))", local: RYGate.matrix(theta: theta))
    }

    /// Apply rotation RZ(θ) about the Z axis to a specific qubit
    func rz(_ theta: Double, _ qubit: Int) {
        let full = embedSingleQubitGate(
            RZGate.matrix(theta: theta),
            qubits: qubits,
            target: qubit
        )
        record(full, actingOn: [qubit], name: "RZ(\(formatted(theta)))", local: RZGate.matrix(theta: theta))
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

    /// Rotate `qubit` so that measuring it in the computational (Z) basis afterward is
    /// equivalent to measuring it in `basis`: `h` for X, `sdg; h` for Y, nothing for Z.
    /// Used directly by `measure(shots:basis:)` and by `pauliRotation`'s forward basis
    /// change below.
    func rotateToZ(_ basis: PauliBasis, _ qubit: Int) {
        switch basis {
        case .x: h(qubit)
        case .y: sdg(qubit); h(qubit)
        case .z: break
        }
    }

    /// Undo `rotateToZ`: `h` for X, `h; s` for Y, nothing for Z.
    private func rotateFromZ(_ basis: PauliBasis, _ qubit: Int) {
        switch basis {
        case .x: h(qubit)
        case .y: h(qubit); s(qubit)
        case .z: break
        }
    }

    /// Measure each qubit in its own Pauli basis and return shot counts, without mutating
    /// this circuit. Appends each qubit's `rotateToZ` rotation to a copy of the recorded
    /// operations, then measures that copy — the original circuit's operation list (and
    /// anything already built from it) is untouched.
    func measure(shots: Int, basis: [PauliBasis]) -> SimulationResult {
        precondition(basis.count == qubits, "Must supply one basis per qubit")

        let copy = QuantumCircuit(qubits: qubits)
        copy.operations = operations
        for (qubit, b) in basis.enumerated() {
            copy.rotateToZ(b, qubit)
        }
        return copy.measure(shots: shots)
    }

    /// Shot-based estimate of a single `PauliString`'s expectation value: rotates every
    /// non-identity qubit into the Z basis (identity qubits are measured in Z too, but
    /// excluded from the parity), then returns
    /// `pauli.coefficient · measure(shots:basis:).parityExpectation(qubits: pauli.activeQubits)`.
    /// An all-`I` string needs no sampling — its expectation is exactly `pauli.coefficient`
    /// on every state — so that case returns immediately. Built entirely on
    /// `measure(shots:basis:)`, so it never mutates this circuit.
    func measureExpectation(of pauli: PauliString, shots: Int) -> Double {
        precondition(pauli.qubits == qubits, "Pauli string must have one label per qubit")

        guard !pauli.activeQubits.isEmpty else {
            return pauli.coefficient
        }

        let basis = pauli.labels.map { $0 ?? .z }
        let result = measure(shots: shots, basis: basis)
        return pauli.coefficient * result.parityExpectation(qubits: pauli.activeQubits)
    }

    /// Shot-based estimate of a `Hamiltonian`'s expectation value. Terms are grouped into
    /// qubit-wise-commuting (QWC) groups via `Hamiltonian.commutingGroups()`, and `shots`
    /// is spent **once per group** rather than once per term: every term in a QWC group
    /// shares one combined per-qubit basis (each qubit's basis is whichever group member's
    /// label is non-`I` there — QWC guarantees every member that specifies one agrees), so
    /// a single `measure(shots:basis:)` call yields every term's `parityExpectation` at
    /// once. This samples `hamiltonian.commutingGroups().count · shots` times in total,
    /// down from `hamiltonian.terms.count · shots` — e.g. page `18VQE`'s six-term H₂
    /// Hamiltonian groups into three settings, halving the shot cost. An all-`I` term needs
    /// no sampling in either scheme, matching `measureExpectation(of: PauliString, shots:)`.
    ///
    /// (`evolve`/`trotterCircuit` below have no equivalent automatic grouping — see there.)
    func measureExpectation(of hamiltonian: Hamiltonian, shots: Int) -> Double {
        precondition(hamiltonian.qubits == qubits, "Hamiltonian must act on this circuit's qubit count")

        var total = 0.0
        for group in hamiltonian.commutingGroups() {
            let (active, identity) = (group.filter { !$0.activeQubits.isEmpty },
                                       group.filter { $0.activeQubits.isEmpty })
            total += identity.reduce(0.0) { $0 + $1.coefficient }
            guard !active.isEmpty else { continue }

            var basis = Array(repeating: PauliBasis.z, count: qubits)
            for term in active {
                for qubit in term.activeQubits { basis[qubit] = term.labels[qubit]! }
            }
            let result = measure(shots: shots, basis: basis)
            total += active.reduce(0.0) { $0 + $1.coefficient * result.parityExpectation(qubits: $1.activeQubits) }
        }
        return total
    }

    /// Append a Trotterized time evolution `exp(-i·hamiltonian·time)` to this circuit, via
    /// `steps` repetitions of a product formula built from `pauliRotation` (one call per
    /// `hamiltonian` term). Terms are applied in the order `hamiltonian.terms` lists them —
    /// there is no automatic grouping into commuting layers; a caller who wants one groups
    /// first via `Hamiltonian.commutingGroups()` and flattens the result into a fresh
    /// `Hamiltonian` (`Hamiltonian(hamiltonian.commutingGroups().flatMap { $0 })`) before
    /// calling `evolve`/`trotterCircuit` — grouping is left opt-in here (unlike
    /// `measureExpectation(of: Hamiltonian, shots:)`, which groups automatically) since
    /// reordering changes the *finite-step* Trotter error, and this method's current term
    /// order is what existing callers' error-scaling numbers are pinned against.
    ///
    /// - Parameter order: `1` for a first-order (Lie–Trotter) step — every term in order, each
    ///   scaled by the full step `dt = time/steps`; `2` for a second-order (Strang/Suzuki) step
    ///   — every term but the last at half `dt`, the last term at full `dt`, then every term but
    ///   the last again at half `dt` in reverse order. A single-term Hamiltonian is exact at
    ///   `steps: 1` for either order (the two orders coincide), since there is nothing to split.
    func evolve(_ hamiltonian: Hamiltonian, time: Double, steps: Int, order: Int = 1) {
        precondition(hamiltonian.qubits == qubits,
                     "Hamiltonian must act on this circuit's qubit count")
        precondition(steps > 0, "Number of steps must be positive")
        precondition(order == 1 || order == 2,
                     "Only first- and second-order Trotter steps are supported")

        let dt = time / Double(steps)
        let terms = hamiltonian.terms

        func fullStep(_ term: PauliString, _ scale: Double) {
            pauliRotation(term.label, theta: 2 * term.coefficient * dt * scale)
        }

        for _ in 0..<steps {
            if order == 1 {
                for term in terms { fullStep(term, 1) }
            } else {
                for term in terms.dropLast() { fullStep(term, 0.5) }
                if let last = terms.last { fullStep(last, 1) }
                for term in terms.dropLast().reversed() { fullStep(term, 0.5) }
            }
        }
    }

    /// Shared preconditions for `increment`/`decrement`: a non-empty register of distinct,
    /// in-range qubits, and (if given) a `control` that's in range and not itself part of
    /// the register.
    private func validateRegisterArithmetic(_ register: [Int], _ control: Int?) {
        precondition(!register.isEmpty, "Register must not be empty")
        precondition(Set(register).count == register.count, "Register qubits must be distinct")
        precondition(register.allSatisfy { $0 >= 0 && $0 < qubits }, "Register qubit out of range")
        if let control = control {
            precondition(control >= 0 && control < qubits, "Control qubit out of range")
            precondition(!register.contains(control), "Control must not be one of the register qubits")
        }
    }

    /// One ripple step of `increment`/`decrement`: flips `register[k]`, controlled by
    /// every less-significant register bit (`register[(k+1)...]`) plus `control`, if given.
    private func rippleStep(_ k: Int, register: [Int], control: Int?) {
        var controls = Array(register[(k + 1)...])
        if let control = control { controls.append(control) }
        mcx(controls, register[k])
    }

    /// Ripple-carry increment of `register` — a binary number stored most-significant
    /// qubit first (`register[0]`), matching Core's qubit-0-is-MSB convention — optionally
    /// gated by `control`. Bit `k` flips iff every less-significant bit already in
    /// `register` (and `control`, if given) is 1, applied most-significant to
    /// least-significant so every flip's controls are read before they're themselves
    /// touched (the standard ripple-carry order).
    func increment(register: [Int], controlledBy control: Int? = nil) {
        validateRegisterArithmetic(register, control)
        for k in register.indices {
            rippleStep(k, register: register, control: control)
        }
    }

    /// The exact inverse of `increment(register:controlledBy:)`: the same multi-controlled
    /// X gates, applied least-significant to most-significant — the reverse order.
    /// Each gate is its own inverse, so reversing the sequence inverts the composite
    /// unitary exactly.
    func decrement(register: [Int], controlledBy control: Int? = nil) {
        validateRegisterArithmetic(register, control)
        for k in register.indices.reversed() {
            rippleStep(k, register: register, control: control)
        }
    }

    /// Three-decimal rendering of a rotation angle, for a gate's `TensorNetwork` label
    /// (e.g. `RX(1.571)`).
    private func formatted(_ theta: Double) -> String {
        String(format: "%.3f", theta)
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
            record(Matrix.identity(size: 1 << qubits) * globalPhase, actingOn: [],
                   name: "phase", local: Matrix([[globalPhase]]))
            return
        }

        for i in active {
            if let basis = PauliBasis(rawValue: chars[i]) {
                rotateToZ(basis, i)
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
            if let basis = PauliBasis(rawValue: chars[i]) {
                rotateFromZ(basis, i)
            }
        }
    }

}
/// Embed a single-qubit gate into an n-qubit system at a specific qubit index.
/// Qubit indexing: 0 = most-significant (leftmost). Internal (not `private`) so
/// `KrausChannel.apply(to:qubit:)` can reuse the same embedding idiom for a noise channel.
func embedSingleQubitGate(
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
