//
//  MatrixScalar.swift
//  SwiftQiskit
//
//  The element requirements for `GenericMatrix`.
//

import Foundation

/// A scalar usable as a `GenericMatrix` entry: a ring with `zero`/`one`,
/// a conjugate (identity for real scalars) and a real magnitude for tolerances.
public protocol MatrixScalar: AdditiveArithmetic, Hashable, CustomStringConvertible {
    static var one: Self { get }
    static func * (lhs: Self, rhs: Self) -> Self
    var conjugate: Self { get }
    var magnitude: Double { get }
}

extension Complex: AdditiveArithmetic, MatrixScalar {}

extension Double: MatrixScalar {
    public static var one: Double { 1 }
    public var conjugate: Double { self }
}
