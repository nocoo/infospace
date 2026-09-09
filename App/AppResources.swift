import AppKit

/// The demo is built both as a SwiftPM executable and as a native Xcode application.
enum AppResources {
    #if SWIFT_PACKAGE
    static let bundle = Bundle.module
    #else
    static let bundle = Bundle.main
    #endif

    /// AppKit resolves SwiftPM's PNG pair and Xcode's combined multi-resolution TIFF.
    @MainActor
    static let toolbarMark = bundle.image(forResource: NSImage.Name("ToolbarMark"))

    @MainActor
    static var applicationIcon: NSImage? {
        guard let url = bundle.url(forResource: "AppIcon", withExtension: "icns") else { return nil }
        return NSImage(contentsOf: url)
    }
}
