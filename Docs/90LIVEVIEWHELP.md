# Playground live views & shared code — help & usage guide

User-facing guide to the playground's shared `Sources/` module and to putting a SwiftUI
live view on any page. Unlike the other `Docs/*HELP.md` files this one isn't numbered —
it documents a mechanism used by several pages, not one page — so read it alongside
whichever page guide sent you here.

**Scope.** The file name leads with "live views" because that's what most people arrive
looking for, but the guide covers the whole shared module, including the one file that
has nothing to do with live views: `BlochVector.swift` is plain math (`import Foundation`
+ `import SwiftQiskitCore`, no SwiftUI) and pages 01/02/03 print its values to the console
independently of anything they render. Everything else in
`Playgrounds.playground/Sources/` is a SwiftUI `View`.

`PLAYGROUNDSUPPORT.md` at the repo root stays the terse reference — the "Current shared
code" / "Which pages use what" tables and the Xcode 27 beta bug log live there; this guide
links to it rather than restating it. Per-page walkthroughs are `Docs/NNxxxHELP.md`.

## What the `Sources/` module is

Xcode playgrounds have a built-in sharing mechanism: a `Sources/` folder at the
playground root compiles into an auxiliary module that every page imports
**automatically** — pages never write an `import` for it. Consequences:

- **Everything a page touches must be `public`**: types, initializers, properties,
  methods. Swift's synthesized memberwise initializers are only `internal`, so each
  shared type needs an explicit `public init`.
- `Sources/` files may `import SwiftQiskitCore` (and `SwiftUI`, etc.) because the
  playground sets `buildActiveScheme='true'` — the `SwiftQiskit` scheme builds first.
- Shared code compiles once, so pages run faster than if the same code were inline.
- `Sources/` is **not** covered by `swift build` or the test suite; it only compiles
  inside Xcode.

## The shared types at a glance

| Type | File | Kind | Stateful? | `init` | Used by |
|---|---|---|---|---|---|
| `BlochVector` | `BlochVector.swift` | plain type | no | `init(_ state: StateVector)`, and `init(x:y:z:)` for mixed-state (sub-unit-length) vectors | 01, 02, 03, 04 (via `BlochExplorerView`), 08, 13, 14, 19, 20 |
| `BlochSphereView` | `BlochSphereView.swift` | view | no | `init(label:bloch:size:)` — `size` defaults to 220 | 01, 02, 03, 13, 14, 19, 20 |
| `BlochProjectionView` | `BlochProjectionView.swift` | view | no | `init(label:horizontal:vertical:verticalPointsDown:)` | 03 |
| `Bloch3DView` | `Bloch3DView.swift` | view | **yes** — `@State azimuth/elevation/lastDrag` | `init(label:bloch:size:)` — `size` defaults to 300 | 04 (via `BlochExplorerView`), 08 (static) |
| `BlochExplorerView` | `BlochExplorerView.swift` | view | **yes** — `@State theta/phi` | `init()` — no arguments | 04 |
| `CHSHChartView` | `CHSHChartView.swift` | view | no | `init(title:xRange:yRange:series:size:)` — `size` defaults to 480 × 300 | 15, 18, 21, 22 |

The *Kind* column is what makes `BlochVector`'s non-view status visible at a glance — it's
the only row usable with no `import SwiftUI` at all. *Stateful?* is what decides where a
type may live — see "Page-inline vs `Sources/`" below.

## Using each type

### `BlochVector`

The non-view type. Maps a single-qubit state |ψ⟩ = α|0⟩ + β|1⟩ to Bloch coordinates:

```swift
import SwiftQiskitCore

let qc = QuantumCircuit(qubits: 1)
qc.h(0)
let bloch = BlochVector(qc.run())   // preconditions dimension == 2
print(bloch.x, bloch.y, bloch.z)    // 1.0 0.0 0.0
print(bloch.theta, bloch.phi)       // acos(z), atan2(y, x) — π/2, 0
```

No `import SwiftUI` or live view needed — this compiles and runs on a console-only page.
`theta`/`phi` clamp/`atan2` their inputs, so a pole (x = y = 0) reports `φ = 0` by
convention, not because the azimuth is meaningful there (see
`Docs/02BLOCH2DHELP.md`'s reading notes for the worked example).

**`init(x:y:z:)`** — a second, additive initializer for vectors that don't come from a
normalized `StateVector` at all: a *mixed*-state Bloch vector r = (Tr(ρX), Tr(ρY), Tr(ρZ)),
which has |r| ≤ 1 rather than identically 1. Pages 19 and 20 build one of these whenever the
point they want to plot is the result of a density-matrix calculation or a shot-based
reconstruction, not a pure `StateVector`:

```swift
// page 19: a partially-dephased state, computed as a density matrix — no
// StateVector to hand at all, only its Pauli expectation values.
let mixed = BlochVector(x: 0.1074, y: 0.0, z: 0.9885)
```

`BlochSphereView` needed no change to support this — it already draws the arrow at the
vector's true length, so a sub-unit vector renders strictly inside the sphere, which is
exactly the point of pages 19/20's live views.

### `BlochSphereView`

Fixed 2D oblique projection (y → right, z → up, x foreshortened toward the viewer):

```swift
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

let bloch = BlochVector(QuantumCircuit(qubits: 1).run())   // |0⟩
PlaygroundPage.current.setLiveView(
    BlochSphereView(label: "|0⟩", bloch: bloch)   // size: defaults to 220
        .frame(width: 300, height: 340)
)
```

Page 03 passes `size: 300` for its single larger sphere. For how to read the drawing
(axes, foreshortening, the dashed equator), see `Docs/02BLOCH2DHELP.md`
§ "Reading the drawing".

### `BlochProjectionView`

Orthographic projection onto one coordinate plane. Unlike the other views its canvas
size is fixed internally (160 × 160), so its `init` has no `size:` parameter. It takes
*any* two labelled numbers, not just Bloch components:

```swift
BlochProjectionView(
    label: "x–y plane",
    horizontal: ("x", bloch.x),
    vertical: ("y", bloch.y)
    // verticalPointsDown: true   — set when the positive vertical axis
    //                              should point down on this canvas
)
```

For the panel semantics and why one of page 03's two panels sets
`verticalPointsDown: true`, see `Docs/03BLOCH2DPROJECTIONHELP.md`
§ "Reading the drawing".

### `Bloch3DView`

A rotatable 3D wireframe, perspective-projected through an orbit camera; dragging the
canvas orbits it. **Stateful** (`@State azimuth/elevation/lastDrag`), so it must live in
`Sources/` regardless of whether a page also drives it with sliders:

```swift
PlaygroundPage.current.setLiveView(
    Bloch3DView(label: "|+⟩", bloch: bloch, size: 320)   // size: defaults to 300
        .frame(width: 380, height: 420)
)
```

It can be used **static**, with no sliders — page 08 does exactly this, showing a fixed
qubit's Pauli expectation values on the same view page 04 drives interactively. For the
camera model (perspective divide, near/far wireframe opacity, the silhouette scale
factor, drag rates), see `Docs/04BLOCH3DHELP.md` § "Reading the drawing".

### `BlochExplorerView`

`Bloch3DView` plus live θ/φ sliders, rebuilding the state on every change:

```swift
PlaygroundPage.current.setLiveView(
    BlochExplorerView()
        .frame(width: 460, height: 640)
)
```

Takes **no parameters** — the starting θ = π/3 (60°), φ = π/4 (45°) are hardcoded in
`BlochExplorerView.swift`'s `init`; edit that file if you want the live view to start
somewhere else.

### `CHSHChartView`

A stateless 2D line/scatter chart, general enough for any `(x, y)` data:

```swift
PlaygroundPage.current.setLiveView(
    CHSHChartView(
        title: "E(θ)",
        xRange: 0...(2 * Double.pi), yRange: -1...1,
        series: [
            CHSHChartView.Series(label: "exact", color: .blue, points: exactPoints, isLine: true),
            CHSHChartView.Series(label: "sampled", color: .orange, points: sampledPoints, isLine: false)
        ]
        // size: defaults to 480 × 300
    )
    .frame(width: 480, height: 340)   // a bit taller than size — leaves room for the legend row
)
```

`isLine: true` draws a connected polyline (points assumed sorted by x); `isLine: false`
draws a scatter of dots. The dashed zero line only appears when `yRange` contains 0.

## Putting a live view on a playground page

The general recipe, independent of which shared view you use:

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
   propose a window-like size, so an unframed view can collapse or clip. Size the root to
   fit its content — e.g. page 02's 2 × 3 grid of 260-point cells plus padding sizes out
   to 560 × 940.
3. **Stateless views may be declared inline in the page.** A page-local `View` that holds
   only `let`s (page 02's `BlochGalleryView`, page 01's `CircuitStagesView`) can live in
   page code with no access modifiers.
4. **Stateful views must live in `Playgrounds.playground/Sources/`.** The Xcode 27 beta
   evaluator cannot expand the SDK 27 `@State` macro in page code; the `Sources/` module
   is compiled by the regular build system, where the macro works. Both `BlochExplorerView`
   and `Bloch3DView` are stateful for this reason — see "Page-inline vs `Sources/`" below.
   Details in `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds".
5. **Everything a page touches in `Sources/` must be explicitly `public`** — types,
   initializers, properties. Swift's synthesized memberwise inits are only `internal`,
   so shared views need a written-out `public init` (see `BlochSphereView.init`).
6. **The scheme must build.** Pages set `buildActiveScheme='true'`; `Sources/` may
   `import SwiftQiskitCore` (and `SwiftUI`) because the SwiftQiskit scheme builds first.
7. **Xcode 27 beta only (machine-specific):** any page importing SwiftUI may hit the
   missing-`libcups.dylib` evaluator bug; the shim recipe is in `PLAYGROUNDSUPPORT.md`
   § "Xcode 27 beta workarounds". Rerun it after Clean Build Folder — or after almost any
   run/build activity on beta 5, which wipes it much faster than a clean.

## Page-inline vs `Sources/`

The decision rule:

- A stateless helper used by exactly one page can stay **inline** in that page.
- Promote to `Sources/` once a second page needs it (`BlochSphereView`), or when the type
  is clearly general-purpose regardless of how many pages currently use it
  (`BlochProjectionView`, `CHSHChartView`).
- Anything using `@State` (or another SwiftUI macro) **must** live in `Sources/` — the
  page-code evaluator can't expand it. This is why `BlochExplorerView` lives in
  `Sources/` even though only page 04 uses it, and equally why `Bloch3DView` does: its
  own drag-to-orbit gesture is backed by `@State azimuth/elevation/lastDrag`, independent
  of whether a page drives it with additional sliders.

## Adding a shared type — checklist

1. One type per file, named after the type, in `Playgrounds.playground/Sources/`.
2. Make the type, its `init`, and anything a page reads `public`.
3. Keep the *lecture commentary* (the math walkthrough) in the page; keep the
   *implementation* here — pages reference the shared type by name.
4. Update `PLAYGROUNDSUPPORT.md`'s "Current shared code" and "Which pages use what"
   tables, and this guide's "at a glance" table, once the type has a second user (or is
   otherwise clearly general — see the rule above).

## Checking it compiles

`Sources/` isn't covered by `swift build` or `swift test`. To type-check it from the
command line:

```bash
xcrun swiftc -emit-module -module-name SwiftQiskitCore \
    -emit-module-path /tmp/sqkit/SwiftQiskitCore.swiftmodule \
    Sources/SwiftQiskitCore/**/*.swift
xcrun swiftc -typecheck -I /tmp/sqkit Playgrounds.playground/Sources/*.swift
```

This only proves the shared code compiles, not that a page runs correctly — and the
reverse trap is just as real: a page run only proves something if the page was actually
rebuilt. An untouched page can look "fixed" purely by reusing a stale build; if you're
checking whether an evaluator bug is still present, edit the page (even trivially) to
force a recompile before trusting a passing run.

## Troubleshooting

Failures below are shared-code failures, distinct from anything specific to one page's
math. The `@State` bug is SwiftUI-macro-specific; the libcups bug fires for any page that
imports SwiftUI; the rest apply to shared code generally.

- **Page won't run / no output at all** — the `SwiftQiskit` scheme must build first;
  check for compile errors in `Sources/SwiftQiskitCore/`.
- **`Cannot find 'X' in scope`** — the `Sources/` declaration (or its `init`) isn't
  `public`, or the file isn't in the playground's top-level `Sources/` folder.
- **A shared type's `init` "doesn't exist"** — Swift's synthesized memberwise
  initializers are only `internal`; every shared type needs an explicit `public init`.
- **`plugin for module 'SwiftUIMacros' not found`, or `'self' is immutable` at a
  mutation site** — an `@State` (or other SwiftUI-macro) view was declared or copied
  inline into a page. Move it to `Playgrounds.playground/Sources/` as a `public` type;
  the page should only instantiate it.
- **`Failed to load linked library cups of module SwiftUI`** — the Xcode 27 beta libcups
  bug; install the shim per `PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds" (a clean
  build deletes it, and on beta 5 so does ordinary run/build activity — re-copy
  immediately before each run).
- **Live view blank, collapsed, or clipped** — the root view passed to `setLiveView` is
  missing an explicit `.frame(width:height:)`.
- **`Bloch sphere is defined for single-qubit states` precondition** — `BlochVector` was
  handed a multi-qubit state; it only accepts `dimension == 2` (e.g.
  `QuantumCircuit(qubits: 1).run()`).
