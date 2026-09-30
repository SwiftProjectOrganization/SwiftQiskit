import SwiftUI
import SwiftQiskit

/// A circuit-aligned drawing of a `TensorNetwork`: qubit wires run left to right, `|0⟩`
/// caps on the left, open output legs on the right, and every gate sits in its own time
/// column as a labelled box on the wires it touches. Stateless (no `@State`), so — like
/// `CHSHChartView` — it can be declared and instantiated directly in page code.
public struct TensorNetworkView: View {

    let network: TensorNetwork
    let title: String
    let size: CGSize

    private let leftMargin: CGFloat = 70
    private let rightMargin: CGFloat = 60
    private let bottomMargin: CGFloat = 20
    private let hasPhaseNode: Bool
    private var topMargin: CGFloat { hasPhaseNode ? 55 : 28 }

    public init(_ network: TensorNetwork, title: String = "Tensor Network", size: CGSize? = nil) {
        self.network = network
        self.title = title
        self.hasPhaseNode = network.nodes.contains {
            if case .gate(let name) = $0.kind { return name == "phase" }
            return false
        }

        let columnSpan = max(network.columns - 1, 1)
        let rowSpan = max(network.qubits - 1, 1)
        let defaultWidth = 70 + CGFloat(columnSpan) * 80 + 60
        let defaultHeight = (hasPhaseNode ? 55 : 28) + CGFloat(rowSpan) * 56 + 20
        self.size = size ?? CGSize(width: defaultWidth, height: defaultHeight)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Canvas { context, canvasSize in
                draw(context, canvasSize: canvasSize)
            }
            .frame(width: size.width, height: size.height)

            legend
        }
    }

    // MARK: - Drawing

    private func draw(_ context: GraphicsContext, canvasSize: CGSize) {
        let columns = max(network.columns - 1, 1)
        let rows = max(network.qubits - 1, 1)
        let columnSpacing = (canvasSize.width - leftMargin - rightMargin) / CGFloat(columns)
        let rowSpacing = network.qubits > 1
            ? (canvasSize.height - topMargin - bottomMargin) / CGFloat(rows)
            : 0

        let point: (Int, Int) -> CGPoint = { column, qubit in
            CGPoint(x: leftMargin + CGFloat(column) * columnSpacing,
                    y: topMargin + CGFloat(qubit) * rowSpacing)
        }

        drawWires(context, point: point)

        for node in network.nodes {
            guard case .gate(let name) = node.kind else { continue }
            if node.qubits.isEmpty {
                drawPhaseNode(context, name: name, column: node.column, columnSpacing: columnSpacing)
            } else if node.qubits.count == 1 {
                drawGateBox(context, label: name, center: point(node.column, node.qubits[0]))
            } else {
                drawMultiQubitBox(context, node: node, point: point)
            }
        }

        for node in network.nodes {
            switch node.kind {
            case .input:
                drawInputCap(context, at: point(node.column, node.qubits[0]))
            case .output:
                drawOutputLeg(context, at: point(node.column, node.qubits[0]), label: "q\(node.qubits[0])")
            case .gate:
                break
            }
        }
    }

    private func drawWires(_ context: GraphicsContext, point: (Int, Int) -> CGPoint) {
        let nodesByID = Dictionary(uniqueKeysWithValues: network.nodes.map { ($0.id, $0) })
        for edge in network.edges {
            guard let from = nodesByID[edge.from], let to = nodesByID[edge.to] else { continue }
            var wire = Path()
            wire.move(to: point(from.column, edge.qubit))
            wire.addLine(to: point(to.column, edge.qubit))
            context.stroke(wire, with: .color(.secondary), lineWidth: 1.5)
        }
    }

    private func drawInputCap(_ context: GraphicsContext, at p: CGPoint) {
        context.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(.primary))
        context.draw(Text("|0⟩").font(.caption2), at: CGPoint(x: p.x - 22, y: p.y))
    }

    private func drawOutputLeg(_ context: GraphicsContext, at p: CGPoint, label: String) {
        context.draw(Text(label).font(.caption2), at: CGPoint(x: p.x + 24, y: p.y))
    }

    private func drawGateBox(_ context: GraphicsContext, label: String, center: CGPoint) {
        let side: CGFloat = 34
        let rect = CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
        let box = Path(roundedRect: rect, cornerRadius: 6)
        context.fill(box, with: .color(.blue.opacity(0.15)))
        context.stroke(box, with: .color(.blue), lineWidth: 1.5)
        context.draw(Text(label).font(.caption2), at: center)
    }

    private func drawMultiQubitBox(_ context: GraphicsContext, node: TensorNetwork.Node, point: (Int, Int) -> CGPoint) {
        let minRow = node.qubits.min()!
        let maxRow = node.qubits.max()!
        let top = point(node.column, minRow)
        let bottom = point(node.column, maxRow)
        let width: CGFloat = 46
        let pad: CGFloat = 14
        let rect = CGRect(x: top.x - width / 2, y: top.y - pad, width: width, height: (bottom.y - top.y) + 2 * pad)

        let box = Path(roundedRect: rect, cornerRadius: 8)
        context.fill(box, with: .color(.blue.opacity(0.15)))
        context.stroke(box, with: .color(.blue), lineWidth: 1.5)

        // Wires that merely cross this gate's row span without being one of its legs are
        // redrawn dashed over the box, to show they are *not* connected to it.
        for row in minRow...maxRow where !node.qubits.contains(row) {
            let y = point(node.column, row).y
            var crossing = Path()
            crossing.move(to: CGPoint(x: rect.minX, y: y))
            crossing.addLine(to: CGPoint(x: rect.maxX, y: y))
            context.stroke(crossing, with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }

        for q in node.qubits {
            let p = point(node.column, q)
            context.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)), with: .color(.blue))
        }

        if case .gate(let name) = node.kind {
            context.draw(Text(name).font(.caption2).bold(), at: CGPoint(x: top.x, y: rect.minY - 10))
        }
    }

    private func drawPhaseNode(_ context: GraphicsContext, name: String, column: Int, columnSpacing: CGFloat) {
        let x = leftMargin + CGFloat(column) * columnSpacing
        let y: CGFloat = 16
        let rect = CGRect(x: x - 22, y: y - 10, width: 44, height: 20)
        let box = Path(roundedRect: rect, cornerRadius: 6)
        context.fill(box, with: .color(.purple.opacity(0.15)))
        context.stroke(box, with: .color(.purple), lineWidth: 1.5)
        context.draw(Text(name).font(.caption2), at: CGPoint(x: x, y: y))
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            legendEntry(color: .blue, text: "gate")
            HStack(spacing: 4) {
                Rectangle().fill(Color.secondary).frame(width: 14, height: 1.5)
                Text("wire").font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Rectangle().fill(Color.secondary.opacity(0.5)).frame(width: 14, height: 1.5)
                Text("pass-through").font(.caption).foregroundStyle(.secondary)
            }
            if hasPhaseNode {
                legendEntry(color: .purple, text: "global phase")
            }
        }
    }

    private func legendEntry(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(0.3))
                .frame(width: 10, height: 10)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }
}
