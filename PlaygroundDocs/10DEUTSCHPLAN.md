# Deutsch's algorithm as a playground page

## Context

The playground's lecture pages so far cover machinery — states, gates, Bloch sphere, Dirac
notation, tensor products — but no actual quantum *algorithm*. Deutsch's algorithm is the
natural first one: given a black-box f: {0,1} → {0,1}, decide whether it is **constant**
(f(0) = f(1)) or **balanced** (f(0) ≠ f(1)) with a *single* oracle query, where classically
two evaluations are required. It also happens to fit the v0.1 API limits exactly: the circuit
needs 2 qubits, and all four possible oracles are buildable from `x(1)` and `cx(0, 1)` — the
one CNOT form the library supports. No changes to `SwiftQiskitCore` are needed.

> **Update (2026-08-13):** `cx(control, target)` is now general — any distinct pair on an
> n-qubit circuit, via `CNOTGate.matrix(qubits:control:target:)`. The construction above
> remains valid; only the "one CNOT form" restriction is historical.

## The algorithm

Circuit on 2 qubits (qubit 0 = input register = MSB, qubit 1 = ancilla):

1. `x(1)` — prepare |01⟩
2. `h(0)`, `h(1)` — → |+⟩|−⟩
3. Oracle U_f: |x⟩|y⟩ → |x⟩|y ⊕ f(x)⟩ — the single query; because X|−⟩ = −|−⟩, this
   kicks (−1)^f(x) back as a phase on the input qubit (phase kickback)
4. `h(0)` — interfere the two branches
5. Measure qubit 0 (leftmost bit): **0 ⇒ constant, 1 ⇒ balanced**, deterministically.
   The ancilla stays in |−⟩, so its bit is 50/50 noise.

The four oracles, from existing gates only (the input qubit is only ever a control):

| f | Type | Gates |
|---|---|---|
| f(x) = 0 | constant | (none — identity) |
| f(x) = 1 | constant | `x(1)` |
| f(x) = x | balanced | `cx(0, 1)` |
| f(x) = 1−x | balanced | `cx(0, 1)` then `x(1)` |

## Changes

### 1. New page `Playgrounds.playground/Pages/10DeutschExample.xcplaygroundpage/Contents.swift`

Console-only page in the sectioned style of `09Tensor` (banner comments, printed checks with
`// Expected:` annotations; no SwiftUI live view, sidestepping the Xcode 27 beta issues in
`PLAYGROUNDSUPPORT.md`). Structure:

- Intro comment: the problem, the circuit, and why phase kickback turns f's value into a sign.
- **Section 1** — the four oracles as a `DeutschOracle` struct
  (`name` / `isBalanced` / `apply: (QuantumCircuit) -> Void`).
- **Section 2** — `deutschCircuit(oracle:)` assembling steps 1–4, plus a `pretty(_:)`
  state formatter with zero-padded ket labels.
- **Section 3** — stage-by-stage walkthrough for f(x) = x, printing the state after each
  gate (`run()` replays the recorded operations, so the circuit is built incrementally):
  |01⟩ → |+⟩|−⟩ → |−⟩|−⟩ (the kickback) → |1⟩|−⟩.
- **Section 4** — loop over all four oracles; P(qubit 0 = 1) from `run().probabilities`
  is exactly 0 (constant) or 1 (balanced), so the verdict is certain from one query.
- **Section 5** — `measure(shots: 1000)` for one constant and one balanced oracle: the
  leftmost bit of every outcome string is the verdict; the ancilla bit is ~50/50.
- **Section 6** — the eigenvalue behind it all: ⟨−|X|−⟩ = −1 via the Dirac API
  (`Ket.minus`, postfix `†`, `Bra * Ket`), tying back to page 08.
- Linked with `//: [Previous](@previous)` / `//: [Next](@next)`; `09Tensor` gains the
  previously missing `//: [Next](@next)` so the chain reaches the new page. Page ordering
  is alphabetical (no page list in `contents.xcplayground`), so `10…` slots in after `09…`
  with no manifest edit.

### 2. Docs

- `CLAUDE.md`: add the `10DeutschExample` bullet to the playground page list.
- This file (`PlaygroundDocs/10DEUTSCHPLAN.md`) records the plan.

## Explicitly not doing

- No new gates or Core changes — everything uses existing `h/x/cx`, `run()`,
  `runAndMeasure()`, `measure(shots:)`, and the Dirac helpers.
- No SwiftUI live view.

## Verification

1. Playground pages compile only inside Xcode, so validate the logic first with
   `RunCodeSnippet` (xcode-tools) running the page's core code against `SwiftQiskitCore`:
   all four oracles must yield P(q0=1) ∈ {0, 1} matching constant/balanced.
2. `BuildProject` — the SwiftQiskit scheme must keep building for pages to run.
3. Open `10DeutschExample` in Xcode and run it; the printed output is annotated inline
   with `// Expected:` comments.
