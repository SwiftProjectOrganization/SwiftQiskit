//
//  CompactBuilderView.swift
//  SwiftQiskitGUI
//
//  iPhone (horizontally-compact) layout: the circuit grid fills the screen
//  with a horizontally-scrolling gate strip pinned below it. The qubit-count
//  stepper doesn't fit a toolbar, so it's a Menu+Picker instead; results
//  (state vector + histogram) open in a sheet rather than a side panel.
//

#if os(iOS)
import SwiftUI
import SwiftQiskitCore

struct CompactBuilderView: View {
    var builder: CircuitBuilder
    @Binding var armedGate: GateKind?

    @State private var showingResults = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CircuitGridView(builder: builder, armedGate: $armedGate)
                    .frame(maxHeight: .infinity)

                Divider()

                GatePaletteView(armedGate: $armedGate, layout: .strip)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
            }
            .navigationTitle("Circuit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu("Qubits: \(builder.qubitCount)") {
                        Picker(
                            "Qubits",
                            selection: Binding(
                                get: { builder.qubitCount },
                                set: { builder.qubitCount = $0 }
                            )
                        ) {
                            ForEach(CircuitBuilder.minQubits...CircuitBuilder.maxQubits, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") { builder.clear() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Results") { showingResults = true }
                }
            }
            .sheet(isPresented: $showingResults) {
                NavigationStack {
                    ResultsView(builder: builder)
                        .padding()
                        .navigationTitle("Results")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showingResults = false }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    CompactBuilderView(builder: CircuitBuilder(qubitCount: 2), armedGate: .constant(nil))
}
#endif
