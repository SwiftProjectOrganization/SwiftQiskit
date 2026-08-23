# 2D Bloch sphere — help & usage guide

User-facing guide to the `02Bloch2d` playground page, which visualizes single-qubit
states on the Bloch sphere with a SwiftUI live view. Unlike the algorithm pages there is no
separate design/plan document — the shared implementation in
`Playgrounds.playground/Sources/` (`BlochVector.swift`, `BlochSphereView.swift`) and its
doc comments are the reference, and `PLAYGROUNDSUPPORT.md` documents the sharing mechanism.

## What the Bloch sphere shows

Every single-qubit state |ψ⟩ = α|0⟩ + β|1⟩ maps — up to an unobservable global phase — to
a point on the surface of the unit sphere:

- x = 2·Re(ᾱβ)
- y = 2·Im(ᾱβ)
- z = |α|² − |β|²

with spherical angles θ = acos(z) (polar angle from the |0⟩ pole) and φ = atan2(y, x)
(azimuth in the xy plane). Two states differing only by a global phase e^{iγ} give the same
ᾱβ and the same |α|²/|β|², so they land on the same point — the sphere shows exactly the
physically distinguishable content of the state. For a normalized state,
x² + y² + z² = (|α|² + |β|²)² = 1, so pure states sit exactly on the surface.

The geography:

| State | Bloch vector | Location |
|---|---|---|
| \|0⟩ | (0, 0, +1) | north pole |
| \|1⟩ | (0, 0, −1) | south pole |
| \|+⟩ = (\|0⟩ + \|1⟩)/√2 | (+1, 0, 0) | +x axis |
| \|−⟩ = (\|0⟩ − \|1⟩)/√2 | (−1, 0, 0) | −x axis |
| \|+i⟩ = (\|0⟩ + i\|1⟩)/√2 | (0, +1, 0) | +y axis |
| \|−i⟩ = (\|0⟩ − i\|1⟩)/√2 | (0, −1, 0) | −y axis |

The page's gallery shows all six. Reaching the ±y states from |0⟩ takes the phase gate
S = √Z, now in Core: `s(0)` / `sdg(0)` after `h(0)`. (`Ket.plusI` / `Ket.minusI` in
`Quantum/Dirac.swift` build the same states directly from amplitudes.)

The math lives in `BlochVector` (playground `Sources/`), which reuses the `Complex`
arithmetic from `SwiftQiskitCore` (`conjugate`, `*`, `magnitudeSquared`) and guards the
single-qubit requirement with `precondition(state.dimension == 2)`.

## The page's sections

| Section | What it shows |
|---|---|
| 1 — Bloch vector math | Commentary only: the α, β → (x, y, z) map above, and where the implementation lives (`BlochVector`, `BlochSphereView` in `Sources/`) |
| 2 — Demo states | The six gallery states built with real circuits — \|0⟩ from an empty `QuantumCircuit(qubits: 1)`, \|1⟩ via `x(0)`, \|+⟩ via `h(0)`, \|−⟩ via `h(0)` + `z(0)`, \|+i⟩ via `h(0)` + `s(0)`, \|−i⟩ via `h(0)` + `sdg(0)` — each turned into a `BlochVector(circuit.run())` and printed to the console |
| 3 — Live view | An inline `BlochGalleryView` (a `LazyVGrid`, 2 × 3) of `BlochSphereView`s, handed to `PlaygroundPage.current.setLiveView(_:)` at 560 × 940 points |

## Running the page

1. Open `Playgrounds.playground` in Xcode and select the **`02Bloch2d`** page
   (or follow the `[Next]` link from `01Qubits` / `[Previous]` from
   `03Bloch2dProjection`).
2. Make sure the **SwiftQiskit** scheme is active and builds — pages set
   `buildActiveScheme` and won't run otherwise.
3. Run the page. Six lines appear in the console, and the 2 × 3 sphere gallery appears
   in the live-view pane (open the Assistant editor / live view area to see it).

This page **imports SwiftUI and shows a live view**, so the Xcode 27 beta evaluator bugs
apply — if the page fails to run or the live view stays blank, see `PLAYGROUNDSUPPORT.md`
§ "Xcode 27 beta workarounds".

## Expected output

The complete console output:

```text
|0⟩  x +0.000  y +0.000  z +1.000  (θ 0.000, φ 0.000)
|1⟩  x +0.000  y +0.000  z -1.000  (θ 3.142, φ 0.000)
|+⟩  x +1.000  y +0.000  z +0.000  (θ 1.571, φ 0.000)
|−⟩  x -1.000  y +0.000  z +0.000  (θ 1.571, φ 3.142)
|+i⟩  x +0.000  y +1.000  z +0.000  (θ 1.571, φ 1.571)
|−i⟩  x +0.000  y -1.000  z +0.000  (θ 1.571, φ -1.571)
```

Reading notes:

- **θ 3.142 is π, θ 1.571 is π/2** — the poles are at θ = 0 and θ = π; the equator at π/2.
- **φ = 0.000 at both poles is a convention, not information** — with x = y = 0 the azimuth
  is undefined; `atan2(0, 0)` returns 0 by definition. Only equatorial (and generally
  non-polar) states have a meaningful φ, like |−⟩'s φ = π.
- **The zeros are exact** — H fills both amplitudes with the same double ±1/√2, so
  z = |α|² − |β|² for |±⟩ subtracts two identical doubles, and y = 2·Im(ᾱβ) of real
  amplitudes is 0. Only the ±1 entries (x for |±⟩, y for |±i⟩) carry rounding:
  2·(1/√2)² is `±0.9999999999999998`
  (the same ~1e-16 as H†H in `Docs/08DIRACHELP.md`), invisible at three decimals.
- **Every zero prints as `+0.000`** — the `%+.3f` format always emits a sign, and no
  computation here produces a negative zero.

## Reading the drawing

`BlochSphereView` draws an *oblique orthographic* projection of the sphere on a SwiftUI
`Canvas`: y points right, z points up, and x — the axis toward the viewer — is
foreshortened by a factor 0.5·√0.5 ≈ 0.354 toward the lower-left:

- canvas-right = y − x·0.354, canvas-up = z − x·0.354

So |+⟩ (+x axis) appears as a short arrow toward the lower-left, |−⟩ toward the upper-right,
and the poles straight up/down at full length. Other elements:

- the **solid circle** is the sphere's outline; the **dashed ellipse** is the equator,
  flattened by the same foreshortening factor;
- all three axes are drawn through the center, labeled `x`, `y`, and `|0⟩`/`|1⟩` at the
  poles (labels sit at 1.15 × radius, just outside the sphere);
- the **red arrow with the dot** is the state vector; the monospaced readout underneath
  repeats the numeric (x, y, z) and (θ, φ).

The projection is fixed. For a rotatable view of the same states, see page
`04Bloch3d` (`Bloch3DView` with drag-to-orbit; user guide `Docs/04BLOCH3DHELP.md`).

## Putting a live view on a playground page

Page 02 is the playground's minimal live-view example; the recipe generalizes to any page.

```swift
import SwiftUI
import PlaygroundSupport

// ... console/lecture code ...

PlaygroundPage.current.setLiveView(
    MyRootView()
        .frame(width: 560, height: 640)   // explicit size — see note 2
)
```

1. **`setLiveView` takes any SwiftUI `View`.** Console `print`s and the live view coexist:
   keep the lecture commentary and printed checks in the page, and the rendering
   implementation in `Sources/` (pages reference the shared type by name so readers know
   where to look).
2. **Give the root view an explicit `.frame(width:height:)`.** The live-view pane does not
   propose a window-like size, so an unframed view can collapse or clip. Page 02 sizes the
   root to fit its content: a 2 × 3 grid of 260-point cells plus padding → 560 × 940.
3. **Stateless views may be declared inline in the page.** `BlochGalleryView` holds only a
   `let` and can live in page code. Inline page types need no access modifiers.
4. **Stateful views must live in `Playgrounds.playground/Sources/`.** The Xcode 27 beta
   evaluator cannot expand the SDK 27 `@State` macro in page code; the `Sources/` module
   is compiled by the regular build system, where the macro works. This is why the
   slider view `BlochExplorerView` (page 04) is in `Sources/`. Details in
   `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds".
5. **Everything a page touches in `Sources/` must be explicitly `public`** — types,
   initializers, properties. Swift's synthesized memberwise inits are only `internal`,
   so shared views need a written-out `public init` (see `BlochSphereView.init`).
6. **The scheme must build.** Pages set `buildActiveScheme='true'`; `Sources/` may
   `import SwiftQiskitCore` (and `SwiftUI`) because the SwiftQiskit scheme builds first.
7. **Xcode 27 beta only (machine-specific):** any page importing SwiftUI may hit the
   missing-`libcups.dylib` evaluator bug; the shim recipe is in `PLAYGROUNDSUPPORT.md`
   § "Xcode 27 beta workarounds". Rerun it after Clean Build Folder.

## Using it in your own code

`BlochVector` and `BlochSphereView` live in the playground's `Sources/` folder, **not** in
`SwiftQiskitCore` — they are available on every playground page (auto-imported), but not
in library targets ("Bloch math stays out of Core"). On any page:

```swift
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// Any single-qubit circuit → a point on the sphere
let qc = QuantumCircuit(qubits: 1)
qc.h(0)
let bloch = BlochVector(qc.run())      // preconditions dimension == 2
print(bloch.x, bloch.y, bloch.z)       // 1.0 0.0 0.0
print(bloch.theta, bloch.phi)          // π/2, 0

// Render one sphere (size: is the square canvas side, default 220;
// page 03 passes 300 for its larger single sphere)
PlaygroundPage.current.setLiveView(
    BlochSphereView(label: "|+⟩", bloch: bloch)
        .frame(width: 300, height: 340)
)
```

States built directly from amplitudes work too — e.g.
`BlochVector(StateVector([Complex(1 / 2.0.squareRoot()), Complex(0, 1 / 2.0.squareRoot())]))`
lands on the +y axis (the same |+i⟩ the gallery reaches with `h(0)` + `s(0)`).

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first; check for
  compile errors in `Sources/SwiftQiskitCore/`.
- **`Failed to load linked library cups of module SwiftUI`** — the Xcode 27 beta libcups
  bug; install the shim per `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (a clean
  build deletes it — rerun the copies).
- **An inline view with `@State` fails** (`plugin for module 'SwiftUIMacros' not found`,
  or `'self' is immutable` at the mutation site) — move the view to
  `Playgrounds.playground/Sources/` as a `public` type; the page only instantiates it.
- **`Bloch sphere is defined for single-qubit states` precondition** — `BlochVector` was
  handed a multi-qubit state; it only accepts `dimension == 2` (e.g.
  `QuantumCircuit(qubits: 1).run()`).
- **Live view blank, collapsed, or clipped** — the root view passed to `setLiveView`
  is missing an explicit `.frame(width:height:)`.
- **`Cannot find 'BlochSphereView' in scope` from a page** — the `Sources/` declaration
  (or its `init`) isn't `public`, or the file isn't in the playground's top-level
  `Sources/` folder.
