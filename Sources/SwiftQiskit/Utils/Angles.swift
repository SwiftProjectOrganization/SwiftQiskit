import Foundation

/// Converts an angle from degrees to radians (all SwiftQiskit angle parameters are radians).
public func deg2rad(_ degrees: Double) -> Double {
    degrees * .pi / 180
}

/// Converts an angle from radians to degrees.
public func rad2deg(_ radians: Double) -> Double {
    radians * 180 / .pi
}
