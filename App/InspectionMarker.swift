import SwiftUI

struct InspectionMarker: ViewModifier {
    let id: String
    var inToolbar = false
    func body(content: Content) -> some View {
        #if DEBUG
        if WindowInspection.isEnabled {
            if inToolbar {
                content.background(ToolbarInspectionAnchor(id: id))
            } else {
                content.onGeometryChange(for: CGRect.self) {
                    $0.frame(in: .named("InfoSpaceWorkspace"))
                } action: { frame in
                    WindowInspection.frames[id] = frame
                }
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

struct InspectionLinkCapture: ViewModifier {
    func body(content: Content) -> some View {
        #if DEBUG
        if WindowInspection.isEnabled {
            content.environment(
                \.openURL,
                OpenURLAction { url in
                    WindowInspection.openedURLs.append(url)
                    return .handled
                })
        } else {
            content
        }
        #else
        content
        #endif
    }
}

#if DEBUG
import AppKit

/// Toolbar items use separate hosting views, so their frames need native window coordinates.
private struct ToolbarInspectionAnchor: NSViewRepresentable {
    let id: String

    func makeNSView(context: Context) -> Anchor {
        let view = Anchor()
        view.markerID = id
        WindowInspection.toolbarMarkers[id] = WindowInspection.WeakToolbarMarker(view: view)
        return view
    }

    func updateNSView(_ view: Anchor, context: Context) {}

    static func dismantleNSView(_ view: Anchor, coordinator: ()) {
        if WindowInspection.toolbarMarkers[view.markerID]?.view === view {
            WindowInspection.toolbarMarkers.removeValue(forKey: view.markerID)
        }
    }

    final class Anchor: NSView {
        var markerID = ""
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
}

#endif
