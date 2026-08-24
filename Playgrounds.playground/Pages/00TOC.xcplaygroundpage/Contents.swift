/*:
 # SwiftQiskit Playgrounds

 Interactive, lecture-style explorations of the SwiftQiskit library — a lightweight,
 educational quantum-computing simulator in pure Swift.

 Before running any page, make sure the **SwiftQiskit** scheme is active and builds:
 pages set `buildActiveScheme` and won't run otherwise.

 ## Pages

 - [01Qubits](01Qubits) — qubit states via the Dirac API: amplitudes, probabilities,
   the dagger `†`, and inner/outer products, plus two example circuits' stages shown
   live on 2D Bloch spheres.
 - [02Bloch2d](02Bloch2d) — the six canonical states |0⟩ |1⟩ |+⟩ |−⟩ |+i⟩ |−i⟩ on a 2D
   Bloch sphere (SwiftUI live view).
 - [03Bloch2dProjection](03Bloch2dProjection) — a general tilted qubit state, with
   x–y and z–y plane projections (live view).
 - [04Bloch3d](04Bloch3d) — rotatable 3D Bloch sphere with live θ/φ sliders.
 - [05Gates](05Gates) — a gentle, gate-by-gate tour of the built-in gates
   (`x/h/z/y/s/sdg/t/p/rx/ry/rz`) on a 1-qubit circuit, with a one-line Bell-state teaser.
 - [06Superposition](06Superposition) — a 4-qubit circuit with every qubit put into
   superposition via `h`, plus a partial-superposition contrast.
 - [07Entanglement](07Entanglement) — annotated Bell-state walkthrough, plus a
   3-qubit GHZ state using `cx` across non-adjacent qubits.
 - [08Dirac](08Dirac) — Dirac notation in depth: projectors, adjoints, and Pauli
   expectation values on a static 3D Bloch sphere.
 - [09Tensor](09Tensor) — tensor products: gate embedding, the mixed-product
   identity, and why the Bell state does not factor.
 - [10DeutschExample](10DeutschExample) — Deutsch's algorithm: constant vs. balanced
   from a single oracle query via phase kickback.
 - [11GroverExample](11GroverExample) — Grover's search: phase oracles, inversion
   about the mean, and a 3-qubit finale with a hand-built CCZ.
 - [12ShorExample](12ShorExample) — compiled Shor factoring of 15: modular
   multiplication, a hand-built QFT†, and phase estimation.
 - [13Teleportation](13Teleportation) — teleportation and superdense coding:
   Bell-basis projectors, deferred measurement, and Bloch spheres of every branch.
 - [14ErrorCorrection](14ErrorCorrection) — the 3-qubit bit-flip/phase-flip code: a
   hand-built syndrome correction, continuous errors digitized exactly, and where a
   distance-3 code breaks.
 - [15CHSH](15CHSH) — the CHSH inequality: the classical bound enumerated exhaustively,
   a Bell pair's S = 2√2, and the gap plotted on a live chart.
 - [16QFT](16QFT) — the quantum Fourier transform as a gate circuit: a hand-derived
   controlled-phase gate, the QFT ladder checked against page 12's matrix, and standalone
   phase estimation.
 - [17DeutschJozsa](17DeutschJozsa) — Deutsch–Jozsa and Bernstein–Vazirani: page 10's
   one-query trick generalized to n bits, plus recovering a hidden string in one query.
 - [18VQE](18VQE) — the variational quantum eigensolver: an H₂ Hamiltonian, a one-parameter
   ansatz, exact parameter-shift gradients, and gradient descent plotted live.

 ## User guides

 Several pages have companion documents in `Docs/` at the repo root, prefixed with the
 page number: `01QUBITSHELP.md`, `02BLOCH2DHELP.md`, `03BLOCH2DPROJECTIONHELP.md`,
 `04BLOCH3DHELP.md`, `05GATESHELP.md`, `06SUPERPOSITIONHELP.md`,
 `07ENTANGLEMENTHELP.md`, `08DIRACHELP.md`, `09TENSORPLAN/HELP.md`, `10DEUTSCHPLAN/HELP.md`,
 `11GROVERPLAN/HELP.md`, `12SHORPLAN/HELP.md`, `13TELEPORTATIONPLAN/HELP.md`,
 `14ERRORCORRECTIONPLAN/HELP.md`, `15CHSHPLAN/HELP.md`, `16QFTPLAN/HELP.md`,
 `17DEUTSCHJOZSAPLAN/HELP.md`, and `18VQEPLAN/HELP.md`. The
 `…PLAN.md` files record design notes; the `…HELP.md` files are user guides with
 expected output and troubleshooting. One guide isn't page-numbered:
 `Docs/LIVEVIEWHELP.md` covers the playground's shared `Sources/` code and the general
 live-view recipe used by several pages. See also `PLAYGROUNDSUPPORT.md` for the terse
 implementation reference on how code in the playground's `Sources/` folder is shared
 between pages.
 */
//: [Next](@next)
