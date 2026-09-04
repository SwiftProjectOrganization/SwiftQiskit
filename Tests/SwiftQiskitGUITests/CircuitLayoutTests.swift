import Testing
import CoreGraphics
@testable import SwiftQiskitGUI

@Suite("CircuitLayout")
struct CircuitLayoutTests {

    @Test("centers advance by cellSize + spacing on each axis")
    func centersAdvanceByStride() {
        let layout = CircuitLayout()

        let a = layout.center(column: 0, qubit: 0)
        let right = layout.center(column: 1, qubit: 0)
        let down = layout.center(column: 0, qubit: 1)

        #expect(abs((right.x - a.x) - (layout.cellSize + layout.columnSpacing)) < 1e-9)
        #expect(abs((down.y - a.y) - (layout.cellSize + layout.rowSpacing)) < 1e-9)
        #expect(right.y == a.y)
        #expect(down.x == a.x)
    }

    @Test("wireY matches the y-coordinate of every center on that row")
    func wireYMatchesCenters() {
        let layout = CircuitLayout()

        for qubit in 0..<4 {
            for column in 0..<4 {
                #expect(layout.wireY(qubit) == layout.center(column: column, qubit: qubit).y)
            }
        }
    }

    @Test("canvasSize grows with both column and qubit counts")
    func canvasSizeGrows() {
        let layout = CircuitLayout()

        let small = layout.canvasSize(columns: 2, qubits: 2)
        let moreColumns = layout.canvasSize(columns: 4, qubits: 2)
        let moreQubits = layout.canvasSize(columns: 2, qubits: 4)

        #expect(moreColumns.width > small.width)
        #expect(moreColumns.height == small.height)
        #expect(moreQubits.height > small.height)
        #expect(moreQubits.width == small.width)
    }
}
