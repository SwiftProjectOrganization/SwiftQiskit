# Dirac notation — help & usage guide

User-facing guide to the `08Dirac` playground page, which walks through the bra–ket API in
`Sources/SwiftQiskitCore/Quantum/Dirac.swift`. Unlike the algorithm pages there is no
separate design/plan document — `Dirac.swift` and its doc comments are the reference.

## What Dirac notation does

Dirac (bra–ket) notation writes a quantum state as a *ket* |ψ⟩ — a column vector — and its
conjugate transpose as a *bra* ⟨ψ| — a row vector. Putting a bra before a ket, ⟨φ|ψ⟩, is the
inner product (a single complex overlap amplitude); putting a ket before a bra, |ψ⟩⟨φ|, is
the outer product (a matrix). One symbol, the dagger †, converts between all of these:
ket ↔ bra, and matrix ↔ its adjoint (conjugate transpose).

In SwiftQiskitCore:

- `Ket` is a typealias of `StateVector`; basis kets come from binary labels (`Ket("01")`)
  or the named constants `.zero/.one/.plus/.minus/.plusI/.minusI`.
- `Bra` stores the *already-conjugated* amplitudes, so `Bra * Ket` is a plain dot product.
- The postfix operator `†` (declared in `Quantum/Dirac.swift`) maps `Ket → Bra`,
  `Bra → Ket`, and `Matrix → Matrix` (via `Matrix.adjoint`).
- A `Bra * Matrix` overload returns a `Bra`, which is what lets expectation values be
  written exactly like the math: `psi† * U * psi`.

The identities the page demonstrates:

- **Involution** — (|ψ⟩†)† = |ψ⟩, *exactly*: `normalize()` skips rescaling when the norm is
  already ≈ 1, so daggering twice returns the identical amplitudes.
- **Orthonormality** — ⟨0|0⟩ = 1, ⟨0|1⟩ = 0; any normalized state has ⟨φ|φ⟩ = 1.
- **Conjugate symmetry** — ⟨φ|ψ⟩ = ⟨ψ|φ⟩*: swapping bra and ket conjugates the amplitude.
- **Completeness & the Born rule** — the basis projectors |0⟩⟨0| + |1⟩⟨1| sum to the
  identity, and P(0) = ⟨ψ|0⟩⟨0|ψ⟩ reproduces `probabilities[0]`.
- **Unitary vs. Hermitian** — gates satisfy U†U = I; the Pauli gates and H are additionally
  Hermitian (U† = U), which is why their expectation values ⟨ψ|U|ψ⟩ are real numbers.
- **Dagger distributes over ⊗** — (|a⟩ ⊗ |b⟩)† = ⟨a| ⊗ ⟨b|, exactly (conjugation doesn't
  touch the doubles, and re-normalizing a normalized state is a no-op).
- **Mixed tensor products are outer products** — |a⟩ ⊗ ⟨b| = |a⟩⟨b| and ⟨a| ⊗ |b⟩ = |b⟩⟨a|.
  Both `Ket ⊗ Bra` and `Bra ⊗ Ket` return the outer-product `Matrix`. This is not a
  convention choice but the literal Kronecker product: a column (m×1) ⊗ a row (1×n) is an
  m×n matrix with entries aᵢb̄ⱼ — exactly |a⟩⟨b| — while a row ⊗ a column puts the ket back
  in the columns, which is why the operands swap in ⟨a| ⊗ |b⟩ = |b⟩⟨a|. The operands may
  live in registers of different sizes, so the result need not be square
  (e.g. `Ket("10") ⊗ Bra("0")` is 4×2).

## The page's sections

Most sections mirror tests in `Tests/SwiftQiskitCoreTests/DiracNotationTests.swift`,
turning their `#expect` assertions into printed checks:

| Section | Mirrors test(s) | What it shows |
|---|---|---|
| 1 — Kets, bras, † | `Double dagger returns the original ket` | \|+⟩ printed as ket and bra; (\|+⟩†)† == \|+⟩ exactly |
| 2 — Inner products | `Computational basis kets are orthonormal`, `Plus state overlaps zero state with amplitude one over root two`, `Inner product of a normalized state with itself is one`, `Inner product has conjugate symmetry` | ⟨0\|0⟩ = 1, ⟨0\|1⟩ = 0, ⟨+\|0⟩ = 1/√2, ⟨φ\|φ⟩ = 1, ⟨φ\|ψ⟩ = ⟨ψ\|φ⟩* |
| 3 — Outer products | `Basis projectors sum to the identity` | \|0⟩⟨0\| and \|1⟩⟨1\| as matrices; the Born rule ⟨φ\|0⟩⟨0\|φ⟩ = P(0) |
| 4 — Matrix adjoints | `Hadamard is its own adjoint`, `Adjoint conjugates and transposes entries` | H† == H, Y† == Y via `PauliYGate`, and H†H ≈ I |
| 5 — Multi-qubit | `Ket from binary label is the matching basis state`, `Bra tensor product matches daggered ket tensor product` | \|01⟩ == \|0⟩ ⊗ \|1⟩; † distributes over ⊗; a Bell amplitude ⟨11\|Φ⁺⟩ |
| 6 — Expectation values | `Pauli Z expectation values match theory` (Z only) | the page-04 qubit's Bloch coordinates as ⟨ψ\|X\|ψ⟩, ⟨ψ\|Y\|ψ⟩, ⟨ψ\|Z\|ψ⟩, cross-checked against `BlochVector` |
| 7 — Live view | — | the same state on a static, rotatable `Bloch3DView` |

Section 4 checks Y† == Y with `PauliYGate.matrix` from Core (the mirrored unit test
predates the gate and still builds the matrix inline). Section 6 reuses it for ⟨ψ|Y|ψ⟩;
the X and Y expectation values have no unit-test counterpart.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`08Dirac`** page
   (or follow the `[Next]` link from `07Entanglement` / `[Previous]` from `09Tensor`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. Console output is annotated inline with `// Expected:` comments, and
   Section 7 puts a `Bloch3DView` in the live-view pane (open the Assistant editor /
   live view area to see it; drag the sphere to rotate).

Unlike the console-only pages 09–12, this page **shows a SwiftUI live view**, so the
Xcode 27 beta evaluator bugs *do* apply here — if the live view fails to appear, see
`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (libcups shim; no `@State` in page
code, which is why the view's interaction state lives in `Playgrounds.playground/Sources/`).

## Expected output

The complete console output (up to floating-point rounding):

```text
|+⟩ as a ket:
|0⟩: 0.7071067811865475
|1⟩: 0.7071067811865475

⟨+| = |+⟩† as a bra:
⟨0|: 0.7071067811865475
⟨1|: 0.7071067811865475

(|+⟩†)† == |+⟩ → true

⟨0|0⟩ = 1.0
⟨0|1⟩ = 0.0
⟨+|0⟩ = 0.7071067811865475
⟨φ|φ⟩ = 1.0
⟨φ|i⟩  = 0.42426406871192845 + 0.565685424949238i
⟨i|φ⟩* = 0.42426406871192845 + 0.565685424949238i

|0⟩⟨0| =
[1.0, 0.0]
[0.0, 0.0]
|1⟩⟨1| =
[0.0, 0.0]
[0.0, 1.0]
⟨φ|0⟩⟨0|φ⟩ = 0.36  vs  probabilities[0] = 0.36

H† == H → true
Y† == Y → true
H†H =
[0.9999999999999998, 0.0]
[0.0, 0.9999999999999998]

|01⟩ == |0⟩ ⊗ |1⟩ → true
⟨+|⊗⟨1| == (|+⟩⊗|1⟩)† → true
⟨11|Φ⁺⟩ = 0.7071067811865475

α = ⟨0|ψ⟩ = 0.8660254037844387
β = ⟨1|ψ⟩ = 0.35355339059327373 + 0.3535533905932737i
⟨ψ|X|ψ⟩ = 0.6124   (sin θ cos φ = 0.6124)
⟨ψ|Y|ψ⟩ = 0.6124   (sin θ sin φ = 0.6124)
⟨ψ|Z|ψ⟩ = 0.5000   (cos θ     = 0.5000)
BlochVector: x 0.6124  y 0.6124  z 0.5000
```

Reading notes:

- **`Ket`/`Bra` printouts do not zero-pad labels** — `|0⟩: …` / `⟨0|: …` lines label basis
  states by their unpadded binary index. (Zero-padded strings appear only in measurement
  results via `SimulationResult`.)
- **⟨φ|i⟩ and ⟨i|φ⟩\* print identically** — that *is* the conjugate-symmetry check: the page
  prints the second value already conjugated. The exact digits are 0.6·(1/√2) and 0.8·(1/√2).
- **H†H prints 0.9999999999999998, not 1.0** — two ±1/√2 multiplications leave ~1e-16 of
  rounding; the corresponding unit test compares entrywise with a 1e-10 tolerance.
- **α and β** match the parametrization exactly: α = cos 30° ≈ 0.8660 and
  β = 0.5·e^{iπ/4} ≈ 0.3536 + 0.3536i.
- **The last four lines agree by construction** — ⟨ψ|X|ψ⟩, ⟨ψ|Y|ψ⟩, ⟨ψ|Z|ψ⟩ are the Bloch
  coordinates, and `BlochVector` (shared playground `Sources/`) computes the same point from
  the amplitudes directly: x = 2·Re(ᾱβ), y = 2·Im(ᾱβ), z = |α|² − |β|².
- Section 2 also has six bare expression lines (`Bra("0")`, `Ket("0")`, and the products
  `Bra("0") * Ket("0")`, `Ket("0") * Bra("0")`, `Bra("0") ⊗ Bra("0")`,
  `Ket("0") ⊗ Bra("0")`) whose values appear only in the playground results sidebar, not
  the console. The last line previews the mixed tensor product: `Ket ⊗ Bra` produces the
  same `Matrix` as the outer product `Ket * Bra` directly above it (mirrored by the
  `Ket tensor Bra equals the outer product` / `Bra tensor Ket swaps the outer product` /
  `Mixed tensor product allows different dimensions` unit tests).

## Using Dirac notation in your own code

Everything except the live view is plain `SwiftQiskitCore` API, so the same patterns work
in any target that imports the library:

```swift
import SwiftQiskitCore

// Overlaps and probabilities
let psi = Ket([Complex(0.6), Complex(0.8)])
let overlap = Ket.plus† * psi               // ⟨+|ψ⟩ — a Complex amplitude
let p0 = (Bra("0") * psi).magnitudeSquared  // Born rule: P(0) = |⟨0|ψ⟩|²

// Projectors from outer products
let projector = Ket.zero * Ket.zero†        // |0⟩⟨0| — a Matrix
let sameThing = Ket.zero ⊗ Ket.zero†        // column ⊗ row is the outer product
                                            // (Bra ⊗ Ket also works: ⟨a|⊗|b⟩ = |b⟩⟨a|)

// Expectation values read like the math (Bra * Matrix returns a Bra)
let expZ = psi† * PauliZGate.matrix * psi   // ⟨ψ|Z|ψ⟩ — real for Hermitian Z

// Unitarity check for any gate
let check = HadamardGate.matrix† * HadamardGate.matrix   // ≈ identity

// Amplitudes of a circuit's output state
let qc = QuantumCircuit(qubits: 2)
qc.h(0)
qc.cx(0, 1)
let amp = Bra("11") * qc.run()              // ⟨11|Φ⁺⟩ = 1/√2
```

Labels follow the library-wide convention: qubit 0 is the most-significant (leftmost) bit,
and ⊗ concatenates labels with the left operand in the high-order bits.

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first; check for
  compile errors in `Sources/SwiftQiskitCore/`.
- **No live view / SwiftUI errors** — this page uses `PlaygroundSupport` and `Bloch3DView`,
  so the Xcode 27 beta workarounds apply: see `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta
  workarounds" (libcups shim in DerivedData, and no `@State` in page code).
- **Can't type `†`** — it is the Unicode dagger U+2020 (⌥T on a US Mac keyboard), declared
  as a postfix operator in `Quantum/Dirac.swift`. ASCII equivalents: `Bra(ket)` for `ket†`,
  `bra.ket` for `bra†`, and `matrix.adjoint` for `matrix†`.
- **Can't type `⊗`** — U+2297 (circled times), declared in `Math/Matrix.swift`; the method
  spelling is `a.tensor(b)` (also available on `Bra`). The mixed `Ket ⊗ Bra` / `Bra ⊗ Ket`
  overloads live in `Quantum/Dirac.swift` and have no `tensor` method spelling — use the
  equivalent outer product (`ket * bra`, or `ket * bra` with the operands swapped for
  `Bra ⊗ Ket`).
- **`Ket("2")` traps** — labels must be non-empty binary strings; the initializer guards
  this with a `precondition`.
- **⟨ψ|U looks wrong when printed** — after `Bra * Matrix` the row vector is generally not
  a valid (normalized) state on its own; it is meant to be consumed by a following `* ket`.
