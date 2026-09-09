import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct IconGenerationError: Error {
    let message: String
}

func loadSquareImage(at url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
        image.width == image.height
    else {
        throw IconGenerationError(message: "Expected a square image at \(url.path)")
    }
    return image
}

func resize(_ image: CGImage, canvasSize: Int, tileSize: Int? = nil) throws -> CGImage {
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
        let context = CGContext(
            data: nil, width: canvasSize, height: canvasSize, bitsPerComponent: 8,
            bytesPerRow: canvasSize * 4, space: colorSpace, bitmapInfo: bitmapInfo)
    else {
        throw IconGenerationError(message: "Could not create a \(canvasSize) px image context")
    }
    let extent = tileSize ?? canvasSize
    let inset = (canvasSize - extent) / 2
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: inset, y: inset, width: extent, height: extent))
    guard let output = context.makeImage() else {
        throw IconGenerationError(message: "Could not render a \(canvasSize) px image")
    }
    return output
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else {
        throw IconGenerationError(message: "Could not create \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw IconGenerationError(message: "Could not finish \(url.path)")
    }
}

func generateIcons(root: URL) throws {
    let foreground = try loadSquareImage(at: root.appending(path: "logo.png"))
    let presentation = try loadSquareImage(at: root.appending(path: "assets/brand/icon-rounded.png"))
    let resources = root.appending(path: "App/Resources", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

    try writePNG(resize(foreground, canvasSize: 22), to: resources.appending(path: "ToolbarMark.png"))
    try writePNG(resize(foreground, canvasSize: 44), to: resources.appending(path: "ToolbarMark@2x.png"))

    // Keep the complete selected rounded tile inside the macOS icon's transparent platform inset.
    let nativeIcon = try resize(presentation, canvasSize: 1024, tileSize: 824)
    try writePNG(nativeIcon, to: root.appending(path: "assets/brand/macos-icon.png"))
    let iconset = FileManager.default.temporaryDirectory.appending(
        path: "infospace-\(UUID().uuidString).iconset", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
    for points in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let suffix = scale == 2 ? "@2x" : ""
            let name = "icon_\(points)x\(points)\(suffix).png"
            try writePNG(resize(nativeIcon, canvasSize: points * scale), to: iconset.appending(path: name))
        }
    }

    let converter = Process()
    converter.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    converter.arguments = [
        "--convert", "icns", "--output", resources.appending(path: "AppIcon.icns").path, iconset.path,
    ]
    try converter.run()
    converter.waitUntilExit()
    guard converter.terminationStatus == 0 else {
        throw IconGenerationError(message: "iconutil exited with status \(converter.terminationStatus)")
    }
    print("Generated the transparent toolbar mark and inset macOS application icon.")
    print("Iconset inputs retained at \(iconset.path)")
}

do {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    try generateIcons(root: root)
} catch {
    let message = (error as? IconGenerationError)?.message ?? String(describing: error)
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(1)
}
