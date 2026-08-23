# The 3-qubit bit-flip/phase-flip code as a playground page

## Context

Pages 10–13 all show a quantum computer *succeeding*: a correct verdict, a search hit, a
factored number, a teleported qubit. Quantum error correction (QEC) is the page that shows
what has to happen *before* any of that is reliable on real hardware — and it is the natural
next stop after page 13 introduced multi-qubit entanglement as a resource rather than a
curiosity. The 3-qubit repetition code is the simplest nontrivial code and fits v0.1 with
**no changes to `SwiftQiskitCore`**:

- The correction step — "look at the two-bit syndrome, then flip whichever qubit it
  accuses" — is a Toffoli-with-mixed-controls, three times over. There is no Toffoli gate
  and no partial/mid-circuit measurement in Core, so (following page 11's CCZ idiom and
  page 12's permutation-matrix idiom) it is built as a single 32×32 basis-state permutation
  fed to `QuantumCircuit.apply(_:)`.
- Because the correction is never conditioned on an actual measurement, it is applied
  *coherently* to the full superposition. This turns out to be the page's most interesting
  fact for free: a continuous `rx(θ)` error digitizes into a discrete correction with
  **exact** fidelity 1.0000 at every θ, because the correction fixes both interfering
  branches (no error / X error) at once.
- Phase-flip protection needs no new machinery: `h` on all three data qubits before and
  after a `z` error turns it into exactly the `x` error the rest of the page already
  handles (H Z H = X), reusing page 08's basis-change idea.

## The code

Register (qubit 0 is the most-significant bit): q0, q1, q2 = data (q0 starts holding \|ψ⟩);
q3, q4 = syndrome ancillas. θ = 60°, φ = 45° — the same payload as pages 04, 08 and 13.

1. Encode: `cx(0,1); cx(0,2)` → α\|000⟩+β\|111⟩.
2. Syndrome: `cx(0,3); cx(1,3)` (parity q0⊕q1 → q3), `cx(1,4); cx(2,4)` (parity q1⊕q2 → q4).
   Verified table: none→00, q0→10, q1→11, q2→01 — every case distinct.
3. Correction: one 32×32 permutation, decoding (q3,q4) and flipping the accused data qubit.
   Confirmed unitary (it's a permutation) and confirmed to restore the exact codeword
   (fidelity 1.0000) for all four single-error cases, syndrome bits left untouched.
4. Decode: `cx(0,2); cx(0,1)` — the encoding run backwards — returns \|ψ⟩ to q0 alone
   (fidelity 1.0000 for all four cases, this time against \|ψ⟩⊗\|00⟩⊗\|syndrome⟩).
5. `rx(θ)` in place of `x`: a coherent partial error. Fidelity stays exactly 1.0000 for
   θ = 0…π while the syndrome ancillas' branch weights track cos²(θ/2)/sin²(θ/2) exactly —
   confirmed numerically at five angles.
6. Two simultaneous errors (q0 **and** q1) alias to the same syndrome (01) as a lone error
   on q2, so the correction "fixes" the qubit that was never wrong — net effect, a full
   logical X on the encoded qubit. Demonstrated starkly with \|ψ⟩ = \|1⟩ (decodes to \|0⟩ with
   certainty), then the exact logical error rate p_L = 3p² − 2p³ confirmed by enumerating
   all 8 independent single-flip patterns and comparing to the closed form (both agree to
   4 decimals at p = 0.05, 0.1, 0.2, 0.3, 0.5).
7. Phase flips: `h(0);h(1);h(2)`, a `z` error, `h(0);h(1);h(2)` again, then the *same*
   syndrome/correction/decode circuit — confirmed to reproduce Section 2's exact syndrome
   table and Section 4's exact fidelities.

## Changes

### 1. New page `Playgrounds.playground/Pages/14ErrorCorrection.xcplaygroundpage/Contents.swift`

Sectioned like pages 10–13, plus a small Bloch-sphere live view. Eight sections (see the
page for the full commentary): the code, the syndrome table, coherent correction, decode,
the continuous-error digitization sweep, the two-error failure mode with the enumerated
logical error rate, phase flips by Hadamard conjugation, and a closing prose section on why
Shor's concatenated 9-qubit code is out of scope for a dense-matrix `QuantumCircuit`. A
final live view shows q0's Bloch point for \|ψ⟩, an *uncorrected* decode (a clean X\|ψ⟩ — the
decode still separates into a product state, it's just the wrong one), and the corrected
state.

### 2. Docs

- `CLAUDE.md`: add the `14ErrorCorrection` bullet.
- `Docs/14ERRORCORRECTIONHELP.md`: user-facing guide.
- This file records the plan.
- `README.md`: a `### 14ErrorCorrection` section, the project tree, and the gate tables'
  "Used in" column.
- `STATUSandTODO.md`: an entry alongside pages 10–13.
- `PLAYGROUNDSUPPORT.md`: a row in "Which pages use what".

## Explicitly not doing

- No `SwiftQiskitCore` changes — no Toffoli, no partial/mid-circuit measurement, no density
  matrices or noise channels (all stay on the `STATUSandTODO.md` roadmap).
- No Shor's 9-qubit concatenated code, no 5-qubit or surface codes — a 9-data-qubit version
  of this page's circuit needs 2¹³-dimensional matrices per operation, which is out of reach
  for v0.1's dense `QuantumCircuit` representation (see the page's Section 8).
- No new shared `Sources/` code — the live view reuses `BlochSphereView`.

## Verification

1. Every numeric claim was checked with `RunCodeSnippet` (xcode-tools) against
   `SwiftQiskitCore` before and after writing the page, in smaller batches once the preview
   service showed instability on the largest combined snippets (each batch individually
   ran clean with matching numbers, and one early full run covered every section at once):
   - syndrome table {00, 10, 11, 01}; correction matrix exactly unitary;
   - fidelity 1.0000 for all four single-error cases, both post-correction (codeword form)
     and post-decode (\|ψ⟩ form);
   - `rx(θ)` sweep: fidelity 1.0000 at θ = 0, π/6, π/3, π/2, π, with syndrome branch weights
     1/0, 0.9330/0.0670, 0.7500/0.2500, 0.5000/0.5000, 0/1 — cos²(θ/2)/sin²(θ/2) exactly;
   - two-error (q0,q1) on \|ψ⟩=\|1⟩ decodes to P(0)=1.0000 — a confident wrong answer;
   - enumerated p_L at p = 0.05/0.1/0.2/0.3/0.5 matches 3p²−2p³ to 4 decimals;
   - phase-flip section reproduces the bit-flip section's syndrome table and fidelities
     exactly;
   - live-view Bloch slice: the uncorrected q0 (index 14/30 of the 32-dim decoded-without-
     correction state — q1, q2 end at \|1⟩ too when the error isn't fixed first) matches
     X\|ψ⟩'s amplitudes exactly.
2. `BuildProject` — the SwiftQiskit scheme must keep building for pages to run.
3. Open `14ErrorCorrection` in Xcode and run it; on Xcode 27 betas, re-copy the `libcups`
   shim immediately before running (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds") —
   this page declares a `View` inline.
