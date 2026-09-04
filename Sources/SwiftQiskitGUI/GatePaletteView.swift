//
//  GatePaletteView.swift
//  SwiftQiskitGUI
//
//  Tap a gate to arm it, then tap a wire in the CircuitGridView to place it.
//  Two layouts share the same gate buttons: `.sidebar` (a vertical column of
//  labeled sections, used on macOS/iPad) and `.strip` (a single horizontal
//  scroller with unlabeled sections, used on the compact iPhone layout).
//

import SwiftUI

struct GatePaletteView: View {
    enum Layout {
        case sidebar
        case strip
    }

    @Binding var armedGate: GateKind?
    var layout: Layout = .sidebar

    private let defaultAngle = Double.pi / 2

    private var sections: [(title: String, gates: [GateKind])] {
        [
            ("Pauli / Hadamard", [.h, .x, .y, .z]),
            ("Phase", [.s, .sdg, .t, .tdg]),
            ("Rotation (θ = π/2)", [.p(defaultAngle), .rx(defaultAngle), .ry(defaultAngle), .rz(defaultAngle)]),
            ("Multi-qubit", [.cx])
        ]
    }

    var body: some View {
        switch layout {
        case .sidebar: sidebarBody
        case .strip: stripBody
        }
    }

    private var sidebarBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gates")
                .font(.headline)

            ForEach(sections, id: \.title) { section in
                sidebarSection(section.title, gates: section.gates)
            }

            if let armed = armedGate {
                Text(hint(for: armed))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var stripBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(sections, id: \.title) { section in
                        HStack(spacing: 6) {
                            ForEach(section.gates, id: \.self) { gate in
                                gateButton(gate)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            if let armed = armedGate {
                Text(hint(for: armed))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    private func hint(for gate: GateKind) -> String {
        gate.qubitSpan == 2
            ? "Tap a control qubit, then a target qubit in the same column."
            : "Tap a wire to place \(gate.symbol)."
    }

    private func sidebarSection(_ title: String, gates: [GateKind]) -> some View {
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
