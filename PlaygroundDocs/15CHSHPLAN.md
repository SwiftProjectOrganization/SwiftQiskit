# The CHSH inequality as a playground page

## Context

Pages 10–14 all showcase a quantum computer *succeeding* at a task — a correct verdict, a
search hit, a factored number, a teleported qubit, a corrected error. The CHSH inequality is
a different kind of page: its payoff is a physics fact, not a speedup — the correlations a
Bell pair produces are provably impossible for any theory where Alice and Bob's outcomes are
fixed in advance by a shared variable. It closes out the protocols/foundations arc alongside
pages 13–14. It fits v0.1 with **no changes to `SwiftQiskitCore`**:

- Measuring "along a tilted axis" needs the observable A(θ) = cos θ·Z + sin θ·X, and
  `Matrix` has no `+` or scalar multiply, so (page 12's QFT† idiom) it is built entrywise.
- Measuring A(θ) via the existing gate set is `ry(-θ)` followed by an ordinary
  computational-basis measurement/expectation. The *sign* of that rotation is not obvious
  from the gate's docstring alone, so it is pinned numerically against the exact
  ⟨ψ|A(θ)|ψ⟩ before any CHSH number is trusted (Section 2) — and the check doubles as a
  cross-reference: A(0) reproduces page 04/08's ⟨Z⟩ = 0.5000 and A(π/2) reproduces their
  ⟨X⟩ = 0.6124 for the same test qubit.
- Every correlator is computed **two ways** — exactly via `psi† * (A(a) ⊗ A(b)) * psi`
  (Core's `⊗` and the Dirac `Bra * Matrix`), and via `measure(shots:)` after rotating each
  qubit into its measurement basis — so the shot-sampled numbers are never taken on faith.

## The math, and what surprised the plan

The CHSH statistic S = E(a,b) − E(a,b′) + E(a′,b) + E(a′,b′) is bounded by |S| ≤ 2 for any
local-hidden-variable (LHV) theory and reaches 2√2 ≈ 2.8284 for a Bell pair measured at
a = 0, a′ = π/2, b = π/4, b′ = 3π/4 (Tsirelson's bound — never higher, even for quantum
states). Confirmed numerically:

- All 16 deterministic ±1 strategies enumerated exhaustively: max \|S\| = 2, exactly.
- A **shared-direction** LHV model — λ uniform on [0, 2π), each side's answer is
  sign(cos(setting − λ)) — was originally planned only as a Monte Carlo sanity check
  ("a randomized-λ sampler for the same conclusion"). It turned out to do more: at the
  standard angles it gives S ≈ 2.0, i.e. it *saturates* the bound rather than merely
  respecting it, and its correlator as a function of the angle difference θ is exactly the
  line 1 − 2θ/π. That line was independently planned as "the classical LHV-compatible line"
  for Section 6's chart — the two turned out to be the same object, so the page introduces
  the model once (Section 1) and reuses it as the chart's classical curve (Section 6)
  instead of asserting an unmotivated line.
- Bell-pair exact and 4000-shot-sampled correlators both match cos(a − b) to 4 decimals;
  exact S = 2.8284 exactly, one sampled run gave S = 2.8305/2.8360 (well inside a
  back-of-envelope ±0.05 statistical band for 4 independent 4000-shot correlators).
- Product state \|+⟩⊗\|+⟩ (no `cx`): S = 1.4142 = √2 — inside the classical-looking-fine
  range but note this isn't the LHV bound check (that's Section 1); it's the "entanglement
  is necessary" check. A fine-grained sweep over the second setting, holding a = 0, a′ = π/2
  fixed, finds a hard ceiling at exactly 2.8284 — Tsirelson's bound, confirmed rather than
  asserted.

## Changes

### 1. New shared view `Playgrounds.playground/Sources/CHSHChartView.swift`

A stateless SwiftUI `Canvas` chart (axes, zero line, polylines for `isLine: true` series,
scatter dots for `isLine: false` series, a small legend), in the style of
`BlochProjectionView.swift`. **No `@State`**, and it's the page's *only* new shared type —
required to live in `Sources/` per the Xcode 27 beta workarounds (an inline `View`
declaration is exactly the case that needs the `libcups` shim, and this page has one anyway
for the gallery pattern pages 13–14 already use, so putting the chart in `Sources/` doesn't
add a new failure mode, just reuses the existing one).

```swift
public struct CHSHChartView: View {
    public struct Series {
        public init(label: String, color: Color, points: [CGPoint], isLine: Bool)
    }
    public init(title: String, xRange: ClosedRange<Double>, yRange: ClosedRange<Double>,
                series: [Series], size: CGSize = CGSize(width: 480, height: 300))
}
```

### 2. New page `Playgrounds.playground/Pages/15CHSH.xcplaygroundpage/Contents.swift`

Sectioned like pages 10–14. Six sections: the exhaustive classical bound plus the
shared-direction LHV model; the tilted-axis observable with its sign convention pinned
numerically; correlators computed exactly and sampled; the violation at the standard angles;
the product-state and Tsirelson-sweep controls; and the angle sweep rendered on
`CHSHChartView` (quantum curve, classical line, sampled points).

### 3. Docs

- `CLAUDE.md`: add the `15CHSH` bullet.
- `PlaygroundDocs/15CHSHHELP.md`: user-facing guide.
- This file records the plan.
- `README.md`: a `### 15CHSH` section, the project tree, the gate tables' "Used in" column
  (`ry` gains its first use as a *measurement* rotation rather than state prep), and a
  hand-built-gate row for A(θ).
- `STATUSandTODO.md`: an entry alongside pages 10–14.
- `PLAYGROUNDSUPPORT.md`: a `CHSHChartView` entry under "Current shared code" and a row in
  "Which pages use what".

## Explicitly not doing

- No `SwiftQiskitCore` changes — A(θ) stays a page-level hand-built `Matrix`, exactly like
  page 12's QFT† and page 14's correction permutation.
- No general N-party or higher-dimension Bell inequality (GHZ/Mermin, CGLMP) — CHSH is the
  canonical two-party, two-setting case and the natural stopping point.
- No density-matrix or POVM machinery — the "measurement" is always `ry(-θ)` then a
  computational-basis read, which is all a pure-state simulator needs for a projective
  measurement along a tilted axis.

## Verification

1. Every section's numbers were computed with `RunCodeSnippet` (xcode-tools) against
   `SwiftQiskitCore` before finalizing the page, in three batches (Sections 1–2, 3–4, 5–6)
   after the preview service showed instability on very large combined snippets — each
   batch ran clean:
   - 16/16 strategies enumerated, max \|S\| = 2;
   - shared-direction model at the standard angles: S ≈ 2.0078 (one 200,000-trial run);
   - A(θ) sign convention: exact vs. `ry(-θ)`-then-Z agree at four angles, including the
     page 04/08 cross-check (0.5000 at θ=0, 0.6124 at θ=π/2);
   - exact correlators match cos(a−b) to 4 decimals at all four setting pairs; sampled
     correlators within ~0.03 at 4000 shots;
   - exact S = 2.8284; one sampled run 2.8305–2.8360;
   - product state S = 1.4142; angle-sweep ceiling exactly 2.8284 (Tsirelson);
   - the θ-sweep table's quantum/classical columns match the hand-derived values exactly
     (agreeing at 0, π/2, π; ~0.207 apart at π/4, 3π/4).
2. `CHSHChartView.swift` type-checked against the built `SwiftQiskitCore` module with the
   command-line recipe in `PLAYGROUNDSUPPORT.md` — clean, no errors.
3. `BuildProject` — the SwiftQiskit scheme must keep building for pages to run.
4. Open `15CHSH` in Xcode and run it; on Xcode 27 betas, re-copy the `libcups` shim
   immediately before running (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds").
