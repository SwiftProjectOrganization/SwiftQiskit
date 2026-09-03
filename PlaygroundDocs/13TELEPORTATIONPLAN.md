# Quantum teleportation and superdense coding as a playground page

## Context

Pages `10DeutschExample`, `11GroverExample` and `12ShorExample` are all *oracle/query*
algorithms: one register, a black box, interference, a verdict. Teleportation is the first
page to use entanglement as a **communication resource** — the protocol that gives the
Bell pair an operational meaning — and its dual, superdense coding, closes the loop on the
same resource. It fits the v0.1 API with **no changes to `SwiftQiskitCore`**:

- The correction step normally reads "measure q0, q1, then apply a *classically
  conditioned* X/Z to q2". `StateVector.measure()` collapses the whole register
  (`Quantum/StateVector.swift:67`) and there is no mid-circuit or partial measurement, so
  the page uses the **deferred-measurement principle**: a classically controlled X becomes
  `cx(1, 2)`, a classically controlled Z becomes CZ(0, 2) — built as `h(2); cx(0,2); h(2)`,
  page 11's CZ idiom. Both need `cx` between non-adjacent qubits, which v0.1's general
  `CNOTGate.matrix(qubits:control:target:)` provides.
- The individual measurement *branches* are recovered without measuring, using the Dirac
  layer: `(Ket("ab") * Bra("ab")) ⊗ Matrix.identity(size: 2)` is the projector
  (\|ab⟩⟨ab\|) ⊗ I₂, via the mixed `⊗` overload in `Quantum/Dirac.swift:199`. Applying it
  with `StateVector.apply(_:)` renormalizes automatically, so the branch comes out as a
  proper state.

## The protocol

Register (qubit 0 is the most-significant bit): q0 = Alice's payload \|ψ⟩, q1 = Alice's half
of a Bell pair, q2 = Bob's half.

1. Prepare \|ψ⟩ = cos(θ/2)\|0⟩ + e^{iφ}sin(θ/2)\|1⟩ with `ry(θ, 0); rz(φ, 0)`, θ = 60°,
   φ = 45° — the same qubit as pages 04 and 08. `rz` contributes an overall e^{−iφ/2}
   relative to those pages' convention; a global phase, and the page checks the Bloch point
   comes out at page 08's (0.6124, 0.6124, 0.5000) anyway.
2. Bell pair on q1, q2: `h(1); cx(1, 2)`.
3. Alice's Bell-basis rotation: `cx(0, 1); h(0)`. The state becomes
   ½ Σ_{a,b} \|ab⟩ ⊗ (X^b Z^a\|ψ⟩) — all four of Bob's possible states at once, tagged by
   the prefix.
4. Corrections, deferred: `cx(1, 2)` then CZ(0, 2).

The payoff check: after step 4 the register **factors** as \|+⟩ ⊗ \|+⟩ ⊗ \|ψ⟩ (verified to
~8e-17). q2 is exactly \|ψ⟩ and q0's marginal is a fair coin — the payload *moved*, which is
the no-cloning theorem showing up as an equality rather than a prohibition.

Superdense coding runs the resource the other way: the same Bell pair, the same four
unitaries {I, X, Z, ZX} applied to Alice's qubit alone, and `cx(0,1); h(0)` decodes two
classical bits from one transmitted qubit with P = 1.

## Changes

### 1. New page `Playgrounds.playground/Pages/13Teleportation.xcplaygroundpage/Contents.swift`

Sectioned in the style of pages 10–12 (banner comments, printed checks with `// Expected:`
annotations), plus a SwiftUI live view. Structure:

- Intro comment: the setup, the register layout, and why deferred measurement stands in for
  the classical channel.
- **Section 1** — \|ψ⟩ and the Bell pair; the page's `pretty(_:qubits:)` formatter; the Bloch
  point cross-checked against page 08.
- **Section 2** — Alice's `cx(0,1); h(0)`, printing all eight amplitudes.
- **Section 3** — the four branches via Dirac projectors: P(ab) = ¼ each (no-signalling),
  and fidelity 1.0000 once each branch gets *its* X^b Z^a.
- **Section 4** — the deferred-measurement corrections; the factoring check against
  `(Ket.plus ⊗ Ket.plus) ⊗ psi`.
- **Section 5** — no cloning: q2's marginal equals \|ψ\|², q0's is [0.5, 0.5]; 1000 shots
  from a freshly built circuit (`measure(shots:)` replays operations per shot).
- **Section 6** — superdense coding: the four messages decoded at P = 1.0000, plus the Bell
  basis's Gram matrix printed as the identity — the orthogonality that makes decoding
  deterministic.
- **Live view** — `TeleportationGalleryView`, an inline stateless view over the existing
  shared `BlochSphereView`/`BlochVector`: \|ψ⟩, the four uncorrected branches X^b Z^a\|ψ⟩,
  and Bob's corrected state. Every ket shown is genuinely 2-dimensional, so no new shared
  code was needed.
- Linked with `//: [Previous](@previous)` / `//: [Next](@next)`; page 12 already carries its
  `[Next]` marker and page order is alphabetical, so `13…` slots in with no manifest edit.

### 2. Docs

- `CLAUDE.md`: add the `13Teleportation` bullet to the playground page list.
- `PlaygroundDocs/13TELEPORTATIONHELP.md`: user-facing guide (companion to `12SHORHELP.md`).
- This file records the plan.
- `README.md`: a `### 13Teleportation` section, the project tree, and the gate tables'
  "Used in" column (`ry`/`rz` gain their first non-page-05 user; `cx` extends to 13).
- `STATUSandTODO.md`: an entry under the algorithm-pages section.
- `PLAYGROUNDSUPPORT.md`: a row in "Which pages use what".

## Explicitly not doing

- No `SwiftQiskitCore` changes — no mid-circuit measurement, no classically conditioned
  gates, no CZ/Toffoli in Core (all stay on the `STATUSandTODO.md` roadmap).
- No entanglement-swapping or repeater extension, no teleportation of a *half* of an
  entangled pair (both would need the same deferred-measurement machinery at 4+ qubits and
  add no new API lesson).
- No new shared `Sources/` code — the live view reuses `BlochSphereView`.

## Verification

1. Logic validated with `RunCodeSnippet` (xcode-tools) against `SwiftQiskitCore` before the
   page was written, and the page's console section re-run afterward to confirm every
   `// Expected:` annotation:
   - all four branch probabilities 0.2500 and fidelities 1.0000 after X^b Z^a;
   - the final state matching \|+⟩⊗\|+⟩⊗\|ψ⟩ to 8.3e-17;
   - q2 marginal [0.7500, 0.2500] vs q0 marginal [0.5000, 0.5000];
   - superdense decoding P = 1.0000 for all four messages, Gram matrix = identity;
   - Bloch points: \|ψ⟩ and the ab = 00 branch at (0.6124, 0.6124, 0.5000), the other three
     branches at the sign-flipped variants.
2. `BuildProject` — the SwiftQiskit scheme must keep building for pages to run.
3. Open `13Teleportation` in Xcode and run it. This page uses SwiftUI, so on Xcode 27 betas
   re-copy the `libcups` shim immediately before the run (`PLAYGROUNDSUPPORT.md`
   § "Xcode 27 beta workarounds"); the live view is stateless and declared inline, which is
   the case that specifically needs the shim.
