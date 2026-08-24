# The QFT gate decomposition — help & usage guide

User-facing guide to the `16QFT` playground page. The implementation plan is in
`16QFTPLAN.md`.

## What the page shows

Page 12 used the quantum Fourier transform for phase estimation but built it as a single
matrix, entrywise — a shortcut that works but skips the actual *circuit*. This page builds
that circuit: a controlled-phase gate CP(θ) made from gates the library already has, a ladder
of Hadamards and CP's that *is* the QFT, a swap network to fix the output order, and the
inverse QFT run backward through phase estimation on a made-up phase.

## Section by section

**Section 1 — the missing gate.** CP(θ) = P(θ/2) on the control, `cx`, P(−θ/2) on the target,
`cx`, P(θ/2) on the target — five calls to `p`/`cx`, checked against the diagonal
`diag(1,1,1,e^{iθ})` it should produce. At θ = π this is exactly CZ, the same gate pages 11
and 15 built by hand for other reasons.

**Section 2 — the QFT circuit.** For each qubit j (0 = most-significant): a Hadamard, then
CP(2π/2^(k−j+1)) controlled by every later qubit k. Checked against page 12's entrywise
formula on all 8 basis states of a 3-qubit register — they agree to ~1e-15.

**Section 3 — why the swaps.** Run the same ladder *without* the final swap network and the
amplitudes land at the bit-reversal of where they belong — proof the swaps are correcting a
real effect of the H/CP ladder's qubit ordering, not decoration.

**Section 4 — the inverse QFT.** Same gates, reversed order, negated angles. QFT then QFT†
returns every basis state to itself (unitarity, checked numerically).

**Section 5 — phase estimation.** The reason any of this matters: encode an unknown phase φ in
a controlled P(2πφ)^(2^k) ladder, apply QFT†, read the counting register. Dyadic phases (exact
multiples of 1/8 with 3 counting qubits) come back with certainty; φ = 0.3 spreads its
probability over its two nearest neighbors.

**Section 6 — precision.** The same non-dyadic φ = 0.3, resolved more tightly with more
counting qubits — smaller error, more concentrated probability.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`16QFT`** (or follow `[Next]` from
   `15CHSH`).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. Console only — no live view, no Xcode 27 beta shim needed.
4. Run the page. Output is annotated inline with `// Expected:` comments.

## Expected output

```text
CP(θ) vs. the diagonal it should produce:
  input 00: amplitude at that index = 1.0  (want  1)
  input 01: amplitude at that index = 1.0  (want  1)
  input 10: amplitude at that index = 1.0  (want  1)
  input 11: amplitude at that index = -1.0 + ...i  (want -1)

gate-level QFT vs. entrywise formula: max amplitude deviation = ~1.4e-15

no-swap amplitude at y equals swapped amplitude at bit-reverse(y): max deviation = 0.0

QFT then QFT†, every basis state: max |amplitude at c| deviation from 1 = ~6.7e-16

phase       best estimate   P(that estimate)
0.1250       0.1250          1.0000
0.5000       0.5000          1.0000
0.7500       0.7500          1.0000

φ = 0.3 (not a multiple of 1/8), 3 counting qubits:
  y=0 (estimate 0.0000): P = 0.0216
  y=1 (estimate 0.1250): P = 0.0518
  y=2 (estimate 0.2500): P = 0.5775
  y=3 (estimate 0.3750): P = 0.2593
  y=4 (estimate 0.5000): P = 0.0409
  y=5 (estimate 0.6250): P = 0.0194
  y=6 (estimate 0.7500): P = 0.0145
  y=7 (estimate 0.8750): P = 0.0149

counting qubits   best estimate   error     P
3                 0.2500          0.0500    0.5775
6                 0.2969          0.0031    0.8752
```

## Using it in your own code

```swift
import SwiftQiskitCore

func cp(_ qc: QuantumCircuit, _ theta: Double, _ control: Int, _ target: Int) {
    qc.p(theta / 2, control)
    qc.cx(control, target)
    qc.p(-theta / 2, target)
    qc.cx(control, target)
    qc.p(theta / 2, target)
}

func swapQubits(_ qc: QuantumCircuit, _ a: Int, _ b: Int) {
    qc.cx(a, b); qc.cx(b, a); qc.cx(a, b)
}

/// Appends the QFT ladder to `qc`'s first `n` qubits.
func appendQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for j in 0..<n {
        qc.h(j)
        for k in (j + 1)..<n {
            cp(qc, 2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j)
        }
    }
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
}
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first.
- **CP(θ) deviation looks larger than ~1e-15** — check the five-gate order; `p(theta/2,
  control)` comes first, and the two `cx` calls must use the same (control, target) pair both
  times.
- **Phase estimation gives a completely wrong peak** — check the eigenstate qubit is prepared
  with `x(n)` *before* the Hadamards on the counting register, and that the controlled powers
  use `2^(n-1-j)` (qubit 0 controls the *highest* power, since it's the most-significant bit).
