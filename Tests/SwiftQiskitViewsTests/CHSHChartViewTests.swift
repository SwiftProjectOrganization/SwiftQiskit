import Foundation
import SwiftUI
import Testing
@testable import SwiftQiskitViews

struct CHSHChartViewTests {

    @Test("instantiates with line and scatter series")
    func instantiation() {
        let line = CHSHChartView.Series(
            label: "exact",
            color: .blue,
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1)],
            isLine: true
        )
        let scatter = CHSHChartView.Series(
            label: "sampled",
            color: .red,
            points: [CGPoint(x: 0.5, y: 0.4)],
            isLine: false
        )
        let chart = CHSHChartView(
            title: "smoke test",
            xRange: 0...1,
            yRange: -1...1,
            series: [line, scatter]
        )
        _ = chart.body
    }
}
