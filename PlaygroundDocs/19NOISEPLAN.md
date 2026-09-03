# Open systems and noise as a playground page

## Context

Pages 01–18 all assume a perfect, isolated, **pure** state — even `14ErrorCorrection` models
errors as discrete coherent `rx(θ)` rotations, not decoherence. The density matrix, the object
that makes mixtures, decoherence, and reduced states of entangled systems expressible, never
appears. This page closes that gap with **no `SwiftQiskitCore` changes**:

- ρ = |ψ⟩⟨ψ| reuses the existing outer product `Ket * Bra`
  (`Sources/SwiftQiskitCore/Quantum/Dirac.swift:119-127`).
- `Matrix` has no `+`, scalar multiply, or trace (`Sources/SwiftQiskitCore/Math/Matrix.swift`),
  so page-level `addM`/`scaleM`/`trace` helpers are required — the same shape as page 12's
  QFT† and page 18's Hamiltonian, both built entrywise for the same reason.
- Kraus channels ρ' = Σ Kᵢ ρ Kᵢ† are assembled from `Matrix *` and the existing `†` adjoint.
- Mixed-state Bloch coordinates reuse `Ket`/Pauli machinery already in Core; only the shared
  `BlochVector` type needs a small additive change (below) to plot a vector shorter than 1.

## The math, and what the plan verified

All figures below were computed by compiling `SwiftQiskitCore` standalone with `swiftc` and
running the exact page math (not paraphrased) — see Verification.

- **Trace preservation** Σ Kᵢ†Kᵢ = I, checked as the max entrywise deviation from I₂ at p = 0.3
  (bit-flip, phase-flip) / p = 0.3 (depolarizing) / γ = 0.3 (amplitude damping):
  bit-flip 0.0, phase-flip 0.0, depolarizing 1.11e-16, amplitude-damping 0.0.
- **Coherence decay is exactly (1 − 2p)ⁿ.** Phase-flip(p = 0.1) applied n times to ρ = |+⟩⟨+|
  (off-diagonal starts at 0.5): n=1 → 0.4 (predicted 0.4), n=5 → 0.16384 (0.16384000...),
  n=10 → 0.0536870912 (0.0536870912...), n=20 → 0.00576460752303... (same) — measured and
  closed-form agree to floating-point precision at every n tested.
- **Purity** Tr(ρ²): |+⟩ starts at 1.0; after 10 rounds of phase-flip(0.1) it is 0.505765 (not
  0.5 — coherence is nearly gone but not exactly zero at finite n). A single full
  depolarizing round (p = 1) on |0⟩ gives ρ = diag(0.5, 0.5), purity exactly 0.5 — the
  maximally mixed state.
- **Amplitude damping pulls the Bloch vector toward the |0⟩ pole while shrinking x, y.**
  Starting from |+⟩ (Bloch (1, 0, 0)) with γ = 0.2, after 20 rounds: Bloch = (0.10737,
  0, 0.98847), purity 0.99430. This matches the closed form exactly: x shrinks by
  √(1−γ) per round → √0.8²⁰ = 0.8¹⁰ = 0.10737418..., z rises as 1 − (1−γ)ⁿ = 1 − 0.8²⁰ =
  0.98847...
  **The Bloch vector sitting *inside* the sphere is the picture no pure state can draw** —
  the reason this page needs `BlochVector(x:y:z:)` (see Changes).
- **Bell-pair partial trace.** For |Φ⁺⟩ = (|00⟩+|11⟩)/√2: ρ (the full 2-qubit state) has
  purity 0.99999999999999996 (≈1, pure), but tracing out qubit 1 gives
  ρ_A = diag(0.5, 0.5) exactly (off-diagonals 0.0), purity 0.5, Bloch magnitude 0.0, and
  **entropy exactly 1.0** via the closed-form 2×2 eigenvalues (page 18's grading trick:
  λ = (1 ± |r|)/2). A product state |+⟩⊗|0⟩ gives ρ_A with Bloch magnitude 0.999999999999...
  (≈1) and entropy 6.04e-15 (≈0) — pure marginal, zero entanglement, confirming the metric
  distinguishes the two cases exactly as claimed.
- **Monte-Carlo unraveling reproduces the channel from pure-state code alone.** Per shot: flip
  a coin with probability p, apply `z(0)` (phase flip) or not, then measure in the rotated
  basis. Over 20,000 shots at p = 0.1 on |+⟩, measured P(+x) = 0.90005 against the exact
  prediction (1 + (1−2p))/2 = 0.9 — agreement well within shot noise (√(pq/N) ≈ 0.0021).
  **This is the section that makes the page a programming example, not just linear algebra**:
  it shows how to add noise to a state-vector simulator without a `DensityMatrix` type.

## Changes

### New page `Playgrounds.playground/Pages/19Noise.xcplaygroundpage/Contents.swift`

Console plus one live view, seven sections: ρ from `Ket * Bra` and purity; a mixture (½|0⟩⟨0| +
½|1⟩⟨1|) vs. a superposition (|+⟩⟨+|) — identical Z-statistics, different X-statistics; the
four Kraus channels with trace-preservation checks; mixed-state Bloch vectors and the closed-form
decay; the Monte-Carlo unraveling; the Bell-pair partial trace and entropy vs. a product-state
control.

### Additive change to `Playgrounds.playground/Sources/BlochVector.swift`

Add `public init(x: Double, y: Double, z: Double)` alongside the existing
`init(_ state: StateVector)`, so a mixed-state Bloch vector (computed as
`(Tr(ρX), Tr(ρY), Tr(ρZ))`) can be plotted directly. No existing call site changes — this is
additive. `theta`/`phi` should keep reading `acos(z)`/`atan2(y,x)` on the raw (possibly
sub-unit) coordinates; `BlochSphereView` already draws the arrow at the vector's true length
(`BlochSphereView.swift:114-126`), so a shrunken vector renders correctly with **no view
change**.

### Docs

- `CLAUDE.md`: add the `19Noise` bullet.
- `PlaygroundDocs/19NOISEHELP.md`: user-facing guide (deferred with the page).
- This file records the plan.
- `README.md`: a `### 19Noise` section and project-tree update.
- `STATUSandTODO.md`: an entry — this is also the "Noise models" roadmap item, so mark that
  line addressed at the playground-example level (Core itself still has no `DensityMatrix`).
- `PLAYGROUNDSUPPORT.md`: a `19Noise` row in "Which pages use what," and document the additive
  `BlochVector(x:y:z:)` initializer.
- `00TOC.xcplaygroundpage`: a bullet plus the guide-list update.
- Page 18 gets `[Next]`; page 19 gets `[Previous]`/`[Next]`.

## Explicitly not doing

- **No `DensityMatrix` type in Core.** v0.1 is a state-vector simulator; ρ stays a page-level
  `Matrix`, exactly like page 12's QFT† and page 18's Hamiltonian. A future Core type is
  roadmap material — this page is the argument for why one would be useful, not the type
  itself.
- **No re-run of page 14's error-correction code under a depolarizing channel** to recover its
  p_L = 3p² − 2p³ empirically — a cross-reference note instead, to keep this page's own scope
  (channels, not codes) legible.
- **No maximum-likelihood state estimation** — that belongs to the tomography page (`20`),
  which depends on this page's mixed states for its own "unphysical estimate" section.

## Verification

1. Every number above was computed by compiling `SwiftQiskitCore`'s sources directly with
   `swiftc` into a standalone dylib (bypassing an `ENABLE_DEBUG_DYLIB` requirement on
   `RunCodeSnippet` for executable-target previews) and running the page's exact math in a
   driver executable — not a paraphrase.
2. `mcp__xcode-tools__BuildProject` — confirmed green on the `SwiftQiskit` scheme before and
   after this work; the scheme must keep building for pages to run.
3. `swift test` / `RunAllTests` under `SwiftQiskit-Package` — no Core changes proposed, so no
   regression expected; not re-run for this plan since only Docs were written.
4. When the page is built: open `19Noise` in Xcode and run it; re-copy the `libcups` shim
   immediately before running (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds").
