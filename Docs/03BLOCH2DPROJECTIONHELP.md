# A general tilted qubit & plane projections — help & usage guide

User-facing guide to the `03Bloch2dProjection` playground page, which follows `02Bloch2d`
with a single *general* single-qubit state and its plane projections. As with `02Bloch2d`
there is no separate design/plan document — the page, its comments, and the shared
implementation in `Playgrounds.playground/Sources/` (`BlochVector.swift`,
`BlochSphereView.swift`, `BlochProjectionView.swift`) are the reference; see
`02BLOCH2DHELP.md` for the Bloch map itself and the general live-view recipe (both apply
unchanged here) and `PLAYGROUNDSUPPORT.md` for how `Sources/` sharing works.

## What the page shows

`02Bloch2d`'s gallery sticks to six special points — the poles and the four equatorial
axis states. This page picks a state that is *not* on any axis, to show the general
machinery: a Bloch vector making a 45° angle with the x-axis and a 60° angle with the
y-axis.

The components of a unit vector are its direction cosines, so:

- x = cos 45° = √2/2 ≈ 0.7071
- y = cos 60° = 1/2
- z = √(1 − x² − y²) = √(1 − 3/4) = 1/2 (choosing the upper hemisphere)

which happens to also put the vector 60° from the z-axis. In spherical angles:

- θ = acos(z) = 60° (polar angle from the |0⟩ pole)
- φ = atan2(y, x) ≈ 35.264° (azimuth from the x-axis)

Any single-qubit state can be written, up to an unobservable global phase, as

```text
|ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
```

(fixing the phase by making the |0⟩ amplitude real and non-negative). Substituting
θ = 60°, φ ≈ 35.264° gives |ψ⟩ ≈ 0.8660|0⟩ + (0.4082 + 0.2887i)|1⟩ — the state the page
builds directly from these amplitudes (SwiftQiskit v0.1 had no rotation/phase gates when
this page was first written; today the same state is also reachable via
`qc.ry(theta, 0); qc.p(phi, 0)` — see "Using it in your own code" below).

The page then closes the loop: it recovers the Bloch vector from those amplitudes with
`BlochVector` and reads back the three direction-cosine angles, checking they land back
on 45°/60°/60°.

## The page's sections

| Section | What it shows |
|---|---|
| 1 — Ket definition | Commentary only: the direction-cosine derivation of θ and φ above, and the general θ/φ parametrization of a single-qubit state |
| 2 — Build the state | `theta = .pi / 3`, `phi = atan2(0.5, sqrt(2) / 2)`, `alpha`/`beta` computed from them, `psi = StateVector([alpha, beta])` |
| 3 — Console readout | The ket definition restated with `theta`/`phi` filled in, then `psi`'s amplitudes, magnitudes, and probabilities |
| 4 — Bloch vector math | Commentary only: the α, β → (x, y, z) map (same as `02Bloch2d`), pointing at `BlochVector` in shared `Sources/` |
| 4 (cont.) — Round-trip check | `bloch = BlochVector(psi)`, then `acos(bloch.x)`, `acos(bloch.y)`, `acos(bloch.z)` printed as degrees — the recovered angles from x, y, z |
| 5 — Plane projections | Commentary only: an orthographic projection onto a coordinate plane drops the out-of-plane component; `BlochProjectionView` (shared `Sources/`) draws one such plane |
| 6 — Live view | An inline `BlochDetailView`: one `BlochSphereView(size: 300)`, an `HStack` of two `BlochProjectionView`s (x–y from +z, z–y from +x), and a monospaced amplitude/probability readout, handed to `PlaygroundPage.current.setLiveView(_:)` at 460 × 720 |

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`03Bloch2dProjection`** page
   (or follow the `[Next]` link from `02Bloch2d` / `[Previous]` from `04Bloch3d`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. The console prints the ket definition, amplitudes, magnitudes,
   probabilities, and the Bloch round-trip; the live-view pane shows the sphere plus the
   two projection panels (open the Assistant editor / live view area to see it).

This page **imports SwiftUI and shows a live view**, so the Xcode 27 beta evaluator bugs
apply — if the page fails to run or the live view stays blank, see `PLAYGROUNDSUPPORT.md`
§ "Xcode 27 beta workarounds".

## Expected output

The complete console output:

```text
Ket definition:
  |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
  θ = 1.047 rad (60.0°), φ = 0.615 rad (35.3°)
  |ψ⟩ ≈ 0.8660|0⟩ + (0.4082 + 0.2887i)|1⟩

Amplitudes:
  α = ⟨0|ψ⟩ = 0.8660254037844387
  β = ⟨1|ψ⟩ = 0.40824829046386296 + 0.2886751345948128i

Magnitudes:
  |α| = 0.8660
  |β| = 0.5000

Probabilities:
  P(0) = |α|² = 0.7500
  P(1) = |β|² = 0.2500

Bloch vector (recovered from amplitudes):
  x +0.7071  y +0.5000  z +0.5000
  angle from x-axis: 45.0°
  angle from y-axis: 60.0°
  angle from z-axis: 60.0°
```

Reading notes:

- **α prints with no imaginary term, β prints as `real + imagi`** — `Complex.description`
  (`Math/Complex.swift`) special-cases `imag == 0`, so a purely real amplitude never gets
  a trailing `+ 0.0i`.
- **The amplitudes print exactly as computed, with no rescaling.** `theta`/`phi` are built
  so cos²(θ/2) + sin²(θ/2) = 1 to the last bit, so `StateVector.normalize()`'s
  `abs(norm - 1) > 1e-12` guard skips the rescale entirely — the printed α/β are the raw
  doubles from `cos`/`sin`, not the result of a division (the same reasoning
  `01QUBITSHELP.md` and `08DIRACHELP.md` use for their exact inner products).
- **The recovered Bloch components carry only ~1e-16 of rounding** — under the `%+.4f`
  format, y is actually `0.4999999999999999` and z is `0.5000000000000002`. The exact
  45.0°/60.0°/60.0° readback is the round trip closing (build ψ from θ, φ → recover
  x, y, z → recover the angles), not a coincidence.
- **|β| = 0.5 = sin 30°, and P(0)/P(1) depend only on θ, never on φ.** Sliding φ moves the
  state around the z-axis (the equator at that latitude) without changing the measurement
  statistics at all — contrast the uniform-superposition case in
  `06SUPERPOSITIONHELP.md`, where every qubit sits exactly on the equator (θ = 90°).
- **This ψ is not the same state as `01QUBITSHELP.md`'s/`08DIRACHELP.md`'s `ket1`**, even
  though both use α = cos 30° ≈ 0.8660 (i.e. the same θ = 60°): `ket1` uses φ = 45° while
  this page's φ ≈ 35.264°, so the two states sit at different points on the same latitude
  (verified: `ket1`'s β ≈ 0.3536 + 0.3536i vs. this page's β ≈ 0.4082 + 0.2887i).

## Reading the drawing

The large sphere reuses `BlochSphereView` unchanged from `02Bloch2d` — same oblique
projection (y → right, z → up, x foreshortened toward the lower-left by 0.354), same
solid-circle outline, dashed equator, and red arrow with numeric readout. See
`02BLOCH2DHELP.md` § "Reading the drawing" for the full explanation; on this page the
tilted state shows as an arrow pointing up and to the right (positive y and z, with a
shorter foreshortened nudge toward the viewer for positive x).

The two `BlochProjectionView` panels drop one Bloch component entirely and draw the
remaining two as a point inside a unit circle — an orthographic projection onto that
coordinate plane, with a labeled horizontal/vertical axis pair, a red arrow + dot for the
projected point, and an `h v r` readout where `r = hypot(h, v)` is the projected vector's
length:

- **x–y plane (view from +z)** — readout `y +0.500  x +0.707  r 0.866`. Since
  r² = x² + y² = 1 − z², the shortfall from the unit circle (0.866 vs. 1.0) is exactly the
  dropped z-component.
- **z–y plane (view from +x)** — readout `y +0.500  z +0.500  r 0.707`. Here
  r² = 1 − x², so the shortfall (0.707 vs. 1.0) is exactly the dropped x-component.

**Why the x–y panel passes `verticalPointsDown: true`:** it's the view looking down from
the |0⟩ pole along −z. To keep the same viewer-facing convention as the main sphere
(x points toward the viewer), +x must point *down* on that particular canvas — the z–y
panel has no such twist, since it's a side view. `BlochProjectionView.point(_:_:center:radius:)`
flips the vertical sign only when this flag is set.

A projected arrow shorter than the unit circle is expected any time the state points out
of that plane — only a state lying exactly in the plane (e.g. an equatorial |±⟩-family
state in the x–y panel) reaches the circle's edge.

## Using it in your own code

`BlochProjectionView` lives in the playground's `Sources/` folder, **not** in
`SwiftQiskitCore` (Bloch math stays out of Core) — it's available on every playground page,
not in library targets. It takes any two labeled numbers, so it isn't limited to Bloch
components:

```swift
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

let theta = Double.pi / 3
let phi = Double.pi / 4
let qc = QuantumCircuit(qubits: 1)
qc.ry(theta, 0)     // cos(θ/2)|0⟩ + sin(θ/2)|1⟩
qc.p(phi, 0)        // adds the relative phase e^{iφ} to |1⟩
let bloch = BlochVector(qc.run())

PlaygroundPage.current.setLiveView(
    HStack {
        BlochSphereView(label: "|ψ⟩", bloch: bloch, size: 300)
        BlochProjectionView(
            label: "x–z plane",
            horizontal: ("x", bloch.x),
            vertical: ("z", bloch.z)
        )
    }
    .frame(width: 620, height: 340)
)
```

`qc.ry(theta, 0)` followed by `qc.p(phi, 0)` reproduces this page's hand-built amplitudes
exactly (`RYGate` in `Gates/Rotation.swift` rotates |0⟩ into
cos(θ/2)|0⟩ + sin(θ/2)|1⟩; `PhaseGate` in `Gates/Phase.swift` then multiplies the |1⟩
amplitude by e^{iφ}) — the page builds amplitudes by hand only to make the θ/φ
parametrization explicit for the reader.

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first; check for
  compile errors in `Sources/SwiftQiskitCore/`.
- **`Failed to load linked library cups of module SwiftUI`** — the Xcode 27 beta libcups
  bug; install the shim per `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (a clean
  build deletes it — rerun the copies).
- **A projected arrow doesn't reach the panel's circle** — expected whenever the state
  points out of that plane; only a state lying exactly in the drawn plane reaches the edge.
  See "Reading the drawing" above for which component each panel drops.
- **`Bloch sphere is defined for single-qubit states` precondition** — `BlochVector` was
  handed a multi-qubit state; it only accepts `dimension == 2`.
- **Live view blank, collapsed, or clipped** — the root view passed to `setLiveView` is
  missing an explicit `.frame(width:height:)`; this page's `BlochDetailView` is already
  framed 460 × 720.
- **`Cannot find 'BlochProjectionView'/'BlochSphereView'/'BlochVector' in scope`** — the
  `Sources/` declaration (or its `init`) isn't `public`, or the file isn't in the
  playground's top-level `Sources/` folder.
