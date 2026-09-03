# Grover's algorithm — help & usage guide

User-facing guide to the `11GroverExample` playground page. The implementation plan is in
`11GROVERPLAN.md`.

## What the algorithm does

Among N = 2ⁿ items exactly one, |w⟩, is "marked", and the only way to learn anything is an
oracle that answers "is this the one?". Classically you can only try items one at a time —
~N/2 queries on average, N − 1 in the worst case. Grover's algorithm (Lov Grover, 1996)
finds the marked item with high probability in about **(π/4)·√N** queries, a quadratic
speedup that applies to *any* problem you can phrase as "recognize the answer when you see
it" (satisfiability, key search, …).

The quantum oracle is a **phase oracle**: it flips the sign of the marked basis state and
leaves every other one alone,

```text
U_w |x⟩ = (−1)^[x = w] |x⟩
```

The mark is invisible to measurement (probabilities are unchanged) — Grover's insight is a
second operator that converts the hidden phase into measurable amplitude.

## The circuit

One **Grover iteration** is two reflections applied to the uniform superposition
|s⟩ = H⊗ⁿ|0…0⟩:

```text
        ┌── repeat k times ──────────────┐
q: |0⟩⊗ⁿ ─ H⊗ⁿ ─┤  U_w (oracle)  →  D  ├─ measure all qubits
        └────────────────────────────────┘
```

| Step | Code | Effect |
|---|---|---|
| 1 | `h(q)` on every qubit | uniform superposition \|s⟩ — every item at amplitude 1/√N |
| 2 | oracle U_w | flip the sign of the marked amplitude (one query) |
| 3 | diffusion D = 2\|s⟩⟨s\| − I | reflect every amplitude about the mean |
| 4 | repeat 2–3 k times, then measure | outcome = marked item with P = sin²((2k+1)θ) |

**Why it works — inversion about the mean.** After the oracle, the marked amplitude is
negative while the rest are positive, so the mean ā drops. The diffusion operator sends
every amplitude aᵢ → 2ā − aᵢ: the unmarked ones shrink toward the mean and the marked one
leaps above it. Geometrically each iteration rotates the state by 2θ toward |w⟩, where
sin θ = 1/√N.

For **N = 4** (the page's main case) sin θ = ½, θ = π/6, and one iteration gives
sin²(3θ) = sin²(π/2) = **1**: the marked item is found *with certainty* from a single
oracle query, where a classical search of 4 items needs 2.25 on average.

## Building the operators from v0.1 gates

The library has no controlled-Z, but conjugating CNOT's target with Hadamards turns its X
into a Z (H X H = Z):

```text
CZ = (I ⊗ H) · CNOT · (I ⊗ H)   →   h(1); cx(0, 1); h(1)
```

and since `cx(control, target)` works between any distinct pair of qubits, the same trick
builds CZ wherever it is needed. Everything else is X-conjugation
(qubit 0 is the most-significant/leftmost bit):

| Operator | Construction |
|---|---|
| oracle for \|w⟩ | `x` on every qubit whose bit in w is 0, then CZ, then the same `x`'s |
| diffusion D | `h` all, `x` all, CZ, `x` all, `h` all (equals −D — a harmless global phase) |

Example: the oracle for \|10⟩ is `x(1); cz; x(1)` — qubit 1 is the 0 bit, and flipping it
maps \|10⟩ ↔ \|11⟩ where CZ acts.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`11GroverExample`** page
   (or follow the `[Next]` link from `10DeutschExample`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. Output is annotated inline with `// Expected:` comments.

## Expected output

Stage-by-stage walkthrough for marked |10⟩ (amplitudes up to floating-point rounding):

```text
uniform |s⟩:      |00⟩: 0.5   |01⟩: 0.5   |10⟩: 0.5    |11⟩: 0.5
after oracle:     |00⟩: 0.5   |01⟩: 0.5   |10⟩: -0.5   |11⟩: 0.5
amplitude mean:   0.25
after diffusion:  |10⟩: -1.0
```

The oracle line shows the mark hidden in the phase (all probabilities still ¼); the
diffusion line shows inversion about the mean: 0.5 → 2·0.25 − 0.5 = 0 for the unmarked
states, −0.5 → 1 for the marked one (printed as −1 because of the gate construction's
global sign).

One iteration finds every marked state with certainty:

```text
marked   P(marked)  found
|00⟩     1.0000     ✓
|01⟩     1.0000     ✓
|10⟩     1.0000     ✓
|11⟩     1.0000     ✓
```

Shots agree with no noise at all (contrast Deutsch's 50/50 ancilla bit — here the whole
register is the answer):

```text
marked |10⟩, 1000 shots:   10: 1000
```

More queries are **not** better — P(marked) oscillates as sin²((2k+1)·π/6):

```text
k:  0       1       2       3       4
P:  0.2500  1.0000  0.2500  0.2500  1.0000
```

And on 3 qubits (Section 8, marked |101⟩) Grover shows its true probabilistic character —
rising to the optimal k = 2, then rotating past the target:

```text
k:  1       2       3       4
P:  0.7813  0.9453  0.3301  0.0122

1000 shots at k = 2:  101: ~945, the other seven states sharing the rest
```

## Using the algorithm in your own code

The 2-qubit building blocks are plain `SwiftQiskitCore` calls:

```swift
import SwiftQiskitCore

func cz(_ qc: QuantumCircuit) { qc.h(1); qc.cx(0, 1); qc.h(1) }

/// Phase oracle flipping the sign of basis state `marked` (0...3).
func oracle(_ qc: QuantumCircuit, marked: Int) {
    let zeroBits = (0..<2).filter { (marked >> (1 - $0)) & 1 == 0 }
    for q in zeroBits { qc.x(q) }
    cz(qc)
    for q in zeroBits { qc.x(q) }
}

func diffusion(_ qc: QuantumCircuit) {
    qc.h(0); qc.h(1)
    qc.x(0); qc.x(1)
    cz(qc)
    qc.x(0); qc.x(1)
    qc.h(0); qc.h(1)
}

let qc = QuantumCircuit(qubits: 2)
qc.h(0); qc.h(1)
oracle(qc, marked: 2)          // hide |10⟩
diffusion(qc)
print(qc.runAndMeasure())      // 2 — always, P(marked) is exactly 1
```

Beyond 2 qubits, `cx` still works on any pair — but a *doubly*-controlled Z cannot be
built from H/X/Z/CNOT alone. `apply(_:)` takes any full 2ⁿ×2ⁿ matrix, so a
multi-controlled Z is one line:

```swift
var ccz = Matrix.identity(size: 8)
ccz[7, 7] = Complex(-1)        // flip the sign of |111⟩
qc.apply(ccz)
```

`h(_:)` and `x(_:)` already work on registers of any size, so the same oracle/diffusion
pattern scales — see the page's Section 8.

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first; check for
  compile errors in `Sources/SwiftQiskitCore/`. On Xcode 27 betas see also
  `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (this page is console-only, so the
  SwiftUI-specific bugs there should not affect it).
- **`cx` precondition failure** — `cx(control, target)` works on any pair of qubits of an
  n-qubit circuit, but control and target must be distinct and in range. The 3-qubit
  section needs a *doubly*-controlled gate, which `cx` alone can't provide — hence the
  hand-built CCZ matrix via `apply(_:)`.
- **P(marked) < 1 on 2 qubits** — check the oracle's X-conjugation: the `x`'s go on the
  qubits whose bit in the marked state is **0** (e.g. `x(1)` for |10⟩, not `x(0)`).
