//
//  ContentView.swift
//  SwiftQiskitGUI
//
//  Owns the CircuitBuilder and armed-gate state so both the regular
//  (CircuitBuilderView) and compact iPhone (CompactBuilderView) layouts
//  share one circuit.
//

import SwiftUI

struct ContentView: View {
    @State private var builder = CircuitBuilder(qubitCount: 2)
    @State private var armedGate: GateKind?

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            CompactBuilderView(builder: builder, armedGate: $armedGate)
        } else {
            CircuitBuilderView(builder: builder, armedGate: $armedGate)
        }
        #else
        CircuitBuilderView(builder: builder, armedGate: $armedGate)
        #endif
    }
}

#Preview {
    ContentView()
}
