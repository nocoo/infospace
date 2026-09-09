#if DEBUG
import AppKit
import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

extension InspectionSession {
    func inspectControlStyle() async {
        let probe = ControlStyleProbe()
        let sample = InfoSpaceModel(rows: 1, columns: 1)
        let hosted = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 640, height: 360),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        hosted.isReleasedWhenClosed = false
        hosted.contentView = NSHostingView(rootView: controlStyleCanvas(model: sample, probe: probe))
        hosted.center()
        defer { hosted.close() }
        await activate(hosted)
        await settle(300)
        let controls = probe.views.compactMap(\.view).filter { $0.window === hosted }
        checks["host-control-style-uses-configured-size"] =
            controls.count == 4
            && controls.allSatisfy { $0.bounds.size == CGSize(width: 40, height: 40) }
        checks["host-control-style-inherits-disabled-state"] = controls.filter { !$0.enabled }.count == 1
        checks["host-control-style-inherits-control-size"] = !controls.isEmpty && controls.allSatisfy(\.largeControls)
        if let disabled = controls.first(where: { !$0.enabled }) {
            let point = disabled.convert(CGPoint(x: 20, y: 20), to: nil)
            post(.leftMouseDown, at: point, in: hosted)
            post(.leftMouseUp, at: point, in: hosted)
            await settle(100)
        }
        checks["host-control-style-keeps-disabled-action-inert"] = probe.actions == 0
        let enabled = controls.filter(\.enabled).sorted {
            $0.convert($0.bounds, to: nil).minX < $1.convert($1.bounds, to: nil).minX
        }
        if let action = enabled.first {
            let point = action.convert(CGPoint(x: 20, y: 20), to: nil)
            let release = releaseMouse(at: point, windowNumber: hosted.windowNumber)
            post(.leftMouseDown, at: point, in: hosted)
            await settle(450)
            release.invalidate()
        }
        checks["host-control-style-observes-pressed-state"] = controls.contains(where: \.sawPressed)
        checks["host-control-style-keeps-native-action"] = probe.actions == 1 && sample.minimized.isEmpty
        captures["11-host-control-style"] = await capture(
            hosted, to: directory.appending(path: "11-host-control-style.png"))
        hosted.setContentSize(CGSize(width: 180, height: 360))
        await settle(300)
        let compact = probe.views.compactMap(\.view).filter { $0.window === hosted }
        checks["host-control-style-compact-menu-preserves-target"] =
            compact.count == 1 && compact.allSatisfy { $0.bounds.size == CGSize(width: 40, height: 40) }
        captures["13-host-compact-control"] = await capture(
            hosted, to: directory.appending(path: "13-host-compact-control.png"))
        await inspectLayoutControlStyle(hosted: hosted, sample: sample, probe: probe)
    }

    private func inspectLayoutControlStyle(
        hosted: NSWindow, sample: InfoSpaceModel, probe: ControlStyleProbe
    ) async {
        probe.views = []
        hosted.setContentSize(CGSize(width: 700, height: 160))
        var dockStyle = InfoSpaceStyle(theme: .light)
        dockStyle.controls.controlSide = 40
        dockStyle.controls.dimensionSize = CGSize(width: 40, height: 40)
        dockStyle.controls.buttonStyle = SpaceControlButtonStyle(InspectionControlStyle(probe: probe))
        hosted.contentView = NSHostingView(
            rootView:
                InfoSpaceLayoutControls(
                    model: sample, style: dockStyle,
                    options: .init(allowsCollapse: false, showsPresets: false)
                )
                .controlSize(.large)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("host-layout-controls"))
        await settle(200)
        let dock = probe.views.compactMap(\.view).filter { $0.window === hosted }
        checks["layout-controls-use-host-size-and-feedback"] =
            dock.count == 7
            && dock.allSatisfy { $0.bounds.size == CGSize(width: 40, height: 40) && $0.largeControls }
        checks["layout-controls-keep-boundary-actions-disabled"] = dock.filter { !$0.enabled }.count == 3
        let identifiers = accessibleIdentifiers(in: hosted)
        let expected = [
            "increase-rows", "decrease-rows", "increase-columns", "decrease-columns",
            "balance", "toggle-grid", "restore-all",
        ]
        checks["layout-controls-retain-accessibility-identifiers"] = expected.allSatisfy(identifiers.contains)
    }

    private func accessibleIdentifiers(in window: NSWindow) -> Set<String> {
        var pending: [AnyObject] = [window]
        var visited: Set<ObjectIdentifier> = []
        var identifiers: Set<String> = []
        while let element = pending.popLast(), visited.count < 5_000 {
            guard visited.insert(ObjectIdentifier(element)).inserted else { continue }
            if let view = element as? NSView { pending.append(contentsOf: view.subviews) }
            guard let object = element as? NSObject else { continue }
            func attribute(_ name: String) -> Any? {
                let selector = NSSelectorFromString(name)
                guard object.responds(to: selector) else { return nil }
                return object.perform(selector)?.takeUnretainedValue()
            }
            if let value = attribute("accessibilityIdentifier") as? String {
                identifiers.insert(value)
            }
            if let values = attribute("accessibilityChildren") as? [AnyObject] {
                pending.append(contentsOf: values)
            }
        }
        return identifiers
    }

    private func controlStyleCanvas(model: InfoSpaceModel, probe: ControlStyleProbe) -> some View {
        var style = InfoSpaceStyle(theme: .light)
        style.panel.headerHeight = 52
        style.panel.controlSide = 40
        style.panel.controlSpacing = 4
        style.panel.actionFont = .system(size: 16)
        style.panel.controlButtonStyle = SpaceControlButtonStyle(InspectionControlStyle(probe: probe))
        return InfoSpaceCanvas(
            model: model, style: style,
            appearance: { _ in SpaceAppearance(title: "Host controls", color: .gray) },
            actions: { _ in
                [
                    SpaceAction(id: "disabled", title: "Disabled action", systemImage: "minus", isEnabled: false) { _ in
                        probe.actions += 100
                    },
                    SpaceAction(id: "enabled", title: "Enabled action", systemImage: "plus") { _ in probe.actions += 1
                    },
                ]
            }, content: { _ in Text("Custom host appearance") }
        )
        .controlSize(.large)
        .preferredColorScheme(.light)
    }

    private func releaseMouse(at point: CGPoint, windowNumber: Int) -> Timer {
        // A common-mode timer can release native tracking even while the main
        // actor's task executor is suspended by AppKit's mouse-down handling.
        let timer = Timer(timeInterval: 0.2, repeats: false) { _ in
            MainActor.assumeIsolated {
                let event = NSEvent.mouseEvent(
                    with: .leftMouseUp, location: point, modifierFlags: [],
                    timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: windowNumber,
                    context: nil, eventNumber: 0, clickCount: 1, pressure: 0)
                if let event {
                    NSApp.postEvent(event, atStart: false)
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }
}

@MainActor private final class ControlStyleProbe {
    struct WeakView { weak var view: ControlStyleAnchor.Anchor? }
    var views: [WeakView] = []
    var actions = 0
}

private struct InspectionControlStyle: ButtonStyle {
    let probe: ControlStyleProbe
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.controlSize) private var controlSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect)
            .background(
                ControlStyleAnchor(
                    probe: probe, enabled: enabled, largeControls: controlSize == .large,
                    pressed: configuration.isPressed)
            )
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
            .scaleEffect(configuration.isPressed && !reduced ? 0.96 : 1)
    }
}

private struct ControlStyleAnchor: NSViewRepresentable {
    let probe: ControlStyleProbe
    let enabled: Bool
    let largeControls: Bool
    let pressed: Bool

    func makeNSView(context: Context) -> Anchor {
        let view = Anchor()
        probe.views.append(.init(view: view))
        return view
    }
    func updateNSView(_ view: Anchor, context: Context) {
        view.enabled = enabled; view.largeControls = largeControls; view.sawPressed = view.sawPressed || pressed
    }

    final class Anchor: NSView {
        var enabled = true
        var largeControls = false
        var sawPressed = false
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
}
#endif
