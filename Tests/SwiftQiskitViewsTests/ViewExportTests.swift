import Foundation
import ImageIO
import CoreGraphics
import Testing
@testable import SwiftQiskit
@testable import SwiftQiskitViews

@MainActor
struct ViewExportTests {

    private func tempURL(_ ext: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("bloch-\(UUID().uuidString).\(ext)")
    }

    private var view: BlochSphereView {
        BlochSphereView(label: "|+⟩", bloch: BlochVector(Ket.plus))
    }

    @Test("writePNG produces a decodable PNG")
    func png() throws {
        let url = tempURL("png")
        defer { try? FileManager.default.removeItem(at: url) }
        try view.writePNG(to: url, scale: 2)

        let data = try Data(contentsOf: url)
        #expect(data.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47]))
        let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        let image = source.flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
        #expect(image != nil)
        // Canvas is 220 pt wide (plus padding), at 2x
        #expect((image?.width ?? 0) >= 440)
    }

    @Test("writePDF produces a single-page PDF")
    func pdf() throws {
        let url = tempURL("pdf")
        defer { try? FileManager.default.removeItem(at: url) }
        try view.writePDF(to: url)

        let data = try Data(contentsOf: url)
        #expect(data.prefix(4) == Data("%PDF".utf8))
        #expect(CGPDFDocument(url as CFURL)?.numberOfPages == 1)
    }
}
