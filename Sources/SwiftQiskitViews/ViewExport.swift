import SwiftUI
import ImageIO
import UniformTypeIdentifiers

/// Errors thrown by `View.writePNG(to:scale:background:)` / `View.writePDF(to:background:)`.
public enum ViewExportError: Error {
    /// `ImageRenderer` produced no image.
    case renderFailed
    /// The destination file could not be created.
    case cannotCreateFile(URL)
    /// The image could not be encoded or written.
    case encodeFailed
}

@MainActor
public extension View {

    /// Rasterizes the view and writes it as a PNG.
    /// - Parameters:
    ///   - scale: pixels per point (2 = Retina).
    ///   - background: fill behind the view; `nil` keeps it transparent.
    func writePNG(to url: URL, scale: CGFloat = 2, background: Color? = .white) throws {
        let renderer = ImageRenderer(content: exportContent(background: background))
        renderer.scale = scale
        guard let image = renderer.cgImage else { throw ViewExportError.renderFailed }
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
        ) else { throw ViewExportError.cannotCreateFile(url) }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw ViewExportError.encodeFailed }
    }

    /// Writes the view as a single-page vector PDF sized to the view's ideal size.
    /// - Parameter background: fill behind the view; `nil` keeps it transparent.
    func writePDF(to url: URL, background: Color? = .white) throws {
        let renderer = ImageRenderer(content: exportContent(background: background))
        var failure: ViewExportError?
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else {
                failure = .cannotCreateFile(url)
                return
            }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
        }
        if let failure { throw failure }
    }

    /// Light-mode content on an optional background, so `.primary`/`.secondary`
    /// strokes stay visible regardless of the system appearance.
    private func exportContent(background: Color?) -> some View {
        self
            .padding(8)
            .background(background ?? .clear)
            .environment(\.colorScheme, .light)
    }
}
