//
//  ParameterPopover.swift
//  SwiftQiskitGUI
//
//  Angle editor for a placed P/RX/RY/RZ gate.
//

import SwiftUI

struct ParameterPopover: View {
    let onChange: (Double) -> Void

    @State private var value: Double

    init(theta: Double, onChange: @escaping (Double) -> Void) {
        self.onChange = onChange
        _value = State(initialValue: theta)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("θ = \(value, format: .number.precision(.fractionLength(3)))")
                .font(.caption.monospaced())

            Slider(value: $value, in: 0...(2 * .pi))
                .frame(width: 200)
                .onChange(of: value) { _, newValue in
                    onChange(newValue)
                }
        }
        .padding()
    }
}
