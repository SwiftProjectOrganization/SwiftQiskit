# Deutsch's algorithm — help & usage guide

User-facing guide to the `10DeutschExample` playground page. The implementation plan is in
`DEUTSCHPLAN.md`.

## What the algorithm does

You are given a black-box function f: {0,1} → {0,1} and must decide whether it is

- **constant** — f(0) = f(1) (the two functions f(x) = 0 and f(x) = 1), or
- **balanced** — f(0) ≠ f(1) (the two functions f(x) = x and f(x) = 1−x).

Classically you must evaluate f **twice**: knowing f(0) alone tells you nothing about f(1).
Deutsch's algorithm (David Deutsch, 1985) decides it with a **single** query to a quantum
oracle. It was the first algorithm to show a quantum computer outperforming any classical
one at a well-defined task, and it is the 1-bit ancestor of Deutsch–Jozsa, Bernstein–Vazirani,
and ultimately Shor's algorithm.

The key idea is that the algorithm never asks "what is f(0)?" or "what is f(1)?" — it asks
for a *global* property, the parity f(0) ⊕ f(1) (0 = constant, 1 = balanced), and quantum
superposition lets one query answer that directly.

## The circuit

Two qubits: qubit 0 is the input register, qubit 1 is the ancilla. (SwiftQiskit convention:
qubit 0 is the most-significant/leftmost bit of state labels and measurement strings.)

```text
q0: |0⟩ ──────── H ──■── H ── measure   →  0 = constant, 1 = balanced
                     │
q1: |0⟩ ── X ─ H ── U_f ────────────────   (ancilla, ends in |−⟩ — discarded)
```

| Step | Code | Effect |
|---|---|---|
| 1 | `x(1)` | prepare \|01⟩ |
| 2 | `h(0)`, `h(1)` | → \|+⟩\|−⟩: input in superposition, ancilla in the kickback state |
| 3 | oracle U_f | \|x⟩\|y⟩ → \|x⟩\|y ⊕ f(x)⟩ — the single query |
| 4 | `h(0)` | interfere the two branches |
| 5 | measure qubit 0 | **0 ⇒ constant, 1 ⇒ balanced**, with certainty |

**Why it works — phase kickback.** The ancilla state \|−⟩ is an eigenvector of X with
eigenvalue −1 (the page checks ⟨−\|X\|−⟩ = −1 with the Dirac API). Since the oracle XORs
f(x) into the ancilla — i.e. applies X to it f(x) times — each branch picks up a sign:

```text
|x⟩|−⟩  →  (−1)^f(x) |x⟩|−⟩
```

A constant f phases both branches of \|+⟩ equally (an invisible global phase); a balanced f
flips the relative sign, turning \|+⟩ into \|−⟩. The final Hadamard maps \|+⟩ → \|0⟩ and
\|−⟩ → \|1⟩, so a single measurement of qubit 0 reads off the parity.

## The four oracles

Every 1-bit oracle is buildable from gates the library already has:

| f | Type | Gates |
|---|---|---|
| f(x) = 0 | constant | (none — identity) |
| f(x) = 1 | constant | `x(1)` |
| f(x) = x | balanced | `cx(0, 1)` |
| f(x) = 1−x | balanced | `cx(0, 1)` then `x(1)` |

Note the input qubit is only ever a *control*: U_f never changes \|x⟩ directly, which is
what makes the phase-kickback reading valid.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`10DeutschExample`** page
   (or follow the `[Next]` link from `09Tensor`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. Output is annotated inline with `// Expected:` comments.

## Expected output

Stage-by-stage walkthrough for f(x) = x (amplitudes up to floating-point rounding):

```text
after x(1):        |01⟩: 1.0
after h(0), h(1):  |00⟩: 0.5   |01⟩: -0.5   |10⟩: 0.5   |11⟩: -0.5
after cx(0,1):     |00⟩: 0.5   |01⟩: -0.5   |10⟩: -0.5   |11⟩: 0.5
after final h(0):  |10⟩: 0.707…   |11⟩: -0.707…
```

The `cx` line is the kickback in action: the ancilla is unchanged, but the input qubit's
\|1⟩ branch (where f(x) = 1) picked up the minus sign — \|+⟩ became \|−⟩.

Verdicts are deterministic — exactly 0 or 1, no statistics needed:

```text
oracle       P(q0=1)  verdict     expected
f(x) = 0     0.0000   constant    constant ✓
f(x) = 1     0.0000   constant    constant ✓
f(x) = x     1.0000   balanced    balanced ✓
f(x) = 1−x   1.0000   balanced    balanced ✓
```

Shot counts (1000 shots; exact splits vary run to run): the leftmost bit — qubit 0, the
answer — never varies, while the ancilla bit is a fair coin because the ancilla ends in \|−⟩:

```text
f(x) = 1 (constant):  00: ~500   01: ~500     ← leftmost bit always 0
f(x) = x (balanced):  10: ~500   11: ~500     ← leftmost bit always 1
```

## Using the algorithm in your own code

The page's building blocks are plain `SwiftQiskitCore` calls, so the same pattern works in
any target that imports the library:

```swift
import SwiftQiskitCore

/// Steps 1–4 of Deutsch's algorithm; the oracle is queried exactly once.
func deutschCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(1)
    qc.h(0)
    qc.h(1)
    oracle(qc)
    qc.h(0)
    return qc
}

let qc = deutschCircuit { $0.cx(0, 1) }        // oracle for f(x) = x
let outcome = qc.runAndMeasure()               // basis index 0...3
let isBalanced = (outcome >> 1) & 1 == 1       // qubit 0 = MSB
print(isBalanced ? "balanced" : "constant")    // "balanced"
```

For a deterministic check without sampling, read the probabilities instead:
`qc.run().probabilities[2] + qc.run().probabilities[3]` is P(qubit 0 = 1) — exactly 0.0
for constant f, exactly 1.0 for balanced f.

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first; check for
  compile errors in `Sources/SwiftQiskitCore/`. On Xcode 27 betas see also
  `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (this page is console-only, so the
  SwiftUI-specific bugs there should not affect it).
- **`cx` precondition failure** — `cx(control, target)` works on any pair of qubits of an
  n-qubit circuit, but control and target must be distinct and in range.
