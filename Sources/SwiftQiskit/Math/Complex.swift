//
//  Complex.swift
//  SwiftQiskit
//
//  A lightweight Complex number implementation
//  used throughout the quantum core.
//
//  Created by Ali on 2025-01-XX.
//

import Foundation

public struct Complex: Equatable, Hashable {
    public var real: Double
    public var imag: Double

    // MARK: - Initializers
    public init(_ real: Double = 0.0, _ imag: Double = 0.0) {
        self.real = real
        self.imag = imag
    }

    // MARK: - Constants
    public static let zero = Complex(0, 0)
    public static let one  = Complex(1, 0)
    public static let i    = Complex(0, 1)

    // MARK: - Computed Properties
    public var magnitude: Double {
        sqrt(real * real + imag * imag)
    }

    public var magnitudeSquared: Double {
        real * real + imag * imag
    }

    public var conjugate: Complex {
        Complex(real, -imag)
    }
}

// MARK: - Arithmetic Operators
public extension Complex {

    static func + (lhs: Complex, rhs: Complex) -> Complex {
        Complex(lhs.real + rhs.real, lhs.imag + rhs.imag)
    }

    static func - (lhs: Complex, rhs: Complex) -> Complex {
        Complex(lhs.real - rhs.real, lhs.imag - rhs.imag)
    }

    static func * (lhs: Complex, rhs: Complex) -> Complex {
        Complex(
            lhs.real * rhs.real - lhs.imag * rhs.imag,
            lhs.real * rhs.imag + lhs.imag * rhs.real
        )
    }

    static func / (lhs: Complex, rhs: Complex) -> Complex {
        let denom = rhs.magnitudeSquared
        precondition(denom != 0, "Division by zero complex number")

        return Complex(
            (lhs.real * rhs.real + lhs.imag * rhs.imag) / denom,
            (lhs.imag * rhs.real - lhs.real * rhs.imag) / denom
        )
    }
}

// MARK: - Scalar Operations
public extension Complex {

    static func * (lhs: Complex, rhs: Double) -> Complex {
        Complex(lhs.real * rhs, lhs.imag * rhs)
    }

    static func * (lhs: Double, rhs: Complex) -> Complex {
        rhs * lhs
    }
}

public extension Complex {

    static func / (lhs: Complex, rhs: Double) -> Complex {
        precondition(rhs != 0, "Division by zero")
        return Complex(lhs.real / rhs, lhs.imag / rhs)
    }

    static prefix func - (value: Complex) -> Complex {
        Complex(-value.real, -value.imag)
    }
}

// MARK: - Polar Form
public extension Complex {

    /// The argument (phase angle) arg(z) = atan2(imag, real), in (-π, π]. Zero for z == 0.
    var argument: Double {
        atan2(imag, real)
    }

    /// The number r·e^{iθ}. With the default magnitude, `Complex(argument: θ)` is the
    /// unit phase e^{iθ}.
    init(magnitude: Double = 1.0, argument: Double) {
        self.init(magnitude * cos(argument), magnitude * sin(argument))
    }

    /// e^z = e^{re}·(cos im + i·sin im).
    static func exp(_ z: Complex) -> Complex {
        Complex(magnitude: Foundation.exp(z.real), argument: z.imag)
    }

    /// zⁿ by repeated squaring, so small Gaussian integers stay exact (i⁴ == 1).
    /// A negative `n` gives 1 / z^|n|.
    static func pow(_ z: Complex, _ n: Int) -> Complex {
        var result = Complex.one
        var base = z
        var remaining = n.magnitude
        while remaining > 0 {
            if remaining & 1 == 1 { result = result * base }
            base = base * base
            remaining >>= 1
        }
        return n < 0 ? Complex.one / result : result
    }

    /// zˣ on the principal branch: |z|ˣ · e^{i·x·arg z}. Zero for z == 0 and x > 0.
    static func pow(_ z: Complex, _ x: Double) -> Complex {
        if z == .zero {
            precondition(x > 0, "Zero raised to a non-positive power")
            return .zero
        }
        return Complex(magnitude: Foundation.pow(z.magnitude, x), argument: x * z.argument)
    }
}

// MARK: - CustomStringConvertible
extension Complex: CustomStringConvertible {
    public var description: String {
        if imag == 0 {
            return "\(real)"
        } else if real == 0 {
            return "\(imag)i"
        } else {
            let sign = imag >= 0 ? "+" : "-"
            return "\(real) \(sign) \(abs(imag))i"
        }
    }
}
