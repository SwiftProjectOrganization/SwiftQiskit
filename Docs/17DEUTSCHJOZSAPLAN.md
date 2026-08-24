# Deutsch–Jozsa and Bernstein–Vazirani as a playground page

## Context

Page 10 (`10DeutschExample`) proves the one-query advantage on a single input bit. The natural
sequel scales the same circuit to n bits, where the payoff sharpens: Deutsch–Jozsa's classical
worst case grows exponentially in n while the quantum query count stays at exactly 1, and
Bernstein–Vazirani turns "one query" into "recover an entire n-bit secret." Neither needs
anything page 10 doesn't already have — same circuit shape, `cx`-built oracles, one extra
register width parameter. **No `SwiftQiskitCore` changes.**

## The math, and what the plan verified

On 3 input qubits + 1 ancilla (`n = 3`, `total = 4`):

- Both constant oracles (do nothing; flip the ancilla unconditionally) give
  P(all-zero input) = 1.0000.
- Both balanced oracles (`cx(0, ancilla)`; full parity `cx(q, ancilla)` for every input qubit)
  give P(all-zero input) = 0.0000.
- Sampling the balanced-on-x₀ oracle for 200 shots returns exactly two outcome strings — 1000
  and 1001 in one run (97/103 split) — confirming the ancilla's bit is a free coin flip
  (it ends in |−⟩) while the input bits are always "100."
- Bernstein–Vazirani with hidden strings s = 101, 110, 111, 000 (oracle: `cx(q, ancilla)` for
  every set bit of s) recovers s exactly in every case, P = 1.0000.

The classical query counts in Section 6's table are the textbook results, not simulated (there
is no classical oracle model in this library to query) — Deutsch–Jozsa's worst case is
2^(n−1)+1 (a classical algorithm can see the same output 2^(n−1) times from a balanced function
before the next query is forced to reveal it), Bernstein–Vazirani's is exactly n (one query per
bit, no way to do better classically).

## Changes

### New page `Playgrounds.playground/Pages/17DeutschJozsa.xcplaygroundpage/Contents.swift`

Console only, six sections: the n-qubit circuit generalized from page 10; the four oracle
shapes; the deterministic verdict; the shot-sampling gotcha (ancilla bit is random, input bits
aren't); Bernstein–Vazirani reusing the identical circuit; a query-count comparison table.

### Docs

- `CLAUDE.md`: add the `17DeutschJozsa` bullet (naming both algorithms).
- `Docs/17DEUTSCHJOZSAHELP.md`: user-facing guide.
- This file records the plan.
- `README.md`: a `### 17DeutschJozsa` section and project tree update.
- `STATUSandTODO.md`: an entry alongside pages 10–16.
- `00TOC.xcplaygroundpage`: a bullet plus the guide-list update.
- Page 16 gets `[Next]`; page 17 gets `[Previous]`/`[Next]`.

## Explicitly not doing

- No classical oracle-query simulator to *measure* the classical worst case empirically —
  Section 6's numbers are the standard closed-form results, stated and cited, not derived from
  a simulation (there's nothing to simulate: a classical decision tree over a black box isn't
  something `SwiftQiskitCore` models).
- No n > 3 by default — 3 input qubits (16 total states) keeps every printed distribution
  legible; the query-count table separately covers n up to 5 to show the scaling without
  printing giant amplitude tables.

## Verification

1. Every printed number was computed with `RunCodeSnippet` against `SwiftQiskitCore`, running
   the exact final page code (not a paraphrase).
2. `BuildProject` — the SwiftQiskit scheme must keep building for pages to run.
3. `swift test` / `RunAllTests` under `SwiftQiskit-Package` — no Core changes, no regression
   expected.
4. Open `17DeutschJozsa` in Xcode and run it (console only).
