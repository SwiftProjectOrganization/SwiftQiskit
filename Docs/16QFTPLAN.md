# The QFT gate decomposition as a playground page

## Context

Page 12 (`12ShorExample`) needed the inverse QFT for phase estimation but built it as a single
entrywise matrix, with an explicit note that the textbook gate decomposition — Hadamards and
controlled phase rotations, then a bit reversal — needed phase gates the library didn't expose
at the time (`12ShorExample.xcplaygroundpage/Contents.swift:171-182`). That gap can now be
closed with **no `SwiftQiskitCore` changes**:

- A controlled phase gate CP(θ) is the standard identity
  `P(θ/2)_c · CX(c,t) · P(−θ/2)_t · CX(c,t) · P(θ/2)_t` — five calls to gates the circuit API
  already has (`p`, `cx`). Verified against `diag(1,1,1,e^{iθ})`; at θ = π it reproduces CZ,
  the same gate pages 11 and 15 built by hand.
- The full QFT ladder (`h` then a cascade of `CP` per qubit, then a swap network) matches page
  12's entrywise DFT matrix to within ~1.4e-15 on every one of the 8 basis states of a 3-qubit
  register.
- Standalone phase estimation (n counting qubits + 1 eigenstate qubit, controlled powers of
  CP, then the inverse QFT ladder) recovers dyadic phases exactly and shows the expected
  spread — concentrated above the 8/π² textbook bound — for a phase that isn't a multiple of
  1/2ⁿ.

## The math, and what the plan verified

- CP(π) vs. CZ: max deviation 1.2e-16 (four basis-state checks, on 2 qubits).
- Gate-level 3-qubit QFT vs. `inverseQFT(size:)`'s formula (forward transform, so
  `e^{+2πi·y·c/N}` rather than page 12's `e^{-2πi·y·c/N}`): max amplitude deviation 1.4e-15
  across all 8 inputs.
- Dropping the final swap network reproduces the *bit-reversed* output exactly (max deviation
  0.0 in one run) — motivating the swap step rather than asserting it.
- QFT then QFT† (swap-first, negated-angle reverse ladder) returns every basis state to itself
  with amplitude-magnitude deviation ~6.7e-16.
- Phase estimation with 3 counting qubits: φ = 0.125/0.5/0.75 recovered with P = 1.0000.
  φ = 0.3 (not a multiple of 1/8) peaks at y=2 (estimate 0.25, P=0.5775) with runner-up y=3
  (estimate 0.375, P=0.2593) — together ≈0.837, above the 8/π² ≈ 0.811 worst-case bound.
- The same φ = 0.3 with 6 counting qubits: estimate 0.2969, error 0.0031 (vs. 0.0500 at 3
  qubits), P=0.8752 — precision and probability concentration both improve with more counting
  qubits, as the theory predicts.

`QuantumCircuit` has no way to splice one circuit's recorded operations into another, so every
helper in the page (`appendQFT`, `appendInverseQFT`, `basisPrep`) takes an existing circuit and
appends to it, rather than building and discarding smaller circuits — the same shape as the
library's own `h`/`cx`/`p` methods.

## Changes

### New page `Playgrounds.playground/Pages/16QFT.xcplaygroundpage/Contents.swift`

Console only, six sections: CP(θ) derived and checked against CZ; the QFT ladder checked
against page 12's matrix; the no-swap bit-reversal demonstration; the inverse QFT and a
unitarity check; standalone phase estimation with exact dyadic recovery and the φ = 0.3 spread;
a precision comparison at 3 vs. 6 counting qubits.

### Docs

- `CLAUDE.md`: add the `16QFT` bullet.
- `Docs/16QFTHELP.md`: user-facing guide.
- This file records the plan.
- `README.md`: a `### 16QFT` section, the project tree, and the gate tables' "Used in" column
  (`p` gains its first use as a *controlled* rotation building block).
- `STATUSandTODO.md`: an entry alongside pages 10–15.
- `00TOC.xcplaygroundpage`: a bullet plus the guide-list update.
- Page 15's `[Next]` marker already points here; page 16 gets `[Previous]`/`[Next]`.

## Explicitly not doing

- No `SwiftQiskitCore` changes — `cp` stays a page-level helper, exactly like CZ/CCZ on pages
  11 and 13, and A(θ) on page 15.
- No rewrite of page 12 to use the gate-level QFT — it stays as is, and this page explains why
  the entrywise matrix was the right call there (it sidesteps bit-reversal bookkeeping when
  the goal is phase estimation's *output*, not the QFT circuit itself).
- No decomposition of CP(θ) further into single-qubit rotations — the five-gate identity is
  the standard textbook form and matches what real hardware compilers emit.

## Verification

1. Every section's numbers were computed with `RunCodeSnippet` against `SwiftQiskitCore`
   before finalizing the page, run as one exact copy of the final page code (not a paraphrase)
   to make sure refactoring the QFT builders into append-style helpers didn't change any
   result.
2. `BuildProject` — the SwiftQiskit scheme must keep building for pages to run.
3. `swift test` / `RunAllTests` under `SwiftQiskit-Package` to confirm no Core regression
   (none expected — no Core changes).
4. Open `16QFT` in Xcode and run it (console only, no live-view/beta-shim concerns).
