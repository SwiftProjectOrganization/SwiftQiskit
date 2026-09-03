//
//  HistogramView.swift
//  SwiftQiskitGUI
//
//  Bar chart of measurement counts from SimulationResult.measure(shots:).
//

import SwiftUI
import SwiftQiskitCore

struct HistogramView: View {
    let result: SimulationResult

    private let maxBarHeight: CGFloat = 120

    var body: some View {
        let sorted = result.sortedCounts
        let maxCount = max(sorted.map(\.count).max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 4) {
            Text("Measurement counts (\(result.shots) shots)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(sorted, id: \.state) { entry in
                        VStack(spacing: 2) {
                            Text("\(entry.count)")
                                .font(.system(size: 9, design: .monospaced))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.accentColor)
                                .frame(width: 22, height: maxBarHeight * CGFloat(entry.count) / CGFloat(maxCount))
                            Text("|\(entry.state)⟩")
                                .font(.system(size: 9, design: .monospaced))
                        }
                    }
                }
            }
        }
    }
}
