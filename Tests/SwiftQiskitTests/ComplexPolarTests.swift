import Foundation
import Testing
import SwiftQiskit

struct ComplexPolarTests {

    private let tolerance = 1e-12

    private func close(_ a: Complex, _ b: Complex) -> Bool {
        (a - b).magnitude < tolerance
    }

    @Test func argumentOnAxesAndQuadrants() {
        #expect(Complex(1, 0).argument == 0)
        #expect(abs(Complex(0, 1).argument - .pi / 2) < tolerance)
        #expect(abs(Complex(-1, 0).argument - .pi) < tolerance)
        #expect(abs(Complex(0, -1).argument + .pi / 2) < tolerance)
        #expect(abs(Complex(1, 1).argument - .pi / 4) < tolerance)
        #expect(abs(Complex(-1, 1).argument - 3 * .pi / 4) < tolerance)
        #expect(abs(Complex(-1, -1).argument + 3 * .pi / 4) < tolerance)
        #expect(Complex.zero.argument == 0)
    }

    @Test func polarInitRoundTrips() {
        let z = Complex(magnitude: 2.5, argument: 0.7)
        #expect(abs(z.magnitude - 2.5) < tolerance)
        #expect(abs(z.argument - 0.7) < tolerance)
    }

    @Test func unitPhaseMatchesPhaseGate() {
        let theta = Double.pi / 3
        #expect(close(Complex(argument: theta), PhaseGate.matrix(theta: theta)[1, 1]))
    }

    @Test func exponential() {
        #expect(close(Complex.exp(Complex.i * Complex(.pi)), Complex(-1)))
        #expect(close(Complex.exp(.zero), .one))
        #expect(close(Complex.exp(Complex(1, 0)), Complex(M_E)))
    }

    @Test func integerPower() {
        #expect(Complex.pow(.i, 4) == .one)
        #expect(Complex.pow(.i, 2) == Complex(-1))
        #expect(Complex.pow(Complex(3, 4), 0) == .one)
        let z = Complex(1, 2)
        #expect(close(Complex.pow(z, -1), Complex.one / z))
        #expect(close(Complex.pow(z, 3), z * z * z))
    }

    @Test func fractionalPower() {
        let z = Complex(3, 4)
        let root = Complex.pow(z, 0.5)
        #expect(close(root * root, z))
        #expect(Complex.pow(.zero, 2.0) == .zero)
    }

    @Test func negationAndRealDivision() {
        #expect(-Complex(1, -2) == Complex(-1, 2))
        #expect(Complex(2, 4) / 2.0 == Complex(1, 2))
    }
}
