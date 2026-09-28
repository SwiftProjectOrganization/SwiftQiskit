import Foundation
import Testing
@testable import SwiftQiskit

struct ParameterShiftTests {

    /// Central finite-difference gradient, for grading the parameter-shift rule against.
    private func finiteDifference(
        at parameters: [Double],
        epsilon: Double = 1e-6,
        _ cost: ([Double]) -> Double
    ) -> [Double] {
        parameters.indices.map { k in
            var plus = parameters
            var minus = parameters
            plus[k] += epsilon
            minus[k] -= epsilon
            return (cost(plus) - cost(minus)) / (2 * epsilon)
        }
    }

    // MARK: - Parameter-shift matches finite difference

    /// A 2-parameter ansatz (`ry(θ₀,0); ry(θ₁,1); cx(0,1)`) against `H = ZZ + 0.5·XI`: the
    /// exact parameter-shift gradient matches a central finite difference at several points.
    @Test func `two parameter gradient matches finite difference`() {
        let hamiltonian = Hamiltonian([
            PauliString("ZZ", coefficient: 1.0),
            PauliString("XI", coefficient: 0.5),
        ])

        func ansatz(_ theta: [Double]) -> QuantumCircuit {
            let qc = QuantumCircuit(qubits: 2)
            qc.ry(theta[0], 0)
            qc.ry(theta[1], 1)
            qc.cx(0, 1)
            return qc
        }

        func energy(_ theta: [Double]) -> Double {
            hamiltonian.expectation(ansatz(theta).run())
        }

        for point in [[0.0, 0.0], [0.3, -0.7], [1.2, 2.4], [-1.5, 0.5]] {
            let exact = ParameterShift.gradient(at: point, energy)
            let fd = finiteDifference(at: point, energy)
            for k in exact.indices {
                #expect(abs(exact[k] - fd[k]) < 1e-5)
            }
        }
    }

    /// Page 18's one-parameter H₂-style ansatz (`x(0); ry(θ,1); cx(1,0)`) against a
    /// 2-qubit Hamiltonian: the parameter-shift gradient matches finite difference.
    @Test func `one parameter ansatz gradient matches finite difference`() {
        let hamiltonian = Hamiltonian([
            PauliString("ZZ", coefficient: 1.0),
            PauliString("XI", coefficient: 0.5),
            PauliString("IX", coefficient: 0.5),
        ])

        func ansatz(_ theta: [Double]) -> QuantumCircuit {
            let qc = QuantumCircuit(qubits: 2)
            qc.x(0)
            qc.ry(theta[0], 1)
            qc.cx(1, 0)
            return qc
        }

        func energy(_ theta: [Double]) -> Double {
            hamiltonian.expectation(ansatz(theta).run())
        }

        for theta in [0.0, 0.4, 1.0, 2.5] {
            let exact = ParameterShift.gradient(at: [theta], energy)
            let fd = finiteDifference(at: [theta], energy)
            #expect(abs(exact[0] - fd[0]) < 1e-5)
        }
    }

    /// The `Hamiltonian`/`ansatz` convenience overload matches the plain-closure form.
    @Test func `Hamiltonian ansatz overload matches the closure form`() {
        let hamiltonian = Hamiltonian([PauliString("Z", coefficient: 1.0), PauliString("X", coefficient: 0.5)])

        func ansatz(_ theta: [Double]) -> QuantumCircuit {
            let qc = QuantumCircuit(qubits: 1)
            qc.ry(theta[0], 0)
            return qc
        }

        let point = [0.6]
        let viaOverload = ParameterShift.gradient(of: hamiltonian, at: point, ansatz: ansatz)
        let viaClosure = ParameterShift.gradient(at: point) { theta in
            hamiltonian.expectation(ansatz(theta).run())
        }
        #expect(abs(viaOverload[0] - viaClosure[0]) < 1e-12)
    }

    // MARK: - Gradient descent converges to a known minimum

    /// A single-qubit `ry(θ)` ansatz against `H = Z + 0.5·X`: the exact ground energy is
    /// `-√(1² + 0.5²)`, reachable since `ry` sweeps the whole X–Z great circle on the Bloch
    /// sphere. Gradient descent from `θ = 0` should converge there.
    @Test func `gradient descent converges to the closed-form ground energy`() {
        let hamiltonian = Hamiltonian([
            PauliString("Z", coefficient: 1.0),
            PauliString("X", coefficient: 0.5),
        ])

        func ansatz(_ theta: [Double]) -> QuantumCircuit {
            let qc = QuantumCircuit(qubits: 1)
            qc.ry(theta[0], 0)
            return qc
        }

        func energy(_ theta: [Double]) -> Double {
            hamiltonian.expectation(ansatz(theta).run())
        }

        let result = GradientDescent.minimize(
            initial: [0.0],
            learningRate: 0.2,
            maxIterations: 500,
            tolerance: 1e-10,
            cost: energy
        )

        let expected = -sqrt(1.0 * 1.0 + 0.5 * 0.5)
        #expect(abs(result.value - expected) < 1e-4)
        #expect(result.converged)
        #expect(result.value <= result.history.first!)
    }

    /// `parameterHistory` tracks `history` one-for-one: same length, same starting point,
    /// same final point, and every recorded cost matches re-evaluating `energy` at the
    /// parameter vector recorded alongside it (needed to plot a descent path against an
    /// E(θ) landscape, as page `18VQE`'s live view does).
    @Test func `parameterHistory lines up with history`() {
        let hamiltonian = Hamiltonian([
            PauliString("Z", coefficient: 1.0),
            PauliString("X", coefficient: 0.5),
        ])

        func ansatz(_ theta: [Double]) -> QuantumCircuit {
            let qc = QuantumCircuit(qubits: 1)
            qc.ry(theta[0], 0)
            return qc
        }

        func energy(_ theta: [Double]) -> Double {
            hamiltonian.expectation(ansatz(theta).run())
        }

        let result = GradientDescent.minimize(
            initial: [0.0],
            learningRate: 0.2,
            maxIterations: 40,
            tolerance: 0,
            cost: energy
        )

        #expect(result.iterations == 40)
        #expect(result.parameterHistory.count == result.history.count)
        #expect(result.parameterHistory.first! == [0.0])
        #expect(result.parameterHistory.last! == result.parameters)
        for (theta, e) in zip(result.parameterHistory, result.history) {
            #expect(abs(energy(theta) - e) < 1e-12)
        }
    }
}
