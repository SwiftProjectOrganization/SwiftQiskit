//
//  GatePaletteView.swift
//  SwiftQiskitGUI
//
//  Tap a gate to arm it, then tap a wire in the CircuitGridView to place it.
//

import SwiftUI

struct GatePaletteView: View {
    @Binding var armedGate: GateKind?

    private let defaultAngle = Double.pi / 2

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gates")
                .font(.headline)

            section("Pauli / Hadamard", gates: [.h, .x, .y, .z])
            section("Phase", gates: [.s, .sdg, .t, .tdg])
            section("Rotation (θ = π/2)", gates: [.p(defaultAngle), .rx(defaultAngle), .ry(defaultAngle), .rz(defaultAngle)])
            section("Multi-qubit", gates: [.cx])

            if let armed = armedGate {
                Text(hint(for: armed))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func hint(for gate: GateKind) -> String {
        gate.qubitSpan == 2
            ? "Tap a control qubit, then a target qubit in the same column."
            : "Tap a wire to place \(gate.symbol)."
    }

    private func section(_ title: String, gates: [GateKind]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 6) {
                ForEach(gates, id: \.self) { gate in
                    gateButton(gate)
                }
            }
        }
    }

    private func gateButton(_ gate: GateKind) -> some View {
        let isArmed = armedGate == gate
        return Button {
            armedGate = isArmed ? nil : gate
        } label: {
            Text(gate.symbol)
                .font(.system(.body, design: .monospaced, weight: .semibold))
                .frame(width: 40, height: 32)
        }
        .buttonStyle(.bordered)
        .tint(isArmed ? .accentColor : .secondary)
    }
}
