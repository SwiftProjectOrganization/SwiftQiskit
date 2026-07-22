# Public tensor-product (Kronecker) API for Matrix and StateVector

## Context

SwiftQiskit currently has a tensor product only as a file-private `kron()` helper inside
`Sources/SwiftQiskitCore/Circuit/QuantumCircuit.swift` (line 114), used to embed single-qubit
gates into n-qubit registers. Users of the library (and the playground pages) cannot compute
tensor products themselves — e.g. building composite gates like `H ⊗ H`, or combining states
`|ψ⟩ ⊗ |φ⟩`. Promoting this to a public API is also groundwork for the roadmap items in
`STATUSandTODO.md` (general multi-qubit CNOT, richer gate construction).

Goal: a public `tensor(_:)` method plus a `⊗` operator on both `Matrix` and `StateVector`,
with `QuantumCircuit` refactored to use it, and unit tests.

## Changes

### 1. `Sources/SwiftQiskitCore/Math/Matrix.swift`

- Declare the custom operator once, at file scope:
  ```swift
  infix operator ⊗ : MultiplicationPrecedence
  ```
- Add a `// MARK: - Tensor Product` extension:
  ```swift
  public extension Matrix {
      /// Kronecker (tensor) product A ⊗ B.
      /// Result is (rows·other.rows) × (cols·other.cols).
      func tensor(_ other: Matrix) -> Matrix
      static func ⊗ (lhs: Matrix, rhs: Matrix) -> Matrix   // calls tensor
  }
  ```
- Implementation is the existing `kron()` loop moved verbatim from
  `QuantumCircuit.swift:114-126` (same style: preconditions not needed — any dimensions are
  valid for a Kronecker product).

### 2. `Sources/SwiftQiskitCore/Quantum/StateVector.swift`

- Add a `// MARK: - Tensor Product` extension:
  ```swift
  public extension StateVector {
      /// Tensor product |ψ⟩ ⊗ |φ⟩ combining two registers.
      /// Qubit 0 is most-significant, so `self` occupies the high-order bits.
      func tensor(_ other: StateVector) -> StateVector
      static func ⊗ (lhs: StateVector, rhs: StateVector) -> StateVector
  }
  ```
- Implementation: result amplitude at index `i * other.dimension + j` is
  `self[i] * other[j]`; construct via the existing `init(_:)` (its auto-normalization is a
  no-op for already-normalized inputs). This matches the project's qubit-0-is-MSB convention.

### 3. `Sources/SwiftQiskitCore/Circuit/QuantumCircuit.swift`

- Delete the file-private `kron()` and `identity(_:)` helpers.
- In `embedSingleQubitGate`, replace `kron(result!, factor)` with `result! ⊗ factor`
  (or `result!.tensor(factor)`) and `identity(2)` with `Matrix.identity(size: 2)`.
- No behavior change — `h/x/z` gate embedding must produce identical matrices.

### 4. Tests — new `Tests/SwiftQiskitCoreTests/TensorProductTests.swift`

Swift `Testing` framework (`@Test`, `#expect`), matching `BellStateTests.swift` style:

- **Matrix**: `I₂ ⊗ I₂ == Matrix.identity(size: 4)`; `H ⊗ I` has the expected 4×4 entries;
  dimensions of a non-square product (e.g. 2×3 ⊗ 2×2 → 4×6).
- **Mixed identity**: `(A ⊗ B).multiply(by: x ⊗ y) == (A·x) ⊗ (B·y)` for small known values,
  within 1e-10 tolerance.
- **StateVector**: `StateVector(qubits: 1) ⊗ StateVector(qubits: 1)` equals
  `StateVector(qubits: 2)` (|00⟩); `(H|0⟩) ⊗ |0⟩` amplitudes match running
  `QuantumCircuit(qubits: 2)` with `h(0)`.
- Existing `BellStateTests` serve as the regression check for the `embedSingleQubitGate`
  refactor.

### 5. Docs

- `CLAUDE.md`: update the `Math/Matrix.swift` and `Circuit/QuantumCircuit.swift` architecture
  bullets — tensor product is now public (`tensor(_:)` / `⊗`) on Matrix and StateVector;
  `kron` is no longer file-private in the circuit file.
- `STATUSandTODO.md`: tick/note the tensor-product addition if a matching TODO exists.

## Verification

1. `BuildProject` (xcode-tools) or `swift build` — library must keep compiling (playground
   pages depend on the scheme building).
2. `RunAllTests` or `swift test` — new `TensorProductTests` pass and `BellStateTests` still
   pass (confirms the `embedSingleQubitGate` refactor is behavior-preserving).
3. Optional: `RunCodeSnippet` in a Core file evaluating `HadamardGate.matrix ⊗ Matrix.identity(size: 2)`
   to eyeball the operator ergonomics.
