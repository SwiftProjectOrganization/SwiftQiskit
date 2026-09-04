//
//  CircuitLayout.swift
//  SwiftQiskitGUI
//
//  Pure geometry for the circuit diagram: turns (column, qubit) into points so
//  the wire layer (CircuitWiresView) and the interactive gate layer
//  (CircuitGridView) can't drift apart.
//

import Foundation
import CoreGraphics

struct CircuitLayout {
    var cellSize: CGFloat = 44
    var columnSpacing: CGFloat = 8
    var rowSpacing: CGFloat = 16
    var labelWidth: CGFloat = 32
    var labelGap: CGFloat = 8
    var padding: CGFloat = 16

    private var columnStride: CGFloat { cellSize + columnSpacing }
    private var rowStride: CGFloat { cellSize + rowSpacing }
    private var originX: CGFloat { padding + labelWidth + labelGap }

    func center(column: Int, qubit: Int) -> CGPoint {
        CGPoint(
            x: originX + CGFloat(column) * columnStride + cellSize / 2,
            y: padding + CGFloat(qubit) * rowStride + cellSize / 2
        )
    }

    func wireY(_ qubit: Int) -> CGFloat {
        center(column: 0, qubit: qubit).y
    }

    func wireXRange(columns: Int) -> ClosedRange<CGFloat> {
        let start = originX
        let end = originX + CGFloat(max(columns, 1)) * columnStride - columnSpacing
        return start...max(start, end)
    }

    func canvasSize(columns: Int, qubits: Int) -> CGSize {
        CGSize(
            width: originX + CGFloat(max(columns, 1)) * columnStride - columnSpacing + padding,
            height: padding + CGFloat(max(qubits, 1)) * rowStride - rowSpacing + padding
        )
    }
}
