//
//  CircuitBuilderView.swift
//  SwiftQiskitGUI
//
//  Regular-width layout: gate palette, circuit grid, and live results side by
//  side. Used on macOS and iPad (any horizontalSizeClass other than .compact).
//  State is owned by ContentView so CompactBuilderView can share the same
//  builder and armed gate.
//

import SwiftUI
import SwiftQiskitCore

struct CircuitBuilderView: View {
    var builder: CircuitBuilder
    @Binding var armedGate: GateKind?

    var body: some View {
        HStack(spacing: 16) {
            GatePaletteView(armedGate: $armedGate)
                .frame(width: 220)
                .padding()
                .background(Color.gray.opacity(0.1))

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Circuit")
                        .font(.headline)

                    Spacer()

                    Stepper(
                        "Qubits: \(builder.qubitCount)",
                        value: Binding(
                            get: { builder.qubitCount },
                            set: { builder.qubitCount = $0 }
                        ),
                        in: CircuitBuilder.minQubits...CircuitBuilder.maxQubits
                    )
                    .frame(width: 160)

                    Button("Clear") { builder.clear() }
                }

                CircuitGridView(builder: builder, armedGate: $armedGate)
                    .frame(maxHeight: .infinity)
            }
            .padding()

            ResultsView(builder: builder)
                .frame(width: 320)
                .padding()
        }
    }
}

#Preview {
    CircuitBuilderView(builder: CircuitBuilder(qubitCount: 2), armedGate: .constant(nil))
        .frame(width: 900, height: 600)
}
