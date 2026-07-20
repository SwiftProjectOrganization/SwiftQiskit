# Status and TODO

Project status, feature status, and the core-library roadmap for SwiftQiskit,
plus this fork's working TODO list.

## Project Status

**SwiftQiskit is currently in an early experimental stage (v0.1).**

- Core quantum simulation is implemented
- API is subject to change
- Performance is not yet optimized
- GUI tools are optional and under development

The project is actively evolving, and major features are planned.

## What Works (v0.1)

- QuantumCircuit abstraction
- Single-qubit gates: H, X, Z
- Two-qubit entanglement (CNOT – limited v0.1)
- StateVector simulation
- Measurement with shots & counts
- Bell State example
- Unit tests for correctness

## Roadmap

- [ ] General multi-qubit CNOT support
- [ ] Additional gates (Y, Phase, Rotation gates)
- [ ] Circuit visualization (ASCII / SwiftUI)
- [ ] Noise models
- [ ] Performance optimizations
- [ ] Stable public API (v1.0)

## Bloch sphere playground pages (this fork)

- [x] Try a 3D Bloch sphere (e.g. SceneKit/RealityKit or a perspective-projected
      SwiftUI Canvas) as an alternative to the current 2D projections in
      `Playgrounds.playground/Sources/BlochSphereView.swift`.
      → `Bloch3DView` (perspective-projected SwiftUI Canvas with drag-to-orbit),
      used by page `07BlochSphere3D`.
- [x] Add constrained live sliders for the spherical angles θ and φ to the
      Bloch sphere live display (θ ∈ [0, π], φ ∈ [0, 2π)), updating the
      rendered state vector interactively.
      → page `07BlochSphere3D`; the θ/φ parametrization keeps |α|² + |β|² = 1
      for every slider position, so the two sliders are independent.
