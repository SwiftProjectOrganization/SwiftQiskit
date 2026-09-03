//
//  CircuitGridView.swift
//  SwiftQiskitGUI
//
//  Renders the circuit as a grid of qubit wires x columns, and handles
//  tap-to-place: arm a gate in the palette, then tap an empty cell. Two-qubit
//  gates (CX) need a control tap followed by a target tap in the same column.
//

import SwiftUI

struct CircuitGridView: View {
    var builder: CircuitBuilder
    @Binding var armedGate: GateKind?

    @State private var pendingControl: (column: Int, qubit: Int)?
    @State private var selectedGateID: UUID?

    private let cellSize: CGFloat = 44

    var body: some View {
        let columns = max(builder.columnCount() + 1, 4)

        ScrollView([.horizontal, .vertical]) {
            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(0..<builder.qubitCount, id: \.self) { qubit in
                    GridRow {
                        Text("q\(qubit)")
                            .font(.caption.monospaced())
                            .frame(width: 28, alignment: .trailing)

                        ForEach(0..<columns, id: \.self) { column in
                            cell(column: column, qubit: qubit)
                        }
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func cell(column: Int, qubit: Int) -> some View {
        if let gate = builder.gate(atColumn: column, qubit: qubit) {
            occupiedCell(gate: gate, qubit: qubit)
                .frame(width: cellSize, height: cellSize)
        } else {
            EmptyCellView(isPendingControl: pendingControl?.column == column && pendingControl?.qubit == qubit)
                .frame(width: cellSize, height: cellSize)
                .onTapGesture { handleTap(column: column, qubit: qubit) }
        }
    }

    @ViewBuilder
    private func occupiedCell(gate: PlacedGate, qubit: Int) -> some View {
        let isPrimary = gate.qubits.first == qubit

        if isPrimary {
            GateTileView(
                gate: gate,
                isSelected: selectedGateID == gate.id,
                onSelect: { selectedGateID = gate.id },
                onDelete: { deleteGate(gate) },
                onThetaChange: { builder.updateTheta(id: gate.id, theta: $0) }
            )
        } else {
            CXTargetView()
                .contentShape(Rectangle())
                .onTapGesture { deleteGate(gate) }
        }
    }

    private func deleteGate(_ gate: PlacedGate) {
        builder.remove(id: gate.id)
        if selectedGateID == gate.id { selectedGateID = nil }
    }

    private func handleTap(column: Int, qubit: Int) {
        guard let armed = armedGate else { return }

        guard armed.qubitSpan == 2 else {
            builder.place(armed, qubits: [qubit], column: column)
            return
        }

        guard let pending = pendingControl else {
            pendingControl = (column, qubit)
            return
        }

        guard pending.column == column, pending.qubit != qubit else {
            pendingControl = (column, qubit)
            return
        }

        if builder.place(armed, qubits: [pending.qubit, qubit], column: column) {
            pendingControl = nil
        }
    }
}
