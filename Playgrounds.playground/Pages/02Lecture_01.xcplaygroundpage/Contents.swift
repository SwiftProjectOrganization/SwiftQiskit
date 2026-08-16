//: [Previous](@previous)

import Foundation
import SwiftQiskitCore

let ket0 = Ket([Complex(1/2), Complex(1/2)])
let bra0 = ket0†
bra0 * ket0
ket0.amplitudes
ket0.probabilities

let ket1 = Ket([Complex(0.8660254037844387), Complex(0.35355339059327373, 0.3535533905932737)])
let bra1 = ket1†
bra1 * ket1

ket1.dimension.magnitude

ket1.amplitudes

ket1.probabilities

ket1†

ket1† * ket1

ket1 ⊗ ket1

(ket1†)†

ket1 * ket1†

ket1† * Matrix.identity(size: 2)

//: [Next](@next)
