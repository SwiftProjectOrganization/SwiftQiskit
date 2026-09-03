# 3D Bloch sphere — help & usage guide

User-facing guide to the `04Bloch3d` playground page, which visualizes a single-qubit
state on a rotatable 3D Bloch sphere with a SwiftUI live view and live θ/φ sliders. As
with `02Bloch2d`/`03Bloch2dProjection` there is no separate design/plan document — the
shared implementation in `Playgrounds.playground/Sources/` (`BlochVector.swift`,
`Bloch3DView.swift`, `BlochExplorerView.swift`) and its doc comments are the reference;
see `02BLOCH2DHELP.md` for the Bloch map itself (applies unchanged here) and
`PlaygroundDocs/90LIVEVIEWHELP.md` for the general live-view recipe and how `Sources/` sharing works.

## What the page shows

Pages 02 and 03 fix a state and look at it from a static projection. This page instead
parametrizes *any* single-qubit state by its spherical angles and lets you move it live:

```text
|ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
```

with θ ∈ [0, π] the polar angle from the |0⟩ pole and φ ∈ [0, 2π) the azimuth from the
x-axis (fixing the global phase by making the |0⟩ amplitude real and non-negative — the
same derivation as `03BLOCH2DPROJECTIONHELP.md`).

The two sliders are independent because the parametrization satisfies normalization
identically:

```text
|α|² + |β|² = cos²(θ/2) + |e^{iφ}|²·sin²(θ/2) = cos²(θ/2) + sin²(θ/2) = 1
```

for *every* θ and φ, since e^{iφ} is a pure phase (|e^{iφ}| = 1) that never changes a
magnitude. That's why the page exposes sliders for the angles rather than the raw
amplitudes: every slider position is a valid normalized state, so the sliders can only
move around the surface of the sphere, never off of it. One consequence worth noticing
while playing with the live view: the measurement probabilities P(0) = cos²(θ/2) and
P(1) = sin²(θ/2) depend only on θ — dragging the φ slider slides the state around its
latitude without changing the measurement statistics at all.

## The page's sections

| Section | What it shows |
|---|---|
| 1 — The θ/φ parametrization | Commentary + the local `makeState(theta:phi:)` helper: the ket definition above and why θ, φ can vary independently |
| 2 — Console readout | The starting state θ = π/3 (60°), φ = π/4 (45°) printed as amplitudes and the |α|² + |β|² check |
| 3 — The 3D view | Commentary only: `Bloch3DView` (shared `Sources/`) draws a rotatable wireframe sphere via an orbit camera, contrasted with the fixed oblique projection of `BlochSphereView` on pages 02/03 |
| 4 — Live view | `BlochExplorerView` (shared `Sources/`): `Bloch3DView` plus live θ/φ sliders, rebuilding the state from the parametrization on every change, handed to `PlaygroundPage.current.setLiveView(_:)` at 460 × 640 |

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`04Bloch3d`** page (or follow
   the `[Next]` link from `03Bloch2dProjection` / `[Previous]` from `05Gates`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. Five lines appear in the console for the starting state, and the
   live-view pane shows the rotatable sphere with its θ/φ sliders (open the Assistant
   editor / live view area to see it). Drag the sphere to orbit the camera; move the
   sliders to move the state.

This page **imports SwiftUI and shows a live view**, so the Xcode 27 beta evaluator bugs
apply — if the page fails to run or the live view stays blank, see `PLAYGROUNDSUPPORT.md`
§ "Xcode 27 beta workarounds".

## Expected output

The complete console output:

```text
Starting state:
  θ = 1.047 rad (60.0°), φ = 0.785 rad (45.0°)
  α = ⟨0|ψ⟩ = 0.8660254037844387
  β = ⟨1|ψ⟩ = 0.35355339059327373 + 0.3535533905932737i
  |α|² + |β|² = 1.000000
```

Reading notes:

- **The raw norm is exactly 1.0**, so `StateVector.normalize()`'s
  `abs(norm - 1) > 1e-12` guard skips the rescale entirely — the printed α/β are the raw
  doubles from `cos`/`sin`, not the result of a division (the same reasoning
  `01QUBITSHELP.md` and `03BLOCH2DPROJECTIONHELP.md` use for their amplitudes).
- **α prints with no imaginary term** — `Complex.description` (`Math/Complex.swift`)
  special-cases `imag == 0`, so a purely real amplitude never gets a trailing `+ 0.0i`.
- **β's real and imaginary parts differ in the last bit** (`...327373` vs `...32737`) —
  both compute sin(30°)·cos(45°) and sin(30°)·sin(45°) respectively, which are
  mathematically equal but reach the CPU via two different transcendental calls
  (`cos` vs `sin`), so they round independently.
- **This is the same ψ as page `08Dirac`'s initial qubit** — page 08 builds a state with
  the identical `makeState(theta:phi:)` at θ = π/3, φ = π/4 and reads off its Pauli
  expectation values ⟨X⟩, ⟨Y⟩, ⟨Z⟩; those three numbers are exactly this state's Bloch
  vector, (0.6124, 0.6124, 0.5000) — see `08DIRACHELP.md`. (It is *not* the same state as
  `03Bloch2dProjection`'s tilted qubit, which shares θ = 60° but uses φ ≈ 35.264° instead
  of 45°.)
- **The live view's details readout at the starting position** reads
  `α 0.8660 |α| 0.8660`, `β 0.3536 +0.3536i |β| 0.5000`, `P(0) 0.7500  P(1) 0.2500`,
  `|α|² + |β|² = 1.0000` — the same amplitudes as the console, restated to four decimals
  by `BlochExplorerView`.

## Reading the drawing

`Bloch3DView` draws a genuine perspective projection instead of the fixed oblique one
used by `BlochSphereView` on pages 02/03: a virtual camera orbits the sphere at
`cameraDistance = 4` sphere-radii, controlled by an azimuth angle (about the z-axis) and
an elevation angle (above the equator), defaulting to azimuth 0.4 rad / elevation
0.35 rad — the "classic oblique" starting view. Each world point is rotated into camera
coordinates (right, depth, up) and perspective-divided: `scale = d / (d − depth)`, so
points nearer the camera draw larger and farther points draw smaller, exactly like a real
3D view.

What's on the canvas:

- **Wireframe** — latitude circles every 30° (poles excluded, since a latitude circle at
  the pole has zero radius) and meridians every 30°, each a full great circle through the
  poles. Every circle is split into near- and far-hemisphere segments by the average
  depth of its two endpoints, then the far half is stroked at 0.12 opacity and the near
  half at 0.45 — a depth cue standing in for proper hidden-line removal.
- **Silhouette** — the sphere's outline under perspective projection is very slightly
  larger than the unit disc; it's drawn as an ellipse of radius `radius · d / √(d² − 1)`,
  which for d = 4 is about 1.033 × the base radius.
- **Axes** — `x`, `y`, `|0⟩`, `|1⟩` lines through the center, each labeled just beyond its
  tip (at 1.15 × radius, same convention as `BlochSphereView`).
- **State vector** — a solid red arrow from the center to the projected state, with
  dashed red drop lines from the tip down to the equator plane and across to the origin
  (a depth cue for reading the vector's z-height and azimuth at a glance), and a dot at
  the tip whose radius is itself perspective-scaled (`4 · d / (d − depth)`) so it looks
  bigger when the state is nearer the camera.
- **Readout** — a monospaced caption below the sphere restating x, y, z, θ, φ.

**Dragging the canvas orbits the camera**: horizontal drag rotates the front of the
sphere in the direction you drag (0.01 rad per point of horizontal delta), vertical drag
tips the front up or down by the same rate, with elevation clamped to ±π/2 so the camera
can't flip past either pole.

For the fixed 2D oblique projection this page's camera model replaces, see
`02BLOCH2DHELP.md` § "Reading the drawing".

## Using it in your own code

`Bloch3DView` and `BlochExplorerView` live in the playground's `Sources/` folder, not in
`SwiftQiskitCore` (see `PlaygroundDocs/90LIVEVIEWHELP.md` for how that sharing works). `Bloch3DView`
takes the same `BlochVector` as `BlochSphereView`, so any single-qubit circuit works:

```swift
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

let qc = QuantumCircuit(qubits: 1)
qc.h(0)
let bloch = BlochVector(qc.run())      // preconditions dimension == 2

PlaygroundPage.current.setLiveView(
    Bloch3DView(label: "|+⟩", bloch: bloch, size: 320)
        .frame(width: 380, height: 420)
)
```

For `BlochExplorerView`'s parameterless `init` and where its starting angles are
hardcoded, see `PlaygroundDocs/90LIVEVIEWHELP.md` § "Using each type" (`BlochExplorerView`). For a
**static** `Bloch3DView` frozen at one state rather than a slider-driven one, see page
`08Dirac`, which reuses the same view to show its initial qubit's Pauli expectation
values.

## Troubleshooting

- **Dragging does nothing / sliders don't move the arrow** — make sure you're dragging
  inside the `Canvas` (not the sliders or readout text below it); the gesture is attached
  to the canvas only.
- **Live view blank, collapsed, or clipped** — this page's live view is already framed
  460 × 640; if it still looks wrong, see the general causes in `PlaygroundDocs/90LIVEVIEWHELP.md`
  § "Troubleshooting" (which also covers the scheme-build requirement, the libcups shim,
  an inline `@State` view, `Cannot find 'X' in scope`, and the `BlochVector`
  single-qubit precondition).
