# SwiftQiskitGUI — help & reference

Implementation reference, extension guide, and troubleshooting for `SwiftQiskitGUI`. The
user-facing walkthrough (how to actually use the app) is `SwiftQiskitDocs/GUITUTORIAL.md`; this
document is its `PLAYGROUNDSUPPORT.md`-style companion — how it's built, not how to drive
it.

## Why a separate front-end model exists

`QuantumCircuit` (`Sources/SwiftQiskitCore/Circuit/QuantumCircuit.swift`) records each
operation as only the resulting full-dimension `Matrix` — no gate name, no target qubit,
no column. That's enough to `run()`/`measure(shots:)`, but not enough to draw or edit a
circuit diagram after the fact: there's nothing to inspect. So the GUI keeps its own
record of *placed* gates and replays them onto a fresh `QuantumCircuit` whenever it needs
to run — the same "keep UI-only concerns out of Core" split the playground uses for Bloch
math and charts. No `SwiftQiskitCore` changes were needed or made for this feature.

## File map (`SwiftQiskitGUI/Sources/`)

| File | Contents |
|---|---|
| `CircuitModel.swift` | `GateKind`, `PlacedGate`, `CircuitBuilder` — the model, no SwiftUI import |
| `CircuitBuilderView.swift` | Top-level 3-pane layout; owns the `CircuitBuilder` and `armedGate` state |
| `GatePaletteView.swift` | Gate buttons, grouped by category; arms a `GateKind` |
| `CircuitGridView.swift` | The qubit-wire grid; tap-to-place and the CX two-tap state machine |
| `GateTileView.swift` | `GateTileView` (a placed single-qubit or CX-control tile), `CXTargetView` (the ⊕ half of a CX), `EmptyCellView` |
| `ParameterPopover.swift` | θ slider for `.p/.rx/.ry/.rz` tiles |
| `ResultsView.swift` | Live state vector + shots/Measure/histogram |
| `HistogramView.swift` | Bar chart of `SimulationResult` counts |
| `ContentView.swift` | Thin wrapper — just returns `CircuitBuilderView()` |
| `main.swift` | `@main App`, unchanged by this feature |

## The model (`CircuitModel.swift`)

```swift
public enum GateKind: Equatable, Hashable {
    case h, x, y, z, s, sdg, t, tdg
    case p(Double), rx(Double), ry(Double), rz(Double)
    case cx
    // .symbol, .qubitSpan (1, or 2 for .cx), .isParameterized, .theta, .withTheta(_:)
}

public struct PlacedGate: Identifiable, Equatable {
    public let id: UUID
    public var kind: GateKind
    public var qubits: [Int]   // 1 entry, or [control, target] for .cx
    public var column: Int
}

@Observable public final class CircuitBuilder {
    public var qubitCount: Int   // clamped 1...8; shrinking drops now-out-of-range gates
    public var gates: [PlacedGate]

    public func place(_ kind: GateKind, qubits: [Int], column: Int) -> Bool  // false if out of range or occupied
    public func remove(id: UUID)
    public func updateTheta(id: UUID, theta: Double)
    public func clear()
    public func buildCircuit() -> QuantumCircuit   // sorts by column, replays onto a fresh circuit
}
```

`CircuitBuilder` is `@Observable` (not `ObservableObject`/`@Published`) — this project's
CLAUDE.md asks to avoid the Combine framework, and `@Observable` is the modern
replacement. That's *why* the package's minimum deployment target is `.macOS(.v14)`
(bumped from `.v13` when this feature was added): `@Observable` and the two-parameter
`onChange(of:initial:_:)` used in `ParameterPopover.swift` both need macOS 14. If you ever
need to drop back below macOS 14, you'd have to fall back to `ObservableObject`/`@Published`
and the older single-parameter `onChange(of:)` instead — a real trade-off, not a style
choice.

`qubitCount`'s clamp-and-filter lives in its own `didSet`, written carefully to avoid
infinite recursion: it only re-assigns `qubitCount` (which would re-trigger `didSet`) when
the clamped value actually differs from the current one, and returns immediately after
so the gate-filtering line only runs once, against the already-clamped value.

## Interaction model (`CircuitGridView.swift`)

Placement is tap-to-arm-then-tap-cell, not drag-and-drop (v1 scope — see "Not implemented"
below):

- Single-qubit gate armed → tapping any empty cell calls
  `builder.place(kind, qubits: [qubit], column: column)` immediately.
- `.cx` armed → the **first** tap on an empty cell sets `pendingControl = (column, qubit)`
  (view-local `@State`, not part of `CircuitBuilder` — it's ephemeral UI state, not circuit
  data). The **second** tap must be in the *same column*, a *different* qubit row; it
  commits `builder.place(.cx, qubits: [control, target], column:)`. A tap that breaks
  either rule resets `pendingControl` to the new cell rather than erroring.
- A `PlacedGate` is drawn once, at its "primary" qubit (`gate.qubits.first`) — that's where
  `GateTileView` renders (the symbol, or a filled dot for CX's control). The other qubit(s)
  of a multi-qubit gate render `CXTargetView` (the ⊕ glyph) instead. Deleting works from
  either half.

## Extending

**Adding a new gate kind:**
1. Add a case to `GateKind` in `CircuitModel.swift`, plus its `symbol`/`qubitSpan` (and
   `theta`/`withTheta` if parameterized).
2. Add the matching case in `CircuitBuilder.apply(_:to:)`, calling the corresponding
   `QuantumCircuit` method.
3. Add a button for it in `GatePaletteView`'s `section(_:gates:)` calls.

No changes needed anywhere else — `CircuitGridView`/`GateTileView` render any `GateKind`
generically via `.symbol`/`.qubitSpan`.

**Adding a chart type / result view:** follow `HistogramView.swift`'s pattern (a small,
stateless `View` taking a value type, not the whole `CircuitBuilder`) and wire it into
`ResultsView.swift`.

## Not implemented (v1 scope)

- **No drag-and-drop.** Tap-to-arm-then-tap-cell was chosen over `onDrag`/`dropDestination`
  for simplicity; revisit if it feels clunky in practice.
- **No wire connecting a CX's control and target visually** — they're drawn as a dot and a
  ⊕ in the same column with nothing joining them, unlike a textbook circuit diagram. Only a
  glyph convention, not a real limitation of the model (`PlacedGate.qubits` already has
  both endpoints) — a future pass could draw the connecting line with an overlay `Canvas`.
- **No persistence.** Closing the app discards the circuit; there's no save/load/export.
- **No undo.** `Clear` and qubit-count shrinking are immediate and irreversible within a
  session.

## Testing

`Tests/SwiftQiskitGUITests/CircuitBuilderTests.swift` covers `CircuitBuilder`'s logic only
(no view tests — SwiftUI views aren't unit-testable here): Bell-state replay via
`buildCircuit()`, occupied/out-of-range placement rejection, qubit-count clamping and
gate-dropping on shrink, `updateTheta`, and `clear`. Run via `swift test` or the
**`SwiftQiskit-Package`** Xcode scheme — the plain `SwiftQiskit` scheme's test plan has no
test targets in it (a pre-existing gotcha, also noted for `SwiftQiskitCoreTests`).

## Troubleshooting

- **Clicking a gate button does nothing.** Check whether it's already armed (tinted with
  the accent color) — clicking an armed gate again disarms it instead of re-arming it.
- **Tapping a grid cell does nothing.** Nothing is armed, or that qubit is already occupied
  at that column — occupied cells render a tile, not the dashed `EmptyCellView`, so if you
  see a tile there, that's why.
- **CX won't place.** Both taps must land in the *same column*; a stray tap elsewhere resets
  the pending control rather than placing the gate. Check for the orange border to confirm
  a control is pending before the second tap.
- **State Vector panel looks stale.** It shouldn't — `ResultsView.body` calls
  `builder.buildCircuit().run()` fresh on every render. If it really doesn't update, that's
  a bug, not expected behavior (unlike `PlaygroundDocs/05GATESHELP.md`'s "nothing prints" case, which
  *is* expected there).
- **App won't build on macOS 13.** Expected — the minimum deployment target is now
  `.macOS(.v14)` (see "The model" above). Either update the deployment target further only
  forward, or don't build this target on macOS 13.
- **Measure gives a different split every time.** Expected; `measure(shots:)` is
  probabilistic, same as everywhere else in this project (`PlaygroundDocs/07ENTANGLEMENTHELP.md`
  etc.) — re-run or raise the shot count for a tighter distribution.
