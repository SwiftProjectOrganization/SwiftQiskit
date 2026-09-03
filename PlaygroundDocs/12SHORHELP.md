# Shor's algorithm — help & usage guide

User-facing guide to the `12ShorExample` playground page. The implementation plan is in
`12SHORPLAN.md`.

## What the algorithm does

Given a composite N, find a nontrivial factor. Every known classical algorithm takes
super-polynomial time — the presumed hardness of factoring is what RSA encryption rests
on. Shor's algorithm (Peter Shor, 1994) factors in **polynomial time** on a quantum
computer, the result that made quantum computing famous.

The quantum part solves *order finding*: pick a base a coprime to N and find the smallest
r > 0 with

```text
a^r ≡ 1 (mod N)
```

That is enough, classically: if r is even and a^(r/2) ≢ −1 (mod N), then
gcd(a^(r/2) ± 1, N) are nontrivial factors (and if the guess a wasn't coprime at all,
gcd(a, N) already is one). The order is found by phase estimation on the modular
multiplication operator U_a |w⟩ = |a·w mod N⟩, whose eigenvalues e^(2πi·s/r) encode r.

The page runs the **compiled** N = 15 instance — the smallest number Shor can factor, and
the one first demonstrated on real hardware (IBM, 2001). Every order mod 15 divides 4,
hence divides 2³, so 3 counting qubits give perfectly sharp peaks and reducing the
measured y/8 to lowest terms replaces the continued-fraction step a general N needs.

## The circuit

Two registers, 7 qubits total (qubit 0 is the most-significant bit):

```text
counting q0–q2: |0⟩ ─ H ──●───────────────┐
                |0⟩ ─ H ──┼──●────────────┤ QFT† ── measure y ≈ 8·s/r
                |0⟩ ─ H ──┼──┼──●─────────┘
                          │  │  │
work     q3–q6: |0001⟩ ── U⁴ U² U¹ ──────── (never read)
                          (Uᵖ = multiply by a^p mod 15)
```

| Step | Code | Effect |
|---|---|---|
| 1 | `h(0); h(1); h(2)` | uniform superposition of counts c = 0…7 |
| 2 | `x(6)` | work register ← \|1⟩ (the value 1) |
| 3 | controlled-U_a powers via `apply(_:)` | work register ← \|a^c mod 15⟩, entangled with c |
| 4 | `apply(qft3Dagger ⊗ I₁₆)` | interfere the period into phase peaks |
| 5 | measure qubits 0–2 | y = 8·s/r for a uniformly random s ∈ {0, …, r−1} |

**Why it works — period to phase.** After step 3 the work register cycles through the
orbit 1, a, a², … with period r as c counts up. The QFT† converts that periodicity into
sharp peaks at the multiples of 8/r: for a = 7 (r = 4) the counting register lands on
y ∈ {0, 2, 4, 6} with probability ¼ each. Reducing y/8 to lowest terms s/r and verifying
a^r ≡ 1 recovers the order — here half of all shots succeed outright (y = 0 says nothing,
and y = 4 reduces to ½, whose denominator 2 fails verification because s shared a factor
with r).

## Building the operators from v0.1 gates

Nothing beyond `h`/`x` is native, but both missing pieces are single matrices for
`apply(_:)` — page 11's CCZ trick, scaled up:

| Operator | Construction |
|---|---|
| U_a (work register) | 16×16 permutation: `m[(a·w) % 15, w] = .one` for w < 15, \|15⟩ fixed |
| controlled-U_a^p | 128×128 permutation: permute the work bits only where counting bit k of the index is 1 |
| QFT† (counting register) | 8×8 inverse DFT built entrywise: `e^(−2πi·y·c/8)/√8` via `cos`/`sin`, embedded as `qft3Dagger ⊗ Matrix.identity(size: 16)` |

Two conventions to keep straight (both explained in the page):

- Qubit 0 is the **most-significant** bit, so counting qubit k has bit weight 2^(2−k) and
  must control U_a^(2^(2−k)) — for a = 7: qubit 0 → ×1 (the identity, since 7⁴ ≡ 1),
  qubit 1 → ×4, qubit 2 → ×7.
- Building the QFT† **matrix** directly on the register's integer index sidesteps the bit
  reversal that the textbook gate decomposition needs.

A permutation matrix needs only one `.one` per column, so even the 128×128 constructions
are cheap 128-iteration loops in page code.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`12ShorExample`** page
   (or follow the `[Next]` link from `11GroverExample`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. Output is annotated inline with `// Expected:` comments.

## Expected output

The orbit of U₇ closes after exactly r = 4 steps (Section 3):

```text
start:  |0001⟩: 1.0
U₇^1:   |0111⟩: 1.0
U₇^2:   |0100⟩: 1.0
U₇^3:   |1101⟩: 1.0
U₇^4:   |0001⟩: 1.0
```

Stage by stage for a = 7 (Section 5) — superposed counts, then the entangled orbit, then
the QFT† peaks:

```text
stage 1:  eight states |ccc 0001⟩ at 0.3536 = 1/√8
stage 2:  |0000001⟩ |0010111⟩ |0100100⟩ |0111101⟩ … — work cycles 1, 7, 4, 13
stage 3:  y = 0:  work 1: 0.25    work 4: 0.25    work 7: 0.25     work 13: 0.25
          y = 2:  work 1: 0.25    work 4: -0.25   work 7: -0.25i   work 13: 0.25i
          y = 4:  work 1: 0.25    work 4: 0.25    work 7: -0.25    work 13: -0.25
          y = 6:  work 1: 0.25    work 4: -0.25   work 7: 0.25i    work 13: -0.25i

y    P(y)      →  exactly 0.2500 at y = 0, 2, 4, 6 and 0.0000 at odd y
```

1000 shots of the counting register (statistical, ±~40 per bin):

```text
000: ~250    010: ~250    100: ~250    110: ~250
```

Post-processing (Section 7) — verify each candidate, then apply the reduction:

```text
y   phase   lowest terms   candidate r   7^r mod 15   verdict
0   0/8     0/1            1             7            ✗ retry
2   2/8     1/4            4             1            ✓ order found
4   4/8     1/2            2             4            ✗ retry
6   6/8     3/4            4             1            ✓ order found

r = 4:  7^(r/2) ≡ 4,  gcd(3, 15) = 3,  gcd(5, 15) = 5
15 = 3 × 5  ✓
```

The Section 8 sweep shows every coprime base at once — including the one unlucky guess:

```text
 a    r    a^(r/2)   result
 2    4     4        15 = 3 × 5
 4    2     4        15 = 3 × 5
 7    4     4        15 = 3 × 5
 8    4     4        15 = 3 × 5
11    2    11        15 = 5 × 3
13    4     4        15 = 3 × 5
14    2    14        ✗ a^(r/2) ≡ −1 — trivial factors, pick another a
```

## Using the algorithm in your own code

The whole order-finder is plain `SwiftQiskitCore` calls plus two hand-built matrices:

```swift
import Foundation
import SwiftQiskitCore

func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
func modPow(_ b: Int, _ e: Int, _ m: Int) -> Int {
    var r = 1, s = b % m, e = e
    while e > 0 { if e & 1 == 1 { r = r * s % m }; s = s * s % m; e >>= 1 }
    return r
}

/// Controlled ×multiplier (mod 15) on qubits 3–6, keyed on counting qubit k.
func controlledModMultiply(controlQubit: Int, multiplier: Int) -> Matrix {
    var m = Matrix(rows: 128, cols: 128)
    for index in 0..<128 {
        let count = index >> 4, work = index & 15
        let hit = (count >> (2 - controlQubit)) & 1 == 1 && work < 15
        m[(count << 4) | (hit ? (multiplier * work) % 15 : work), index] = .one
    }
    return m
}

var qftDagger = Matrix(rows: 8, cols: 8)
for y in 0..<8 {
    for c in 0..<8 {
        let theta = -2.0 * Double.pi * Double(y * c) / 8.0
        qftDagger[y, c] = Complex(cos(theta), sin(theta)) * (1.0 / sqrt(8.0))
    }
}

let a = 7
let qc = QuantumCircuit(qubits: 7)
for q in 0..<3 { qc.h(q) }
qc.x(6)
for k in 0..<3 {
    qc.apply(controlledModMultiply(controlQubit: k, multiplier: modPow(a, 1 << (2 - k), 15)))
}
qc.apply(qftDagger ⊗ Matrix.identity(size: 16))

let y = qc.runAndMeasure() >> 4        // counting register = top 3 bits
let r = 8 / gcd(y == 0 ? 8 : y, 8)     // candidate order — verify, retry on failure
if modPow(a, r, 15) == 1 && r % 2 == 0 {
    let h = modPow(a, r / 2, 15)
    print("15 = \(gcd(h - 1, 15)) × \(gcd(h + 1, 15))")   // 15 = 3 × 5
}
```

For repeated sampling, prefer one `run()` and sample its `probabilities` — see the
Troubleshooting note below.

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first; check for
  compile errors in `Sources/SwiftQiskitCore/`. On Xcode 27 betas see also
  `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (this page is console-only, so the
  SwiftUI-specific bugs there should not affect it).
- **`apply` precondition failure** — `apply(_:)` demands a full 2ⁿ×2ⁿ matrix. An operator
  on a sub-register must be embedded by hand: high-order factor on the left, e.g.
  `qftDagger ⊗ Matrix.identity(size: 16)` for the counting register.
- **Peaks in the wrong places** — check the qubit-k ↔ power mapping: qubit 0 is the MSB,
  so counting qubit k controls U_a^(2^(2−k)), *not* U_a^(2^k). Getting it backwards
  scrambles the phase estimate.
- **`measure(shots:)` takes forever** — it replays every recorded operation for every
  shot; at dimension 128 that is ~40 ms × shots. Call `run()` once and sample its
  `probabilities` instead (statistically identical for a full measurement of a pure
  state), as the page's Section 6 does.
