# SwiftQiskitGUI — tutorial & usage guide

A hands-on walkthrough of `SwiftQiskitGUI`, the interactive macOS app for building
`QuantumCircuit`s by tapping gates onto a grid instead of writing Swift. This document is
the *how to use it* guide; for the app's architecture, extension points, and
troubleshooting, see the companion `SwiftQiskitDocs/GUIHELP.md`.

The app lives at `Sources/SwiftQiskitGUI/` and is a normal SwiftPM executable target — no
playground involved. It's mac-only (`.macOS(.v14)` minimum, per `Package.swift`) and uses
nothing outside `SwiftQiskitCore`'s existing `h/x/y/z/s/sdg/t/tdg/p/rx/ry/rz/cx` circuit API.

## Launching the app

- **Command line:** `swift run SwiftQiskitGUI` from the repo root.
- **Xcode:** select the **`SwiftQiskitGUI`** scheme with run destination **My Mac**, then
  Run (⌘R).

## The three panels

| Panel | What it's for |
|---|---|
| **Gates** (left) | Tap a gate button to *arm* it (it highlights). |
| **Circuit** (center) | A grid, one wire per qubit, drawn as a real horizontal line. Tap an empty cell to place the armed gate there. Has the qubit-count stepper and a **Clear** button. |
| **State Vector** (right) | Live amplitudes/probabilities for the circuit as currently built, plus a **Measure** button and shot-count histogram. |

Full control-by-control reference is in `SwiftQiskitDocs/GUIHELP.md`.

## Walkthrough: build and measure a Bell state

This reproduces the classic `h(0); cx(0, 1)` circuit from
`PlaygroundDocs/07ENTANGLEMENTHELP.md`, but by tapping instead of writing code.

1. **Launch the app.** It opens with the default 2-qubit circuit (rows `q0`, `q1`), empty.

2. **Place the Hadamard.** In the palette's "Pauli / Hadamard" section, click **H** — it
   highlights (armed). Click the first empty cell in the `q0` row. An `H` tile appears
   there.

   The State Vector panel updates immediately: two states are listed, `|00⟩` and `|10⟩`,
   each with probability ≈ 0.500 (amplitude ≈ 0.707). `q0` is the leftmost bit — the
   convention used everywhere else in this project — so it's the *first* character of the
   label that's split, not the second.

3. **Place the CX.** Click **CX** in the "Multi-qubit" section to arm it. Click the `q0`
   cell in the *next* empty column — an orange ring appears there, marking it as the
   pending control. Click the `q1` cell in that *same* column. The `q0` cell now shows a
   filled dot (control) and the `q1` cell shows a circle-plus (⊕, target), joined by a
   vertical line connecting the two.

   The State Vector panel now shows only two states: `|00⟩` and `|11⟩`, each with
   probability ≈ 0.500 — the Bell state.

4. **Measure it.** Set the **Shots** stepper to whatever you like (default 1000) and click
   **Measure**. A bar chart appears below, with counts split roughly evenly between `00`
   and `11` and (statistically) nothing elsewhere.

Re-clicking **Measure** re-samples — expect the split to jitter around 50/50, not land on
it exactly, same as `measure(shots:)` anywhere else in this project.

## Other things to try

- **A parameterized gate.** Arm **RX** (under "Rotation") and place it on a qubit. Tap the
  placed tile again to open a popover with a θ slider (0 to 2π); dragging it updates the
  State Vector panel live.
- **Deleting a gate.** Right-click (or ⌃-click) a placed single-qubit tile and choose
  **Delete** from the context menu. For a CX gate, clicking *either* the control dot or the
  target ⊕ removes the whole gate.
- **Growing the circuit.** Use the **Qubits** stepper (1–8) to add rows. Shrinking it drops
  any placed gates that no longer fit — there's no undo, so if you want to keep them, note
  the recipe before shrinking.
- **Clear.** The **Clear** button removes every placed gate but keeps the current qubit
  count.
- **A 3-qubit GHZ state.** Bump **Qubits** to 3, place `H` on `q0`, then `CX(q0, q1)` and
  `CX(q0, q2)` in the next two columns — the State Vector panel should settle on `|000⟩` and
  `|111⟩` only, each ≈ 0.500, mirroring the GHZ section of `PlaygroundDocs/07ENTANGLEMENTHELP.md`.
