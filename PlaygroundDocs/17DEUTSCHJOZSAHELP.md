# Deutsch–Jozsa and Bernstein–Vazirani — help & usage guide

User-facing guide to the `17DeutschJozsa` playground page. The implementation plan is in
`17DEUTSCHJOZSAPLAN.md`.

## What the page shows

Page 10 answered "is this 1-bit function constant or balanced?" in a single query. This page
asks the same question of an n-bit function (Deutsch–Jozsa), where a classical computer needs
up to 2^(n−1)+1 queries in the worst case — and then reuses the identical circuit to recover an
entire hidden n-bit string in one query (Bernstein–Vazirani), where a classical computer needs
exactly n queries, one bit at a time.

## Section by section

**Section 1 — the circuit.** Page 10's circuit, widened: n input qubits, one ancilla,
Hadamards on everything, one oracle query, Hadamards on the inputs only.

**Section 2 — oracles from `cx`.** Constant-0 (do nothing), constant-1 (`x` the ancilla
unconditionally), balanced-on-x₀ (`cx(0, ancilla)`), full parity (`cx` from every input qubit).

**Section 3 — the verdict.** P(all-zero input register) is exactly 1 for constant oracles and
exactly 0 for balanced ones — no statistics needed, from a single query.

**Section 4 — a gotcha.** `measure(shots:)` reports the ancilla too, and the ancilla ends in
|−⟩ — an equal superposition — so its bit is a fair coin. 200 shots of the balanced-on-x₀
oracle come back as two outcome strings sharing the same input prefix but differing in the
last (ancilla) character. Slice it off before reading the verdict from shot data.

**Section 5 — Bernstein–Vazirani.** The same circuit with oracle f(x) = s·x mod 2 for hidden
string s (`cx(q, ancilla)` for every set bit of s). The input register reads back s itself,
exactly, every time.

**Section 6 — the gap.** A table: quantum queries stay at 1 for every n; classical
Deutsch–Jozsa's worst case doubles roughly every bit (3, 5, 9, 17 for n = 2..5); classical
Bernstein–Vazirani grows by exactly 1 query per bit.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`17DeutschJozsa`** (or follow `[Next]`
   from `16QFT`).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. Console only — no live view, no Xcode 27 beta shim needed.
4. Run the page. Output is annotated inline with `// Expected:` comments; the 200-shot section
   is statistical (a fresh run may split e.g. 95/105 instead of 97/103).

## Expected output

```text
oracle             P(|000⟩)  verdict    expected
constant 0        1.0000    constant   constant ✓
constant 1        1.0000    constant   constant ✓
balanced on x0    0.0000    balanced   balanced ✓
balanced parity   0.0000    balanced   balanced ✓

balanced-on-x0, 200 shots, raw outcome strings:
  1000: ~100
  1001: ~100

hidden s   recovered   P
101        101         1.0000
110        110         1.0000
111        111         1.0000
000        000         1.0000

n    quantum queries   classical DJ (worst case)   classical BV
2    1                 3                          2
3    1                 5                          3
4    1                 9                          4
5    1                 17                          5
```

## Using it in your own code

```swift
import SwiftQiskitCore

let n = 3, ancilla = n, total = n + 1

func djCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: total)
    qc.x(ancilla)
    for q in 0...ancilla { qc.h(q) }
    oracle(qc)
    for q in 0..<n { qc.h(q) }
    return qc
}

// Bernstein–Vazirani: recover hidden string s in one query.
func bvOracle(_ s: Int) -> (QuantumCircuit) -> Void {
    { qc in
        for q in 0..<n where (s >> (n - 1 - q)) & 1 == 1 {
            qc.cx(q, ancilla)
        }
    }
}
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first.
- **Verdict looks flipped** — check the final Hadamard layer only touches the *input* qubits
  (`0..<n`), not the ancilla; re-Hadamarding the ancilla undoes its |−⟩ phase-kickback state.
- **Shot counts don't split ~50/50 on the ancilla bit** — that's expected variance at 200
  shots; increase the shot count for a tighter split, or check the verdict off `probabilities`
  instead (Section 3), which is exact.
