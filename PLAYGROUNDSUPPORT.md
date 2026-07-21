# Playground Support Code

How code is shared between the pages of `Playgrounds.playground`.

## How sharing works

Xcode playgrounds have a built-in mechanism for shared code: a `Sources/` folder at the
playground root.

```text
Playgrounds.playground/
├── Sources/                  ← shared code (this document)
│   ├── BlochVector.swift
│   ├── BlochSphereView.swift
│   ├── BlochProjectionView.swift
│   ├── Bloch3DView.swift
│   └── BlochExplorerView.swift
└── Pages/
    ├── 01BellExample.xcplaygroundpage
    ├── ...
    ├── 05BlochSphere2D.xcplaygroundpage
    ├── 06BlochSphere2D+Projections.xcplaygroundpage
    └── 07BlochSphere3D.xcplaygroundpage
```

Xcode compiles `Sources/` into an auxiliary module that every page imports
**automatically** — pages never write an `import` for it. The rules that follow from
this:

- **Everything a page touches must be `public`**: types, initializers, properties, and
  methods. Swift's synthesized memberwise initializers are only `internal`, so each
  shared type needs an explicit `public init`.
- Sources files may `import SwiftQiskitCore` (and `SwiftUI`, etc.) because the playground
  sets `buildActiveScheme='true'` — the SwiftQiskit scheme is built before pages run.
- Shared code compiles once, so pages run faster than when the same code is inline.
- Like all playground code, `Sources/` is **not** covered by `swift build` or the test
  suite; it only compiles inside Xcode. To type-check it from the command line:

  ```bash
  xcrun swiftc -emit-module -module-name SwiftQiskitCore \
      -emit-module-path /tmp/sqkit/SwiftQiskitCore.swiftmodule \
      Sources/SwiftQiskitCore/**/*.swift
  xcrun swiftc -typecheck -I /tmp/sqkit Playgrounds.playground/Sources/*.swift
  ```

## Current shared code

### `BlochVector.swift`

Maps a single-qubit `StateVector` |ψ⟩ = α|0⟩ + β|1⟩ to Bloch-sphere coordinates
(up to global phase):

- x = 2·Re(ᾱβ), y = 2·Im(ᾱβ), z = |α|² − |β|²
- `theta` — polar angle from the |0⟩ pole, `phi` — azimuth in the XY plane

```swift
public init(_ state: StateVector)   // preconditions dimension == 2
```

### `BlochSphereView.swift`

SwiftUI view drawing the Bloch sphere as a 2D orthographic projection
(y → right, z → up, x → toward the viewer, foreshortened) with axes, the state
vector arrow, and a numeric readout.

```swift
public init(label: String, bloch: BlochVector, size: CGFloat = 220)
```

`size` is the side length of the square canvas — page 05 uses the default, page 06
uses `300`.

### `BlochProjectionView.swift`

SwiftUI view drawing the orthographic projection of a Bloch vector onto one
coordinate plane (a unit circle with the in-plane arrow).

```swift
public init(
    label: String,
    horizontal: (label: String, value: Double),
    vertical: (label: String, value: Double),
    verticalPointsDown: Bool = false
)
```

Set `verticalPointsDown` when the positive vertical axis should point down on the
canvas (e.g. the x-axis when looking down from +z).

### `Bloch3DView.swift`

SwiftUI view drawing the Bloch sphere as a rotatable 3D wireframe: latitude/longitude
circles are perspective-projected through an orbit camera (azimuth/elevation held in
`@State`), the far hemisphere is drawn dimmer as a depth cue, and dragging the canvas
orbits the camera. Shows axes, the state vector arrow with dashed drop lines to the
equator plane, and the same numeric readout as `BlochSphereView`.

```swift
public init(label: String, bloch: BlochVector, size: CGFloat = 300)
```

### `BlochExplorerView.swift`

Interactive wrapper around `Bloch3DView`: live sliders for θ ∈ [0, π] and φ ∈ [0, 2π)
rebuild |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩ on every change, with a numeric readout
that includes |α|² + |β|² (identically 1 — the parametrization keeps the state
normalized, which is why the two sliders are independent).

```swift
public init()   // starts at θ = 60°, φ = 45°
```

Unlike the other views, this one is in Sources out of necessity, not reuse: the
Xcode 27 beta playground evaluator cannot expand the SDK 27 `@State` macro in page
code, while the Sources module is compiled by the regular build system, where the
macro works — see "Xcode 27 beta workarounds" below.

## Which pages use what

| Page | Shared code used |
|---|---|
| `05BlochSphere2D` | `BlochVector`, `BlochSphereView` (2×2 gallery of \|0⟩ \|1⟩ \|+⟩ \|−⟩) |
| `06BlochSphere2D+Projections` | `BlochVector`, `BlochSphereView` (size 300), two `BlochProjectionView`s |
| `07BlochSphere3D` | `BlochExplorerView` (which uses `BlochVector` + `Bloch3DView`) |

## Xcode 27 beta workarounds

As of Xcode 27.0 beta (27A5209h, July 2026), the playground expression evaluator has two
bugs that break SwiftUI pages. Both are toolchain issues, not project issues; remove the
workarounds once a fixed Xcode ships. **Both bugs verified still present in beta 4
(27A5228h) on 2026-07-20** — by running page 05 with the shims removed (bug 1) and a page
with an inline `@State` view (bug 2).

**The bugs appear to be machine-specific.** On 2026-07-20 a fresh clone on an M3 Mac with
the same Xcode 27 beta 4 and macOS 27 beta 4 ran the SwiftUI pages with no shim at all
(bug 1 absent; bug 2 untested there — page 07 uses the `Sources/` view, so it does not
exercise inline `@State`). The affected machine is an A18-based Mac that had earlier
Xcode 27 betas installed.

**Cache-wipe result (2026-07-20, affected machine):** deleting the project's DerivedData,
`ModuleCache.noindex`, and `~/Library/Caches/com.apple.dt.Xcode` (then restarting Xcode)
*narrowed* bug 1 rather than fixing it. Shim-free, pages that import SwiftUI and only
instantiate `Sources/` views now run; but a page that *declares a View type inline*
still fails with the cups error at the evaluator's link stage. The shim fixes that case
too — the error's search-path trace explicitly lists the three DerivedData product
directories, confirming the shim locations.

Bug 2 also survives the wipe, with a **changed symptom**: instead of "plugin for module
'SwiftUIMacros' not found", an inline `@State` view now fails with
`left side of mutating operator isn't mutable: 'self' is immutable` at the mutation site
(e.g. `taps += 1` in a Button action). The evaluator expands the property as plain
storage without State's nonmutating setter — same conclusion, stateful views must stay
in `Sources/`.

Note the wipe brought the affected machine to parity with the M3 on everything tested on
both (Bloch pages, shim-free). The residual failures only involve *inline page code*,
which was never exercised on the M3 — so they may be universal Xcode 27 beta 4 evaluator
bugs, not machine-specific ones. To find out, run a page with an inline `@State` view on
another Mac; if it fails there too, this belongs in a Feedback to Apple.

### 1. `Failed to load linked library cups of module SwiftUI`

The macOS 27 SDK's `CUPS` clang module declares `link "cups"`, and the evaluator tries to
`dlopen` a literal `libcups.dylib` — which only exists inside the dyld shared cache (as
`libcups.2.dylib`), not on disk, so every page importing SwiftUI fails to run. Note the bug
is specific to the evaluator's loading path: a plain-process `dlopen("libcups.dylib")`
succeeds via the shared cache, so a dlopen test outside the evaluator does not prove the
bug is fixed — only an actual page run does.

**Workaround:** build a shim dylib that re-exports the real library and drop it into the
playground product directories in DerivedData (which are on the evaluator's search path):

```bash
echo '' > /tmp/empty.c
xcrun clang -dynamiclib /tmp/empty.c -o /tmp/libcups.dylib -Wl,-reexport-lcups
DD=~/Library/Developer/Xcode/DerivedData/SwiftQiskit-*/Build/Intermediates.noindex
cp /tmp/libcups.dylib $DD/Playgrounds/Playgrounds/Products/Debug/
cp /tmp/libcups.dylib $DD/Playgrounds/Products/Debug/
cp /tmp/libcups.dylib $DD/Playgrounds/Products/Debug/PackageFrameworks/
```

**Clean Build Folder deletes the shim**, and playground rebuilds can regenerate the whole
products tree (which also removes it) — rerun the copies whenever the error comes back. If the
same error names a different library (`z` and `resolv` are also cache-only), the identical
recipe works with `-reexport-l<name>`.

### 2. `plugin for module 'SwiftUIMacros' not found`

In SDK 27, SwiftUI's `@State` is a macro implemented in a compiler plugin, and the
evaluator cannot load that plugin for code typed directly in a *page*. Code in `Sources/`
is compiled by the regular build system, where the macro expands fine.

**Workaround:** any view using `@State` (or other SwiftUI macros) must live in `Sources/`
as a `public` type; the page only instantiates it. This is why `BlochExplorerView` is in
`Sources/` even though only page `07BlochSphere3D` uses it. Also note the SDK 27 `@State`
init pattern: if a view sets `@State` values in its `init`, drop the initial value at the
declaration and assign only in the `init`.

## Adding shared code

- One type per file, named after the type, in `Playgrounds.playground/Sources/`.
- Make the type, its `init`, and anything pages read `public`.
- Keep the *lecture commentary* (the math walkthrough) in the page; keep the
  *implementation* here. Pages should reference the shared type by name so readers
  know where to look.
- Helpers used by a single page can stay inline in that page — only promote code to
  `Sources/` once a second page needs it (or it is clearly general, like
  `BlochProjectionView`).
