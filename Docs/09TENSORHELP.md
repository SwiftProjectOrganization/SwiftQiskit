# Tensor products — help & usage guide

User-facing guide to the `09Tensor` playground page. The API design and implementation plan is
in `09TENSORPLAN.md`.

## What the tensor product does

The Kronecker (tensor) product ⊗ is how quantum mechanics builds composite systems: matrices
combine into multi-qubit gates, and state vectors combine into multi-qubit registers. Without
it, "apply H to qubit 0 of a 2-qubit circuit" would have no matrix meaning — with it, that
operation *is* the 4×4 matrix H ⊗ I. SwiftQiskitCore exposes it as a `tensor(_:)` method plus
the `⊗` operator on both `Matrix` and `StateVector` (the operator is declared in
`Sources/SwiftQiskitCore/Math/Matrix.swift`).

The rules the page demonstrates:

- **Block rule** — A ⊗ B replaces every entry aᵢⱼ of A with the block aᵢⱼ·B, so an
  m×n ⊗ p×q product has shape mp×nq. Unlike matrix multiplication, ⊗ is defined for *any*
  pair of shapes — there is no dimension mismatch to precondition against.
- **Mixed-product identity** — (A ⊗ B)(x ⊗ y) = (Ax) ⊗ (By): acting on a composite system
  with A ⊗ B is the same as acting on each part separately and then combining. This is the
  property that makes ⊗ the right composition rule for quantum systems.
- **Ordering** — ⊗ is *not* commutative. SwiftQiskit's convention is qubit 0 = most-significant
  (leftmost) bit, so in `v ⊗ w` the left operand occupies the high-order bits and tensoring
  matches label concatenation: \|1⟩ ⊗ \|0⟩ = \|10⟩.
- **The limit** — ⊗ can only build *product states*, whose qubit measurements are independent.
  Entangled states like the Bell state cannot be written as a tensor product of single-qubit
  states; creating them takes a two-qubit gate such as `cx`.

## The page's sections

Each section mirrors one test in `Tests/SwiftQiskitCoreTests/TensorProductTests.swift`,
turning its `#expect` assertions into printed checks (Section 7 is the deliberate exception —
the flip side of the story, not a test):

| Section | Mirrors test | What it shows |
|---|---|---|
| 1 | `Identity tensor identity gives larger identity` | I₂ ⊗ I₂ == I₄, exactly (`Matrix` is `Equatable`) |
| 2 | `Hadamard tensor identity has expected entries` | the block rule; H ⊗ I₂ is exactly what `h(0)` builds on a 2-qubit circuit |
| 3 | `Tensor product of non-square matrices has product dimensions` | (2×3) ⊗ (2×2) → 4×6 — dimensions multiply, nothing fails |
| 4 | `Tensor product satisfies mixed-product identity` | (X ⊗ H)(x ⊗ y) = (Xx) ⊗ (Hy) on small known vectors |
| 5 | `Zero state tensor zero state gives two-qubit zero state` | \|0⟩ ⊗ \|0⟩ = \|00⟩ — labels concatenate, `self` in the high bits |
| 6 | `State tensor product matches embedded gate in circuit` | (H\|0⟩) ⊗ \|0⟩ equals running `h(0)` on a 2-qubit circuit |
| 7 | — | the Bell state violates α₀₀·α₁₁ = α₀₁·α₁₀, so it does not factor: entanglement |

Sections 1–2 use exact `==` where entries are exactly 0 or 1, and a 1e-10 tolerance where
they are irrational (±1/√2) — the same distinction the unit tests make.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`09Tensor`** page
   (or follow the `[Next]` link from `08BraKet`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. Output is annotated inline with `// Expected:` comments.

## Expected output

The complete console output (up to floating-point rounding):

```text
I₂ ⊗ I₂ == I₄ → true

H ⊗ I₂ =
[0.7071067811865475, 0.0, 0.7071067811865475, 0.0]
[0.0, 0.7071067811865475, 0.0, 0.7071067811865475]
[0.7071067811865475, 0.0, -0.7071067811865475, -0.0]
[0.0, 0.7071067811865475, -0.0, -0.7071067811865475]
max entry difference vs expected: 0.0

(2×3) ⊗ (2×2) → 4×6

max |(X⊗H)(x⊗y) − (Xx)⊗(Hy)| = 0.0

|0⟩ ⊗ |0⟩ == |00⟩ → true

(H|0⟩) ⊗ |0⟩:
|0⟩: 0.7071067811865475
|1⟩: 0.0
|10⟩: 0.7071067811865475
|11⟩: 0.0
max amplitude difference vs circuit h(0): 0.0

|Φ⁺⟩: α₀₀·α₁₁ = 0.4999999999999999, α₀₁·α₁₀ = 0.0
factors as a tensor product → false
```

Reading notes:

- **H ⊗ I₂** shows the block rule directly: each ±1/√2 entry of H became a ±1/√2·I₂ block.
  The `-0.0` entries are ordinary floating-point signed zeros from multiplying by −1/√2.
- **`StateVector`'s printout does not zero-pad labels** — in the (H\|0⟩) ⊗ \|0⟩ block,
  `|0⟩` and `|1⟩` mean the 2-qubit basis states \|00⟩ and \|01⟩. (Zero-padded strings appear
  only in measurement results via `SimulationResult`.)
- The "max … difference" lines print exactly 0.0 on current hardware; the corresponding unit
  tests allow up to 1e-10 of rounding.
- The finale: 0.4999999999999999 vs 0.0 — the Bell state's amplitudes fail the factorization
  identity by ½, so no pair of single-qubit states tensors into it.

## Using ⊗ in your own code

Both operands of the page are plain `SwiftQiskitCore` API, so the same patterns work in any
target that imports the library (`tensor(_:)` is the ASCII spelling of `⊗`):

```swift
import SwiftQiskitCore

// Build a multi-qubit gate from single-qubit parts…
let hh = HadamardGate.matrix ⊗ HadamardGate.matrix   // H ⊗ H, a 4×4 unitary

let qc = QuantumCircuit(qubits: 2)
qc.apply(hh)                        // same unitary as qc.h(0); qc.h(1)
print(qc.run())                     // uniform superposition — all amplitudes 0.5

// …and a register from single-qubit states.
var plus = StateVector(qubits: 1)
plus.apply(HadamardGate.matrix)     // |+⟩
let zero = StateVector(qubits: 1)   // |0⟩
let psi = plus ⊗ zero               // |+0⟩ = (|00⟩ + |10⟩)/√2 — `plus` is qubit 0 (MSB)
```

Remember the limit from Section 7: anything you build this way is a product state. To
entangle, apply a genuinely two-qubit operation afterwards — `cx(0, 1)` on `psi` above
yields the Bell state.

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first; check for
  compile errors in `Sources/SwiftQiskitCore/`. On Xcode 27 betas see also
  `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (this page is console-only, so the
  SwiftUI-specific bugs there should not affect it).
- **Can't type `⊗`** — it is the Unicode character U+2297 (circled times), declared as a
  custom operator in `Math/Matrix.swift`. Copy it from any page/test, or just call the
  equivalent method: `a.tensor(b)`.
- **Result looks bit-reversed** — ⊗ is not commutative: the *left* operand is qubit 0, the
  most-significant/leftmost label bit. `zero ⊗ plus` is (|00⟩ + |01⟩)/√2, not |+0⟩.
