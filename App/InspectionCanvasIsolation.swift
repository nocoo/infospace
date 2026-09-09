#if DEBUG
import AppKit
import InfoSpaceCore
import InfoSpaceUI
import Observation
import SwiftUI

extension InspectionSession {
    func inspectCanvasIsolation() async {
        let sample = InfoSpaceModel()
        let probe = CanvasIsolationProbe()
        let hosted = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 640, height: 400),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        hosted.isReleasedWhenClosed = false
        hosted.contentView = NSHostingView(rootView: CanvasIsolationView(model: sample, probe: probe))
        hosted.center()
        defer { hosted.close() }
        await activate(hosted)
        await settle(300)
        let before = probe.constructions
        let frame = probe.frames[SpaceID(row: 0, column: 0)]
        let target = DividerTarget(column: 0, row: 0)
        sample.beginDrag(target)
        for step in 1...24 {
            sample.updateDrag(target, columnTick: 16 + Double(step) / 8, rowTick: 16 - Double(step) / 8)
            await settle(16)
        }
        checks["drag-does-not-rebuild-host-content"] = before >= 4 && probe.constructions == before
        checks["isolated-content-still-resizes-continuously"] = probe.frames[SpaceID(row: 0, column: 0)] != frame
        sample.endDrag()
        await settle(200)
        probe.title = "Updated host content"
        await settle(200)
        checks["host-content-updates-without-layout-revision"] = probe.displayedTitles == ["Updated host content"]
        diagnostics["content-constructions-before-drag"] = String(before)
        diagnostics["content-constructions-after-host-update"] = String(probe.constructions)
    }
}

@MainActor @Observable private final class CanvasIsolationProbe {
    var title = "Initial host content"
    @ObservationIgnored var constructions = 0
    @ObservationIgnored var frames: [SpaceID: CGRect] = [:]
    @ObservationIgnored var displayedTitles: Set<String> = []
}

private struct CanvasIsolationView: View {
    let model: InfoSpaceModel
    let probe: CanvasIsolationProbe

    var body: some View {
        InfoSpaceCanvas(
            model: model, appearance: { _ in SpaceAppearance(title: "Panel", color: .gray) },
            content: { id in CanvasIsolationContent(id: id, title: probe.title, probe: probe) })
    }
}

private struct CanvasIsolationContent: View {
    let id: SpaceID
    let title: String
    let probe: CanvasIsolationProbe

    init(id: SpaceID, title: String, probe: CanvasIsolationProbe) {
        self.id = id
        self.title = title
        self.probe = probe
        probe.constructions += 1
    }

    var body: some View {
        Text(title).frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .local)
            } action: {
                probe.frames[id] = $0
            }
            .onChange(of: title, initial: true) { _, value in probe.displayedTitles = [value] }
    }
}
#endif
