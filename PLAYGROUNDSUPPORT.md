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
│   └── BlochProjectionView.swift
└── Pages/
    ├── 01BellExample.xcplaygroundpage
    ├── ...
    ├── 05BlochSphere.xcplaygroundpage
    └── 06BlochSphere_02.xcplaygroundpage
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

## Which pages use what

| Page | Shared code used |
|---|---|
| `05BlochSphere` | `BlochVector`, `BlochSphereView` (2×2 gallery of \|0⟩ \|1⟩ \|+⟩ \|−⟩) |
| `06BlochSphere_02` | `BlochVector`, `BlochSphereView` (size 300), two `BlochProjectionView`s |

## Adding shared code

- One type per file, named after the type, in `Playgrounds.playground/Sources/`.
- Make the type, its `init`, and anything pages read `public`.
- Keep the *lecture commentary* (the math walkthrough) in the page; keep the
  *implementation* here. Pages should reference the shared type by name so readers
  know where to look.
- Helpers used by a single page can stay inline in that page — only promote code to
  `Sources/` once a second page needs it (or it is clearly general, like
  `BlochProjectionView`).
