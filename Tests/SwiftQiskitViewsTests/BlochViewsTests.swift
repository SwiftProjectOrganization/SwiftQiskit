import Foundation
import Testing
@testable import SwiftQiskit
@testable import SwiftQiskitViews

struct BlochViewsTests {

    private let samples = [
        BlochVector(x: 1, y: 0, z: 0),
        BlochVector(Ket.plusI)
    ]

    @Test("BlochSphereView instantiates")
    func sphere() {
        for bloch in samples {
            _ = BlochSphereView(label: "q0", bloch: bloch).body
        }
    }

    @Test("Bloch3DView instantiates")
    func threeD() {
        for bloch in samples {
            _ = Bloch3DView(label: "q0", bloch: bloch, size: 200).body
        }
    }

    @Test("BlochProjectionView instantiates, including flipped vertical axis")
    func projection() {
        for down in [false, true] {
            _ = BlochProjectionView(
                label: "x–z",
                horizontal: (label: "x", value: 0.5),
                vertical: (label: "z", value: -0.5),
                verticalPointsDown: down
            ).body
        }
    }

    @Test("BlochExplorerView instantiates")
    func explorer() {
        _ = BlochExplorerView().body
    }
}
