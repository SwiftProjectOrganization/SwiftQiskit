# SwiftQiskit API Reference

This is the API reference for the `SwiftQiskit` **core library** (`Sources/SwiftQiskit/`) — the
product you get from `import SwiftQiskit`. It does not cover the playground helper module
(`Playgrounds.playground/Sources/`); see `PLAYGROUNDSUPPORT.md` for that.

SwiftQiskit is v0.1 — the API is unstable and correctness is prioritized over performance.
Keep this document in sync with the source when the public API changes.

## Conventions

- **Qubit indexing:** qubit 0 is the most-significant (leftmost) bit. This applies to
  `QuantumCircuit` gate methods, `CNOTGate.matrix(qubits:control:target:)`, `⊗` (tensor
  product — the left-hand operand occupies the high-order bits), and binary state labels
  like `Ket("01")`.
- **Angles are in radians**, and — following Qiskit — appear as the *first* argument on
  parameterized circuit methods: `p(theta, qubit)`, `rx(theta, qubit)`, etc.
- **Invariants are enforced with `precondition`**, not thrown errors: passing a mismatched
  matrix dimension, an out-of-range qubit index, or an empty state traps at runtime rather
  than failing gracefully. Check preconditions before calling.
- **Value types throughout**, except `QuantumCircuit`, which is a `final class` (reference
  semantics — copies alias the same circuit).

## Quick Start

```swift
import SwiftQiskit

let circuit = QuantumCircuit(qubits: 2)
circuit.h(0)
circuit.cx(0, 1)

let state = circuit.run()
print(state)
// |0⟩: 0.7071067811865475     <- unpadded label; this is |00⟩
// |1⟩: 0.0                    <- this is |01⟩
// |10⟩: 0.0
// |11⟩: 0.7071067811865475

let result = circuit.measure(shots: 1000)
print(result.sortedCounts)
// [(state: "00", count: 487), (state: "11", count: 513)]  -- counts vary run to run
```

---

## `Complex`

`Sources/SwiftQiskit/Math/Complex.swift` — a value-type complex number.

```swift
public struct Complex: Equatable, Hashable {
    public var real: Double
    public var imag: Double
    public init(_ real: Double = 0.0, _ imag: Double = 0.0)
}
```

| Member | Notes |
|---|---|
| `.zero`, `.one`, `.i` | Constants `Complex(0,0)`, `Complex(1,0)`, `Complex(0,1)`. |
| `magnitude` | `\|z\|`. |
| `magnitudeSquared` | `\|z\|²` — used internally to avoid a `sqrt` where only the square is needed (e.g. probabilities). |
| `conjugate` | `z̄`. |
| `+`, `-`, `*`, `/` | Standard complex arithmetic. `/` traps via `precondition` on division by zero. |
| `*(Complex, Double)`, `*(Double, Complex)` | Scalar multiplication, either operand order. |
| `description` | Formats as `"a"`, `"bi"`, or `"a + bi"` / `"a - bi"`. |

**Gaps to know about:** there is no unary `-` and no `exp`/polar constructor — write
`Complex(-1)` for negation and `Complex(cos(theta), sin(theta))` for `e^{iθ}` (see how the
gate files do it).

---

## `Matrix`

`Sources/SwiftQiskit/Math/Matrix.swift` (plus `adjoint`, added in `Dirac.swift`) — a
row-major, dense complex matrix.

```swift
public struct Matrix: Equatable, Hashable {
    public let rows: Int
    public let cols: Int
    public init(rows: Int, cols: Int, repeating value: Complex = .zero)
    public init(_ data: [[Complex]])
    public subscript(row: Int, col: Int) -> Complex { get set }
}
```

- `init(_ data:)` traps on an empty array or ragged rows.
- `subscript` traps on out-of-range indices.

| Operation | Signature | Notes |
|---|---|---|
| Matrix × matrix | `static func * (Matrix, Matrix) -> Matrix` | Traps if `lhs.cols != rhs.rows`. |
| Matrix × vector | `func multiply(by vector: [Complex]) -> [Complex]` | Traps if `cols != vector.count`. |
| Addition / subtraction | `static func + / -` | Entrywise; traps on a dimension mismatch. |
| Scalar multiply | `static func * (Matrix, Complex)`, `(Complex, Matrix)`, `(Matrix, Double)`, `(Double, Matrix)` | All four orders/types are supported. |
| Identity | `static func identity(size: Int) -> Matrix` | |
| Tensor (Kronecker) product | `func tensor(_ other: Matrix) -> Matrix`, operator `⊗` | `(rows·other.rows) × (cols·other.cols)`; any dimensions are valid, not just square. `⊗` is declared here as `infix operator ⊗ : MultiplicationPrecedence`. |
| Adjoint (conjugate transpose) | `var adjoint: Matrix`, postfix `†` | Declared in `Dirac.swift`. |
| Unitarity check | `func isUnitary(tolerance: Double = 1e-10) -> Bool` | `true` iff square and `U†U ≈ I` entrywise within `tolerance`; `false` for any non-square matrix. Replaces the hand `M†M ≈ I` check otherwise repeated at every call site (see the `Equatable` gotcha below). |
| Trace | `var trace: Complex` | Σᵢ `self[i,i]`. Traps if the matrix isn't square. |
| Permutation matrix | `static func permutation(size: Int, image: (Int) -> Int) -> Matrix` | Builds the `size`×`size` permutation sending column `i` to row `image(i)` (i.e. `\|image(i)⟩ ← \|i⟩`). Traps unless `image` is a genuine bijection on `0..<size` — every row must be hit by exactly one column — so the constructor itself is the unitarity check a hand-rolled permutation loop would otherwise verify separately. |
| Matrix exponential | `func expm(terms: Int = 20) -> Matrix` | e^A via scaling-and-squaring: halves `A` until its ∞-norm (max absolute row sum) is ≤ 0.5, sums a `terms`-term Taylor series there, then squares the result back up the same number of times. Traps if the matrix isn't square. No implicit `-i` — for e^(-iθH), scale `H` by `Complex(0, -theta)` yourself first. |
| Description | `description` | One bracketed row per line. |

**Gotcha:** `Equatable`/`Hashable` compare `Complex` entries exactly, so two matrices that
are mathematically equal but differ by floating-point rounding will compare unequal with
`==`. Use `isUnitary(tolerance:)` or an approximate comparison in tests (see
`MatrixArithmeticTests.swift` for the pattern used in this repo).

---

## `StateVector` (aka `Ket`)

`Sources/SwiftQiskit/Quantum/StateVector.swift`, extended in `Dirac.swift` — a normalized
vector of complex amplitudes representing an *n*-qubit pure state (2ⁿ amplitudes).

```swift
public struct StateVector: Equatable {
    public private(set) var amplitudes: [Complex]
    public init(_ amplitudes: [Complex])   // auto-normalizes; traps on an empty or all-zero input
    public init(qubits: Int)               // |0...0⟩; traps if qubits <= 0
}

public typealias Ket = StateVector
```

| Member | Notes |
|---|---|
| `dimension` | `2ⁿ`, i.e. `amplitudes.count`. |
| `probabilities` | `[Double]` of `\|αᵢ\|²`, one per basis state. |
| `subscript(index:)` | Amplitude at a basis index; traps out of range. |
| `normalize()` | Mutating; rescales to unit norm. Skips the rescale (and the rounding error it would add) when the norm is already within `1e-12` of 1, which keeps the dagger a true involution: `(ψ†)† == ψ` exactly. Traps if the norm is zero. |
| `apply(_ matrix: Matrix)` | Mutating: `\|ψ'⟩ = U\|ψ⟩`, then re-normalizes. **Any** matrix of the right dimension is accepted and silently rescaled to a unit vector — a non-unitary `U` will not be rejected, it will just change the probabilities in ways `U` alone wouldn't predict. |
| `measure() -> Int` | Mutating: samples a basis index from `probabilities` and **collapses** `self` to that basis state (all other amplitudes become `.zero`). Not idempotent — calling it twice is a different measurement, not a re-read. |
| `marginalProbabilities(over qubits: [Int]) -> [String: Double]` | Sums out every qubit *not* listed. The result's keys are the bits of `qubits`, **in the order given** (not necessarily ascending index), zero-padded to `qubits.count` characters — *every* one of the 2^k possible keys is present, including zero-probability ones. Traps if `qubits` is empty, has a duplicate, or has an out-of-range index. |
| `tensor(_ other:) -> StateVector`, operator `⊗` | Combines two registers; `self` occupies the high-order bits. |
| `description` | One `"|label⟩: amplitude"` line per basis state. The binary label is **not** zero-padded (e.g. a 2-qubit state's index 1 prints as `|1⟩`, not `|01⟩`) — contrast with `SimulationResult`, whose keys *are* zero-padded. |

### Basis kets (`Dirac.swift`)

```swift
Ket("01")          // basis ket from a binary label (qubit 0 = leftmost bit)
StateVector.zero    // |0⟩
StateVector.one     // |1⟩
StateVector.plus    // |+⟩  = (|0⟩ + |1⟩)/√2
StateVector.minus   // |−⟩  = (|0⟩ − |1⟩)/√2
StateVector.plusI   // |i⟩  = (|0⟩ + i|1⟩)/√2
StateVector.minusI  // |−i⟩ = (|0⟩ − i|1⟩)/√2
```

`Ket(_ label:)` traps if the label contains anything but `0`/`1` or is empty.

---

## `Bra` and Dirac Operators

`Sources/SwiftQiskit/Quantum/Dirac.swift` — bra-ket notation built on top of `StateVector`/`Matrix`.

```swift
public struct Bra: Equatable {
    public private(set) var amplitudes: [Complex]   // stored already conjugated
    public init(_ ket: StateVector)                  // ⟨ψ| = (|ψ⟩)†
    public init(_ label: String)                     // e.g. Bra("01") = ⟨01|
    public var ket: StateVector { get }               // |ψ⟩ = (⟨ψ|)†
    public var dimension: Int { get }
}
```

### The dagger operator `†`

```swift
postfix operator †
public postfix func † (ket: StateVector) -> Bra     // ⟨ψ| = (|ψ⟩)†
public postfix func † (bra: Bra) -> StateVector      // |ψ⟩ = (⟨ψ|)†
public postfix func † (matrix: Matrix) -> Matrix     // U† (same as .adjoint)
```

### Products

| Expression | Type | Notes |
|---|---|---|
| `Bra * StateVector` | `Complex` | Inner product ⟨φ\|ψ⟩. Traps on a dimension mismatch. |
| `Bra * Matrix` | `Bra` | ⟨ψ\|U — row vector times matrix. Enables expectation values: `psi† * U * psi`. |
| `StateVector * Bra` | `Matrix` | Outer product \|ψ⟩⟨φ\|. |
| `Bra ⊗ Bra` | `Bra` | Combines two bras; `self` is the high-order register. |
| `StateVector ⊗ Bra`, `Bra ⊗ StateVector` | `Matrix` | Mixed tensor product — both reduce to the outer product \|a⟩⟨b\|. |

**Worked example — a Pauli-Z expectation value:**

```swift
let psi = StateVector.plus
let z = psi† * PauliZGate.matrix * psi   // ⟨ψ|Z|ψ⟩, a Complex (real part ≈ 0 for |+⟩)
```

### Expectation values

```swift
public extension StateVector {
    func expectation(_ observable: Matrix) -> Double   // ⟨ψ|A|ψ⟩.real
}
```

A named one-liner wrapping the worked example above: `psi.expectation(z)` instead of
`(psi† * z * psi).real`. Assumes `observable` is Hermitian (any genuine observable — Pauli
matrices, projectors, real linear combinations of these) — the imaginary part is discarded
rather than checked, so a non-Hermitian matrix won't trap, it will just quietly lose
information. Traps (via the underlying `Bra` products) on a dimension mismatch.

---

## Gates

`Sources/SwiftQiskit/Gates/*.swift` — each fixed gate is a `public enum` exposing a static
`matrix: Matrix`; parameterized gates expose a static `matrix(theta:) -> Matrix` instead.
Follow this pattern when adding a new gate.

| Gate | Type | Circuit method | Notes |
|---|---|---|---|
| `HadamardGate.matrix` | fixed | `h(qubit)` | `1/√2 · [[1, 1], [1, -1]]`. |
| `PauliXGate.matrix` | fixed | `x(qubit)` | `[[0, 1], [1, 0]]`. |
| `PauliYGate.matrix` | fixed | `y(qubit)` | `[[0, -i], [i, 0]]`. |
| `PauliZGate.matrix` | fixed | `z(qubit)` | `[[1, 0], [0, -1]]`. |
| `SGate.matrix` | fixed | `s(qubit)` | `P(π/2)`, exact entries `[[1,0],[0,i]]`. |
| `SDaggerGate.matrix` | fixed | `sdg(qubit)` | `SGate.matrix.adjoint`. |
| `TGate.matrix` | fixed | `t(qubit)` | `PhaseGate.matrix(theta: .pi/4)`. |
| `TDaggerGate.matrix` | fixed | `tdg(qubit)` | `TGate.matrix.adjoint`. |
| `PhaseGate.matrix(theta:)` | parameterized | `p(theta, qubit)` | `[[1,0],[0, e^{iθ}]]`. |
| `RXGate.matrix(theta:)` | parameterized | `rx(theta, qubit)` | Rotation about X: `exp(-iθX/2)`. |
| `RYGate.matrix(theta:)` | parameterized | `ry(theta, qubit)` | Rotation about Y: `exp(-iθY/2)`, all-real entries. |
| `RZGate.matrix(theta:)` | parameterized | `rz(theta, qubit)` | Rotation about Z: `exp(-iθZ/2)`; equals `P(θ)` up to the global phase `e^{-iθ/2}`. |
| `CNOTGate.matrix` | fixed, 2-qubit | `cx(control, target)`* | The plain 4×4 CNOT (control = qubit 0, target = qubit 1). |
| `CNOTGate.matrix(qubits:control:target:)` | general, n-qubit | `cx(control, target)` | The full 2ⁿ×2ⁿ CNOT for any distinct control/target pair on an *n*-qubit register, built as a basis-state permutation. Traps if `qubits < 2`, if either index is out of range, or if `control == target`. |
| `RZZGate.matrix(theta:)` | parameterized, 2-qubit | `rzz(theta, q0, q1)`* | `exp(-iθ·Z⊗Z/2)` on adjacent qubits; equals `cx(0,1); rz(θ,1); cx(0,1)` exactly. |
| `RXXGate.matrix(theta:)` | parameterized, 2-qubit | `rxx(theta, q0, q1)`* | `exp(-iθ·X⊗X/2)` on adjacent qubits. |
| `RYYGate.matrix(theta:)` | parameterized, 2-qubit | `ryy(theta, q0, q1)`* | `exp(-iθ·Y⊗Y/2)` on adjacent qubits. |
| `ToffoliGate.matrix` | fixed, 3-qubit | `ccx(control1, control2, target)`* | The plain 8×8 Toffoli (controls = qubits 0/1, target = qubit 2). |
| `ToffoliGate.matrix(qubits:control1:control2:target:)` | general, n-qubit | `ccx(control1, control2, target)` | The full 2ⁿ×2ⁿ Toffoli for any three distinct qubits, built via `Matrix.permutation`: flips `target` iff both controls are 1. Symmetric in its two controls. Traps if `qubits < 3`, if any index is out of range, or if the three indices aren't distinct. |
| `MultiControlledXGate.matrix(qubits:controls:target:)` | general, n-qubit | `mcx(controls, target)` | Flips `target` iff every qubit in `controls` is 1, built via `Matrix.permutation`. `controls` may be empty (an unconditional flip, equivalent to `x`); one control is equivalent to `cx`, two to `ccx`. Traps if `target` is out of range, any control is out of range or duplicated, or `controls` contains `target`. |

\* `QuantumCircuit.cx`/`ccx` always call the general `CNOTGate.matrix(qubits:control:target:)`/
`ToffoliGate.matrix(qubits:control1:control2:target:)` forms, not the fixed-size ones — the
fixed forms are exposed separately for direct use as standalone gates. `rzz`/`rxx`/`ryy` work
on *any* distinct pair of qubits on an *n*-qubit circuit (not just adjacent ones) — see
`pauliRotation` below.

Rotation gates satisfy `RA(2π) = -I` (a full turn is minus identity) and
`RA(π) = -i·A` up to that same global phase, for the corresponding Pauli matrix `A`.

**Note:** the library has no built-in CZ or SWAP gate. Build these with `apply(_:)` and a
hand-constructed permutation or product of existing gates (several playground pages — e.g.
`11GroverExample`, `13Teleportation` — show the pattern).

---

## `QuantumCircuit`

`Sources/SwiftQiskit/Circuit/QuantumCircuit.swift` — records gate operations as full 2ⁿ×2ⁿ
matrices and replays them on demand.

```swift
public final class QuantumCircuit {
    public let qubits: Int
    public init(qubits: Int)                    // traps if qubits <= 0
    public func apply(_ matrix: Matrix)          // full-dimension gate; traps on dimension mismatch
}
```

Because it's a `final class`, assigning or passing a `QuantumCircuit` shares the same
underlying operation list — it does not copy.

### Gate methods (all `public extension QuantumCircuit`)

```swift
func h(_ qubit: Int)
func x(_ qubit: Int)
func y(_ qubit: Int)
func z(_ qubit: Int)
func s(_ qubit: Int)
func sdg(_ qubit: Int)
func t(_ qubit: Int)
func tdg(_ qubit: Int)
func p(_ theta: Double, _ qubit: Int)
func rx(_ theta: Double, _ qubit: Int)
func ry(_ theta: Double, _ qubit: Int)
func rz(_ theta: Double, _ qubit: Int)
func cx(_ control: Int, _ target: Int)
func ccx(_ control1: Int, _ control2: Int, _ target: Int)
func mcx(_ controls: [Int], _ target: Int)
func rzz(_ theta: Double, _ q0: Int, _ q1: Int)
func rxx(_ theta: Double, _ q0: Int, _ q1: Int)
func ryy(_ theta: Double, _ q0: Int, _ q1: Int)
func pauliRotation(_ pauli: String, theta: Double)
func rotateToZ(_ basis: PauliBasis, _ qubit: Int)
func evolve(_ hamiltonian: Hamiltonian, time: Double, steps: Int, order: Int = 1)
func increment(register: [Int], controlledBy control: Int? = nil)
func decrement(register: [Int], controlledBy control: Int? = nil)
```

Single-qubit gates are embedded across the full register via `Matrix.tensor(_:)`
(the file-private `embedSingleQubitGate`), so calling `h(1)` on a 3-qubit circuit builds and
applies `I ⊗ H ⊗ I` under the hood.

`pauliRotation(_:theta:)` applies `exp(-iθ·P/2)` for an arbitrary Pauli string (one character
per qubit, `I`/`X`/`Y`/`Z` only, indexed the same way as `Ket("01")` — character *i* acts on
qubit *i*). Traps if `pauli.count != qubits` or the string contains any other character.
Built entirely from existing gate methods: a basis change into Z on every non-`I` qubit
(`h` for X, `sdg;h` for Y), a CNOT staircase computing the parity of every active qubit into
the last one, a single `rz` there, the staircase undone, then the basis change undone. An
all-`I` string applies only the global phase `e^{-iθ/2}·I` (via `apply(_:)`), matching
`Matrix.expm()` on the same generator exactly rather than dropping the phase.
`rzz`/`rxx`/`ryy(theta, q0, q1)` are thin wrappers building the two-character Pauli string
and calling `pauliRotation` — they work on any distinct pair of qubits, not just adjacent
ones (traps if `q0 == q1` or either is out of range).

`rotateToZ(_ basis: PauliBasis, _ qubit: Int)` appends the rotation that turns a subsequent
Z-basis measurement of `qubit` into a measurement in `basis`: `h` for `.x`, `sdg;h` for `.y`,
nothing for `.z`. `pauliRotation`'s own basis-change step is built on this (and its
private inverse, `rotateFromZ`).

`evolve(_ hamiltonian:time:steps:order:)` appends `steps` repetitions of a Trotterized
product formula for `exp(-i·hamiltonian·time)`, one `pauliRotation` call per term. `order:
1` (default) applies every term in the order `hamiltonian.terms` lists them, each scaled by
the full step `dt = time/steps`; `order: 2` is a second-order (Strang/Suzuki) step — every
term but the last at half `dt`, the last term at full `dt`, then every term but the last
again at half `dt` in reverse. There is no automatic grouping into commuting layers — the
caller controls layering by ordering `hamiltonian.terms`. Traps if `hamiltonian.qubits !=
qubits`, `steps <= 0`, or `order` isn't `1` or `2`. `Hamiltonian.trotterCircuit(time:steps:
order:)` (below) is a `QuantumCircuit(qubits:)` + `evolve(...)` convenience.

`increment(register:controlledBy:)`/`decrement(register:controlledBy:)` implement
ripple-carry `±1` on `register` — a binary number stored most-significant qubit first
(`register[0]`), matching Core's qubit-0-is-MSB convention — via `mcx`: bit `k` flips iff
every less-significant bit already in `register` (and `control`, if given) is 1.
`increment` applies most-significant to least-significant so every flip's controls are read
before they're themselves touched; `decrement` is the exact inverse (each `mcx` is
self-inverse, so the reverse-order sequence inverts the composite unitary). `register` need
not be contiguous or in index order. Traps if `register` is empty, has a duplicate or
out-of-range qubit, or `control` is out of range or one of the `register` qubits.

### Execution

| Method | Signature | Notes |
|---|---|---|
| `run()` | `() -> StateVector` | Builds a fresh `StateVector(qubits: qubits)` (i.e. \|0…0⟩) and replays every recorded operation. Gates are recorded when called and only *applied* here — calling `run()` twice gives the same result each time. |
| `runAndMeasure()` | `() -> Int` | `run()` then a single `measure()` on the result — collapses that local copy, not any circuit state (the circuit itself has no persistent state to collapse). |
| `measure(shots:)` | `(Int) -> SimulationResult` | Traps if `shots <= 0`. Runs the circuit **once** to get the final probability distribution, then draws `shots` independent samples from it — it does *not* replay the whole circuit per shot, since a full measurement of a pure state never changes the probabilities of the underlying state that produced it. |
| `measure(shots:basis:)` | `(Int, [PauliBasis]) -> SimulationResult` | Traps if `basis.count != qubits`. Appends each qubit's `rotateToZ` rotation to a **copy** of the recorded operations and measures that copy — the receiver's own operation list is untouched, so the same circuit can be measured in different bases without rebuilding it. |
| `measureExpectation(of:shots:)` | `(PauliString, Int) -> Double` | Shot-based estimate of one Pauli term's expectation value, built on `measure(shots:basis:)` + `SimulationResult.parityExpectation(qubits:)`. Traps if `pauli.qubits != qubits`. An all-`I` term returns `pauli.coefficient` exactly, with no sampling. |
| `measureExpectation(of:shots:)` | `(Hamiltonian, Int) -> Double` | The sum of the Pauli-term overload over every term in `hamiltonian`, spending `shots` **per term** (terms aren't grouped by commuting basis, so this samples `hamiltonian.terms.count · shots` times total). Traps if `hamiltonian.qubits != qubits`. |

---

## `SimulationResult`

`Sources/SwiftQiskit/Quantum/SimulationResult.swift` — shot counts from
`QuantumCircuit.measure(shots:)`.

```swift
public struct SimulationResult {
    public let shots: Int
    public let counts: [String: Int]           // zero-padded binary state -> count
    public var sortedCounts: [(state: String, count: Int)] { get }  // ascending by state string
}
```

Keys in `counts` are zero-padded to `qubits` characters via `String.leftPadding` (below), and
qubit 0 is the leftmost character, matching the rest of the library's indexing convention.

| Member | Signature | Notes |
|---|---|---|
| `marginalCounts(over:)` | `([Int]) -> [String: Int]` | Groups `counts` by a subset of qubits, summing out the rest. Keys are the bits of `qubits`, **in the order given**; only observed keys appear (unlike `StateVector.marginalProbabilities`, which always returns every key). Traps if `qubits` is empty, has a duplicate, or has an out-of-range index; also traps if the counts keys don't all share one length. |
| `parityExpectation(qubits:)` | `([Int]) -> Double` | The ±1 parity-product average over `counts` — `Σ count · (−1)^(number of 1 bits among qubits) / shots` — the shot-based estimator for a Pauli-Z-string expectation value such as ⟨Z⊗Z⟩ across the listed qubits. |

---

## `PauliBasis`

`Sources/SwiftQiskit/Quantum/PauliBasis.swift`:

```swift
public enum PauliBasis: Character, CaseIterable {
    case x = "X"
    case y = "Y"
    case z = "Z"
}
```

A single-qubit Pauli measurement basis. The `Character` raw value interoperates with the
plain Pauli-string labels `pauliRotation(_:theta:)` already accepts (`.x.rawValue == "X"`,
etc.). Used by `QuantumCircuit.rotateToZ`/`measure(shots:basis:)` above.

---

## `PauliString`

`Sources/SwiftQiskit/Quantum/PauliString.swift` — a single weighted Pauli tensor-product
term: `coefficient · P₀ ⊗ P₁ ⊗ … ⊗ Pₙ₋₁`, one label per qubit (`nil` = `I`).

```swift
public struct PauliString: Equatable, Hashable {
    public let labels: [PauliBasis?]      // nil = I; qubit 0 first (MSB)
    public let coefficient: Double
    public init(labels: [PauliBasis?], coefficient: Double = 1)
    public init(_ label: String, coefficient: Double = 1)   // e.g. "XIZ"; I/X/Y/Z only
    public var qubits: Int { get }
    public var activeQubits: [Int] { get }   // indices with a non-nil label
    public var label: String { get }         // round-trips through init(_:coefficient:)
    public var matrix: Matrix { get }        // coefficient · (P₀ ⊗ P₁ ⊗ …)
    public func expectation(_ state: StateVector) -> Double   // coefficient · ⟨ψ|P₀⊗P₁⊗…|ψ⟩
}
```

`init(_:coefficient:)` traps on an empty string or a character outside `IXYZ`.
`expectation(_:)` traps if `state.dimension != 1 << qubits`. Shares its label type with
`QuantumCircuit.rotateToZ`/`pauliRotation(_:theta:)` — `label` is exactly the string
`pauliRotation` accepts.

---

## `Hamiltonian`

`Sources/SwiftQiskit/Quantum/Hamiltonian.swift` — a qubit Hamiltonian as a plain sum of
`PauliString` terms (no merging of duplicate labels, no commuting-term grouping).

```swift
public struct Hamiltonian: Equatable {
    public let terms: [PauliString]
    public init(_ terms: [PauliString])   // traps if empty or the terms disagree on qubit count
    public var qubits: Int { get }
    public var matrix: Matrix { get }             // Σ term.matrix
    public func expectation(_ state: StateVector) -> Double   // Σ term.expectation(state)
    public func trotterCircuit(time: Double, steps: Int, order: Int = 1) -> QuantumCircuit
}
```

Replaces the entrywise "build a matrix, then add `coefficient·term` to it index by index"
idiom page `18VQE` (and the app's VQE/Trotter chapters) hand-roll for an H₂-style
Hamiltonian. `trotterCircuit(time:steps:order:)` is `QuantumCircuit(qubits:)` +
`QuantumCircuit.evolve(_:time:steps:order:)` (see above) — a fresh circuit implementing
Trotterized time evolution `exp(-i·self·time)`.

---

## `ParameterShift` and `GradientDescent`

`Sources/SwiftQiskit/Quantum/ParameterShift.swift` — the parameter-shift gradient rule,
generalized to any number of parameters and any real-valued cost closure, plus a minimal
gradient-descent optimizer built on it.

```swift
public enum ParameterShift {
    static func gradient(at parameters: [Double], shift: Double = .pi / 2,
                          _ cost: ([Double]) -> Double) -> [Double]
    static func gradient(of hamiltonian: Hamiltonian, at parameters: [Double],
                          shift: Double = .pi / 2,
                          ansatz: ([Double]) -> QuantumCircuit) -> [Double]
}

public enum GradientDescent {
    public struct Result {
        public let parameters: [Double]
        public let value: Double        // cost(parameters), the last entry of history
        public let history: [Double]    // cost at every visited parameter vector
        public let iterations: Int
        public let converged: Bool      // true iff the gradient norm dropped below tolerance
    }

    static func minimize(initial: [Double], learningRate: Double = 0.1,
                          maxIterations: Int = 200, tolerance: Double = 1e-10,
                          cost: @escaping ([Double]) -> Double,
                          gradient: (([Double]) -> [Double])? = nil) -> Result
}
```

`ParameterShift.gradient` computes, for each parameter `k`, `[cost(θ + shift·eₖ) −
cost(θ − shift·eₖ)] / (2·sin(shift))`. This is **exact**, not a finite-difference
approximation, whenever every parameter enters `cost` as the angle of a single
`exp(-iθP/2)` rotation — the shape of every parameterized `QuantumCircuit` gate
(`rx`/`ry`/`rz`/`rzz`/`rxx`/`ryy`/`pauliRotation`). The default `shift = π/2` makes the
divisor `1`, matching the textbook rule `[cost(θ+π/2) − cost(θ−π/2)] / 2` (page `18VQE`'s
own one-parameter derivation). `cost` may be exact (`Hamiltonian.expectation`) or shot-based
(`QuantumCircuit.measureExpectation`) — the rule doesn't care which. Traps if `parameters`
is empty or `shift` is a multiple of `π` (zero divisor). The `of hamiltonian:`/`ansatz:`
overload is a convenience for the common VQE shape, using
`hamiltonian.expectation(ansatz(θ).run())` as the cost.

`GradientDescent.minimize` takes fixed-size steps of `learningRate · gradient` until the
gradient's Euclidean norm drops below `tolerance` or `maxIterations` is reached.
`gradient` defaults to `ParameterShift.gradient(at:_:)` applied to `cost` itself. No line
search, momentum, or COBYLA/Nelder-Mead — sufficient for the small, smooth landscapes a
VQE-style ansatz produces. Traps if `initial` is empty, `learningRate <= 0`, or
`maxIterations <= 0`.

---

## `StateTomography`

`Sources/SwiftQiskit/Quantum/StateTomography.swift` — a caseless namespace turning
`measure(shots:basis:)` results into a reconstructed single-qubit Bloch vector.

```swift
public enum StateTomography {
    static func estimate(qubit: Int, result: SimulationResult) -> Double
    static func estimateBlochVector(of circuit: QuantumCircuit, qubit: Int, shots: Int)
        -> (x: Double, y: Double, z: Double)
    static func reconstructSingleQubit(x: Double, y: Double, z: Double, tolerance: Double = 1e-9)
        -> (vector: (x: Double, y: Double, z: Double), isPhysical: Bool)
    static func clampToPhysical(_ v: (x: Double, y: Double, z: Double))
        -> (x: Double, y: Double, z: Double)
}
```

| Member | Notes |
|---|---|
| `estimate(qubit:result:)` | `(N₀ − N₁)/N` for `qubit`, from a `result` already measured in the desired basis — a single-qubit wrapper over `SimulationResult.parityExpectation(qubits:)`. |
| `estimateBlochVector(of:qubit:shots:)` | Runs three settings — every qubit measured in X, then Y, then Z, via `measure(shots:basis:)` — and returns `qubit`'s estimated `(x, y, z)`. Spends `shots` per setting (`3·shots` total). Never mutates `circuit`. Traps if `qubit` is out of range. |
| `reconstructSingleQubit(x:y:z:tolerance:)` | Packages a three-axis estimate as a vector plus `isPhysical` (`\|r\| ≤ 1 + tolerance`). A *pure* state's per-axis shot estimate lands outside the ball about half the time at any shot count — `isPhysical == false` there is expected, not a bug. |
| `clampToPhysical(_:)` | Rescales an out-of-ball vector onto the unit sphere (`r → r/\|r\|`); leaves an already-physical vector unchanged. A named rescale, not a maximum-likelihood or linear-inversion estimator. |

Returns plain `(x:, y:, z:)` tuples rather than a package-level `BlochVector` type, since
every playground page auto-imports its own `BlochVector` from
`Playgrounds.playground/Sources/`, which a same-named Core type would collide with.

---

## Utilities

`Sources/SwiftQiskit/Utils/String+Padding.swift`:

```swift
public extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String
}
```

Left-pads a string with `character` up to `toLength` (no-ops if already that long or
longer). This is really an internal implementation detail of measurement-result formatting
that happens to be `public`; don't build new API around it.

---

## Not Yet in Core

Several capabilities that later playground pages need — noise/Kraus channels and mid-circuit
or partial measurement (`DensityMatrix`/`KrausChannel`), and a real maximum-likelihood or
linear-inversion state-tomography reconstruction (`StateTomography` above is a rescale, not
this) — are implemented *inside individual playground pages* rather than in
`Sources/SwiftQiskit`, deliberately (see each page's plan doc under `PlaygroundDocs/`).
Proposed Core extensions for these areas, with rationale, are tracked in
`STATUSandTODO.md` under "Proposed Core extensions — ...". (`Hamiltonian.trotterCircuit`
and the `increment`/`decrement` register builders, previously listed here, are now
implemented — see `QuantumCircuit.evolve`/`Hamiltonian.trotterCircuit` and
`QuantumCircuit.increment`/`decrement` above.)

For the SwiftUI-facing helper types (`BlochVector`, `Bloch3DView`, `CHSHChartView`, etc.)
used by playground live views, see `PLAYGROUNDSUPPORT.md`.
