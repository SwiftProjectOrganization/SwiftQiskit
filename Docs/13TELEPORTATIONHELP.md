# Quantum teleportation & superdense coding — help & usage guide

User-facing guide to the `13Teleportation` playground page. The implementation plan is in
`13TELEPORTATIONPLAN.md`.

## What the protocol does

Alice holds a qubit in an unknown state \|ψ⟩ and wants Bob to have it. They have no quantum
channel — only a **Bell pair** shared in advance and an ordinary **classical** channel.
Teleportation (Bennett et al., 1993) does it with two classical bits.

Three things it is *not*:

- **Not faster than light.** Bob's qubit is useless until Alice's two bits arrive; before
  that his outcome statistics are the same no matter what \|ψ⟩ was (the page prints
  P(ab) = ¼ for all four branches to make this concrete).
- **Not cloning.** Alice's qubit ends in \|+⟩, carrying nothing of \|ψ⟩. The state *moved*.
- **Not a way to transmit an unknown state's description.** Neither party ever learns α, β.

## The register and the circuit

Qubit 0 is the most-significant/leftmost bit of state labels and measurement strings.

```text
q0: |ψ⟩ ──────────────■── H ─────────■─── (Alice, ends in |+⟩)
                      │              │
q1: |0⟩ ── H ──■─────⊕──────────■────│─── (Alice, ends in |+⟩)
               │                 │    │
q2: |0⟩ ───────⊕────────────────⊕───Z─── (Bob, ends in |ψ⟩)
```

| Step | Code | Effect |
|---|---|---|
| 1 | `ry(θ,0); rz(φ,0)` | prepare the payload \|ψ⟩ on q0 |
| 2 | `h(1); cx(1,2)` | the shared Bell pair on q1, q2 |
| 3 | `cx(0,1); h(0)` | Alice's rotation into the Bell basis |
| 4 | *measure q0 → a, q1 → b; send (a,b)* | the classical channel |
| 5 | X^b then Z^a on q2 | Bob's correction |

**Steps 4–5 in this simulator.** `SwiftQiskitCore` has no mid-circuit measurement, so the
page uses the **deferred-measurement principle**: a correction conditioned on a measured bit
is equivalent to a quantum-controlled gate applied *before* measuring. So X^b becomes
`cx(1, 2)` and Z^a becomes CZ(0, 2), built as `h(2); cx(0,2); h(2)` (page 11's idiom). Every
branch is corrected at once, in superposition — and the final state factors exactly.

**Why it works.** After step 3 the register is

```text
½ Σ_{a,b} |ab⟩ ⊗ (X^b Z^a |ψ⟩)
```

Each of Alice's four equally likely outcomes leaves Bob holding \|ψ⟩ mangled by a *known*
Pauli, which his two classical bits let him undo:

| Alice's bits ab | Bob's state | Bob applies |
|---|---|---|
| 00 | \|ψ⟩ | I |
| 01 | X\|ψ⟩ | X |
| 10 | Z\|ψ⟩ | Z |
| 11 | XZ\|ψ⟩ | XZ |

## Superdense coding — the dual

Same Bell pair, opposite direction: Alice sends **two classical bits** by transmitting
**one qubit**. She applies one of I / `x(0)` / `z(0)` / `z(0);x(0)` to her half, sends it,
and Bob undoes the entangling circuit with `cx(0,1); h(0)` and reads both bits with
certainty. The four encodings produce the four Bell states, which are orthonormal — the page
prints their Gram matrix as the identity, which is exactly why decoding never errs.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`13Teleportation`** page (or
   follow `[Next]` from `12ShorExample`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set `buildActiveScheme`
   and won't run otherwise.
3. This page has a SwiftUI live view. On Xcode 27 betas, re-copy the `libcups` shim
   immediately before running — see `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds".
4. Run the page. Output is annotated inline with `// Expected:` comments.

## Expected output

The payload (θ = 60°, φ = 45°, matching pages 04 and 08):

```text
|ψ⟩:  |0⟩: 0.8001 - 0.3314i   |1⟩: 0.4619 + 0.1913i
P(0), P(1):  ["0.7500", "0.2500"]
Bloch point: x 0.6124  y 0.6124  z 0.5000
```

That Bloch point is exactly page 08's ⟨X⟩, ⟨Y⟩, ⟨Z⟩ for the same angles. Building \|ψ⟩ with
`rz` introduces a global phase e^{−iφ/2} relative to page 08's amplitudes, and this line is
the check that a global phase changes nothing observable.

The four branches — equal probabilities, perfect recovery:

```text
ab   P(ab)    correction   fidelity
00   0.2500    I            1.0000
01   0.2500    X            1.0000
10   0.2500    Z            1.0000
11   0.2500    XZ           1.0000
```

After the deferred corrections, the register factors:

```text
matches |+⟩⊗|+⟩⊗|ψ⟩ to within 8.3e-17

q2 (Bob) marginal:    ["0.7500", "0.2500"]
ψ probabilities:      ["0.7500", "0.2500"]
q0 (Alice) marginal:  ["0.5000", "0.5000"]
```

1000 shots (statistical, ±~25 per bin): each `ab` prefix takes ~250, and within every prefix
the last bit splits ~187/~62 — \|ψ\|²'s 0.75/0.25, however Alice's bits fall.

Superdense coding is deterministic:

```text
sent  decoded  P
 00     00    1.0000
 01     01    1.0000
 10     10    1.0000
 11     11    1.0000
```

## The live view

Bloch spheres for \|ψ⟩ as prepared, the four *uncorrected* branches Bob could be holding,
and his corrected state:

| Sphere | x | y | z |
|---|---|---|---|
| \|ψ⟩ and ab = 00 | 0.6124 | 0.6124 | 0.5000 |
| ab = 01 (X\|ψ⟩) | 0.6124 | −0.6124 | −0.5000 |
| ab = 10 (Z\|ψ⟩) | −0.6124 | −0.6124 | 0.5000 |
| ab = 11 (XZ\|ψ⟩) | −0.6124 | 0.6124 | −0.5000 |
| Bob, corrected | 0.6124 | 0.6124 | 0.5000 |

Read the middle four as the Pauli rotations they are: X is a half-turn about the x-axis
(y and z flip), Z a half-turn about z (x and y flip). Bob's corrected sphere lands back on
the first one — that is the whole protocol in one picture.

## Using it in your own code

```swift
import SwiftQiskitCore

/// Teleport q0's state to q2, with the corrections deferred into gates.
func teleportCircuit(prepare: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 3)
    prepare(qc)                       // put |ψ⟩ on q0
    qc.h(1); qc.cx(1, 2)              // shared Bell pair
    qc.cx(0, 1); qc.h(0)              // Alice's Bell-basis rotation
    qc.cx(1, 2)                       // X^b correction
    qc.h(2); qc.cx(0, 2); qc.h(2)     // Z^a correction (CZ)
    return qc
}

let qc = teleportCircuit { $0.ry(Double.pi / 3, 0); $0.rz(Double.pi / 4, 0) }
let bob = StateVector([qc.run()[0], qc.run()[1]])   // q2's slice — exactly |ψ⟩
```

To inspect one measurement branch instead, project with the Dirac layer:

```swift
let projector = (Ket("01") * Bra("01")) ⊗ Matrix.identity(size: 2)
var branch = qc.run()
branch.apply(projector)      // collapses to ab = 01, renormalized
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first; check for
  compile errors in `Sources/SwiftQiskitCore/`.
- **`Failed to load linked library cups`** — the Xcode 27 beta evaluator bug; this page
  declares a `View` inline, which is the case that needs the shim. Re-copy it immediately
  before each run (`PLAYGROUNDSUPPORT.md`).
- **Fidelity below 1 in your own variant** — check the correction order. Bob applies X^b
  *then* Z^a; swapping them costs a relative sign on one branch (ZX = −XZ), which is
  harmless as a global phase only if it is applied uniformly.
- **`cx` precondition failure** — control and target must be distinct and in range;
  `cx` itself works on any pair.
