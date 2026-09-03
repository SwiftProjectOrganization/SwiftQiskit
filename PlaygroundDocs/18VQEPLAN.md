# VQE (the variational quantum eigensolver) as a playground page

## Context

Pages 10–17 all run a *fixed* circuit — the algorithm is compiled ahead of time and executed
once (or sampled many times). None of them show the loop that defines the NISQ era: a
parameterized circuit prepares a trial state, a Hamiltonian's expectation value is measured on
it, and a classical optimizer nudges the parameter to lower that energy. VQE closes that gap
with **no `SwiftQiskitCore` changes**:

- The target is the 2-qubit qubit Hamiltonian for H₂ in a minimal (STO-3G) basis after the
  Jordan–Wigner transform, near its equilibrium bond length — the standard example from the
  VQE literature (O'Malley et al., 2016), reused across most VQE tutorials because it is small
  enough to diagonalize by hand for grading.
- `Matrix` has no `+` or scalar multiply, so H is assembled entrywise from six Pauli terms
  (page 12's QFT† idiom, page 15's tilted observable) — Pauli tensor products via Core's `⊗`.
- A single-parameter ansatz (`x(0); ry(θ,1); cx(1,0)`) stays exactly inside the
  {|01⟩, |10⟩} subspace for every θ, so the exact ground energy is a closed-form 2×2
  eigenvalue — no eigensolver needed to check the optimizer's answer.
- The energy is `psi† * H * psi`, page 08's Dirac expectation-value idiom, reused rather than
  reinvented.
- The parameter-shift rule gives an *exact* gradient for a single-Pauli-rotation gate — not an
  approximation — verified against a finite difference before using it to drive gradient
  descent.

## The math, and what the plan verified

- H assembled from g = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910] on
  I⊗I, Z⊗I, I⊗Z, Z⊗Z, Y⊗Y, X⊗X.
- `ansatz(θ)` amplitudes at |00⟩ and |11⟩ are exactly 0 at every θ tested (0.0, 0.7, 0.9, 2.0)
  — confirms the ansatz never leaves the single-excitation subspace.
- E(0) = -1.830200, E(π/2) = -0.870000, E(π) = -0.273800, E(3π/2) = -1.234000.
- Exact electronic ground energy (closed-form 2×2 eigenvalue of H's {|01⟩,|10⟩} block):
  -1.851199 Ha; with nuclear repulsion (0.7055 Ha, a fixed classical offset): -1.145699 Ha.
- Parameter-shift gradient vs. finite difference agree to 6 decimals at θ = 0.0, 0.4, 1.0, 2.5
  (e.g. both give 0.470678 at θ = 0.4).
- Gradient descent from θ = 0, learning rate 1.0, 40 steps: converges by step 10 to
  θ = -0.229744, E = -1.851199, error vs. the closed form **exactly 0.00e+00**.

## Changes

### New page `Playgrounds.playground/Pages/18VQE.xcplaygroundpage/Contents.swift`

Console + one live view. Seven sections: the Hamiltonian assembled entrywise; the ansatz and
its subspace check; the energy via the Dirac expectation value; the exact closed-form answer;
parameter-shift gradients pinned against finite differences; gradient descent to convergence;
a live chart of the E(θ) landscape with the optimizer's own visited points overlaid.

The chart reuses `CHSHChartView` (`Playgrounds.playground/Sources/CHSHChartView.swift`)
unchanged — its `Series(label:color:points:isLine:)` API is already generic, so no new shared
view is added and no new exposure to the Xcode 27 beta `@State`/macro bug. Its file-header
comment, currently framed as CHSH-specific, is widened to describe it as the shared 2D
line/scatter chart used by pages 15 and 18.

### Docs

- `CLAUDE.md`: add the `18VQE` bullet.
- `PlaygroundDocs/18VQEHELP.md`: user-facing guide.
- This file records the plan.
- `README.md`: a `### 18VQE` section, project tree update, and gate tables' "Used in" column
  (`ry` gains a variational use alongside its page 15 measurement-rotation use).
- `STATUSandTODO.md`: likely its own short heading, since VQE isn't a textbook fixed-circuit
  algorithm like pages 10–17.
- `PLAYGROUNDSUPPORT.md`: an `18VQE` row in "Which pages use what," and the widened
  `CHSHChartView` description above.
- `00TOC.xcplaygroundpage`: a bullet plus the guide-list update.
- Page 17 gets `[Next]`; page 18 gets `[Previous]` only (currently the last page).

## Explicitly not doing

- No shot-noise-based energy estimation (measuring each Pauli term in its own basis and
  averaging shots) — that's the honest hardware story, but it doubles the page's length for a
  point pages 07/13/15 already made about sampling vs. exact expectation values. Called out as
  a "what real hardware does differently" note instead.
- No multi-parameter ansatz or general-purpose classical optimizer (Nelder–Mead, COBYLA) — one
  parameter keeps the energy landscape a single 2D curve, plottable and graded exactly against
  a closed-form answer. A richer ansatz is future scope, not this page's job.
- No `SwiftQiskitCore` changes — H stays a page-level hand-built `Matrix`, exactly like page
  12's QFT† and page 15's A(θ).

## Verification

1. Every printed number was computed with `RunCodeSnippet` against `SwiftQiskitCore`, running
   the exact final page code for Sections 1–6 (the live-view Section 7 isn't runnable outside
   Xcode's playground evaluator).
2. `BuildProject` — the SwiftQiskit scheme must keep building for pages to run.
3. `swift test` / `RunAllTests` under `SwiftQiskit-Package` — no Core changes, no regression
   expected.
4. Open `18VQE` in Xcode and run it; re-copy the `libcups` shim immediately before running
   (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds").
