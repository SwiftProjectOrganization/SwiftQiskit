# 3-qubit error correction — help & usage guide

User-facing guide to the `14ErrorCorrection` playground page. The implementation plan is in
`14ERRORCORRECTIONPLAN.md`.

## What the code does

A physical qubit is fragile, and you cannot check on it without collapsing the very
superposition you are trying to protect. The **3-qubit bit-flip code** spreads one logical
qubit across three physical ones so that an error can be *detected and corrected* without
ever measuring α or β directly:

- **Encode**: α\|0⟩+β\|1⟩ → α\|000⟩+β\|111⟩. Not cloning — the three qubits are entangled,
  and no single one of them holds \|ψ⟩ on its own.
- **Syndrome**: two ancilla qubits learn the *parities* q0⊕q1 and q1⊕q2. Every single-qubit
  bit-flip produces a distinct two-bit syndrome, and reading the parities disturbs the
  superposition of *which qubit is wrong* while leaving α, β untouched.
- **Correct**: flip whichever data qubit the syndrome accuses.
- **Decode**: undo the encoding to return \|ψ⟩ to one qubit.

## The register and circuit

Qubit 0 is the most-significant/leftmost bit. q0–q2 are data, q3–q4 are syndrome ancillas.

```text
q0: |ψ⟩ ──■────■───────────■──────────────■────■───
          │    │           │              │    │
q1: |0⟩ ──⊕────│───■───────┼───■──────────⊕────│───
               │   │       │   │
q2: |0⟩ ───────⊕───┼───■───┼───┼───■──────────⊕───
                   │   │   │   │   │
q3: |0⟩ ───────────⊕───┼───┼───┼───┼── [correction]
                       │   │   │
q4: |0⟩ ───────────────⊕───┼───┼─────────────────
                            (error here, e.g. x(0))
```

| Step | Code | Effect |
|---|---|---|
| 1 | `cx(0,1); cx(0,2)` | encode: α\|0⟩+β\|1⟩ → α\|000⟩+β\|111⟩ |
| 2 | (error) | `x(q)` flips one data qubit |
| 3 | `cx(0,3); cx(1,3)` | q3 ← q0⊕q1 |
| 4 | `cx(1,4); cx(2,4)` | q4 ← q1⊕q2 |
| 5 | correction | flip the accused data qubit (a hand-built permutation) |
| 6 | `cx(0,2); cx(0,1)` | decode: return \|ψ⟩ to q0 |

| Syndrome (q3 q4) | Meaning |
|---|---|
| 00 | no error |
| 10 | q0 flipped |
| 11 | q1 flipped |
| 01 | q2 flipped |

**Why the correction is a hand-built matrix.** "Flip q0 if the syndrome is 10" is a
Toffoli-with-mixed-controls (control on q3 = 1, q4 = 0, target q0) — `SwiftQiskitCore` has
no Toffoli gate. Following pages 11–12's precedent, the whole three-case correction is one
32×32 permutation matrix, built by decoding each basis index's syndrome bits and computing
which index it maps to, then applied with `apply(_:)`.

## Why the correction works on *every* error strength

Because the correction is never conditioned on an actual measurement — the ancillas are
never collapsed — it acts coherently on the full superposition. Replace the error with
`rx(θ)`, a partial bit-flip (a coherent mix of "no error" and "X error"), and the correction
fixes *both* branches simultaneously: the data qubit comes back with **fidelity exactly
1.0000 for every θ**, while the syndrome ancillas end up in a superposition recording how
much error there was (weights cos²(θ/2) and sin²(θ/2)). This is the page's central,
counter-intuitive fact: a continuous error becomes a discrete, fully-corrected outcome
*before* anyone measures anything.

## Where it breaks

The code is distance 3: it corrects any *one* error but is fooled by two. X on q0 **and**
q1 gives syndrome 01 — indistinguishable from a lone error on q2 — so the correction flips
q2, which was fine. The net result is all three qubits flipped: a full logical X on the
encoded qubit. Worse, this failure is *silent*: the corrected circuit reports success with
full confidence in the wrong answer. The exact logical error rate, enumerating all 8
independent single-qubit-flip patterns weighted by the per-qubit flip probability p, is

```text
p_L = 3p² − 2p³
```

which only beats the unencoded error rate p below the break-even point p = ½ — encoding
helps against weak, independent noise and actively hurts against strong noise.

## Phase flips, for free

The same code protects against Z errors if you look at it in the X basis: `h` the three
data qubits, suffer a Z error, `h` them back. Since HZH = X, a phase flip becomes exactly
the bit flip the rest of the page already knows how to fix — the syndrome table and
fidelities come out identical to the bit-flip case.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`14ErrorCorrection`** (or follow
   `[Next]` from `13Teleportation`).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. This page has a SwiftUI live view. On Xcode 27 betas, re-copy the `libcups` shim
   immediately before running (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds").
4. Run the page. Output is annotated inline with `// Expected:` comments.

## Expected output

```text
|ψ⟩ on q0:  |00000⟩: 0.8001 − 0.3314i   |10000⟩: 0.4619 + 0.1913i
encoded (α|000⟩+β|111⟩):  |00000⟩: 0.8001 − 0.3314i   |11100⟩: 0.4619 + 0.1913i

error   syndrome (q3 q4)   P
none     00              0.7500
q0       10              0.7500
q1       11              0.7500
q2       01              0.7500

correction matrix is unitary: true

error   fidelity to (α|000⟩+β|111⟩)⊗|syndrome⟩
none     1.0000
q0       1.0000
q1       1.0000
q2       1.0000

error   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩
none     1.0000
q0       1.0000
q1       1.0000
q2       1.0000

θ       fidelity   P(syndrome none)  P(syndrome q0)
0       1.0000     1.0000            0.0000
π/6     1.0000     0.9330            0.0670
π/3     1.0000     0.7500            0.2500
π/2     1.0000     0.5000            0.5000
π       1.0000     0.0000            1.0000

|ψ⟩ = |1⟩, errors on q0 AND q1 (syndrome wrongly accuses q2):
decoded P(0) = 1.0000   P(1) = 0.0000

p       p_L (encoded)   p (unencoded)   formula 3p²−2p³
0.05    0.0073          0.0500          0.0073
0.10    0.0280          0.1000          0.0280
0.20    0.1040          0.2000          0.1040
0.30    0.2160          0.3000          0.2160
0.50    0.5000          0.5000          0.5000

phase-flip error   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩
none     1.0000
q0       1.0000
q1       1.0000
q2       1.0000
```

## The live view

Three Bloch spheres for q0: \|ψ⟩ as prepared, q0 after decoding a single X error **without**
running the correction first (a clean X\|ψ⟩ — the decode still separates cleanly, it just
carries the error through), and q0 after the full correction (back to \|ψ⟩):

| Sphere | x | y | z |
|---|---|---|---|
| \|ψ⟩ as prepared | 0.6124 | 0.6124 | 0.5000 |
| q0, error, no correction | 0.6124 | −0.6124 | −0.5000 |
| q0, error, corrected | 0.6124 | 0.6124 | 0.5000 |

The middle sphere is X\|ψ⟩ — the same half-turn about the x-axis you saw on page 13's
uncorrected teleportation branch — and the last sphere lands back on the first.

## Using it in your own code

```swift
import SwiftQiskitCore

/// The 3-qubit repetition-code correction: a 32x32 permutation that
/// flips whichever data qubit (of q0,q1,q2) the syndrome (q3,q4)
/// accuses, leaving everything else unchanged.
func bitFlipCorrection() -> Matrix {
    var m = Matrix(rows: 32, cols: 32)
    for i in 0..<32 {
        var bits = (0..<5).map { (i >> (4 - $0)) & 1 }
        switch (bits[3], bits[4]) {
        case (1, 0): bits[0] = 1 - bits[0]
        case (1, 1): bits[1] = 1 - bits[1]
        case (0, 1): bits[2] = 1 - bits[2]
        default: break
        }
        let j = bits[0]*16 + bits[1]*8 + bits[2]*4 + bits[3]*2 + bits[4]
        m[j, i] = Complex(1)
    }
    return m
}

let qc = QuantumCircuit(qubits: 5)
qc.ry(Double.pi / 3, 0)     // prepare |ψ⟩
qc.cx(0, 1); qc.cx(0, 2)    // encode
qc.x(0)                     // an error
qc.cx(0, 3); qc.cx(1, 3)    // syndrome
qc.cx(1, 4); qc.cx(2, 4)
qc.apply(bitFlipCorrection())
qc.cx(0, 2); qc.cx(0, 1)    // decode
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first.
- **`Failed to load linked library cups`** — the Xcode 27 beta evaluator bug; re-copy the
  shim (`PLAYGROUNDSUPPORT.md`) since this page declares a `View` inline.
- **Fidelity below 1 in your own variant** — check the correction matrix's index arithmetic
  against your qubit ordering (`String(index, radix: 2)`-style bit extraction is easy to get
  backwards relative to the qubit-0-is-MSB convention used throughout the library).
- **Wondering why two errors aren't "twice as bad" instead of a clean logical flip** — that
  *is* the distance-3 story: the code can't tell "two wrongs" apart from "one wrong
  elsewhere," so it always produces a definite (wrong) answer rather than a partial one.
