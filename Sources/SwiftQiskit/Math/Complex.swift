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
