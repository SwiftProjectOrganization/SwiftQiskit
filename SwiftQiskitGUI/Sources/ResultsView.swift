//
//  ResultsView.swift
//  SwiftQiskitGUI
//
//  Live state vector for the current circuit, plus an on-demand shots
//  measurement with a histogram.
//

import SwiftUI
import SwiftQiskitCore

struct ResultsView: View {
    var builder: CircuitBuilder

    @State private var shots: Int = 1000
    @State private var lastResult: SimulationResult?

    var body: some View {
        let state = builder.buildCircuit().run()

        VStack(alignment: .leading, spacing: 12) {
            Text("State Vector")
                .font(.headline)

            ScrollView {
                stateVectorList(state)
            }
            .frame(maxHeight: 220)

            Divider()

            HStack {
                Stepper("Shots: \(shots)", value: $shots, in: 1...10000, step: 100)
            }

            Button("Measure") {
                lastResult = builder.buildCircuit().measure(shots: shots)
            }

            if let result = lastResult {
                HistogramView(result: result)
                    .frame(height: 160)
            }

            Spacer()
        }
    }

    private func stateVectorList(_ state: StateVector) -> some View {
        let probabilities = state.probabilities

        return VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<state.dimension, id: \.self) { index in
                if probabilities[index] > 1e-9 {
                    Text("|\(binaryLabel(index))⟩: \(state[index].description)  (p=\(String(format: "%.3f", probabilities[index])))")
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
    }

    private func binaryLabel(_ index: Int) -> String {
        String(index, radix: 2).leftPadding(toLength: builder.qubitCount, withPad: "0")
    }
}
