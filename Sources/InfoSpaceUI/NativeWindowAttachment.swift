import SwiftUI

struct NativeWindowAttachment: NSViewRepresentable {
    let configuration: InfoSpaceWindowConfiguration

    func makeNSView(context: Context) -> Attachment { Attachment(configuration: configuration) }

    func updateNSView(_ view: Attachment, context: Context) {
        view.configuration = configuration
        view.window?.backgroundColor = NSColor(configuration.background)
    }

    static func dismantleNSView(_ view: Attachment, coordinator: ()) { view.stopObserving() }

    @MainActor
    final class Attachment: NSView {
        var configuration: InfoSpaceWindowConfiguration
        private weak var sizedWindow: NSWindow?
        private var observation: NSObjectProtocol?

        init(configuration: InfoSpaceWindowConfiguration) {
            self.configuration = configuration
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { nil }

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stopObserving()
            guard let window, window !== sizedWindow else { return }
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(configuration.background)
            observation = NotificationCenter.default.addObserver(
                forName: NSWindow.didUpdateNotification, object: window, queue: .main
            ) { [weak self] _ in MainActor.assumeIsolated { self?.applyFrame() } }
            Task { @MainActor [weak self] in
                await Task.yield()
                self?.applyFrame()
            }
        }

        private func applyFrame() {
            guard let window, window.isVisible, window !== sizedWindow,
                let visible = (window.screen ?? NSScreen.main)?.visibleFrame
            else { return }
            sizedWindow = window
            stopObserving()
            // Apply after attachment to avoid re-entering SwiftUI's initial layout.
            // The native toolbar reserves its own height above the workspace.
            window.styleMask.remove(.fullSizeContentView)
            guard configuration.centersOnLaunch else { return }
            let width = visible.width * fraction(configuration.screenWidthFraction)
            let height = visible.height * fraction(configuration.screenHeightFraction)
            let size = CGSize(
                width: min(visible.width, max(configuration.minimumSize.width, width)),
                height: min(visible.height, max(configuration.minimumSize.height, height)))
            let frame = CGRect(
                x: visible.midX - size.width / 2, y: visible.midY - size.height / 2,
                width: size.width, height: size.height)
            window.setFrame(frame, display: true)
        }

        private func fraction(_ value: CGFloat) -> CGFloat { value.isFinite ? min(1, max(0.1, value)) : 0.9 }

        func stopObserving() {
            if let observation { NotificationCenter.default.removeObserver(observation) }
            observation = nil
        }
    }
}
