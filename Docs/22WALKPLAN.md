# The discrete-time quantum walk as a playground page

## Context

No page shows interference producing a *distribution* rather than answering an oracle question
(Deutsch/DJ/BV) or amplifying a marked item (Grover). This page closes that gap with
**no `SwiftQiskitCore` changes**:

- The conditional shift is a hand-built permutation matrix applied via `apply(_:)` — the same
  idiom as page 12's modular-multiplication permutations and page 14's 32×32 correction
  matrix.
- The coin flip is exactly `h(0)`; the symmetric-coin variant reuses Core's existing
  `StateVector.plusI` basis ket with no new code.
- The classical comparison is plain Swift (a stochastic-matrix update), not Core — the point
  is the contrast between the two, computed side by side.

## The math, and what the plan verified

All figures were computed by compiling `SwiftQiskitCore` standalone with `swiftc` and running
the page's exact math in a driver executable.

- **Register size, corrected from the original sketch.** A coin qubit (q0) plus a position
  register of **16 sites (4 qubits, total dimension 32)** — not 8 sites: on a cycle, a
  nearest-neighbor walk starting at site 0 can reach sites −t..+t after t steps, so avoiding
  wraparound self-overlap through t=7 needs 2·7+1 = 15 distinct sites; 8 sites would alias by
  t≈4, while 16 keeps t=7 clean (2·7+1 = 15 ≤ 16). Dimension 32 also keeps `measure(shots:)`
  fast — well under the dimension-128 slowness page 12 flags.
- **The shift is a genuine permutation.** S†S = I checked entrywise: max deviation **0.0**.
- **A cyclic-coordinate bug caught and fixed during verification, worth keeping as a
  page note.** Computing position standard deviation from raw site *indices* (0..15) is wrong
  once the distribution's support straddles the 0/15 wraparound boundary — index 15 is
  actually adjacent to index 0, but naive variance treats them as far apart, producing
  nonsensical non-monotonic "spread" numbers. The fix: unwrap each index to a signed offset
  from the start site before computing variance (valid as long as the spread stays under half
  the cycle, true through t=7 here). **This is a natural gotcha for anyone implementing a
  cyclic random walk and is worth one sentence in the page.**
- **Ballistic vs. diffusive spreading, confirmed with the corrected metric.** Quantum walk
  (Hadamard coin, starting `|0⟩`), stddev at t=1..7: 1.0, 1.414, 1.658, 2.0, 2.595, 3.112,
  3.450 — growing roughly linearly in t (ratio σ/t: 1.0, 0.71, 0.55, 0.50, 0.52, 0.52, 0.49;
  the oscillation at small t is a known finite-size/parity effect in coined quantum walks, not
  an error). Classical walk (symmetric ½/½ coin flip), same steps: stddev 1.0, 1.414, 1.732,
  2.0, 2.236, 2.449, 2.646 — **σ/√t is pinned at exactly 1.0 at every single t**, the textbook
  diffusive signature. The qualitative contrast (σ/t roughly constant vs. σ/√t exactly
  constant) is the page's headline, not a claim about the specific asymptotic constant.
- **The asymmetry is interference, not a bug.** The position distribution at t=7 starting from
  coin `|0⟩` is visibly asymmetric (e.g. site 3: 0.3203 vs. its mirror site 13: 0.0391 — a
  ratio of ~8×). Starting from coin `|+i⟩` instead, the same 7 steps give a distribution that
  is symmetric to 4 decimal places at every mirrored pair (site 1 ↔ 15: 0.1016/0.1016; site 3
  ↔ 13: 0.1797/0.1797; site 5 ↔ 11: 0.2109/0.2109; site 7 ↔ 9: 0.0078/0.0078) — confirming the
  bias comes from the coin's phase relationship to the shift, not from any asymmetry in the
  shift operator itself.

## Changes

### New page `Playgrounds.playground/Pages/22Walk.xcplaygroundpage/Contents.swift`

Console plus one live chart, five sections: the shift as a permutation matrix (with the
S†S = I check); one step as `S · (H⊗I₁₆)` and the position marginal; the quantum-vs-classical
spread comparison (with the cyclic-coordinate gotcha called out); the `|0⟩`-vs-`|+i⟩` coin
symmetry contrast; cross-references to Grover (page 11, a search algorithm expressible as a
walk) and Trotter (page 21 — the continuous-time walk is `expm` applied to a graph's adjacency
matrix).

The live chart reuses `CHSHChartView` unchanged, plotting the quantum and classical position
distributions at t=7 as two series — no new shared view.

### Docs

- `CLAUDE.md`: add the `22Walk` bullet.
- `Docs/22WALKHELP.md`: user-facing guide (deferred with the page).
- This file records the plan.
- `README.md`: a `### 22Walk` section.
- `STATUSandTODO.md`: an entry alongside pages 19–21, closing out this batch of four.
- `PLAYGROUNDSUPPORT.md`: a `22Walk` row in "Which pages use what."
- `00TOC.xcplaygroundpage`: a bullet plus the guide-list update.
- Page 21 gets `[Next]`; page 22 gets `[Previous]` only (last page, unless more are added
  later).

## Explicitly not doing

- **No walk-based search or hitting-time analysis** — that is Grover's page (11); this page
  cross-references it rather than re-deriving search from the walk.
- **No continuous-time walk implementation** — a one-line cross-reference to page 21's `expm`
  applied to the cycle's adjacency matrix, not a second implementation.
- **No walk on a general graph** — the cycle keeps the shift a single, easily-verified
  permutation; a general graph would need a different shift construction per topology, adding
  complexity without a new conceptual payoff for this page.

## Verification

1. Every number above was computed by compiling `SwiftQiskitCore`'s sources standalone with
   `swiftc` (bypassing an `ENABLE_DEBUG_DYLIB` requirement on `RunCodeSnippet` for
   executable-target previews) and running the page's exact math in a driver executable. The
   cyclic-coordinate stddev bug was caught by this process — the first run produced
   non-monotonic, clearly-wrong spread numbers, which is what prompted the fix recorded above.
2. `mcp__xcode-tools__BuildProject` — confirmed green on the `SwiftQiskit` scheme.
3. `swift test` / `RunAllTests` under `SwiftQiskit-Package` — no Core changes proposed; not
   re-run for this plan since only Docs were written.
4. When the page is built: open `22Walk` in Xcode and run it (console + chart only); re-copy
   the `libcups` shim immediately before running
   (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds").
