import SwiftUI

/// Orthographic projection of the Bloch vector onto a coordinate plane.
/// Dropping the out-of-plane component leaves the point (h, v); the
/// projected arrow is shorter than the unit circle whenever the state
/// points out of the plane — the missing length is the dropped component.
public struct BlochProjectionView: View {

    let label: String
    /// Component drawn along the horizontal canvas axis (positive → right)
    let horizontal: (label: String, value: Double)
    /// Component drawn along the vertical canvas axis (positive → up by default)
    let vertical: (label: String, value: Double)
    /// Set when the positive vertical axis should point down on the canvas
    let verticalPointsDown: Bool

    public init(
        label: String,
        horizontal: (label: String, value: Double),
        vertical: (label: String, value: Double),
        verticalPointsDown: Bool = false
    ) {
        self.label = label
        self.horizontal = horizontal
        self.vertical = vertical
        self.verticalPointsDown = verticalPointsDown
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.headline)

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 16

                drawCircle(context, center: center, radius: radius)
                drawAxes(context, center: center, radius: radius)
                drawProjectedVector(context, center: center, radius: radius)
            }
            .frame(width: 160, height: 160)

            Text(readout)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var readout: String {
        String(
            format: "%@ %+.3f  %@ %+.3f  r %.3f",
            horizontal.label, horizontal.value,
            vertical.label, vertical.value,
            hypot(horizontal.value, vertical.value)
        )
    }

    /// Map in-plane coordinates to canvas points
    private func point(
        _ h: Double, _ v: Double,
        center: CGPoint, radius: Double
    ) -> CGPoint {
        CGPoint(
            x: center.x + h * radius,
            y: center.y + (verticalPointsDown ? v : -v) * radius
        )
    }

    private func drawCircle(_ context: GraphicsContext, center: CGPoint, radius: Double) {
        // Unit circle — the sphere's silhouette in this plane
        let outline = Path(
            ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            )
        )
        context.stroke(outline, with: .color(.primary.opacity(0.6)), lineWidth: 1)
    }

    private func drawAxes(_ context: GraphicsContext, center: CGPoint, radius: Double) {
        let axes: [(h: Double, v: Double, label: String)] = [
            (1, 0, horizontal.label),
            (0, 1, vertical.label)
        ]

        for axis in axes {
            var line = Path()
            line.move(to: point(-axis.h, -axis.v, center: center, radius: radius))
            line.addLine(to: point(axis.h, axis.v, center: center, radius: radius))
            context.stroke(line, with: .color(.secondary.opacity(0.5)), lineWidth: 0.5)

            // Label just beyond the positive axis tip
            context.draw(
                Text(axis.label).font(.caption2).foregroundStyle(.secondary),
                at: point(axis.h * 1.15, axis.v * 1.15, center: center, radius: radius)
            )
        }
    }

    private func drawProjectedVector(_ context: GraphicsContext, center: CGPoint, radius: Double) {
        let tip = point(horizontal.value, vertical.value, center: center, radius: radius)

        var arrow = Path()
        arrow.move(to: center)
        arrow.addLine(to: tip)
        context.stroke(arrow, with: .color(.red), lineWidth: 2)

        let dot = Path(
            ellipseIn: CGRect(x: tip.x - 4, y: tip.y - 4, width: 8, height: 8)
        )
        context.fill(dot, with: .color(.red))
    }
}
