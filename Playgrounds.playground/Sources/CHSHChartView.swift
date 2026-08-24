import SwiftUI

/// A minimal, general-purpose 2D line/scatter chart — used for the CHSH
/// correlation curves (page 15) and the VQE energy landscape and
/// optimizer trajectory (page 18). Stateless (no `@State`), so it can
/// be declared and instantiated directly in page code — see
/// PLAYGROUNDSUPPORT.md.
public struct CHSHChartView: View {

    /// One plotted series: either a connected curve (`isLine: true`,
    /// points assumed sorted by x) or a scatter of individual samples
    /// (`isLine: false`, drawn as dots — e.g. shot-sampled correlators).
    public struct Series {
        let label: String
        let color: Color
        let points: [CGPoint]
        let isLine: Bool

        public init(label: String, color: Color, points: [CGPoint], isLine: Bool) {
            self.label = label
            self.color = color
            self.points = points
            self.isLine = isLine
        }
    }

    let title: String
    let xRange: ClosedRange<Double>
    let yRange: ClosedRange<Double>
    let series: [Series]
    let size: CGSize

    public init(
        title: String,
        xRange: ClosedRange<Double>,
        yRange: ClosedRange<Double>,
        series: [Series],
        size: CGSize = CGSize(width: 480, height: 300)
    ) {
        self.title = title
        self.xRange = xRange
        self.yRange = yRange
        self.series = series
        self.size = size
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Canvas { context, canvasSize in
                let padding: CGFloat = 28
                let plotRect = CGRect(
                    x: padding, y: padding,
                    width: canvasSize.width - 2 * padding,
                    height: canvasSize.height - 2 * padding
                )
                drawAxes(context, plotRect: plotRect)
                drawZeroLine(context, plotRect: plotRect)
                for s in series {
                    if s.isLine {
                        drawLine(context, series: s, plotRect: plotRect)
                    } else {
                        drawScatter(context, series: s, plotRect: plotRect)
                    }
                }
            }
            .frame(width: size.width, height: size.height)

            legend
        }
    }

    // MARK: - Coordinate mapping

    private func mapped(_ point: CGPoint, plotRect: CGRect) -> CGPoint {
        let xFrac = (Double(point.x) - xRange.lowerBound) / (xRange.upperBound - xRange.lowerBound)
        let yFrac = (Double(point.y) - yRange.lowerBound) / (yRange.upperBound - yRange.lowerBound)
        return CGPoint(
            x: plotRect.minX + CGFloat(xFrac) * plotRect.width,
            y: plotRect.maxY - CGFloat(yFrac) * plotRect.height
        )
    }

    // MARK: - Drawing

    private func drawAxes(_ context: GraphicsContext, plotRect: CGRect) {
        let border = Path(plotRect)
        context.stroke(border, with: .color(.secondary.opacity(0.5)), lineWidth: 0.5)
    }

    private func drawZeroLine(_ context: GraphicsContext, plotRect: CGRect) {
        guard yRange.contains(0) else { return }
        let y = mapped(CGPoint(x: xRange.lowerBound, y: 0), plotRect: plotRect).y
        var line = Path()
        line.move(to: CGPoint(x: plotRect.minX, y: y))
        line.addLine(to: CGPoint(x: plotRect.maxX, y: y))
        context.stroke(line, with: .color(.secondary.opacity(0.3)), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
    }

    private func drawLine(_ context: GraphicsContext, series: Series, plotRect: CGRect) {
        guard series.points.count > 1 else { return }
        var path = Path()
        path.move(to: mapped(series.points[0], plotRect: plotRect))
        for p in series.points.dropFirst() {
            path.addLine(to: mapped(p, plotRect: plotRect))
        }
        context.stroke(path, with: .color(series.color), lineWidth: 2)
    }

    private func drawScatter(_ context: GraphicsContext, series: Series, plotRect: CGRect) {
        for p in series.points {
            let center = mapped(p, plotRect: plotRect)
            let dot = Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
            context.fill(dot, with: .color(series.color))
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            ForEach(series.indices, id: \.self) { i in
                HStack(spacing: 4) {
                    if series[i].isLine {
                        Rectangle()
                            .fill(series[i].color)
                            .frame(width: 14, height: 2)
                    } else {
                        Circle()
                            .fill(series[i].color)
                            .frame(width: 6, height: 6)
                    }
                    Text(series[i].label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
