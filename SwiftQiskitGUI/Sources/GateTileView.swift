//
//  GateTileView.swift
//  SwiftQiskitGUI
//
//  A single placed gate. Takes only the gate value + closures, not the whole
//  CircuitBuilder, so it only redraws when its own data changes.
//

import SwiftUI

struct GateTileView: View {
    let gate: PlacedGate
    let isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void
    var onThetaChange: (Double) -> Void

    @State private var showingParameters = false

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? Color.accentColor.opacity(0.25) : Color.accentColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
                if gate.kind.isParameterized {
                    showingParameters = true
                }
            }
            .popover(isPresented: $showingParameters) {
                ParameterPopover(theta: gate.kind.theta ?? 0, onChange: onThetaChange)
            }
            .contextMenu {
                Button("Delete", role: .destructive, action: onDelete)
            }
    }

    @ViewBuilder
    private var content: some View {
        if gate.kind.qubitSpan == 2 {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 14, height: 14)
        } else {
            Text(gate.kind.symbol)
                .font(.system(.body, design: .monospaced, weight: .semibold))
        }
    }
}

/// The target-qubit half of a placed CX gate (the control's row shows the dot via GateTileView).
struct CXTargetView: View {
    var body: some View {
        Circle()
            .stroke(Color.accentColor, lineWidth: 2)
            .overlay(
                ZStack {
                    Rectangle().fill(Color.accentColor).frame(width: 12, height: 2)
                    Rectangle().fill(Color.accentColor).frame(width: 2, height: 12)
                }
            )
            .frame(width: 20, height: 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyCellView: View {
    let isPendingControl: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .strokeBorder(
                isPendingControl ? Color.orange : Color.secondary.opacity(0.25),
                lineWidth: isPendingControl ? 2 : 1
            )
            .background(Color.secondary.opacity(0.03))
            .contentShape(Rectangle())
    }
}
