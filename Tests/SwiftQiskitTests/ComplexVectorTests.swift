import Foundation
import Testing
import SwiftQiskit

struct ComplexVectorTests {

    private let tolerance = 1e-12

    @Test func addSubtractScale() {
        let a: [Complex] = [Complex(1, 0), Complex(0, 1)]
        let b: [Complex] = [Complex(2, 0), Complex(0, -1)]
        #expect(a.adding(b) == [Complex(3, 0), Complex(0, 0)])
        #expect(a.subtracting(b) == [Complex(-1, 0), Complex(0, 2)])
        #expect([Complex(1, 0), Complex(2, 0)].scaled(by: Complex.i) == [Complex(0, 1), Complex(0, 2)])
        #expect(a.scaled(by: 2.0) == [Complex(2, 0), Complex(0, 2)])
    }

    @Test func innerProductConjugatesReceiver() {
        let v: [Complex] = [Complex(1, 0), .i]
        let w: [Complex] = [Complex(1, 0), Complex(0, -1)]
        #expect(v.inner(w) == .zero)
        // ⟨v|v⟩ is real and equals |v|².
        #expect(v.inner(v) == Complex(2, 0))
        // Swapping the arguments conjugates the result.
        let a: [Complex] = [Complex(1, 2)]
        let b: [Complex] = [Complex(3, -1)]
        #expect(a.inner(b) == b.inner(a).conjugate)
    }

    @Test func innerMatchesBraKet() {
        let s = 1 / sqrt(2.0)
        let psi = StateVector([Complex(s, 0), Complex(0, s)])
        let phi = StateVector([Complex(s, 0), Complex(s, 0)])
        let viaBra = phi† * psi
        let viaArrays = phi.amplitudes.inner(psi.amplitudes)
        #expect((viaBra - viaArrays).magnitude < tolerance)
    }

    @Test func normAndNormalized() {
        let raw: [Complex] = [Complex(1, 0), .i]
        #expect(abs(raw.norm - sqrt(2.0)) < tolerance)
        #expect(abs(raw.normSquared - 2) < tolerance)
        let unit = raw.normalized()
        #expect(abs(unit.norm - 1) < tolerance)
    }

    @Test func plusStillConcatenates() {
        let a: [Complex] = [.one]
        let b: [Complex] = [.zero]
        #expect((a + b).count == 2)
    }
}
