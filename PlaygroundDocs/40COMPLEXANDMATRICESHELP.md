# Complex numbers and matrices — help & usage guide

User-facing guide to the `40ComplexAndMatrices` playground page. It is the first of the `40+`
pages, numbered separately from `01`–`23` because they accompany chapters of the
SwiftQiskitApp `INTRODUCTION.md` book (`Docs/Introduction/02-ComplexAndMatrices.md`) rather
than continuing that sequence. It runs every code fragment from the book's Chapter 2, in
order, against `Complex` (`Math/Complex.swift`) and `Matrix` (`Math/Matrix.swift`); no Core
library changes were needed.

## What the page shows

`Complex` and `Matrix` are the scalar and transformation types every state vector and gate
matrix is built from. The page walks through them in the order the book introduces them:

1. `Complex` construction, `*`, `/`, `conjugate`, `magnitude`/`magnitudeSquared`.
2. Why amplitudes are complex: `z · z̄` is always real, so it can serve as a probability
   (the Born rule).
3. The complex plane: magnitude and phase via Euler's formula, checked against
   `PhaseGate.matrix(theta:)`.
4. Plain `[Complex]` vectors with one-line `zip`/`map` helpers (the library has no vector
   arithmetic on bare arrays; `StateVector` takes over from Chapter 3).
5. Inner products, the dagger, orthogonality, length and normalization.
6. `Matrix` as a transformation, and why "apply A then B" is `B * A`.
7. Unitary matrices, why exact `==` lies on `H`, and how Hermitian matrices relate.
8. The tensor product `⊗`.

This page has **no live view**; every result is printed to the console (no companion
`PlaygroundDocs/…PLAN.md`; this is the only guide).

## The page's sections

| Section | What it shows |
|---|---|
| §2.2 | `a = Complex(3, 4)`, `b = Complex(1, -2)`: `a * b`, `a / b`; `z = Complex(3, 2)`: `z * z.conjugate` and `z.magnitudeSquared` (printed as tuples via string interpolation) |
| §2.3 | `amp = 1/√2`: `amp.magnitudeSquared` is ≈ 0.5, not exactly 0.5 |
| §2.4 | `theta = Double.pi/3`; `rad2deg(theta)`; `phase = Complex(cos θ, sin θ)` and its magnitude; compares against `PhaseGate.matrix(theta:)[1, 1]` |
| §2.5 | `[Complex]` states `zeroState`/`oneState`/`plusState`; page-local `addVec`/`scale` helpers; `Complex` `+` |
| §2.6 | Page-local `innerProduct(_:_:)` (conjugating the first argument); `v = [1, i]` and `w = [1, −i]` are orthogonal |
| §2.7 | Page-local `norm(_:)`; `[1, i]` has norm √2 and is not a legal state; dividing by the norm normalizes it |
| §2.8 | `H`, `H[0, 0]`, `H.multiply(by:)`; `(Z * H)` vs. `(H * Z)` applied to `|0⟩` — order matters |
| §2.9 | `g.adjoint * g == I2` for `H`, `X`, `S`, `T`; page-local `maxDiff(_:_:)`; then the Hermitian paragraph (below) |
| §2.10 | `mat1 ⊗ HadamardGate.matrix` (a 2×2 integer matrix tensored with `H`); `a23.tensor(I2)` shape; `H.tensor(I2)`; `(H ⊗ I2)` applied to `|00⟩` vs. `QuantumCircuit.h(0)` |

### Hermitian matrices (end of §2.9)

A comment-only paragraph, no code. A square matrix `A` is Hermitian when it equals its own
conjugate transpose, `A† == A`. Hermitian matrices matter because their eigenvalues are
always real, which makes them the natural representation of measurable quantities
(observables) such as energy, spin and momentum — a measurement outcome has to be a real
number. Quantum gates are unitary (`U†U = I`); the two classes are linked through the same
conjugate transpose, and every unitary can be written `U = e^{-iθA}` for some Hermitian `A`
(page `21Trotter` builds gates exactly this way with `Matrix.expm()`). `X`, `Y`, `Z` and `H`
are both Hermitian and unitary.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`40ComplexAndMatrices`** page
   (via `00TOC`, or follow `[Next]`/`[Previous]` from its neighbors).
2. Make sure the **`SwiftQiskit-Package`** scheme (or any scheme that builds `SwiftQiskit`)
   is active and builds. The page only does `import SwiftQiskit`, so it does not need
   `SwiftQiskitViews`.
3. Run the page and read the console. With no live view, it is unaffected by the Xcode 27
   beta SwiftUI evaluator bugs.

## Expected results

Verified by hand / against the library up to floating-point rounding; the exact digits of
`Double` values may differ in the last place.

**§2.2–§2.3 — complex arithmetic**

| Expression | Value |
|---|---|
| `a * b` | `11 − 2i` |
| `a / b` | `−1 + 2i` |
| `z * z.conjugate` | `13 + 0i` (always real) |
| `z.magnitudeSquared` | `13.0` |
| `amp.magnitudeSquared` | `≈ 0.5` (e.g. `0.4999999999999999`) |

**§2.4 — phase**

| Expression | Value |
|---|---|
| `rad2deg(theta)` | `≈ 60.0` (`theta = π/3`) |
| `phase` | `≈ 0.5 + 0.866i` |
| `phase.magnitude` | `≈ 1.0` — a pure phase never changes size |
| `PhaseGate.matrix(theta: theta)[1, 1]` | equal to `phase` |

**§2.5–§2.7 — vectors**

| Expression | Value |
|---|---|
| `a1 + b1` | `1 + 1i` |
| `addVec(m1, m2)` | `[3 + 0i, 0 + 0i]` |
| `scale(.i, [1, 2])` | `[0 + 1i, 0 + 2i]` |
| `innerProduct(v, w)` | `0` — orthogonal |
| `norm(raw)` | `≈ 1.4142` (√2) |
| `norm(normalized)` | `≈ 1.0` |

**§2.8 — order matters**

| Expression | Value |
|---|---|
| `H.multiply(by: [1, 0])` | `[√2/2, √2/2]` |
| `(Z * H).multiply(by: ket0)` | `[√2/2, −√2/2]` — `|−⟩`, the intended "H then Z" |
| `(H * Z).multiply(by: ket0)` | `[√2/2, √2/2]` — `|+⟩`, the wrong order |

**§2.9 — unitarity**

| Expression | Value |
|---|---|
| `g.adjoint * g == I2` for `X`, `S`, `T` | `true` |
| `H.adjoint * H == I2` | `false` — `H`'s ±1/√2 entries only approximate as a `Double` |
| `maxDiff(H.adjoint * H, I2)` | `≈ 2.22e-16` |

**§2.10 — tensor product**

| Expression | Value |
|---|---|
| `mat1 ⊗ HadamardGate.matrix` | a 4×4 matrix: each entry of `mat1` becomes `entry · H` as a 2×2 block (the top-left block is `1 · H`, the bottom-right block is `4 · H`); its last expression on the page, so it shows in the results sidebar, not the console |
| `a23.tensor(I2).rows, .cols` | `4 6` (2×3 tensored with 2×2 gives 4×6) |
| `H.tensor(I2)` | 4×4: each ±1/√2 entry of `H` becomes a ±1/√2 · `I2` block |
| `qc.run().amplitudes` | `[√2/2, 0, √2/2, 0]` |
| `(H ⊗ I2).multiply(by: [1, 0, 0, 0])` | identical to the line above |

## Reading notes

- **Why `z · z̄` matters.** `Complex(3, 2) * z.conjugate` is exactly `13 + 0i`: the imaginary
  parts cancel. That is why `magnitudeSquared` can serve as a probability (§2.3) — it is
  always real and never negative.
- **Why exact `==` lies on `H`.** `H` is exactly as unitary as `X`, `S` or `T`, but its
  entries are `1/√2` rounded to a `Double`, so `H†H` misses `I` by ~2.22e-16. Use a
  tolerance comparison (`maxDiff` here, `Matrix.isUnitary(tolerance:)` in the library), never
  `==`, on any matrix with irrational entries.
- **Apply A then B is `B * A`.** `Z * H` is "H first, then Z". `QuantumCircuit` itself never
  hits this trap, because `run()` applies each placed gate one at a time rather than forming
  a single product matrix.
- **Hermitian vs. unitary.** Both are defined through the conjugate transpose (`Matrix.adjoint`,
  postfix `†`): Hermitian means `A† = A`, unitary means `U† = U⁻¹`. The gates `X`, `Y`, `Z`
  and `H` are both, so each is its own inverse; `S` and `T` are unitary but not Hermitian.
- **`⊗` is not commutative and places no constraint on shapes.** An m×n matrix tensored with
  a p×q matrix is always mp×nq; `h(0)` on a 2-qubit circuit is exactly `H ⊗ I` applied to the
  state, with no special code path for "one gate on one qubit of several".
- **Page-local helpers** (`addVec`, `scale`, `innerProduct`, `norm`, `maxDiff`) are defined on
  the page and are not part of the library — plain `[Complex]` vectors have no library
  arithmetic. `StateVector` and the Dirac API (`01Qubits`, `08Dirac`) replace them.

## Using it in your own code

```swift
import SwiftQiskit

let a = Complex(3, 4), b = Complex(1, -2)
let product = a * b                         // 11 - 2i
let probability = a.magnitudeSquared        // 25.0

let H = HadamardGate.matrix
let isUnitary = H.isUnitary(tolerance: 1e-10)          // true; H.adjoint * H == I would be false

let X = PauliXGate.matrix
let isHermitian = X.adjoint == X                        // true (exact for X's 0/1 entries)

let HI = H ⊗ Matrix.identity(size: 2)                  // what h(0) applies on 2 qubits
```

## Troubleshooting

- **Nothing prints for `mat1 ⊗ HadamardGate.matrix`** — it's a bare expression with no
  `print(...)`, so its value appears in the results sidebar, not the console.
- **A `Double` result is "off" by ~1e-16** — ordinary floating-point rounding (see §2.3 and
  §2.9, and the reading notes in `01QUBITSHELP.md`).
- **`H.adjoint * H == I2` prints `false`** — expected, not a bug; see "Why exact `==` lies on
  `H`" above.
- **`Complex`/`Matrix` printed output looks different from the tables** — the tables show
  values in mathematical notation; the playground prints the types' own `description`.
