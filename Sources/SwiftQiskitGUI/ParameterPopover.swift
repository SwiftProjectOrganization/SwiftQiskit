//
//  ParameterPopover.swift
//  SwiftQiskitGUI
//
//  Angle editor for a placed P/RX/RY/RZ gate.
//

import SwiftUI

struct ParameterPopover: View {
    @Binding var theta: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("θ = \(theta, format: .number.precision(.fractionLength(3)))")
                .font(.caption.monospaced())

            Slider(value: $theta, in: 0...(2 * .pi))
                .frame(width: 200)
        }
        .padding()
        .presentationCompactAdaptation(.popover)
    }
}
