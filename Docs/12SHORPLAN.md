# Shor's algorithm as a playground page

## Context

`10DeutschExample` and `11GroverExample` built the playground's algorithm arc; Shor's
algorithm is its natural finale — the polynomial-time factoring algorithm that made
quantum computing famous, and the destination `10DEUTSCHHELP.md` already promised. The page
is a **compiled** Shor: N = 15 is fixed, and it fits the v0.1 API with **no changes to
`SwiftQiskitCore`**:

- Modular multiplication U_a |w⟩ = |a·w mod 15⟩ is a basis-state *permutation* (a is
  coprime to 15), so U_a and its controlled powers are permutation matrices fed to
  `apply(_:)` — page 11's hand-built CCZ idiom, scaled up to 16×16 and 128×128. Building a
  permutation costs one `.one` assignment per column, so even the 128×128 versions are
  cheap 128-iteration loops in page code.
- The inverse QFT needs controlled phase rotations the library doesn't have — but the
  *matrix* is just the inverse DFT, `QFT†[y, c] = e^(−2πi·y·c/8)/√8`, built entrywise with
  Foundation's `cos`/`sin` and embedded across the register as `qft3Dagger ⊗
  Matrix.identity(size: 16)`. Building the matrix directly on the register's integer index
  also sidesteps the gate decomposition's bit-reversal bookkeeping entirely.

## The algorithm

Factoring reduces classically to **order finding**: for a coprime to N with even order
r = ord_N(a) and a^(r/2) ≢ −1 (mod N), the numbers gcd(a^(r/2) ± 1, N) are nontrivial
factors. The quantum part finds r by phase estimation on U_a, whose eigenvalues are
e^(2πi·s/r), s = 0 … r−1.

Register layout (qubit 0 is the most-significant bit): qubits 0–2 = 3-qubit counting
register, qubits 3–6 = 4-qubit work register; state index = count·16 + work. The circuit:

1. `h(0); h(1); h(2)` — uniform superposition of counts c.
2. `x(6)` — work register ← |1⟩ (the value 1, an equal superposition of U_a's
   eigenvectors — which is why the measured s is uniformly random).
3. Controlled-U_a powers: counting qubit k has bit weight 2^(2−k) in c, so it controls
   U_a^(2^(2−k)) — for a = 7 that is ×1 (identity, since 7⁴ ≡ 1), ×4, ×7. Afterward the
   work register holds |a^c mod 15⟩, entangled with the count.
4. QFT† on the counting register.
5. Measure the counting register: peaks at y = 8·s/r.

The compiled luxury: every order mod 15 divides 4, hence divides 2³, so with 3 counting
qubits the peaks are **exact** (no continued fractions needed — reduce y/8 to lowest terms
and verify). For a = 7 (r = 4): P(y) = ¼ exactly at y = 0, 2, 4, 6, zero elsewhere; the
post-QFT† amplitudes are magnitude ¼ with phases e^(−iπ·y·c₀/4), c₀ = dlog₇(work).
Post-processing: y = 2, 6 → r = 4 ✓; y = 4 → candidate 2, fails verification (s shared a
factor with r); y = 0 says nothing. Half of all shots succeed outright; then 7² ≡ 4 gives
gcd(3, 15) = 3 and gcd(5, 15) = 5.

## Changes

### 1. New page `Playgrounds.playground/Pages/12ShorExample.xcplaygroundpage/Contents.swift`

Console-only page in the sectioned style of pages 10–11 (banner comments, printed checks
with `// Expected:` annotations; no SwiftUI live view). Structure:

- Intro comment: factoring, the reduction to order finding, the two-register phase
  estimation circuit, the compiled-N=15 caveat.
- **Section 1** — plain-Swift `gcd`/`modPow`; the reduction; a table over a = 2…14 showing
  the six non-coprime "lucky guesses" where gcd alone factors 15.
- **Section 2** — the classical answer key: 7^k mod 15 = 1 7 4 13 … (r = 4) and the
  factors the reduction will deliver.
- **Section 3** — `modMultiplyGate(_:)` (16×16 permutation); exact unitarity via `==`
  (0/1 entries); a 4-qubit circuit walking the orbit |1⟩ → |7⟩ → |4⟩ → |13⟩ → |1⟩ — the
  orbit length *is* r. Also defines the page's `fmt`/`pretty` printing helpers (`fmt`
  rounds to 4 decimals and drops < 1e-9 components so QFT† residues print clean).
- **Section 4** — `inverseQFT(size:)` built entrywise; checks: QFT†₂ = H (~1e-16),
  unitarity (~1e-15, tolerance not `==`), QFT† of the uniform state = |000⟩.
- **Section 5** — `controlledModMultiply(controlQubit:multiplier:)` (128×128 permutation);
  the qubit-k ↔ power table (qubit 0's op is the identity — why the distribution has
  period 8/r); stage-by-stage `run()` prints (superposed counts / entangled work register /
  post-QFT† amplitudes grouped by y); the counting marginals (¼ at y = 0, 2, 4, 6),
  computed by summing probabilities — there is no partial-measurement API.
- **Section 6** — 1000 shots via a local classical sampler over `run().probabilities`,
  **not** `measure(shots:)`: that method replays every recorded operation per shot
  (~40 ms × 1000 at dimension 128 ≈ most of a minute), and sampling one run's
  distribution is statistically identical for a pure state measured in full.
- **Section 7** — post-processing table y → phase → lowest terms → verified candidate r,
  including the y = 0 and y = 4 failure modes; then r = 4 → 15 = 3 × 5.
- **Section 8** — generic `shorCircuit(a:)` / `shorOrder(a:)` / `shorFactors(a:order:)`;
  sweep a ∈ {2, 4, 7, 8, 11, 13, 14}: six factor 15, and a = 14 ≡ −1 hits the
  a^(r/2) ≡ −1 branch — trivial factors, pick another a.
- Linked with `//: [Previous](@previous)` / `//: [Next](@next)`; `11GroverExample` already
  carries its `[Next]` marker and page ordering is alphabetical, so `12…` slots in with no
  manifest edit.

### 2. Docs

- `CLAUDE.md`: add the `12ShorExample` bullet to the playground page list.
- `Docs/12SHORHELP.md`: user-facing guide (companion to `11GROVERHELP.md`).
- This file (`Docs/12SHORPLAN.md`) records the plan.
- `README.md`: extend the gate tables (Hadamard/Pauli-X "Used in" now 08–12; new
  hand-built rows for U_a and QFT†), the project tree, and a `### 12ShorExample` section.

## Explicitly not doing

- No new gates or Core changes — no QFT, controlled-phase, or swap gates (they stay on the
  `STATUSandTODO.md` roadmap); everything uses `h/x`, `apply(_:)`, `run()`, `⊗`, and
  postfix `†`.
- No partial measurement API — counting-register statistics are marginals summed in page
  code.
- No continued-fraction engine — lowest-terms reduction suffices because every order
  divides 8 here; a general-N Shor would need it (and ~2n counting qubits).
- No `measure(shots:)` on the 7-qubit circuit (per-shot replay cost; see Section 6 above).
- No general N — the modular arithmetic is compiled for N = 15.
- No SwiftUI live view.

## Verification

1. Playground pages compile only inside Xcode, so the logic was validated first with
   `RunCodeSnippet` (xcode-tools) against `SwiftQiskitCore`: U₇ exactly unitary with orbit
   1 → 7 → 4 → 13 → 1; QFT† unitary to ~7e-16 with QFT†₂ = H; the a = 7 circuit's counting
   marginals exactly {0, 2, 4, 6: ¼ each} with the predicted stage-2/3 amplitudes; the
   Section 8 sweep table including a = 14's trivial factors; one `run()` timed at ~40 ms,
   confirming the `measure(shots:)` cost analysis.
2. `BuildProject` — the SwiftQiskit scheme must keep building for pages to run.
3. Open `12ShorExample` in Xcode and run it; the printed output is annotated inline with
   `// Expected:` comments (Section 6's histogram is statistical, ±~40 per bin; everything
   else is exact up to the 4-decimal formatter).
