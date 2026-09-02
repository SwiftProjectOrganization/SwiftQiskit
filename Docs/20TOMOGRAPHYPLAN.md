# State tomography as a playground page

## Context

Every page from 01 through 19 reads a state's amplitudes directly off the `StateVector` —
something no real device permits. `measure(shots:)` is used for statistics (pages 06, 07, 15,
17) but never to *reconstruct* an unknown state. This page is the honest version of "what a
real device gives you," and it depends on page 19's mixed states for its most important
result. **No `SwiftQiskitCore` changes:**

- Basis rotations reuse existing circuit gates: `h(0)` for the X basis, `sdg(0); h(0)` for the
  Y basis (verified below against page 19's `plusI`/`minusI` basis kets, not asserted).
- The estimator ⟨A⟩ ≈ (N₀ − N₁)/N and the reconstructed Bloch vector reuse
  `Ket`/`StateVector.measure()` exactly as they exist.
- The Bell-marginal reconstruction reuses page 19's mixed-state result (ρ_A = I/2) as the
  *target* the estimator should recover from shots alone.

## The math, and what the plan verified

- **Basis-rotation order, pinned exactly (not assumed):** applying `Sdg` then `H` to `|+i⟩`
  (a +1 eigenstate of Y) collapses it to `|0⟩` deterministically (amplitude 0.99999999999998,
  0.0) — confirming `sdg(0); h(0)` is the correct order for a Y-basis measurement. The reverse
  order (`H` then `Sdg`) does **not** diagonalize Y (gives an equal superposition), so this was
  worth checking rather than guessing.
- **Estimator sign check.** On a tilted state (RY(1.0472) then RZ(0.7854), i.e. θ≈60°, φ≈45°
  in page 04/08's parametrization), the exact expectation values are
  ⟨X⟩=0.612372, ⟨Y⟩=0.612374, ⟨Z⟩=0.499998; shot-based estimates at N=100,000 are 0.61676,
  0.61472, 0.50038 — all within ~0.005 of exact, consistent with shot noise at that N.
- **Error scales as 1/√N.** RMS error of the X-estimate against the exact value, over 20
  trials per N: N=100 → 0.0875, N=1,000 → 0.0201, N=10,000 → 0.00663, N=100,000 → 0.00158.
  Successive ratios (0.0875/0.0201≈4.35, 0.0201/0.00663≈3.03, 0.00663/0.00158≈4.2) bracket the
  √10 ≈ 3.16 predicted by a 10× increase in N, confirming the 1/√N trend (some scatter is
  expected from only 20 trials per point).
- **Unphysical estimates: the real result is subtler than "shrinks with N."** For a *pure*
  state sitting exactly on the Bloch-ball boundary, an all-three-axis reconstruction (X, Y, Z
  each independently estimated from shots) lands outside the unit ball roughly **half the
  time no matter how large N is** — measured frequency at N=10/50/200/1,000/5,000 on the
  tilted state: 0.632, 0.547, 0.505, 0.501, 0.498, converging to 0.5, not 0. This makes sense:
  symmetric per-axis noise straddles a boundary point equally in both directions. A stabilizer
  state (e.g. |+⟩, an exact X-eigenstate) is the misleading edge case — its X-estimate is
  *deterministic* at 1.0, so any Y/Z noise pushes the norm over 1 on nearly every trial
  (measured ≈0.96–1.0 across N), which looks like a bug but is a real consequence of measuring
  a state exactly aligned with one axis. **Only a genuinely mixed state's frequency shrinks
  toward zero**: an ensemble that is 75% |0⟩/25% |1⟩ (Bloch (0,0,0.5), |r|=0.5) gives unphysical
  frequency 0.083 at N=10 and 0.0 at N≥50 over 1,000 trials. The page's takeaway is this
  contrast, not a single decaying curve — and it is the direct payoff of page 19 supplying a
  genuinely mixed state to test against.
- **Bell marginal reconstructed from shots alone.** Estimating qubit 0's Bloch vector from a
  Bell pair (50,000 shots per basis) gives (x,y,z) = (−0.0124, −0.0011, 0.0004), |r| = 0.0125 —
  statistically indistinguishable from the origin, reproducing page 19's exact ρ_A = I/2 by
  measurement rather than derivation, and restating page 13's no-cloning result as "one copy of
  an entangled qubit is never enough to see anything."
- **Cost table (not simulated, recorded as a table):** full single-qubit tomography needs 3
  settings; two qubits need 3² = 9; n qubits need 3ⁿ. This is exactly why page 18's VQE
  measures individual Pauli terms of the Hamiltonian rather than reconstructing the full state.

## Changes

### New page `Playgrounds.playground/Pages/20Tomography.xcplaygroundpage/Contents.swift`

Console plus one live view, five sections: basis rotations pinned against exact expectation
values; the estimator and its 1/√N error scaling; the pure-vs-mixed unphysical-frequency
contrast; the Bell-marginal reconstruction; the 3ⁿ cost table.

### Live view

Two `BlochSphereView`s side by side — the true Bloch vector (from `BlochVector(_:)`) and the
shot-reconstructed one (from page 19's new `BlochVector(x:y:z:)`). Depends on page 19's
additive initializer; no further shared-code change.

### Docs

- `CLAUDE.md`: add the `20Tomography` bullet, after `19Noise`.
- `Docs/20TOMOGRAPHYHELP.md`: user-facing guide (deferred with the page).
- This file records the plan.
- `README.md`: a `### 20Tomography` section.
- `STATUSandTODO.md`: an entry alongside page 19.
- `PLAYGROUNDSUPPORT.md`: a `20Tomography` row in "Which pages use what."
- `00TOC.xcplaygroundpage`: a bullet plus the guide-list update.
- Page 19 gets `[Next]`; page 20 gets `[Previous]`/`[Next]`.

## Explicitly not doing

- **No maximum-likelihood or linear-inversion estimator implementation** — named and motivated
  as the fix for unphysical estimates, not coded. Implementing one is a reasonable follow-up
  page, not this one's job.
- **No two-qubit full-state tomography** beyond the cost-table entry — the point is the
  exponential scaling, not walking through all 9 settings.
- **No classical shadows** or other sample-efficient estimation schemes — out of scope for an
  educational first look at measurement.

## Verification

1. Every number above was computed by compiling `SwiftQiskitCore` standalone with `swiftc` and
   running the page's exact math in a driver executable, including the basis-rotation order
   check (run both orders on `|+i⟩` before picking one) and the pure-vs-mixed unphysical
   frequency contrast (initially run only on `|+⟩`, which gave a misleading ~100% frequency at
   every N until re-run on a generic tilted state and a genuinely mixed ensemble revealed the
   real trend — the corrected numbers above are what belongs in the page).
2. `mcp__xcode-tools__BuildProject` — confirmed green on the `SwiftQiskit` scheme.
3. `swift test` / `RunAllTests` under `SwiftQiskit-Package` — no Core changes proposed; not
   re-run for this plan since only Docs were written.
4. When the page is built: open `20Tomography` in Xcode and run it; re-copy the `libcups` shim
   immediately before running (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds").
